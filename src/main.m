#import <Cocoa/Cocoa.h>

static NSString *kConfigPath = @".config/阅读隐身器/config.plist";
static NSInteger kMaxHistory = 10;

@interface ReaderPanel : NSPanel @end
@implementation ReaderPanel
- (BOOL)canBecomeKeyWindow { return YES; }
- (BOOL)canBecomeMainWindow { return NO; }
@end

@interface ClickTextView : NSTextView
@property (weak) id clickTarget;
@property SEL clickAction;
@property (weak) id rightClickTarget;
@property SEL rightClickAction;
@end
@implementation ClickTextView
- (void)mouseDown:(NSEvent *)event {
    [self.clickTarget performSelector:self.clickAction withObject:nil afterDelay:0.01];
}
- (void)rightMouseDown:(NSEvent *)event {
    [self.rightClickTarget performSelector:self.rightClickAction withObject:nil afterDelay:0.01];
}
@end

@protocol MHandler <NSObject>
- (void)readerMouseEntered;
- (void)readerMouseExited;
@end

@interface CView : NSView @end
@implementation CView { NSTrackingArea *_ta; }
- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    if (_ta) [self removeTrackingArea:_ta];
    _ta = [[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingMouseEnteredAndExited|NSTrackingActiveAlways owner:self userInfo:nil];
    [self addTrackingArea:_ta];
}
- (void)mouseEntered:(NSEvent *)event { [(id<MHandler>)self.window.delegate readerMouseEntered]; }
- (void)mouseExited:(NSEvent *)event { [(id<MHandler>)self.window.delegate readerMouseExited]; }
@end

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, MHandler> {
    NSInteger _currentPage;
    NSInteger _totalPages;
}
@property (strong) ReaderPanel *panel;
@property (strong) NSScrollView *scrollView;
@property (strong) ClickTextView *textView;
@property (strong) NSTextField *pageInput;
@property (strong) NSTextField *pageLabel;
@property (strong) NSTextField *hintLabel;
@property (strong) NSString *fullText;
@property (assign) BOOL isVisible;
@property (strong) NSStatusItem *statusItem;
@property (strong) NSColor *bgColor, *fgColor;
@property CGFloat bgAlpha, winWidth, winHeight, fontSize;
@property (strong) NSMutableArray *recentFiles;
@property (strong) NSWindow *settingsWindow;
@property (strong) NSTextView *previewView;
@property (strong) NSTextField *alphaValueLabel;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    self.recentFiles = [NSMutableArray array];
    self.winWidth = 420; self.winHeight = 500; self.fontSize = 14.0;
    _currentPage = 0; _totalPages = 0;
    [self loadConfig];
    [self setupPanel];
    [self updateMainMenu];
    [self setupStatusItem];
    [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer *t){ [self checkHotZone]; }];
    NSArray *args = NSProcessInfo.processInfo.arguments;
    if (args.count > 1) [self loadFile:args[1]];
    else self.fullText = @"点击📖选择文件\n或拖拽txt到图标";
    [self updatePage];
}

- (void)setupPanel {
    self.panel = [[ReaderPanel alloc] initWithContentRect:NSMakeRect(0, 0, self.winWidth, self.winHeight)
                                                styleMask:NSWindowStyleMaskBorderless|NSWindowStyleMaskNonactivatingPanel
                                                  backing:NSBackingStoreBuffered defer:NO];
    self.panel.level = NSFloatingWindowLevel;
    self.panel.opaque = NO;
    self.panel.backgroundColor = [self.bgColor colorWithAlphaComponent:self.bgAlpha];
    self.panel.hasShadow = YES;
    self.panel.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces|NSWindowCollectionBehaviorIgnoresCycle;
    self.panel.hidesOnDeactivate = NO;
    self.panel.delegate = self;
    [self.panel orderOut:nil];

    CView *cv = [[CView alloc] initWithFrame:NSMakeRect(0, 0, self.winWidth, self.winHeight)];
    cv.autoresizingMask = NSViewWidthSizable|NSViewHeightSizable;

    self.scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 30, self.winWidth, self.winHeight - 30)];
    self.scrollView.drawsBackground = NO;
    self.scrollView.hasVerticalScroller = NO;
    self.scrollView.hasHorizontalScroller = NO;
    self.scrollView.autohidesScrollers = YES;
    self.scrollView.borderType = NSNoBorder;
    self.scrollView.autoresizingMask = NSViewWidthSizable|NSViewHeightSizable;

    self.textView = [[ClickTextView alloc] initWithFrame:NSMakeRect(0, 0, self.winWidth, self.winHeight - 30)];
    self.textView.editable = NO; self.textView.selectable = NO; self.textView.drawsBackground = NO;
    self.textView.textColor = self.fgColor;
    self.textView.font = [NSFont monospacedSystemFontOfSize:self.fontSize weight:NSFontWeightRegular];
    self.textView.textContainerInset = NSMakeSize(20, 35);
    self.textView.autoresizingMask = NSViewWidthSizable;
    self.textView.clickTarget = self; self.textView.clickAction = @selector(nextPage);
    self.textView.rightClickTarget = self; self.textView.rightClickAction = @selector(prevPage);
    self.scrollView.documentView = self.textView;
    [cv addSubview:self.scrollView];

    self.pageInput = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 5, 55, 22)];
    self.pageInput.placeholderString = @"页码";
    self.pageInput.font = [NSFont systemFontOfSize:12]; self.pageInput.bezeled = YES;
    self.pageInput.bezelStyle = NSTextFieldRoundedBezel; self.pageInput.target = self;
    self.pageInput.action = @selector(jumpToPage);
    self.pageInput.autoresizingMask = NSViewMaxXMargin|NSViewMinYMargin;
    [cv addSubview:self.pageInput];

    self.pageLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(80, 7, 60, 18)];
    self.pageLabel.font = [NSFont systemFontOfSize:11];
    self.pageLabel.textColor = [self.fgColor colorWithAlphaComponent:0.5];
    self.pageLabel.drawsBackground = NO; self.pageLabel.bezeled = NO;
    self.pageLabel.editable = NO; self.pageLabel.selectable = NO;
    self.pageLabel.autoresizingMask = NSViewMaxXMargin|NSViewMinYMargin;
    [cv addSubview:self.pageLabel];

    self.hintLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(145, 7, self.winWidth - 165, 18)];
    self.hintLabel.stringValue = @"左键/空格=下一页  右键=上一页";
    self.hintLabel.textColor = [self.fgColor colorWithAlphaComponent:0.5];
    self.hintLabel.font = [NSFont systemFontOfSize:11];
    self.hintLabel.drawsBackground = NO; self.hintLabel.bezeled = NO;
    self.hintLabel.editable = NO; self.hintLabel.selectable = NO;
    self.hintLabel.autoresizingMask = NSViewWidthSizable|NSViewMinYMargin;
    [cv addSubview:self.hintLabel];

    self.panel.contentView = cv;
    [self repositionPanel];

    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent*(NSEvent*e){
        if(e.keyCode==49&&self.isVisible&&self.panel.visible){
            NSResponder *fr=[(NSWindow*)self.panel firstResponder];
            if(![fr isKindOfClass:[NSTextField class]]||fr!=self.pageInput){[self nextPage];return nil;}
        }return e;
    }];
}

- (void)repositionPanel {
    NSScreen *s = NSScreen.mainScreen;
    [self.panel setFrame:NSMakeRect(s.visibleFrame.size.width-self.winWidth-20,
                                     s.visibleFrame.size.height-self.winHeight-10,
                                     self.winWidth, self.winHeight) display:YES];
}

- (void)updatePage {
    if(!self.fullText.length){self.textView.string=@"";self.pageLabel.stringValue=@"";return;}
    self.textView.string = self.fullText;
    NSLayoutManager *lm = self.textView.layoutManager;
    NSTextContainer *tc = self.textView.textContainer;
    [lm ensureLayoutForTextContainer:tc];
    NSRect tvBounds = self.textView.bounds;
    CGFloat visibleH = self.scrollView.contentSize.height;
    if(visibleH <= 0) visibleH = self.winHeight - 70;
    _totalPages = MAX(1, ceil(tvBounds.size.height / visibleH));
    _currentPage = MAX(0, MIN(_currentPage, _totalPages - 1));
    CGFloat scrollY = _currentPage * visibleH;
    [self.textView scrollPoint:NSMakePoint(0, scrollY)];
    self.pageLabel.stringValue = [NSString stringWithFormat:@"%ld/%ld", (long)(_currentPage+1), (long)_totalPages];
}

- (void)nextPage {
    if(!self.fullText.length) return;
    _currentPage = (_currentPage + 1 < _totalPages) ? _currentPage + 1 : 0;
    [self updatePage];
}
- (void)prevPage {
    if(!self.fullText.length) return;
    _currentPage = (_currentPage > 0) ? _currentPage - 1 : _totalPages - 1;
    [self updatePage];
}
- (void)jumpToPage {
    NSInteger pg = self.pageInput.integerValue;
    if(pg < 1) pg = 1;
    _currentPage = MIN(pg - 1, _totalPages - 1);
    [self updatePage];
}

#pragma mark - Menu
- (void)updateMainMenu {
    NSMenu *mm=[[NSMenu alloc]init]; NSMenuItem *ai=[[NSMenuItem alloc]init]; NSMenu *am=[[NSMenu alloc]init];
    [am addItemWithTitle:@"打开文件..." action:@selector(openFile) keyEquivalent:@"o"];
    [am addItem:NSMenuItem.separatorItem];
    if(self.recentFiles.count>0){
        NSMenuItem *ht=[[NSMenuItem alloc]initWithTitle:@"最近打开" action:nil keyEquivalent:@""];ht.enabled=NO;[am addItem:ht];
        for(NSString *p in self.recentFiles){
            NSMenuItem *it=[[NSMenuItem alloc]initWithTitle:[p lastPathComponent] action:@selector(openRecent:)keyEquivalent:@""];
            it.representedObject=p;it.target=self;[am addItem:it];}
        [am addItem:NSMenuItem.separatorItem];}
    [am addItemWithTitle:@"设置..." action:@selector(showSettings) keyEquivalent:@","];
    [am addItem:NSMenuItem.separatorItem]; [am addItemWithTitle:@"退出" action:@selector(terminate:) keyEquivalent:@"q"];
    [ai setSubmenu:am]; [mm addItem:ai]; NSApp.mainMenu=mm;
}
- (void)setupStatusItem {
    self.statusItem=[NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.title=@"📖";[self updateStatusMenu];
}
- (void)updateStatusMenu {
    NSMenu *sm=[[NSMenu alloc]init];
    [[sm addItemWithTitle:@"打开文件..." action:@selector(openFile) keyEquivalent:@""]setTarget:self];
    [sm addItem:NSMenuItem.separatorItem];
    if(self.recentFiles.count>0){
        NSMenuItem *ht=[[NSMenuItem alloc]initWithTitle:@"最近打开" action:nil keyEquivalent:@""];ht.enabled=NO;[sm addItem:ht];
        for(NSString *p in self.recentFiles){
            NSMenuItem *it=[[NSMenuItem alloc]initWithTitle:[p lastPathComponent] action:@selector(openRecent:)keyEquivalent:@""];
            it.representedObject=p;it.target=self;[sm addItem:it];}
        [sm addItem:NSMenuItem.separatorItem];}
    [[sm addItemWithTitle:@"设置..." action:@selector(showSettings) keyEquivalent:@""]setTarget:self];
    [sm addItem:NSMenuItem.separatorItem];
    [[sm addItemWithTitle:@"退出" action:@selector(terminate:) keyEquivalent:@""]setTarget:NSApp];
    self.statusItem.menu=sm;
}
- (void)openRecent:(NSMenuItem*)s{if(s.representedObject)[self loadFile:s.representedObject];}

#pragma mark - Config
- (void)loadConfig {
    NSDictionary*c=[NSDictionary dictionaryWithContentsOfFile:[NSHomeDirectory()stringByAppendingPathComponent:kConfigPath]];
    CGFloat r=0.102,g=0.102,b=0.180,a=0.90,fr=0.88,fgR=0.88,fb=0.88;
    if(c){
        NSArray*ba=c[@"bg"];if(ba.count>=3){r=[ba[0]doubleValue];g=[ba[1]doubleValue];b=[ba[2]doubleValue];}
        if(c[@"alpha"])a=[c[@"alpha"]doubleValue];
        NSArray*fa=c[@"fg"];if(fa.count>=3){fr=[fa[0]doubleValue];fgR=[fa[1]doubleValue];fb=[fa[2]doubleValue];}
        if(c[@"winWidth"])self.winWidth=[c[@"winWidth"]doubleValue];
        if(c[@"winHeight"])self.winHeight=[c[@"winHeight"]doubleValue];
        if(c[@"fontSize"])self.fontSize=[c[@"fontSize"]doubleValue];
        NSArray*h=c[@"recentFiles"];if([h isKindOfClass:[NSArray class]])self.recentFiles=[h mutableCopy];
    }
    self.bgColor=[NSColor colorWithRed:r green:g blue:b alpha:1.0];
    self.fgColor=[NSColor colorWithRed:fr green:fgR blue:fb alpha:1.0];
    self.bgAlpha=a;
}
- (void)saveConfig {
    NSString*path=[NSHomeDirectory()stringByAppendingPathComponent:kConfigPath];
    [[NSFileManager defaultManager]createDirectoryAtPath:[path stringByDeletingLastPathComponent]withIntermediateDirectories:YES attributes:nil error:nil];
    CGFloat r1,g1,b1,a1,r2,g2,b2,a2;
    [self.bgColor getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    [self.fgColor getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
    [@{@"bg":@[@(r1),@(g1),@(b1)],@"fg":@[@(r2),@(g2),@(b2)],@"alpha":@(self.bgAlpha),
       @"winWidth":@(self.winWidth),@"winHeight":@(self.winHeight),@"fontSize":@(self.fontSize),
       @"recentFiles":self.recentFiles?:@[]} writeToFile:path atomically:YES];
}
- (void)addRecentFile:(NSString*)p{
    [self.recentFiles removeObject:p];[self.recentFiles insertObject:p atIndex:0];
    while(self.recentFiles.count>kMaxHistory)[self.recentFiles removeLastObject];
    [self saveConfig];[self updateMainMenu];[self updateStatusMenu];
}

#pragma mark - Settings
- (void)showSettings {
    if(self.settingsWindow){[self.settingsWindow makeKeyAndOrderFront:nil];return;}
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];[NSApp activateIgnoringOtherApps:YES];
    CGFloat y=370;
    NSWindow*win=[[NSWindow alloc]initWithContentRect:NSMakeRect(0,0,460,y+20)
                                            styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable
                                              backing:NSBackingStoreBuffered defer:NO];
    win.title=@"EasyReader - 设置";win.level=NSFloatingWindowLevel;
    win.collectionBehavior=NSWindowCollectionBehaviorCanJoinAllSpaces;win.delegate=self;[win center];
    NSView*v=[[NSView alloc]initWithFrame:win.contentView.bounds];
    NSFont*lf=[NSFont systemFontOfSize:13];int ln=0;

    NSColorWell*bw=[[NSColorWell alloc]initWithFrame:NSMakeRect(20,y,50,24)];
    bw.color=self.bgColor;bw.target=self;bw.action=@selector(bgColorChanged:);[v addSubview:bw];
    {NSTextField*l=[[NSTextField alloc]initWithFrame:NSMakeRect(80,y-2,80,20)];l.stringValue=@"背景色";l.font=lf;
     l.bezeled=NO;l.drawsBackground=NO;l.editable=NO;l.selectable=NO;[v addSubview:l];}
    NSColorWell*fw=[[NSColorWell alloc]initWithFrame:NSMakeRect(200,y,50,24)];
    fw.color=self.fgColor;fw.target=self;fw.action=@selector(fgColorChanged:);[v addSubview:fw];
    {NSTextField*l=[[NSTextField alloc]initWithFrame:NSMakeRect(260,y-2,80,20)];l.stringValue=@"字体色";l.font=lf;
     l.bezeled=NO;l.drawsBackground=NO;l.editable=NO;l.selectable=NO;[v addSubview:l];}ln++;

    NSSlider*as=[[NSSlider alloc]initWithFrame:NSMakeRect(130,y-ln*30,200,24)];
    as.minValue=0.1;as.maxValue=1.0;as.doubleValue=self.bgAlpha;as.target=self;
    as.action=@selector(alphaChanged:);as.continuous=YES;[v addSubview:as];
    {NSTextField*l=[[NSTextField alloc]initWithFrame:NSMakeRect(20,y-ln*30-2,100,20)];l.stringValue=@"背景透明度";l.font=lf;
     l.bezeled=NO;l.drawsBackground=NO;l.editable=NO;l.selectable=NO;[v addSubview:l];}
    self.alphaValueLabel=[[NSTextField alloc]initWithFrame:NSMakeRect(340,y-ln*30,50,20)];
    self.alphaValueLabel.stringValue=[NSString stringWithFormat:@"%.0f%%",self.bgAlpha*100];self.alphaValueLabel.font=lf;
    self.alphaValueLabel.bezeled=NO;self.alphaValueLabel.drawsBackground=NO;
    self.alphaValueLabel.editable=NO;self.alphaValueLabel.selectable=NO;[v addSubview:self.alphaValueLabel];ln++;

    NSSlider*fs=[[NSSlider alloc]initWithFrame:NSMakeRect(110,y-ln*30,180,24)];
    fs.minValue=10;fs.maxValue=32;fs.doubleValue=self.fontSize;fs.target=self;
    fs.action=@selector(fontSizeChanged:);fs.continuous=YES;[v addSubview:fs];
    {NSTextField*l=[[NSTextField alloc]initWithFrame:NSMakeRect(20,y-ln*30-2,80,20)];l.stringValue=@"字体大小";l.font=lf;
     l.bezeled=NO;l.drawsBackground=NO;l.editable=NO;l.selectable=NO;[v addSubview:l];}
    {NSTextField*l=[[NSTextField alloc]initWithFrame:NSMakeRect(300,y-ln*30,50,20)];
     l.stringValue=[NSString stringWithFormat:@"%.0f",self.fontSize];l.tag=10;l.font=lf;
     l.bezeled=NO;l.drawsBackground=NO;l.editable=NO;l.selectable=NO;[v addSubview:l];}ln++;

    NSSlider*ws=[[NSSlider alloc]initWithFrame:NSMakeRect(110,y-ln*30,180,24)];
    ws.minValue=200;ws.maxValue=1200;ws.doubleValue=self.winWidth;ws.target=self;
    ws.action=@selector(widthChanged:);ws.continuous=YES;[v addSubview:ws];
    {NSTextField*l=[[NSTextField alloc]initWithFrame:NSMakeRect(20,y-ln*30-2,80,20)];l.stringValue=@"窗口宽度";l.font=lf;
     l.bezeled=NO;l.drawsBackground=NO;l.editable=NO;l.selectable=NO;[v addSubview:l];}
    {NSTextField*l=[[NSTextField alloc]initWithFrame:NSMakeRect(300,y-ln*30,50,20)];
     l.stringValue=[NSString stringWithFormat:@"%.0f",self.winWidth];l.tag=11;l.font=lf;
     l.bezeled=NO;l.drawsBackground=NO;l.editable=NO;l.selectable=NO;[v addSubview:l];}ln++;

    NSSlider*hs=[[NSSlider alloc]initWithFrame:NSMakeRect(110,y-ln*30,180,24)];
    hs.minValue=100;hs.maxValue=1200;hs.doubleValue=self.winHeight;hs.target=self;
    hs.action=@selector(heightChanged:);hs.continuous=YES;[v addSubview:hs];
    {NSTextField*l=[[NSTextField alloc]initWithFrame:NSMakeRect(20,y-ln*30-2,80,20)];l.stringValue=@"窗口高度";l.font=lf;
     l.bezeled=NO;l.drawsBackground=NO;l.editable=NO;l.selectable=NO;[v addSubview:l];}
    {NSTextField*l=[[NSTextField alloc]initWithFrame:NSMakeRect(300,y-ln*30,50,20)];
     l.stringValue=[NSString stringWithFormat:@"%.0f",self.winHeight];l.tag=12;l.font=lf;
     l.bezeled=NO;l.drawsBackground=NO;l.editable=NO;l.selectable=NO;[v addSubview:l];}ln++;

    {NSTextField*l=[[NSTextField alloc]initWithFrame:NSMakeRect(20,y-ln*30-5,200,20)];l.stringValue=@"预览效果";l.font=lf;
     l.bezeled=NO;l.drawsBackground=NO;l.editable=NO;l.selectable=NO;[v addSubview:l];}ln++;
    self.previewView=[[NSTextView alloc]initWithFrame:NSMakeRect(20,20,420,y-ln*30-30)];
    self.previewView.drawsBackground=YES;
    self.previewView.backgroundColor=[self.bgColor colorWithAlphaComponent:self.bgAlpha];
    self.previewView.textColor=self.fgColor;
    self.previewView.font=[NSFont systemFontOfSize:self.fontSize];
    self.previewView.string=@"预览文字 — 颜色/字体效果";self.previewView.editable=NO;
    self.previewView.autoresizingMask=NSViewWidthSizable|NSViewHeightSizable;[v addSubview:self.previewView];
    win.contentView=v;win.releasedWhenClosed=NO;self.settingsWindow=win;[win makeKeyAndOrderFront:nil];
}
- (void)bgColorChanged:(NSColorWell*)s{self.bgColor=s.color;[self applyStyle];[self updatePreview];}
- (void)fgColorChanged:(NSColorWell*)s{self.fgColor=s.color;[self applyStyle];[self updatePreview];}
- (void)alphaChanged:(NSSlider*)s{self.bgAlpha=s.doubleValue;self.alphaValueLabel.stringValue=[NSString stringWithFormat:@"%.0f%%",self.bgAlpha*100];[self applyStyle];[self updatePreview];}
- (void)fontSizeChanged:(NSSlider*)s{self.fontSize=s.doubleValue;[[self.settingsWindow.contentView viewWithTag:10]setStringValue:[NSString stringWithFormat:@"%.0f",self.fontSize]];[self applyStyle];[self updatePreview];_currentPage=0;[self updatePage];}
- (void)widthChanged:(NSSlider*)s{self.winWidth=s.doubleValue;[[self.settingsWindow.contentView viewWithTag:11]setStringValue:[NSString stringWithFormat:@"%.0f",self.winWidth]];[self rebuildPanel];}
- (void)heightChanged:(NSSlider*)s{self.winHeight=s.doubleValue;[[self.settingsWindow.contentView viewWithTag:12]setStringValue:[NSString stringWithFormat:@"%.0f",self.winHeight]];[self rebuildPanel];}
- (void)applyStyle{self.panel.backgroundColor=[self.bgColor colorWithAlphaComponent:self.bgAlpha];self.textView.textColor=self.fgColor;self.textView.font=[NSFont monospacedSystemFontOfSize:self.fontSize weight:NSFontWeightRegular];self.hintLabel.textColor=[self.fgColor colorWithAlphaComponent:0.5];}
- (void)rebuildPanel{BOOL w=self.isVisible;[self.panel orderOut:nil];self.isVisible=NO;[self setupPanel];if(w){[self.panel orderFront:nil];self.isVisible=YES;}}
- (void)updatePreview{self.previewView.backgroundColor=[self.bgColor colorWithAlphaComponent:self.bgAlpha];self.previewView.textColor=self.fgColor;self.previewView.font=[NSFont systemFontOfSize:self.fontSize];}
- (void)windowWillClose:(NSNotification*)n{if(n.object==self.settingsWindow){self.settingsWindow=nil;[NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];[self saveConfig];}}

#pragma mark - Mouse
- (void)readerMouseEntered{}
- (void)readerMouseExited{dispatch_after(dispatch_time(DISPATCH_TIME_NOW,0.3*NSEC_PER_SEC),dispatch_get_main_queue(),^{[self tryHide];});}
- (void)checkHotZone{NSPoint l=NSEvent.mouseLocation;CGFloat mx=NSMaxX(NSScreen.mainScreen.visibleFrame),my=NSMaxY(NSScreen.mainScreen.visibleFrame);if(l.x>=mx-8&&l.y>=my-8&&!self.isVisible){[self.panel orderFront:nil];self.isVisible=YES;}}
- (void)tryHide{if(!self.isVisible||!self.panel.visible)return;NSPoint l=NSEvent.mouseLocation;NSRect wf=self.panel.frame;if(!(l.x>=wf.origin.x&&l.x<=wf.origin.x+wf.size.width&&l.y>=wf.origin.y&&l.y<=wf.origin.y+wf.size.height)){[self.panel orderOut:nil];self.isVisible=NO;}}

- (void)openFile{
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];[NSApp activateIgnoringOtherApps:YES];
    NSOpenPanel*p=[NSOpenPanel openPanel];p.canChooseFiles=YES;p.canChooseDirectories=NO;p.allowsMultipleSelection=NO;
    p.message=@"选择要阅读的文本文件";
    p.allowedFileTypes=@[@"txt",@"text",@"md",@"log",@"csv",@"json",@"xml",@"yml",@"yaml",@"ini",@"cfg",@"conf",@"py",@"js",@"ts",@"html",@"css",@"c",@"h",@"cpp",@"java",@"go",@"rs",@"sh",@"bat"];
    if([p runModal]==NSModalResponseOK)[self loadFile:p.URL.path];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
}
- (void)loadFile:(NSString*)path{
    NSError*e=nil;NSString*c=[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&e];
    if(!c){self.fullText=[NSString stringWithFormat:@"无法打开文件:\n%@",e.localizedDescription];_currentPage=0;[self updatePage];return;}
    self.fullText=c;_currentPage=0;[self addRecentFile:path];[self updatePage];
}
- (BOOL)application:(NSApplication*)sender openFile:(NSString*)filename{[self loadFile:filename];return YES;}
@end

int main(){
    @autoreleasepool{
        AppDelegate*d=[[AppDelegate alloc]init];
        NSApplication.sharedApplication.delegate=d;
        [NSApp run];
    }
    return 0;
}
