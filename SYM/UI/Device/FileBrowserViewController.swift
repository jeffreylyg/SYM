// The MIT License (MIT)
//
// Copyright (c) 2017 - present zqqf16
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


import Cocoa 

extension NSPopUpButton {
    func reloadItemsWithApps(_ apps: [MDAppInfo]) {
        self.removeAllItems()
        apps.forEach({ (app) in
            self.addItem(withTitle: "\(app.name)(\(app.identifier))")
        })
    }
}

class FileBrowserViewController: NSViewController, LoadingAble {

    @IBOutlet weak var exportButton: NSButton!
    @IBOutlet weak var exportIndicator: NSProgressIndicator!
    @IBOutlet weak var outlineView: NSOutlineView!
    
    var loadingIndicator: NSProgressIndicator!
    
    private var deviceID: String?
    private var appID: String?
    
    private var rootDir: MDDeviceFile!
    private var afcClient: MDAfcClient!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func reloadData(withDeviceID deviceID: String?, appID: String?) {
        if deviceID == self.deviceID && appID == self.appID {
            return
        }

        self.deviceID = deviceID
        self.appID = appID
        
        if deviceID == nil || appID == nil {
            self.rootDir = nil
            self.outlineView.reloadData()
            return
        }
        
        self.showLoading()
        DispatchQueue.global().async {
            let lockdown = MDLockdown(udid: deviceID!)
            let houseArrest = MDHouseArrest(lockdown: lockdown, appID: appID!)
            let afcClient = MDAfcClient.fileClient(with: houseArrest)
            let rootDir = MDDeviceFile(afcClient: afcClient)
            rootDir.path = "."
            rootDir.isDirectory = true
            let _ = rootDir.children // preload children
            
            DispatchQueue.main.async {
                self.afcClient = afcClient
                self.rootDir = rootDir
                self.outlineView.reloadData()
                self.hideLoading()
            }
        }
    }
    
    @IBAction func didClickExportButton(_ sender: NSButton) {
        let row = self.outlineView.selectedRow
        self.exportFile(atIndex: row)
    }

    @IBAction func didDoubleClickCell(_ sender: AnyObject?) {
        let row = self.outlineView.clickedRow
        self.openFile(atIndex: row)
    }
    
    @IBAction func reloadFiles(_ sender: AnyObject?) {
        let deviceID = self.deviceID
        let appID = self.appID
        self.deviceID = nil
        self.appID = nil
        self.reloadData(withDeviceID: deviceID, appID: appID)
    }
    
    @IBAction func openFile(_ sender: AnyObject?) {
        let row = self.outlineView.selectedRow
        self.exportFile(atIndex: row)
    }
    
    @IBAction func removeFile(_ sender: AnyObject?) {
        let row = self.outlineView.selectedRow
        guard let file = self.outlineView.item(atRow: row) as? MDDeviceFile,
              let parent = self.outlineView.parent(forItem: file) as? MDDeviceFile
        else {
            // TODO: root dir?
            return
        }
        self.showLoading()
        if parent.removeChild(file) {
            let index = self.outlineView.childIndex(forItem: file)
            self.outlineView.removeItems(at: IndexSet(integer: index), inParent: parent, withAnimation: .effectFade)
        }
        self.hideLoading()
    }

    private func exportFile(atIndex index: Int) {
        guard index >= 0, let file = self.outlineView.item(atRow: index) as? MDDeviceFile else {
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = file.name
        savePanel.beginSheetModal(for: self.view.window!) { [weak savePanel] (result) in
            guard result == .OK, let url = savePanel?.url else {
                return
            }
            var name = savePanel?.nameFieldStringValue ?? ""
            if name.isEmpty {
                name = file.name
            }
            let dest = URL(fileURLWithPath: name, relativeTo: url)
            self.exportFile(file, toURL: dest)
        }
    }

    private func exportFile(_ file: MDDeviceFile, toURL url: URL) {
        //self.exportIndicator.startAnimation(nil)
        //self.exportIndicator.isHidden = false
        //self.exportButton.isEnabled = false
        DispatchQueue.global().async {
            file.copy(url.path)
            /*
            DispatchQueue.main.async {
                self.exportIndicator.stopAnimation(nil)
                self.exportIndicator.isHidden = true
                self.exportButton.isEnabled = true
            }
             */
        }
    }
    
    private func openFile(atIndex index: Int) {
        guard index >= 0, let file = self.outlineView.item(atRow: index) as? MDDeviceFile else {
            return
        }
        if file.isDirectory {
            self.exportFile(atIndex: index)
            return
        }
        self.showLoading()
        DispatchQueue.global().async {
            guard let udid = self.deviceID else {
                self.hideLoading()
                return
            }
            
            let path = FileManager.default.localCrashDirectory(udid) + "/\(file.name)"
            let url = URL(fileURLWithPath: path)
            file.copy(url.path)
            DispatchQueue.main.async {
                self.hideLoading()
                NSWorkspace.shared.open(url)
            }
        }
    }
}

extension FileBrowserViewController: NSOutlineViewDelegate, NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let file = item as? MDDeviceFile, file.isDirectory, let children = file.children {
            return children.count
        }
        
        return self.rootDir?.children?.count ?? 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let file = item as? MDDeviceFile, file.isDirectory, let children = file.children {
            return children[index]
        }
        
        return self.rootDir!.children![index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let file = item as? MDDeviceFile, file.isDirectory, let children = file.children {
            return children.count > 0
        }

        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        var view: NSTableCellView?
        guard let file = item as? MDDeviceFile else {
            return view
        }
        
        view = outlineView.makeView(withIdentifier: tableColumn!.identifier, owner: nil) as? NSTableCellView
        if tableColumn == outlineView.tableColumns[0] {
            view?.textField?.stringValue = file.name
            if file.isDirectory {
                view?.imageView?.image = NSImage(named: NSImage.folderName as NSImage.Name)
            } else {
                view?.imageView?.image = NSWorkspace.shared.icon(forFileType: file.extension)
            }
        } else if tableColumn == outlineView.tableColumns[1] {
            view?.textField?.stringValue = file.date.formattedString
        } else {
            view?.textField?.stringValue = "\(file.size.readableSize)"
        }
        
        return view
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
    }
}
