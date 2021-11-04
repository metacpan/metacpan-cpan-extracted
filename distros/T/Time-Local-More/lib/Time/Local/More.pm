package Time::Local::More;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-17'; # DATE
our $DIST = 'Time-Local-More'; # DIST
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
                       time_startofminute_local
                       time_startofminute_utc
                       localtime_startofminute
                       gmtime_startofminute

                       time_startofhour_local
                       time_startofhour_utc
                       localtime_startofhour
                       gmtime_startofhour

                       time_startofday_local
                       time_startofday_utc
                       localtime_startofday
                       gmtime_startofday

                       time_startofsaturday_local
                       time_startofsaturday_utc
                       localtime_startofsaturday
                       gmtime_startofsaturday

                       time_startofsunday_local
                       time_startofsunday_utc
                       localtime_startofsunday
                       gmtime_startofsunday

                       time_startofmonday_local
                       time_startofmonday_utc
                       localtime_startofmonday
                       gmtime_startofmonday

                       time_startofmonth_local
                       time_startofmonth_utc
                       localtime_startofmonth
                       gmtime_startofmonth

                       time_startoflastdayofmonth_local
                       time_startoflastdayofmonth_utc
                       localtime_startoflastdayofmonth
                       gmtime_startoflastdayofmonth

                       time_startoflastdayoflastmonth_local
                       time_startoflastdayoflastmonth_utc
                       localtime_startoflastdayoflastmonth
                       gmtime_startoflastdayoflastmonth

                       time_startofyear_local
                       time_startofyear_utc
                       localtime_startofyear
                       gmtime_startofyear
               );
our %EXPORT_TAGS = (all => \@EXPORT_OK);

# XXX just calculate ($t - $t[0]) for speed, benchmark the diff
sub time_startofminute_local {
    my @t = localtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    require Time::Local;
    Time::Local::timelocal_nocheck(@t);
}

sub time_startofminute_utc {
    my @t = gmtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    require Time::Local;
    Time::Local::timegm_nocheck(@t);
}

sub localtime_startofminute {
    my @t = localtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    if (wantarray) {
        return @t;
    } else {
        require Time::Local;
        localtime(Time::Local::timelocal_nocheck(@t));
    }
}

sub gmtime_startofminute {
    my @t = gmtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    if (wantarray) {
        return @t;
    } else {
        require Time::Local;
        gmtime(Time::Local::timegm_nocheck(@t));
    }
}

sub time_startofhour_local {
    my @t = localtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    $t[1] = 0; # minute
    require Time::Local;
    Time::Local::timelocal_nocheck(@t);
}

sub time_startofhour_utc {
    my @t = gmtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    $t[1] = 0; # minute
    require Time::Local;
    Time::Local::timegm_nocheck(@t);
}

sub localtime_startofhour {
    my @t = localtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    $t[1] = 0; # minute
    if (wantarray) {
        return @t;
    } else {
        require Time::Local;
        localtime(Time::Local::timelocal_nocheck(@t));
    }
}

sub gmtime_startofhour {
    my @t = gmtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    $t[1] = 0; # minute
    if (wantarray) {
        return @t;
    } else {
        require Time::Local;
        gmtime(Time::Local::timegm_nocheck(@t));
    }
}

sub time_startofday_local {
    my @t = localtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    $t[1] = 0; # minute
    $t[2] = 0; # hour
    require Time::Local;
    Time::Local::timelocal_nocheck(@t);
}

sub time_startofday_utc {
    my @t = gmtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    $t[1] = 0; # minute
    $t[2] = 0; # hour
    require Time::Local;
    Time::Local::timegm_nocheck(@t);
}

sub localtime_startofday {
    my @t = localtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    $t[1] = 0; # minute
    $t[2] = 0; # hour
    if (wantarray) {
        return @t;
    } else {
        require Time::Local;
        localtime(Time::Local::timelocal_nocheck(@t));
    }
}

sub gmtime_startofday {
    my @t = gmtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    $t[1] = 0; # minute
    $t[2] = 0; # hour
    if (wantarray) {
        return @t;
    } else {
        require Time::Local;
        gmtime(Time::Local::timegm_nocheck(@t));
    }
}

sub time_startofsaturday_local {
    my @t  = localtime(defined $_[0] ? $_[0] : time());
    $t[0]  = 0; # second
    $t[1]  = 0; # minute
    $t[2]  = 0; # hour
    $t[3] -= ($t[6]<6 ? $t[6]+7 : $t[6]) - 6; # day
    # $t[6]  = 6; # wday -> 6 saturday # no effect
    require Time::Local;
    Time::Local::timelocal_nocheck(@t);
}

sub time_startofsaturday_utc {
    my @t = gmtime(defined $_[0] ? $_[0] : time());
    $t[0]  = 0; # second
    $t[1]  = 0; # minute
    $t[2]  = 0; # hour
    $t[3] -= ($t[6]<6 ? $t[6]+7 : $t[6]) - 6; # day
    # $t[6]  = 6; # wday -> 6 saturday # no effect
    require Time::Local;
    Time::Local::timegm_nocheck(@t);
}

sub localtime_startofsaturday {
    my @t = localtime(defined $_[0] ? $_[0] : time());
    $t[0]  = 0; # second
    $t[1]  = 0; # minute
    $t[2]  = 0; # hour
    $t[3] -= ($t[6]<6 ? $t[6]+7 : $t[6]) - 6; # day
    # $t[6]  = 6; # wday -> 6 saturday # no effect
    require Time::Local;
    localtime(Time::Local::timelocal_nocheck(@t));
}

sub gmtime_startofsaturday {
    my @t = gmtime(defined $_[0] ? $_[0] : time());
    $t[0]  = 0; # second
    $t[1]  = 0; # minute
    $t[2]  = 0; # hour
    $t[3] -= ($t[6]<6 ? $t[6]+7 : $t[6]) - 6; # day
    # $t[6]  = 6; # wday -> 6 saturday # no effect
    require Time::Local;
    gmtime(Time::Local::timegm_nocheck(@t));
}

sub time_startofsunday_local {
    my @t  = localtime(defined $_[0] ? $_[0] : time());
    $t[0]  = 0; # second
    $t[1]  = 0; # minute
    $t[2]  = 0; # hour
    $t[3] -= $t[6]; # day
    # $t[6]  = 0; # wday -> 0 sunday # no effect
    require Time::Local;
    Time::Local::timelocal_nocheck(@t);
}

sub time_startofsunday_utc {
    my @t = gmtime(defined $_[0] ? $_[0] : time());
    $t[0]  = 0; # second
    $t[1]  = 0; # minute
    $t[2]  = 0; # hour
    $t[3] -= $t[6]; # day
    # $t[6]  = 0; # wday -> 0 sunday # no effect
    require Time::Local;
    Time::Local::timegm_nocheck(@t);
}

sub localtime_startofsunday {
    my @t = localtime(defined $_[0] ? $_[0] : time());
    $t[0]  = 0; # second
    $t[1]  = 0; # minute
    $t[2]  = 0; # hour
    $t[3] -= $t[6]; # day
    # $t[6]  = 0; # wday -> 0 sunday # no effect
    require Time::Local;
    localtime(Time::Local::timelocal_nocheck(@t));
}

sub gmtime_startofsunday {
    my @t = gmtime(defined $_[0] ? $_[0] : time());
    $t[0]  = 0; # second
    $t[1]  = 0; # minute
    $t[2]  = 0; # hour
    $t[3] -= $t[6]; # day
    # $t[6]  = 0; # wday -> 0 sunday # no effect
    require Time::Local;
    gmtime(Time::Local::timegm_nocheck(@t));
}

sub time_startofmonday_local {
    my @t  = localtime(defined $_[0] ? $_[0] : time());
    $t[0]  = 0; # second
    $t[1]  = 0; # minute
    $t[2]  = 0; # hour
    $t[3] -= ($t[6] < 1 ? $t[6]+7 : $t[6]) - 1; # day
    # $t[6]  = 1; # wday -> 1 monday # no effect
    require Time::Local;
    Time::Local::timelocal_nocheck(@t);
}

sub time_startofmonday_utc {
    my @t = gmtime(defined $_[0] ? $_[0] : time());
    $t[0]  = 0; # second
    $t[1]  = 0; # minute
    $t[2]  = 0; # hour
    $t[3] -= ($t[6] < 1 ? $t[6]+7 : $t[6]) - 1; # day
    # $t[6]  = 1; # wday -> 1 monday # no effect
    require Time::Local;
    Time::Local::timegm_nocheck(@t);
}

sub localtime_startofmonday {
    my @t = localtime(defined $_[0] ? $_[0] : time());
    $t[0]  = 0; # second
    $t[1]  = 0; # minute
    $t[2]  = 0; # hour
    $t[3] -= ($t[6] < 1 ? $t[6]+7 : $t[6]) - 1; # day
    # $t[6]  = 1; # wday -> 1 monday # no effect
    require Time::Local;
    localtime(Time::Local::timelocal_nocheck(@t));
}

sub gmtime_startofmonday {
    my @t = localtime(defined $_[0] ? $_[0] : time());
    $t[0]  = 0; # second
    $t[1]  = 0; # minute
    $t[2]  = 0; # hour
    $t[3] -= ($t[6] < 1 ? $t[6]+7 : $t[6]) - 1; # day
    # $t[6]  = 1; # wday -> 1 monday # no effect
    require Time::Local;
    gmtime(Time::Local::timegm_nocheck(@t));
}

sub time_startofmonth_local {
    my @t = localtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    $t[1] = 0; # minute
    $t[2] = 0; # hour
    $t[3] = 1; # day
    require Time::Local;
    Time::Local::timelocal_nocheck(@t);
}

sub time_startofmonth_utc {
    my @t = gmtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    $t[1] = 0; # minute
    $t[2] = 0; # hour
    $t[3] = 1; # day
    require Time::Local;
    Time::Local::timegm_nocheck(@t);
}

sub localtime_startofmonth {
    my @t = localtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    $t[1] = 0; # minute
    $t[2] = 0; # hour
    $t[3] = 1; # day
    require Time::Local;
    localtime(Time::Local::timelocal_nocheck(@t));
}

sub gmtime_startofmonth {
    my @t = localtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    $t[1] = 0; # minute
    $t[2] = 0; # hour
    $t[3] = 1; # day
    require Time::Local;
    gmtime(Time::Local::timegm_nocheck(@t));
}

sub time_startoflastdayofmonth_local {
    my @t = localtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    $t[1] = 0; # minute
    $t[2] = 0; # hour
    $t[3] = 0; # day
    $t[4]++;   # month
    require Time::Local;
    Time::Local::timelocal_nocheck(@t);
}

sub time_startoflastdayofmonth_utc {
    my @t = gmtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    $t[1] = 0; # minute
    $t[2] = 0; # hour
    $t[3] = 0; # day
    $t[4]++;   # month
    require Time::Local;
    Time::Local::timegm_nocheck(@t);
}

sub localtime_startoflastdayofmonth {
    my @t = localtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    $t[1] = 0; # minute
    $t[2] = 0; # hour
    $t[3] = 0; # day
    $t[4]++;   # month
    require Time::Local;
    localtime(Time::Local::timelocal_nocheck(@t));
}

sub gmtime_startoflastdayofmonth {
    my @t = localtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    $t[1] = 0; # minute
    $t[2] = 0; # hour
    $t[3] = 0; # day
    $t[4]++;   # month
    require Time::Local;
    gmtime(Time::Local::timegm_nocheck(@t));
}

sub time_startoflastdayoflastmonth_local {
    my @t = localtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    $t[1] = 0; # minute
    $t[2] = 0; # hour
    $t[3] = 0; # day
    require Time::Local;
    Time::Local::timelocal_nocheck(@t);
}

sub time_startoflastdayoflastmonth_utc {
    my @t = gmtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    $t[1] = 0; # minute
    $t[2] = 0; # hour
    $t[3] = 0; # day
    require Time::Local;
    Time::Local::timegm_nocheck(@t);
}

sub localtime_startoflastdayoflastmonth {
    my @t = localtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    $t[1] = 0; # minute
    $t[2] = 0; # hour
    $t[3] = 0; # day
    require Time::Local;
    localtime(Time::Local::timelocal_nocheck(@t));
}

sub gmtime_startoflastdayoflastmonth {
    my @t = localtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    $t[1] = 0; # minute
    $t[2] = 0; # hour
    $t[3] = 0; # day
    require Time::Local;
    gmtime(Time::Local::timegm_nocheck(@t));
}

sub time_startofyear_local {
    my @t = localtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    $t[1] = 0; # minute
    $t[2] = 0; # hour
    $t[3] = 1; # day
    $t[4] = 0; # month
    require Time::Local;
    Time::Local::timelocal_nocheck(@t);
}

sub time_startofyear_utc {
    my @t = gmtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    $t[1] = 0; # minute
    $t[2] = 0; # hour
    $t[3] = 1; # day
    $t[4] = 0; # month
    require Time::Local;
    Time::Local::timegm_nocheck(@t);
}

sub localtime_startofyear {
    my @t = localtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    $t[1] = 0; # minute
    $t[2] = 0; # hour
    $t[3] = 1; # day
    $t[4] = 0; # month
    require Time::Local;
    localtime(Time::Local::timelocal_nocheck(@t));
}

sub gmtime_startofyear {
    my @t = localtime(defined $_[0] ? $_[0] : time());
    $t[0] = 0; # second
    $t[1] = 0; # minute
    $t[2] = 0; # hour
    $t[3] = 1; # day
    $t[4] = 0; # month
    require Time::Local;
    gmtime(Time::Local::timegm_nocheck(@t));
}

1;
# ABSTRACT: More functions for producing Unix epoch timestamp or localtime/gmtime tuple

__END__

=pod

=encoding UTF-8

=head1 NAME

Time::Local::More - More functions for producing Unix epoch timestamp or localtime/gmtime tuple

=head1 VERSION

This document describes version 0.002 of Time::Local::More (from Perl distribution Time-Local-More), released on 2021-06-17.

=head1 SYNOPSIS

 use Time::Local::More qw(
                       time_startofminute_local
                       time_startofminute_utc
                       localtime_startofminute
                       gmtime_startofminute

                       time_startofhour_local
                       time_startofhour_utc
                       localtime_startofhour
                       gmtime_startofhour

                       time_startofday_local
                       time_startofday_utc
                       localtime_startofday
                       gmtime_startofday

                       time_startofsaturday_local
                       time_startofsaturday_utc
                       localtime_startofsaturday
                       gmtime_startofsaturday

                       time_startofsunday_local
                       time_startofsunday_utc
                       localtime_startofsunday
                       gmtime_startofsunday

                       time_startofmonday_local
                       time_startofmonday_utc
                       localtime_startofmonday
                       gmtime_startofmonday

                       time_startofmonth_local
                       time_startofmonth_utc
                       localtime_startofmonth
                       gmtime_startofmonth

                       time_startoflastdayofmonth_local
                       time_startoflastdayofmonth_utc
                       localtime_startlastdayofofmonth
                       gmtime_startlastdayofofmonth

                       time_startoflastdayoflastmonth_local
                       time_startoflastdayoflastmonth_utc
                       localtime_startoflastdayoflastmonth
                       gmtime_startoflastdayoflastmonth

                       time_startofyear_local
                       time_startofyear_utc
                       localtime_startofyear
                       gmtime_startofyear
                    );
 # you can import all using :all tag

 my $epoch1 = 1623894635; # Thu Jun 17 08:50:35 2021 Asia/Jakarta
                          # Thu Jun 17 01:50:35 2021 UTC

 # assuming we are in Asia/Jakarta
 say time_startofday_local($epoch1); # => 1623862800
                                     # = Thu Jun 17 00:00:00 2021 Asia/Jakarta
 say time_startofday_utc($epoch1);   # => 1623888000
                                     # = Thu Jun 17 00:00:00 2021 UTC

=head1 DESCRIPTION

B<EARLY RELEASE: API MIGHT CHANGE.>

Overview of the module:

=over

=item * The C<*startof*> functions

These functions basically "round" the time to the start of minute, hour, day, or
so on. For example, L</time_startofday_local> is basically equivalent to:

 my @t = localtime(); # e.g. 1623894635 (Thu Jun 17 08:50:35 2021 Asia/Jakarta)
 $t[0] = 0; # zero the second
 $t[1] = 0; # zero the minute
 $t[2] = 0; # zero the hour
 Time::Local::timelocal_nocheck(@t); # convert back to epoch. result is 1623862800 (Thu Jun 17 00:00:00 2021 Asia/Jakarta)

or alternatively:

 my $t = time();
 my @t = localtime($t);
 $t - $t[0] - $t[1]*60 - $t[2]*3600;

=back

Keywords: start of period, time rounding, truncating timestamp.

=for Pod::Coverage .+

=head1 FUNCTIONS

=head2 time_startofminute_local

Usage:

 my $time = time_startofminute_local( [ $time0 ] );

Return Unix epoch timestamp for start of minute at local timezone. If C<$time0>
is not specified, will default to current timestamp (C<time()>).

=head2 time_startofminute_utc

Usage:

 my $time = time_startofminute_utc( [ $time0 ] );

Return Unix epoch timestamp for start of minute at UTC. If C<$time0>
is not specified, will default to current timestamp (C<time()>).

=head2 localtime_startofminute

Usage:

 localtime_startofminute( [ $time0 ] ); # like output of localtime()

Return localtime() output for start of minute. If C<$time0> is not specified,
will default to current timestamp (C<time()>).

=head2 gmtime_startofminute

Usage:

 gmtime_startofminute( [ $time0 ] ); # like output of gmtime()

Return gmtime() output for start of minute. If C<$time0> is not specified,
will default to current timestamp (C<time()>).

=head2 time_startofhour_local

Usage:

 my $time = time_startofhour_local( [ $time0 ] );

Return Unix epoch timestamp for start of hour at local timezone. If C<$time0>
is not specified, will default to current timestamp (C<time()>).

=head2 time_startofhour_utc

Usage:

 my $time = time_startofhour_utc( [ $time0 ] );

Return Unix epoch timestamp for start of hour at UTC. If C<$time0>
is not specified, will default to current timestamp (C<time()>).

=head2 localtime_startofhour

Usage:

 localtime_startofhour( [ $time0 ] ); # like output of localtime()

Return localtime() output for start of hour. If C<$time0> is not specified,
will default to current timestamp (C<time()>).

=head2 gmtime_startofhour

Usage:

 gmtime_startofhour( [ $time0 ] ); # like output of gmtime()

Return gmtime() output for start of hour. If C<$time0> is not specified,
will default to current timestamp (C<time()>).

=head2 time_startofday_local

Usage:

 my $time = time_startofday_local( [ $time0 ] );

Return Unix epoch timestamp for start of day at local timezone. If C<$time0>
is not specified, will default to current timestamp (C<time()>).

=head2 time_startofday_utc

Usage:

 my $time = time_startofday_utc( [ $time0 ] );

Return Unix epoch timestamp for start of day at UTC. If C<$time0>
is not specified, will default to current timestamp (C<time()>).

=head2 localtime_startofday

Usage:

 localtime_startofday( [ $time0 ] ); # like output of localtime()

Return localtime() output for start of day. If C<$time0> is not specified,
will default to current timestamp (C<time()>).

=head2 gmtime_startofday

Usage:

 gmtime_startofday( [ $time0 ] ); # like output of gmtime()

Return gmtime() output for start of day. If C<$time0> is not specified,
will default to current timestamp (C<time()>).

=head2 time_startofsaturday_local

Usage:

 my $time = time_startofsaturday_local( [ $time0 ] );

Return Unix epoch timestamp for start of most recent past Saturday at local
timezone. If C<$time0> is not specified, will default to current timestamp
(C<time()>).

=head2 time_startofsaturday_utc

Usage:

 my $time = time_startofsaturday_utc( [ $time0 ] );

Return Unix epoch timestamp for start of most recent past Saturday at UTC. If
C<$time0> is not specified, will default to current timestamp (C<time()>).

=head2 localtime_startofsaturday

Usage:

 localtime_startofsaturday( [ $time0 ] ); # like output of localtime()

Return localtime() output for start of most recent past Saturday. If C<$time0>
is not specified, will default to current timestamp (C<time()>).

=head2 gmtime_startofsaturday

Usage:

 gmtime_startofsaturday( [ $time0 ] ); # like output of gmtime()

Return gmtime() output for start of most recent past Saturday. If C<$time0> is
not specified, will default to current timestamp (C<time()>).

=head2 time_startofsunday_local

Usage:

 my $time = time_startofsunday_local( [ $time0 ] );

Return Unix epoch timestamp for start of most recent past Sunday at local
timezone. If C<$time0> is not specified, will default to current timestamp
(C<time()>).

=head2 time_startofsunday_utc

Usage:

 my $time = time_startofsunday_utc( [ $time0 ] );

Return Unix epoch timestamp for start of most recent past Sunday at UTC. If C<$time0>
is not specified, will default to current timestamp (C<time()>).

=head2 localtime_startofsunday

Usage:

 localtime_startofsunday( [ $time0 ] ); # like output of localtime()

Return localtime() output for start of sunday. If C<$time0> is not specified,
will default to current timestamp (C<time()>).

=head2 gmtime_startofsunday

Usage:

 gmtime_startofsunday( [ $time0 ] ); # like output of gmtime()

Return gmtime() output for start of most recent past Sunday. If C<$time0> is not
specified, will default to current timestamp (C<time()>).

=head2 time_startofmonday_local

Usage:

 my $time = time_startofmonday_local( [ $time0 ] );

Return Unix epoch timestamp for start of most recent past Monday at local timezone. If C<$time0>
is not specified, will default to current timestamp (C<time()>).

=head2 time_startofmonday_utc

Usage:

 my $time = time_startofmonday_utc( [ $time0 ] );

Return Unix epoch timestamp for start of most recent past Monday at UTC. If
C<$time0> is not specified, will default to current timestamp (C<time()>).

=head2 localtime_startofmonday

Usage:

 localtime_startofmonday( [ $time0 ] ); # like output of localtime()

Return localtime() output for start of most recent past Monday. If C<$time0> is
not specified, will default to current timestamp (C<time()>).

=head2 gmtime_startofmonday

Usage:

 gmtime_startofmonday( [ $time0 ] ); # like output of gmtime()

Return gmtime() output for start of most recent past Monday. If C<$time0> is not
specified, will default to current timestamp (C<time()>).

=head2 time_startofmonth_local

Usage:

 my $time = time_startofmonth_local( [ $time0 ] );

Return Unix epoch timestamp for start of month at local timezone. If C<$time0>
is not specified, will default to current timestamp (C<time()>).

=head2 time_startofmonth_utc

Usage:

 my $time = time_startofmonth_utc( [ $time0 ] );

Return Unix epoch timestamp for start of month at UTC. If C<$time0>
is not specified, will default to current timestamp (C<time()>).

=head2 localtime_startofmonth

Usage:

 localtime_startofmonth( [ $time0 ] ); # like output of localtime()

Return localtime() output for start of month. If C<$time0> is not specified,
will default to current timestamp (C<time()>).

=head2 gmtime_startofmonth

Usage:

 gmtime_startofmonth( [ $time0 ] ); # like output of gmtime()

Return gmtime() output for start of month. If C<$time0> is not specified,
will default to current timestamp (C<time()>).

=head2 time_startoflastdayofmonth_local

Usage:

 my $time = time_startoflastdayofmonth_local( [ $time0 ] );

Return Unix epoch timestamp for start of last day of month at local timezone. If C<$time0>
is not specified, will default to current timestamp (C<time()>).

=head2 time_startoflastdayofmonth_utc

Usage:

 my $time = time_startoflastdayofmonth_utc( [ $time0 ] );

Return Unix epoch timestamp for start of last day of month at UTC. If C<$time0>
is not specified, will default to current timestamp (C<time()>).

=head2 localtime_startoflastdayofmonth

Usage:

 localtime_startoflastdayofmonth( [ $time0 ] ); # like output of localtime()

Return localtime() output for start of last day of month. If C<$time0> is not specified,
will default to current timestamp (C<time()>).

=head2 gmtime_startoflastdayofmonth

Usage:

 gmtime_startoflastdayofmonth( [ $time0 ] ); # like output of gmtime()

Return gmtime() output for start of last day of month. If C<$time0> is not specified,
will default to current timestamp (C<time()>).

=head2 time_startoflastdayoflastmonth_local

Usage:

 my $time = time_startoflastdayoflastmonth_local( [ $time0 ] );

Return Unix epoch timestamp for start of last day of last month at local
timezone. If C<$time0> is not specified, will default to current timestamp
(C<time()>).

=head2 time_startoflastdayoflastmonth_utc

Usage:

 my $time = time_startoflastdayoflastmonth_utc( [ $time0 ] );

Return Unix epoch timestamp for start of last day of last month at UTC. If
C<$time0> is not specified, will default to current timestamp (C<time()>).

=head2 localtime_startoflastdayoflastmonth

Usage:

 localtime_startoflastdayoflastmonth( [ $time0 ] ); # like output of localtime()

Return localtime() output for start of last day of last month. If C<$time0> is
not specified, will default to current timestamp (C<time()>).

=head2 gmtime_startoflastdayoflastmonth

Usage:

 gmtime_startoflastdayoflastmonth( [ $time0 ] ); # like output of gmtime()

Return gmtime() output for start of last day of last month. If C<$time0> is not
specified, will default to current timestamp (C<time()>).

=head2 time_startofyear_local

Usage:

 my $time = time_startofyear_local( [ $time0 ] );

Return Unix epoch timestamp for start of year at local timezone. If C<$time0>
is not specified, will default to current timestamp (C<time()>).

=head2 time_startofyear_utc

Usage:

 my $time = time_startofyear_utc( [ $time0 ] );

Return Unix epoch timestamp for start of year at UTC. If C<$time0>
is not specified, will default to current timestamp (C<time()>).

=head2 localtime_startofyear

Usage:

 localtime_startofyear( [ $time0 ] ); # like output of localtime()

Return localtime() output for start of year. If C<$time0> is not specified,
will default to current timestamp (C<time()>).

=head2 gmtime_startofyear

Usage:

 gmtime_startofyear( [ $time0 ] ); # like output of gmtime()

Return gmtime() output for start of year. If C<$time0> is not specified,
will default to current timestamp (C<time()>).

=head1 FAQ

=head2 Where are "startofweek" functions?

Use the "startofsunday" or "startofmonday" functions; since some people use
Sunday as start of the week and some people use Monday.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Time-Local-More>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Time-Local-More>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Time-Local-More>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Time::Local>

C<localtime()> and C<gmtime()> in L<perlfunc>.

You can also use L<DateTime> to calculate these "start of period" epochs. For
example, to get start of month epoch: C<< DateTime->now->set(day => 1)->epoch
>>. Note that L<DateTime> has a significantly larger footprint than
L<Time::Local>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
