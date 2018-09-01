#!/usr/bin/env perl
use 5.006;
use strict;
use warnings;
use Test::More;

use utf8;

use Unicode::Homoglyph::Replace;

plan tests => 84;

diag( "Testing Unicode::Homoglyph::Replace $Unicode::Homoglyph::Replace::VERSION, Perl $], $^X" );



# First, a map of known disguised homoglpyh => ASCII tests:
my %tests = (
    'Saỿ іt ⅼⲟuⅾ aᥒⅾ siᥒɡ it рrοᥙd tⲟdɑỿⵑ'
        => 'Say it loud and sing it proud today!',
    'Теⅼⅼ tһᥱⅿ ᥒоt tο feаr nഠ mഠrᥱ'
        => 'Tell them not to fear no more',
    '﹛｝／⁚' => '{}/:',
    '1∼ᒿ⁓3~4﹕ⵑ￨｛{}﹜⎢￨ᛁ' => '1~2~3~4:!|{{}}|||',
);
while(my($disguised, $ascii) = each(%tests)) {
    is(
        Unicode::Homoglyph::Replace::replace_homoglyphs($disguised),
        $ascii,
        "Decoded '$disguised' to '$ascii'",
    );   
}



# Secondly, call disguise() a bunch of times with various inputs, feeding its
# result to replace_homoglyphs, and make sure we get the same text back -
# testing both methods at once, and doing it often enough that we should
# statistically hit most of the possible homoglyphs (since we pick at random
# in disguise())
for my $test_string (
    "Take the time to make some sense",
    "Of what you want to say,",
    "And cast your words away upon the waves.",
    "Sail them home with acquiesce,",
    "On a ship of hope today",
    "And as they land upon the shore",
    "Tell them not to fear no more",
    "Say it loud and sing it proud today!",
) {
    for (1..10) {
        my $disguised = Unicode::Homoglyph::Replace::disguise($test_string);
        diag "$test_string => $disguised";
        is(
            Unicode::Homoglyph::Replace::replace_homoglyphs($disguised),
            $test_string,
            "$disguised goes back to $test_string",
        );
    }
}

