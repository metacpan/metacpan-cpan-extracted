#!/usr/bin/env perl
# You can tell Timer::Milestones to also time individual functions, as a subset
# of how long a particular milestone takes.

package TestsFor::Timer::Milestones::TimeFunction;

use strict;
use warnings;

use Carp;
use Scalar::Util qw(refaddr);
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
test_wrapping_stops();
test_exported_function_interface();
test_coderef();

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

# Once we stop timing, the wrapping stops.

sub test_wrapping_stops {
    sub time_this_many_times {
        my $frames_required = 0;
        while ((caller($frames_required))[0] ne __PACKAGE__) {
            $frames_required++;
        }
        return $frames_required;
    }
    is(time_this_many_times(), 0, 'Before anything else, direct access');

    my $timer = Timer::Milestones->new;
    $timer->time_function('time_this_many_times');
    is(time_this_many_times(), 1, 'One timer: indirect access');

    my $other_timer = Timer::Milestones->new;
    $other_timer->time_function('time_this_many_times');
    is(time_this_many_times(), 2, 'Two timers: two-level indirection');

    $other_timer->stop_timing;
    is(time_this_many_times(), 1, 'One timer finishes: back to one level');

    $timer->stop_timing;
    is(time_this_many_times(), 0, 'Both gone: direct access again');
}

# We can use exported functions as well as the OO interface for this.
# This also tests that we can use unqualified function names passed to
# time_function.

sub test_exported_function_interface {
    sub it_only_matters_that_we_call_it { }
    sub this_one_matters_even_less { }
    start_timing();
    time_function('it_only_matters_that_we_call_it');
    time_function('this_one_matters_even_less', summarise_calls => 1);
    it_only_matters_that_we_call_it();
    for (1..3) {
        this_one_matters_even_less();
    }
    add_milestone('Part-way through');
    my $report = generate_intermediate_report();
    like($report, my $re_partial = qr{
        ^
        START: \s [^\n]+ \n
        [^\n]+ \n # Don't worry about the timing for this milestone
        \s+ \d+ \s ms \s it_only_matters_that_we_call_it \n
        \s+ \d+ \s ms \s this_one_matters_even_less \s [(] x3 [)] \n
        Part-way \s through
    }xsm, 'Got subroutine calls in the first part');
    
    it_only_matters_that_we_call_it();
    it_only_matters_that_we_call_it();
    $report = generate_final_report();
    like($report,
        qr{
            ^
            $re_partial \n
            [^\n]+ \n # Don't worry about timing for this second part either
            ( \s+ \d+ \s ms \s it_only_matters_that_we_call_it \n ){2}
            END: \s .+
            $
        }xsm,
        'Got subroutine calls in the second part as well'
    );
}

# You can pass a coderef to time_function; the wrapped coderef is returned.
# The name you supply is mentioned in the report; otherwise, something vaguely
# useful is used.

sub test_coderef {
    my $timer = Timer::Milestones->new;

    # A simple coderef. This is used mostly to check that we work out its name.
    my $line_defined = __LINE__ + 1;
    my $simple_code = sub { return 'Duh!' };
    my $wrapped_simple_code = $timer->time_function($simple_code);
    isnt(refaddr($wrapped_simple_code), refaddr($simple_code),
        'We got returned a different coderef for the simple code');

    # A more elegant coderef that we'll give a name to, and report details
    # of its arguments just to make sure all of this stuff works.
    my $factoid = 'Hippos are more closely related to whales than pigs';
    my $elegant_code = sub { return $factoid };
    my $wrapped_elegant_code = $timer->time_function(
        $elegant_code,
        report_name_as      => 'interesting factoid',
        summarise_arguments => sub { scalar @_ }
    );
    isnt(refaddr($wrapped_elegant_code), refaddr($elegant_code),
        'We got returned a different coderef for the elegant code');

    # Test the two coderefs.
    is($wrapped_simple_code->(), 'Duh!', 'The simple coderef works');
    is($elegant_code->(), $factoid, 'Our original elegant coderef still works');
    is($wrapped_elegant_code->(qw(these arguments are just counted)),
        $factoid, 'Our wrapped elegant coderef works as well');
    $factoid = q{Rodents can't burp};
    is($wrapped_elegant_code->('Huh!'),
        $factoid, 'And we can still mess with it');

    # Our report includes the alternative name etc. and does not include the
    # first call to the elegant code.
    my $final_report = $timer->generate_final_report;
    like(
        $final_report,
        qr{
            ^
            START: \s [^\n]+ \n
            \s+ [^\n]+ \n # Ignore total elapsed time
            \s+ \d+ \s ms \s CODE [(] 0x [0-9a-f]+ [)] \n
            \s+ \d+ \s ms \s interesting \s factoid \n
            \s+ 5 \n
            \s+ \d+ \s ms \s interesting \s factoid \n
            \s+ 1 \n
            END: \s .+
            $
        }xsm,
        'The report uses the reported name etc.'
    )
}

1;
