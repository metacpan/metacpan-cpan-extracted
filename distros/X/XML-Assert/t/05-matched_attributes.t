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
       xpath => q{//cd[2]},
       attr  => q{genre},
       match => q{Pop},
       msg   => q{The first CD should be 'Pop'},
   },
   {
       xpath => q{//cd[3]},
       attr  => q{genre},
       match => qr{ \A C }xms,
       msg   => q{The third CD should begin with 'C'},
   },
];

my $tests_ok_ns = [
   {
       xpath => q{//cat:cd[2]},
       attr  => q{genre},
       match => q{Pop},
       msg   => q{The first CD should be 'Pop'},
   },
   {
       xpath => q{//cat:cd[3]},
       attr  => q{genre},
       match => qr{ \A C }xms,
       msg   => q{The third CD should begin with 'C'},
   },
];

# no namespace
my $doc = $parser->parse_string( xml() );
my $xml_assert = XML::Assert->new();
foreach my $t ( @$tests_ok ) {
    ok( $xml_assert->does_attr_value_match($doc, $t->{xpath}, $t->{attr}, $t->{match}), $t->{name} )
	    or diag($xml_assert->error);
}

# with namespace
my $doc_ns = $parser->parse_string( xml_ns() )->documentElement();
$xml_assert->xmlns({
    'cat' => 'urn:catalog',
});
foreach my $t ( @$tests_ok_ns ) {
    ok( $xml_assert->does_attr_value_match($doc_ns, $t->{xpath}, $t->{attr}, $t->{match}), $t->{name} )
	    or diag($xml_assert->error);
}
