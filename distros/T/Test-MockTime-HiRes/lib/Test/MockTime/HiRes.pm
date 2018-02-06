package Test::MockTime::HiRes;
use strict;
use warnings;

# cpan
use Test::More;
use Test::MockTime qw(:all);
use Time::HiRes;

# core
use Exporter qw(import);
our @EXPORT = qw(
    set_relative_time
    set_absolute_time
    set_fixed_time
    restore_time
    mock_time
);

our $VERSION = '0.08';

my $datetime_was_loaded;

BEGIN {
    no warnings 'redefine';
    my $_time_original = \&Test::MockTime::_time;
    *Test::MockTime::_time = sub {
        my ($time, $spec) = @_;
        my $usec = 0;
        ($time, $usec) = ($1, $2) if $time =~ /\A(\d+)[.](\d+)\z/;
        $time = $_time_original->($time, $spec);
        $time = "$time.$usec" if $usec;
        return $time;
    };

    *CORE::GLOBAL::sleep = sub ($) {
        return int(Test::MockTime::HiRes::_sleep($_[0], sub {CORE::sleep $_[0]}));
    };
    my $hires_clock_gettime = \&Time::HiRes::clock_gettime;
    my $hires_time = \&Time::HiRes::time;
    my $hires_gettimeofday = \&Time::HiRes::gettimeofday;
    my $hires_sleep = \&Time::HiRes::sleep;
    my $hires_usleep = \&Time::HiRes::usleep;
    my $hires_nanosleep = \&Time::HiRes::nanosleep;

    *Test::MockTime::time = sub () {
        return int(Test::MockTime::HiRes::time($hires_time));
    };
    *CORE::GLOBAL::time = \&Test::MockTime::time;

    *Time::HiRes::clock_gettime = sub (;$) {
        return Test::MockTime::HiRes::time($hires_clock_gettime, @_);
    };
    *Time::HiRes::time = sub () {
        return Test::MockTime::HiRes::time($hires_time);
    };
    *Time::HiRes::gettimeofday = sub () {
        return Test::MockTime::HiRes::gettimeofday($hires_gettimeofday);
    };
    *Time::HiRes::sleep = sub (;@) {
        return Test::MockTime::HiRes::_sleep($_[0], $hires_sleep);
    };
    *Time::HiRes::usleep = sub ($) {
        return Test::MockTime::HiRes::_sleep($_[0], $hires_usleep, 1000_000);
    };
    *Time::HiRes::nanosleep = sub ($) {
        return Test::MockTime::HiRes::_sleep($_[0], $hires_nanosleep, 1000_000_000);
    };

    $datetime_was_loaded = 1 if $INC{'DateTime.pm'};
}

sub time ($;@) {
    my $original = shift;
    defined $Test::MockTime::fixed ? $Test::MockTime::fixed : $original->(@_) + $Test::MockTime::offset;
}

sub gettimeofday() {
    my $original = shift;
    if (defined $Test::MockTime::fixed) {
        return wantarray ? do {
            my $int_part = int($Test::MockTime::fixed);
            ($int_part, 1_000_000 * sprintf('%.6f', ($Test::MockTime::fixed - $int_part)))
        }: $Test::MockTime::fixed;
    } else {
        return $original->(@_);
    }
};

sub _sleep ($&;$) {
    my ($sec, $original, $resolution) = @_;
    if (defined $Test::MockTime::fixed) {
        $sec /= $resolution if $resolution;
        $Test::MockTime::fixed += $sec;
        note "sleep $sec";
        return $sec;
    } else {
        return $original->($sec);
    }
}

sub mock_time (&$) {
    my ($code, $time) = @_;

    warn sprintf(
        '%s does not affect DateTime->now since %s is loaded after DateTime',
        'mock_time',
        __PACKAGE__,
    ) if $datetime_was_loaded;

    local $Test::MockTime::fixed = $time;
    return $code->();
}

1;
__END__

=head1 NAME

Test::MockTime::HiRes - Replaces actual time with simulated high resolution time

=head1 SYNOPSIS

    use Test::MockTime::HiRes qw(mock_time);

    my $now = time;
    mock_time {
        time;    # == $now;

        sleep 3; # returns immediately

        time;    # == $now + 3;

        usleep $microsecond;
    } $now;

=head1 DESCRIPTION

C<Test::MockTime::HiRes> is a L<Time::HiRes> compatible version of
L<Test::MockTime>.  You can wait milliseconds in simulated time.

It also provides C<mock_time> to restrict the effect of the simulation
in a code block.

=head1 SEE ALSO

L<Test::MockTime>

L<Time::HiRes>

=head1 LICENSE

Copyright (C) INA Lintaro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

INA Lintaro E<lt>tarao.gnn@gmail.comE<gt>

=cut
