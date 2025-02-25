// Copyright 2019-present 650 Industries. All rights reserved.

#import <ABI45_0_0ExpoModulesCore/ABI45_0_0EXAppLifecycleService.h>
#import <ABI45_0_0ExpoModulesCore/ABI45_0_0EXDefines.h>
#import <ABI45_0_0ExpoModulesCore/ABI45_0_0EXEventEmitterService.h>
#import <ABI45_0_0ExpoModulesCore/ABI45_0_0EXModuleRegistryProvider.h>

#import <ABI45_0_0EXScreenOrientation/ABI45_0_0EXScreenOrientationModule.h>
#import <ABI45_0_0EXScreenOrientation/ABI45_0_0EXScreenOrientationUtilities.h>
#import <ABI45_0_0EXScreenOrientation/ABI45_0_0EXScreenOrientationRegistry.h>

#import <UIKit/UIKit.h>

static NSString *const ABI45_0_0EXScreenOrientationDidUpdateDimensions = @"expoDidUpdateDimensions";

@interface ABI45_0_0EXScreenOrientationModule ()

@property (nonatomic, weak) ABI45_0_0EXScreenOrientationRegistry *screenOrientationRegistry;
@property (nonatomic, weak) id<ABI45_0_0EXEventEmitterService> eventEmitter;

@end

@implementation ABI45_0_0EXScreenOrientationModule

ABI45_0_0EX_EXPORT_MODULE(ExpoScreenOrientation);

-(void)dealloc
{
  [self stopObserving];
  [_screenOrientationRegistry moduleWillDeallocate:self];
}

- (void)setModuleRegistry:(ABI45_0_0EXModuleRegistry *)moduleRegistry
{
  _screenOrientationRegistry = [moduleRegistry getSingletonModuleForName:@"ScreenOrientationRegistry"];
  [[moduleRegistry getModuleImplementingProtocol:@protocol(ABI45_0_0EXAppLifecycleService)] registerAppLifecycleListener:self];
  _eventEmitter = [moduleRegistry getModuleImplementingProtocol:@protocol(ABI45_0_0EXEventEmitterService)];

  // TODO: This shouldn't be here, but it temporarily fixes
  // https://github.com/expo/expo/issues/13641 and https://github.com/expo/expo/issues/11558
  // We're going to redesign this once we drop support for multiple apps being open in Expo Go at the same time.
  // Then we probably won't need the screen orientation registry at all. (@tsapeta)
  [self onAppForegrounded];
}

ABI45_0_0EX_EXPORT_METHOD_AS(lockAsync,
                    lockAsync:(NSNumber *)orientationLock
                    resolver:(ABI45_0_0EXPromiseResolveBlock)resolve
                    rejecter:(ABI45_0_0EXPromiseRejectBlock)reject)
{
  UIInterfaceOrientationMask orientationMask = [ABI45_0_0EXScreenOrientationUtilities importOrientationLock:orientationLock];
  
  if (!orientationMask) {
    return reject(@"ERR_SCREEN_ORIENTATION_INVALID_ORIENTATION_LOCK", [NSString stringWithFormat:@"Invalid screen orientation lock %@", orientationLock], nil);
  }
  if (![ABI45_0_0EXScreenOrientationUtilities doesDeviceSupportOrientationMask:orientationMask]) {
    return reject(@"ERR_SCREEN_ORIENTATION_UNSUPPORTED_ORIENTATION_LOCK", [NSString stringWithFormat:@"This device does not support the requested orientation %@", orientationLock], nil);
  }
  
  [_screenOrientationRegistry setMask:orientationMask forModule:self];
  resolve(nil);
}

ABI45_0_0EX_EXPORT_METHOD_AS(lockPlatformAsync,
                    lockPlatformAsync:(NSArray <NSNumber *> *)allowedOrientations
                    resolver:(ABI45_0_0EXPromiseResolveBlock)resolve
                    rejecter:(ABI45_0_0EXPromiseRejectBlock)reject)
{
  // combine all the allowedOrientations into one bitmask
  UIInterfaceOrientationMask allowedOrientationsMask = 0;
  for (NSNumber *allowedOrientation in allowedOrientations) {
    UIInterfaceOrientation orientation = [ABI45_0_0EXScreenOrientationUtilities importOrientation:allowedOrientation];
    UIInterfaceOrientationMask orientationMask = [ABI45_0_0EXScreenOrientationUtilities maskFromOrientation:orientation];
    if (!orientationMask) {
      return reject(@"ERR_SCREEN_ORIENTATION_INVALID_ORIENTATION_LOCK", @"Invalid screen orientation lock.", nil);
    }
                                                                         
    allowedOrientationsMask = allowedOrientationsMask | orientationMask;
  }
  
  if (![ABI45_0_0EXScreenOrientationUtilities doesDeviceSupportOrientationMask:allowedOrientationsMask]) {
    return reject(@"ERR_SCREEN_ORIENTATION_UNSUPPORTED_ORIENTATION_LOCK", @"This device does not support the requested orientation.", nil);
  }
  
  [_screenOrientationRegistry setMask:allowedOrientationsMask forModule:self];
  resolve(nil);
}

ABI45_0_0EX_EXPORT_METHOD_AS(getOrientationLockAsync,
                    getOrientationLockAsyncWithResolver:(ABI45_0_0EXPromiseResolveBlock)resolve
                    rejecter:(ABI45_0_0EXPromiseRejectBlock)reject)
{
  resolve([ABI45_0_0EXScreenOrientationUtilities exportOrientationLock:[_screenOrientationRegistry currentOrientationMask]]);
}

ABI45_0_0EX_EXPORT_METHOD_AS(getPlatformOrientationLockAsync,
                    getPlatformOrientationLockAsyncResolver:(ABI45_0_0EXPromiseResolveBlock)resolve
                    rejecter:(ABI45_0_0EXPromiseRejectBlock)reject)
{
  UIInterfaceOrientationMask orientationMask = [_screenOrientationRegistry currentOrientationMask];
  NSDictionary *maskToOrienationMap = @{
    @(UIInterfaceOrientationMaskPortrait): @(UIInterfaceOrientationPortrait),
    @(UIInterfaceOrientationMaskPortraitUpsideDown): @(UIInterfaceOrientationPortraitUpsideDown),
    @(UIInterfaceOrientationMaskLandscapeLeft): @(UIInterfaceOrientationLandscapeLeft),
    @(UIInterfaceOrientationMaskLandscapeRight): @(UIInterfaceOrientationLandscapeRight)
  };
  // If the particular orientation is supported, we add it to the array of allowedOrientations
  NSMutableArray *allowedOrientations = [[NSMutableArray alloc] init];
  for (NSNumber *wrappedSingleOrientation in [maskToOrienationMap allKeys]) {
    UIInterfaceOrientationMask supportedOrientationMask = orientationMask & [wrappedSingleOrientation intValue];
    if (supportedOrientationMask) {
      UIInterfaceOrientation supportedOrientation = [maskToOrienationMap[@(supportedOrientationMask)] intValue];
      [allowedOrientations addObject:[ABI45_0_0EXScreenOrientationUtilities exportOrientation:supportedOrientation]];
    }
  }
  resolve(allowedOrientations);
}

ABI45_0_0EX_EXPORT_METHOD_AS(supportsOrientationLockAsync,
                    supportsOrientationLockAsync:(NSNumber *)orientationLock
                    resolver:(ABI45_0_0EXPromiseResolveBlock)resolve
                    rejecter:(ABI45_0_0EXPromiseRejectBlock)reject)
{
  UIInterfaceOrientationMask orientationMask = [ABI45_0_0EXScreenOrientationUtilities importOrientationLock:orientationLock];
 
  if (orientationMask && [ABI45_0_0EXScreenOrientationUtilities doesDeviceSupportOrientationMask:orientationMask]) {
    return resolve(@YES);
  }
  
  resolve(@NO);
}

ABI45_0_0EX_EXPORT_METHOD_AS(getOrientationAsync,
                    getOrientationAsyncResolver:(ABI45_0_0EXPromiseResolveBlock)resolve
                    rejecter:(ABI45_0_0EXPromiseRejectBlock)reject)
{
  resolve([ABI45_0_0EXScreenOrientationUtilities exportOrientation:[_screenOrientationRegistry currentOrientation]]);
}

// Will be called when this module's first listener is added.
- (void)startObserving
{
  [_screenOrientationRegistry registerModuleToReceiveNotification:self];
}

// Will be called when this module's last listener is removed, or on dealloc.
- (void)stopObserving
{
  [_screenOrientationRegistry unregisterModuleFromReceivingNotification:self];
}

- (void)screenOrientationDidChange:(UIInterfaceOrientation)orientation
{
  UITraitCollection * currentTraitCollection = [_screenOrientationRegistry currentTrailCollection];
  [_eventEmitter sendEventWithName:ABI45_0_0EXScreenOrientationDidUpdateDimensions body:@{
    @"orientationLock": [ABI45_0_0EXScreenOrientationUtilities exportOrientationLock:[_screenOrientationRegistry currentOrientationMask]],
    @"orientationInfo": @{
      @"orientation": [ABI45_0_0EXScreenOrientationUtilities exportOrientation:orientation],
      @"verticalSizeClass": ABI45_0_0EXNullIfNil(@(currentTraitCollection.verticalSizeClass)),
      @"horizontalSizeClass": ABI45_0_0EXNullIfNil(@(currentTraitCollection.horizontalSizeClass)),
    }
  }];
}

- (NSArray<NSString *> *)supportedEvents {
  return @[ABI45_0_0EXScreenOrientationDidUpdateDimensions];
}

- (void)onAppBackgrounded {
  [_screenOrientationRegistry moduleDidBackground:self];
}

- (void)onAppForegrounded {
  [_screenOrientationRegistry moduleDidForeground:self];
}

@end
