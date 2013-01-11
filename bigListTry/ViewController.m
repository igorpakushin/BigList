//
//  ViewController.m
//  bigListTry
//
//  Created by Igor on 1/11/13.
//  Copyright (c) 2013 Igor. All rights reserved.
//

#import "ViewController.h"


#pragma mark -
#pragma mark Artist
@interface Artist : NSObject {}

@property (nonatomic, retain) NSString* name;

+(Artist*)artistWithName:(NSString*)name;

@end

@implementation Artist
@synthesize name;

+(Artist*)artistWithName:(NSString*)name
{
    Artist* ret = [[Artist new] autorelease];
    ret.name = name;
    return ret;
}

-(void)dealloc
{
//    NSLog(@"dealloc Artist");
    [self.name release];
    [super dealloc];
}

@end


#pragma mark -
#pragma mark Song
@interface Song : NSObject {}

@property (nonatomic, retain) NSString* title;
@property (nonatomic, retain) Artist* artist;

+(Song*)songWithTitle:(NSString*)title artist:(NSString*)name;

@end

@implementation Song
@synthesize title, artist;

+(Song*)songWithTitle:(NSString*)title artist:(NSString*)name
{
    Song* ret = [[self new] autorelease];
    ret.title = title;
    ret.artist = [Artist artistWithName:name];
    return ret;
}

-(void)dealloc
{
//    NSLog(@"dealloc Song");
    [self.title release];
    [self.artist release];
    [super dealloc];
}

@end



@interface ViewController ()
@property (nonatomic, retain) NSMutableArray* songs;
@property (nonatomic, retain) NSMutableDictionary* artists;
@property (nonatomic, retain) NSArray* artists_keys_sorted;
@property (nonatomic, retain) NSMutableDictionary* songs_keys_sorted;
@end

@implementation ViewController

-(NSString*)stringRandom
{
    // thanks to dasblinkenlight: http://stackoverflow.com/questions/10252080/is-this-a-good-way-to-generate-a-random-string-on-iphone
    const uint NUM_CHR = 15;
    char data[NUM_CHR];
    for (int i=0; i<NUM_CHR; data[i++] = (char)('a' + (arc4random_uniform(26))));
    data[0] = (char)('A' + (arc4random_uniform(26)));
    uint space = arc4random_uniform(NUM_CHR-5) + 3;
    data[ space ] = ' ';
    data[ space + 1 ] = (char)('A' + (arc4random_uniform(26)));
    return [[NSString alloc] initWithBytes:data length:NUM_CHR encoding:NSUTF8StringEncoding];
}

-(void)generateSongsArray
{
    static const uint NUM_SONGS = 5000;
    static const uint NUM_ARTISTS = 100; // 50 songs per author

    self.songs = [NSMutableArray arrayWithCapacity:NUM_SONGS];

    // i do not know where and how do you get the list of songs so i'll generate a random one
    // i won't bother to sort these, but i'll do that myself later
    // generate array of artists:
    NSMutableArray* artitsts = [NSMutableArray arrayWithCapacity:NUM_ARTISTS];
    for (int i=0; i<NUM_ARTISTS; i++)
        [artitsts addObject:[self stringRandom]];

    NSUInteger j = 0;
    for (int i=0; i<NUM_SONGS; i++)
    {
        if (j >= NUM_ARTISTS) j = 0;
        [self.songs addObject:[Song songWithTitle:[NSString stringWithFormat:@"%@ - %@", [artitsts objectAtIndex:j], [self stringRandom] ]
                                           artist:[artitsts objectAtIndex:j++]]];
    }

}

-(void)convertArrayToDictionary
{
    self.artists = [NSMutableDictionary dictionary];
    for (Song *song in self.songs) {
        NSMutableDictionary* artist = [self.artists objectForKey:song.artist.name];

        if (artist == nil) {
            artist = [NSMutableDictionary dictionary];
            [self.artists setObject:artist forKey:song.artist.name];
        }

        [artist setObject:song forKey:song.title];

    }

    // okay now here is where i will have to bother to sort data

    // sort sections
//    self.artists_keys_sorted = [self.artists keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2) {
//        NSLog(@"%@", obj1);
//        NSLog(@"%@", obj2);
        // i was surprised to see in logs that obj1 and obj2 are dictionaries? :O WTF?!
        // the method is keysSortedByValueUsingComparator, not valuesSortedByKeyUsingComparator,
        // could someone explain me this please? :O
//        return [obj1 caseInsensitiveCompare:obj2] == NSOrderedAscending;
//    }];
    // so this is a workaround:
    self.artists_keys_sorted = [[self.artists allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 caseInsensitiveCompare:obj2] == NSOrderedDescending;
    }];

    // sort rows
    self.songs_keys_sorted = [NSMutableDictionary dictionaryWithCapacity:self.artists_keys_sorted.count];
    for (NSString* key in self.artists_keys_sorted) {

        NSDictionary* artist = [self.artists objectForKey:key];
        NSArray* sorted_songs = [[artist allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [obj1 caseInsensitiveCompare:obj2] == NSOrderedDescending;
        }];
        [self.songs_keys_sorted setObject:sorted_songs forKey:artist];
    }

}

-(void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.


    // generate some songs and artists randomly
    [self generateSongsArray];

    //
    [self convertArrayToDictionary];

}


#pragma mark -
#pragma UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary* songs = nil;
    NSEnumerator* e = [self.artists objectEnumerator];
    for (NSInteger i = 0; i<=section; i++)
        songs = [e nextObject];

    return songs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    NSDictionary* artist = [self.artists objectForKey:[self.artists_keys_sorted objectAtIndex:[indexPath section]]];
    NSArray* songsOfArtist = [self.songs_keys_sorted objectForKey:artist];

    cell.textLabel.text = [songsOfArtist objectAtIndex:[indexPath row]];

    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.artists.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.artists_keys_sorted objectAtIndex:section];
}

/*
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{}
*/





-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc
{
    [self.songs release];
    [self.artists release];
    [self.artists_keys_sorted release];
    [self.songs_keys_sorted release];
    [super dealloc];
}

@end
