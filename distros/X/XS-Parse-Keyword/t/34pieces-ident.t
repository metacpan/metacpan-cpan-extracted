#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use lib "t";
use testcase "t::pieces";

BEGIN { $^H{"t::pieces/permit"} = 1; }

{
   my $ret = pieceident foobar;
   is( $ret, "foobar", 'result of pieceident' );

   ok( !defined eval 'pieceident',
      'pieceident complains of missing ident' );
   like( $@, qr/^Expected an identifier at /, 'message from missing ident' );
}

{
   my $ret = pieceident_opt present;
   is( $ret, "present", 'result of pieceident_opt with ident' );

   $ret = pieceident_opt;
   ok( !defined $ret, 'result of pieceident_opt without' );
}

{
   my $ret = piecepkg Bar::Foo;
   is( $ret, "Bar::Foo", 'result of piecepkg' );

   ok( !defined eval 'piecepkg',
      'piecepkg complains of missing packagename' );
   like( $@, qr/^Expected a package name at /, 'message from missing packagename' );
}

done_testing;
