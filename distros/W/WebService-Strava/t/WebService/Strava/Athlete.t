#!/usr/bin/perl -w

use strict;
use Test::More;
use WebService::Strava;
use Test::Warnings;

SKIP: {
  skip "No auth credentials found.", 2 unless ( -e "$ENV{HOME}/.stravarc" );
  my $strava = WebService::Strava->new();
  &strava_test($strava, "Testing Live Strava API");
}

TODO: { # Convert to skip block once working
  todo_skip  "We use a configurable API endpoint internally, but we don't expose a way to set it.", 2;

  eval {  
    require Dancer2; 
    require Proc::Daemon;
  };

  skip 'These tests are for cached testing and require Proc::Daemon + Dancer2.', 2 if ($@);
  my $strava = WebService::Strava->new();
  &strava_test($strava, "Testing Cached Methods Locally");
}

sub strava_test {
  my ($strava,$message) = @_;
  my $athlete = $strava->athlete;
  subtest 'Athlete' => sub {
    isa_ok($athlete, 'WebService::Strava::Athlete');
    can_ok($athlete, qw(list_records));
    isnt($athlete->{firstname}, undef, 'User returned');
  
    if (@{$athlete->{clubs}}[0])  {
      subtest 'Athlete Clubs' => sub {
        is( ref( $athlete->{clubs} ), 'ARRAY', 'Clubs is an array' );
        isa_ok( @{$athlete->{clubs}}[0], 'WebService::Strava::Club');
        my $club_activities = @{$athlete->{clubs}}[0]->list_activities();
        if (@{$club_activities}[0]) {
          is( ref( $club_activities ), 'ARRAY', 'Club Activities is an array' );
          isa_ok( @{$club_activities}[0], 'WebService::Strava::Athlete::Activity');
          can_ok(@{$club_activities}[0], qw(retrieve));
        } else {
          note('Current club appears to have no activities');
        }
      };
    } else {
      note('Current authenticated user is not associated with a club');
    }
  
    if (@{$athlete->{bikes}}[0])  {
      subtest 'Athlete Bikes' => sub {
        is( ref( $athlete->{bikes} ), 'ARRAY', 'Bikes is an array' );
        isa_ok( @{$athlete->{bikes}}[0], 'WebService::Strava::Athlete::Gear::Bike');
      };
    } else {
      note('Current authenticated user doesn\'t have any bikes');
    }
  
    if (@{$athlete->{shoes}}[0])  {
      subtest 'Athlete Bikes' => sub {
        is( ref( $athlete->{shoes} ), 'ARRAY', 'Shoes is an array' );
        isa_ok( @{$athlete->{shoes}}[0], 'WebService::Strava::Athlete::Gear::Shoe');
      };
    } else {
      note('Current authenticated user doesn\'t have any shoes');
    }
  };
}

done_testing();
