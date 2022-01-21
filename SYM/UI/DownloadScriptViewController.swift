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

class DownloadScriptViewController: NSViewController {

    @IBOutlet var textView: NSTextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.textView.font = NSFont(name: "Menlo", size: 11)!
        self.textView.textContainerInset = CGSize(width: 10, height: 10)
        
        Config.prepareDsymDownloadDirectory()
        self.loadContent()
    }
    
    @IBAction func didClickDoneButton(_ sender: Any) {
        var script = self.textView.string
        if script.lengthOfBytes(using: .utf8) > 0 {
            if !script.hasPrefix("#!") {
                script = "#!/bin/bash\n" + script
            }
        }
        do {
            try script.write(to: Config.downloadScriptURL, atomically: true, encoding: .utf8)
        } catch {
            // TODO: error handling
        }
        
        self.close(sender)
    }
    
    @IBAction func close(_ sender: Any) {
        self.view.window?.windowController?.close()
    }
    
    func loadContent() {
        let defaultContent = """
                                #!/bin/bash

                                # Download the .dSYM file to wherever you want.
                                # SYM can find it immediately.

                                # Crash informations
                                #     $1               # original crash file path
                                #     $2               # download directory
                                #     ${APP_NAME}      # e.g. im_zorro_sym
                                #     ${UUID}          # e.g. E5B0A378-6816-3D90-86FD-2AEF15894A85
                                #     ${BUNDLE_ID}     # e.g. im.zorro.sym
                                #     ${APP_VERSION}   # e.g. 212 (1.0.1)

                                # Error handling:
                                #     exit 0           # success
                                #     exit 1           # crash not supported
                                #     exit 2           # download failed"

                                # Examples:
                                #     curl -o $2/${UUID}.zip http://your.server.domain/path/to/${UUID}.zip
                                #     unzip -o "$2/${UUID}.zip" -d "$2/${UUID}"
                                #     for f in "$2/${UUID}/*.dSYM"; do dwarfdump --uuid $f ; done
                                #
                                
                                """
        let saved = try? String(contentsOf: Config.downloadScriptURL, encoding: .utf8)
        if saved != nil && saved!.count > 0 {
            self.textView.string = saved!
        } else {
            self.textView.string = defaultContent
        }
    }
}
