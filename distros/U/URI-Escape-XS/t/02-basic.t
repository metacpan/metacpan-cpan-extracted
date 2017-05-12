#!perl -w
#
# $Id: 02-basic.t,v 0.2 2015/06/27 00:28:39 dankogai Exp $
#
# Original as URI-1.35/t/escape.t
#

use URI::Escape::XS;
use Test::More tests => 697;

# basic round-trip test
for my $ord (  0 .. 255 ) {
    use bytes;
    my $chr = chr $ord;
    my $esc = $chr =~ /[A-Za-z0-9\-_.!~*'()]/ ? $chr : sprintf "%%%02X", $ord;
    is encodeURIComponent($chr) => $esc, "encodeURIComponent(ord $ord)";
    is decodeURIComponent($esc) => $chr, "decodeURIComponent($esc)";
    if ($esc =~ /^%/) {
        my $lesc = lc $esc;
        is decodeURIComponent($lesc) => $chr, "decodeURIComponent($lesc)";
    }
}
