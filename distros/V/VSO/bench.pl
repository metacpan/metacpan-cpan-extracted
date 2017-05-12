#!/usr/bin/perl -w

package Foo;

use VSO;

package main;

use strict;
use warnings 'all';
use Benchmark qw( :all :hireswallclock );

use lib 't/lib';
use MooseState;
#use MoState;
use State;

my %args = (
  name        => 'Colorado',
  capital     => 'Denver',
  population  => 5_000_000,
  foo         => { bar => bless {}, 'Foo' },
  func        => sub { }
);

my $results = timethese(100_000, {
  blessed_hashref => \&blessed_hashref,
  hashref         => \&hashref,
  vso             => \&vso,
#  moose           => \&moose,
#  mo              => \&mo,
});

cmpthese($results);

sub blessed_hashref
{
  my $state = bless { %args }, 'Foo';
}# end blessed_hashref()


sub hashref
{
  my $state = { %args };
}# end hashref()


sub moose
{
  my $state = MooseState->new( %args );
}# end moose()


sub vso
{
  my $state = State->new( %args );
}# end vso()


sub mo
{
  my $state = MoState->new( %args );
}# end mo()

