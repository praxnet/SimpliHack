//
//  DetailViewController.m
//  Summarize
//
//  Created by Sachin Kesiraju on 2/28/15.
//  Copyright (c) 2015 Sachin Kesiraju. All rights reserved.
//

#import "DetailViewController.h"
#import "CourseViewController.h"
#import "NLPClient.h"
#import "AppDelegate.h"
#import "StatsTableCell.h"
#import "MapTableCell.h"
#import "SummaryTableCell.h"

@interface DetailViewController ()

@property (strong, nonatomic) NSArray *courses;
@property (strong, nonatomic) NSMutableArray *keywords;
@property (strong, nonatomic) NSMutableArray *concepts;
@property (strong, nonatomic) NSDictionary *entity;
@property (strong, nonatomic) NSMutableArray *summaries;
@property (strong, nonatomic) NSMutableArray *stats;

@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.tableView.dataSource = self;
    self.tableView.delegate =self;
    self.tableView.tableFooterView = [UIView new];
    self.navigationItem.title = @"Summary";
    self.keywords = [[NSMutableArray alloc] init];
    self.concepts = [[NSMutableArray alloc] init];
    self.entity = [[NSDictionary alloc] init];
    self.summaries = [[NSMutableArray alloc] init];
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    self.managedObjectContext = delegate.managedObjectContext;
}

- (void) viewDidAppear:(BOOL)animated
{
    //Insert summary text/url +details to core data
    
    [NLPClient getKeywordsForText:_detailText withCompletion:^(NSArray *keywords, NSError *error)
     {
         for(int i=0; i<keywords.count; i++)
         {
             [self.keywords addObject:[[keywords objectAtIndex:i] objectForKey:@"text"]];
         }
         NSLog(@"Keywords %@", self.keywords);
     }];
    [NLPClient getConceptsForText:_detailText withCompletion:^(NSArray *concepts, NSError *error)
     {
         for(int i=0; i<concepts.count; i++)
         {
             [self.concepts addObject:[[concepts objectAtIndex:i] objectForKey:@"text"]];
         }
         NSLog(@"Concepts %@", self.concepts);
     }];
    [NLPClient getEntitiesForText:_detailText withCompletion:^(NSDictionary *entity, NSError *error)
     {
         self.entity = entity;
     }];
    [NLPClient getSummaryForText:_detailText withCompletion:^(NSArray *summaries, NSError *error)
     {
         NSLog(@"Summaries %@", summaries);
         self.summaries = [NSMutableArray arrayWithArray:summaries];
     }];
    
    if(self.entity[@"percentage"])
    {
        [self.stats addObject:self.entity[@"percentage"][0]];
    }
    if(self.entity[@"organization"])
    {
        [self.stats addObject:self.entity[@"organization"][0]];
    }
    if(self.entity[@"date"])
    {
        [self.stats addObject:self.entity[@"date"][0]];
    }
    if(self.entity[@"money"])
    {
        [self.stats addObject:self.entity[@"money"][0]];
    }
    if(self.entity[@"person"])
    {
        [self.stats addObject:self.entity[@"person"][0]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"showCourses"])
    {
        CourseViewController *courseView = (CourseViewController *) segue.destinationViewController;
        courseView.courses = self.courses;
    }
}

- (void) getCoursesForTopics: (NSString *) topic
{
    NSString *url = [NSString stringWithFormat:@"https://api.coursera.org/api/catalog.v1/courses?q=search&query=%@", topic];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]] queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
    {
        if(!error)
        {
            NSError *jsonError = nil;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
            if(!jsonError)
            {
                self.courses = [[NSArray alloc] initWithArray:json[@"elements"]];
                [self performSegueWithIdentifier:@"showCourses" sender:self];
            }
        }
    }];
}

#pragma mark - Table View

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.stats.count + 2;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    switch(indexPath.row)
    {
        case 1: {
            MapTableCell *mapCell = [tableView dequeueReusableCellWithIdentifier:@"MapTableCell"];
            if(mapCell == nil)
            {
                NSLog(@"Calling map cell");
                mapCell = [MapTableCell mapTableCell];
            }
            [mapCell setLocationName:[self.entity objectForKey:@"location"][0]];
            cell = mapCell;
        }
            break;
        case 0: {
            SummaryTableCell *summaryCell = [tableView dequeueReusableCellWithIdentifier:@"SummaryCell"];
            if(summaryCell == nil)
            {
                summaryCell = [SummaryTableCell summaryTableCell];
            }
            summaryCell.summaryView.text = @"\u2022 Stephen Hawing  \n \n \u2022 Centre for Theoretical Cosmology within the University of Cambridge.";
            //summaryCell.summaryView.text = [NSString stringWithFormat:@"\u2022 %@ \n \n \u2022 %@ \n \n \u2022 %@", self.summaries[0], self.summaries[1], self.summaries[2]];
            cell = summaryCell;
        }
            break;
        default:
        {
            StatsTableCell *statCell = [tableView dequeueReusableCellWithIdentifier:@"StatCell"];
            if(statCell == nil)
            {
                NSLog(@"Stat cell");
                statCell = [StatsTableCell statsTableCell];
            }
            statCell.statLabel.text = [self.stats objectAtIndex:indexPath.row-2];
            statCell.statLabel.textColor = [UIColor colorWithRed:250.0f/255.0f green:60.0f/255.0f blue:57.0f/255.0f alpha:1.0000];
            cell = statCell;
        }
    }
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == 0)
    {
        return 223;
    }
    else if (indexPath.row == 1)
    {
        return 200;
    }
    else
    {
        return 100;
    }
}

@end
