#!/usr/bin/perl

use v5.14;
use warnings;
use utf8;

use Test::More;

use B qw( svref_2object walkoptree );

use B::Deparse;
my $deparser = B::Deparse->new();

use lib "t";
use testcase "t::infix";

BEGIN { plan skip_all => "No PL_infix_plugin" unless XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN; }

BEGIN { $^H{"t::infix/permit"} = 1; }

{
   my $result = 10 add 20;
   is( $result, 30, 'add infix operator' );

   $result = 15 ⊕ 20;
   is( $result, 27, 'xor infix operator' );

   my $aref = ["|" intersperse qw( a b c )];
   is_deeply( $aref, [qw( a | b | c )],
      'intersperse infix operator' );

   my @list = qw( x y z );
   $aref = ["|" intersperse @list];
   is_deeply( $aref, [qw( x | y | z )],
      'intersperse infix operator on PADAV' );

   is_deeply( [ (2, 4, 6) addpairs (1, 1, 1) ],
      [ 3, 5, 7 ], 'addpairs infix operator' );
}

sub is_deparsed
{
   my ( $sub, $exp, $name ) = @_;

   my $got = $deparser->coderef2text( $sub );

   # Deparsed output is '{ ... }'-wrapped
   $got = ( $got =~ m/^{\n(.*)\n}$/s )[0];

   # Deparsed output will have a lot of pragmata and so on; just grab the
   # final line
   $got = ( split m/\n/, $got )[-1];
   $got =~ s/^\s+//;

   is( $got, $exp, $name );
}

{
   is_deparsed sub { $_[0] add $_[1] },
      '$_[0] add $_[1];',
      'deparsed call to infix operator';

   is_deparsed sub { $_[0] ⊕ $_[1] },
      '$_[0] ⊕ $_[1];',
      'deparsed operator yields UTF-8';

   is_deparsed sub { "+" intersperse (1,2,3) },
      q['+' intersperse (1, 2, 3);],
      'deparsed call to infix operator with list RHS';

   is_deparsed sub { (1,2,3) addpairs (4,5,6) },
      '(1, 2, 3) addpairs (4, 5, 6);',
      'deparsed call to infix list/list operator';
}

done_testing;
