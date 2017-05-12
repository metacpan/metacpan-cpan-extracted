#!/usr/bin/perl
#
# Test FileContents-blessed arguments
#
use strict; use warnings;
use lib qw/ t /;

use MyMechanize;
use Test::WWW::Mechanize::Driver qw/ Stacked FileContents ApplyTemplate /;
use Test::More;

my $tester = Test::WWW::Mechanize::Driver->new(
  mechanize => MyMechanize->new,
  after_response => sub {
    my ($mech, $opt) = @_;
    is( $$opt{fields}{foo}, 12,                    "plain field value" );
    is( "".$$opt{fields}{myfile}, "Hello World!\n",   "FileContents field value" );
    is( "".$$opt{fields}{stacked}, "HELLO HTTP://TEST/HOME.HTML!\n",  "Stacked field value" );
  },
  after_response_tests => 3,
);
$tester->mechanize->my_mech_load_files( glob("t/webpages/*.yml") );
$tester->run;
