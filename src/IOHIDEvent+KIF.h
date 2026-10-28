//
//  IOHIDEvent+KIF.h
//  KIF
//
//  Created by Thomas Bonnin on 7/6/15.
//

#ifndef QF_IOHIDEVENT_KIF_H
#define QF_IOHIDEVENT_KIF_H

#import <Foundation/Foundation.h>
#import "IOKit+SPI.h"

IOHIDEventRef kif_IOHIDEventWithTouches(NSArray *touches) CF_RETURNS_RETAINED;

#endif
