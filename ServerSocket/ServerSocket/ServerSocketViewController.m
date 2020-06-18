//
//  ServerViewController.m
//  socket
//
//  Created by cherish on 2020/6/17.
//  Copyright © 2020 cherish. All rights reserved.
//

#import "ServerSocketViewController.h"
#import <GCDAsyncSocket.h>
@interface ServerSocketViewController ()<GCDAsyncSocketDelegate>

@property (nonatomic,strong) GCDAsyncSocket *serverSocket;
@property (nonatomic,strong) UITextField *portText;
@property (nonatomic,strong) NSMutableArray <GCDAsyncSocket*>*clientSockets;
@property (nonatomic,strong) UITextField *messageTextView;
@property (nonatomic,strong) NSTimer *chekcTimer;
@property (nonatomic,strong) UITextView *allMessageTextView;
@property (nonatomic,strong) NSMutableDictionary <NSString*,NSString*>*checkMap;
@property (nonatomic,assign) BOOL listenStatus;

@end

@implementation ServerSocketViewController

#pragma mark - ViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Server Socket(TCP/IP)";
    [self initData];
    [self setUp];
}

#pragma mark - Pirvate Methods
- (void)initData
{
    self.serverSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    self.clientSockets = [NSMutableArray new];
    self.checkMap = [NSMutableDictionary dictionary];
}

- (void)setUp
{
    self.portText = [[UITextField alloc]initWithFrame:CGRectMake(20, 100, self.view.frame.size.width-160, 40)];
    self.portText.placeholder = @"input the open port number";
    self.portText.textAlignment = NSTextAlignmentLeft;
    self.portText.layer.borderWidth = 0.5;
    self.portText.keyboardType = UIKeyboardTypeNumberPad;
    self.portText.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.5].CGColor;
    self.portText.layer.cornerRadius = 5.0f;
    self.portText.layer.masksToBounds = YES;
    self.portText.font = [UIFont systemFontOfSize:15.0f];
    self.portText.textColor = [UIColor blackColor];
    [self.view addSubview: self.portText];
    
    UIButton *confirm = [UIButton buttonWithType:UIButtonTypeCustom];
    [confirm setTitle:@"start listening" forState:UIControlStateNormal];
    confirm.frame = CGRectMake(self.view.frame.size.width-120, 105, 100, 30);
    [confirm setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    confirm.titleLabel.font = [UIFont systemFontOfSize:12.0f];
    confirm.titleLabel.textAlignment = NSTextAlignmentCenter;
    confirm.layer.borderColor = [UIColor blueColor].CGColor;
    confirm.layer.borderWidth = 0.5;
    confirm.layer.cornerRadius = 5.0f;
    confirm.layer.masksToBounds = YES;
    [confirm addTarget:self action:@selector(acceptPort:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:confirm];
    
    //send message
    self.messageTextView = [[UITextField alloc]initWithFrame:CGRectMake(20, self.portText.frame.origin.y+50,self.view.frame.size.width-150, 30)];
    self.messageTextView.textAlignment = NSTextAlignmentLeft;
    self.messageTextView.placeholder = @"Send a message to a client";
    self.messageTextView.font = [UIFont systemFontOfSize:15.0f];
    self.messageTextView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.messageTextView.layer.borderWidth = 0.5;
    self.messageTextView.layer.cornerRadius = 5.0f;
    self.messageTextView.layer.masksToBounds = YES;
    [self.view addSubview:self.messageTextView];
    
    //
    UIButton *postBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    postBtn.frame = CGRectMake(self.view.frame.size.width-100, self.portText.frame.origin.y+50, 80, 30);
    [postBtn setTitle:@"send" forState:UIControlStateNormal];
    [postBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    postBtn.titleLabel.font = [UIFont systemFontOfSize:12.0f];
    postBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    postBtn.layer.borderColor = [UIColor blueColor].CGColor;
    postBtn.layer.borderWidth = 0.5;
    postBtn.layer.cornerRadius = 5.0f;
    postBtn.layer.masksToBounds = YES;
    [postBtn addTarget:self action:@selector(postMessageToClient:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:postBtn];
    
    self.allMessageTextView = [[UITextView alloc]initWithFrame:CGRectMake(20, self.messageTextView.frame.origin.y+50, self.view.frame.size.width-40, 200)];
    self.allMessageTextView.textAlignment = NSTextAlignmentLeft;
    self.allMessageTextView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.1];
    self.allMessageTextView.layer.cornerRadius = 5.0f;
    self.allMessageTextView.layer.masksToBounds = YES;
    self.allMessageTextView.textColor = [UIColor blackColor];
    self.allMessageTextView.text = @"The status of all messages is displayed here \n";
    self.allMessageTextView.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:self.allMessageTextView];
    
    
}

- (void)addCheckTimer
{
    self.chekcTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(checkLongConnect:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.chekcTimer forMode:NSRunLoopCommonModes];
}

- (NSString*)getCurrentTime
{
    return [NSString stringWithFormat:@"%ld",(long)[[NSDate date] timeIntervalSince1970]];
}

#pragma mark - Action Methods
- (void)acceptPort:(UIButton*)sender
{
    if (!self.listenStatus) {
        NSError *error = nil;
        BOOL result = [self.serverSocket acceptOnPort:self.portText.text.integerValue error:&error];
        if (result && !error) {
            self.allMessageTextView.text = [self.allMessageTextView.text stringByAppendingString:[NSString stringWithFormat:@"\nPort number %@ is open. start listening \n",self.portText.text]];
            self.listenStatus = YES;
            self.portText.userInteractionEnabled = sender.userInteractionEnabled = NO;
        }else{
           self.portText.userInteractionEnabled = sender.userInteractionEnabled = YES;
        }
    }
}

- (void)postMessageToClient:(UIButton*)sender
{
    if (self.clientSockets.count>0 && self.messageTextView.text.length>0) {
    NSData *data = [self.messageTextView.text dataUsingEncoding:NSUTF8StringEncoding];
    [self.clientSockets enumerateObjectsUsingBlock:^(GCDAsyncSocket * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj writeData:data withTimeout:-1 tag:0];
    }];
    }
}//给所有客户端发送消息

- (void)checkLongConnect:(NSTimer*)timer
{
    [self.checkMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *currentTimeStr = [self getCurrentTime];
        if (currentTimeStr.doubleValue - [obj doubleValue] >=10) {
             //disconnect
            [self.checkMap removeObjectForKey:key];
        }else{
            NSLog(@"%@ in bad shape = overtime:%.2f",key,currentTimeStr.doubleValue - [obj doubleValue]);
        }
    }];
}

#pragma mark - GCDAsyncSocket Delegate
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(nonnull GCDAsyncSocket *)newSocket
{
    BOOL isExist = NO;
    for (GCDAsyncSocket *item in self.clientSockets) {
        if ([item.connectedHost isEqualToString:newSocket.connectedHost] && item.connectedPort == newSocket.connectedPort) {
            isExist = YES;
            break;
        }
    }
    if (!isExist) {
        [self.clientSockets addObject:newSocket];
        self.allMessageTextView.text = [self.allMessageTextView.text stringByAppendingString:[NSString stringWithFormat:@"\n client address: %@ -- ports: %d \n", newSocket.connectedHost, newSocket.connectedPort]];
    }
    [self addCheckTimer];
    [newSocket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *content = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    self.allMessageTextView.text = [self.allMessageTextView.text stringByAppendingString:[NSString stringWithFormat:@"\n A message from %@ => %@ \n",sock.connectedHost,content]];
    [sock readDataWithTimeout:-1 tag:0];
}



@end

