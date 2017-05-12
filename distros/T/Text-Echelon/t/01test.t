#!/usr/bin/perl -w

use strict;
use Test::More tests => 10;

use_ok('Text::Echelon');

my $original = \@Text::Echelon::Wordlist;
@Text::Echelon::Wordlist = qw(apple);

my $ech = Text::Echelon->new();

isa_ok($ech, "Text::Echelon");

#-----------------------------------------------------------------------------
# Test get
#-----------------------------------------------------------------------------

my $phrase = $ech->get;

isnt($phrase, undef, "get returns defined value");
isnt($phrase, "", "get doesn't return an empty string");

#-----------------------------------------------------------------------------
# Test getmany
#-----------------------------------------------------------------------------

my @many = split ",", $ech->getmany();

is(@many, 3, "got three phrases");

@many = split ":", $ech->getmany(5, ": ");

is(@many, 5, "got five phrases");

#-----------------------------------------------------------------------------
# Test make custom
#-----------------------------------------------------------------------------

$phrase = $ech->makecustom("wibble:");

my ($header, $words) = split ":", $phrase;

@many = split ",", $words;

is($header, "wibble", "header is correct");
is(@many, 3, "got the default number of phrases");

#-----------------------------------------------------------------------------
# test makeheader
#-----------------------------------------------------------------------------

$phrase = $ech->makeheader();

($header, $words) = split ":", $phrase;

@many = split ",", $words;

is($header, "X-Echelon", "header is correct");
is(@many, 3, "got the default number of phrases");

