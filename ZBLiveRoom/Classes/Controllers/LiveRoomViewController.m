//
//  LiveRoomViewController.m
//  ZBLiveRoom
//
//  Created by Suzhibin on 2020/4/15.
//  Copyright © 2020 Suzhibin. All rights reserved.
//

#import "LiveRoomViewController.h"
#import <Masonry/Masonry.h>
#import <SuperPlayer/SuperPlayer.h>
#import "ChatInputBoardView.h"
#import "ChatRoomSystemMessageCell.h"
#import "ChatRoomTextMessageCell.h"
#import "Macro.h"
#import "YYWeakProxy.h"
#import "UIImageView+WebCache.h"
#import "OCBarrage.h"
#import <pthread/pthread.h>
#import "ZBChatRoomView.h"
#import "NDGiftAnimation.h"
#import <YYModel/YYModel.h>
#import "ChatRoomGiftModel.h"
@interface LiveRoomViewController ()<ChatInputBoardViewDelegate,SuperPlayerDelegate>
@property (nonatomic,strong) ChatInputBoardView *inputView;//聊天框
@property (nonatomic) UIView *playerFatherView;//播放器父view
@property (strong, nonatomic) SuperPlayerView *playerView;//播放器
@property (strong, nonatomic) ZBChatRoomView *chatRoomView;

@property (nonatomic, strong) NSTimer *refreshTimer;
@property (nonatomic, assign) NSInteger page;
@property (nonatomic, strong)OCBarrageManager *barrageManager;
@property (nonatomic, strong) NDGiftAnimation *giftAnimation;
@property (nonatomic, assign) NSInteger isBarrage;
@end

@implementation LiveRoomViewController
- (void)dealloc{
    NSLog(@"释放%s",__func__);
    [_playerView resetPlayer];//销毁播放器
    [self stopTimer];//销毁倒计时
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
 
}
- (ZBChatRoomView *)chatRoomView {
    if(!_chatRoomView){
        _chatRoomView = [[ZBChatRoomView alloc] init];
        //_chatRoom.delegate = self;
        _chatRoomView.reloadType = self.mesType;
    }
    return _chatRoomView;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor=[UIColor whiteColor];
    [self createaPlayerView];
    [self startPlay];
    [self createAddDataBtn];
    [self createBarrageBtn];
    
    [self.view addSubview:self.chatRoomView];
    [self.chatRoomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_playerFatherView.mas_bottom).offset(10);
        make.left.right.equalTo(@(0));
        make.bottom.equalTo(self.view.mas_bottom).offset(-(ChatKeyBoardInputViewH+safeAreaBottomHeight));
    }];
    
    [self createInputBoardView];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //延时为了获取self.chatRoomView.frame
        self.giftAnimation = [[NDGiftAnimation alloc] initWithView:self.view frame:CGRectMake(0, self.chatRoomView.frame.origin.y, 160, 30)];
    });
    _page=0;
    _isBarrage=NO;
  
    
}
- (ChatRoomMessageModel *)creatTestMessage{
   NSDictionary *dict= _conmentAry[arc4random() % _conmentAry.count];
    ChatRoomMessageModel *msgModel = [ChatRoomMessageModel yy_modelWithDictionary:dict];
    msgModel.user.name= _nameAry[arc4random() % _nameAry.count];
    [msgModel initMsgAttribute];
    return  msgModel;
}
#pragma mark - inputViewDelegate 发送消息
- (void)chatKeyInputBoardView:(ChatInputBoardView *)inputBoardView messageText:(NSString *)messageText{
    ChatRoomMessageModel *msgModel = [[ChatRoomMessageModel alloc]init];
    msgModel.mesType = 1;
    ChatRoomUserModel *userModel=[[ChatRoomUserModel alloc]init];
    userModel.name=@"大锤兄弟";
    userModel.userId=@"10099";
    msgModel.user=userModel;
    msgModel.content=messageText;
    [msgModel initMsgAttribute];
   
    NSString *str= [NSString stringWithFormat:@"%@:%@",msgModel.user.name,msgModel.content];
    [self sendbarrage:str ismember:YES];
    [self.chatRoomView sendChatRoomMessage:msgModel];
    inputBoardView.content=@"";
}
#pragma mark - 礼物事件
- (void)sendBtn_Action:(UIButton *)sender{
//    ChatRoomGiftModel *giftModel=[[ChatRoomGiftModel alloc]init];
//    giftModel.giftID=@"GiftID_10001";
//    giftModel.giftName = @"礼物_飞机";
//    giftModel.duration=[NSNumber numberWithInteger:arc4random() % 2000 + 2000];
    NDGiftModel *showGift = [NDGiftModel new];
    showGift.userId = @"10099";
    showGift.userName=@"大锤兄弟";
 
    showGift.duration=[NSNumber numberWithInteger:8000 + 2000];
    showGift.giftId=@"10000";
    showGift.giftName=@"大宝剑";
    showGift.giftImageName=@"gift_icon_0";
    showGift.giftCount =1;
    [_giftAnimation receivedGift:showGift];
}
#pragma mark - 播放视频
- (void)startPlay{
    /* 播放前可以做移动网络提示
    if (不是WiFi) {
     //搭建移动提示ui
    }else{
     //播放
    }
     */
    SuperPlayerModel *playerModel = [[SuperPlayerModel alloc] init];
    /**
     坑一
     模拟器播放 flv格式 画面红色，有声音，真机没有问题。
     因为SuperPlayerViewConfig 内的hwAcceleration 方法 ，模拟器默认硬解码为默认 NO造成的 ，
    坑二
    模拟器 播放视频 帧数很低 20-30fps吧 使用真机正常 基本57-60fps
     */
    playerModel.videoURL=@"http://5815.liveplay.myqcloud.com/live/5815_89aad37e06ff11e892905cb9018cf0d4_900.flv";
   // playerModel.videoURL=@"http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/28742df34564972819219071568/master_playlist.m3u8";
    [_playerView.coverImageView sd_setImageWithURL:[NSURL URLWithString:@"http://1252463788.vod2.myqcloud.com/e12fcc4dvodgzp1252463788/28742df34564972819219071568/4564972819209692959.jpeg"]];
    [_playerView playWithModel:playerModel];
}
#pragma mark - 播放器代理 SuperPlayerDelegate
- (void)superPlayerDidStart:(SuperPlayerView *)player{/// 播放开始通知
    self.isBarrage=YES;
    [self startRefreshData];
}
- (void)superPlayerDidEnd:(SuperPlayerView *)player{/// 播放结束通知
    [self.barrageManager stop];
}
- (void)superPlayerError:(SuperPlayerView *)player errCode:(int)code errMessage:(NSString *)why{/// 播放错误通知
}
- (void)superPlayerFullScreenChanged:(SuperPlayerView *)player{/// 全屏改变通知  刷新状态栏
    if(player.isFullScreen){
        self.chatRoomView.inPending=YES;
        SPDefaultControlView *controlView = (SPDefaultControlView *)player.controlView;
        controlView.moreBtn.hidden = YES;
        controlView.captureBtn.hidden = YES;
        controlView.danmakuBtn.hidden = YES;
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }else{
        self.chatRoomView.inPending=NO;
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
}
- (void)superPlayerBackAction:(SuperPlayerView *)player{///返回
    [self exitViewController];
}
- (void)exitViewController{
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}
#pragma mark - 屏幕旋转
- (BOOL)shouldAutorotate {// 返回值要必须为NO
    return NO;
}
- (BOOL)prefersStatusBarHidden {
    return self.playerView.isFullScreen;
}
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}
#pragma mark - 创建播放器
- (void)createaPlayerView{
    _playerView = [[SuperPlayerView alloc] init];
    _playerView.delegate = self;
    _playerView.playerConfig.enableLog=NO;
    self.playerFatherView = [[UIView alloc] init];
    self.playerFatherView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.playerFatherView];
    [self.playerFatherView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        } else {
            make.top.mas_equalTo(20+self.navigationController.navigationBar.bounds.size.height);
        }
        make.leading.trailing.mas_equalTo(0);
        make.height.mas_equalTo(self.playerFatherView.mas_width).multipliedBy(9.0f/16.0f);// 这里宽高比16：9,可自定义宽高比
    }];
    _playerView.fatherView =_playerFatherView;// 设置父 View，_playerView 会被自动添加到 holderView 下面
    [self.playerView addSubview:self.barrageManager.renderView];
    [self.playerView sendSubviewToBack:self.barrageManager.renderView];//防止挡住控制层
    [self.barrageManager.renderView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.playerView);
        make.top.equalTo(@(20));
        make.bottom.equalTo(self.playerView.mas_bottom).offset(-20);
    }];
}
#pragma mark - 创建输入框
- (void)createInputBoardView{
    _inputView =[[ChatInputBoardView alloc]init];
    _inputView.maxFontNum = 100;
    _inputView.placeHolder=@"输入聊天内容";
    _inputView.delegate = self;
    [_inputView.sendBtn setTitle:@"礼物" forState:UIControlStateNormal];
    [_inputView.sendBtn addTarget:self action:@selector(sendBtn_Action:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_inputView];
}

#pragma mark - 创建添加数据按钮
- (void)createAddDataBtn{
    UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [addBtn setFrame:CGRectMake(0, 0, 60, 44)];
    addBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [addBtn setTitle:@"暂停数据" forState:UIControlStateNormal];
    [addBtn setTitle:@"添加数据" forState:UIControlStateSelected];
    [addBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [addBtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    addBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [addBtn addTarget:self action:@selector(addBtn_Action:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem * leftBtnItem =[[UIBarButtonItem alloc] initWithCustomView: addBtn];
    self.navigationItem.leftBarButtonItem=leftBtnItem;
}
#pragma mark - 创建弹幕开关按钮
- (void)createBarrageBtn{
    UIButton *barrageBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [barrageBtn setFrame:CGRectMake(0, 0, 60, 44)];
    barrageBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [barrageBtn setTitle:@"关闭弹幕" forState:UIControlStateNormal];
    [barrageBtn setTitle:@"开启弹幕" forState:UIControlStateSelected];
    [barrageBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [barrageBtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    barrageBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [barrageBtn addTarget:self action:@selector(barrageBtn_Action:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem * rightBtnItem =[[UIBarButtonItem alloc] initWithCustomView: barrageBtn];
    self.navigationItem.rightBarButtonItem=rightBtnItem;
}
#pragma mark - 添加测试数据事件
- (void)addBtn_Action:(UIButton *)sender{
    sender.selected=!sender.selected;
    if (sender.selected==YES) {
        [self stopTimer];
    }else{
        [self startRefreshData];
    }
}
- (void)startRefreshData {
    [self.barrageManager start];
    if (self.refreshTimer) {
        return;
    }
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:[YYWeakProxy proxyWithTarget:self] selector:@selector(timerEvent) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.refreshTimer forMode:NSRunLoopCommonModes];
}
- (void)stopTimer {
    if (self.refreshTimer) {
        [self.refreshTimer invalidate];
        self.refreshTimer=nil;
    }
}
- (void)timerEvent{
    _page++;
    ChatRoomMessageModel *msgModel=[self creatTestMessage];
    if (msgModel.mesType==1&&self.isBarrage==YES) {
         NSString *str= [NSString stringWithFormat:@"%@:%@",msgModel.user.name,msgModel.content];
        [self sendbarrage:str ismember:NO];
    }
    if (msgModel.mesType==4) {
        if (msgModel.user.name==_nameAry[arc4random() % _nameAry.count]) {
            NDGiftModel *showGift = [NDGiftModel new];
            showGift.userId = msgModel.user.userId;
            showGift.userName=msgModel.user.name;
            showGift.duration=[NSNumber numberWithInteger:10000];
            showGift.giftId=msgModel.gift.giftId;
            showGift.giftName=msgModel.gift.giftName;
            showGift.giftImageName=msgModel.gift.giftImageName;
            showGift.giftCount =1;
            [_giftAnimation receivedGift:showGift];
        }
    }else{
        [self.chatRoomView sendChatRoomMessage:msgModel];
    }
}
#pragma mark - 配置弹幕
- (void)sendbarrage:(NSString *)str ismember:(BOOL)member{
     OCBarrageTextDescriptor *textDescriptor = [[OCBarrageTextDescriptor alloc] init];
     textDescriptor.text = str;
     textDescriptor.textColor = kRandomColor;
//    CGFloat bannerHeight = 185.0/2.0;
     textDescriptor.renderRange = NSMakeRange(0,100);
    if (member==YES) {
        textDescriptor.positionPriority = OCBarragePositionMiddle;
        textDescriptor.textFont = [UIFont systemFontOfSize:20];
    }else{
        textDescriptor.positionPriority = OCBarragePositionLow;
        textDescriptor.textFont = [UIFont systemFontOfSize:14];
    }
    
     textDescriptor.strokeColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
     textDescriptor.strokeWidth = -1;
     textDescriptor.animationDuration = arc4random()%5 + 10;
     textDescriptor.barrageCellClass = [OCBarrageTextCell class];
    self.barrageManager.renderView.renderPositionStyle=OCBarrageRenderPositionIncrease;
     [self.barrageManager renderBarrageDescriptor:textDescriptor];
}
#pragma mark - 弹幕开关事件
- (void)barrageBtn_Action:(UIButton *)sender{
    sender.selected=!sender.selected;
    if (sender.selected) {
        [self.barrageManager stop];
    } else {
        [self.barrageManager start];
    }
}

- (OCBarrageManager *)barrageManager{
    if (!_barrageManager) {
         _barrageManager = [[OCBarrageManager alloc] init];
        _barrageManager.renderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _barrageManager;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
