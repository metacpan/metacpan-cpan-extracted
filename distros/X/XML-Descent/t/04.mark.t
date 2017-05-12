#!perl

use strict;
use warnings;

use XML::Descent;
use Test::More;

plan skip_all => 'mark/rewind not done yet';
plan tests    => 4;

{
  my $inner  = "<b>Foo</b>";
  my $middle = "<p>$inner</p>";
  my $outer  = "<body>$middle</body>";

  my $p = XML::Descent->new( { Input => \$outer } );
  $p->on(
    body => sub {
      my $got_p = 0;
      $p->on(
        p => sub {
          $got_p++;
          my $got_b = 0;
          $p->on( b => sub { $got_b++ } );
          $p->mark->walk;
          my $txt_b = $p->rewind->text;
          is $got_b, 1,     'inner walk';
          is $txt_b, 'Foo', 'inner text';
        }
      );
      $p->mark->walk;
      my $xml_p = $p->rewind->xml;
      is $got_p, 1, 'middle walk';
      is $xml_p, $middle, 'middle text';
    }
  );
  $p->walk;

}

# vim:ts=2:sw=2:et:ft=perl

