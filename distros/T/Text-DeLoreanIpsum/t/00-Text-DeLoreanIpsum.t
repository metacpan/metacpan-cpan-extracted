# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Text-DeLoreanIpsum.t'

#########################

use strict;
use warnings;

use Test::More tests => 11;
BEGIN {
    use_ok('Text::DeLoreanIpsum');
    use_ok('Text::DeLoreanIpsumData');
    ok( my $object = Text::DeLoreanIpsum->new(),            "Made a new object" );
    ok( my $characters = $object->characters(),             "Got characters" );
    is( my @characters = split( / \/ /, $characters ), 42,  "List of characters" );
    ok( my $words = $object->words(3),                      "Got some words" );
    is( my @words = split( /\s+/, $words ), 3,              "There were 3 words" );
    ok( my $sentences = $object->sentences(3),              "Got some sentences" );
    is( my @sentences = split( /\./, $sentences ), 3,       "There were 3 sentences" );
    ok( my $paragraphs = $object->paragraphs(4),            "Got some paragraphs" );
    is( my @paragraphs = split ( /\n\n/, $paragraphs ), 4,  "There were 4 paragraphs" );
};
