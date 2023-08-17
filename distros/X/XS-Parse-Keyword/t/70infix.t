#!/usr/bin/perl

use v5.14;
use warnings;
use utf8;

use Test2::V0;

use B::Deparse;
my $deparser = B::Deparse->new( "-p" );

use lib "t";
use testcase "t::infix";

BEGIN { plan skip_all => "No PL_infix_plugin" unless XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN; }

use v5.16;

BEGIN { $^H{"t::infix/permit"} = 1; }

{
   my $result = 10 add 20;
   is( $result, 30, 'add infix operator' );

   $result = 15 ⊕ 20;
   is( $result, 27, 'xor infix operator' );

   my $aref = ["|" intersperse qw( a b c )];
   is( $aref, [qw( a | b | c )],
      'intersperse infix operator' );

   my @list = qw( x y z );
   $aref = ["|" intersperse @list];
   is( $aref, [qw( x | y | z )],
      'intersperse infix operator on PADAV' );

   is( [ (2, 4, 6) addpairs (1, 1, 1) ],
      [ 3, 5, 7 ], 'addpairs infix operator' );
}

sub _getoptree
{
   my ( $sub ) = @_;

   # Ugh - this would be so much neater if we could pass coderefs into
   # B::walkoptree directly
   # Additionally there's no pre-mid-postfix walk options :(

   my $dump_optree = sub {
      my $sub = __SUB__;
      my ( $op ) = @_;
      my $opname = $op->name;

      # Avoid test-dependence on the actual ppaddr by mangling out the name
      $opname =~ s/0x[[:xdigit:]]+/0xXXX/;

      return $op->first->$sub if $opname eq "null";

      my @kids;
      if( $op->flags & B::OPf_KIDS ) {
         my $kid = $op->first;
         while( $kid ) {
            push @kids, $kid->$sub;

            $kid = $kid->sibling; undef $kid if ref($kid) eq "B::NULL";
         }
      }

      my $ret = $opname;
      $ret .= "[" . join( ", ", @kids ) . "]" if @kids;
      return $ret;
   };

   # Reach inside to the first statement
   return B::svref_2object( $sub )->ROOT->first->first->sibling
      ->$dump_optree;
}

sub is_optree
{
   my ( $sub, $exp, $name ) = @_;
   is( _getoptree( $sub ), $exp, $name );
}

{
   is_optree sub { $_[0] add $_[1] },
      "infix_add_0xXXX[aelemfast, aelemfast]",
      'optree of call to infix operator';

   # Check precedence of operator parsing by observing the following precedence
   # ordering:
   #   <--High      Low-->
   #      **  *  +  &&

   is_optree sub { $_[0] * $_[1] add $_[2] * $_[3] },
      "infix_add_0xXXX[multiply[aelemfast, aelemfast], multiply[aelemfast, aelemfast]]",
      'optree binds add lower than *';
   is_optree sub { $_[0] + $_[1] add $_[2] + $_[3] },
      "add[infix_add_0xXXX[add[aelemfast, aelemfast], aelemfast], aelemfast]",
      'optree binds add equal to +';
   is_optree sub { $_[0] && $_[1] add $_[2] && $_[3] },
      "and[and[aelemfast, infix_add_0xXXX[aelemfast, aelemfast]], aelemfast]",
      'optree binds add higher than &&';

   is_optree sub { $_[0] ** $_[1] mul $_[2] ** $_[3] },
      "infix_mul_0xXXX[pow[aelemfast, aelemfast], pow[aelemfast, aelemfast]]",
      'optree binds mul lower than **';
   is_optree sub { $_[0] * $_[1] mul $_[2] * $_[3] },
      "multiply[infix_mul_0xXXX[multiply[aelemfast, aelemfast], aelemfast], aelemfast]",
      'optree binds mul equal to *';
   is_optree sub { $_[0] + $_[1] mul $_[2] + $_[3] },
      "add[add[aelemfast, infix_mul_0xXXX[aelemfast, aelemfast]], aelemfast]",
      'optree binds mul higher than +';

   is_optree sub { $_[0] * ($_[1] add $_[2]) * $_[3] },
      "multiply[multiply[aelemfast, infix_add_0xXXX[aelemfast, aelemfast]], aelemfast]",
      'optree of call to infix operator at forced precedence';
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
      'deparsed call to infix add operator';

   is_deparsed sub { $_[0] * $_[1] add $_[2] * $_[3] },
      '($_[0] * $_[1]) add ($_[2] * $_[3]);',
      'deparsed call to infix add operator at default precedence';

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
