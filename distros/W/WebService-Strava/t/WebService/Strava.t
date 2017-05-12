#!/usr/bin/perl -w

use strict;
use Test::More;
use WebService::Strava;
use Test::Warnings;

SKIP: {
  skip "No auth credentials found.", 3 unless ( -e "$ENV{HOME}/.stravarc" );
  my $strava = WebService::Strava->new();
  &strava_test($strava, "Testing Live Strava API");
}

TODO: { # Convert to skip block once working
  todo_skip  "We use a configurable API endpoint internally, but we don't expose a way to set it.", 3;

  eval {  
    require Dancer2; 
    require Proc::Daemon;
  };

  skip 'These tests are for cached testing and require Proc::Daemon + Dancer2. - Currently in TODO status.', 3 if ($@);
  my $strava = WebService::Strava->new();
  &strava_test($strava, "Testing Cached Methods Locally");
}

sub strava_test {
  my ($strava,$message) = @_;
  pass($message);
  subtest 'Strava' => sub {
    isa_ok($strava, 'WebService::Strava');
    isa_ok($strava->auth, 'WebService::Strava::Auth');
    can_ok($strava, qw(auth athlete clubs segment list_starred_segments
        effort activity list_activities list_friends_activities));  
    can_ok($strava->auth, qw(get post auth get_api setup));
    
    subtest 'Strava Methods' => sub {
      my $clubs = $strava->clubs;
      if (@{$clubs}[0])  {
        is( ref( $clubs ), 'ARRAY', 'Clubs is an array' );
        isa_ok( @{$clubs}[0], 'WebService::Strava::Club');
      } else {
        note('Current authenticated user is not associated with a club');
      }
  
      my $starred = $strava->list_starred_segments;
      if (@{$starred}[0])  {
        is( ref( $starred ), 'ARRAY', 'Starred is an array' );
        isa_ok( @{$starred}[0], 'WebService::Strava::Segment');
      } else {
        note('Current authenticated user has not starred a segment');
      }
  
      my $activities = $strava->list_activities;
      if (@{$activities}[0])  {
        is( ref( $activities ), 'ARRAY', 'Activities is an array' );
        isa_ok( @{$activities}[0], 'WebService::Strava::Athlete::Activity');
        #Check data was populated
        ok( defined( @{$activities}[0]->start_date ));
      } else {
        note('Current authenticated user has not got any activities');
      }
  
      my $friends_activities = $strava->list_friends_activities;
      if (@{$friends_activities}[0])  {
        is( ref( $friends_activities ), 'ARRAY', 'Friends activities is an array' );
        isa_ok( @{$friends_activities}[0], 'WebService::Strava::Athlete::Activity');
        #Check data was populated
        ok( defined( @{$friends_activities}[0]->start_date ));
      } else {
        note('Current authenticated user has not got any friends with activities');
      }
    };
  };
}

done_testing();
