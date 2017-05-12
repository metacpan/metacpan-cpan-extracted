#!/usr/bin/perl
#
# Focus on Test::WWW::Mechanize tests, very little Driver magic
#
use strict; use warnings;
use lib qw/ t /;

use MyMechanize;
use Test::WWW::Mechanize::Driver;

my $tester = Test::WWW::Mechanize::Driver->new(
  mechanize => MyMechanize->new,
  base => 'http://test/',
);
$tester->mechanize->my_mech_load_files( glob("t/webpages/*.yml") );
$tester->run;
