//
//  ViewController.m
//  Example
//
//  Created by HCW on 16/4/25.
//  Copyright © 2016年 HCW. All rights reserved.
//

#import "ViewController.h"
#import "UIImageView+WebCache.h"
#import "HCWPhotoBrowser.h"

@interface ViewController ()
@property (nonatomic, strong) NSArray *imageURLs;
@property (nonatomic, strong) NSMutableArray *imageViews;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageViews = [NSMutableArray new];
    
    self.imageURLs = @[@"http://img.sccnn.com/bimg/311/011.jpg",
                       @"http://pic9.nipic.com/20100826/4376639_180752159879_2.jpg",
                       @"http://pic21.nipic.com/20120425/7156172_111847620387_2.jpg",
                       @"http://pic8.nipic.com/20100722/2194093_140126005826_2.jpg",
                       @"http://img3.redocn.com/20110418/20110415_9e86967f4b28360e5afbHmybhr1LpDJ5.jpg",
                       @"http://pic10.nipic.com/20101026/4690416_135348005709_2.jpg",
                       ];
    
    
    // image group
    
    NSInteger line = 0, row = 0, lineNumber = 3;
    CGFloat imageWitdh = 60;
    for (int i=0; i<self.imageURLs.count; i++) {
        
        if (row % lineNumber == 0) {
            row = 0;
            line ++;
        }
        
        CGFloat x = row * (imageWitdh+10);
        CGFloat y = line * (imageWitdh+10);
        
        UIImageView *thumb = [[UIImageView alloc] initWithFrame:CGRectZero];
        thumb.tag = i+1;
        thumb.clipsToBounds = YES;
        thumb.contentMode = UIViewContentModeScaleAspectFill;
        thumb.userInteractionEnabled = YES;
        [thumb addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectThumb:)]];
        [self.view addSubview:thumb];
        
        [thumb sd_setImageWithURL:[NSURL URLWithString:self.imageURLs[i]]];
        [self.imageViews addObject:thumb];
        
        thumb.frame = CGRectMake(x+50, y, imageWitdh, imageWitdh);
        row += 1;
    }
    
}

- (void)selectThumb:(UITapGestureRecognizer *)sender
{
    NSInteger selectIndex = sender.view.tag-1;
    
    NSMutableArray *photoModels = [NSMutableArray arrayWithCapacity:self.imageURLs.count];
    for (int i=0; i< self.imageURLs.count; i++) {
        HCWPhotoModel *model = [HCWPhotoModel new];
        model.largeImageURL = [NSURL URLWithString:self.imageURLs[i]];
        model.thumbView = self.imageViews[i];
        [photoModels addObject:model];
    }
    
    HCWPhotoBrowser *photoBrowser = [[HCWPhotoBrowser alloc] initWithPhotoModels:photoModels];
    [photoBrowser presentFromImageView:sender.view toContainer:self.view animated:YES completion:nil];
}

@end
