package BankAccount;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = {
        _balance => shift || 0.00,
    };
    bless $self, $class;
    return $self;
}

sub balance {
    my $self = shift;
    return $self->{_balance};
}

sub transfer {
    my ($self, $amt, $target) = @_;

    $self->{_balance} -= $amt;
    $target->{_balance} += $amt;
}

1;
