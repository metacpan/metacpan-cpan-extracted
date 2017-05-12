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
my $doc = $parser->parse_string( xml_ns() )->documentElement();

my $tests_ok = [
   {
       xpath => '//Error',
       count => 0,
       name  => 'Error in response',
   },
   {
       xpath => '/cat:catalog/cat:cd',
       count => 3,
       name  => 'Three CDs available',
   },
   {
       xpath => '//cat:cd',
       count => 3,
       name  => 'Three CDs available everywhere',
   },
   {
       xpath => '//cat:title',
       count => 3,
       name  => 'Three titles found',
   },
   {
       xpath => '//cat:rating',
       count => 2,
       name  => 'Only two ratings',
   },
   # this attribute doesn't need a namespace since they don't belong to one
   # (only inherited somewhat from the element they are in)
   {
       xpath => '//@genre',
       count => 2,
       name  => 'Three genres found',
   },
];

my $tests_fail = [
   {
       xpath => '//cat:price',
       count => 2,
       name  => 'Three prices, not two',
   },
];

my $xml_assert = XML::Assert->new();
$xml_assert->xmlns({
    'cat' => 'urn:catalog',
});

foreach my $t ( @$tests_ok ) {
    ok( $xml_assert->is_xpath_count($doc, $t->{xpath}, $t->{count}), $t->{name} )
	    or diag($xml_assert->error);
}

foreach my $t ( @$tests_fail ) {
    ok( !$xml_assert->is_xpath_count($doc, $t->{xpath}, $t->{count}), $t->{name} );
}

