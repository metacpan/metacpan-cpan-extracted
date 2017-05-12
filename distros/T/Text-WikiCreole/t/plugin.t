#!perl -T
use Test::Simple tests => 1;
use Text::WikiCreole;

# test user-supplied plugin function

$markup = qq|This is a paragraph with an uppercasing << plugin >>.
Check it out.|;

$goodhtml = qq|<p>This is a paragraph with an uppercasing  PLUGIN .
Check it out.</p>

|;

sub uppercase {
  $_[0] =~ s/([a-z])/\u$1/gso;
  return $_[0];
}

creole_plugin(\&uppercase);
$html = creole_parse $markup;

ok( $html eq $goodhtml );

