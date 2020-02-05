#!/usr/bin/env perl
# You can tell Timer::Milestones to also time individual functions, as a subset
# of how long a particular milestone takes.

package TestsFor::Timer::Milestones::TimeFunction;

use strict;
use warnings;

use Carp;
use Test::Fatal;
# Prototype disagreement between Test::More and Test2::Tools::Compare, so
# explicitly use the Test2::Tools::Compare versions.
use Test::More import => [qw(!is !like)];
use Test2::Tools::Compare qw(is like array item end);

use Timer::Milestones qw(:all);

# We're not testing reports here, so silence them.
no warnings 'redefine';
local *Timer::Milestones::_default_notify_report = sub { return sub {} };
use warnings 'redefine';

test_validity();
test_timing();
test_pass_through();

done_testing();

# You can't intercept any old thing.

sub test_validity {
    my $timer = Timer::Milestones->new;

    # A function must exist.
    ok(exception { $timer->time_function('non::existent::function') },
        q{Cannot time a function that doesn't exist});

    # And must be a function, not any other kind of symbol.
    our @not_a_function = sub { 'Just a tray of sandwiches in a pub' };
    ok(
        exception { $timer->time_function(__PACKAGE__ . '::not_a_function') },
        q{A symbol of the wrong type won't do either}
    );
}

# If you intercept a function, we take a snapshot of the time at the beginning
# and end.

sub test_timing {
    # Four times: start, end, and beginning and end of the intercepted
    # function.
    my @times = qw(100 425 490 600);
    my $get_time
        = sub { my $time = shift @times or croak 'Ran out of times!'; $time };
    my $timer = Timer::Milestones->new(get_time => $get_time);

    # Check that by the time the function is called, we've picked two times
    # off the list - i.e. the beginning of all timing, and what's intended to
    # be the start time of the function.
    # This function wants to be named, and won't be used again, so don't
    # worry about what will happen to @times outside this scope. It's
    # not going to be used outside this scope!
    no warnings 'closure';
    sub two_times_left { is(scalar @times, 2, 'Two times left') };
    use warnings 'closure';

    # Install it. Nothing has fired apart from start_timing called by the
    # constructor, so there's still 3 times left on the stack.
    $timer->time_function(__PACKAGE__ . '::two_times_left');
    is(scalar @times, 3,
        'Before calling our intercepted function, 3 times left');

    # Calling the function triggers timing before it and after it.
    two_times_left();
    is(scalar @times, 1, 'Just the one time left');

    # Finally when we stop timing, we use the last time in the list.
    $timer->stop_timing;
    is(scalar @times, 0, 'All times used up');

    # We recorded all of that.
    like(
        $timer,
        {
            milestones => array {
                item {
                    name           => 'START',
                    started        => 100,
                    function_calls => [
                        {
                            function_name => __PACKAGE__ . '::two_times_left',
                            started       => 425,
                            ended         => 490,
                        }
                    ],
                    ended => 600,
                };
                end();
            }
        },
        'The milestone contains details of this function call'
    );
}

# Variables are passed through correctly.
sub test_pass_through {
    # Set up a function that mangles its provided arguments, returns different
    # values according to context, and takes a note of what they were.
    my $provided;
    no warnings 'closure';
    sub _summarise {
        my @arguments = @_;

        $provided = scalar @arguments . ' arguments';
        if (wantarray) {
            return map { substr($_, 0, 3) } @arguments;
        } elsif (defined wantarray) {
            return $provided;
        } else {
            return;
        }
    }
    use warnings 'closure';

    # The arguments are passed through correctly in all contexts.
    my $timer = Timer::Milestones->new;
    $timer->time_function(__PACKAGE__ . '::_summarise');

    _summarise(qw(ignore all of this stuff), { including => 'this' });
    is($provided, '6 arguments', 'Arguments passed in void context');

    is(scalar _summarise('bunch', 'of', 'stuff'), '3 arguments',
        'Return value correct in scalar context');
    is($provided, '3 arguments', 'Arguments passed in scalar context');

    is(
        [_summarise('Wossname', 'doohickey')],
        ['Wos', 'doo'],
        'Return value correct in list context'
    );
    is($provided, '2 arguments', 'Arguments passed in list contet');
}

1;
