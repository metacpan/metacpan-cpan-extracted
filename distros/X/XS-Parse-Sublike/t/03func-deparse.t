#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
BEGIN {
   $] >= 5.026000 or plan skip_all => "No parse_subsignature()";
}

use feature 'signatures';
no warnings 'experimental';

use lib "t";
use testcase "t::func";

use B::Deparse;

my $deparser = B::Deparse->new();

# check that signatured functions deparse the right way
#   (RT132335)

# with signature
{
   my $sub  = sub  ($x, $y) { return $x + $y; };
   my $func = func ($x, $y) { return $x + $y; };

   my $code = $deparser->coderef2text( $sub ); # the reference source text
   is( $deparser->coderef2text( $func ), $code,
      'Deparsed func with signature identical to deparsed code' );
}

# empty signature
{
   my $sub  = sub  () { return 123; };
   my $func = func () { return 123; };

   my $code = $deparser->coderef2text( $sub ); # the reference source text
   is( $deparser->coderef2text( $func ), $code,
      'Deparsed func with empty signature identical to deparsed code' );
}

# empty body
{
   my $sub  = sub  () {};
   my $func = func () {};

   my $code = $deparser->coderef2text( $sub ); # the reference source text
   is( $deparser->coderef2text( $func ), $code,
      'Deparsed func with empty body identical to deparsed code' );
}

done_testing;
