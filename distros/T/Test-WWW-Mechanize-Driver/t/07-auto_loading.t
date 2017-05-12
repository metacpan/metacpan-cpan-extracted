#!/usr/bin/perl
#
# Test that running without loading anything will autoload.
# Example given in documentation is:
#
#   Test::WWW::Mechanize::Driver->new->run;

use strict; use warnings;
use lib qw/ t /;

use MyMechanize;
use Test::WWW::Mechanize::Driver;

my $tester = Test::WWW::Mechanize::Driver->new(
  mechanize => MyMechanize->new
);
$tester->mechanize->my_mech_load_files( glob("t/webpages/*.yml") );
$tester->run;
