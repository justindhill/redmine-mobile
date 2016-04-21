//
//  OZLModelTimeEntryActivity.h
//  Facets
//
//  Created by lizhijie on 7/23/13.

@import Foundation;

@interface OZLModelTimeEntryActivity : NSObject

@property (nonatomic) NSInteger index;
@property (nonatomic, strong) NSString *name;

- (id)initWithDictionary:(NSDictionary *)dic;
- (NSMutableDictionary *)toParametersDic;

@end
