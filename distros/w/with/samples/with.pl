#!/usr/bin/env perl

package Deuce;

use strict;
use warnings;

sub new { my $class = shift; bless { id => shift }, $class }

sub hlagh { my $self = shift; print "Deuce::hlagh $self->{id}\n" }


package main;

use strict;
use warnings;

use lib 'blib/lib';

sub hlagh { print "Pants::hlagh\n" }

our @ISA;
push @ISA, 'Deuce';
my $deuce = new Deuce 1;
my $d = new Deuce 3;

hlagh;         # Pants::hlagh

{
 use with \$deuce;
 hlagh;        # Deuce::hlagh 1
 main::hlagh;  # Pants::hlagh
 
 {
  use with \Deuce->new(2); # Constant blessed reference
  hlagh;       # Deuce::hlagh 2
 }

 hlagh;        # Deuce::hlagh 1

 no with;
 hlagh;        # Pants::hlagh
}

hlagh;         # Pants::hlagh
