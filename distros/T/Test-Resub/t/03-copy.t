#!/usr/bin/env perl

use strict;

use Test::More tests => 3;

use lib 't/lib';
use lib 'lib';
use lib '../lib';

use Storable qw(dclone);
use Test::Resub;

# Deep vs. shallow copies
{
  my %original_nested = (
    bert => [1, 2, [3, 4, [5, 6]]],
    a_coderef => sub {},
  );

  my %modified_nested = (
    bert => [1, 2, [3, 4, [5, 100]]],
    a_coderef => sub {},
  );

  {
    package SomePackage;
    sub f1 {}
    sub f2 {}
    sub f_default {}
  }

  my $rs1 = Test::Resub->new({
    name => 'SomePackage::f1',
    deep_copy => 0,
    capture => 1,
  });
  my $rs2 = Test::Resub->new({
    name => 'SomePackage::f2',
    deep_copy => 1,
    capture => 1,
  });
  my $rs_default = Test::Resub->new({
    name => 'SomePackage::f_default',
    capture => 1,
  });

  $Storable::Eval = $Storable::Deparse = 1;
  $Storable::Eval = $Storable::Deparse = 1;

  my %passed_in = %{dclone(\%original_nested)};

  SomePackage::f1(%passed_in);
  SomePackage::f2(%passed_in);
  SomePackage::f_default(%passed_in);

  $passed_in{bert}[2][2][1] = 100;

  is( $rs1->named_args->[0]{bert}[2][2][1], 100, 'shallow copy' );
  is( $rs2->named_args->[0]{bert}[2][2][1], 6, 'deep copy' );
  is( $rs_default->named_args->[0]{bert}[2][2][1], 100, 'shallow copy by default' );
}
