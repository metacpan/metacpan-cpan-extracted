use strict;
use warnings;
use utf8;
use 5.010000;

use Test::More::Behaviour;

{
    package BankAccount;
    sub new {
        my ($class, $amount) = @_;
        bless \$amount, $class;
    }
    sub transfer {
        my ($self, $amount, $other) = @_;
        $$self  -= $amount;
        $$other += $amount;
    }
    sub balance {
        my $self = shift;
        return $$self;
    }
}

describe 'Bank Account' => sub {
    context 'transferring money' => sub {
        it 'withdrawals amount from the source account' => sub {
            my $source = BankAccount->new(100);
            my $target = BankAccount->new(0);
            $source->transfer( 50, $target );
            is( $source->balance, 50 );
        };
        it 'deposits amount into target account' => sub {
            my $source = BankAccount->new(100);
            my $target = BankAccount->new(0);
            $source->transfer( 50, $target );
            is( $target->balance, 50 );
        };
    };
};

done_testing;
