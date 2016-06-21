//
//  ViewController.h
//  MoonStoneStreamer
//
//  Created by duskash on 16/3/31.
//  Copyright © 2016年 duskash. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property(nonatomic,retain)IBOutlet UITextField* tiptext;
@property(nonatomic,retain)IBOutlet UIButton* connectbtn;
@property(nonatomic,retain)IBOutlet UISlider* sliderbtn;
@property(nonatomic,retain)IBOutlet UILabel* labText;
@property(nonatomic,retain)IBOutlet UILabel* labNetwork;
-(IBAction)streamConnect:(id)sender;

-(IBAction)camaraToggle:(id)sender;
-(IBAction)FilterClick:(id)sender;
-(IBAction)TorchClick:(id)sender;
@end

