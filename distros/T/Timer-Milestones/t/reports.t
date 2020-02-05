#!/usr/bin/env perl
# You can get a report from Timer::Milestones.

use strict;
use warnings;

use Carp;
use Test::Fatal;
# Prototype disagreement between Test::More and Test2::Tools::Compare, so
# explicitly use the Test2::Tools::Compare versions.
use Test::More import => [qw(!is !like)];
use Test2::Tools::Compare qw(is like);

use Timer::Milestones qw(:all);

test_generate_report();
test_time_function();
test_time_function_summaries();
test_report_notification();
test_divide_by_zero();
test_human_elapsed_time();

done_testing();

# Calling generate_report produces a report. Then it does nothing until we
# add more milestones, at which point a completely new report is returned.

sub test_generate_report {
    # Set up date mocking.
    my @times = (
         77904000, # 12pm Washington time
         77904323, # roughly 5 minutes later
         77905110, # 18 1/2 minutes after the start
        118166400, # 12pm months later when the problem is "discovered"
             time, # Now, when some bright spark thinks of something new
    );
    my $localtime_start = localtime($times[0]);
    my $localtime_end   = localtime($times[-2]);
    my $get_time
        = sub { my $time = shift @times or croak 'Ran out of times!'; $time };
    my $timer = Timer::Milestones->new(get_time => $get_time);

    # Before any milestones have been recorded, we just report that timing
    # started, but there are no interval times.
    like($timer->generate_intermediate_report,
        qr{
            ^
            START: \s \Q$localtime_start\E \n
            $
        }xsm,
        'Just a blank report before any milestones'
    );

    # Add a milestone; now there's a report.
    # \s{4} and \s rather than \s{5} because (a) there's a leading 4-space
    # indent, and then (b) because you can have up to 60 minutes, there's a
    # one-space indent for the seconds.
    $timer->add_milestone('Something completely innocuous');
    my $intermediate_report = $timer->generate_intermediate_report;
    like($intermediate_report,
        qr{
            ^
            START: \s \Q$localtime_start\E \n
            \s{4} \s 5 \s min \s 23 \s s \s [(] 100[.]00% [)] \n
            \QSomething completely innocuous\E \n
            $
        }xsm,
        'The report so far mentions when it started, milestone and elapsed time'
    );

    # We don't get another report if nothing else has happened.
    ok(!defined $timer->generate_intermediate_report,
        'If we ask again, nothing');

    # But if we add another milestone, we do.
    $timer->add_milestone('Something equally innocuous, honest');
    my $updated_report = $timer->generate_intermediate_report;
    like($updated_report,
        qr{
            ^
            START: \s \Q$localtime_start\E \n
            \s{4} \s 5 \s min \s 23 \s s \s [(] \s 29[.]10% [)] \n
            \QSomething completely innocuous\E \n
            \s{4} 13 \s min \s \s 7 \s s \s [()] \s 70[.]90% [)] \n
            \QSomething equally innocuous, honest\E \n
            $
        }xsm,
        'The report now has a new milestone and recalculated percentages',
    );

    # Eventually we can generate a final report.
    my $final_report = $timer->generate_final_report;
    like($final_report,
        qr{
            ^
            START: \s \Q$localtime_start\E \n
            \s{4} \s 5 \s min \s 23 \s s \s [(] \s{2} 0[.]00% [)] \n
            \QSomething completely innocuous\E \n
            \s{4} 13 \s min \s \s 7 \s s \s [()] \s{2} 0[.]00% [)] \n
            \QSomething equally innocuous, honest\E \n
            \s{4} 11183 \s h \s 41 \s min \s [()] 100[.]00% [)] \n
            END: \s \Q$localtime_end\E \n
            $
        }xsm,
        'Eventually we get an end time, and more recalculated percentages',
    );
    ok(
        !defined $timer->generate_final_report,
        'If we ask for a "final" report again, nothing'
    );

    # Once we have a final report, we cannot add more milestones.
    ok(
        exception { $timer->add_milestone('The truth, revealed!') },
        'We cannot add more milestones after a final report'
    );    
}

# We include any timed functions in-between the appropriate milestones.

sub test_time_function {
    # Build up a list of things that we'll do as part of the code that we're
    # timing.
    my @steps = (
        0,
        { call => 'Internal::Logging::init', meh => 1 },
        { call => 'Internal::Finance::do_tax_stuff', meh => 1 },
        4,
        { call => 'Obvious::Suspect::actually_pretty_efficient' },
        4.250,
        { call => 'Internal::Database::start_transaction', meh => 1 },
        5.150,
        { milestone => 'Finished chugging through set-up' },
        5.340,
        { call => 'Obvious::Suspect::slow_but_could_be_worse' },
        5.805,
        { call => 'Internal::Shim::cause_pathological_problem', meh => 1 },
        6.100,
        { call => 'Obscure::Package::pathological_problem'},
        14.980,
        15.200,
        { milestone => 'Done the hard work' },
        15.400,
        { call => 'Garbage::Collection::surprisingly_slow' },
        17.200,
        17.505,
    );

    # Create functions that we're going to call, and tell our object about the
    # times that all of these things happen at.
    no strict 'refs';
    for my $step (grep { ref($_) && $_->{call} } @steps) {
        *{ $step->{call} } = sub {};
    }
    use strict 'refs';
    my @times = grep { !ref($_) } @steps;
    my $timer = Timer::Milestones->new(
        get_time => sub {
            @times or croak 'Ran out of times!';
            return shift @times;
        }
    );
    for my $important_step (grep { ref($_) && $_->{call} && !$_->{meh} }
        @steps)
    {
        $timer->time_function($important_step->{call});
    }

    # Go through our steps doing things.
    for my $step (grep { ref($_) } @steps) {
        if (my $function = $step->{call}) {
            no strict 'refs';
            &{ $function }();
            use strict 'refs';
        } elsif (my $milestone = $step->{milestone}) {
            $timer->add_milestone($milestone);
        }
    }

    # Our report should match the steps above.
    my $report = $timer->generate_final_report;
    my ($timing_stuff) = ($report =~ m{
        ^
        START: \s [^\n]+ \n
        (.+)
        END: \s [^\n]+ \n
        $
    }xsm);
    is($timing_stuff, <<TIMING_STUFF, 'We recorded details of function calls');
     5 s ( 29.42%)
        250 ms Obvious::Suspect::actually_pretty_efficient
Finished chugging through set-up
    10 s ( 57.41%)
        464 ms Obvious::Suspect::slow_but_could_be_worse
           8 s Obscure::Package::pathological_problem
Done the hard work
     2 s ( 13.17%)
           1 s Garbage::Collection::surprisingly_slow
TIMING_STUFF
}

# We'll summarise function calls and/or arguments.

sub test_time_function_summaries {
    # Set up a timer, and tell it to pay attention to various things that happen
    # during a game of rugby. We want to know about tries (who scored them),
    # conversions (the scorer doesn't matter), penalties (who scored them,
    # but these things pile up so just summarise them) and substitutions
    # (pile up and don't matter in the long run, so just summarise them).
    my $timer = Timer::Milestones->new;
    my %time_args = (
        try_scored => {
            summarise_arguments => sub { shift; join(' for ', @_) }
        },
        conversion => {},
        penalty    => {
            summarise_arguments => sub { shift; join(' for ', @_) },
            summarise_calls     => 1
        },
        substitution => { summarise_calls => 1 }
    );
    for my $function_name (keys %time_args) {
        no strict 'refs';
        *{"TestMatch::Rugby::$function_name"} = sub { };
        use strict 'refs';
        $timer->time_function(
            "TestMatch::Rugby::$function_name",
            %{ $time_args{$function_name} }
        );
    }

    # Play through a rugby match.
    my $class = 'TestMatch::Rugby';
    $class->try_scored('Flair player', 'Exciting team');
    for (1 .. 3) { $class->penalty('Mr Metronome', 'Boring team'); }
    $class->try_scored('Crazy sideburns guy', 'Exciting team');
    $class->conversion('Oh look, they do have a kicker', 'Exciting team');
    for (1 .. 2) { $class->penalty('Mr Metronome', 'Boring team') }

    $timer->add_milestone('Half-time');

    $class->try_scored('Flair player', 'Exciting team');
    for (1..4) { $class->penalty('Mr Metronome', 'Boring team')};
    $class->substitution('Oh look, they do have a kicker', 'Exciting team');
    $class->try_scored('Flair player', 'Exciting team');
    $class->conversion('The full back is their kicker now?', 'Exciting team');
    $class->substitution('Mr Metronome', 'Boring team');
    $class->try_scored('Died his hair pink', 'Exciting team');
    for (1 .. 3) {
        $class->penalty('How many guys like this do they have?',
            'Boring team')
    }
    $class->substitution('The full back, FFS', 'Exciting team');
    $class->penalty('They let the physio have a go lol', 'Exciting team');
    for (qw(a whole bunch of guys)) {
        $class->substitution($_, 'Exciting team');
        $class->substitution($_, 'Boring team');
    }
    $class->try_scored('Basically the entire front row, Warhammer-style',
        'Boring team');
    $class->conversion('Do they assemble these guys from kits?', 'Boring team');

    # The report summarises arguments and/or function calls where it needs to.
    # We don't care about timing here, so strip all of that out.
    my $report = $timer->generate_final_report;
    my ($functions_before, $functions_after) = $report =~ m{
        ^
        START: \s [^\n]+ \n
        \s{4} [^\n]+ \n
        (.+ \n)

        Half-time \n
        \s{4} [^\n]+ \n
        (.+ \n)

        END: \s [^\n]+ \n
        $
    }xsm;
    for ($functions_before, $functions_after) {
        s/^ \s{8} //xgsm;
        s/^ \s{1,3} \d+ \s ms \s /(time) /xgsm;
    }

    # Because we said to summarise calls, each function call will be grouped
    # with its fellow calls under the first time it happens
    like($functions_before, <<BEFORE, 'The first half summary looks legit');
(time) TestMatch::Rugby::try_scored
    Flair player for Exciting team
(time) TestMatch::Rugby::penalty (x5)
    Mr Metronome for Boring team (x5)
(time) TestMatch::Rugby::try_scored
    Crazy sideburns guy for Exciting team
(time) TestMatch::Rugby::conversion
BEFORE
    like($functions_after, <<AFTER, 'The second half summary looks legit');
(time) TestMatch::Rugby::try_scored
    Flair player for Exciting team
(time) TestMatch::Rugby::penalty (x8)
    Mr Metronome for Boring team (x4)
    How many guys like this do they have? for Boring team (x3)
    They let the physio have a go lol for Exciting team
(time) TestMatch::Rugby::substitution (x13)
(time) TestMatch::Rugby::try_scored
    Flair player for Exciting team
(time) TestMatch::Rugby::conversion
(time) TestMatch::Rugby::try_scored
    Died his hair pink for Exciting team
(time) TestMatch::Rugby::try_scored
    Basically the entire front row, Warhammer-style for Boring team
(time) TestMatch::Rugby::conversion
AFTER
}

# When an object stops, or goes out of scope, we notify the caller of its
# final report.

sub test_report_notification {
    my $automatic_report;

    # If we explicitly say stop_timing, a report is generated.
    my $verbose_timer
        = Timer::Milestones->new(
        notify_report => sub { $automatic_report = shift });
    $verbose_timer->add_milestone('Done something');
    $verbose_timer->stop_timing;
    like(
        $automatic_report,
        qr{
            ^
            START: \s [^\n]+ \n
            \s{4} [^\n]+ \n
            \QDone something\E \n
            \s{4} [^\n]+ \n
            END: \s .+
            $
        }xsm,
        'Stopping timing generated a report'
    );

    # (But if we'd already generated a report, nothing happens.)
    my $quiet_timer
        = Timer::Milestones->new(
        notify_report => sub { $automatic_report = shift });
    $automatic_report = 'Nothing to see here';
    $quiet_timer->add_milestone('Nobody needs to know');
    my $quiet_report = $quiet_timer->generate_final_report;
    like(
        $quiet_report,
        qr{Nobody needs to know},
        'We got a report from generate_final_report'
    );
    $quiet_timer->stop_timing;
    is(
        $automatic_report,
        'Nothing to see here',
        'Because we generated a report explicitly, nothing else got reported'
    );

    # This also happens if our object goes out of scope.
    my $out_of_scope_report;
    my $temporary_timer = Timer::Milestones->new(
        notify_report => sub { $out_of_scope_report = shift });
    $temporary_timer->add_milestone(
        'Confront the bad guy without having told anybody else'
    );
    undef $temporary_timer;
    like(
        $out_of_scope_report,
        qr/Confront the bad guy/,
        'Going out of scope also triggers a final report'
    );
}

# If e.g. we don't have Time::HiRes, or time passed *really quickly*
# (it happened once when running these tests), we still manage to carry on
# even though the total elapsed time is 0.
sub test_divide_by_zero {
    my $timer = Timer::Milestones->new;
    $timer->{milestones} = [
        {
            name    => 'START',
            started => 12345,
            ended   => 12345,
        }
    ];
    $timer->{timing_stopped} = 1;
    like(
        $timer->_generate_report,
        qr{
            ^
            START: \s [^\n]+ \n
            \s{4} \s{2} 0 \s ms \s [(] [^)]+ [)] \n
            END: \s [^\n]+ \n
            $
        }xsm, 'We generated a report even though no time elapsed'
    );
}

# Various intervals, in fractions of seconds, seconds, minutes or hours,
# are reported in a way that makes sense to human beings.

sub test_human_elapsed_time {
    my %expect_human_elapsed_time = (
        # Anything below 1 second: milliseconds
        0.001 => '  1 ms',
        0.010 => ' 10 ms',
        0.234 => '234 ms',
        0.999 => '999 ms',
        # Anything below 1 minute: seconds
        1     => ' 1 s',
        30    => '30 s',
        59    => '59 s',
        # Less than an hour: minutes and seconds
        60    => ' 1 min  0 s',
        61    => ' 1 min  1 s',
        123   => ' 2 min  3 s',
        999   => '16 min 39 s',
        3599  => '59 min 59 s',
        # Beyond that, hours and minutes; hours aren't padded as there's
        # no upper limit to fit into.
        3600  => '1 h  0 min',
        3601  => '1 h  0 min',
        4000  => '1 h  6 min', # Rounded down
        7195  => '1 h 59 min',
        86400 => '24 h  0 min',
    );
    my $timer = Timer::Milestones->new(notify_report => sub {});
    for my $elapsed_time (sort { $a <=> $b } keys %expect_human_elapsed_time)
    {
        is(
            $timer->_human_elapsed_time($elapsed_time),
            $expect_human_elapsed_time{$elapsed_time},
            "Correct value for $elapsed_time"
        );
    }
}

1;
