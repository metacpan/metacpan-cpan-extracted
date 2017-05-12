#!perl -T
use Test::Simple tests => 1;
use Text::WikiCreole;

# test user-customized open tag

creole_tag("p", "open", "<p class=special>");

$markup = qq|This is a paragraph.|;

$goodhtml = qq|<p class=special>This is a paragraph.</p>

|;

$html = creole_parse $markup;

ok( $html eq $goodhtml );

