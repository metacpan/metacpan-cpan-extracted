#!/usr/bin/env perl

use strict;
use warnings;

use Test::More::Behaviour;

BEGIN {
    use_ok('BankAccount');
}

describe 'Bank Account' => sub {
    context 'when opening an account with no initial deposit' => sub {
        it 'has an initial balance of 0.00' => sub {
            my $account = BankAccount->new();
            is($account->balance, 0.00);
        };
    };
    context 'when opening an account with an initial deposit' => sub {
        it 'has an initial balance of the deposit amount' => sub {
            my $account = new BankAccount(50.00);
            is($account->balance, 50.00);
        };
    };
    context 'when transferring money between two accounts' => sub {
        my $source = BankAccount->new(100);

        my $target = BankAccount->new(0);
        $source->transfer(50, $target);

        it 'withdraws amount from the source account' => sub {
            is($source->balance, 50);
        };
        it 'deposits amount into target account' => sub {
            is($target->balance, 50);
        };
    };
};

done_testing();
