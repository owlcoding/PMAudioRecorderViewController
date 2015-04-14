//
//  AudioNoteRecordedViewController.m
//
//  Created by Pawel Maczewski on 29/01/14.
//

#import "UIImage+BlurredFrame.h"

#import "AudioNoteRecorderViewController.h"

@interface AudioNoteRecorderViewController ()
@property (nonatomic, strong) UIImageView *background;

@property (nonatomic, strong) UIButton *play;
@property (nonatomic, strong) UIButton *record;
@property (nonatomic, strong) UILabel *recordLengthLabel;

@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) NSTimer *recordingTimer;
@property (nonatomic, strong) UIView *controlsBg;
@end

@implementation AudioNoteRecorderViewController

#pragma mark - public methods
+ (id) showRecorderMasterViewController:(UIViewController *)masterViewController withFinishedBlock:(AudioNoteRecorderFinishBlock)finishedBlock
{
    AudioNoteRecorderViewController *avc = [[AudioNoteRecorderViewController alloc] initWithMasterViewController:masterViewController];
    avc.finishedBlock = finishedBlock;
    [masterViewController presentViewController:avc animated:YES completion:nil];
    return avc;
}
+ (id) showRecorderWithMasterViewController:(UIViewController *)masterViewController withDelegate:(id<AudioNoteRecorderDelegate>)delegate
{
    AudioNoteRecorderViewController *avc = [[AudioNoteRecorderViewController alloc] initWithMasterViewController:masterViewController];
    avc.delegate = delegate;
    [masterViewController presentViewController:avc animated:YES completion:nil];
    return avc;
}

- (id) initWithMasterViewController:(UIViewController *) masterViewController
{
    self = [super init];
    if (self) {
        // make screenshot
        CGSize imageSize = CGSizeMake(masterViewController.view.window.bounds.size.width, masterViewController.view.window.bounds.size.height);
        UIGraphicsBeginImageContext(imageSize);
        [masterViewController.view.window.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        self.background = [[UIImageView alloc] initWithImage:[viewImage applyDarkEffectAtFrame:masterViewController.view.window.frame]];
        [self.view addSubview:_background];
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}
- (void) viewDidAppear:(BOOL)animated
{

    // create the controls
    CGFloat height = 240.f;
    CGFloat barHeight = 30.0f;
    
    self.controlsBg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, height)];
    UIView *topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, barHeight)];
    // buttons
    UIButton *done = [UIButton buttonWithType:UIButtonTypeCustom];
    [done setTitle:NSLocalizedString(@"Done",) forState:UIControlStateNormal];
    UIButton *cancel = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancel setTitle:NSLocalizedString(@"Cancel",) forState:UIControlStateNormal];
    [cancel addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    [done addTarget:self action:@selector(done:) forControlEvents:UIControlEventTouchUpInside];
    [done sizeToFit];
    [cancel sizeToFit];
    done.frame = CGRectMake(10, 5, done.frame.size.width, barHeight - 2*5);
    cancel.frame = CGRectMake(self.view.frame.size.width - 10 - cancel.frame.size.width, 5, cancel.frame.size.width, barHeight - 2*5);
    [topBar addSubview:done];
    [topBar addSubview:cancel];
    
    // gray background for the controls
    UIView *bg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, height)];
    [bg setBackgroundColor:[UIColor blackColor]];
    bg.alpha = 0.3;
    [_controlsBg addSubview:bg];
    [_controlsBg addSubview:topBar];
    
    _controlsBg.frame = CGRectMake(0, self.view.frame.size.height - _controlsBg.frame.size.height, _controlsBg.frame.size.width, _controlsBg.frame.size.height);

    [self.view addSubview:_controlsBg];
    
    
    // recording controls...
    self.recordLengthLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, barHeight + 10, self.view.frame.size.width - 20, 20)];
    [_controlsBg addSubview:_recordLengthLabel];
    _recordLengthLabel.textAlignment = NSTextAlignmentCenter;
    
    self.record = [UIButton buttonWithType:UIButtonTypeCustom];
    [_record setImage:[UIImage imageNamed:@"record.png"] forState:UIControlStateNormal];
    [_record setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateSelected];
    _record.frame = CGRectMake(0, 0, 100, 100);
    _record.center = CGPointMake(10 + _record.frame.size.width / 2, 0.5 * (height - barHeight) + barHeight );
    
    self.play = [UIButton buttonWithType:UIButtonTypeCustom];
    [_play setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
    [_play setImage:nil forState:UIControlStateDisabled];
//    [_play setTitleColor:[UIColor clearColor] forState:UIControlStateDisabled];
    _play.frame = CGRectMake(0, 0, 100, 100);
    _play.center = CGPointMake(self.view.frame.size.width - 10 - _play.frame.size.width / 2, 0.5 * (height - barHeight) + barHeight );
    _play.enabled = NO;
    [_controlsBg addSubview:_record];
    [_controlsBg addSubview:_play];
    
    // actions
    [_record addTarget:self action:@selector(recordTap:) forControlEvents:UIControlEventTouchUpInside];
    [_play addTarget:self action:@selector(playTap:) forControlEvents:UIControlEventTouchUpInside];
    
    
    _controlsBg.center = CGPointMake(_controlsBg.center.x, _controlsBg.center.y + self.view.frame.size.height);
    [UIView animateWithDuration:0.5f animations:^{
        _controlsBg.center = CGPointMake(_controlsBg.center.x, _controlsBg.center.y - self.view.frame.size.height);
    }];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - actions
- (void) cancel :(UIButton *)sender
{
    if (_recorder == nil || _recorder.isRecording == NO) {
        [UIView animateWithDuration:0.5 animations:^{
            _controlsBg.center = CGPointMake(_controlsBg.center.x, _controlsBg.center.y + self.view.frame.size.height);
        } completion:^(BOOL finished) {
            [self dismissViewControllerAnimated:YES completion:^{
                if (self.delegate) {
                    [self.delegate audioNoteRecorderDidCancel:self];
                }
                if (self.finishedBlock) {
                    self.finishedBlock ( NO, nil );
                }
            }];
        }];
    }
}
- (void) done:(UIButton *) sender
{
    if (_recorder && _recorder.isRecording == NO) {

        [UIView animateWithDuration:0.5 animations:^{
            _controlsBg.center = CGPointMake(_controlsBg.center.x, _controlsBg.center.y + self.view.frame.size.height);
        } completion:^(BOOL finished) {
            [self dismissViewControllerAnimated:YES completion:^{
                if (self.delegate) {
                    [self.delegate audioNoteRecorderDidTapDone:self withRecordedURL:_recorder.url];
                }
                if (self.finishedBlock) {
                    self.finishedBlock ( YES, _recorder.url );
                }
            }];
        }];
    }
}
- (void) recordTap:(UIButton *) sender
{
    if (sender.selected) {
        // stop
        [self.recorder stop];
        _play.enabled = YES;
        [self.recordingTimer invalidate];
        self.recordingTimer = nil;
        NSLog(@"%@", self.recorder.url);
    } else {
        // start
        _play.enabled = NO;
//        NSURL *tmp = [NS]
        
        if (self.recorderSettings == nil) {
            self.recorderSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithInt:kAudioFormatAppleIMA4],AVFormatIDKey,
                                     [NSNumber numberWithInt:44100],AVSampleRateKey,
                                     [NSNumber numberWithInt:1],AVNumberOfChannelsKey,
                                     [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                                     [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                                     [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                     nil];
        }
        if (self.fileExtension == nil) {
            self.fileExtension = @"caf";
        }
        
        NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString] ;
        NSString *uniqueFileName = [NSString stringWithFormat:@"%@.%@", guid, self.fileExtension];
        NSError* error = nil;
        self.recorder = [[AVAudioRecorder alloc]
                         initWithURL:[NSURL URLWithString:[NSTemporaryDirectory() stringByAppendingPathComponent:uniqueFileName]]
                         settings:self.recorderSettings
                         error:&error];
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error: nil];
        [[AVAudioSession sharedInstance] setActive: YES error: nil];
        UInt32 doChangeDefault = 1;
        AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof(doChangeDefault), &doChangeDefault);
        
        self.recorder.delegate = self;
        [self.recorder record];
        self.recordingTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(recordingTimerUpdate:) userInfo:nil repeats:YES];
        [_recordingTimer fire];
    }
    sender.selected = !sender.selected;
    
}
- (void) playTap:(UIButton *) sender
{
//    [SimpleAudioPlayer playFile:_recorder.url.description];
    NSError* error = nil;

    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:_recorder.url error:&error];
    _player.volume = 1.0f;
    _player.numberOfLoops = 0;
    _player.delegate = self;
    [_player play];
    NSLog(@"duration: %f", _player.duration);
}
- (void) recordingTimerUpdate:(id) sender
{
    NSLog(@"%f %@", _recorder.currentTime, sender);
    self.recordLengthLabel.text = [NSString stringWithFormat:@"%.2f", _recorder.currentTime];
}


- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"did finish playing %d", flag);
}

@end
