#!/usr/bin/perl -w

package MooseState;

use Moose;

has 'name' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

has 'capital' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

has 'population' => (
  is        => 'rw',
  isa       => 'Int',
  required  => 1,
);

__PACKAGE__->meta->make_immutable();

package MoState;

use Mo qw(required);

has 'name' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

has 'capital' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

has 'population' => (
  is        => 'rw',
  isa       => 'Int',
  required  => 1,
);


package main;

use strict;
use warnings 'all';
use Benchmark qw( :all :hireswallclock );


my %args = (
  name        => 'Colorado',
  capital     => 'Denver',
  population  => 5_000_000,
);

my $results = timethese(1_000_000, {
  blessed_hashref => \&blessed_hashref,
  hashref         => \&hashref,
  moose           => \&moose,
  mo              => \&mo,
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


sub mo
{
  my $state = MoState->new( %args );
}# end mo()

