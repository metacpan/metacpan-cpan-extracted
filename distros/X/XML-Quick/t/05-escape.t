#!perl -T

use warnings;
use strict;

use Test::More;
use XML::Quick;

plan tests => 8;

my @tests = qw(
    &   &amp;
    <   &lt;
    >   &gt;
    "   &quot;

    abcdefghijklmnopqrstuvwxyz  abcdefghijklmnopqrstuvwxyz
    ABCDEFGHIJKLMNOPQRSTUVWXYZ  ABCDEFGHIJKLMNOPQRSTUVWXYZ

    v&lue       v&amp;lue
    <html>      &lt;html&gt;
);

while(@tests > 1) {
    my $in = shift @tests;
    my $out = shift @tests;

    is(xml($in), $out);
}

diag("test set had leftover items, probable bug in $0") if @tests > 0;
