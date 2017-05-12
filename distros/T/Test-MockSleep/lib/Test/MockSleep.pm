package Test::MockSleep;
use strict;
use warnings;

our $VERSION = 0.02;

no warnings 'redefine';
my $time_hires_sleep;
my $have_mock_time;

our $use_mock_time = 0;

our $Slept;

sub mock_sleep (;@) {
    my $seconds = shift;
    $seconds ||= 0;
    $Slept += $seconds;
    if($have_mock_time && $use_mock_time) {
        Test::MockTime::set_relative_time($seconds);
    }
}

sub slept {
    my $ret = $Slept;
    $Slept = 0;
    return $ret;
}

eval {
    require Time::HiRes;
    $time_hires_sleep = \&Time::HiRes::sleep;
};

eval {
    require Test::MockTime;
    $have_mock_time = 1;
};

sub import {
    my $cls = shift;
    my @args = @_;
    
    if(grep $_ eq ':with_mocktime', @args) {
        $use_mock_time = 1;
    } else {
        $use_mock_time = 0;
    }
    
    my $cpkg = caller();
    no strict 'refs';
    *{$cpkg.'::slept'} = \&slept;
    *CORE::GLOBAL::sleep = \&mock_sleep;
    if($time_hires_sleep) {
        *Time::HiRes::sleep = \&mock_sleep;
    }
    1;
}

sub restore {
    my ($cpkg,@args);
    
    if($have_mock_time && $use_mock_time) {
        Test::MockTime::restore();
    }
    
    *CORE::GLOBAL::sleep = sub (;@) { CORE::sleep(shift) };
    if($time_hires_sleep) {
        *Time::HiRes::sleep = $time_hires_sleep;
    }
}
1;

__END__

=head1 NAME

Test::MockSleep - Pretend to sleep!

=head1 SYNOPSIS

    use Test::More;
    use Test::MockSleep;
    
    use Time::HiRes;
    
    use Dir::Self;
    use lib __DIR__;
    use dummy_module;
    
    my $begin_time = time();
    
    sleep(20);
    is(slept, 20, "in same module (CORE::sleep)");
    Time::HiRes::sleep(2.5);
    is(slept, 2.5, "in same module (Time::HiRes::sleep)");
    
    dummy_module::sleep_core(5);
    is(slept(), 5, "CORE::sleep");
    
    dummy_module::sleep_time_hires(0.5);
    is(slept(), 0.5, "Time::HiRes::sleep");
    
    dummy_module_thr::thr_sleep(0.5);
    is(slept(), 0.5, "Time::HiRes::sleep (implicit)");
    
    sleep(100);
    sleep(100);
    is($Test::MockSleep::Slept, 200, "package \$Slept");
    
    Test::MockSleep->restore();
    my $begin = Time::HiRes::time();
    Time::HiRes::sleep(0.1);
    my $end = Time::HiRes::time();
    ok($begin != $end, "Real Time::HiRes::sleep: ($begin to $end)");
    
    diag "Sleeping 1 second for real";
    
    $begin = time();
    sleep(1);
    $end = time();
    ok($begin != $end, "Real CORE::sleep ($begin to $end)");
    
    done_testing();

=head1 DESCRIPTION

C<Test::MockSleep> overrides perl's C<sleep> call. A call to C<sleep> will not
really sleep.

It also provides a facility to check how many seconds a program would have slept.


It has a few bonuses:

=over

=item *

If L<Time::HiRes> is available, this module will override its C<sleep> method as
well.

=item *

If L<Test::MockTime> is available, and C<Time::MockSleep> is imported with the
C<:with_mocktime> option, then C<Time::MockTime>'s clock will be adjusted to show
the updated time, B<as-if> the program had actually slept, and the clock is advanced.

=back

=head2 DETERMINING TIME FAKE-SLEPT

There are two means to do this. The more convenient is a function called C<slept>
which is exported to your calling code's namespace.

    use Test::MockSleep;
    sleep(5);
    my $slept = slept();
    
C<Test::MockSleep> retains an internal counter which increments each time sleep
is called. This counter is reset when C<slept> is called, which is presumably
what you want anyway.

If for whatever reason, you do not want the internal counter to be reset, you can
access it directly as a package variable: C<$Test::MockSleep::Slept>, and reset
it manually when desired.

=head2 MANGLING SLEEP

Simply do
    
    use Test::MockSleep;
    
This should be done before C<use>ing other modules which might potentially use
L<Time::HiRes>'s sleep (in which case the calling package's C<sleep> will be
aliased to Time::HiRes' sleep, at the time of import).

If you wish to have your clocked advanced as well, and the module
L<Test::MockTime> is installed, you can do

    use Test::MockSleep qw(:with_mocktime);
    
=head2 FINALLY GOING TO BED

    Test::MockSleep->restore();
    
Will restore global sleep's behavior (as well as Time::HiRes').

=head1 AUTHOR & COPYRIGHT

Copyright (C) 2012 by M. Nunberg

You may use and distribute this software under the same terms and license as Perl
itself.

=head1 SEE ALSO

L<Test::MockTime>
