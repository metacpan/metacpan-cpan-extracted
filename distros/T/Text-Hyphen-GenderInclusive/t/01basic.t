#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Test::More;

use Text::Hyphen::GenderInclusive;

ok( my $hyp = Text::Hyphen::GenderInclusive->new( class => 'Text::Hyphen::DE' ),
    'hyphenator loaded' );

sub is_hyph ($$) {
    my ( $word, $expected ) = @_;
    my $result = $hyp->hyphenate($word);
    is( $result, $expected, qq{hyphenated another word} );
}

is_hyph( 'Arbeiter*innen', 'Ar-bei-te-r*in-nen' );
is_hyph( 'Arbeiter?innen', 'Ar-bei-ter?in-nen' );

done_testing;
