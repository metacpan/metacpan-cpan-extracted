use Test::More tests => 1;

my $text;

package Foo;
use perl5-ingy;

$text = io($0)->all;

package main;

like $text, qr/perl5-ingy/,
    'It looks like us';
