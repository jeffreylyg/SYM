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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MDAfcClient;

@interface MDDeviceFile : NSObject

@property (nonatomic, strong) NSString *path;
@property (nonatomic, assign) BOOL isDirectory;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, assign) NSUInteger size;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *lowercaseName;
@property (nonatomic, strong, readonly) NSString *extension;
@property (nonatomic, readonly, nullable) NSArray<MDDeviceFile *> *children;

- (instancetype)initWithAfcClient:(MDAfcClient *)afcClient;

- (nullable NSData *)read;
- (void)copy:(NSString *)path;

- (BOOL)remove;
- (BOOL)removeChild:(MDDeviceFile *)child;

@end

NS_ASSUME_NONNULL_END
