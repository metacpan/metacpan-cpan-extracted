package Time::ETA::MockTime;
$Time::ETA::MockTime::VERSION = '1.2.0';
# ABSTRACT: make it possible to test time


use warnings;
use strict;
use Exporter qw(import);
use Time::HiRes qw();
use Carp;

our @EXPORT_OK = qw(
    sleep
    usleep
    gettimeofday
);
our @EXPORT = @EXPORT_OK;

our @mocked_time = Time::HiRes::gettimeofday();
my $microseconds_in_second = 1_000_000;

{
    no strict 'refs';
    no warnings 'redefine';

    my @packages_having_gettimeofday = grep {defined(&{$_ . '::gettimeofday'})} (map {s'\.pm''; s'/'::'g; $_} keys(%INC)), 'main';
    *{$_ . '::gettimeofday'} = \&Time::ETA::MockTime::gettimeofday foreach @packages_having_gettimeofday;
}


sub sleep {
    my ($seconds) = @_;

    croak "Incorrect seconds" if $seconds !~ /^[0-9]+$/;
    $mocked_time[0] += $seconds;
}


sub usleep ($) {
    my ($microseconds) = @_;

    croak "Incorrect microseconds" if $microseconds !~ /^[0-9]+$/;

    $mocked_time[1] += $microseconds;
    my $ms = $mocked_time[1] % $microseconds_in_second;
    my $remain = $mocked_time[1] - $ms;

    $mocked_time[0] += ($remain / $microseconds_in_second);
    $mocked_time[1] = $ms;
}


sub gettimeofday () {
    if (@mocked_time) {
        return wantarray ? @mocked_time : "$mocked_time[0].$mocked_time[1]";
    }
}


sub set_mock_time  {
    my ($sec, $ms) = @_;

    $mocked_time[0] = $sec;
    $mocked_time[1] = $ms;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Time::ETA::MockTime - make it possible to test time

=head1 VERSION

version 1.2.0

=head1 DESCRIPTION

This is an internal thing that is used only in testing Perl module Time::ETA.

=head1 sleep

=head1 usleep

=head1 gettimeofday

=head1 set_mock_time

=head1 AUTHOR

Ivan Bessarabov <ivan@bessarabov.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Bessarabov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
