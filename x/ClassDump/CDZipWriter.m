#import "CDZipWriter.h"
#import <zlib.h>

static void CDAppendUInt16(NSMutableData *data, uint16_t value) {
    uint16_t v = CFSwapInt16HostToLittle(value);
    [data appendBytes:&v length:sizeof(v)];
}

static void CDAppendUInt32(NSMutableData *data, uint32_t value) {
    uint32_t v = CFSwapInt32HostToLittle(value);
    [data appendBytes:&v length:sizeof(v)];
}

static NSString *CDRelativePath(NSString *path, NSString *rootDir) {
    NSString *prefix = [rootDir stringByAppendingString:@"/"];
    if ([path hasPrefix:prefix]) {
        return [path substringFromIndex:prefix.length];
    }
    return path.lastPathComponent ?: @"file";
}

static NSData *CDLocalHeader(NSData *nameData, uint32_t crc, uint32_t size) {
    NSMutableData *d = [NSMutableData data];
    CDAppendUInt32(d, 0x04034b50);
    CDAppendUInt16(d, 20);
    CDAppendUInt16(d, 0);
    CDAppendUInt16(d, 0);
    CDAppendUInt16(d, 0);
    CDAppendUInt16(d, 0);
    CDAppendUInt32(d, crc);
    CDAppendUInt32(d, size);
    CDAppendUInt32(d, size);
    CDAppendUInt16(d, (uint16_t)nameData.length);
    CDAppendUInt16(d, 0);
    [d appendData:nameData];
    return d;
}

static NSData *CDCentralHeader(NSData *nameData, uint32_t crc, uint32_t size, uint32_t offset) {
    NSMutableData *d = [NSMutableData data];
    CDAppendUInt32(d, 0x02014b50);
    CDAppendUInt16(d, 20);
    CDAppendUInt16(d, 20);
    CDAppendUInt16(d, 0);
    CDAppendUInt16(d, 0);
    CDAppendUInt16(d, 0);
    CDAppendUInt16(d, 0);
    CDAppendUInt32(d, crc);
    CDAppendUInt32(d, size);
    CDAppendUInt32(d, size);
    CDAppendUInt16(d, (uint16_t)nameData.length);
    CDAppendUInt16(d, 0);
    CDAppendUInt16(d, 0);
    CDAppendUInt16(d, 0);
    CDAppendUInt16(d, 0);
    CDAppendUInt32(d, 0);
    CDAppendUInt32(d, offset);
    [d appendData:nameData];
    return d;
}



static BOOL CDWrite(NSFileHandle *handle, NSData *data, NSError **error) {
    if (data.length == 0) return YES;
    return [handle writeData:data error:error];
}

@implementation CDZipWriter

+ (BOOL)createZipAtPath:(NSString *)zipPath
                rootDir:(NSString *)rootDir
                  files:(NSArray<NSString *> *)files
               progress:(CDZipProgressBlock)progress
                  error:(NSError **)error {

    NSFileManager *fm = NSFileManager.defaultManager;

    
    
    if (files.count > UINT16_MAX) {
        if (error) {
            NSString *desc = [NSString stringWithFormat:@"文件数 %lu 超过 ZIP 上限 65535（未实现 ZIP64）",
                              (unsigned long)files.count];
            *error = [NSError errorWithDomain:@"CDZipWriter" code:-2
                                     userInfo:@{NSLocalizedDescriptionKey: desc}];
        }
        return NO;
    }

    NSString *parent = [zipPath stringByDeletingLastPathComponent];
    if (parent.length) {
        NSError *dirError = nil;
        BOOL success = [fm createDirectoryAtPath:parent withIntermediateDirectories:YES attributes:nil error:&dirError];
        if (!success && dirError) {
            NSLog(@"[CDZipWriter] 创建目录失败: %@", dirError);
        }
    }

    [fm removeItemAtPath:zipPath error:nil];

    BOOL created = [fm createFileAtPath:zipPath contents:[NSData data] attributes:nil];
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:zipPath];
    if (!created || !handle) {
        if (error) {
            NSString *desc = [NSString stringWithFormat:@"ZIP创建失败: %@", zipPath ?: @"nil"];
            *error = [NSError errorWithDomain:@"CDZipWriter"
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey:desc}];
        }
        return NO;
    }

    NSMutableData *central = [NSMutableData data];
    uint64_t offset = 0;
    uint32_t entryCount = 0;
    BOOL failed = NO;

    NSUInteger total = files.count;
    NSUInteger done = 0;

    for (NSString *file in files) {
        @autoreleasepool {
            BOOL isDir = NO;
            if (![fm fileExistsAtPath:file isDirectory:&isDir] || isDir) {
                done++;
                continue;
            }

            NSData *content = [NSData dataWithContentsOfFile:file];
            if (!content) {
                done++;
                continue;
            }

            NSString *relative = CDRelativePath(file, rootDir);
            NSData *nameData = [relative dataUsingEncoding:NSUTF8StringEncoding];
            if (!nameData || nameData.length == 0 || nameData.length > UINT16_MAX) {
                done++;
                continue;
            }

            
            if (content.length > UINT32_MAX || offset + content.length > UINT32_MAX) {
                if (error) {
                    *error = [NSError errorWithDomain:@"CDZipWriter" code:-3
                                             userInfo:@{NSLocalizedDescriptionKey:
                                                            @"归档超过 4GB（未实现 ZIP64）"}];
                }
                failed = YES;
                break;
            }

            uint32_t size = (uint32_t)content.length;
            uint32_t crc = (uint32_t)crc32(0, content.bytes, (uInt)content.length);

            NSData *local = CDLocalHeader(nameData, crc, size);
            if (!CDWrite(handle, local, error) || !CDWrite(handle, content, error)) {
                failed = YES;
                break;
            }

            NSData *center = CDCentralHeader(nameData, crc, size, (uint32_t)offset);
            [central appendData:center];

            offset += local.length + content.length;
            entryCount++;

            done++;
            if (progress) {
                progress((CGFloat)done / (CGFloat)MAX(total, 1));
            }
        }
    }

    if (!failed) {
        uint32_t centralOffset = (uint32_t)offset;
        failed = !CDWrite(handle, central, error);

        NSMutableData *end = [NSMutableData data];
        CDAppendUInt32(end, 0x06054b50);
        CDAppendUInt16(end, 0);
        CDAppendUInt16(end, 0);
        CDAppendUInt16(end, (uint16_t)entryCount);
        CDAppendUInt16(end, (uint16_t)entryCount);
        CDAppendUInt32(end, (uint32_t)central.length);
        CDAppendUInt32(end, centralOffset);
        CDAppendUInt16(end, 0);
        if (!failed) failed = !CDWrite(handle, end, error);
    }

    [handle closeFile];

    if (failed) {
        
        [fm removeItemAtPath:zipPath error:nil];
        return NO;
    }
    return YES;
}

@end
