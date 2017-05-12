
use strict;
use warnings;
use UR;
use IO::File;

use Test::More tests => 57;

UR::Object::Type->define(
    class_name => 'Circle',
    has => [
        radius => {
            is => 'Number',
            default_value => 1,
        },
    ],
);

sub add_test_observer {
    my ($aspect, $context, $observer_ran_ref) = @_;
    $$observer_ran_ref = 0;

    my $observer;
    my $callback;
    $callback = sub { $$observer_ran_ref = 1; };
    $observer = $context->add_observer(
        aspect => $aspect,
        callback => $callback,
    );

    unless ($observer) {
        die "Failed to add $aspect observer!";
    }
    return $observer;
}

# Create a Circle
my $circle = Circle->create();
ok($circle->isa('Circle'), 'create a circle');
ok($circle->radius == 1, 'default radius is 1');



# Verify Transaction Rollback Removes Observer and its Subscription
# making sure if someone tries to catch their observer's delete that it runs
# before the observer's self-created delete subscription
{
    my $ran_observer_observer = 0;

    my $circle_trans = UR::Context::Transaction->begin();
    ok($circle_trans, 'begin transaction');
    my $ran_circle_radius_observer = 0;
    my $circle_obs = $circle->add_observer(
        aspect => 'radius',
        callback => sub { $ran_circle_radius_observer = 1; },
    );
    my $circle_obs_id = $circle_obs->id;

    my $ran_circle_obs_delete_obs = 0;
    my $subscription = $circle_obs->class->create_subscription(
        id => $circle_obs->id,
        method => 'delete',
        callback => sub { $ran_circle_obs_delete_obs = 1; },
        note => "$circle_obs",
    );
    my $observer_observer = UR::Observer->get(subject_class_name => 'UR::Observer', subject_id => $subscription->[1]);

    ok($circle_obs->isa('UR::Observer'), 'added an observer on the circle');
    is(UR::Observer->get(subject_class_name => 'Circle', subject_id => $circle->id, aspect => 'radius'),
       $circle_obs,
       'Can get the observer on the circle with get()');
    my $circle_sub = $UR::Context::all_change_subscriptions->{Circle}->{radius}->{$circle->id};
    ok($circle_sub, 'adding observer inserted a callback into the Context data structure for callbacks');

    is(UR::Observer->get(subject_class_name => 'UR::Observer', subject_id => $circle_obs->id, aspect => 'delete'),
       $observer_observer,
       'Can get the observer on the original observer deletion with get()');

    ok($circle_trans->rollback(), 'rolled back transaction');

    ok($ran_circle_obs_delete_obs == 0, 'rollback did not run the delete observer');  # because it's creation was undone before the radius observer was deleted
    $circle_sub = $UR::Context::all_change_subscriptions->{Circle}->{radius}->{$circle->id};
    ok(!$circle_sub, 'rolling back transaction (and with it the observer) removed the subscription');
    ok($circle_obs->isa('UR::DeletedRef'), 'radius observer is now a DeletedRef');

    ok(! UR::Observer->get(subject_class_name => 'Circle', subject_id => $circle->id, aspect => 'radius'),
       'get() no longer returns the circle observer');
    ok(! UR::Observer->get(subject_class_name => 'UR::Observer', subject_id => $circle_obs_id, aspect => 'delete'),
       'get() no longer returns the observer observer');

    $ran_circle_obs_delete_obs = 0;
    $circle->radius(1);
    is($ran_circle_obs_delete_obs, 0, 'The circle radius observer did not run');
};



# Verify Transaction Rollback Observer Runs
{
    $circle->radius(3);
    ok($circle->radius == 3, "original radius is three");
    my $transaction = UR::Context::Transaction->begin();
    my $observer_ran = 0;
    add_test_observer('rollback', $transaction, \$observer_ran);
    my $sub = $UR::Context::all_change_subscriptions->{'UR::Context::Transaction'}->{rollback}->{$transaction->id};
    ok($sub, 'adding observer also create change subscription');
    ok($transaction->isa('UR::Context::Transaction'), "created first transaction (to test rollback observer)");
    ok(!$observer_ran, "observer rollback flag reset to 0");
    $circle->radius(5);
    ok($circle->radius == 5, "in transaction (rollback test), radius is five");
    ok($transaction->rollback(), "ran transaction rollback");
    ok($observer_ran, "rollback observer ran successfully");
    ok($circle->radius == 3, "after rollback, radius is three");
};



# Verify Transaction Commit Observer Runs
{
    $circle->radius(4);
    ok($circle->radius == 4, "original radius (commit test) is four");
    my $transaction = UR::Context::Transaction->begin();
    my $observer_ran = 0;
    add_test_observer('commit', $transaction, \$observer_ran);
    ok($transaction->isa('UR::Context::Transaction'), "created second transaction (to test commit observer)");
    ok(!$observer_ran, "observer rollback flag reset to 0");
    $circle->radius(6);
    ok($circle->radius == 6, "in transaction (commit test), radius is six");
    ok($transaction->commit(), "ran transaction commit");
    ok($observer_ran, "commit observer ran successfully");
    ok($circle->radius == 6, "after commit, radius is six");

    # Trying to Rollback a Committed Transaction Fails
    ok($transaction->state eq 'committed', "transaction is already committed");
    my $rv= eval {$transaction->rollback()} || 0;
    ok($rv == 0, "properly failed transaction rollback for already committed transaction");
};



# Test Nested Transactions
{
    $circle->radius(3);
    ok($circle->radius == 3, "original radius is 3");
    my $outer_transaction = UR::Context::Transaction->begin();
    my $outer_observer_ran = 0;
    add_test_observer('rollback', $outer_transaction, \$outer_observer_ran);
    ok($outer_transaction->isa('UR::Context::Transaction'), "created outer transaction");
    ok(!$outer_observer_ran, "outer observer flag reset to 0");
    $circle->radius(5);
    ok($circle->radius == 5, "in outer transaction, radius is 5");
    my $inner_transaction = UR::Context::Transaction->begin();
    my $inner_observer_ran = 0;
    add_test_observer('rollback', $inner_transaction, \$inner_observer_ran);
    ok($inner_transaction->isa('UR::Context::Transaction'), "created inner transaction");
    ok(!$inner_observer_ran, "inner observer flag reset to 0");
    $circle->radius(7);
    ok($circle->radius == 7, "in inner transaction, radius is 7");
    ok($inner_transaction->rollback(), "ran inner transaction rollback");
    ok($inner_observer_ran, "inner transaction observer ran successfully");
    ok($circle->radius == 5, "after inner transaction rollback, radius is 5");
    ok($outer_transaction->rollback(), "ran transaction rollback");
    ok($outer_observer_ran, "outer transaction observer ran successfully");
    ok($circle->radius == 3, "after rollback, radius is 3");
};

# testing inner commit
{
    $circle->radius(4);
    ok($circle->radius == 4, "original radius is 4");
    my $outer_transaction = UR::Context::Transaction->begin();
    my $outer_observer_ran = 0;
    add_test_observer('rollback', $outer_transaction, \$outer_observer_ran);
    ok($outer_transaction->isa('UR::Context::Transaction'), "created outer transaction");
    ok(!$outer_observer_ran, "outer observer flag reset to 0");
    $circle->radius(6);
    ok($circle->radius == 6, "in outer transaction, radius is 6");
    my $inner_transaction = UR::Context::Transaction->begin();
    my $inner_observer_ran = 0;
    add_test_observer('commit', $inner_transaction, \$inner_observer_ran);
    ok($inner_transaction->isa('UR::Context::Transaction'), "created inner transaction");
    ok(!$inner_observer_ran, "inner observer flag reset to 0");
    $circle->radius(8);
    ok($circle->radius == 8, "in inner transaction, radius is 8");
    ok($inner_transaction->commit(), "ran inner transaction commit");
    ok($inner_observer_ran, "inner transaction observer ran successfully");
    ok($circle->radius == 8, "after inner transaction commit, radius is 8");
    ok($outer_transaction->rollback(), "ran transaction rollback");
    ok($outer_observer_ran, "outer transaction observer ran successfully");
    ok($circle->radius == 4, "after rollback, radius is 4");
};

done_testing();

1;
