#import <SPStackedNav/SPSideTabBar.h>
#import "SPBadgeView.h"
#import "SPSideTabItemButton.h"
#import "UIImage+SPTabBarImage.h"
#import "SPSideTabController.h"
#import <SPSuccinct/SPSuccinct.h>

@interface SPSideTabBar ()
{
    UIColor *       _backgroundPattern;
}
@property(nonatomic,retain) NSArray *itemButtons;
@property(nonatomic,retain) NSArray *additionalItemButtons;
-(void)itemButtonWasTapped:(SPSideTabItemButton*)button;
@end

@interface SPSideTabBadgeView : SPBadgeView
+ (SPSideTabBadgeView *) badgeViewWithFrame:(CGRect)frame;
-(void)bindToTabItem:(UITabBarItem *)item;
@end


@implementation SPSideTabBar

- (void)commonSetup
{
    UIImage *bgI = [UIImage imageNamed:@"bg-tb"];
    _backgroundPattern = [UIColor colorWithPatternImage:bgI];
    
    CGRect r = self.frame;
    if(r.size.width > [bgI size].width) {
        r.size.width = [bgI size].width;
        self.frame = r;
    }
}

-(id)initWithFrame:(CGRect)r
{
    if (!(self = [super initWithFrame:r]))
        return nil;
    
    [self commonSetup];
    
    return self;
}

-(id)initWithCoder:(NSCoder*)decoder
{
    if (!(self = [super initWithCoder:decoder]))
        return nil;
    
    [self commonSetup];
    
    return self;
}

- (void)drawRect:(CGRect)rect
{
    // <anton> we are drawing the background manually to avoid blending the layer.
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    {
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:[self bounds]
                                                   byRoundingCorners:UIRectCornerTopLeft
                                                         cornerRadii:CGSizeMake(5, 5)];
        CGContextAddPath(context, [path CGPath]);
        CGContextClip(context);
        
        [_backgroundPattern setFill];
        CGContextFillRect(context, rect);
    } CGContextRestoreGState(context);
}

-(UIImage*)imageForState:(UIControlState)state inItem:(UITabBarItem*)item;
{
    UIImage *image = nil;
    
    if (item.image) {
        if (state & (UIControlStateSelected))
            return [item.image sp_selectedImageForTabBar];
        if (state & (UIControlStateSelected|UIControlStateHighlighted))
            return [item.image sp_selectedAndHighlightedImageForTabBar];
        return [item.image sp_imageForTabBar];
    }
    
    SPTabBarItem *spItem = (SPTabBarItem*)item;
    if (![item isKindOfClass:[SPTabBarItem class]])
        return nil;
        
    NSString *imageName = spItem.imageName;
    if (!imageName)
        return nil;
    
    if (state == (UIControlStateSelected|UIControlStateHighlighted) && (image = [UIImage imageNamed:[NSString stringWithFormat:@"%@-%@-tb", imageName, @"selected+pressed"]]))
        return image;
    if (state & UIControlStateHighlighted && (image = [UIImage imageNamed:[NSString stringWithFormat:@"%@-%@-tb", imageName, @"pressed"]]))
        return image;
    if (state & UIControlStateSelected && (image = [UIImage imageNamed:[NSString stringWithFormat:@"%@-%@-tb", imageName, @"selected"]]))
        return image;
    
    return [UIImage imageNamed:[NSString stringWithFormat:@"%@-tb", imageName]];
}

-(UIView*)buttonForItem:(UITabBarItem*)item withFrame:(CGRect)pen;
{
    if ([item isKindOfClass:[SPTabBarItem class]] && [(SPTabBarItem*)item view]) {
        UIView *view = [(SPTabBarItem*)item view];
        [view setFrame:pen];
        return view;
    }
    
    SPSideTabItemButton *b = [[SPSideTabItemButton alloc] initWithFrame:pen];
    
    [b addTarget:self action:@selector(itemButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    [b setTitle:[item title] forState:UIControlStateNormal];
    
    [b setImage:[self imageForState:UIControlStateNormal inItem:item] forState:UIControlStateNormal];
    [b setImage:[self imageForState:UIControlStateSelected inItem:item] forState:UIControlStateSelected];
    [b setImage:[self imageForState:UIControlStateHighlighted inItem:item] forState:UIControlStateHighlighted];
    [b setImage:[self imageForState:UIControlStateSelected|UIControlStateHighlighted inItem:item] forState:UIControlStateSelected|UIControlStateHighlighted];
    
    SPSideTabBadgeView *badge = [SPSideTabBadgeView badgeViewWithFrame:CGRectMake(0, 0, 0, 0)];
    badge.center = CGPointMake(50, 6);
    [badge bindToTabItem:item];
    b.badgeView = badge;
    
    return b;
}

-(void)setItems:(NSArray*)items;
{
    if([items isEqual:_items]) return;
    
    self.selectedItem = nil;
    
    _items = [items copy];
    
    for(UIView *b in _itemButtons) [b removeFromSuperview];
    self.itemButtons = nil;

    if(_items) {
        NSMutableArray *itemButtons = [NSMutableArray array];
        CGRect pen = CGRectMake(0, 10, 80, 70);
        for(UITabBarItem *item in _items) {
            UIView *b = [self buttonForItem:item withFrame:pen];
            [itemButtons addObject:b];
            [self addSubview:b];
            pen.origin.y += pen.size.height + 10;
        }
        self.itemButtons = itemButtons;
    }
}
static const int kIsAdditionalItem = 1;
-(void)setAdditionalItems:(NSArray*)moreItems;
{
    if([moreItems isEqual:_additionalItems]) return;
    
    _additionalItems = [moreItems copy];
    
    for(UIView *b in _additionalItemButtons) [b removeFromSuperview];
    self.additionalItemButtons = nil;
    
    if(_additionalItems) {
        NSMutableArray *itemButtons = [NSMutableArray array];
        CGRect pen = CGRectMake(0, self.frame.size.height-70-10, 80, 70);
        for(UITabBarItem *item in _additionalItems) {
            UIView *b = [self buttonForItem:item withFrame:pen];
            b.tag = kIsAdditionalItem;
            b.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
            [itemButtons addObject:b];
            [self addSubview:b];
            pen.origin.y -= pen.size.height - 10;
        }
        self.additionalItemButtons = itemButtons;
    }
}

-(void)itemButtonWasTapped:(SPSideTabItemButton*)button;
{
    NSArray *items = (button.tag == kIsAdditionalItem)?_additionalItems:_items;
    NSArray *buttons = (button.tag == kIsAdditionalItem)?_additionalItemButtons:_itemButtons;
    
    UITabBarItem *tappedItem = items[[buttons indexOfObject:button]];
    if(!_delegate)
        self.selectedItem = tappedItem;
    else
        [self.delegate tabBar:self didSelectItem:tappedItem];
}
-(void)setSelectedItem:(UITabBarItem*)item;
{
    if(item == _selectedItem) return;
    
    if(_selectedItem) [_itemButtons[[_items indexOfObject:_selectedItem]] setSelected:NO];
    
    _selectedItem = item;

    if(_selectedItem) [_itemButtons[[_items indexOfObject:_selectedItem]] setSelected:YES];
}
-(void)select:(BOOL)selected additionalItem:(UITabBarItem*)item;
{
    [_additionalItemButtons[[_additionalItems indexOfObject:item]] setSelected:selected];
}
-(CGRect)rectForItem:(UITabBarItem*)item;
{
    NSUInteger idx = [_items indexOfObject:item];
    UIView *button = nil;
    if(idx != NSNotFound) {
        button = _itemButtons[idx];
    } else {
        idx = [_additionalItems indexOfObject:item];
        button = _additionalItemButtons[idx];
    }
    return button.frame;
}
@end

@implementation SPSideTabBadgeView

+ (SPSideTabBadgeView *) badgeViewWithFrame:(CGRect)frame;
{
    SPSideTabBadgeView *badge = [[SPSideTabBadgeView alloc] initWithFrame:frame];
    badge.backgroundImage = [[UIImage imageNamed:@"unread-tb~ipad.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(11, 10, 11, 10)];
    badge.textColor = [UIColor whiteColor];
    badge.font = [UIFont systemFontOfSize:12];
    
    return badge;
}

-(void)bindToTabItem:(UITabBarItem *)item;
{
    SPRemoveAssociatedDependencies(self);
    if(item)
        $depends(@"badge value text", item, @"badgeValue", (id)^{
            selff.text = item.badgeValue;
            selff.hidden = item.badgeValue.length == 0;
        });
}

-(void)dealloc;
{
    SPRemoveAssociatedDependencies(self);
}

@end