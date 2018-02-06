package Test::Time::HiRes;

use strict;
use warnings;

use Test::More;
use Test::Time;
use Time::HiRes ();

our $VERSION = '0.02';

our $time    = 0;    # epoch in microseconds
our $seconds = 0;    # i.e. standard epoch

my $in_effect = 1;

sub in_effect {
    $in_effect;
}

# assume time only goes forwards
# take the highest as current epoch time
sub _synchronise_times {
    if ( $seconds < $Test::Time::time ) {
        my $microseconds = _microseconds();    # part after DP
        $seconds = $Test::Time::time;
        $time    = ( $seconds * 1_000_000 ) + $microseconds;
    }
}

sub _time {
    _synchronise_times();
    return $time;
}

sub _seconds {
    _synchronise_times();
    return $seconds;
}

sub _microseconds {
    return 0 unless $time;
    return $time - ( $seconds * 1_000_000 );
}

sub import {
    my ( $class, %opts ) = @_;

    # If time set on import then use it and update
    # Test::Time, otherwise use $Test::Time::time
    if ( defined $opts{time} ) {
        my $tmp = $opts{time};
        $Test::Time::time = $seconds = int($tmp);
        $time = $tmp * 1_000_000;
    }
    else {
        $seconds = $Test::Time::time;
        $time    = $seconds * 1_000_000;
    }

    no warnings 'redefine';

    my $sub_time         = *Time::HiRes::time;
    my $sub_usleep       = *Time::HiRes::usleep;
    my $sub_gettimeofday = *Time::HiRes::gettimeofday;

    *Time::HiRes::time = sub() {
        if (in_effect) {
            my $t = _time() / 1_000_000;
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

            return 0 unless $sleep;

            $time    = _time() + $sleep;
            $seconds = int( $time / 1_000_000 );

            # update Test::Time to keep our $time's in sync
            if ( $seconds > $Test::Time::time ) {
                $Test::Time::time = $seconds;
            }

            note "sleep $sleep";

            return $sleep;
        }
        else {
            return $sub_usleep->(shift);
        }
    };

    *Time::HiRes::gettimeofday = sub() {
        if (in_effect) {
            return ( _seconds(), _microseconds() );
        }
        else {
            return $sub_gettimeofday->();
        }
    };
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

=head1 COPYRIGHT

Copyright 2018- Michael Jemmeson

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


