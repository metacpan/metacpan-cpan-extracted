#!perl

use strict;
use warnings;

use Test::More tests => 2;
use WWW::ErnestMarples;

{
  my $em = WWW::ErnestMarples->new;
  my ( $lat, $lon ) = $em->lookup( 'CA9 3NT' );
  like $lat, qr/^-?\d+(?:\.\d+)?$/, 'lat ok';
  like $lon, qr/^-?\d+(?:\.\d+)?$/, 'lon ok';
}

# vim:ts=2:sw=2:et:ft=perl

