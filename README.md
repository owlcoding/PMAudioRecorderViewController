PMAudioRecorderViewController
=============================

Drop-in class to record audio note in iOS application and get it back in the app. 

Usage
-----

Instalation: 

    pod 'PMAudioRecorderViewController'

or drop the contents of `AudioNoteRecorderViewController` directory in your XCode project.

In the code:

    #import "AudioRecorderViewController"
    ...
    [AudioNoteRecorderViewController showRecorderMasterViewController:self withFinishedBlock:^(BOOL wasRecordingTaken, NSURL *recordingURL) {
        if (wasRecordingTaken) {
            // do whatever you want with that URL to the .caf file
        }
    }];

Or, to have it more customisable:

    NSDictionary *recorderSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithInt:kAudioFormatAppleIMA4],AVFormatIDKey,
                                [NSNumber numberWithInt:44100],AVSampleRateKey, 
                                [NSNumber numberWithInt:1],AVNumberOfChannelsKey,
                                [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                                [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey, 
                                [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                nil];

    [AudioNoteRecorderViewController showRecorderMasterViewController:self 
                                                withRecorderSettings:recorderSettings
                                                withFileExtension:@"caf"
                                                withFinishedBlock:^(BOOL wasRecordingTaken, NSURL *recordingURL) {
        if (wasRecordingTaken) {
            // do whatever you want with that URL to the .caf file
        }
    }];

Author
------

(C) Paweł Mączewski, kender@codingslut.com, Twitter: http://twitter.com/pawelmaczewski. 