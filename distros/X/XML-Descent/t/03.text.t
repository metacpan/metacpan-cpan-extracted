#!perl

use strict;
use warnings;

use Test::More tests => 1;
use XML::Descent;

{
  my $text = "<b>This &amp; that</b>";
  my $xml  = "<p>$text</p>";

  my $p = XML::Descent->new( { Input => \$xml } );
  my $got;
  $p->on(
    p => sub {
      $got = $p->xml;
    }
  )->walk;
  is $got, $text, 'round trip OK';
}

# vim:ts=2:sw=2:et:ft=perl

