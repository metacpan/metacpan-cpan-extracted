#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Test::More;

use Text::Hyphen::DE;

ok( my $hyp = Text::Hyphen::DE->new, 'hyphenator loaded' );

sub is_hyph ($$) {
    my ( $word, $expected ) = @_;
    my $result = $hyp->hyphenate($word);
    is( $result, $expected, qq{hyphenated another word} );
}

is_hyph('Arbeiterinnen','Ar-bei-te-rin-nen');
is_hyph('Arbeiter','Ar-bei-ter');

done_testing;
