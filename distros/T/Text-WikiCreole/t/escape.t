#!perl -T
use Test::Simple tests => 1;
use Text::WikiCreole;

$name = "escape";

# load the markup
open M, "<t/$name.markup" or die "failed to open $name.markup";
{ local $/; $markup = <M>; }
close M;

# load the html to compare
open H, "<t/$name.html" or die "failed to open $name.html";
{ local $/; $goodhtml = <H>; }
close H;

$html = creole_parse $markup;

ok( $html eq $goodhtml );

