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

  skip 'These tests are for cached testing and require Proc::Daemon + Dancer2. - Currently in TODO status.', 2 if ($@);
  my $strava = WebService::Strava->new();
  &strava_test($strava, "Testing Cached Methods Locally");
}

sub strava_test {
  my ($strava,$message) = @_;
  my $segment = $strava->segment(3468536);
  subtest 'Segment' => sub {
    isa_ok($segment, 'WebService::Strava::Segment');
    can_ok($segment, qw(retrieve list_efforts leaderboard));
    is($segment->{activity_type}, 'Ride', 'activity_type is a Ride');
    
    subtest 'Segment: List Efforts' => sub { 
      my $efforts = $segment->list_efforts;
      is( ref( $efforts ), 'ARRAY', 'Efforts is an array' );
      isa_ok( @{$efforts}[0], 'WebService::Strava::Athlete::Segment_Effort');
      can_ok(@{$efforts}[0], qw(retrieve));
    };
    
    subtest 'Segment: Leaderboard' => sub { 
      my $leaderboard = $segment->leaderboard;
      is( ref( $leaderboard ), 'ARRAY', 'Leaderboard is an array' );
    };
  };
}

done_testing();
