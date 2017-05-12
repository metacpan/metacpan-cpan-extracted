use strict;
use warnings;

use Test::More tests => 18;

use UR;
use UR::Context::Transaction;

UR::Object::Type->define(
    class_name => 'Thing',
);

is(thing_count(), 0, 'got 0 Things');

Thing->create();
is(thing_count(), 1, 'got 1 Thing');

my $message = 'Something happened!';

# eval dies
my $dead_thing = UR::Context::Transaction::eval {
    Thing->create();
    is(thing_count(), 2, 'got 2 Things');
    die $message;
};
ok(!$dead_thing, 'got no return from eval (die)');
is(thing_count(), 1, 'got 1 Thing after eval (die)');

# eval does not die
my $live_thing = UR::Context::Transaction::eval {
    my $thing = Thing->create();
    is(thing_count(), 2, 'got 2 Things');
    return $thing;
};
isa_ok($live_thing, 'Thing', 'return');
is(thing_count(), 2, 'got 2 Things after eval (success)');

# do dies
eval {
    UR::Context::Transaction::do {
        Thing->create();
        is(thing_count(), 3, 'got 3 Things');
        die $message;
    };
};
my $eval_error = $@;
like($eval_error, qr/^$message/, 'got expected eval error');
is(thing_count(), 2, 'got 2 Things after do (die)');

# do returns false
eval {
    UR::Context::Transaction::do {
        Thing->create();
        is(thing_count(), 3, 'got 3 Things');
        return;
    };
};
$eval_error = $@;
is($eval_error, '', 'did not get an eval error');
is(thing_count(), 2, 'got 2 Things after do (return)');

# do does not die and does not return false
UR::Context::Transaction::do {
    Thing->create();
    is(thing_count(), 3, 'got 3 Things');
};
is(thing_count(), 3, 'got 3 Things');

eval {
    no warnings 'redefine';
    local *UR::Context::Transaction::commit = sub { return };
    eval {
        UR::Context::Transaction::eval {
            return 1;
        };
    };
    my $eval_error = $@;
    like($eval_error, qr/^failed to commit transaction/, 'got exception if eval fails to commit');
};

eval {
    no warnings 'redefine';
    local *UR::Context::Transaction::rollback = sub { return };
    eval {
        UR::Context::Transaction::eval {
            die 'trigger rollback';
        };
    };
    my $eval_error = $@;
    like($eval_error, qr/^failed to rollback transaction/, 'got exception if eval fails to rollback');
};

####

sub thing_count {
    my @things = Thing->get();
    return scalar(@things);
}
