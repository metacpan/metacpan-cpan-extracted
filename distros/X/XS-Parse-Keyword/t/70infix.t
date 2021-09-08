#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use B qw( svref_2object walkoptree );

use lib "t";
use testcase "t::infix";

BEGIN { $^H{"t::infix/permit"} = 1; }

{
   my $result = t::infix::addfunc( 10, 20 );
   is( $result, 30, 'add wrapper func' );
}

sub count_ops
{
   my ( $code ) = @_;
   my %opcounts;

   # B::walkoptree() is stupid
   #   https://github.com/Perl/perl5/issues/19101
   no warnings 'once';
   local *B::OP::collect_opnames = sub {
      my ( $op ) = @_;
      $opcounts{ $op->name }++ unless $op->name eq "null";
   };
   walkoptree( svref_2object( $code )->ROOT, "collect_opnames" );

   return %opcounts;
}

# callhecker rewrote the optree
{
   my %opcounts;

   %opcounts = count_ops sub { t::infix::addfunc( $_[0], $_[1] ) };

   # If the callchecker ran correctly we should see one 'custom' op and no
   # 'entersub's
   ok(  $opcounts{custom},   'callchecker generated an OP_CUSTOM call' );
   ok( !$opcounts{entersub}, 'callchecker removed an OP_ENTERSUB call' );

   # Opchecker should ignore non-scalar args
   %opcounts = count_ops sub { t::infix::addfunc( @_, "more" ) };
   ok( !$opcounts{custom},   'No OP_CUSTOM call for DEFAV' );

   %opcounts = count_ops sub { t::infix::addfunc( lhs(), rhs() ) };
   ok( !$opcounts{custom},   'No OP_CUSTOM call for list ENTERSUB' );

   # Opchecker still permits scalar entersub calls
   %opcounts = count_ops sub { t::infix::addfunc( scalar lhs(), scalar rhs() ) };
   ok(  $opcounts{custom},   'OP_CUSTOM call for scalar ENTERSUB' );
}

# wrapper func by coderef
{
   my $wrapper = \&t::infix::addfunc;
   is( $wrapper->( 30, 40 ), 70, 'add wrapper func by CODE reference' );
}

# argument checking
{
   ok( !eval { t::infix::addfunc( 10, 20, 30 ) },
      'Wrapper func fails for too many args' );
   like( $@, qr/^Too many arguments for subroutine 't::infix::addfunc'/,
      'Failure message for too many args' );

   ok( !eval { t::infix::addfunc( 60 ) },
      'Wrapper func fails for too few args' );
   like( $@, qr/^Too few arguments for subroutine 't::infix::addfunc'/,
      'Failure message for too few args' );
}

done_testing;
