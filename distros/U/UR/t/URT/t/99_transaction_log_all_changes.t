#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;

use_ok('UR::Context::Transaction');

subtest 'ensure log_all_changes is turned off after last transaction' => sub {
    plan tests => 10;


    is(scalar(() = UR::Context::Transaction->get()), 0, 'no transactions at start');
    is($UR::Context::Transaction::log_all_changes, 0, 'log_all_changes is disabled at start');
    my @tx = UR::Context::Transaction->begin();
    is($UR::Context::Transaction::log_all_changes, 1, 'beginning outer transaction enabled log_all_changes');
    push @tx, UR::Context::Transaction->begin();
    is($UR::Context::Transaction::log_all_changes, 1, 'beginning inner transaction leaves log_all_changes enabled');
    pop(@tx)->commit();
    is($UR::Context::Transaction::log_all_changes, 1, 'committing inner transaction leaves log_all_changes enabled');
    pop(@tx)->commit();
    is($UR::Context::Transaction::log_all_changes, 0, 'committing outer transaction disables log_all_changes');
    push @tx, UR::Context::Transaction->begin();
    is($UR::Context::Transaction::log_all_changes, 1, 'beginning a new first transaction enabled log_all_changes');
    push @tx, UR::Context::Transaction->begin();
    is($UR::Context::Transaction::log_all_changes, 1, 'beginning inner transaction leaves log_all_changes enabled');
    pop(@tx)->rollback();
    is($UR::Context::Transaction::log_all_changes, 1, 'rolling back inner transaction leaves log_all_changes enabled');
    pop(@tx)->rollback();
    is($UR::Context::Transaction::log_all_changes, 0, 'rolling back outer transaction disables log_all_changes');
};

subtest 'undos are fired by top-level context even if software tx commits' => sub {
    plan tests => 1;

    my $cb_was_called = 0;
    my $cb = sub { $cb_was_called++ };

    my $tx = UR::Context::Transaction->begin();
    my $foo = UR::Value->get(1);
    UR::Context::Transaction->log_change(
        $foo, 'UR::Value', 1, 'external_change', $cb,
    );

    $tx->commit();      # $tx is the current transaction
    UR::Context->rollback();    # this is the top-level transaction
    is($cb_was_called, 1, 'external change was undone when top-level transaction was rolled back');
};

subtest 'undos are not fired after top-level tx commits' => sub {
    plan tests => 1;

    my $cb_was_called = 0;
    my $shouldnt_be_called = sub { $cb_was_called++ };

    my $foo = UR::Value->get(1);
    UR::Context::Transaction->log_change(
        $foo, 'UR::Value', 1, 'external_change', $shouldnt_be_called,
    );

    UR::Context->commit();      # Both of these are the top-level transaction
    UR::Context->rollback();
    is($cb_was_called, 0, 'external change was not undone in rollback');
};

subtest 'undos are not fired twice if the top-level tx rolls back twice' => sub {
    plan tests => 1;

    my $cb_was_called = 0;
    my $cb = sub { $cb_was_called++ };

    my $foo = UR::Value->get(1);
    UR::Context::Transaction->log_change(
        $foo, 'UR::Value', 1, 'external_change', $cb,
    );

    UR::Context->rollback();    # Both of these are the top-level transaction
    UR::Context->rollback();
    is($cb_was_called, 1, 'external change was undone only once in rollback');
};
