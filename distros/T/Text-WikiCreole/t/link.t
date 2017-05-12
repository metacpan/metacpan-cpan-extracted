#!perl -T
use Test::Simple tests => 1;
use Text::WikiCreole;

# test user-supplied link modifying function

$markup = qq|This is a paragraph with an uppercased [[ link ]].
Check it out.|;

$goodhtml = qq|<p>This is a paragraph with an uppercased <a href="LINK">link</a>.
Check it out.</p>

|;

sub uppercase {
  $_[0] =~ s/([a-z])/\u$1/gso;
  return $_[0];
}

creole_link(\&uppercase);
$html = creole_parse $markup;

ok( $html eq $goodhtml );

