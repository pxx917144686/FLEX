






#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger, UCClassSearchMode) {
    UCClassSearchModeClassDump = 0,  
    UCClassSearchModeDisassembler,   
};

@interface UCClassSearchViewController : UIViewController


@property (nonatomic, assign) UCClassSearchMode searchMode;


+ (instancetype)searchViewControllerWithMode:(UCClassSearchMode)mode;

@end

NS_ASSUME_NONNULL_END
