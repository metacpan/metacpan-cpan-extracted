#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;
use XML::Assert;
use FindBin qw($Bin);
use lib "$Bin";

# $XML::Compare::VERBOSE = 1;

require 'data.pl';

my $parser = XML::LibXML->new();
my $doc = $parser->parse_string( xml() )->documentElement();

my $exceptions_count = [
   {
       xpath => q{//cd},
       count => 2,
       name  => q{Should be 3 CDs not 2},
       error => qr{has 3 nodes},
   },
   {
       xpath => q{//cd[@genre='Country']},
       count => 2,
       name  => q{Should be one Country album, not 2},
       error => qr{has 1 node},
   },
];

my $exceptions_match = [
   {
       xpath => q{//cd},
       match => qr{Shouldn't even get to this match},
       name  => q{Can't match on multiple nodes},
       error => qr{matched 3 nodes},
   },
   {
       xpath => q{//cd[@genre='Country']},
       match => qr{Bonnie Tyler},
       name  => q{The Country CD is Dolly Parton},
       error => qr{doesn't match},
   },
];

foreach my $t ( @$exceptions_count ) {
    throws_ok(
        sub { XML::Assert->assert_xpath_count( $doc, $t->{xpath}, $t->{count}) },
        $t->{error},
        $t->{name},
    );
}

foreach my $t ( @$exceptions_match ) {
    throws_ok(
        sub { XML::Assert->assert_xpath_value_match( $doc, $t->{xpath}, $t->{match}) },
        $t->{error},
        $t->{name},
    );
}
