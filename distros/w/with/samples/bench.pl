#!/usr/bin/env perl

use strict;
use warnings;

use Benchmark qw<cmpthese>;

use lib 'blib/lib';

my $counter;
my @poultry = (qw<cock chick>);

sub Duck::quack { $counter += $_[0]->{id} * $_[0] }
sub fly { $counter += $_[0]; }
sub Duck::unshift { CORE::unshift @poultry, $_[0]->{id} * $_[3] }
sub Duck::pop     { CORE::pop @poultry }

my $duck = bless { id => 0.7 }, 'Duck';

cmpthese -2, {
 explicit => sub { $duck->quack(3); },
 with     => sub {
  use with \$duck;
  quack -3;
 }
};

cmpthese -2, {
 direct   => sub { fly(2); },
 deferred => sub {
  use with \$duck;
  fly -2;
 }
};

cmpthese -2, {
 core    => sub { push @poultry, 1; shift @poultry; },
 wrapped => sub {
  use with \$duck;
  push @poultry, 1; shift @poultry;
 }
};

cmpthese -2, {
 core      => sub { unshift @poultry, $duck->{id} * 5; pop @poultry; },
 flattened => sub {
  use with \$duck;
  unshift @poultry, -5; pop @poultry;
 }
};
