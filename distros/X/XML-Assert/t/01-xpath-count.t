#!/usr/bin/perl

use strict;
use warnings;
use Test::More qw(no_plan);
use XML::Assert;
use XML::LibXML;
use FindBin qw($Bin);
use lib "$Bin";

# $XML::Assert::VERBOSE = 1;

require 'data.pl';

my $parser = XML::LibXML->new();
my $doc = $parser->parse_string( xml() )->documentElement();

my $tests_ok = [
   {
       xpath => '//Error',
       count => 0,
       name  => 'Error in response',
   },
   {
       xpath => '/catalog/cd',
       count => 3,
       name  => 'Three CDs available',
   },
   {
       xpath => '//cd',
       count => 3,
       name  => 'Three CDs available everywhere',
   },
   {
       xpath => '//title',
       count => 3,
       name  => 'Three titles found',
   },
   {
       xpath => '//rating',
       count => 2,
       name  => 'Only two ratings',
   },
   {
       xpath => '//@genre',
       count => 2,
       name  => 'Three genres found',
   },
];

my $tests_fail = [
   {
       xpath => '//price',
       count => 2,
       name  => 'Three prices, not two',
   },
];

my $xml_assert = XML::Assert->new();

foreach my $t ( @$tests_ok ) {
    ok( $xml_assert->is_xpath_count($doc, $t->{xpath}, $t->{count}), $t->{name} )
	    or diag($xml_assert->error);
}

foreach my $t ( @$tests_fail ) {
    ok( !$xml_assert->is_xpath_count($doc, $t->{xpath}, $t->{count}), $t->{name} );
}
