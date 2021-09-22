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

BEGIN { $^H{"t::infix/permit"} = 1; }

{
   my $result = t::infix::addfunc( 10, 20 );
   is( $result, 30, 'add wrapper func' );

   my $aref = [ t::infix::interspersefunc( "Z", "a", "b" ) ];
   is_deeply( $aref, [qw( a Z b )], 'intersperse wrapper func' );
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
   ok( (scalar grep { m/^infix_0x/ } keys %opcounts),
      'callchecker generated an OP_CUSTOM call' );
   ok( !$opcounts{entersub}, 'callchecker removed an OP_ENTERSUB call' );

   # Opchecker should ignore non-scalar args
   %opcounts = count_ops sub { t::infix::addfunc( @_, "more" ) };
   ok( !$opcounts{custom},   'No OP_CUSTOM call for DEFAV' );

   %opcounts = count_ops sub { t::infix::addfunc( lhs(), rhs() ) };
   ok( !$opcounts{custom},   'No OP_CUSTOM call for list ENTERSUB' );

   # Opchecker still permits scalar entersub calls
   %opcounts = count_ops sub { t::infix::addfunc( scalar lhs(), scalar rhs() ) };
   ok( (scalar grep { m/^infix_0x/ } keys %opcounts),
      'OP_CUSTOM call for scalar ENTERSUB' );
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
   # We need to ensure the wrapper function doesn't deparse to the actual
   # infix operator syntax in order to test this one
   BEGIN { delete $^H{"t::infix/permit"} }

   is_deparsed sub { t::infix::addfunc( $_[0], $_[1] ) },
      't::infix::addfunc($_[0], $_[1]);',
      'deparsed call to wrapper func';
}

done_testing;
