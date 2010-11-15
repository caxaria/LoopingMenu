/*
 *  LoopingMenu.mm
 *  Banzai
 *
 *  Created by João Caxaria on 5/29/09.
 *  Copyright 2009 Imaginary Factory. All rights reserved.
 *
 */

#import "LoopingMenu.h"
#import "InputController.h"
#import "SimpleAudioEngine.h"

@interface CCMenu (Private)
// returns touched menu item, if any, implemented in Menu.m
-(CCMenuItem *) itemForTouch: (UITouch *) touch;



@end

@interface LoopingMenu (Animation)

-(void) updateAnimation;
-(void) moveItemsLeftBy:(float) offset;
-(void) moveItemsRightBy:(float) offset;

@end

@implementation LoopingMenu

@synthesize yOffset;

#pragma mark -
#pragma mark Menu

-(void) alignItemsVerticallyWithPadding:(float)padding
{
	[self alignItemsHorizontallyWithPadding:padding];
}

-(void) alignItemsHorizontallyWithPadding:(float)padding
{
	isAccelerometerEnabled = true;
	accelerometerVelocity = 0;
	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:1.0/60.0];
	hPadding = padding;
	lowerBound = [(CCMenuItem*)[children_ objectAtIndex:0] contentSize].height / 2.0;
	[super alignItemsHorizontallyWithPadding:padding];
	[self updateAnimation];
}

-(void) registerWithTouchDispatcher
{
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:INT_MIN+1 swallowsTouches:false];
}

#pragma mark -
#pragma mark Accelerometer

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
	if(touchDown) 
		return;
	float x = acceleration.y;
	float y = acceleration.x;
	float tVectorLength=sqrt(x*x+y*y);
	if(tVectorLength == 0)
		return;
	float xTilt=-5.0f*x/tVectorLength;
	accelerometerVelocity = (accelerometerVelocity * 4.0 + xTilt) / 5.0;
	if(accelerometerVelocity < 0)
		[self moveItemsLeftBy:accelerometerVelocity];
	else if(accelerometerVelocity > 0)
		[self moveItemsRightBy:accelerometerVelocity];
}


#pragma mark -
#pragma mark Touches

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	if([[event allTouches] count] != 1)
		return false;
	touchDown = true;
	moving = false;
	selectedItem = [super itemForTouch:touch];
	[selectedItem selected];
	
	state = kMenuStateTrackingTouch;
	return true;
}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
	if([[event allTouches] count] != 1)
	{
		[self ccTouchCancelled:touch withEvent:event];
		return;
	}
	
	if(!moving && state == kMenuStateTrackingTouch)
		[super ccTouchEnded:touch withEvent:event];
	else if(state == kMenuStateTrackingTouch)
		[self ccTouchCancelled:touch withEvent:event];
	moving = false;
	touchDown = false;
}

-(void) ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
	[selectedItem unselected];
	
	touchDown = false;
	state = kMenuStateWaiting;
	
	moving = false;
}

-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	if([[event allTouches] count] != 1)
	{
		[self ccTouchCancelled:touch withEvent:event];
		return;
	}
	NSMutableSet* touches = [[[NSMutableSet alloc] initWithObjects:touch, nil] autorelease];
	
	CGPoint distance = icDistance(1, touches, event);
	
	if(icWasSwipeLeft(touches, event) && distance.y < distance.x)
	{
		moving = true;
		[self moveItemsLeftBy:-distance.x];
	} 
	else if(icWasSwipeRight(touches, event)  && distance.y < distance.x)
	{
		moving = true;
		[self moveItemsRightBy:distance.x];
	}
	else if(!moving && state == kMenuStateTrackingTouch)
	{
		[super ccTouchMoved:touch withEvent:event];
	}
	
}


@end

@implementation LoopingMenu (Animation)

-(void) moveItemsLeftBy:(float) offset
{
	[selectedItem unselected];
	
	for(CCMenuItem<CCRGBAProtocol>* item in children_)
	{
		[item setPosition:ccpAdd([item position], ccp(offset, 0))];
	}
	
	CCMenuItem* leftItem = [children_ objectAtIndex:0];
	if(leftItem.position.x + [self position].x + leftItem.contentSize.width / 2.0  < 0)
	{
		[[SimpleAudioEngine sharedEngine] playEffect:@"dragteam.caf"];
		[leftItem retain];
		[children_ removeObjectAtIndex:0];
		CCMenuItem* lastItem = [children_ objectAtIndex:[children_ count] - 1];
		[leftItem setPosition:ccpAdd([lastItem position], ccp([lastItem contentSize].width / 2.0 + [leftItem contentSize].width / 2.0 + hPadding, 0))];
		[children_ addObject:leftItem];
		[leftItem autorelease];
	}
	[self updateAnimation];
}

-(void) moveItemsRightBy:(float) offset
{
	[selectedItem unselected];
	
	for(CCMenuItem<CCRGBAProtocol>* item in children_)
	{
		[item setPosition:ccpAdd([item position], ccp(offset, 0))];
	}
	
	CCMenuItem* lastItem = [children_ objectAtIndex:[children_ count] - 1];
	if(lastItem.position.x + [self position].x - lastItem.contentSize.width / 2.0 > 480)
	{
		[[SimpleAudioEngine sharedEngine] playEffect:@"dragteam.caf"];
		[lastItem retain];
		[children_ removeObjectAtIndex:[children_ count] - 1];
		CCMenuItem* firstItem = [children_ objectAtIndex:0];
		[lastItem setPosition:ccpSub([firstItem position], ccp([firstItem contentSize].width / 2.0 + [lastItem contentSize].width / 2.0 + hPadding, 0))];
		[children_ insertObject:lastItem atIndex:0];
		[lastItem autorelease];
	}
	[self updateAnimation];
}


-(void) updateAnimation
{
	static float quadraticCoefficient = -1.0/90000.0; //1/300^
	
	for(CCMenuItem<CCRGBAProtocol>* item in children_)
	{
		float distance = fabsf(item.position.x - 240.0 + self.position.x);
		
		if(distance > 240.0)
			distance = 240.0;
		else if(distance < 0.0)
			distance = 0.0;
		
		float ratio = quadraticCoefficient * (distance*distance) + 1;
		
		[item setScale: ratio];
		[item setOpacity:ratio * 255.0];
		item.position=ccp(item.position.x, yOffset - (lowerBound - item.contentSize.height * ratio / 2.0));
	}
}

@end