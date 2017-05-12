package WebService::Strava::CachedAPI::Auth;
use Dancer2 appname => 'WebService::Strava::CachedAPI';

get '/athlete' => sub {
  {
    'resource_state' => 3,
    'clubs' => [],
    'sex' => 'M',
    'email' => 'strava_test@example.com',
    'bikes' => [
                 {
                   'id' => 'b1816631',
                   'distance' => '11097',
                   'name' => 'Giant',
                   'resource_state' => 2,
                   'primary' => 1,
                 }
               ],
    'badge_type_id' => 0,
    'firstname' => 'Perl API',
    'country' => 'Australia',
    'mutual_friend_count' => 0,
    'state' => 'Western Australia',
    'profile' => 'avatar/athlete/large.png',
    'follower' => undef,
    'lastname' => 'Testing',
    'friend' => undef,
    'premium' => 0,
    'shoes' => [
                 {
                   'primary' => 1,
                   'resource_state' => 2,
                   'name' => 'No name Worn Flimsy',
                   'distance' => '0',
                   'id' => 'g683635'
                 }
               ],
    'measurement_preference' => 'meters',
    'id' => 1234567,
    'city' => 'Perth',
    'ftp' => undef,
    'date_preference' => '%m/%d/%Y',
    'friend_count' => 0,
    'updated_at' => '2015-02-18T07:18:04Z',
    'created_at' => '2015-02-18T07:13:24Z',
    'profile_medium' => 'avatar/athlete/medium.png',
    'follower_count' => 0
  };
};

post '/uploads' => sub {
  { 
    id => 12345678,
    external_id => "sample.gpx",
    error => undef,
    status => "Your activity is still being processed.",
    activity_id => undef,
  }
};

get '/uploads/:id' => sub {
  {
    'external_id' => 'sample.gpx',
    'activity_id' => 123456789,
    'id' => 12345678,
    'error' => undef,
    'status' => 'Your activity is ready.'
  };
};

# XXX: Probably a little dodgy, but it works
our $blarg;

del '/activities/:id' => sub {
  if ($blarg) {
    status '404';
  } else {
    $blarg = 1;
    status '204';
  }
};

get '/activities/:id' => sub {
  {
    'kudos_count' => 0,
    'id' => 256892594,
    'type' => 'Ride',
    'distance' => '11096.8',
    'location_country' => 'Australia',
    'achievement_count' => 0,
    'start_date' => '2011-05-22T08:32:29Z',
    'moving_time' => 1692,
    'location_city' => 'Kingsley',
    'photos' => {
                  'count' => 0,
                  'primary' => undef
                },
    'segment_efforts' => [
      {
        'name' => 'Lake Goollelal Bike Path East',
        'activity' => {
                        'id' => 256892594
                      },
        'athlete' => {
                       'id' => 7972137
                     },
        'kom_rank' => undef,
        'start_date_local' => '2011-05-22T16:32:29Z',
        'pr_rank' => undef,
        'segment' => {
                       'start_latitude' => '-31.8199955',
                       'distance' => '1606.58',
                       'id' => 2277269,
                       'starred' => 0,
                       'start_longitude' => '115.818779',
                       'average_grade' => '-0.8',
                       'city' => 'Kingsley',
                       'end_longitude' => '115.816678',
                       'resource_state' => 2,
                       'start_latlng' => [
                                           '-31.8199955',
                                           '115.818779'
                                         ],
                       'country' => 'Australia',
                       'activity_type' => 'Ride',
                       'end_latitude' => '-31.806383',
                       'maximum_grade' => '3.1',
                       'elevation_low' => '20.1',
                       'elevation_high' => '35.1',
                       'end_latlng' => [
                                         '-31.806383',
                                         '115.816678'
                                       ],
                       'climb_category' => 0,
                       'state' => 'WA',
                       'name' => 'Lake Goollelal Bike Path East',
                       'private' => 1,
          },
        'resource_state' => 2,
        'end_index' => 219,
        'hidden' => 0,
        'achievements' => [],
        'elapsed_time' => 226,
        'id' => 6016562203,
        'distance' => '1618.6',
        'start_date' => '2011-05-22T08:32:29Z',
        'start_index' => 0,
        'moving_time' => 226
      },
      {
        'achievements' => [],
        'id' => 6016562214,
        'elapsed_time' => 735,
        'distance' => '4802.3',
        'start_date' => '2011-05-22T08:36:20Z',
        'start_index' => 223,
        'moving_time' => 735,
        'hidden' => 0,
        'start_date_local' => '2011-05-22T16:36:20Z',
        'pr_rank' => undef,
        'segment' => {
                       'elevation_low' => '18.7',
                       'maximum_grade' => '17.2',
                       'end_latitude' => '-31.80628',
                       'country' => 'Australia',
                       'activity_type' => 'Ride',
                       'start_latlng' => [
                                           '-31.806149',
                                           '115.816603'
                                         ],
                       'resource_state' => 2,
                       'private' => 0,
                       'name' => 'Lake Goolelel Kingfisher start',
                       'state' => 'WA',
                       'climb_category' => 0,
                       'end_latlng' => [
                                         '-31.80628',
                                         '115.816684'
                                       ],
                       'elevation_high' => '44.5',
                       'average_grade' => '0',
                       'start_longitude' => '115.816603',
                       'starred' => 0,
                       'id' => 6861382,
                       'distance' => '5039.3',
                       'start_latitude' => '-31.806149',
                       'end_longitude' => '115.816684',
                       'city' => 'Kingsley'
                     },
        'resource_state' => 2,
        'end_index' => 911,
        'name' => 'Lake Goolelel Kingfisher start',
        'activity' => {
                        'id' => 256892594
                      },
        'athlete' => {
                       'id' => 7972137
                     },
        'kom_rank' => undef
      },
      {
        'distance' => '2173.5',
        'id' => 6016562207,
        'achievements' => [],
        'elapsed_time' => 322,
        'start_date' => '2011-05-22T08:38:15Z',
        'start_index' => 319,
        'moving_time' => 322,
        'hidden' => 0,
        'start_date_local' => '2011-05-22T16:38:15Z',
        'pr_rank' => undef,
        'segment' => {
                       'id' => 6861363,
                       'distance' => '2207.4',
                       'start_longitude' => '115.811123',
                       'average_grade' => '-0.1',
                       'starred' => 0,
                       'start_latitude' => '-31.804051',
                       'end_longitude' => '115.815438',
                       'city' => 'Woodvale',
                       'end_latitude' => '-31.820064',
                       'elevation_low' => '28.9',
                       'maximum_grade' => '10.2',
                       'resource_state' => 2,
                       'activity_type' => 'Ride',
                       'country' => 'Australia',
                       'start_latlng' => [
                                           '-31.804051',
                                           '115.811123'
                                         ],
                       'name' => 'Goollelel Bike Path West',
                       'state' => 'WA',
                       'private' => 0,
                       'climb_category' => 0,
                       'end_latlng' => [
                                         '-31.820064',
                                         '115.815438'
                                       ],
                       'elevation_high' => '44.5'
                     },
        'end_index' => 632,
        'resource_state' => 2,
        'name' => 'Goollelel Bike Path West',
        'activity' => {
                        'id' => 256892594
                      },
        'kom_rank' => undef,
        'athlete' => {
                       'id' => 7972137
                     }
      },
      {
        'name' => 'Greenwood Grunt',
        'athlete' => {
                       'id' => 7972137
                     },
        'kom_rank' => undef,
        'activity' => {
                        'id' => 256892594
                      },
        'pr_rank' => undef,
        'start_date_local' => '2011-05-22T16:43:43Z',
        'resource_state' => 2,
        'end_index' => 673,
        'segment' => {
                       'end_longitude' => '115.819205',
                       'city' => 'Greenwood',
                       'distance' => '298.1',
                       'id' => 8045743,
                       'starred' => 0,
                       'average_grade' => '-0.9',
                       'start_longitude' => '115.816087',
                       'start_latitude' => '-31.820239',
                       'state' => 'Western Australia',
                       'name' => 'Greenwood Grunt',
                       'private' => 0,
                       'elevation_high' => '36.8',
                       'end_latlng' => [
                                         '-31.820191',
                                         '115.819205'
                                       ],
                       'climb_category' => 0,
                       'end_latitude' => '-31.820191',
                       'elevation_low' => '32.7',
                       'maximum_grade' => '2.7',
                       'resource_state' => 2,
                       'start_latlng' => [
                                           '-31.820239',
                                           '115.816087'
                                         ],
                       'activity_type' => 'Ride',
                       'country' => 'Australia'
                     },
        'hidden' => 0,
        'achievements' => [],
        'elapsed_time' => 35,
        'id' => 6016562209,
        'distance' => '259.3',
        'start_index' => 638,
        'moving_time' => 35,
        'start_date' => '2011-05-22T08:43:43Z'
      },
      {
        'start_date_local' => '2011-05-22T16:44:18Z',
        'pr_rank' => undef,
        'segment' => {
                       'maximum_grade' => '3.1',
                       'elevation_low' => '20.1',
                       'end_latitude' => '-31.806383',
                       'activity_type' => 'Ride',
                       'country' => 'Australia',
                       'start_latlng' => [
                                           '-31.8199955',
                                           '115.818779'
                                         ],
                       'resource_state' => 2,
                       'private' => 0,
                       'state' => 'WA',
                       'name' => 'Lake Goollelal Bike Path East',
                       'climb_category' => 0,
                       'end_latlng' => [
                                         '-31.806383',
                                         '115.816678'
                                       ],
                       'elevation_high' => '35.1',
                       'average_grade' => '-0.8',
                       'start_longitude' => '115.818779',
                       'starred' => 0,
                       'id' => 2277269,
                       'distance' => '1606.58',
                       'start_latitude' => '-31.8199955',
                       'end_longitude' => '115.816678',
                       'city' => 'Kingsley'
                     },
        'end_index' => 910,
        'resource_state' => 2,
        'name' => 'Lake Goollelal Bike Path East',
        'activity' => {
                        'id' => 256892594
                      },
        'kom_rank' => undef,
        'athlete' => {
                       'id' => 7972137
                     },
        'distance' => '1637.6',
        'achievements' => [],
        'elapsed_time' => 256,
        'id' => 6016562210,
        'start_date' => '2011-05-22T08:44:18Z',
        'start_index' => 673,
        'moving_time' => 256,
        'hidden' => 0,
      },
      {
        'hidden' => 0,
        'achievements' => [],
        'id' => 6016562220,
        'elapsed_time' => 328,
        'distance' => '2167.8',
        'moving_time' => 328,
        'start_index' => 1019,
        'start_date' => '2011-05-22T08:50:44Z',
        'name' => 'Goollelel Bike Path West',
        'athlete' => {
                       'id' => 7972137
                     },
        'kom_rank' => undef,
        'activity' => {
                        'id' => 256892594
                      },
        'pr_rank' => undef,
        'start_date_local' => '2011-05-22T16:50:44Z',
        'resource_state' => 2,
        'end_index' => 1330,
        'segment' => {
                       'name' => 'Goollelel Bike Path West',
                       'state' => 'WA',
                       'private' => 0,
                       'elevation_high' => '44.5',
                       'end_latlng' => [
                                         '-31.820064',
                                         '115.815438'
                                       ],
                       'climb_category' => 0,
                       'end_latitude' => '-31.820064',
                       'elevation_low' => '28.9',
                       'maximum_grade' => '10.2',
                       'resource_state' => 2,
                       'start_latlng' => [
                                           '-31.804051',
                                           '115.811123'
                                         ],
                       'activity_type' => 'Ride',
                       'country' => 'Australia',
                       'end_longitude' => '115.815438',
                       'city' => 'Woodvale',
                       'distance' => '2207.4',
                       'id' => 6861363,
                       'starred' => 0,
                       'start_longitude' => '115.811123',
                       'average_grade' => '-0.1',
                       'start_latitude' => '-31.804051'
                     }
      },
      {
        'activity' => {
                        'id' => 256892594
                      },
        'kom_rank' => undef,
        'athlete' => {
                       'id' => 7972137
                     },
        'name' => 'Greenwood Grunt',
        'segment' => {
                       'private' => 0,
                       'name' => 'Greenwood Grunt',
                       'state' => 'Western Australia',
                       'climb_category' => 0,
                       'elevation_high' => '36.8',
                       'end_latlng' => [
                                         '-31.820191',
                                         '115.819205'
                                       ],
                       'maximum_grade' => '2.7',
                       'elevation_low' => '32.7',
                       'end_latitude' => '-31.820191',
                       'country' => 'Australia',
                       'activity_type' => 'Ride',
                       'start_latlng' => [
                                           '-31.820239',
                                           '115.816087'
                                         ],
                       'resource_state' => 2,
                       'end_longitude' => '115.819205',
                       'city' => 'Greenwood',
                       'average_grade' => '-0.9',
                       'start_longitude' => '115.816087',
                       'starred' => 0,
                       'id' => 8045743,
                       'distance' => '298.1',
                       'start_latitude' => '-31.820239'
                     },
        'end_index' => 1370,
        'resource_state' => 2,
        'start_date_local' => '2011-05-22T16:56:18Z',
        'pr_rank' => undef,
        'hidden' => 0,
        'start_date' => '2011-05-22T08:56:18Z',
        'start_index' => 1335,
        'moving_time' => 36,
        'distance' => '267.4',
        'elapsed_time' => 36,
        'achievements' => [],
        'id' => 6016562223
      }
    ],
    'description' => 'Testing the Perl API Client',
    'total_elevation_gain' => '79.5',
    'truncated' => undef,
    'trainer' => 0,
    'upload_id' => 290510038,
    'location_state' => 'Western Australia',
    'calories' => 0,
    'average_speed' => '6.558',
    'start_latlng' => [
                        '-31.81998',
                        '115.81876'
                      ],
    'resource_state' => 3,
    'has_kudoed' => 0,
    'athlete_count' => 2,
    'comment_count' => 0,
    'gear' => {
                'resource_state' => 2,
                'primary' => 1,
                'id' => 'b1816631',
                'name' => 'Giant',
                'distance' => '11097'
              },
    'end_latlng' => [
                      '-31.80762',
                      '115.81718'
                    ],
    'external_id' => 'sample.gpx',
    'start_longitude' => '115.81876',
    'elapsed_time' => 1692,
    'map' => {
               'id' => 'a256892594',
               'resource_state' => 3
             },
    'start_latitude' => '-31.81998',
    'device_watts' => 0,
    'commute' => 0,
    'flagged' => 0,
    'photo_count' => 0,
    'start_date_local' => '2011-05-22T16:32:29Z',
    'manual' => 0,
    'max_speed' => '9.7',
    'private' => 1,
    'name' => 'API Test',
    'gear_id' => 'b1816631',
    'timezone' => '(GMT+08:00) Australia/Perth',
    'athlete' => {
                   'resource_state' => 1,
                   'id' => 7972137
                 }
  };
};

1;
