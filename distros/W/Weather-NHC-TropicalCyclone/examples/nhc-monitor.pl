#!/usr/bin/env perl

use strict;
use warnings;
use Weather::NHC::TropicalCyclone ();

my $nhc = Weather::NHC::TropicalCyclone->new;

my $stormsAdv = {};

WATCH:
while (1) {
    local $@;
    my $ok = eval {
      $nhc->fetch;
    };

    if (not $ok or $@) {
      print qq{Error fetching NHC JSON detected. Retrying in 5 seconds...\n};
      sleep 5;
      next WATCH;
    }

    my $storms_ref = $nhc->active_storms;

    STORMS:
    foreach my $storm (@$storms_ref) {
        my $advNum = $storm->publicAdvisory->{advNum};
        my $imgs_ref = $storm->fetch_forecastGraphics;
        if (not $stormsAdv->{$storm->id}->{$advNum}) {
           my ( $text, $advNum, $local_file ) = $storm->fetch_publicAdvisory;
          $stormsAdv->{$storm->id}->{$advNum} = $text;
          print qq{New advisory ($advNum) found for } . $storm->id . qq{!\n};
        } 
    }
    print qq{sleeping 30 seconds\n};
    sleep 30;
}
