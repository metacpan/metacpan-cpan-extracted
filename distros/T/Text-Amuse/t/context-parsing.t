#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 40;
use Text::Amuse::Functions qw/muse_to_html
                              muse_to_tex
                              muse_to_object
                             /;

use Data::Dumper;

{
    my $muse =<<'MUSE';
Prova

<example>

                         Signed.<br>
                         A. Pallino

</example>

<verse>
Prova
    Prova
</verse>

> this is a verse
>
>   And This is the same

 a. test

Test
MUSE

    my $doc = muse_to_object($muse);
    my @elements = $doc->document->elements;
    my @expected = ([null => 'null'],
                    [regular => 'regular'],
                    [null => 'null'],
                    [example => 'example'],
                    [null => 'null'],
                    [null => 'null'],
                    [verse => 'verse'],
                    [null => 'null'],
                    [null => 'null'],                    
                    [verse => 'verse'],
                    [null => 'null'],
                    [startblock => 'ola'],
                    [startblock => 'li'],
                    [regular => 'regular'],
                    [null => 'null'],
                    [stopblock => 'li'],
                    [stopblock => 'ola'],
                    [regular => 'regular'],
                   );
    foreach my $i (0..$#expected) {
        is ($elements[$i]->type, $expected[$i][0],
            "type of block $i: " . $expected[$i][0]);
        is ($elements[$i]->block, $expected[$i][1],
            "block $i: is " . $expected[$i][1]);
    }
    ok ($doc->as_html);
    ok ($doc->as_latex);
    my $raw_round_trip = join('', map { $_->rawline } @elements);
    is $raw_round_trip, $muse . "\n\n", "no text was lost";
    is (join('', $doc->document->raw_body), $muse . "\n\n", "no text was lost");
}

