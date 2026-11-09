package Validator::LIVR::Rules::DateTime;

use strict;
use warnings;

our $VERSION = '2.22';

# LIVR 2.5: dates with bounds, datetimes and times. Grammars use ASCII digits only and match the
# whole value: \z, not $, which also matches before a trailing newline

my $DATE_RE = qr/\A([0-9]{4})-([0-9]{2})-([0-9]{2})\z/;

# YYYY-MM-DD "T" HH ":" MM [ ":" SS [ "." 1*9DIGIT ] ] ( "Z" / ( "+" / "-" ) HH ":" MM )
my $DATETIME_RE = qr/\A
    ([0-9]{4})-([0-9]{2})-([0-9]{2})
    T([0-9]{2}):([0-9]{2})
    (?: :([0-9]{2}) (?: \.([0-9]{1,9}) )? )?
    (?: Z | ([+-])([0-9]{2}):([0-9]{2}) )
\z/x;

# HH:MM, HH:MM:SS or HH:MM:SS.fraction
my $TIME_RE = qr/\A([0-9]{2}):([0-9]{2})(?::([0-9]{2})(?:\.([0-9]{1,9}))?)?\z/;

my %RELATIVE_DAYS = ( yesterday => -1, today => 0, tomorrow => 1 );

my @DAYS_IN_MONTH = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );

my $DAY_MS = 86_400_000;

sub _days_in_month {
    my ( $year, $month ) = @_;
    return $DAYS_IN_MONTH[ $month - 1 ] if $month != 2;
    return ( $year % 4 == 0 && $year % 100 != 0 ) || $year % 400 == 0 ? 29 : 28;
}

sub _is_date {
    my ( $year, $month, $day ) = @_;
    return $month >= 1 && $month <= 12 && $day >= 1 && $day <= _days_in_month( $year, $month );
}

# iso_date with { min, max }. Validator::LIVR::Rules::Special::iso_date calls it for an object
# argument: the LIVR 2.0 forms are there
sub iso_date {
    my ( $options, $rule_builders ) = ( $_[0], $_[-1] );

    # Arguments after the options are ignored
    _check_options( 'iso_date', $options );
    my $min = _date_bound( $options, 'min' );
    my $max = _date_bound( $options, 'max' );

    return Validator::LIVR::Rules::Special::iso_date($rule_builders) if !defined($min) && !defined($max);
    _check_order( 'iso_date', $min, $max );

    # A bound is a date, or the number of days from the current date: dates YYYY-MM-DD are
    # compared as strings
    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';

        if ( ref($value) ) {
            return ref($value) =~ /Boolean/ ? 'WRONG_DATE' : 'FORMAT_ERROR';
        }

        return 'WRONG_DATE' unless $value =~ $DATE_RE && _is_date( $1, $2, $3 );

        my $min_date = ref($min) ? _relative_date($$min) : $min;
        return 'DATE_TOO_EARLY' if defined($min_date) && $value lt $min_date;

        my $max_date = ref($max) ? _relative_date($$max) : $max;
        return 'DATE_TOO_LATE' if defined($max_date) && $value gt $max_date;

        return;
    };
}

# A date, or a reference to the days from the current date, undef without the bound
sub _date_bound {
    my ( $options, $name ) = @_;
    return undef if !exists $options->{$name};

    my $bound = $options->{$name};
    if ( defined($bound) && !ref($bound) ) {
        return \$RELATIVE_DAYS{$bound} if exists $RELATIVE_DAYS{$bound};
        return $bound if $bound =~ $DATE_RE && _is_date( $1, $2, $3 );
    }

    my $hint = defined($bound) && $bound eq 'current' ? ', use "today" instead of "current"' : '';
    die qq{Rule [iso_date] takes a date YYYY-MM-DD, "today", "yesterday" or "tomorrow" as "$name"$hint\n};
}

sub iso_datetime {
    my ( $min, $max ) = _instant_bounds(@_);

    return sub {
        my ( $value, undef, $output_ref ) = @_;
        return if !defined($value) || $value eq '';

        if ( ref($value) ) {
            return ref($value) =~ /Boolean/ ? 'WRONG_DATETIME' : 'FORMAT_ERROR';
        }

        my @utc = _parse_datetime($value);
        return 'WRONG_DATETIME' if !@utc || $utc[0] < 0 || $utc[0] > 9999;

        if ( defined($min) || defined($max) ) {
            my $key = _instant_key(@utc);

            my $min_key = ref($min) ? _relative_day_key($$min) : $min;
            return 'DATETIME_TOO_EARLY' if defined($min_key) && $key < $min_key;

            my $max_key = ref($max) ? _relative_day_key($$max) + $DAY_MS - 1 : $max;
            return 'DATETIME_TOO_LATE' if defined($max_key) && $key > $max_key;
        }

        # The instant in UTC with three fraction digits. 24 characters with "Z" is this form
        if ( length($value) != 24 || substr( $value, 23 ) ne 'Z' ) {
            $$output_ref = sprintf '%04d-%02d-%02dT%02d:%02d:%02d.%03dZ',
                $utc[0], $utc[1], $utc[2], int( $utc[3] / 60 ), $utc[3] % 60, $utc[4], $utc[5];
        }

        return;
    };
}

# The bounds of iso_datetime as keys of instants, or as references to the days from the
# current date. A date is the start of its UTC day as "min", the end of it as "max"
sub _instant_bounds {
    my @args = @_;
    pop @args; # rule_builders
    return () if !@args;

    # Arguments after the options are ignored
    _check_options( 'iso_datetime', $args[0] );

    my @bounds;
    foreach my $name (qw/min max/) {
        if ( !exists $args[0]{$name} ) {
            push @bounds, undef;
            next;
        }

        my $bound = $args[0]{$name};
        my $key;

        if ( defined($bound) && !ref($bound) ) {
            if ( exists $RELATIVE_DAYS{$bound} ) {
                $key = \$RELATIVE_DAYS{$bound};
            } elsif ( $bound =~ $DATE_RE ) {
                $key = _instant_key( $1, $2, $3, 0, 0, 0 ) + ( $name eq 'max' ? $DAY_MS - 1 : 0 )
                    if _is_date( $1, $2, $3 );
            } elsif ( my @utc = _parse_datetime($bound) ) {
                # Of any year: a bound is only compared
                $key = _instant_key(@utc);
            }
        }

        if ( !defined $key ) {
            my $hint = defined($bound) && $bound eq 'current' ? ', use "today" instead of "current"' : '';
            die qq{Rule [iso_datetime] takes a datetime with an offset, a date YYYY-MM-DD, "today", "yesterday" or "tomorrow" as "$name"$hint\n};
        }

        push @bounds, $key;
    }

    _check_order( 'iso_datetime', @bounds );
    return @bounds;
}

# "min" later than "max" dies when both bounds are fixed or both are relative: no value could pass.
# A fixed and a relative bound depend on the current date. Fixed bounds are dates YYYY-MM-DD or
# keys of instants, relative bounds are references to the days from the current date
sub _check_order {
    my ( $rule_name, $min, $max ) = @_;
    return if !defined($min) || !defined($max) || ref($min) ne ref($max);

    my $is_later = ref($min) ? $$min > $$max : $rule_name eq 'iso_date' ? $min gt $max : $min > $max;
    die qq{Rule [$rule_name] got "min" later than "max"\n} if $is_later;
}

# A datetime with an offset as (year, month, day, minutes of the day, seconds, milliseconds)
# in UTC, cut to milliseconds. An empty list for any other string. The year may be -1 or 10000
sub _parse_datetime {
    return () unless $_[0] =~ $DATETIME_RE;

    my ( $year, $month, $day, $hours, $minutes ) = ( $1, $2, $3, $4, $5 );
    my $seconds = $6 // 0;
    my $ms = defined $7 ? substr( $7 . '00', 0, 3 ) : 0;
    my $offset = defined $8 ? ( $9 * 60 + $10 ) * ( $8 eq '-' ? -1 : 1 ) : 0;

    return () if !_is_date( $year, $month, $day ) || $hours > 23 || $minutes > 59 || $seconds > 59;
    return () if defined($8) && ( $9 > 23 || $10 > 59 );

    # An offset moves the time by less than a day
    my $minutes_of_day = $hours * 60 + $minutes - $offset;
    if ( $minutes_of_day < 0 ) {
        $minutes_of_day += 1440;
        if ( --$day == 0 ) {
            if ( --$month == 0 ) {
                $month = 12;
                $year--;
            }
            $day = _days_in_month( $year, $month );
        }
    } elsif ( $minutes_of_day >= 1440 ) {
        $minutes_of_day -= 1440;
        if ( ++$day > _days_in_month( $year, $month ) ) {
            $day = 1;
            if ( ++$month == 13 ) {
                $month = 1;
                $year++;
            }
        }
    }

    return ( $year + 0, $month + 0, $day + 0, $minutes_of_day, $seconds + 0, $ms + 0 );
}

# A number in the order of instants: no calendar arithmetic, exact for all years of the grammar
sub _instant_key {
    my ( $year, $month, $day, $minutes_of_day, $seconds, $ms ) = @_;
    return ( $year * 512 + $month * 32 + $day ) * $DAY_MS + ( $minutes_of_day * 60 + $seconds ) * 1000 + $ms;
}

sub iso_time {
    my @args = @_;
    pop @args; # rule_builders

    my ( $min, $max );
    if (@args) {
        # Arguments after the options are ignored
        _check_options( 'iso_time', $args[0] );

        foreach my $name (qw/min max/) {
            next if !exists $args[0]{$name};

            my $time = _time_of_day( $args[0]{$name} );
            die qq{Rule [iso_time] takes a time HH:MM, HH:MM:SS or HH:MM:SS.fraction as "$name"\n} if !defined $time;

            if   ( $name eq 'min' ) { $min = $time }
            else                    { $max = $time }
        }
    }

    # Over midnight, { min => '22:00', max => '06:00' }: a time in the gap gets the error of the
    # nearer bound, TIME_TOO_EARLY exactly in the middle
    my $is_over_midnight = defined($min) && defined($max) && $min > $max;

    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';

        if ( ref($value) ) {
            return ref($value) =~ /Boolean/ ? 'WRONG_TIME' : 'FORMAT_ERROR';
        }

        my $time = _time_of_day($value);
        return 'WRONG_TIME' if !defined $time;

        if ($is_over_midnight) {
            return if $time >= $min || $time <= $max;
            return $time - $max < $min - $time ? 'TIME_TOO_LATE' : 'TIME_TOO_EARLY';
        }

        return 'TIME_TOO_EARLY' if defined($min) && $time < $min;
        return 'TIME_TOO_LATE'  if defined($max) && $time > $max;
        return;
    };
}

# Nanoseconds since midnight, exact (below 2^53), or undef for a wrong time
sub _time_of_day {
    my $time = shift;
    return undef if !defined($time) || ref($time) || $time !~ $TIME_RE;
    return undef if $1 > 23 || $2 > 59 || ( defined($3) && $3 > 59 );

    my $fraction = defined $4 ? $4 . '0' x ( 9 - length($4) ) : 0;
    return ( ( $1 * 60 + $2 ) * 60 + ( $3 // 0 ) ) * 1_000_000_000 + $fraction;
}

sub _check_options {
    my ( $rule_name, $options ) = @_;

    die qq{Rule [$rule_name] takes no arguments or an object with "min" and "max"\n} if ref($options) ne 'HASH';

    foreach my $name ( sort keys %$options ) {
        next if $name eq 'min' || $name eq 'max';

        my $hint = $name eq 'format' && $rule_name eq 'iso_date' ? ', use "iso_datetime" for datetimes' : '';
        die qq{Rule [$rule_name] got an unknown option "$name"$hint\n};
    }
}

# The current date: days since 1970-01-01 in UTC. Tests fix the time with Test::MockTime, which
# replaces CORE::GLOBAL::time: it has to be loaded before this module
sub _current_day {
    my $seconds = time;

    my $day = int( $seconds / 86400 );
    $day-- if $day * 86400 > $seconds;
    return $day;
}

# The dates and keys of yesterday, today and tomorrow for the day in $cached_day: they change
# once a day
my $cached_day = 'none';
my ( %cached_dates, %cached_keys );

sub _cache_day {
    my $today = shift;

    foreach my $days ( -1, 0, 1 ) {
        my ( undef, undef, undef, $day, $month, $year ) = gmtime( ( $today + $days ) * 86400 );
        $cached_dates{$days} = sprintf '%04d-%02d-%02d', $year + 1900, $month + 1, $day;
        $cached_keys{$days}  = _instant_key( $year + 1900, $month + 1, $day, 0, 0, 0 );
    }

    $cached_day = $today;
}

# YYYY-MM-DD of the current date plus $days
sub _relative_date {
    my $days = shift;
    my $today = _current_day();
    _cache_day($today) if $today ne $cached_day;
    return $cached_dates{$days};
}

# The key of the start of the current date plus $days
sub _relative_day_key {
    my $days = shift;
    my $today = _current_day();
    _cache_day($today) if $today ne $cached_day;
    return $cached_keys{$days};
}

1;

=head1 NAME

Validator::LIVR::Rules::DateTime - LIVR 2.5 rules of Validator::LIVR for dates and times: iso_date with bounds, iso_datetime and iso_time

=head1 DESCRIPTION

This module has the code of these rules, which are documented in
L<Validator::LIVR/LIVR 2.5 rules>. Validator::LIVR loads it when a validator
uses one of the rules. C<iso_date> without bounds is in
L<Validator::LIVR::Rules::Special>.

Each sub is the builder of the rule with the same name.

=cut
