
//
//  SPNImageViewer.m
//  
//
//  Created by Vimal Das on 27/10/17.
//
//

#import "SPNImageViewer.h"
#import "SPNContentViewController.h"

@implementation SPNImageViewer
/// setup the image viewer screen
-(void)setupViews:(UIImageView *)imgView view:(UIViewController *)viewController {
    isViewing   = NO;
    sizeChanged = NO;
    isZoomed    = NO;
    mainViewController = viewController;
    mainView = viewController.view;
    imgView.userInteractionEnabled = YES;
    
    screenCenter = CGPointMake([[UIScreen mainScreen] bounds].size.width/2,
                               [[UIScreen mainScreen] bounds].size.height/2);
    screenSize = CGSizeMake([[UIScreen mainScreen] bounds].size.width,
                            [[UIScreen mainScreen] bounds].size.height);
    [self addSingleTapGesture:imgView];
    
}

/// get the viewController at a particular index
-(SPNContentViewController *)getViewControllerAtIndex: (NSInteger)index {
    if (_imageArray.count == 0) {
        return [[VDSContentViewController alloc]init];
    }
    SPNContentViewController *vc = [[SPNContentViewController alloc]init];
    vc.pageIndex = index;
    vc.createdScrollView = [[UIScrollView alloc]init];
    vc.createdImageView = [[UIImageView alloc]init];
    vc.createdImageView.image = [UIImage imageNamed:_imageArray[index]];
    vc.panView = [[UIView alloc]init];
    vc.panView.userInteractionEnabled = YES;
    if (mainViewControllerImageView == nil) {
        mainViewControllerImageView = vc.createdImageView;
    }
    if (mainViewControllerScrollView == nil) {
        mainViewControllerScrollView = vc.createdScrollView;
    }
    if (panView == nil) {
        panView = vc.panView;
    }
    [self addPanGesture:vc.panView];
    return vc;
}

/// add single tap gesture to the image viewer
-(void)addSingleTapGesture:(UIImageView *)imgView {
    singleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(singleTapAction:)];
    singleTap.numberOfTapsRequired = 1;
    [imgView addGestureRecognizer: singleTap];
}

/// create image viewer
-(UIImageView *)createAnimatedImageView {
    UIImageView *imageView = [[UIImageView alloc]init];
    imageView.userInteractionEnabled = YES;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.image = originalImageView.image;
    return imageView;
}

/// add double tap gesture to the image viewer
-(void)addDoubleTapGesture:(UIScrollView *)doubleTapView {
    doubleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTapAction:)];
    doubleTap.numberOfTapsRequired = 2;
    [doubleTapView addGestureRecognizer: doubleTap];
}

/// add pan gesture to the image viewer
-(void)addPanGesture:(UIView *)panview {
    panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panAction:)];
    [panview addGestureRecognizer: panGesture];
}

/// handle pan action in image viewer
-(void)panAction:(UIPanGestureRecognizer *)sender {
    if (!isZoomed) {
        if (sender.state == UIGestureRecognizerStateBegan ||
            sender.state == UIGestureRecognizerStateChanged) {
            
            CGPoint pan = [sender translationInView:panView];
            [mainViewControllerImageView setCenter: CGPointMake(mainViewControllerImageView.center.x, mainViewControllerImageView.center.y + pan.y)];
            panView.center = mainViewControllerImageView.center;
            [sender setTranslation:CGPointZero inView:panView];
            
            if (mainViewControllerImageView.center.y > screenCenter.y + 50 || mainViewControllerImageView.center.y < screenCenter.y - 50) {
                
                if (!sizeChanged) {
                    storePoint = mainViewControllerImageView.center;
                    [UIView animateWithDuration:0.3 animations:^{
                        animatedImageView.image = mainViewControllerImageView.image;
                        mainViewControllerImageView.frame = CGRectMake(0, 0, mainViewControllerImageView.frame.size.width/2, mainViewControllerImageView.frame.size.height/2);
                        animatedImageView.frame = mainViewControllerImageView.frame;
                        mainViewControllerImageView.center = CGPointMake(screenCenter.x, storePoint.y);
                    }];
                    sizeChanged = YES;
                }
            }

        }else {
            if (mainViewControllerImageView.center.y > screenCenter.y + 100 || mainViewControllerImageView.center.y < screenCenter.y - 100) {
                
                [panView removeFromSuperview];
                [mainViewControllerImageView removeFromSuperview];
                [mainViewControllerScrollView removeFromSuperview];
                panView = nil;
                mainViewControllerImageView = nil;
                mainViewControllerScrollView = nil;
                [self animateBackToNormal];
            } else {
                
                [UIView animateWithDuration:0.3 animations:^{
                    mainViewControllerImageView.frame = CGRectMake(0, 0, mainView.frame.size.width, mainView.frame.size.height);
                    animatedImageView.frame = mainViewControllerImageView.frame;
                    mainViewControllerImageView.center = mainViewControllerScrollView.center;
                }];
                sizeChanged = NO;
            }

        }
    }
}

/// animate back to normal
-(void)animateBackToNormal {
    [UIView animateWithDuration:0.3 animations:^{
        mainViewControllerImageView.alpha = 0;
        animatedImageView.frame = originalImageView.frame;
        animatedImageView.center = originalImageViewCenter;
    } completion:^(BOOL finished) {
        [animatedImageView removeFromSuperview];
    
    }];
    sizeChanged = NO;
    isViewing = NO;
    isZoomed = NO;
}

/// handle single tap on imageviewer
-(void)singleTapAction: (UITapGestureRecognizer *)sender {
    if (!isViewing) {
        for (UIView *view in mainView.subviews) {
            if ([view isKindOfClass:[UITableView class]]) {
                tableview = (UITableView *)view;
            }
            cellRect = tableview.visibleCells.firstObject.frame;
        }
        originalImageView = (UIImageView *)sender.view;
        tag = originalImageView.tag;
        calculatedImageViewPoint = cellRect.size.height * tag - tableview.contentOffset.y + tableview.frame.origin.y;
        animatedImageView = [self createAnimatedImageView];
        animatedImageView.image = originalImageView.image;
        animatedImageView.frame = CGRectMake(originalImageView.frame.origin.x, calculatedImageViewPoint, originalImageView.frame.size.width, originalImageView.frame.size.height);
        originalImageViewCenter = animatedImageView.center;
        [mainView addSubview: animatedImageView];
        [mainView bringSubviewToFront:animatedImageView];
        isViewing = YES;
    }
    
}

/// setup the pageViewer
-(void)setupPageViewController {
    pageViewController = [[UIPageViewController alloc]
                          initWithTransitionStyle: UIPageViewControllerTransitionStyleScroll navigationOrientation: UIPageViewControllerNavigationOrientationHorizontal options:nil];
    
    [pageViewController setDataSource:self];
    pageViewControllerScrollView = (UIScrollView *)pageViewController.view.subviews[0];
    [self addDoubleTapGesture:pageViewControllerScrollView];
    [self restartAction];
    CATransition* transition = [CATransition animation];
    transition.duration = 0.3;
    transition.type = kCATransitionFade;
    transition.subtype = kCATransitionFromBottom;
    [mainViewController.view.window.layer addAnimation:transition forKey:kCATransition];
        [mainViewController presentViewController:pageViewController animated:NO completion:nil];

}

/// restart image viewer
-(void)restartAction {
    [pageViewController setViewControllers:[NSArray arrayWithObject:[self viewControllerAtIndex:tag]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL finished) {
    }];
}

/// handle double tap action
-(void)doubleTapAction: (UITapGestureRecognizer *)sender {
    isZoomed = !isZoomed;
    
    if (isZoomed) {
        mainViewControllerScrollView.minimumZoomScale = 1;
        mainViewControllerScrollView.maximumZoomScale = 5;
        [mainViewControllerScrollView setZoomScale:2 animated:YES];
        mainViewControllerScrollView.contentSize = mainViewControllerImageView.frame.size;
        mainViewControllerImageView.frame = CGRectMake(0, 0, mainViewControllerImageView.frame.size.width, mainViewControllerImageView.frame.size.height);
        animatedImageView.frame = CGRectMake(0, 0, animatedImageView.frame.size.width, animatedImageView.frame.size.height);
        
    } else {
        mainViewControllerScrollView.minimumZoomScale = 1;
        mainViewControllerScrollView.maximumZoomScale = 1;
        [mainViewControllerScrollView setZoomScale:1 animated:YES];
        [UIView animateWithDuration:0.3 animations:^{
            animatedImageView.center = screenCenter;
        }];
    }
}

// MARK:- UIPageViewController dataSource.
// MARK: viewControllerAfterViewController
-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController{
    VDSContentViewController *vc = (VDSContentViewController *)viewController;
    NSInteger index = vc.pageIndex;
    _pageIndex = index;
    panView = vc.panView;
    mainViewControllerImageView = vc.createdImageView;
    mainViewControllerScrollView = vc.createdScrollView;
    if (index == NSNotFound) {
        return nil;
    }
    index++;
    if (index == _imageArray.count) {
        return nil;
    }
    if (isZoomed) {
        isZoomed = !isZoomed;
    }
    
    return [self viewControllerAtIndex:index];
}

// MARK: viewControllerBeforeViewController
-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController{
    VDSContentViewController *vc = (VDSContentViewController *)viewController;
    NSInteger index = vc.pageIndex;
    mainViewControllerImageView = vc.createdImageView;
    mainViewControllerScrollView = vc.createdScrollView;
    panView = vc.panView;
    _pageIndex = index;

    if (index == NSNotFound || index == 0) {
        return nil;
    }
    index--;
    if (isZoomed) {
        isZoomed = !isZoomed;
    }
    return [self viewControllerAtIndex:index];
}

@end
