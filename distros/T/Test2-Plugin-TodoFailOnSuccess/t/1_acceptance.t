use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Compare      qw( all_items array call etc event object T F );
use Test2::API                 qw( intercept );

# We'll run these tests and then examine the resulting event stream.
# Inserted some sleeps between tests to make sure we don't get
# unexpected event ordering due to overlapping events, which would
# complicate comparing to the expected list of events.
#
my $tests_to_run = sub {
    ok(1, 'Expected pass');
    sleep 1;
    todo 'Inside TODO' => sub {
        ok(0, 'Failing TODO test');
        sleep 1;
        ok(1, 'Passing TODO test');
        sleep 1;
    };
    sleep 1;
    ok(1, 'Another expected pass');
    sleep 1;
    done_testing();
};

# First make sure a failing TODO test is ignored as expected:
#
is(
    intercept( sub { $tests_to_run->() } ),
    array {
        event Ok => sub {
            call name           => 'Expected pass';
            call pass           => T();
            call effective_pass => T();
        };
        event Ok => sub {
            call name           => 'Failing TODO test';
            call pass           => F();
            call effective_pass => T();
        };
        event Note => sub {
        };
        event Ok => sub {
            call name           => 'Passing TODO test';
            call pass           => T();
            call effective_pass => T();
        };
        event Ok => sub {
            call name           => 'Another expected pass';
            call pass           => T();
            call effective_pass => T();
        };
        event Plan => sub {
            call directive => '';
            call max       => 4;
        };
        end();
    },
    'Regular TODO',
);

# Now make sure a passing TODO test is reported as a failure
# when Test2::Plugin::TodoFailOnSuccess is loaded:
#
require Test2::Plugin::TodoFailOnSuccess;
Test2::Plugin::TodoFailOnSuccess->import;

is(
    intercept( sub { $tests_to_run->() } ),
    array {
        event Ok => sub {
            call name           => 'Expected pass';
            call pass           => T();
            call effective_pass => T();
        };
        event Ok => sub {
            call name           => 'Failing TODO test';
            call pass           => F();
            call effective_pass => T();
        };
        event Note => sub {
        };
        event Ok => sub {
            call name           => 'Passing TODO test';
            call pass           => T();
            call effective_pass => T();
        };
        event Fail => sub {
            call name => 'TODO passed unexpectedly: Passing TODO test';
            call amnesty => array {
                all_items object {
                    call details => 'Inside TODO';
                    call tag     => 'TODO';
                };
                etc();
            };
        };
        event Ok => sub {
            call name           => 'Another expected pass';
            call pass           => T();
            call effective_pass => T();
        };
        event Plan => sub {
            call directive => '';
            call max       => 5;
        };
        end();
    },
    'TODO with TodoFailOnSuccess',
);

done_testing;

1;

