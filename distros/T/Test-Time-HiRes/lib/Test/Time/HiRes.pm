package Test::Time::HiRes;

use strict;
use warnings;

use Test::More;
use Test::Time;
use Time::HiRes ();

our $VERSION = '0.04';

our $time    = 0;    # epoch in microseconds
our $seconds = 0;    # i.e. standard epoch

my $in_effect = 1;
my $imported  = 0;

sub in_effect {
    $in_effect;
}

sub set_time {
    my ( $class, $arg ) = @_;

    $Test::Time::time = $seconds = int($arg);    # epoch time in seconds
    $time = $arg * 1_000_000;                    # epoch time in microseconds
}

# synchronise times so time is correct whether using sleep() or usleep().
# - assume time only goes forwards
# - take the highest as current epoch time
sub _synchronise_times {

    if ( $seconds < $Test::Time::time ) {

        # update seconds from Test::Time, but keep the fractional microsecond part
        my $microseconds = _microseconds();    # part after DP
        $seconds = $Test::Time::time;
        $time    = ( $seconds * 1_000_000 ) + $microseconds;
    }
    elsif ( $seconds > $Test::Time::time ) {
        $Test::Time::time = $seconds;
    }
}

sub _microseconds {
    return 0 unless $time;
    return $time % 1_000_000;
}

sub import {
    my ( $class, %opts ) = @_;

    $in_effect = 1;
    Test::Time->import; # make sure Test::Time is enabled, in case
                        # there was a call to ->unimport earlier

    return if $imported;

    # If time set on import then use it and update
    # Test::Time, otherwise use $Test::Time::time
    if ( defined $opts{time} ) {
        $class->set_time( $opts{time} );
    }
    else {
        $seconds = $Test::Time::time;
        $time    = $seconds * 1_000_000;
    }

    no warnings 'redefine';

    # keep copies of the original subroutines
    my $sub_time         = \&Time::HiRes::time;
    my $sub_usleep       = \&Time::HiRes::usleep;
    my $sub_gettimeofday = \&Time::HiRes::gettimeofday;

    *Time::HiRes::time = sub() {
        if (in_effect) {
            _synchronise_times();

            my $t = $time / 1_000_000;
            return sprintf( "%.6f", $t );
        }
        else {
            return $sub_time->();
        }
    };

    *Time::HiRes::usleep = sub($) {

        unless (@_) {
            return $sub_usleep->();    # always give "no argument" error
        }

        if (in_effect) {
            my $sleep = shift;

            _synchronise_times();

            return 0 unless $sleep;

            $time    = $time + $sleep;
            $seconds = int( $time / 1_000_000 );

            _synchronise_times();

            note "sleep $sleep";

            return $sleep;
        }
        else {
            return $sub_usleep->(shift);
        }
    };

    *Time::HiRes::gettimeofday = sub() {
        if (in_effect) {
            _synchronise_times();
            return ( $seconds, _microseconds() );
        }
        else {
            return $sub_gettimeofday->();
        }
    };

    $imported++;
}

sub unimport {
    $in_effect = 0;
    Test::Time->unimport();
}

1;

__END__

=head1 NAME

Test::Time::HiRes - drop-in replacement for Test::Time to work with Time::HiRes

=head1 SYNOPSIS

    # ensure loaded before any code importing functions from Time::HiRes
    use Test::Time::HiRes time => 123.456789;

    # Freeze time
    my $now       = time();
    my $now_hires = Time::HiRes::time();

    # Increment internal time (returns immediately)
    sleep 1;        # seconds
    usleep 1000;    # microseconds

    # Return internal time incremented by 1.001s
    my $then       = time();
    my $then_hires = Time::HiRes::time();

    # set/reset time
    Test::Time::HiRes->set_time( 123.456789 );

    Test::Time::HiRes->unimport(); # turn off behaviour

=head1 DESCRIPTION

Drop-in replacement for L<Test::Time> that also works with the L<Time::HiRes>
functions C<usleep> and C<gettimeofday>.

Must be loaded before importing functions from L<Time::HiRes>.

Patches/suggestions very welcome. This was just a quick fix to a problem.

=head1 SEE ALSO

=over

=item L<Test::Time>

=back

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/mjemmeson/Test-Time-HiRes/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/mjemmeson/Test-Time-HiRes>

    git clone git://github.com/mjemmeson/Test-Time-HiRes.git

=head1 AUTHOR

Michael Jemmeson E<lt>mjemmeson@cpan.orgE<gt>

=head1 CONTRIBUTORS

Gianni Ceccarelli E<lt>dakkar@thenautilus.netE<gt>

=head1 COPYRIGHT

Copyright 2018- Michael Jemmeson

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


