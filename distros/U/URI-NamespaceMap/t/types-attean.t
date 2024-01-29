#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Requires { 'Attean' => '0.024' };
use Test::Requires { 'Types::Attean' => '0.024' };
use Types::Namespace qw( to_NamespaceMap to_Namespace to_Uri to_Iri );

use lib 't/lib';

use CommonTest qw(test_to_ns);

my $nsuri = URI::Namespace->new('http://www.example.net/');

isa_ok($nsuri, 'URI::Namespace');
is($nsuri->as_string, 'http://www.example.net/', "Correct string URI to Namespace");

use Attean;
use Types::Attean qw( to_AtteanIRI );
my $airi = to_AtteanIRI($nsuri);
isa_ok($airi, 'Attean::IRI');
is($airi->as_string, 'http://www.example.net/', "Correct string URI to AtteanIRI");
test_to_ns(Attean::IRI->new('http://www.example.net/'));



done_testing;
