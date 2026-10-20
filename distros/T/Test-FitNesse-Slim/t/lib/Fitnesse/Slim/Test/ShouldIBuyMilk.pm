package Fitnesse::Slim::Test::ShouldIBuyMilk;

# Adapted from fitnesse.slim.test.ShouldIBuyMilk in FitNesse v20251025.
# Copyright (C) 2003-2009 by Object Mentor, Inc. All rights reserved.
# Released under CPL 1.0; see LICENSE.CPL and THIRD-PARTY-NOTICES.md.

use strict;
use warnings;

sub new {
    my ($class) = @_;
    return bless {
        dollars     => 0,
        pints       => 0,
        credit_card => 0,
    }, $class;
}

sub set_cash_in_wallet {
    my ($self, $dollars) = @_;
    $self->{dollars} = $dollars;
    return;
}

sub set_pints_of_milk_remaining {
    my ($self, $pints) = @_;
    $self->{pints} = $pints;
    return;
}

sub set_credit_card {
    my ($self, $valid) = @_;
    $self->{credit_card} = defined($valid) && $valid eq 'yes' ? 1 : 0;
    return;
}

sub go_to_store {
    my ($self) = @_;
    return $self->{pints} == 0
        && ($self->{dollars} > 2 || $self->{credit_card})
        ? 'yes'
        : 'no';
}

sub execute    { return }
sub reset      { return }
sub begin_table { return }
sub table      { return }
sub end_table  { return }

1;
