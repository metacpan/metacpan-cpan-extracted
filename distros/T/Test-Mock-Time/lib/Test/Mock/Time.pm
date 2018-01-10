package Test::Mock::Time;
use 5.008001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v0.1.7';

use Export::Attrs;
use List::Util qw( any );
use Scalar::Util qw( weaken );
use Test::MockModule;

use constant TIME_HIRES_CLOCK_NOT_SUPPORTED => -1;
use constant MICROSECONDS                   => 1_000_000;
use constant NANOSECONDS                    => 1_000_000_000;

use constant DEFAULT_WAIT_ONE_TICK => 0.05;
our $WAIT_ONE_TICK = DEFAULT_WAIT_ONE_TICK;

my $Absolute    = time; # usual time starts at current actual time
my $Monotonic   = 0;    # monotonic time starts at 0 if not available
my $Relative    = 0;    # how many deterministic time passed since start
my @Timers;             # active timers
my @Timers_ns;          # inactive timers
my %Module;             # keep module mocks


_mock_core_global();
## no critic (RequireCheckingReturnValueOfEval)
eval {
    require Time::HiRes;
    Time::HiRes->import(qw( CLOCK_REALTIME CLOCK_MONOTONIC ));
    _mock_time_hires();
};
eval {
    require EV;
    _mock_ev();
};
eval {
    require Mojolicious;
    Mojolicious->VERSION('6'); # may be compatible with older ones, needs testing
    require Mojo::Reactor::Poll;
    _mock_mojolicious();
};


# FIXME make ff() reentrant
sub ff :Export(:DEFAULT) {
    my ($dur) = @_;

    @Timers = sort {
        $a->{start}+$a->{after} <=> $b->{start}+$b->{after} or
        $a->{id} cmp $b->{id}   # preserve order to simplify tests
        } @Timers;
    my $next_at = @Timers ? $Timers[0]{start}+$Timers[0]{after} : 0;
    $next_at = sprintf '%.6f', $next_at;

    if (!defined $dur) {
        $dur = $next_at > $Relative ? $next_at - $Relative : 0;
        $dur = sprintf '%.6f', $dur;
    }
    croak "ff($dur): negative time not invented yet" if $dur < 0;

    if ($next_at == 0 || $next_at > $Relative+$dur) {
        $Relative += $dur;
        $Relative = sprintf '%.6f', $Relative;
        return;
    }

    if ($next_at > $Relative) {
        $dur -= $next_at - $Relative;
        $dur = sprintf '%.6f', $dur;
        $Relative = $next_at;
    }
    my $cb = $Timers[0]{cb};
    if ($Timers[0]{repeat} == 0) {
        if ($Timers[0]{watcher}) {
            _stop_timer($Timers[0]{watcher});
        }
        else {
            shift @Timers;
        }
    }
    else {
        $Timers[0]{after} = $Timers[0]{repeat};
        $Timers[0]{start} = $Relative;
    }
    $cb->();
    @_ = ($dur);
    goto &ff;
}

{
my $next_id = 0;
sub _add_timer {
    my ($loop, $after, $repeat, $cb, $watcher) = @_;
    my $id = sprintf 'fake_%05d', $next_id++;
    push @Timers, {
        id      => $id,
        start   => $Relative,
        loop    => $loop,
        after   => sprintf('%.6f', $after < 0 ? 0 : $after),
        repeat  => sprintf('%.6f', $repeat < 0 ? 0 : $repeat),
        cb      => $cb,
        watcher => $watcher,
    };
    if ($watcher) {
        weaken($Timers[-1]{watcher});
    }
    return $id;
}
}

sub _start_timer {
    my ($watcher) = @_;
    my ($timer) = grep { $_->{watcher} && $_->{watcher} eq $watcher } @Timers_ns;
    if ($timer) {
        @Timers_ns = grep { !$_->{watcher} || $_->{watcher} ne $watcher } @Timers_ns;
        push @Timers, $timer;
    }
    return;
}

sub _stop_timer {
    my ($watcher) = @_;
    my ($timer) = grep { $_->{watcher} && $_->{watcher} eq $watcher } @Timers;
    if ($timer) {
        @Timers = grep { !$_->{watcher} || $_->{watcher} ne $watcher } @Timers;
        push @Timers_ns, $timer;
    }
    return;
}

sub _mock_core_global {
    $Module{'CORE::GLOBAL'} = Test::MockModule->new('CORE::GLOBAL', no_auto=>1);
    $Module{'CORE::GLOBAL'}->mock(time => sub () {
        return int($Absolute + $Relative);
    });
    $Module{'CORE::GLOBAL'}->mock(localtime => sub (;$) {
        my $time = defined $_[0] ? $_[0] : int($Absolute + $Relative);
        return CORE::localtime($time);
    });
    $Module{'CORE::GLOBAL'}->mock(gmtime => sub (;$) {
        my $time = defined $_[0] ? $_[0] : int($Absolute + $Relative);
        return CORE::gmtime($time);
    });
    $Module{'CORE::GLOBAL'}->mock(sleep => sub ($) {
        my $dur = int $_[0];
        croak 'sleep with negative value is not supported' if $dur < 0;
        $Relative += $dur;
        $Relative = sprintf '%.6f', $Relative;
        return $dur;
    });
    return;
}

sub _mock_time_hires {
    # Do not improve precision of current actual time to simplify tests.
    #$Absolute = Time::HiRes::time();
    # Use current actual monotonic time.
    $Monotonic = Time::HiRes::clock_gettime(CLOCK_MONOTONIC());

    $Module{'Time::HiRes'} = Test::MockModule->new('Time::HiRes');
    $Module{'Time::HiRes'}->mock(time => sub () {
        return 0+sprintf '%.6f', $Absolute + $Relative;
    });
    $Module{'Time::HiRes'}->mock(gettimeofday => sub () {
        my $t = sprintf '%.6f', $Absolute + $Relative;
        return wantarray ? (map {0+$_} split qr/[.]/ms, $t) : 0+$t;
    });
    $Module{'Time::HiRes'}->mock(clock_gettime => sub (;$) {
        my ($which) = @_;
        if ($which == CLOCK_REALTIME()) {
            return 0+sprintf '%.6f', $Absolute + $Relative;
        }
        elsif ($which == CLOCK_MONOTONIC()) {
            return 0+sprintf '%.6f', $Monotonic + $Relative;
        }
        return TIME_HIRES_CLOCK_NOT_SUPPORTED;
    });
    $Module{'Time::HiRes'}->mock(clock_getres => sub (;$) {
        my ($which) = @_;
        if ($which == CLOCK_REALTIME() || $which == CLOCK_MONOTONIC()) {
            return $Module{'Time::HiRes'}->original('clock_getres')->(@_);
        }
        return TIME_HIRES_CLOCK_NOT_SUPPORTED;
    });
    $Module{'Time::HiRes'}->mock(sleep => sub (;@) {
        my ($seconds) = @_;
        croak 'sleep without arg is not supported' if !@_;
        croak "Time::HiRes::sleep($seconds): negative time not invented yet" if $seconds < 0;
        $Relative += $seconds;
        $Relative = sprintf '%.6f', $Relative;
        return $seconds;
    });
    $Module{'Time::HiRes'}->mock(usleep => sub ($) {
        my ($useconds) = @_;
        croak "Time::HiRes::usleep($useconds): negative time not invented yet" if $useconds < 0;
        $Relative += $useconds / MICROSECONDS;
        $Relative = sprintf '%.6f', $Relative;
        return $useconds;
    });
    $Module{'Time::HiRes'}->mock(nanosleep => sub ($) {
        my ($nanoseconds) = @_;
        croak "Time::HiRes::nanosleep($nanoseconds): negative time not invented yet" if $nanoseconds < 0;
        $Relative += $nanoseconds / NANOSECONDS;
        $Relative = sprintf '%.6f', $Relative;
        return $nanoseconds;
    });
    $Module{'Time::HiRes'}->mock(clock_nanosleep => sub ($$;$) {
        my ($which, $nanoseconds, $flags) = @_;
        croak "Time::HiRes::clock_nanosleep(..., $nanoseconds): negative time not invented yet" if $nanoseconds < 0;
        croak 'only CLOCK_REALTIME and CLOCK_MONOTONIC are supported' if $which != CLOCK_REALTIME() && $which != CLOCK_MONOTONIC();
        croak 'only flags=0 is supported' if $flags;
        $Relative += $nanoseconds / NANOSECONDS;
        $Relative = sprintf '%.6f', $Relative;
        return $nanoseconds;
    });
    return;
}

# TODO Distinguish timers set on different event loops / Mojo reactor
# objects while one_tick?

sub _mock_ev { ## no critic (ProhibitExcessComplexity)
    $Module{'EV'}           = Test::MockModule->new('EV');
    $Module{'EV::Watcher'}  = Test::MockModule->new('EV::Watcher',  no_auto=>1);
    $Module{'EV::Timer'}    = Test::MockModule->new('EV::Timer',    no_auto=>1);
    $Module{'EV::Periodic'} = Test::MockModule->new('EV::Periodic', no_auto=>1);
    $Module{'EV'}->mock(time => sub () {
        return 0+sprintf '%.6f', $Absolute + $Relative;
    });
    $Module{'EV'}->mock(now => sub () {
        return 0+sprintf '%.6f', $Absolute + $Relative;
    });
    $Module{'EV'}->mock(sleep => sub ($) {
        my ($seconds) = @_;
        if ($seconds < 0) {
            $seconds = 0;
        }
        $Relative += $seconds;
        $Relative = sprintf '%.6f', $Relative;
        return;
    });
    $Module{'EV'}->mock(run => sub (;$) {
        my ($flags) = @_;
        my $tick = 0;
        my $w;
        if (@Timers) {
            $w = $Module{'EV'}->original('timer')->(
                $WAIT_ONE_TICK, $WAIT_ONE_TICK, sub {
                    my $me = shift;
                    my $k;
                    if (!$tick++ || !$flags) {
                        $k = $me->keepalive(0);
                        ff();
                    }
                    if (!@Timers) {
                        $me->stop;
                    }
                    elsif ($k && ($flags || any {$_->{watcher} && $_->{watcher}->keepalive} @Timers)) {
                        $me->keepalive(1);
                    }
                }
            );
            if (!($flags || any {$_->{watcher} && $_->{watcher}->keepalive} @Timers)) {
                $w->keepalive(0);
            }
        }
        # $tick above and this second RUN_ONCE is work around bug in EV-4.10+
        # http://lists.schmorp.de/pipermail/libev/2016q1/002656.html
        # FIXME I believe this workaround isn't correct with EV-4.03 - calling
        # RUN_ONCE twice must have side effect in processing two events
        # (at least one of them must be a non-timer event) instead of one.
        # To make it correct we probably need to mock all watcher types
        # to intercept invoking their callbacks and thus make it possible
        # to find out is first RUN_ONCE has actually called any callbacks.
        if ($flags && $flags == EV::RUN_ONCE()) {
            $Module{'EV'}->original('run')->(@_);
        }
        return $Module{'EV'}->original('run')->(@_);
    });
    $Module{'EV'}->mock(timer => sub ($$$) {
        my ($after, $repeat, $cb) = @_;
        my $w = $Module{'EV'}->original('timer_ns')->(@_);
        weaken(my $weakw = $w);
        _add_timer('EV', $after, $repeat, sub { $weakw && $weakw->invoke(EV::TIMER()) }, $w);
        return $w;
    });
    $Module{'EV'}->mock(timer_ns => sub ($$$) {
        my $w = EV::timer(@_);
        _stop_timer($w);
        return $w;
    });
    $Module{'EV'}->mock(periodic => sub ($$$$) {
        my ($at, $repeat, $reschedule_cb, $cb) = @_;
        croak 'reschedule_cb is not supported yet' if $reschedule_cb;
        $at = sprintf '%.6f', $at < 0 ? 0 : $at;
        $repeat = sprintf '%.6f', $repeat < 0 ? 0 : $repeat;
        my $now = sprintf '%.6f', $Absolute + $Relative;
        if ($repeat > 0 && $at < $now) {
            use bignum;
            $at += $repeat * int(($now - $at) / $repeat + 1);
            $at = sprintf '%.6f', $at;
        }
        my $after = $at > $now ? $at - $now : 0;
        $after = sprintf '%.6f', $after;
        my $w = $Module{'EV'}->original('periodic_ns')->(@_);
        weaken(my $weakw = $w);
        _add_timer('EV', $after, $repeat, sub { $weakw && $weakw->invoke(EV::TIMER()) }, $w);
        return $w;
    });
    $Module{'EV'}->mock(periodic_ns => sub ($$$$) {
        my $w = EV::periodic(@_);
        _stop_timer($w);
        return $w;
    });
    $Module{'EV::Watcher'}->mock(is_active => sub {
        my ($w) = @_;
        my ($active) = grep { $_->{watcher} && $_->{watcher} eq $w } @Timers;
        my ($inactive) = grep { $_->{watcher} && $_->{watcher} eq $w } @Timers_ns;
        if ($active) {
            return 1;
        }
        elsif ($inactive) {
            return;
        }
        return $Module{'EV::Watcher'}->original('is_active')->(@_);
    });
    $Module{'EV::Timer'}->mock(DESTROY => sub {
        my ($w) = @_;
        @Timers = grep { !$_->{watcher} || $_->{watcher} ne $w } @Timers;
        @Timers_ns = grep { !$_->{watcher} || $_->{watcher} ne $w } @Timers_ns;
        return $Module{'EV::Timer'}->original('DESTROY')->(@_);
    });
    $Module{'EV::Timer'}->mock(start => sub {
        return _start_timer(@_);
    });
    $Module{'EV::Timer'}->mock(stop => sub {
        return _stop_timer(@_);
    });
    $Module{'EV::Timer'}->mock(set => sub {
        my ($w, $after, $repeat) = @_;
        if (!defined $repeat) {
            $repeat = 0;
        }
        my ($timer) = grep { $_->{watcher} && $_->{watcher} eq $w } @Timers, @Timers_ns;
        if ($timer) {
            $timer->{start} = $Relative;
            $timer->{after} = sprintf '%.6f', $after < 0 ? 0 : $after;
            $timer->{repeat}= sprintf '%.6f', $repeat < 0 ? 0 : $repeat;
        }
        return;
    });
    $Module{'EV::Timer'}->mock(remaining => sub {
        my ($w) = @_;
        my ($timer) = grep { $_->{watcher} && $_->{watcher} eq $w } @Timers, @Timers_ns;
        if ($timer) {
            return 0+sprintf '%.6f', $timer->{start} + $timer->{after} - $Relative;
        }
        return;
    });
    $Module{'EV::Timer'}->mock(again => sub {
        my ($w, $repeat) = @_;
        if (defined $repeat && $repeat < 0) {
            $repeat = 0;
        }
        my ($active) = grep { $_->{watcher} && $_->{watcher} eq $w } @Timers;
        my ($inactive) = grep { $_->{watcher} && $_->{watcher} eq $w } @Timers_ns;
        if ($active) {
            $active->{repeat} = sprintf '%.6f', defined $repeat ? $repeat : $active->{repeat};
            if ($active->{repeat} > 0) {
                $active->{after} = $active->{repeat};
                $active->{start} = $Relative;
            }
            else {
                _stop_timer($active->{watcher});
            }
        }
        elsif ($inactive) {
            $inactive->{repeat} = sprintf '%.6f', defined $repeat ? $repeat : $inactive->{repeat};
            if ($inactive->{repeat} > 0) {
                $inactive->{after} = $inactive->{repeat};
                $inactive->{start} = $Relative;
                _start_timer($inactive->{watcher});
            }
        }
        return;
    });
    $Module{'EV::Periodic'}->mock(DESTROY => sub {
        my ($w) = @_;
        @Timers = grep { !$_->{watcher} || $_->{watcher} ne $w } @Timers;
        @Timers_ns = grep { !$_->{watcher} || $_->{watcher} ne $w } @Timers_ns;
        return $Module{'EV::Periodic'}->original('DESTROY')->(@_);
    });
    $Module{'EV::Periodic'}->mock(start => sub {
        return _start_timer(@_);
    });
    $Module{'EV::Periodic'}->mock(stop => sub {
        return _stop_timer(@_);
    });
    $Module{'EV::Periodic'}->mock(set => sub {
        my ($w, $at, $repeat, $reschedule_cb, $cb) = @_;
        croak 'reschedule_cb is not supported yet' if $reschedule_cb;
        $at = sprintf '%.6f', $at < 0 ? 0 : $at;
        $repeat = sprintf '%.6f', $repeat < 0 ? 0 : $repeat;
        my $now = sprintf '%.6f', $Absolute + $Relative;
        if ($repeat > 0 && $at < $now) {
            use bignum;
            $at += $repeat * int(($now - $at) / $repeat + 1);
            $at = sprintf '%.6f', $at;
        }
        my $after = $at > $now ? $at - $now : 0;
        $after = sprintf '%.6f', $after;
        my ($timer) = grep { $_->{watcher} && $_->{watcher} eq $w } @Timers, @Timers_ns;
        if ($timer) {
            $timer->{start} = $Relative;
            $timer->{after} = $after;
            $timer->{repeat}= $repeat;
        }
        return;
    });
    $Module{'EV::Periodic'}->mock(again => sub {
        return _start_timer(@_);
    });
    $Module{'EV::Periodic'}->mock(at => sub {
        my ($w) = @_;
        my ($timer) = grep { $_->{watcher} && $_->{watcher} eq $w } @Timers, @Timers_ns;
        if ($timer) {
            return 0+sprintf '%.6f', $timer->{start} + $timer->{after};
        }
        return;
    });
    return;
}

sub _mock_mojolicious {
    $Module{'Mojo::Reactor::Poll'} = Test::MockModule->new('Mojo::Reactor::Poll');
    $Module{'Mojo::Reactor::Poll'}->mock(one_tick => sub {
        my ($self) = @_;
        if (!@Timers) {
            return $Module{'Mojo::Reactor::Poll'}->original('one_tick')->(@_);
        }
        my $id = $Module{'Mojo::Reactor::Poll'}->original('timer')->(
            $self, $WAIT_ONE_TICK, sub { ff() }
        );
        $Module{'Mojo::Reactor::Poll'}->original('one_tick')->(@_);
        $Module{'Mojo::Reactor::Poll'}->original('remove')->($self, $id);
        return;
    });
    $Module{'Mojo::Reactor::Poll'}->mock(timer => sub {
        my ($self, $delay, $cb) = @_;
        if ($delay == 0) {  # do not fake timer for 0 seconds to avoid hang
            return $Module{'Mojo::Reactor::Poll'}->original('timer')->(@_);
        }
        return _add_timer($self, $delay, 0, sub { $cb->($self) });
    });
    $Module{'Mojo::Reactor::Poll'}->mock(recurring => sub {
        my ($self, $delay, $cb) = @_;
        return _add_timer($self, $delay, $delay, sub { $cb->($self) });
    });
    $Module{'Mojo::Reactor::Poll'}->mock(again => sub {
        my ($self, $id) = @_;
        if ($id !~ /\Afake_\d+\z/ms) {
            $Module{'Mojo::Reactor::Poll'}->original('again')->(@_);
        }
        else {
            my ($timer) = grep { $_->{id} eq $id } @Timers;
            if ($timer) {
                $timer->{start} = $Relative;
            }
        }
        return;
    });
    $Module{'Mojo::Reactor::Poll'}->mock(remove => sub {
        my ($self, $id) = @_;
        if ($id !~ /\Afake_\d+\z/ms) {
            $Module{'Mojo::Reactor::Poll'}->original('remove')->(@_);
        }
        else {
            @Timers = grep { $_->{loop} ne $self || $_->{id} ne $id } @Timers;
        }
        return;
    });
    $Module{'Mojo::Reactor::Poll'}->mock(reset => sub {
        my ($self) = @_;
        @Timers = grep { $_->{loop} ne $self } @Timers;
        return $Module{'Mojo::Reactor::Poll'}->original('reset')->(@_);
    });
    return;
}


1;
__END__

=encoding utf8

=for stopwords localtime gmtime gettimeofday usleep nanosleep

=head1 NAME

Test::Mock::Time - Deterministic time & timers for event loop tests


=head1 VERSION

This document describes Test::Mock::Time version v0.1.7


=head1 SYNOPSIS

  use Test::Mock::Time;

  # All these functions will return same constant time
  # until you manually move time forward by some deterministic
  # value by sleep(), ff() or doing one tick of your event loop.
  say time();
  say localtime();
  say gmtime();
  say Time::HiRes::time();
  say Time::HiRes::gettimeofday();
  say Time::HiRes::clock_gettime(CLOCK_REALTIME());
  say Time::HiRes::clock_gettime(CLOCK_MONOTONIC());

  # All these functions will fast-forward time (so time() etc.
  # will return increased value on next call) and return immediately.
  # Pending timers of your event loop (if any) will not be processed.
  sleep(1);
  Time::HiRes::sleep(0.5);
  Time::HiRes::usleep(500_000);
  Time::HiRes::nanosleep(500_000_000);
  Time::HiRes::clock_nanosleep(500_000_000);

  # This will fast-forward time and process pending timers (if any).
  ff(0.5);

  # These will call ff() in case no other (usually I/O) event happens in
  # $Test::Mock::Time::WAIT_ONE_TICK seconds of real time and there are
  # some active timers.
  Mojo::IOLoop->one_tick;
  EV::run(EV::RUN_ONCE);


=head1 DESCRIPTION

This module replaces actual time with simulated time everywhere
(core time(), Time::HiRes, EV, AnyEvent with EV, Mojolicious, …) and
provide a way to write deterministic tests for event loop based
applications with timers.

B<IMPORTANT!> This module B<must> be loaded by your script/app/test before
other related modules (Time::HiRes, Mojolicious, EV, etc.).


=head1 EXPORTS

These functions are exported by default:

    ff


=head1 INTERFACE

=head2 WAIT_ONE_TICK

    $Test::Mock::Time::WAIT_ONE_TICK = 0.05;

This value is used to limit amount of real time spend waiting for
non-timer (usually I/O) event while one tick of event loop if there are
some active timers. In case no events happens while this time event loop
will be interrupted and time will be fast-forward to time when next timer
should expire by calling ff().

=head2 ff

    ff( $seconds );
    ff();

Fast-forward current time by $seconds (can be fractional). All functions
like time() will returns previous value increased by $seconds after that.

Will run callbacks for pending timers of your event loop if they'll expire
while $seconds or if they've already expired (because you've used functions
like sleep() which fast-forward time without processing timers).

When called without params will fast-forward time by amount needed to run
callback for next pending timer (it may be 0 in case there are no pending
timers or if next pending timer already expired).

=head2 Mocked functions/methods from other modules

See L</"SYNOPSIS"> for explanation how they works.

=over

=item CORE::GLOBAL

=over

=item time

=item localtime

=item gmtime

=item sleep

=back

=item Time::HiRes

=over

=item time

=item gettimeofday

=item clock_gettime

=item clock_getres

=item sleep

=item usleep

=item nanosleep

=item clock_nanosleep

=back

=item Mojo::Reactor::Poll

All required methods.

=item EV

All required methods except:

    EV::once
    EV::Watcher::feed_event

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-Test-Mock-Time/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-Test-Mock-Time>

    git clone https://github.com/powerman/perl-Test-Mock-Time.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=Test-Mock-Time>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Test-Mock-Time>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Mock-Time>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Test-Mock-Time>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/Test-Mock-Time>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016- by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
