//
//  FSSyncSpinner.h
//  Pods
//
//  Created by Wenchao Ding on 3/8/15.
//
//

#import <UIKit/UIKit.h>

@interface FSSyncSpinner : UIView

@property (strong, nonatomic) UIColor *colorOfSuccess;
@property (strong, nonatomic) UIColor *colorOfFailure;

@property (assign, nonatomic) BOOL hidesWhenFinished;
@property (assign, nonatomic) BOOL showsArrows;

- (void)startAnimating;
- (void)finishWithSuccess:(BOOL)success;

@end
