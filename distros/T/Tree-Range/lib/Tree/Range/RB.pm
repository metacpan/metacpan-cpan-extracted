### RB.pm --- Tree::Range::RB: range tree based on Tree::RB  -*- Perl -*-

### Copyright (C) 2013 Ivan Shmakov

## Permission to copy this software, to modify it, to redistribute it,
## to distribute modified versions, and to use it for any purpose is
## granted, subject to the following restrictions and understandings.

## 1.  Any copy made of this software must include this copyright notice
## in full.

## 2.  I have made no warranty or representation that the operation of
## this software will be error-free, and I am under no obligation to
## provide any services, by way of maintenance, update, or otherwise.

## 3.  In conjunction with products arising from the use of this
## material, there shall be no use of my name in any advertising,
## promotional, or sales literature without prior written consent in
## each case.

### Code:

package Tree::Range::RB;

use strict;

our $VERSION = 0.22;

require Carp;
require Tree::Range::base;

use Tree::RB qw (LUGTEQ LULTEQ);

push (our @ISA, qw (Tree::Range::base));

sub backend {
    ## .
    $_[0]->{"backend"};
}

sub cmp_fn {
    ## .
    $_[0]->{"cmp"};
}

sub value_equal_p_fn {
    ## .
    $_[0]->{"equal-p"};
}

sub leftmost_value {
    ## .
    $_[0]->{"leftmost"};
}

sub delete {
    ## .
    $_[0]->backend ()->delete ($_[1]);
}

sub lookup_geq {
    my ($value, $node)
        = $_[0]->backend ()->lookup ($_[1], LUGTEQ ());
    ## .
    $node;
}

sub lookup_leq {
    my ($value, $node)
        = $_[0]->backend ()->lookup ($_[1], LULTEQ ());
    ## .
    $node;
}

sub min_node {
    ## .
    $_[0]->backend ()->min ();
}

sub max_node {
    ## .
    $_[0]->backend ()->max ();
}

sub put {
    ## .
    $_[0]->backend ()->put (@_[1 .. 2]);
}

sub new {
    my ($class, $options) = @_;
    my ($cmp, $equal_p, $leftmost)
        = (defined ($options)
           ? @$options{qw (cmp equal-p leftmost)}
           : ());
    $cmp
        //= sub { $_[0] cmp $_[1] };
    my $backend
        = Tree::RB->new ($cmp)
        or Carp::croak ();
    my $self = {
        "backend"   => $backend,
        "cmp"       => $cmp,
        "equal-p"   => $equal_p // sub { 0; },
        "leftmost"  => $leftmost,
    };
    bless ($self, $class);

    ## .
    $self;
}

1;

### Emacs trailer
## Local variables:
## coding: us-ascii
## fill-column: 72
## indent-tabs-mode: nil
## ispell-local-dictionary: "american"
## End:
### RB.pm ends here
