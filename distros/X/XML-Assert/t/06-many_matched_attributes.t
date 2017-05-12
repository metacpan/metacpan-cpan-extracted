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

my $tests_ok = [
   {
       xpath => q{//cd},
       attr  => q{barcode},
       match => qr{ \A \d-\d{6}-\d{6} \z }xms,
       name  => q{All barcodes should match this regex},
   },
];

my $tests_ok_ns = [
   {
       xpath => q{//cat:cd},
       attr  => q{barcode},
       match => qr{ \A \d-\d{6}-\d{6} \z }xms,
       name  => q{All barcodes should match this regex},
   },
];

# no namespace
my $doc = $parser->parse_string( xml() )->documentElement();
my $xml_assert = XML::Assert->new();
foreach my $t ( @$tests_ok ) {
    ok( $xml_assert->do_attr_values_match($doc, $t->{xpath}, $t->{attr}, $t->{match}), $t->{name} )
	    or diag($xml_assert->error);
}

# with namespace
my $doc_ns = $parser->parse_string( xml_ns() )->documentElement();
$xml_assert->xmlns({
    'cat' => 'urn:catalog',
});
foreach my $t ( @$tests_ok_ns ) {
    ok( $xml_assert->do_attr_values_match($doc_ns, $t->{xpath}, $t->{attr}, $t->{match}), $t->{name} )
	    or diag($xml_assert->error);
}
