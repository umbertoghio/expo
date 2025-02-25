#import <Foundation/Foundation.h>
#import <ABI45_0_0React/ABI45_0_0RCTViewManager.h>

NS_ASSUME_NONNULL_BEGIN

@interface ABI45_0_0RCTOnPageScrollStateChanged : NSObject <ABI45_0_0RCTEvent>

- (instancetype) initWithABI45_0_0ReactTag:(NSNumber *)ABI45_0_0ReactTag
                            state:(NSString *)state
                    coalescingKey:(uint16_t)coalescingKey;

@end

NS_ASSUME_NONNULL_END
