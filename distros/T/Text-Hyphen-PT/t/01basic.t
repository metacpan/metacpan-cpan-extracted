#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use open qw(:std :encoding(utf-8));
use Test::More;

use Text::Hyphen::PT;

ok( my $hyp = Text::Hyphen::PT->new, 'hyphenator loaded' );

sub is_hyph ($$) {
    my ( $word, $expected ) = @_;
    my $result = $hyp->hyphenate($word);
    is( $result, $expected, qq{hyphenated another word} );
}

is_hyph('Trabalhadores','Tra-ba-lha-do-res');
is_hyph('Trabalhador','Tra-ba-lha-dor');
is_hyph('canção','can-ção');
is_hyph('caráter','ca-rá-ter');

done_testing;
