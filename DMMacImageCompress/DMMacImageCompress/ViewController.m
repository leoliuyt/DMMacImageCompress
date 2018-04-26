//
//  ViewController.m
//  DMMacImageCompress
//
//  Created by leoliu on 2018/4/25.
//  Copyright © 2018年 leoliu. All rights reserved.
//

#import "ViewController.h"
#import "NSImage+DM.h"
#import "LLImageCompressOperation.h"
#import "LLImageCompressManager.h"

@interface ViewController()
@property (nonatomic, strong) NSTask *task;
@property (weak) IBOutlet NSImageView *imageView;
@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    NSLog(@"%@",[[NSScreen mainScreen].deviceDescription description]);
    // Do any additional setup after loading the view.
    
//    [self taskAdv];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}
- (IBAction)clickBtn:(id)sender {
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    __weak typeof(self)weakSelf = self;
    
    //允许选中的文件类型
    panel.allowedFileTypes = @[@"png",@"jpg",@"jpeg"];
    //是否可以创建文件夹
    panel.canCreateDirectories = NO;
    //是否可以选择文件夹
    panel.canChooseDirectories = NO;
    //是否可以选择文件
    panel.canChooseFiles = YES;
    //是否可以多选
    panel.allowsMultipleSelection = YES;
    //显示
    
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
        //是否点击open 按钮
        if (result == NSModalResponseOK) {
            NSArray <NSString *>*array = [panel.URLs valueForKeyPath:@"path"];
            [weakSelf testCompressManager:array];
        }
    }];
}

- (void)testOperation:(NSArray *)array
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 5;
    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        LLImageCompressOperation *op = [[LLImageCompressOperation alloc] initWithImageAsset:obj maxSize:CGSizeMake(2048, 2048) maxFileSize:20];
        [op addHandlersForCompleted:^(NSData *data, NSSize size) {
            NSLog(@"index = %tu,data = %lu,size = %@",idx,data.length,NSStringFromSize(size));
        }];
        [queue addOperation:op];
    }];
}

- (void)testCompressManager:(NSArray *)array
{
    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [[LLImageCompressManager shared] compressImageWithAsset:obj completed:^(NSData *data, NSSize size) {
          NSLog(@"index = %tu,data = %lu,size = %@",idx,data.length,NSStringFromSize(size));
        }];
    }];
    
}

- (void)testOther:(NSArray *)array
{
//    NSMutableArray *tmpArr = [NSMutableArray arrayWithCapacity:panel.URLs.count];
//    //            [panel.URLs enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//    //                NSImage *img = [[NSImage alloc] initWithContentsOfFile:obj.path];
//    //                if (img) {
//    //                    [tmpArr addObject:img];
//    //                }
//    //            }];
//
//    NSString *path = panel.URLs.firstObject.path;
//    NSImage *image = [[NSImage alloc] initWithContentsOfFile:path];
//    //            NSDictionary *fileDic = [[NSFileManager defaultManager] attributesOfItemAtPath:outPath error:nil];//获取文件的属性
//    //            unsigned long long size = [[fileDic objectForKey:NSFileSize] longLongValue];
//
//    NSDictionary *fileDic = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
//    unsigned long long size = [[fileDic objectForKey:NSFileSize] longLongValue];
//    NSLog(@"===压缩前文件大小：%llu",size);
//
//    CGSize maxSize = CGSizeZero;
//    //            NSData *data = [image compressImageToMaxSize:maxSize maxFileSize:4];
//
//    //            self.imageView.image  = [[NSImage alloc] initWithData:data];
//    //            NSLog(@"===压缩后文件大小：%lu",data.length);
//    //            [self taskAdv:path];
}

- (void)taskAdv:(NSString *)filePath
{
    self.task = [NSTask new];
    
    NSString *path = [self pathForExecutalbeName:@"advpng"];
    NSMutableArray* arguments = [NSMutableArray arrayWithObjects:
                            [NSString stringWithFormat:@"-%tu",4],
                            @"-z",
                            @"--",
                            [self tempPath].path,
                            nil];
//    --timelimit=48 --iterations=10 --filters=p --lossy_transparent -y
//    NSMutableArray* arguments = [NSMutableArray arrayWithObjects:
//                                 [NSString stringWithFormat:@"-%tu",4],
//                                 @"-z",
//                                 @"--",
//                                 filePath,
//                                 nil];
    
//    NSString *tmpPath = @"/Users/leoliu/Desktop/testExt/compress.png";
    // clone the current environment
    NSMutableDictionary *
    environment =[NSMutableDictionary dictionaryWithDictionary: [[NSProcessInfo processInfo] environment]];
    
    // set up for unbuffered I/O
    environment[@"NSUnbufferedIO"] = @"YES";
    
    if ([self.task respondsToSelector:@selector(setQualityOfService:)]) {
        self.task.qualityOfService = NSQualityOfServiceUtility;
    }
    
    
     NSLog(@"Launching %@ %@",path,[arguments componentsJoinedByString:@" "]);
    
    [self.task setLaunchPath:path];
    
    [self.task setArguments:arguments];
    
    [self.task setEnvironment:environment];
    
    
    NSPipe *commandPipe = [NSPipe pipe];
    NSFileHandle *commandHandle = [commandPipe fileHandleForReading];
    
    [self.task setStandardOutput:commandPipe];
    [self.task setStandardError:commandPipe];
    
    [self launchTask];

    [self parseLinesFromHandle:commandHandle];
    BOOL ok = [self waitUntilTaskExit];

    [commandHandle closeFile];
    
    if(!ok){
        NSLog(@"error");
    } else {
        NSLog(@"success");
        
        BOOL isExt = [[NSFileManager defaultManager] fileExistsAtPath:[self tempPath].path];
        if (isExt) {
            NSLog(@"YES");
            
            NSDictionary *orgfileDic = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];//获取文件的属性
            unsigned long long orgsize = [[orgfileDic objectForKey:NSFileSize] longLongValue];
            
            NSDictionary *fileDic = [[NSFileManager defaultManager] attributesOfItemAtPath:[self tempPath].path error:nil];//获取文件的属性
            unsigned long long size = [[fileDic objectForKey:NSFileSize] longLongValue];
            CGFloat filesize = 1.0*size/1024;
            NSLog(@"原文件大小:%f ;压缩后文件大小 = %f",orgsize / 1000.,size / 1000.);
            NSData *data = [NSData dataWithContentsOfURL:[self tempPath]];
            NSImage *imag = [[NSImage alloc] initWithData:data];
            NSLog(@"%@",imag);
        } else {
            NSLog(@"NO");
        }
    }
}


- (void)taskZop:(NSString *)filePath
{
    self.task = [NSTask new];
    
    NSString *path = [self pathForExecutalbeName:@"zopflipng"];
    //    NSMutableArray* arguments = [NSMutableArray arrayWithObjects:
    //                            [NSString stringWithFormat:@"-%tu",4],
    //                            @"-z",
    //                            @"--",
    //                            [self tempPath].path,
    //                            nil];
    //    --timelimit=48 --iterations=10 --filters=p --lossy_transparent -y
    //    NSMutableArray* arguments = [NSMutableArray arrayWithObjects:
    //                                 [NSString stringWithFormat:@"-%tu",4],
    //                                 @"-z",
    //                                 @"--",
    //                                 filePath,
    //                                 nil];
    
    //    NSString *tmpPath = @"/Users/leoliu/Desktop/testExt/compress.png";
    NSMutableArray *arguments = [NSMutableArray arrayWithObjects:
                                 @"--timelimit=48",
                                 @"--iterations=10",
                                 @"--filters=p",
                                 @"--lossy_transparent",
                                 @"-y",
                                 filePath,
                                 [self tempPath].path,
                                 nil];
    // clone the current environment
    NSMutableDictionary *
    environment =[NSMutableDictionary dictionaryWithDictionary: [[NSProcessInfo processInfo] environment]];
    
    // set up for unbuffered I/O
    environment[@"NSUnbufferedIO"] = @"YES";
    
    if ([self.task respondsToSelector:@selector(setQualityOfService:)]) {
        self.task.qualityOfService = NSQualityOfServiceUtility;
    }
    
    
    NSLog(@"Launching %@ %@",path,[arguments componentsJoinedByString:@" "]);
    
    [self.task setLaunchPath:path];
    
    [self.task setArguments:arguments];
    
    [self.task setEnvironment:environment];
    
    
    NSPipe *commandPipe = [NSPipe pipe];
    NSFileHandle *commandHandle = [commandPipe fileHandleForReading];
    
    [self.task setStandardOutput:commandPipe];
    [self.task setStandardError:commandPipe];
    
    [self launchTask];
    
    [self parseLinesFromHandle:commandHandle];
    BOOL ok = [self waitUntilTaskExit];
    
    [commandHandle closeFile];
    
    if(!ok){
        NSLog(@"error");
    } else {
        NSLog(@"success");
        
        BOOL isExt = [[NSFileManager defaultManager] fileExistsAtPath:[self tempPath].path];
        if (isExt) {
            NSLog(@"YES");
            
            NSDictionary *orgfileDic = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];//获取文件的属性
            unsigned long long orgsize = [[orgfileDic objectForKey:NSFileSize] longLongValue];
            
            NSDictionary *fileDic = [[NSFileManager defaultManager] attributesOfItemAtPath:[self tempPath].path error:nil];//获取文件的属性
            unsigned long long size = [[fileDic objectForKey:NSFileSize] longLongValue];
            CGFloat filesize = 1.0*size/1024;
            NSLog(@"原文件大小:%f ;压缩后文件大小 = %f",orgsize / 1000.,size / 1000.);
            NSData *data = [NSData dataWithContentsOfURL:[self tempPath]];
            NSImage *imag = [[NSImage alloc] initWithData:data];
            NSLog(@"%@",imag);
        } else {
            NSLog(@"NO");
        }
    }
}


-(void)launchTask {
    @try {
//        BOOL supportsQoS = [self.task respondsToSelector:@selector(setQualityOfService:)];
//
//        if (supportsQoS) {
//            self.task.qualityOfService = self.qualityOfService;
//        }
        [self.task launch];
        
        int pid = [self.task processIdentifier];
        if (pid > 1) setpriority(PRIO_PROCESS, pid, PRIO_MAX/2); // PRIO_MAX is minimum priority. POSIX is intuitive.
    }
    @catch (NSException *e) {
        NSLog(@"Failed to launch %@ - %@",[self className],e);
    }
}

-(BOOL)parseLine:(NSString *)line {
    /* stub */
    return NO;
}


-(BOOL)waitUntilTaskExit {
    [self.task waitUntilExit];
    int status = [self.task terminationStatus];
    if (status) {
        NSLog(@"Task %@ failed with status %d", [self className], status);
        return NO;
    }
    return YES;
}
-(void)parseLinesFromHandle:(NSFileHandle *)commandHandle {
    NSData *temp;
    char inputBuffer[4096];
    NSInteger inputBufferPos=0;
    while ((temp = [commandHandle availableData]) && [temp length]) {
        const char *tempBytes = [temp bytes];
        NSInteger bytesPos=0, bytesLength = [temp length];
        
        while (bytesPos < bytesLength) {
            if (tempBytes[bytesPos] == '\n' || tempBytes[bytesPos] == '\r' || inputBufferPos == sizeof(inputBuffer)-1) {
                inputBuffer[inputBufferPos] = '\0';
                if ([self parseLine:@(inputBuffer)]) {
                    [commandHandle readDataToEndOfFile];
                    return;
                }
                inputBufferPos=0;
                bytesPos++;
            } else {
                inputBuffer[inputBufferPos++] = tempBytes[bytesPos++];
            }
        }
    }
}

- (NSString *)pathForExecutalbeName:(NSString *)executalbeName
{
    NSBundle *bundle = [NSBundle mainBundle];
    
    NSString *path = [bundle pathForAuxiliaryExecutable:executalbeName];
    if (!path) {
        path = [bundle pathForResource:executalbeName ofType:@""];
    }
    
    if (path) {
        if (![[NSFileManager defaultManager] isExecutableFileAtPath:path]) {
            NSLog(@"File %@ for %@ is not executable", path, executalbeName);
            return nil;
        }
    }
    return path;
}

-(NSURL *)tempPath {
    static int uid=0;
    if (uid==0) uid = getpid()<<12;
//    NSString *filename = [NSString stringWithFormat:@"ImageOptim.%@.%x.%x.temp",[self className],(unsigned int)([Job hash]^[self hash]),uid++];
    NSString *filename = @"compress.temp";
    return [NSURL fileURLWithPath: [NSTemporaryDirectory() stringByAppendingPathComponent: filename]];
}
@end
