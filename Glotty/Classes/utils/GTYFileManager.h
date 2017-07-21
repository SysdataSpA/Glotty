// Copyright 2017 Sysdata S.p.A.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <Foundation/Foundation.h>

#define RESOURCES_DIRECTORY @"resources"

@interface GTYFileInfo : NSObject

@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSDate* modificationDateOnServer;
@property (nonatomic, strong) NSDate* downloadDateLocal;
@property (nonatomic, strong) NSString* path;

@end


@interface GTYFileManager : NSObject

@property (nonatomic, strong) NSString* cacheDirectory;
@property (nonatomic, strong) NSString* documentsDirectory;
@property (nonatomic, strong) NSString* applicationSupportDirectory;

+ (instancetype) sharedManager;

+ (NSString*) getFileNameFromUrl:(NSString*)url;

// File Utilities
+ (NSString*) getPathOfResourceDirectory;
+ (BOOL) deleteResourceDirectory;

+ (void) createDirectoryForFileAtPathIfNeeded:(NSString*)filePath;
+ (BOOL) createDirectoryAtPath:(NSString*)folderPath withIntermediateDirectories:(BOOL)createIntemediate;

+ (NSArray*) getFilesContentInDirectoryNamed:(NSString*)directoryName;

+ (NSArray*) getInfoAboutFilesContentInDirectoryNamed:(NSString*)directoryName;
+ (GTYFileInfo*) getInfoAboutFileAtPath:(NSString*)path;
+ (GTYFileInfo*) getInfoAboutFileNamed:(NSString*)fileName inDirectoryNamed:(NSString*)directoryName;

+ (BOOL) deleteFilesAtPath:(NSString*)filePath;
+ (BOOL) deleteFilesContentInDirectoryNamed:(NSString*)directoryName withModifyDateBefore:(NSDate*)expirationDate;

// Images
+ (UIImage*) getImageNamed:(NSString*)fileName inDirectoryNamed:(NSString*)directoryName;
+ (void) saveImage:(UIImage*)image named:(NSString*)fileName inDirectoryNamed:(NSString*)directoryName;

@end
