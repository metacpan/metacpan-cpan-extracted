#!/usr/bin/env perl
use lib './t/lib/';

use strict;
use Dancer2;

package WebService::Strava::CachedAPI {
  use Dancer2;
  use WebService::Strava::CachedAPI::Auth;
  my $DEBUG = $ENV{STRAVA_DEBUG} || 0;
  
  # Debug/Dev
  if ($DEBUG) {
    set logger => 'console';
    set log => 'core';
  }
  
  # Setting it in the config file didn't appear to work.
  # Not sure why, normally would use plackup, but unnecessary
  # here.
  set serializer => 'JSON';
  set port => 3001;
}

WebService::Strava::CachedAPI->to_app;

dance;
