//
//  ViewController.m
//  SymbolCrashLog
//
//  Created by nazimai on 2021/7/30.
//

#import "ViewController.h"

#import "KSCrashReportFilterAppleFmt.h"
#import <Python/Python.h>

@interface ViewController () {
    NSString *_dest_json_path;
    NSString *_dest_log_path;
}
@property (weak) IBOutlet NSButton *selectJsonBtn;
@property (weak) IBOutlet NSButton *jsonConvertBtn;
@property (weak) IBOutlet NSButton *jsonShowBtn;
@property (weak) IBOutlet NSTextField *jsonPathTextField;

@property (weak) IBOutlet NSButton *selectDYSMBtn;
@property (weak) IBOutlet NSButton *dysmConvertBtn;
@property (weak) IBOutlet NSButton *dysmShowBtn;
@property (weak) IBOutlet NSTextField *dysmPathTextField;

@property (weak) IBOutlet NSScrollView *symbolTextView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    _dest_json_path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"/MESymbol/report"];
    _dest_log_path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"/MESymbol/symbol"];
    BOOL isDirectory = YES;
    BOOL issuc;
    if (![[NSFileManager defaultManager] fileExistsAtPath:_dest_json_path isDirectory:&isDirectory]) {
        issuc = [[NSFileManager defaultManager] createDirectoryAtPath:_dest_json_path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:_dest_log_path isDirectory:&isDirectory]) {
        issuc = [[NSFileManager defaultManager] createDirectoryAtPath:_dest_log_path withIntermediateDirectories:YES attributes:nil error:nil];
    }
}


- (IBAction)selectJsonClick:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseDirectories = NO;
    panel.resolvesAliases = NO;
    panel.canChooseFiles = YES;

    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSModalResponseOK) {
            NSURL *document = [[panel URLs] objectAtIndex:0];
            self.jsonPathTextField.stringValue = document.path;
        }
    }];
}

- (IBAction)jsonConvertClick:(id)sender {
    if (self.jsonPathTextField.stringValue.length <= 0) {
        [self showAlertWithText:@"请先选择 sentry json 文件路径"];
        return;
    }

    NSString *srcFilePath = self.jsonPathTextField.stringValue;
    NSString *destFilePath = [_dest_json_path stringByAppendingPathComponent:@"/crash-report.crash"];
    _dest_json_path = destFilePath;
    NSLog(@"json path : %@", destFilePath);

    NSData *myJSON = [NSData dataWithContentsOfFile:srcFilePath];

    NSError *localError = nil;

    NSDictionary *parsedJSON = [NSJSONSerialization JSONObjectWithData:myJSON options:0 error:&localError];

    if(localError != nil) {
        return;
    }

    id filter = [KSCrashReportFilterAppleFmt filterWithReportStyle:KSAppleReportStyleSymbolicatedSideBySide];

    NSArray *reports = @[parsedJSON];
    [filter filterReports:reports onCompletion:^(NSArray *filteredReports, BOOL completed, NSError *error) {
        if(error != nil) {
            return;
        }

        if(completed) {
            NSString *contents = [filteredReports objectAtIndex:0];
            [contents  writeToFile:destFilePath
                      atomically:YES
                          encoding:NSStringEncodingConversionAllowLossy
                           error:nil];
        }
        [self showAlertWithText:[NSString stringWithFormat:@"转换成功 \n %@", self->_dest_json_path]];
    }];
}

- (IBAction)jsonShowClick:(id)sender {
    [[NSWorkspace sharedWorkspace] selectFile:nil inFileViewerRootedAtPath:_dest_json_path];
}

- (IBAction)selectDYSMClick:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseDirectories = NO;
    panel.resolvesAliases = NO;
    panel.canChooseFiles = YES;

    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSModalResponseOK) {
            NSURL *document = [[panel URLs] objectAtIndex:0];
            self.dysmPathTextField.stringValue = document.path;
        }
    }];
}

- (IBAction)dysmConvertClick:(id)sender {
    
}

- (IBAction)dysmShowClick:(id)sender {
    [[NSWorkspace sharedWorkspace] selectFile:nil inFileViewerRootedAtPath:_dest_log_path];
}

- (void)showAlertWithText:(NSString *)text {
    NSAlert *alert = [[NSAlert alloc]init];
    alert.messageText = text;
    [alert addButtonWithTitle:@"确定"];
    [alert beginSheetModalForWindow:[NSApplication sharedApplication].windows[0] completionHandler:^(NSModalResponse returnCode) {
    }];
}
@end
