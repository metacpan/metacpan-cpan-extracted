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
       xpath => q{/catalog/cd[1]/artist},
       match => q{Bob Dylan},
       name  => q{First artist is Bob Dylan},
   },
   {
       xpath => q{//cd[@genre][2]/@genre},
       match => q{Country},
       name  => q{Second CD with a 'genre' attribute is a Country album},
   },
];

my $xml_assert = XML::Assert->new();

foreach my $t ( @$tests_ok ) {
    ok( $xml_assert->does_xpath_value_match($doc, $t->{xpath}, $t->{match}), $t->{name} )
	    or diag($xml_assert->error);
}
