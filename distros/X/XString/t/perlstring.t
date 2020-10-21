#!./perl

use warnings;
use strict;

BEGIN  {
    eval { require threads; threads->import; }
}

use Test::More;

use XString ();

for my $do_utf8 (""," utf8") {
    my $max = $do_utf8 ? 1024  : 255;
    my @bad;
    for my $cp ( 0 .. $max ) {
        my $char= chr($cp);
        utf8::upgrade($char);
        my $escaped= XString::perlstring($char);
        my $evalled= eval $escaped;
        push @bad, [ $cp, $evalled, $char, $escaped ] if $evalled ne $char;
    }
    is(0+@bad, 0, "Check if any$do_utf8 codepoints fail to round trip through XString::perlstring()");
    if (@bad) {
        foreach my $tuple (@bad) {
            my ( $cp, $evalled, $char, $escaped ) = @$tuple;
            is($evalled, $char, "check if XString::perlstring of$do_utf8 codepoint $cp round trips ($escaped)");
        }
    }
}

done_testing();