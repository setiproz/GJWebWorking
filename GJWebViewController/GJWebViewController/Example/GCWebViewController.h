//
//  ViewController.h
//  GJWebViewController
//
//  Created by Alien on 16/5/24.
//  Copyright © 2016年 Alien. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GJWebViewController.h"
@interface GCWebViewController : UIViewController
@property (nonatomic ,copy, readwrite) NSString *bgLabelText;
@property (weak, nonatomic) IBOutlet UIView *customNavgationBar;
@end

