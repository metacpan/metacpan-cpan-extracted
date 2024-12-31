package mykura;
use strict;
use warnings;

use kura ();
use MyConstraint;

sub import {
    shift;
    my ($name, $args) = @_;

    my $caller = caller;

    no strict 'refs';
    no warnings 'redefine';
    local *{"kura::create_constraint"} = \&create_constraint;

    kura->import_into($caller, $name, $args);
}

sub create_constraint {
    my ($args, $opts) = @_;
    return (undef, "Invalid mykura arguments") unless (ref $args||'') eq 'HASH';
    return (MyConstraint->new(%$args), undef);
}

1;
