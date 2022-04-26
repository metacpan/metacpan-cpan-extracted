use strict;
use warnings;
use Test::More;
use Text::Bidi qw(get_mirror_char);

open my $fh, '<', 't/MirrorTest.txt' 
    or plan skip_all => "can't open mirror table: $!";


foreach ( <$fh> ) {
    next if /^\s*(#|$)/;
    chomp;
    if ( /^(....); (....) # (.*$)/ ) {
        my $chr = "0x$1";
        my $mir = "0x$2";
        my $desc = $3;
        is chr(hex($chr)), get_mirror_char(chr(hex($mir))), "Wrong mirror for $mir ($desc)";
    }
}

done_testing;

