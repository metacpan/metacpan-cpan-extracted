#!/usr/bin/perl
use strict; use warnings;
use lib qw/ lib t /;

use MyMechanize;
use Test::WWW::Mechanize::Driver;
my $mech = MyMechanize->new;
$mech->my_mech_load_files( glob("t/webpages/*.yml") );

Test::WWW::Mechanize::Driver->new(
  mechanize => $mech,
  base => 'http://test',
)->run;
