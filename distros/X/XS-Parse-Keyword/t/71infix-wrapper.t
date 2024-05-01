#!/usr/bin/perl

use v5.14;
use warnings;
use utf8;

use Test2::V0;

use B qw( svref_2object walkoptree );

use B::Deparse;
my $deparser = B::Deparse->new();

use lib "t";
use testcase "t::infix";

BEGIN { $^H{"t::infix/permit"} = 1; }

# Newer perls generate OP_SREFGEN directly; older perls see only OP_REFGEN
use constant REFGEN => $] >= 5.022 ? "srefgen" : "refgen";

{
   my $result = t::infix::addfunc( 10, 20 );
   is( $result, 30, 'add wrapper func' );

   my $aref = [ t::infix::interspersefunc( "Z", "a", "b" ) ];
   is( $aref, [qw( a Z b )], 'intersperse wrapper func' );

   is( [ t::infix::addpairsfunc( [ 1, 2 ], [ 3, 4 ] ) ],
      [ 4, 6 ], 'addpairs wrapper func' );
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

# callchecker for scalar/scalar ops
{
   my %opcounts;

   %opcounts = count_ops sub { t::infix::addfunc( $_[0], $_[1] ) };

   # If the callchecker ran correctly we should see one 'custom' op and no
   # 'entersub's
   ok( (scalar grep { m/^infix_add_0x/ } keys %opcounts),
      'callchecker generated an OP_CUSTOM call' );
   ok( !$opcounts{entersub}, 'callchecker removed an OP_ENTERSUB call' );

   # Opchecker should ignore non-scalar args
   %opcounts = count_ops sub { t::infix::addfunc( @_, "more" ) };
   ok( !$opcounts{custom},   'No OP_CUSTOM call for DEFAV' );

   %opcounts = count_ops sub { t::infix::addfunc( lhs(), rhs() ) };
   ok( !$opcounts{custom},   'No OP_CUSTOM call for list ENTERSUB' );

   # Opchecker still permits scalar entersub calls
   %opcounts = count_ops sub { t::infix::addfunc( scalar lhs(), scalar rhs() ) };
   ok( (scalar grep { m/^infix_add_0x/ } keys %opcounts),
      'OP_CUSTOM call for scalar ENTERSUB' );
}

# callchecker for list/list ops
{
   my $code;
   my %opcounts;

   my $aref = [1,2,3];
   %opcounts = count_ops $code = sub { t::infix::addpairsfunc( $aref, $aref ) };
   ok( (scalar grep { m/^infix_addpairs_0x/ } keys %opcounts),
      'callchecker generated an OP_CUSTOM call for list/list' );
   ok( !$opcounts{entersub}, 'callchecker removed an OP_ENTERSUB call for list/list' );
   is( $opcounts{rv2av}, 2, 'callchecker made two OP_RV2AV' );
   is( [ $code->() ], [ 2, 4, 6 ], 'result of callcheckered code for list/list' );

   my @padav = (1,2,3);

   %opcounts = count_ops $code = sub { t::infix::addpairsfunc( \@padav, \@padav ) };
   ok( !$opcounts{srefgen}, 'callchecker made no OP_SREFGEN for \@padav' );
   is( [ $code->() ], [ 2, 4, 6 ], 'result of callcheckered code for list/list on \@padav' );

   our @pkgav = (1,2,3);

   %opcounts = count_ops $code = sub { t::infix::addpairsfunc( \@pkgav, \@pkgav ) };
   ok( !$opcounts{srefgen}, 'callchecker made no OP_SREFGEN for \@pkgav' );
   is( [ $code->() ], [ 2, 4, 6 ], 'result of callcheckered code for list/list on \@pkgav' );

   # stress-test it

   %opcounts = count_ops $code = sub { t::infix::addpairsfunc( \@{ \@{ \@padav } }, \@{ \@{ \@padav } } ) };
   # Preserve the two sets of inner ones but remove the outer ones
   is( $opcounts{+REFGEN}, 4, 'callchecker removed one layer of OP_SREFGEN for stress-test' );
   is( [ $code->() ], [ 2, 4, 6 ], 'result of callcheckered code for list/list on stress-test' );

   package OneTwoThree {
      use overload '@{}' => sub { return [1, 2, 3] };
   }

   $code = sub { t::infix::addpairsfunc( bless( {}, "OneTwoThree" ), \@padav ) };
   is( [ $code->() ], [ 2, 4, 6 ], 'result of callcheckered code for list/list on blessed object' );

   # anonlist remains on LHS
   %opcounts = count_ops $code = sub { t::infix::addpairsfunc( [1,2,3], \@padav ) };
   ok( $opcounts{anonlist}, 'callchecker left OP_ANONLIST on LHS' );
   is( [ $code->() ], [ 2, 4, 6 ], 'result of callcheckered code for list/list on anonlist' );

   # anonlist is unwrapped on RHS
   %opcounts = count_ops $code = sub { t::infix::addpairsfunc( \@padav, [1,2,3] ) };
   ok( !$opcounts{anonlist}, 'callchecker removed OP_ANONLIST on RHS' );
   is( [ $code->() ], [ 2, 4, 6 ], 'result of callcheckered code for list/list on anonlist' );
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

   my @padav;
   our @pkgav;

   is_deparsed sub { t::infix::addpairsfunc( $_[0], $_[1] ) },
      't::infix::addpairsfunc($_[0], $_[1]);',
      'deparsed call to list/list wrapper func on slugs';
   is_deparsed sub { t::infix::addpairsfunc( \@padav, \@padav ) },
      't::infix::addpairsfunc(\@padav, \@padav);',
      'deparsed call to list/list wrapper func on padav';
   is_deparsed sub { t::infix::addpairsfunc( \@pkgav, \@pkgav ) },
      't::infix::addpairsfunc(\@pkgav, \@pkgav);',
      'deparsed call to list/list wrapper func on pkgav';
   is_deparsed sub { t::infix::addpairsfunc( [1,2], [3,4] ) },
      't::infix::addpairsfunc([1, 2], [3, 4]);',
      'deparsed call to list/list wrapper func on anonlist';
}

# list-associative
{
   # wrapper by direct call
   is( t::infix::catfunc( "a", "b", "c" ), "^abc^",
      'List-associative wrapper function by direct call' );

   # wrapper by direct call non-convertable
   my @args = qw( a b c );
   is( t::infix::catfunc( @args ), "^abc^",
      'List-associative wrapper function by non-convertable direct call' );

   my $wrapper = \&t::infix::catfunc;
   is( $wrapper->( "d", "e", "f" ), "^def^",
      'List-associative wrapper function by CODE reference' );
}

# call-checker for list-associative ops
{
   my $code;
   my %opcounts;

   # scalars
   %opcounts = count_ops $code = sub { t::infix::catfunc "X", "Y" };
   ok( (scalar grep { m/^infix_cat_0x/ } keys %opcounts),
      'callchecker generated an OP_CUSTOM call for listassoc scalars' );
   ok( !$opcounts{entersub}, 'callchecker removed an OP_ENTERSUB call for listassoc scalars' );
   is( $code->(), "^XY^", 'result of callcheckered code for listassoc scalars' );

   # lists
   %opcounts = count_ops $code = sub { t::infix::LLfunc ["X"], ["Y"] };
   ok( (scalar grep { m/^infix_LL_0x/ } keys %opcounts),
      'callchecker generated an OP_CUSTOM call for listassoc lists' );
   ok( !$opcounts{entersub}, 'callchecker removed an OP_ENTERSUB call for listassoc lists' );
   is( $code->(), "([X][Y])", 'result of callcheckered code for listassoc lists' );

   # RT153244
   $code = sub { t::infix::catfunc() };
   pass( 'Compiling a zero argument listassoc scalars wrapper did not crash' );

   $code = sub { t::infix::LLfunc() };
   pass( 'Compiling a zero argument listassoc scalars wrapper did not crash' );
}

done_testing;
