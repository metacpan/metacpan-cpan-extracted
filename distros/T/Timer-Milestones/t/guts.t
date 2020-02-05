#!/usr/bin/env perl
# Low-level tests regarding the guts of Timer::Milestones.

use strict;
use warnings;

use Scalar::Util;
# Prototype disagreement between Test::More and Test2::Tools::Compare, so
# explicitly use the Test2::Tools::Compare versions.
use Test::More import => [qw(!is !like)];
use Test2::Tools::Compare;

use Timer::Milestones;

# We're not testing reports here, so silence them.
no warnings 'redefine';
local *Timer::Milestones::_default_notify_report = sub { return sub {} };
use warnings 'redefine';

test_object_and_arguments();
test_get_time();

done_testing();

# object_and_arguments will pass through a blessed object, or return a
# singleton.
# With this established, we merely need to test that exportable functions
# work on the singleton object, and can limit more-detailed tests to the
# OO interface.

sub test_object_and_arguments {
    # If we call the method with no arguments, we get a singleton.
    my ($first_object)  = Timer::Milestones::_object_and_arguments;
    my ($second_object) = Timer::Milestones::_object_and_arguments;
    isa_ok($first_object,  'Timer::Milestones');
    isa_ok($second_object, 'Timer::Milestones');
    # Stupid $$;$ prototype of is() means we can't pass a list of refaddrs,
    # because that gets squashed into a scalar.
    is(
        Scalar::Util::refaddr($first_object),
        Scalar::Util::refaddr($second_object),
        '_object_and_arguments with no arguments returns a singleton'
    );

    # If we provide arguments, but they're not blessed objects, we get back
    # the singleton and the arguments we provided.
    my @arguments = Timer::Milestones::_object_and_arguments([qw(How about)],
        { that => 'ball' }, 'game');
    my $third_object = shift @arguments;
    is(
        Scalar::Util::refaddr($third_object),
        Scalar::Util::refaddr($first_object),
        '_object_and_arguments with arguments also returns a singleton...'
    );
    like(
        [@arguments],
        [[qw(How about)], { that => 'ball' }, 'game'],
        '...and the arguments we supplied'
    );

    # For that matter, if we pass in a blessed object but it's not a
    # Timer::Milestones object, it's considered an argument, not an invocant.
    my $harmless_object = bless { stuff => 'harmless' } => 'Some::Object';
    my @blessed_arguments
        = Timer::Milestones::_object_and_arguments($harmless_object);
    is(scalar @blessed_arguments, 2,
        'Passing in a random object results in two arguments back');
    is(
        [map { ref($_) } @blessed_arguments],
        ['Timer::Milestones', 'Some::Object'],
        'Two blessed objects, in fact'
    );

    # But if we pass it a blessed object of the right kind, it's returned
    # as-is.
    @DJO::AppleJuice::ISA = qw(Timer::Milestones);
    my $unlikely_object
        = bless { quote => 'I have a business installing styrofoam nuns' } =>
        'DJO::AppleJuice';
    my ($as_is_object)
        = Timer::Milestones::_object_and_arguments($unlikely_object);
    is(ref($as_is_object), 'DJO::AppleJuice',
        'An object is apparently unmolested');
    is(
        Scalar::Util::refaddr($as_is_object),
        Scalar::Util::refaddr($unlikely_object),
        'It was, in fact, the same object'
    );

    # As are any other arguments.
    my @mixed_arguments = Timer::Milestones::_object_and_arguments(
        $unlikely_object,
        q{My van's in pieces},
        'What do you say we make apple juice and fax it to each other?',
        {
            references => 'obscure',
            url => 'https://www.youtube.com/watch?v=414TmP12WAU',
        }
    );
    is(scalar @mixed_arguments, 4,
        'We get our object and other arguments back');
    is(
        [map { ref($_) } @mixed_arguments],
        ['DJO::AppleJuice', '', '', 'HASH'],
        'They look like what we expected'
    );
}

# There is a get_time coderef in each object that calls either
# Time::HiRes::time, time, or a coderef we've injected.

sub test_get_time {
    # Pretend that there's a Time::HiRes::time function which works. We'll
    # use it.
    {
        local $INC{'Time/HiRes'} = 'Sure';
        no warnings 'redefine';
        local *Time::HiRes::time = sub { return 12345 };
        use warnings 'redefine';
        my $faked_out_timer = Timer::Milestones->new;
        is($faked_out_timer->_now, 12345,
            q{We'll try to use Time::HiRes::time});
    }
    # Pretnend that there's a Time::HiRes::time function which fails.
    # We'll fall back to the system time.
    {
        local $INC{'Time/HiRes'} = 'Mwahahaha';
        no warnings 'redefine';
        local *Time::HiRes::time = sub { die 'Foolish mortals!' };
        use warnings 'redefine';
        my $doomed_timer = Timer::Milestones->new;
        my $low_res_time = time;
        my $returned_time = $doomed_timer->_now;
        # If more than 10 seconds elapsed between us working out what time it
        # is and what the timer returns, the machine is being more than
        # expectedly slow.
        my $time_delta = $returned_time - $low_res_time;
        ok(
            $time_delta >= 0 && $time_delta < 10,
            'After a Time::HiRes failure, we still returned something plausible'
        );
    }
    # We can also inject a get_time coderef into our object.
    my $mocking_timer = Timer::Milestones->new;
    my $counter = 100;
    $mocking_timer->{get_time} = sub { $counter++ };
    is($mocking_timer->_now, 100, 'We can inject a coderef');
    is($mocking_timer->_now, 101, 'Which is called every time and not cached');
}

1;
