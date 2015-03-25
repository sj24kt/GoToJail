//
//  JailViewController.m
//  GoToJail
//
//  Created by Sherrie Jones on 3/25/15.
//  Copyright (c) 2015 Sherrie Jones. All rights reserved.
//

#import "JailViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface JailViewController () <CLLocationManagerDelegate>
@property (strong, nonatomic) IBOutlet UITextView *myTextView;
@property CLLocationManager *locationManager;

@end

@implementation JailViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.locationManager = [CLLocationManager new];
    [self.locationManager requestWhenInUseAuthorization];// better for battery life
    self.locationManager.delegate = self; // be sure to add the delegate <>
}

- (void)reverseGeocode:(CLLocation *)location {

    CLGeocoder *geoCoder = [CLGeocoder new];
    [geoCoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *placemark = placemarks.firstObject;
        NSString *address = [NSString stringWithFormat:@"%@ %@\n%@",
                             placemark.subThoroughfare,
                             placemark.thoroughfare,
                             placemark.locality];
        self.myTextView.text = [NSString stringWithFormat:@"Found you: %@", address];
        [self findJailNear:placemark.location];
    }];

// 39.612058,-104.722871 > home address get from google maps
}

- (void)findJailNear:(CLLocation *)location {

    MKLocalSearchRequest *request = [MKLocalSearchRequest new];
    request.naturalLanguageQuery = @"correctional";
    request.region = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(1, 1));
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        MKMapItem *mapItem = response.mapItems.firstObject;
        self.myTextView.text = [NSString stringWithFormat:@"You should go to %@", mapItem.name];
        [self getDirectionsTo:mapItem];
    }];

}
// need source and destination
- (void)getDirectionsTo:(MKMapItem *)destinationMapItem {
    MKDirectionsRequest *request = [MKDirectionsRequest new];
    request.source = [MKMapItem mapItemForCurrentLocation];
    request.destination = destinationMapItem;
    request.transportType = MKDirectionsTransportTypeAutomobile;
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        MKRoute *route = response.routes.firstObject; // directions have steps

        NSMutableString *directionString = [NSMutableString new];
        int counter = 1;

        for (MKRouteStep *step in route.steps) {
            // for every step in route add to
            [directionString appendFormat:@"%d %@\n", counter, step.instructions];
            counter++;
            self.myTextView.text = directionString;
            

            //NSLog(@"%@", step.instructions);
        }

    }];


}

#pragma mark - location manager delegates

- (IBAction)startViolatingPrivacyButton:(UIButton *)sender {

    [self.locationManager startUpdatingLocation];
    self.myTextView.text = @"Start locating you";
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"%@", error);
}
// pass in array of locations
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {

    for (CLLocation *location in locations) {
        // location to find youself
        if (location.horizontalAccuracy < 1000 && location.verticalAccuracy < 1000) {
            self.myTextView.text = @"Location Found, reverse Geocoding";
            [self.locationManager stopUpdatingLocation];
            [self reverseGeocode:location];
            break;
        }
    }
}




@end
