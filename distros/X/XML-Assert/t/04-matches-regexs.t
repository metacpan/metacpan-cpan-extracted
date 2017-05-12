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
my $doc = $parser->parse_string( xml() );

my $tests_ok = [
   {
       xpath => q{//cd[@genre='Country']},
       match => qr{Dolly Parton},
       msg   => q{The Country CD is Dolly Parton},
   },
   {
       xpath => q{//year},
       match => qr{\d{4}},
       msg   => q{All years are \d\d\d\d},
   },
];

my $xml_assert = XML::Assert->new();

foreach my $t ( @$tests_ok ) {
    ok( $xml_assert->do_xpath_values_match($doc, $t->{xpath}, $t->{match}), $t->{name} )
	    or diag($xml_assert->error);
}
