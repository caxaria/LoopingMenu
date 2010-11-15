/*
 *  LoopingMenu.h
 *  Banzai
 *
 *  Created by João Caxaria on 5/29/09.
 *  Copyright 2009 Imaginary Factory. All rights reserved.
 *
 */
#import "cocos2d.h"

@interface LoopingMenu : CCMenu
{	
	float hPadding;
	float lowerBound;
	float yOffset;
	bool moving;
	bool touchDown;
	float accelerometerVelocity;
}

@property float yOffset;

@end
