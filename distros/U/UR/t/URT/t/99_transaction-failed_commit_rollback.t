use strict;
use warnings;

use UR;
use IO::File;

use Test::More tests => 4;

use UR::Context::Transaction qw(TRANSACTION_STATE_COMMITTED);

UR::Object::Type->define(
    class_name => 'Circle',
    has => [
        radius => {
            is => 'Number',
            default_value => 1,
        },
    ],
);

sub Circle::__errors__ {
    my $tag = UR::Object::Tag->create (
        type => 'invalid',
        properties => ['test_property'],
        desc => 'intentional error for test',
    );
    return ($tag);
}

# Create a Circle
my $circle = Circle->create();
ok($circle->isa('Circle'), 'create a circle');
ok($circle->radius == 1, 'default radius is 1');


subtest 'fail to commit then rollback' => sub {
    plan tests => 10;

    my $transaction = UR::Context::Transaction->begin;
    isa_ok($transaction, 'UR::Context::Transaction');

    my $old_radius = $circle->radius;
    my $new_radius = $circle->radius + 5;
    isnt($circle->radius, $new_radius, "new circle radius isn't current radius");
    $circle->radius($new_radius);
    is($circle->radius, $new_radius, "circle radius changed to new radius");

    $transaction->dump_error_messages(0);
    $transaction->queue_error_messages(1);

    is($transaction->commit, undef, 'commit failed');

    my @messages = $transaction->error_messages();
    is(scalar(@messages), 2, 'commit generated 2 error messages');
    my $circleid = $circle->id;
    is($messages[0], 'Invalid data for save!', 'First error text is correct');
    like($messages[1],
        qr(Circle identified by $circleid has problems on\s+INVALID: property 'test_property': intentional error for test),
        'Error message text is correct');

    is($transaction->rollback, 1, 'rollback succeeded');
    is($circle->radius, $old_radius, 'circle radius was rolled back');

    isa_ok($transaction, 'UR::DeletedRef', 'transaction obj is now a deleted ref');
};

subtest 'transaction can ignore errors on commit' => sub {
    plan tests => 5;

    my $transaction = UR::Context::Transaction->begin(commit_validator => sub { 1 });
    ok($transaction, 'Begin trans');

    my $orig_radius = $circle->radius;
    ok(my $new_radius = $circle->radius($orig_radius + 1), 'change radius');

    ok($transaction->commit, 'commit transaction');

    is($circle->radius, $new_radius, 'radius remains new value after commit');
    is($transaction->state, TRANSACTION_STATE_COMMITTED, 'transaction state is committed');
};

1;
