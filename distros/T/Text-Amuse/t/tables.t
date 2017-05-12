#!perl

use strict;
use warnings;
use Test::More tests => 10;
use Text::Amuse::Functions qw/muse_to_html muse_to_tex/;

{
    my $muse =<<'MUSE';
#title test

|test me|

MUSE
    my $html = muse_to_html($muse);
    my $ltx  = muse_to_tex($muse);
    like $html, qr{\|test me\|};
    unlike $html, qr{<table>};
    like $ltx, qr{\\textbar\{\}test me\\textbar\{\}};
    unlike $ltx, qr{tabularx};
}


{
    my $muse =<<'MUSE';
#title test

 |test me|

MUSE
    my $html = muse_to_html($muse);
    my $ltx  = muse_to_tex($muse);
    unlike $html, qr{\|test me\|};
    like $html, qr{<table>};
    unlike $ltx, qr{\\textbar\{\}};
    like $ltx, qr{tabularx};
    like $html, qr{test me};
    like $ltx, qr{test me};
}




