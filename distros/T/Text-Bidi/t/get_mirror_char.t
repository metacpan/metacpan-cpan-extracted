use strict;
use warnings;
use open qw[:encoding(UTF-8) :std];
use Test::More;
use Text::Bidi qw(get_mirror_char);

open my $fh, '<', 't/MirrorTest.txt' 
    or plan skip_all => "can't open mirror table: $!";


foreach ( <$fh> ) {
    next if /^\s*(#|$)/;
    chomp;
    if ( /^(....); (....) # (.*$)/ ) {
        my ($chr, $mir, $desc) = ($1, $2, $3);
        is chr(hex($chr)), get_mirror_char(chr(hex($mir))),
            "Wrong mirror for $mir ($desc)";
    }
}

done_testing;

