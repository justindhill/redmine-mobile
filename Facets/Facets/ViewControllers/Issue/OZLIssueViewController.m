//
//  OZLIssueViewController.m
//  Facets
//
//  Created by Justin Hill on 11/5/15.
//  Copyright © 2015 Justin Hill. All rights reserved.
//

#import "OZLIssueViewController.h"
#import "OZLIssueHeaderView.h"
#import "OZLIssueDescriptionCell.h"
#import <DRPSlidingTabView/DRPSlidingTabView.h>
#import "OZLIssueFullDescriptionViewController.h"
#import "OZLWebViewController.h"
#import "OZLLoadingView.h"

#import "OZLIssueAboutTabView.h"
#import "OZLTabTestView.h"
#import "OZLIssueAttachmentGalleryCell.h"

#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <URBMediaFocusViewController/URBMediaFocusViewController.h>

const CGFloat contentPadding = 16;

const NSInteger OZLDetailSectionIndex = 0;
const NSInteger OZLDescriptionSectionIndex = 1;

NSString * const OZLDetailReuseIdentifier = @"OZLDetailReuseIdentifier";
NSString * const OZLDescriptionReuseIdentifier = @"OZLDescriptionReuseIdentifier";
NSString * const OZLAttachmentsReuseIdentifier = @"OZLAttachmentsReuseIdentifier";

@interface OZLIssueViewController () <OZLIssueViewModelDelegate, DRPSlidingTabViewDelegate, OZLIssueAttachmentGalleryCellDelegate, AVAssetResourceLoaderDelegate, URBMediaFocusViewControllerDelegate>

@property (strong) OZLIssueHeaderView *issueHeader;
@property (strong) DRPSlidingTabView *detailView;
@property (strong) OZLIssueAboutTabView *aboutTabView;
@property (strong) URBMediaFocusViewController *focusView;

@property BOOL isFirstAppearance;

@end

@implementation OZLIssueViewController

#pragma mark - Life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.focusView = [[URBMediaFocusViewController alloc] init];
    self.focusView.delegate = self;
    
    self.issueHeader = [[OZLIssueHeaderView alloc] init];
    self.issueHeader.contentPadding = contentPadding;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:OZLDetailReuseIdentifier];
    [self.tableView registerClass:[OZLIssueDescriptionCell class] forCellReuseIdentifier:OZLDescriptionReuseIdentifier];
    [self.tableView registerClass:[OZLIssueAttachmentGalleryCell class] forCellReuseIdentifier:OZLAttachmentsReuseIdentifier];
    
    self.isFirstAppearance = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSAssert(self.viewModel.issueModel, @"Attempted to show an issue view controller with no issue.");
    
    if (self.isFirstAppearance) {
        self.detailView = [[DRPSlidingTabView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 0)];
        self.detailView.delegate = self;
        self.detailView.tabContainerHeight = 35;
        self.detailView.titleFont = [UIFont systemFontOfSize:14];
        self.detailView.backgroundColor = [UIColor OZLVeryLightGrayColor];
        self.detailView.dividerColor = [UIColor OZLVeryLightGrayColor];
        self.detailView.sliderHeight = 3.;
        
        self.aboutTabView = [[OZLIssueAboutTabView alloc] init];
        self.aboutTabView.backgroundColor = [UIColor OZLVeryLightGrayColor];
        self.aboutTabView.contentPadding = contentPadding;
        [self.detailView addPage:self.aboutTabView withTitle:@"ABOUT"];
        
        OZLTabTestView *scheduleView = [[OZLTabTestView alloc] init];
        scheduleView.backgroundColor = [UIColor OZLVeryLightGrayColor];
        scheduleView.heightToReport = 100;
        [self.detailView addPage:scheduleView withTitle:@"SCHEDULE"];
        
        OZLTabTestView *relatedView = [[OZLTabTestView alloc] init];
        relatedView.backgroundColor = [UIColor OZLVeryLightGrayColor];
        relatedView.heightToReport = 200;
        [self.detailView addPage:relatedView withTitle:@"RELATED"];
    }
    
    if (self.viewModel.issueModel) {
        [self applyIssueModel:self.viewModel.issueModel];
    }
    
    self.isFirstAppearance = NO;
}

#pragma mark - Accessors
- (void)setViewModel:(OZLIssueViewModel *)viewModel {
    
    _viewModel = viewModel;
    viewModel.delegate = self;
    
    if (self.isViewLoaded && viewModel.issueModel) {
        [self applyIssueModel:viewModel.issueModel];
    }
}

- (void)applyIssueModel:(OZLModelIssue *)issue {
    self.navigationItem.title = [NSString stringWithFormat:@"%@ #%ld", issue.tracker.name, issue.index];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"#%ld", issue.index] style:UIBarButtonItemStylePlain target:nil action:nil];
    [self.issueHeader applyIssueModel:issue];
    [self.aboutTabView applyIssueModel:issue];
    [self refreshHeaderSize];
    
    if (self.viewModel.completeness == OZLIssueCompletenessSome) {
        [self showLoadingSpinner];
        [self.viewModel loadIssueData];
    }
    
    [self.tableView reloadData];
}

- (void)refreshHeaderSize {
    CGSize newSize = [self.issueHeader sizeThatFits:CGSizeMake(self.view.frame.size.width, UIViewNoIntrinsicMetric)];
    self.issueHeader.frame = (CGRect){CGPointZero, newSize};
    self.tableView.tableHeaderView = self.issueHeader;
}

- (void)showLoadingSpinner {
    if (!self.tableView.tableFooterView) {
        OZLLoadingView *loadingView = [[OZLLoadingView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
        self.tableView.tableFooterView = loadingView;
        
        [loadingView.loadingSpinner startAnimating];
    }
}

- (void)hideLoadingSpinner {
    if (self.tableView.tableFooterView) {
        self.tableView.tableFooterView = nil;
    }
}

#pragma mark - Button actions
- (void)descriptionShowMoreAction:(UIButton *)button {
    OZLIssueFullDescriptionViewController *descriptionVC = [[OZLIssueFullDescriptionViewController alloc] init];
    descriptionVC.descriptionLabel.text = self.viewModel.issueModel.description;
    descriptionVC.contentPadding = contentPadding;
    
    [self.navigationController pushViewController:descriptionVC animated:YES];
}

#pragma mark - UITableViewDelegate / DataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *sectionName = self.viewModel.currentSectionNames[indexPath.section];
    
    if ([sectionName isEqualToString:OZLIssueSectionDetail]) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:OZLDetailReuseIdentifier forIndexPath:indexPath];
        cell.clipsToBounds = YES;
        self.detailView.frame = cell.contentView.bounds;
        
        if (!self.detailView.superview) {
            [cell.contentView addSubview:self.detailView];
        }
        
        return cell;
        
    } else if ([sectionName isEqualToString:OZLIssueSectionDescription]) {
        OZLIssueDescriptionCell *cell = [tableView dequeueReusableCellWithIdentifier:OZLDescriptionReuseIdentifier forIndexPath:indexPath];
        cell.contentPadding = 16.;
        cell.descriptionPreviewString = self.viewModel.issueModel.description;
        [cell.showMoreButton addTarget:self action:@selector(descriptionShowMoreAction:) forControlEvents:UIControlEventTouchUpInside];
        
        return cell;
        
    } else if ([sectionName isEqualToString:OZLIssueSectionAttachments]) {
        OZLIssueAttachmentGalleryCell *cell = [tableView dequeueReusableCellWithIdentifier:OZLAttachmentsReuseIdentifier forIndexPath:indexPath];
        cell.contentPadding = 16.;
        cell.attachments = self.viewModel.issueModel.attachments;
        cell.delegate = self;
        
        return cell;
    }
    
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.viewModel.currentSectionNames.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *sectionName = self.viewModel.currentSectionNames[indexPath.section];
    
    if ([sectionName isEqualToString:OZLIssueSectionDetail]) {
        return self.detailView.intrinsicHeight;
        
    } else if ([sectionName isEqualToString:OZLIssueSectionDescription]) {
        return [OZLIssueDescriptionCell heightWithWidth:tableView.frame.size.width
                                           description:self.viewModel.issueModel.description
                                        contentPadding:contentPadding];
        
    } else if ([sectionName isEqualToString:OZLIssueSectionAttachments]) {
        return 140.;
    }
    
    return 44.;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark - DRPSlidingTabViewDelegate
- (void)view:(UIView *)view intrinsicHeightDidChangeTo:(CGFloat)newHeight {
    if (view == self.detailView) {
        [UIView beginAnimations:nil context:NULL];
        
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
        self.detailView.frame = self.detailView.superview.bounds;
        
        [UIView commitAnimations];
    }
}

#pragma mark - OZLIssueViewModelDelegate
- (void)viewModel:(OZLIssueViewModel *)viewModel didFinishLoadingIssueWithError:(NSError *)error {
    [self hideLoadingSpinner];
    [self.tableView reloadData];
}

#pragma mark - OZLIssueAttachmentGalleryCellDelegate
- (void)galleryCell:(OZLIssueAttachmentGalleryCell *)galleryCell didSelectAttachment:(OZLModelAttachment *)attachment withCellRelativeFrame:(CGRect)frame {
    
    if ([attachment.contentType hasPrefix:@"video"] || [attachment.contentType containsString:@"mp4"]) {
        
        AVPlayerViewController *playerVC = [[AVPlayerViewController alloc] init];
        playerVC.player = [AVPlayer playerWithURL:[NSURL URLWithString:attachment.contentURL]];
        playerVC.showsPlaybackControls = YES;
        
        [self presentViewController:playerVC animated:YES completion:nil];
        
    } else if ([attachment.contentType hasPrefix:@"image"]) {
        CGRect rect = [galleryCell convertRect:frame toView:self.view];
        
        [self.focusView showImageFromURL:[NSURL URLWithString:attachment.contentURL] fromRect:rect];
        
    } else if ([attachment.contentType isEqualToString:@"text/plain"]) {
        OZLWebViewController *textVC = [[OZLWebViewController alloc] init];
        textVC.sourceURL = [NSURL URLWithString:attachment.contentURL];
        
        [self.navigationController pushViewController:textVC animated:YES];
    }
    NSLog(@"Attachment selected: %@", attachment);
}

#pragma mark - URBFocusViewControllerDelegate
- (void)mediaFocusViewController:(URBMediaFocusViewController *)mediaFocusViewController didFailLoadingImageWithError:(NSError *)error {
    NSLog(@"%@", error);
}

- (void)mediaFocusViewController:(URBMediaFocusViewController *)mediaFocusViewController didFinishLoadingImage:(UIImage *)image {
    NSLog(@"");
}

@end
