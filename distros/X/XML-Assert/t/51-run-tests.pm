#!/usr/bin/perl

use strict;
use warnings;

use Test::XML::Assert qw(no_plan);
use FindBin qw($Bin);
use lib "$Bin";

require 'data.pl';

my $parser = XML::LibXML->new();
my $doc = $parser->parse_string( xml() )->documentElement();

my $tests_pass = [
   {
       xpath => '//Error',
       count => 0,
       name  => 'No error in response',
   },
   {
       xpath => '//price',
       count => 3,
       name  => 'Three prices found',
   },
];

foreach my $t ( @$tests_pass ) {
    is_xpath_count($doc, {}, $t->{xpath}, $t->{count}, $t->{name} );
}
