//
//  ViewController.m
//  AudioNoteRecorderDemo
//
//  Created by Pawel Maczewski on 29/01/14.
//  Copyright (c) 2014 OwlCoding. All rights reserved.
//

#import "ViewController.h"
#import "AudioNoteRecorderViewController.h"
@interface ViewController ()
@property (strong, nonatomic) IBOutlet UILabel *urlLabel;
- (IBAction)recordTap:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)recordTap:(id)sender {
    [AudioNoteRecorderViewController showRecorderMasterViewController:self withFinishedBlock:^(BOOL wasRecordingTaken, NSURL *recordingURL) {
        if (wasRecordingTaken) {
            self.urlLabel.text = [recordingURL absoluteString];
        }
    }];
}
@end
