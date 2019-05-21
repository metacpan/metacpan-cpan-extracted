package Time::Zone::Olson;

use strict;
use warnings;

use FileHandle();
use File::Spec();
use Config;
use Carp();
use English qw( -no_match_vars );
use DirHandle();
use POSIX();

our $VERSION = '0.13';

sub _SIZE_OF_TZ_HEADER                     { return 44 }
sub _SIZE_OF_TRANSITION_TIME_V1            { return 4 }
sub _SIZE_OF_TRANSITION_TIME_V2            { return 8 }
sub _SIZE_OF_TTINFO                        { return 6 }
sub _SIZE_OF_LEAP_SECOND_V1                { return 4 }
sub _SIZE_OF_LEAP_SECOND_V2                { return 8 }
sub _PAIR                                  { return 2 }
sub _STAT_MTIME_IDX                        { return 9 }
sub _MAX_LENGTH_FOR_TRAILING_TZ_DEFINITION { return 256 }
sub _MONTHS_IN_ONE_YEAR                    { return 12 }
sub _HOURS_IN_ONE_DAY                      { return 24 }
sub _MINUTES_IN_ONE_HOUR                   { return 60 }
sub _SECONDS_IN_ONE_MINUTE                 { return 60 }
sub _SECONDS_IN_ONE_HOUR                   { return 3_600 }
sub _SECONDS_IN_ONE_DAY                    { return 86_400 }
sub _NEGATIVE_ONE                          { return -1 }
sub _LOCALTIME_ISDST_INDEX                 { return 8 }
sub _LOCALTIME_DAY_OF_WEEK_INDEX           { return 6 }
sub _LOCALTIME_YEAR_INDEX                  { return 5 }
sub _LOCALTIME_MONTH_INDEX                 { return 4 }
sub _LOCALTIME_DAY_INDEX                   { return 3 }
sub _LOCALTIME_HOUR_INDEX                  { return 2 }
sub _LOCALTIME_MINUTE_INDEX                { return 1 }
sub _LOCALTIME_SECOND_INDEX                { return 0 }
sub _LOCALTIME_BASE_YEAR                   { return 1900 }
sub _EPOCH_YEAR                            { return 1970 }
sub _EPOCH_WDAY                            { return 4 }
sub _DAYS_IN_JANUARY                       { return 31 }
sub _DAYS_IN_FEBRUARY_LEAP_YEAR            { return 29 }
sub _DAYS_IN_FEBRUARY_NON_LEAP             { return 28 }
sub _DAYS_IN_MARCH                         { return 31 }
sub _DAYS_IN_APRIL                         { return 30 }
sub _DAYS_IN_MAY                           { return 31 }
sub _DAYS_IN_JUNE                          { return 30 }
sub _DAYS_IN_JULY                          { return 31 }
sub _DAYS_IN_AUGUST                        { return 31 }
sub _DAYS_IN_SEPTEMBER                     { return 30 }
sub _DAYS_IN_OCTOBER                       { return 31 }
sub _DAYS_IN_NOVEMBER                      { return 30 }
sub _DAYS_IN_DECEMBER                      { return 31 }
sub _DAYS_IN_A_LEAP_YEAR                   { return 366 }
sub _DAYS_IN_A_NON_LEAP_YEAR               { return 365 }
sub _LAST_WEEK_VALUE                       { return 5 }
sub _LOCALTIME_WEEKDAY_HIGHEST_VALUE       { return 6 }
sub _DAYS_IN_ONE_WEEK                      { return 7 }
sub _EVERY_FOUR_HUNDRED_YEARS              { return 400 }
sub _EVERY_FOUR_YEARS                      { return 4 }
sub _EVERY_ONE_HUNDRED_YEARS               { return 100 }
sub _DEFAULT_DST_START_HOUR                { return 2 }
sub _DEFAULT_DST_END_HOUR                  { return 2 }

sub _TZ_DEFINITION_KEYS {
    return
      qw(std_name std_sign std_hours std_minutes std_seconds dst_name dst_sign dst_hours dst_minutes dst_seconds start_julian_without_feb29 end_julian_withou_feb29 start_julian_with_feb29 end_julian_with_feb29 start_month end_month start_week end_week start_day end_day start_hour end_hour start_minute end_minute start_second end_second);
}

sub _TIMEZONE_FULL_NAME_REGEX {
    return qr/(?<area>\w+)(?:\/(?<location>[\w\-\/+]+))?/smx;
}

my $_default_zoneinfo_directory = '/usr/share/zoneinfo';
if ( -e $_default_zoneinfo_directory ) {
}
else {
    if ( -e '/usr/lib/zoneinfo' ) {
        $_default_zoneinfo_directory = '/usr/lib/zoneinfo';
    }
}
my $_zonetab_cache = {};
my $_tzdata_cache  = {};

sub _DEFAULT_ZONEINFO_DIRECTORY { return $_default_zoneinfo_directory }

sub new {
    my ( $class, %params ) = @_;
    my $self = {};
    bless $self, $class;
    if (   ( $OSNAME eq 'MSWin32' )
        && ( !$params{directory} )
        && ( !$ENV{TZDIR} ) )
    {
        require Time::Zone::Olson::Win32;
        bless $self, 'Time::Zone::Olson::Win32';
    }
    else {
        $self->directory( $params{directory}
              || $ENV{TZDIR}
              || _DEFAULT_ZONEINFO_DIRECTORY() );
    }
    if ( defined $params{offset} ) {
        $self->offset( $params{offset} );
    }
    else {
        $self->timezone( $params{timezone} || $ENV{TZ} );
    }
    return $self;
}

sub directory {
    my ( $self, $new ) = @_;
    my $old = $self->{directory};
    if ( defined $new ) {
        $self->{directory} = $new;
    }
    return $old;
}

sub offset {
    my ( $self, $new ) = @_;
    my $old = $self->{offset};
    if ( defined $new ) {
        $self->{offset} = $new;
        delete $self->{tz};
    }
    return $old;
}

sub equiv {
    my ( $self, $compare_time_zone, $from_time ) = @_;
    $from_time = defined $from_time ? $from_time : time;
    my $class = ref $self;
    my $compare = $class->new( 'timezone' => $compare_time_zone );
    my %offsets_compare;
    foreach my $transition_time ( $compare->transition_times() ) {
        if ( $transition_time >= $from_time ) {
            $offsets_compare{$transition_time} =
              $compare->local_offset($transition_time);
        }
    }
    my %offsets_self;
    foreach my $transition_time ( $self->transition_times() ) {
        if ( $transition_time >= $from_time ) {
            $offsets_self{$transition_time} =
              $self->local_offset($transition_time);
        }
    }
    if ( scalar keys %offsets_compare == scalar keys %offsets_self ) {
        foreach my $transition_time ( sort { $a <=> $b } keys %offsets_compare )
        {
            if (
                ( defined $offsets_self{$transition_time} )
                && ( $offsets_self{$transition_time} ==
                    $offsets_compare{$transition_time} )
              )
            {
            }
            else {
                return;
            }
        }
        if ( $self->_tz_definition_equiv($compare) ) {
            return 1;
        }
    }
    return;
}

sub _tz_definition_equiv {
    my ( $self, $compare ) = @_;
    my $current_time_zone = $self->timezone();
    my $compare_time_zone = $compare->timezone();
    if ( ( defined $self->{_tzdata}->{$current_time_zone}->{tz_definition} )
        && (
            defined $compare->{_tzdata}->{$compare_time_zone}->{tz_definition} )
      )
    {
        my $current_tz_definition =
          $self->{_tzdata}->{$current_time_zone}->{tz_definition};
        my $compare_tz_definition =
          $compare->{_tzdata}->{$compare_time_zone}->{tz_definition};
        foreach my $key ( _TZ_DEFINITION_KEYS() ) {
            next if ( $key eq 'std_name' );
            next if ( $key eq 'dst_name' );
            if (    ( defined $current_tz_definition->{$key} )
                and ( defined $compare_tz_definition->{$key} ) )
            {
                if ( ( $key eq 'std_sign' ) or ( $key eq 'dst_sign' ) ) {
                    if ( $current_tz_definition->{$key} ne
                        $compare_tz_definition->{$key} )
                    {
                        return;
                    }
                }
                else {
                    if ( $current_tz_definition->{$key} !=
                        $compare_tz_definition->{$key} )
                    {
                        return;
                    }
                }
            }
            elsif ( defined $current_tz_definition->{$key} ) {
                return;
            }
            elsif ( defined $compare_tz_definition->{$key} ) {
                return;
            }
        }
    }
    elsif ( defined $self->{_tzdata}->{$current_time_zone}->{tz_definition} ) {
        return;
    }
    elsif ( defined $compare->{_tzdata}->{$compare_time_zone}->{tz_definition} )
    {
        return;
    }
    return 1;
}

sub _timezones {
    my ($self) = @_;
    my $path = File::Spec->catfile( $self->directory(), 'zone.tab' );
    my $handle = FileHandle->new($path)
      or Carp::croak("Failed to open $path for reading:$EXTENDED_OS_ERROR");
    my @stat = stat $handle
      or Carp::croak("Failed to stat $path:$EXTENDED_OS_ERROR");
    my $last_modified = $stat[ _STAT_MTIME_IDX() ];
    if (   ( $self->{_zonetab_last_modified} )
        && ( $self->{_zonetab_last_modified} == $last_modified ) )
    {
    }
    elsif (( $_zonetab_cache->{_zonetab_last_modified} )
        && ( $_zonetab_cache->{_zonetab_last_modified} == $last_modified ) )
    {

        foreach my $key (qw(_zonetab_last_modified _comments _zones)) {
            $self->{$key} = $_zonetab_cache->{$key};
        }
    }
    else {
        $self->{_zones}    = [];
        $self->{_comments} = {};
        while ( my $line = <$handle> ) {
            next if ( $line =~ /^[#]/smx );
            chomp $line;
            my ( $country_code, $coordinates, $timezone, $comment ) =
              split /\t/smx, $line;
            push @{ $self->{_zones} }, $timezone;
            $self->{_comments}->{$timezone} = $comment;
        }
        close $handle
          or Carp::croak("Failed to close $path:$EXTENDED_OS_ERROR");
        $self->{_zonetab_last_modified} = $last_modified;
        foreach my $key (qw(_zonetab_last_modified _comments _zones)) {
            $_zonetab_cache->{$key} = $self->{$key};
        }
    }
    my @sorted_zones = sort { $a cmp $b } @{ $self->{_zones} };
    return @sorted_zones;
}

sub areas {
    my ($self) = @_;
    my %areas;
    foreach my $timezone ( $self->_timezones() ) {
        my $timezone_full_name_regex = _TIMEZONE_FULL_NAME_REGEX();
        if ( $timezone =~ /^$timezone_full_name_regex$/smx ) {
            $areas{ $LAST_PAREN_MATCH{area} } = 1;
        }
        else {
            Carp::croak(
                "'$timezone' does not have a valid format for a TZ timezone");
        }
    }
    my @sorted_areas = sort { $a cmp $b } keys %areas;
    return @sorted_areas;
}

sub locations {
    my ( $self, $area ) = @_;
    if ( !length $area ) {
        return ();
    }
    my %locations;
    foreach my $timezone ( $self->_timezones() ) {
        my $timezone_full_name_regex = _TIMEZONE_FULL_NAME_REGEX();
        if ( $timezone =~ /^$timezone_full_name_regex$/smx ) {
            if (   ( $area eq $LAST_PAREN_MATCH{area} )
                && ( $LAST_PAREN_MATCH{location} ) )
            {
                $locations{ $LAST_PAREN_MATCH{location} } = 1;
            }
        }
        else {
            Carp::croak(
                "'$timezone' does not have a valid format for a TZ timezone");
        }
    }
    my @sorted_locations = sort { $a cmp $b } keys %locations;
    return @sorted_locations;
}

sub comment {
    my ( $self, $tz ) = @_;
    $tz ||= $self->timezone();
    $self->_timezones();
    if ( defined $self->{_comments}->{$tz} ) {
        return $self->{_comments}->{$tz};
    }
    else {
        return;
    }
}

sub area {
    my ($self) = @_;
    return $self->{area};
}

sub location {
    my ($self) = @_;
    return $self->{location};
}

sub timezone {
    my ( $self, $new ) = @_;
    my $old = $self->{tz};
    if ( defined $new ) {
        if ( defined $new ) {
            my $timezone_full_name_regex = _TIMEZONE_FULL_NAME_REGEX();
            if ( $new =~ /^$timezone_full_name_regex$/smx ) {
                $self->{area}     = $LAST_PAREN_MATCH{area};
                $self->{location} = $LAST_PAREN_MATCH{location};
                if (   ( $OSNAME eq 'MSWin32' )
                    && ( !defined $self->directory() ) )
                {
                    my %mapping = Time::Zone::Olson::Win32->mapping();
                    if ( !defined $mapping{$new} ) {
                        Carp::croak(
"'$new' is not an timezone in the existing Win32 registry"
                        );
                    }
                }
                else {
                    my $path = File::Spec->catfile( $self->directory(), $new );
                    if ( !-f $path ) {
                        Carp::croak(
"'$new' is not an timezone in the existing Olson database"
                        );
                    }
                }
            }
            elsif ( my $tz_definition =
                $self->_parse_tz_variable( $new, 'TZ' ) )
            {
                $self->{_tzdata}->{$new} = {
                    tz_definition    => $tz_definition,
                    transition_times => [],
                    no_tz_file       => 1,
                };
            }
            else {
                Carp::croak(
                    "'$new' does not have a valid format for a TZ timezone");
            }
        }
        $self->{tz} = $new;
        delete $self->{offset};
    }
    return $old;
}

sub _is_leap_year {
    my ( $self, $year ) = @_;
    my $leap_year;
    if (
        ( $year % _EVERY_FOUR_HUNDRED_YEARS() == 0 )
        || (   ( $year % _EVERY_FOUR_YEARS() == 0 )
            && ( $year % _EVERY_ONE_HUNDRED_YEARS() != 0 ) )
      )
    {
        $leap_year = 1;
    }
    else {
        $leap_year = 0;
    }
    return $leap_year;
}

sub _in_dst_according_to_v2_tz_rule {
    my ( $self, $check_time, $tz_definition ) = @_;

    if (   ( defined $tz_definition->{start_day} )
        && ( defined $tz_definition->{end_day} )
        && ( defined $tz_definition->{start_week} )
        && ( defined $tz_definition->{end_week} )
        && ( defined $tz_definition->{start_month} )
        && ( defined $tz_definition->{end_month} ) )
    {
        my $check_year =
          ( $self->_gm_time($check_time) )[ _LOCALTIME_YEAR_INDEX() ] +
          _LOCALTIME_BASE_YEAR();
        my $dst_start_time = $self->_get_time_for_wday_week_month_year(
            $tz_definition->{start_day},   $tz_definition->{start_week},
            $tz_definition->{start_month}, $check_year
          ) +
          ( $tz_definition->{start_hour} *
              _SECONDS_IN_ONE_MINUTE() *
              _MINUTES_IN_ONE_HOUR() ) +
          ( $tz_definition->{start_minute} * _SECONDS_IN_ONE_MINUTE() ) +
          $tz_definition->{start_second} -
          $tz_definition->{std_offset_in_seconds};
        my $dst_end_time = $self->_get_time_for_wday_week_month_year(
            $tz_definition->{end_day},   $tz_definition->{end_week},
            $tz_definition->{end_month}, $check_year
          ) +
          ( $tz_definition->{end_hour} *
              _SECONDS_IN_ONE_MINUTE() *
              _MINUTES_IN_ONE_HOUR() ) +
          ( $tz_definition->{end_minute} * _SECONDS_IN_ONE_MINUTE() ) +
          $tz_definition->{end_second} -
          $tz_definition->{dst_offset_in_seconds};

        if ( $dst_start_time < $dst_end_time ) {
            if (   ( $dst_start_time < $check_time )
                && ( $check_time < $dst_end_time ) )
            {
                return 1;
            }
        }
        else {
            if (   ( $check_time >= $dst_start_time )
                || ( $dst_end_time >= $check_time ) )
            {
                return 1;
            }
        }
    }

    return 0;
}

sub _get_time_for_wday_week_month_year {
    my ( $self, $wday, $week, $month, $year ) = @_;

    my $check_year = _EPOCH_YEAR();
    my $time       = 0;
    my $increment  = 0;
    my $leap_year  = 1;
    while ( $check_year < $year ) {
        $check_year += 1;
        if ( $self->_is_leap_year($check_year) ) {
            $leap_year = 1;
            $increment = _DAYS_IN_A_LEAP_YEAR() * _SECONDS_IN_ONE_DAY();
        }
        else {
            $leap_year = 0;
            $increment = _DAYS_IN_A_NON_LEAP_YEAR() * _SECONDS_IN_ONE_DAY();
        }
        $time += $increment;
    }

    $increment = 0;
    my $check_month   = 1;
    my @days_in_month = $self->_days_in_month($leap_year);
    while ( $check_month < $month ) {

        $increment = $days_in_month[ $check_month - 1 ] * _SECONDS_IN_ONE_DAY();
        $time += $increment;
        $check_month += 1;
    }

    if ( $week == _LAST_WEEK_VALUE() ) {
        $time +=
          ( $days_in_month[ $check_month - 1 ] - 1 ) * _SECONDS_IN_ONE_DAY();
        my $check_day_of_week =
          ( $self->_gm_time($time) )[ _LOCALTIME_DAY_OF_WEEK_INDEX() ];

        while ( $check_day_of_week != $wday ) {

            $time -= _SECONDS_IN_ONE_DAY;
            $check_day_of_week -= 1;
            if ( $check_day_of_week < 0 ) {
                $check_day_of_week = _LOCALTIME_WEEKDAY_HIGHEST_VALUE();
            }
        }
    }
    else {
        my $check_day_of_week =
          ( $self->_gm_time($time) )[ _LOCALTIME_DAY_OF_WEEK_INDEX() ];
        my $check_week = 1;
        $increment = _DAYS_IN_ONE_WEEK() * _SECONDS_IN_ONE_DAY();
        while ( $check_week < $week ) {
            $check_week += 1;
            $time += $increment;
        }

        while ( $check_day_of_week != $wday ) {

            $time += _SECONDS_IN_ONE_DAY();
            $check_day_of_week += 1;
            $check_day_of_week = $check_day_of_week % _DAYS_IN_ONE_WEEK();
        }
    }

    return $time;
}

sub _get_tz_offset_according_to_v2_tz_rule {
    my ( $self, $time ) = @_;
    if ( defined $self->offset() ) {
        return ( 0, $self->offset() * _SECONDS_IN_ONE_MINUTE(), q[] );
    }
    my $tz = $self->timezone();
    my ( $isdst, $gmtoff, $abbr );
    my $tz_definition = $self->{_tzdata}->{$tz}->{tz_definition};
    if ( defined $tz_definition->{std_name} ) {
        if ( defined $tz_definition->{dst_name} ) {
            if ( $self->_in_dst_according_to_v2_tz_rule( $time, $tz_definition )
              )
            {
                $isdst  = 1;
                $gmtoff = $tz_definition->{dst_offset_in_seconds};
                $abbr   = $tz_definition->{dst_name};
            }
            else {
                $isdst  = 0;
                $gmtoff = $tz_definition->{std_offset_in_seconds};
                $abbr   = $tz_definition->{std_name};
            }
        }
        else {
            $isdst  = 0;
            $gmtoff = $tz_definition->{std_offset_in_seconds};
            $abbr   = $tz_definition->{std_name};
        }
    }
    return ( $isdst, $gmtoff, $abbr );
}

sub _negative_gm_time {
    my ( $self, $time ) = @_;
    my $year           = _EPOCH_YEAR() - 1;
    my $wday           = _EPOCH_WDAY() - 1;
    my $check_time     = 0;
    my $number_of_days = 0;
    my $leap_year;
  YEAR: while (1) {
        $leap_year      = $self->_is_leap_year($year);
        $number_of_days = $self->_number_of_days_in_a_year($leap_year);
        my $increment = $number_of_days * _SECONDS_IN_ONE_DAY();
        if ( $check_time - $increment > $time ) {
            $check_time -= $increment;
            $wday       -= $number_of_days;
            $year       -= 1;
        }
        else {
            last YEAR;
        }
    }
    my $yday = $self->_number_of_days_in_a_year($leap_year);
    $year -= _LOCALTIME_BASE_YEAR();

    my $month         = _MONTHS_IN_ONE_YEAR();
    my @days_in_month = $self->_days_in_month($leap_year);
  MONTH: while (1) {

        $number_of_days = $days_in_month[ $month - 1 ];
        my $increment = $number_of_days * _SECONDS_IN_ONE_DAY();
        if ( $check_time - $increment > $time ) {
            $check_time -= $increment;
            $wday       -= $number_of_days;
            $yday       -= $number_of_days;
            $month      -= 1;
        }
        else {
            last MONTH;
        }
    }
    $month -= 1;

    my $day       = $days_in_month[$month];
    my $increment = _SECONDS_IN_ONE_DAY();
  DAY: while (1) {
        if ( $check_time - $increment > $time ) {
            $check_time -= $increment;
            $day        -= 1;
            $yday       -= 1;
            $wday       -= 1;
        }
        else {
            last DAY;
        }
    }

    $wday = abs $wday % _DAYS_IN_ONE_WEEK();

    my $hour = _HOURS_IN_ONE_DAY() - 1;
    $increment = _SECONDS_IN_ONE_HOUR();
  HOUR: while (1) {
        if ( $check_time - $increment > $time ) {
            $check_time -= $increment;
            $hour -= 1;
        }
        else {
            last HOUR;
        }
    }
    my $minute = _MINUTES_IN_ONE_HOUR() - 1;
    $increment = _SECONDS_IN_ONE_MINUTE();
  MINUTE: while (1) {
        if ( $check_time - $increment > $time ) {
            $check_time -= $increment;
            $minute -= 1;
        }
        else {
            last MINUTE;
        }
    }
    my $seconds = _SECONDS_IN_ONE_MINUTE() - ( $check_time - $time );

    return ( $seconds, $minute, $hour, $day, $month, "$year", $wday, $yday, 0 );
}

sub _positive_gm_time {
    my ( $self, $time ) = @_;
    my $year           = _EPOCH_YEAR();
    my $wday           = _EPOCH_WDAY();
    my $check_time     = 0;
    my $number_of_days = 0;
    my $leap_year;
  YEAR: while (1) {
        $leap_year      = $self->_is_leap_year($year);
        $number_of_days = $self->_number_of_days_in_a_year($leap_year);
        my $increment = $number_of_days * _SECONDS_IN_ONE_DAY();
        if ( $check_time + $increment <= $time ) {
            $check_time += $increment;
            $wday       += $number_of_days;
            $year       += 1;
        }
        else {
            last YEAR;
        }
    }
    $year -= _LOCALTIME_BASE_YEAR();

    my $month         = 0;
    my @days_in_month = $self->_days_in_month($leap_year);
    my $yday          = 0;
  MONTH: while (1) {

        $number_of_days = $days_in_month[$month];
        my $increment = $number_of_days * _SECONDS_IN_ONE_DAY();
        if ( $check_time + $increment <= $time ) {
            $check_time += $increment;
            $wday       += $number_of_days;
            $yday       += $number_of_days;
            $month      += 1;
        }
        else {
            last MONTH;
        }
    }
    my $day       = 1;
    my $increment = _SECONDS_IN_ONE_DAY();
  DAY: while (1) {
        if ( $check_time + $increment <= $time ) {
            $check_time += $increment;
            $day        += 1;
            $yday       += 1;
            $wday       += 1;
        }
        else {
            last DAY;
        }
    }

    $wday = $wday % _DAYS_IN_ONE_WEEK();

    my $hour = 0;
    $increment = _SECONDS_IN_ONE_HOUR();
  HOUR: while (1) {
        if ( $check_time + $increment <= $time ) {
            $check_time += $increment;
            $hour += 1;
        }
        else {
            last HOUR;
        }
    }
    my $minute = 0;
    $increment = _SECONDS_IN_ONE_MINUTE();
  MINUTE: while (1) {
        if ( $check_time + $increment <= $time ) {
            $check_time += $increment;
            $minute += 1;
        }
        else {
            last MINUTE;
        }
    }
    my $seconds = $time - $check_time;

    return ( $seconds, $minute, $hour, $day, $month, "$year", $wday, $yday, 0 );
}

sub _gm_time {
    my ( $self, $time ) = @_;
    my @gmtime;
    if ( $time < 0 ) {
        @gmtime = $self->_negative_gm_time($time);
    }
    else {
        @gmtime = $self->_positive_gm_time($time);
    }
    if (wantarray) {
        return @gmtime;
    }
    else {
        my $formatted_date = POSIX::strftime( '%a %b %d %H:%M:%S %Y', @gmtime );
        $formatted_date =~
          s/^(\w+[ ]\w+[ ])0(\d+[ ])/$1 $2/smx;    # %e doesn't work on Win32
        return $formatted_date;
    }
}

sub time_local {
    my ( $self, @localtime ) = @_;
    my $time = 0;
    $localtime[ _LOCALTIME_YEAR_INDEX() ] += _LOCALTIME_BASE_YEAR();
    if ( $localtime[ _LOCALTIME_YEAR_INDEX() ] >= _EPOCH_YEAR() ) {
        return $self->_positive_time_local(@localtime);
    }
    else {
        return $self->_negative_time_local(@localtime);
    }
}

sub _positive_time_local {
    my ( $self, @localtime ) = @_;
    my $check_year = _EPOCH_YEAR();
    my $wday       = _EPOCH_WDAY();
    my $time       = 0;
    my $leap_year  = 0;
  YEAR: while (1) {

        if ( $check_year < $localtime[ _LOCALTIME_YEAR_INDEX() ] ) {
            $time += $self->_number_of_days_in_a_year($leap_year) *
              _SECONDS_IN_ONE_DAY();
            $check_year += 1;
            $leap_year = $self->_is_leap_year($check_year);
        }
        else {
            last YEAR;
        }
    }

    my $check_month   = 0;
    my @days_in_month = $self->_days_in_month($leap_year);
  MONTH: while (1) {

        if ( $check_month < $localtime[ _LOCALTIME_MONTH_INDEX() ] ) {
            $time += $days_in_month[$check_month] * _SECONDS_IN_ONE_DAY();
            $check_month += 1;
        }
        else {
            last MONTH;
        }
    }
    my $check_day = 1;
  DAY: while (1) {
        if ( $check_day < $localtime[ _LOCALTIME_DAY_INDEX() ] ) {
            $time += _SECONDS_IN_ONE_DAY();
            $check_day += 1;
        }
        else {
            last DAY;
        }
    }

    $wday = $wday % _DAYS_IN_ONE_WEEK();

    my $check_hour = 0;
  HOUR: while (1) {
        if ( $check_hour < $localtime[ _LOCALTIME_HOUR_INDEX() ] ) {
            $time += _SECONDS_IN_ONE_HOUR();
            $check_hour += 1;
        }
        else {
            last HOUR;
        }
    }
    my $check_minute = 0;
  MINUTE: while (1) {
        if ( $check_minute < $localtime[ _LOCALTIME_MINUTE_INDEX() ] ) {
            $time += _SECONDS_IN_ONE_MINUTE();
            $check_minute += 1;
        }
        else {
            last MINUTE;
        }
    }
    $time += $localtime[ _LOCALTIME_SECOND_INDEX() ];
    my ( $isdst, $gmtoff, $abbr ) =
      $self->_get_isdst_gmtoff_abbr_calculating_for_time_local($time);
    $time -= $gmtoff;

    return $time;
}

sub _days_in_month {
    my ( $self, $leap_year ) = @_;
    return (
        _DAYS_IN_JANUARY(),
        (
            $leap_year
            ? _DAYS_IN_FEBRUARY_LEAP_YEAR()
            : _DAYS_IN_FEBRUARY_NON_LEAP()
        ),
        _DAYS_IN_MARCH(),
        _DAYS_IN_APRIL(),
        _DAYS_IN_MAY(),
        _DAYS_IN_JUNE(),
        _DAYS_IN_JULY(),
        _DAYS_IN_AUGUST(),
        _DAYS_IN_SEPTEMBER(),
        _DAYS_IN_OCTOBER(),
        _DAYS_IN_NOVEMBER(),
        _DAYS_IN_DECEMBER(),
    );
}

sub _number_of_days_in_a_year {
    my ( $self, $leap_year ) = @_;
    if ($leap_year) {
        return _DAYS_IN_A_LEAP_YEAR();
    }
    else {
        return _DAYS_IN_A_NON_LEAP_YEAR();
    }
}

sub _negative_time_local {
    my ( $self, @localtime ) = @_;
    my $check_year = _EPOCH_YEAR() - 1;
    my $wday       = _EPOCH_WDAY();
    my $time       = 0;
    my $leap_year;
  YEAR: while (1) {

        if ( $check_year > $localtime[ _LOCALTIME_YEAR_INDEX() ] ) {
            $time -= $self->_number_of_days_in_a_year($leap_year) *
              _SECONDS_IN_ONE_DAY();
            $check_year -= 1;
            $leap_year = $self->_is_leap_year($check_year);
        }
        else {
            last YEAR;
        }
    }

    my $check_month   = _MONTHS_IN_ONE_YEAR() - 1;
    my @days_in_month = $self->_days_in_month($leap_year);
  MONTH: while (1) {

        if ( $check_month > $localtime[ _LOCALTIME_MONTH_INDEX() ] ) {
            $time -= $days_in_month[$check_month] * _SECONDS_IN_ONE_DAY();
            $check_month -= 1;
        }
        else {
            last MONTH;
        }
    }
    my $check_day = $days_in_month[$check_month];
  DAY: while (1) {
        if ( $check_day > $localtime[ _LOCALTIME_DAY_INDEX() ] ) {
            $time -= _SECONDS_IN_ONE_DAY();
            $check_day -= 1;
        }
        else {
            last DAY;
        }
    }

    $wday = $wday % _DAYS_IN_ONE_WEEK();

    my $check_hour = _HOURS_IN_ONE_DAY() - 1;
  HOUR: while (1) {
        if ( $check_hour > $localtime[ _LOCALTIME_HOUR_INDEX() ] ) {
            $time -= _SECONDS_IN_ONE_HOUR();
            $check_hour -= 1;
        }
        else {
            last HOUR;
        }
    }
    my $check_minute = _MINUTES_IN_ONE_HOUR();
  MINUTE: while (1) {
        if ( $check_minute > $localtime[ _LOCALTIME_MINUTE_INDEX() ] ) {
            $time -= _SECONDS_IN_ONE_MINUTE();
            $check_minute -= 1;
        }
        else {
            last MINUTE;
        }
    }
    $time += $localtime[ _LOCALTIME_SECOND_INDEX() ];
    my ( $isdst, $gmtoff, $abbr ) =
      $self->_get_isdst_gmtoff_abbr_calculating_for_time_local($time);
    $time -= $gmtoff;

    return $time;
}

sub _get_first_standard_time_type {
    my ( $self, $tz ) = @_;
    my $first_standard_time_type;
    if ( defined $self->{_tzdata}->{$tz}->{local_time_types}->[0] ) {
        $first_standard_time_type =
          $self->{_tzdata}->{$tz}->{local_time_types}->[0];
    }
  FIRST_STANDARD_TIME_TYPE:
    foreach
      my $local_time_type ( @{ $self->{_tzdata}->{$tz}->{local_time_types} } )
    {
        if ( $local_time_type->{isdst} ) {
        }
        else {
            $first_standard_time_type = $local_time_type;
            last FIRST_STANDARD_TIME_TYPE;
        }
    }
    return $first_standard_time_type;
}

sub _get_isdst_gmtoff_abbr_calculating_for_time_local {
    my ( $self, $time ) = @_;
    if ( defined $self->offset() ) {
        return ( 0, $self->offset() * _SECONDS_IN_ONE_MINUTE(), q[] );
    }
    my ( $isdst, $gmtoff, $abbr );
    my $tz = $self->timezone();
    $self->_read_tzfile();
    my $first_standard_time_type = $self->_get_first_standard_time_type($tz);
    my $transition_index         = 0;
    my $transition_time_found;
    my $previous_offset = $first_standard_time_type->{gmtoff};
    my $first_transition_time;
  TRANSITION_TIME:

    foreach my $transition_time_in_gmt ( $self->transition_times() ) {

        if ( !defined $first_transition_time ) {
            $first_transition_time = $transition_time_in_gmt;
        }
        my $local_time_index =
          $self->{_tzdata}->{$tz}->{local_time_indexes}->[$transition_index];
        my $local_time_type =
          $self->{_tzdata}->{$tz}->{local_time_types}->[$local_time_index];
        if ( $local_time_type->{gmtoff} < $previous_offset ) {
            if (
                ( $transition_time_in_gmt > $time - $previous_offset )
                && ( $transition_time_in_gmt <=
                    $time - $local_time_type->{gmtoff} )
              )
            {
                $transition_time_found = 1;
                last TRANSITION_TIME;
            }
            elsif (
                $transition_time_in_gmt > $time - $local_time_type->{gmtoff} )
            {
                $transition_time_found = 1;
                last TRANSITION_TIME;
            }
        }
        else {
            if ( $transition_time_in_gmt > $time - $local_time_type->{gmtoff} )
            {
                $transition_time_found = 1;
                last TRANSITION_TIME;
            }
        }
        $transition_index += 1;
        $previous_offset = $local_time_type->{gmtoff};
    }
    my $offset_found;
    if (
           ( defined $first_transition_time )
        && ($first_standard_time_type)
        && ( $time <
            $first_transition_time + $first_standard_time_type->{gmtoff} )
      )
    {
        $gmtoff       = $first_standard_time_type->{gmtoff};
        $isdst        = $first_standard_time_type->{isdst};
        $abbr         = $first_standard_time_type->{abbr};
        $offset_found = 1;
    }
    elsif ( !$transition_time_found ) {
        my $tz_definition = $self->{_tzdata}->{$tz}->{tz_definition};
        $time -= $tz_definition->{dst_offset_in_seconds} || 0;
        ( $isdst, $gmtoff, $abbr ) =
          $self->_get_tz_offset_according_to_v2_tz_rule($time);
        if ( defined $gmtoff ) {
            $offset_found = 1;
        }
    }
    if ($offset_found) {
    }
    elsif (
        defined $self->{_tzdata}->{$tz}->{local_time_indexes}
        ->[ $transition_index - 1 ] )
    {
        my $local_time_index = $self->{_tzdata}->{$tz}->{local_time_indexes}
          ->[ $transition_index - 1 ];
        my $local_time_type =
          $self->{_tzdata}->{$tz}->{local_time_types}->[$local_time_index];
        $gmtoff = $local_time_type->{gmtoff};
        $isdst  = $local_time_type->{isdst};
        $abbr   = $local_time_type->{abbr};
    }
    else {
        $gmtoff = $first_standard_time_type->{gmtoff};
        $isdst  = $first_standard_time_type->{isdst};
        $abbr   = $first_standard_time_type->{abbr};
    }
    return ( $isdst, $gmtoff, $abbr );
}

sub _get_isdst_gmtoff_abbr_calculating_for_local_time {
    my ( $self, $time ) = @_;
    my ( $isdst, $gmtoff, $abbr );
    if ( defined $self->offset() ) {
        return ( 0, $self->offset() * _SECONDS_IN_ONE_MINUTE(), q[] );
    }
    my $tz = $self->timezone();
    $self->_read_tzfile();
    my $transition_index = 0;
    my $transition_time_found;
    my $first_transition_time;
  TRANSITION_TIME:
    foreach my $transition_time_in_gmt ( $self->transition_times() ) {

        if ( !defined $first_transition_time ) {
            $first_transition_time = $transition_time_in_gmt;
        }
        if ( $transition_time_in_gmt > $time ) {
            $transition_time_found = 1;
            last TRANSITION_TIME;
        }
        $transition_index += 1;
    }
    my $first_standard_time_type = $self->_get_first_standard_time_type($tz);
    my $offset_found;
    if (   ( defined $first_transition_time )
        && ( $time < $first_transition_time ) )
    {
        $gmtoff       = $first_standard_time_type->{gmtoff};
        $isdst        = $first_standard_time_type->{isdst};
        $abbr         = $first_standard_time_type->{abbr};
        $offset_found = 1;
    }
    elsif ( !$transition_time_found ) {
        ( $isdst, $gmtoff, $abbr ) =
          $self->_get_tz_offset_according_to_v2_tz_rule($time);
        if ( defined $gmtoff ) {
            $offset_found = 1;
        }
    }
    if ($offset_found) {
    }
    elsif (
        defined $self->{_tzdata}->{$tz}->{local_time_indexes}
        ->[ $transition_index - 1 ] )
    {
        my $local_time_index = $self->{_tzdata}->{$tz}->{local_time_indexes}
          ->[ $transition_index - 1 ];
        my $local_time_type =
          $self->{_tzdata}->{$tz}->{local_time_types}->[$local_time_index];
        $gmtoff = $local_time_type->{gmtoff};
        $isdst  = $local_time_type->{isdst};
        $abbr   = $local_time_type->{abbr};
    }
    else {
        $gmtoff = $first_standard_time_type->{gmtoff};
        $isdst  = $first_standard_time_type->{isdst};
        $abbr   = $first_standard_time_type->{abbr};
    }
    return ( $isdst, $gmtoff, $abbr );
}

sub local_offset {
    my ( $self, $time ) = @_;
    if ( !defined $time ) {
        $time = time;
    }
    my ( $isdst, $gmtoff, $abbr ) =
      $self->_get_isdst_gmtoff_abbr_calculating_for_local_time($time);
    return int( $gmtoff / _SECONDS_IN_ONE_MINUTE() );
}

sub local_time {
    my ( $self, $time ) = @_;
    if ( !defined $time ) {
        $time = time;
    }

    my ( $isdst, $gmtoff, $abbr ) =
      $self->_get_isdst_gmtoff_abbr_calculating_for_local_time($time);
    $time += $gmtoff;

    if (wantarray) {
        my (@local_time) = $self->_gm_time($time);
        $local_time[ _LOCALTIME_ISDST_INDEX() ] = $isdst;
        return @local_time;
    }
    else {
        return $self->_gm_time($time);
    }
}

sub transition_times {
    my ($self) = @_;
    my $tz = $self->timezone();
    $self->_read_tzfile();
    return @{ $self->{_tzdata}->{$tz}->{transition_times} };
}

sub leap_seconds {
    my ($self) = @_;
    my $tz = $self->timezone();
    $self->_read_tzfile();
    my @leap_seconds =
      sort { $a <=> $b } keys %{ $self->{_tzdata}->{$tz}->{leap_seconds} };
    return @leap_seconds;
}

sub _read_header {
    my ( $self, $handle, $path ) = @_;
    my $result = $handle->read( my $buffer, _SIZE_OF_TZ_HEADER() );
    if ( defined $result ) {
        if ( $result != _SIZE_OF_TZ_HEADER() ) {
            Carp::croak(
"Failed to read entire header from $path.  $result bytes were read instead of the expected "
                  . _SIZE_OF_TZ_HEADER() );
        }
    }
    else {
        Carp::croak("Failed to read header from $path:$EXTENDED_OS_ERROR");
    }
    my ( $magic, $version, $ttisgmtcnt, $ttisstdcnt, $leapcnt, $timecnt,
        $typecnt, $charcnt )
      = unpack 'A4A1x15N!N!N!N!N!N!', $buffer;
    ( $magic eq 'TZif' ) or Carp::croak("$path is not a TZ file");
    my $header = {
        magic      => $magic,
        version    => $version,
        ttisgmtcnt => $ttisgmtcnt,
        ttisstdcnt => $ttisstdcnt,
        leapcnt    => $leapcnt,
        timecnt    => $timecnt,
        typecnt    => $typecnt,
        charcnt    => $charcnt
    };

    return $header;
}

sub _read_transition_times {
    my ( $self, $handle, $path, $timecnt, $sizeof_transition_time ) = @_;
    my $sizeof_transition_times = $timecnt * $sizeof_transition_time;
    my $result = $handle->read( my $buffer, $sizeof_transition_times );
    if ( defined $result ) {
        if ( $result != $sizeof_transition_times ) {
            Carp::croak(
"Failed to read all the transition times from $path.  $result bytes were read instead of the expected "
                  . $sizeof_transition_times );
        }
    }
    else {
        Carp::croak(
            "Failed to read transition times from $path:$EXTENDED_OS_ERROR");
    }
    my @transition_times;
    if ( $sizeof_transition_time == _SIZE_OF_TRANSITION_TIME_V1() ) {
        @transition_times = unpack 'l>' . $timecnt, $buffer;
    }
    elsif ( $sizeof_transition_time == _SIZE_OF_TRANSITION_TIME_V2() ) {
        eval { @transition_times = unpack 'q>' . $timecnt, $buffer; 1; } or do {
            require Math::Int64;
            @transition_times =
              map { Math::Int64::net_to_int64($_) } unpack '(a8)' . $timecnt,
              $buffer;
        };
    }
    return \@transition_times;
}

sub _read_local_time_indexes {
    my ( $self, $handle, $path, $timecnt ) = @_;
    my $result = $handle->read( my $buffer, $timecnt );
    if ( defined $result ) {
        if ( $result != $timecnt ) {
            Carp::croak(
"Failed to read all the local time indexes from $path.  $result bytes were read instead of the expected "
                  . $timecnt );
        }
    }
    else {
        Carp::croak(
            "Failed to read local time indexes from $path:$EXTENDED_OS_ERROR");
    }
    my @local_time_indexes = unpack 'C' . $timecnt, $buffer;
    return \@local_time_indexes;
}

sub _read_local_time_types {
    my ( $self, $handle, $path, $typecnt ) = @_;
    my $sizeof_local_time_types = $typecnt * _SIZE_OF_TTINFO();
    my $result = $handle->read( my $buffer, $sizeof_local_time_types );
    if ( defined $result ) {
        if ( $result != $sizeof_local_time_types ) {
            Carp::croak(
"Failed to read all the local time types from $path.  $result bytes were read instead of the expected "
                  . $sizeof_local_time_types );
        }
    }
    else {
        Carp::croak(
            "Failed to read local time types from $path:$EXTENDED_OS_ERROR");
    }
    my @local_time_types;
    foreach my $local_time_type ( unpack '(a6)' . $typecnt, $buffer ) {
        my ( $c1, $c2, $c3 ) = unpack 'a4aa', $local_time_type;
        my $gmtoff  = unpack 'l>', $c1;
        my $isdst   = unpack 'C',  $c2;
        my $abbrind = unpack 'C',  $c3;
        push @local_time_types,
          { gmtoff => $gmtoff, isdst => $isdst, abbrind => $abbrind };
    }
    return \@local_time_types;
}

sub _read_time_zone_abbreviation_strings {
    my ( $self, $handle, $path, $charcnt ) = @_;
    my $result = $handle->read( my $time_zone_abbreviation_strings, $charcnt );
    if ( defined $result ) {
        if ( $result != $charcnt ) {
            Carp::croak(
"Failed to read all the time zone abbreviations from $path.  $result bytes were read instead of the expected "
                  . $charcnt );
        }
    }
    else {
        Carp::croak(
"Failed to read time zone abbreviations from $path:$EXTENDED_OS_ERROR"
        );
    }
    return $time_zone_abbreviation_strings;
}

sub _read_leap_seconds {
    my ( $self, $handle, $path, $leapcnt, $sizeof_leap_second ) = @_;
    my $sizeof_leap_seconds = $leapcnt * _PAIR() * $sizeof_leap_second;
    my $result = $handle->read( my $buffer, $sizeof_leap_seconds );
    if ( defined $result ) {
        if ( $result != $sizeof_leap_seconds ) {
            Carp::croak(
"Failed to read all the leap seconds from $path.  $result bytes were read instead of the expected "
                  . $sizeof_leap_seconds );
        }
    }
    else {
        Carp::croak(
            "Failed to read leap seconds from $path:$EXTENDED_OS_ERROR");
    }
    my @paired_leap_seconds = unpack 'L>' . $leapcnt, $buffer;
    my %leap_seconds;
    while (@paired_leap_seconds) {
        my $time_leap_second_occurs      = shift @paired_leap_seconds;
        my $total_number_of_leap_seconds = shift @paired_leap_seconds;
        $leap_seconds{$time_leap_second_occurs} = $total_number_of_leap_seconds;
    }
    return \%leap_seconds;
}

sub _read_is_standard_time {
    my ( $self, $handle, $path, $ttisstdcnt ) = @_;
    my $result = $handle->read( my $buffer, $ttisstdcnt );
    if ( defined $result ) {
        if ( $result != $ttisstdcnt ) {
            Carp::croak(
"Failed to read all the is standard time values from $path.  $result bytes were read instead of the expected "
                  . $ttisstdcnt );
        }
    }
    else {
        Carp::croak(
"Failed to read is standard time values from $path:$EXTENDED_OS_ERROR"
        );
    }
    my @is_std_time = unpack 'C' . $ttisstdcnt, $buffer;
    return \@is_std_time;
}

sub _read_is_gmt {
    my ( $self, $handle, $path, $ttisgmtcnt ) = @_;
    my $result = $handle->read( my $buffer, $ttisgmtcnt );
    if ( defined $result ) {
        if ( $result != $ttisgmtcnt ) {
            Carp::croak(
"Failed to read all the is GMT values from $path.  $result bytes were read instead of the expected "
                  . $ttisgmtcnt );
        }
    }
    else {
        Carp::croak(
            "Failed to read is GMT values from $path:$EXTENDED_OS_ERROR");
    }
    my @is_gmt_time = unpack 'C' . $ttisgmtcnt, $buffer;
    return \@is_gmt_time;
}

sub _read_tz_definition {
    my ( $self, $handle, $path ) = @_;
    my $result =
      $handle->read( my $buffer, _MAX_LENGTH_FOR_TRAILING_TZ_DEFINITION() );
    if ( defined $result ) {
        if ( $result == _MAX_LENGTH_FOR_TRAILING_TZ_DEFINITION() ) {
            Carp::croak(
                    "The tz defintion at the end of $path could not be read in "
                  . _MAX_LENGTH_FOR_TRAILING_TZ_DEFINITION()
                  . ' bytes' );
        }
    }
    else {
        Carp::croak(
            "Failed to read tz definition from $path:$EXTENDED_OS_ERROR");
    }
    if ( $buffer =~ /^\n([^\n]+)\n*$/smx ) {
        return $self->_parse_tz_variable( $1, $path );

    }
    return;
}

sub _parse_tz_variable {
    my ( $self, $tz_variable, $path ) = @_;
    my $timezone_abbr_name_regex =
      qr/(?:[^:\d,+-][^\d,+-]{2,}|[<]\w*[+-]?\d+[>])/smx;
    my $std_name_regex = qr/(?<std_name>$timezone_abbr_name_regex)/smx
      ;    # Name for standard offset from GMT
    my $std_sign_regex    = qr/(?<std_sign>[+-])/smx;
    my $std_hours_regex   = qr/(?<std_hours>\d+)/smx;
    my $std_minutes_regex = qr/(?::(?<std_minutes>\d+))/smx;
    my $std_seconds_regex = qr/(?::(?<std_seconds>\d+))/smx;
    my $std_offset_regex =
qr/$std_sign_regex?$std_hours_regex$std_minutes_regex?$std_seconds_regex?/smx
      ;    # Standard offset from GMT
    my $dst_name_regex = qr/(?<dst_name>$timezone_abbr_name_regex)/smx
      ;    # Name for daylight saving offset from GMT
    my $dst_sign_regex    = qr/(?<dst_sign>[+-])/smx;
    my $dst_hours_regex   = qr/(?<dst_hours>\d+)/smx;
    my $dst_minutes_regex = qr/(?::(?<dst_minutes>\d+))/smx;
    my $dst_seconds_regex = qr/(?::(?<dst_seconds>\d+))/smx;
    my $dst_offset_regex =
qr/$dst_sign_regex?$dst_hours_regex$dst_minutes_regex?$dst_seconds_regex?/smx
      ;    # Standard offset from GMT
    my $start_julian_without_feb29_regex =
      qr/(?:J(?<start_julian_without_feb29>\d{1,3}))/smx;
    my $start_julian_with_feb29_regex =
      qr/(?<start_julian_with_feb29>\d{1,3})/smx;
    my $start_month_regex = qr/(?<start_month>\d{1,2})/smx;
    my $start_week_regex  = qr/(?<start_week>[1-5])/smx;
    my $start_day_regex   = qr/(?<start_day>[0-6])/smx;
    my $start_month_week_day_regex =
      qr/(?:M$start_month_regex[.]$start_week_regex[.]$start_day_regex)/smx;
    my $start_date_regex =
qr/(?:$start_julian_without_feb29_regex|$start_julian_with_feb29_regex|$start_month_week_day_regex)/smx;
    my $start_hour_regex   = qr/(?<start_hour>\-?\d+)/smx;
    my $start_minute_regex = qr/(?::(?<start_minute>\d+))/smx;
    my $start_second_regex = qr/(?::(?<start_second>\d+))/smx;
    my $start_time_regex =
      qr/[\/]$start_hour_regex$start_minute_regex?$start_second_regex?/smx;
    my $start_datetime_regex = qr/$start_date_regex(?:$start_time_regex)?/smx;
    my $end_julian_without_feb29_regex =
      qr/(?:J(?<end_julian_without_feb29>\d{1,3}))/smx;
    my $end_julian_with_feb29_regex = qr/(?<end_julian_with_feb29>\d{1,3})/smx;
    my $end_month_regex             = qr/(?<end_month>\d{1,2})/smx;
    my $end_week_regex              = qr/(?<end_week>[1-5])/smx;
    my $end_day_regex               = qr/(?<end_day>[0-6])/smx;
    my $end_month_week_day_regex =
      qr/(?:M$end_month_regex[.]$end_week_regex[.]$end_day_regex)/smx;
    my $end_date_regex =
qr/(?:$end_julian_without_feb29_regex|$end_julian_with_feb29_regex|$end_month_week_day_regex)/smx;
    my $end_hour_regex   = qr/(?<end_hour>\-?\d+)/smx;
    my $end_minute_regex = qr/(?::(?<end_minute>\d+))/smx;
    my $end_second_regex = qr/(?::(?<end_second>\d+))/smx;
    my $end_time_regex =
      qr/[\/]$end_hour_regex$end_minute_regex?$end_second_regex?/smx;
    my $end_datetime_regex = qr/$end_date_regex(?:$end_time_regex)?/smx;

    if ( $tz_variable =~
/^$std_name_regex$std_offset_regex(?:$dst_name_regex(?:$dst_offset_regex)?,$start_datetime_regex,$end_datetime_regex)?$/smx
      )
    {
        my $tz_definition = { tz => $tz_variable };
        foreach my $key ( _TZ_DEFINITION_KEYS() ) {
            if ( defined $LAST_PAREN_MATCH{$key} ) {
                $tz_definition->{$key} = $LAST_PAREN_MATCH{$key};
            }
        }
        $self->_initialise_undefined_tz_definition_values($tz_definition);
        return $tz_definition;
    }
    else {
        Carp::croak(
            "Failed to parse the tz defintion of $tz_variable from $path");
    }
}

sub _dst_offset_in_seconds {
    my ( $self, $tz_definition ) = @_;
    my $dst_offset_in_seconds = $tz_definition->{dst_seconds} || 0;
    if ( defined $tz_definition->{dst_minutes} ) {
        $dst_offset_in_seconds +=
          $tz_definition->{dst_minutes} * _SECONDS_IN_ONE_MINUTE();
    }
    if ( defined $tz_definition->{dst_hours} ) {
        $dst_offset_in_seconds +=
          $tz_definition->{dst_hours} *
          _MINUTES_IN_ONE_HOUR() *
          _SECONDS_IN_ONE_MINUTE();
    }
    else {
        $dst_offset_in_seconds +=
          ( $tz_definition->{std_hours} ) *
          _MINUTES_IN_ONE_HOUR() *
          _SECONDS_IN_ONE_MINUTE();
        if ( defined $tz_definition->{std_minutes} ) {
            $dst_offset_in_seconds +=
              $tz_definition->{std_minutes} * _SECONDS_IN_ONE_MINUTE();
        }
    }
    if (   ( defined $tz_definition->{dst_sign} )
        && ( $tz_definition->{dst_sign} eq q[-] ) )
    {
    }
    elsif ( defined $tz_definition->{dst_hours} ) {
        $dst_offset_in_seconds *= _NEGATIVE_ONE();
    }
    elsif (( defined $tz_definition->{std_sign} )
        && ( $tz_definition->{std_sign} eq q[-] ) )
    {
        $dst_offset_in_seconds +=
          _MINUTES_IN_ONE_HOUR() * _SECONDS_IN_ONE_MINUTE();
    }
    else {
        $dst_offset_in_seconds *= _NEGATIVE_ONE();
        $dst_offset_in_seconds +=
          _MINUTES_IN_ONE_HOUR() * _SECONDS_IN_ONE_MINUTE();
    }
    return $dst_offset_in_seconds;
}

sub _std_offset_in_seconds {
    my ( $self, $tz_definition ) = @_;
    my $std_offset_in_seconds = $tz_definition->{std_seconds} || 0;

    if ( defined $tz_definition->{std_minutes} ) {
        $std_offset_in_seconds +=
          $tz_definition->{std_minutes} * _SECONDS_IN_ONE_MINUTE();
    }
    if ( defined $tz_definition->{std_hours} ) {
        $std_offset_in_seconds +=
          $tz_definition->{std_hours} *
          _MINUTES_IN_ONE_HOUR() *
          _SECONDS_IN_ONE_MINUTE();
    }
    if (   ( defined $tz_definition->{std_sign} )
        && ( $tz_definition->{std_sign} eq q[-] ) )
    {
    }
    else {
        $std_offset_in_seconds *= _NEGATIVE_ONE();
    }
    return $std_offset_in_seconds;
}

sub _initialise_undefined_tz_definition_values {
    my ( $self, $tz_definition ) = @_;
    $tz_definition->{start_hour} =
      defined $tz_definition->{start_hour}
      ? $tz_definition->{start_hour}
      : _DEFAULT_DST_START_HOUR();
    $tz_definition->{start_minute} =
      defined $tz_definition->{start_minute}
      ? $tz_definition->{start_minute}
      : 0;
    $tz_definition->{start_second} =
      defined $tz_definition->{start_second}
      ? $tz_definition->{start_second}
      : 0;
    $tz_definition->{end_hour} =
      defined $tz_definition->{end_hour}
      ? $tz_definition->{end_hour}
      : _DEFAULT_DST_END_HOUR();
    $tz_definition->{end_minute} =
      defined $tz_definition->{end_minute}
      ? $tz_definition->{end_minute}
      : 0;
    $tz_definition->{end_second} =
      defined $tz_definition->{end_second}
      ? $tz_definition->{end_second}
      : 0;
    $tz_definition->{std_offset_in_seconds} =
      $self->_std_offset_in_seconds($tz_definition);
    $tz_definition->{dst_offset_in_seconds} =
      $self->_dst_offset_in_seconds($tz_definition);
    return;
}

sub _set_abbrs {
    my ( $self, $tz ) = @_;
    my $index = 0;
    foreach
      my $local_time_type ( @{ $self->{_tzdata}->{$tz}->{local_time_types} } )
    {
        if ( $self->{_tzdata}->{$tz}->{local_time_types}->[ $index + 1 ] ) {
            $local_time_type->{abbr} =
              substr $self->{_tzdata}->{$tz}->{time_zone_abbreviation_strings},
              $local_time_type->{abbrind},
              $self->{_tzdata}->{$tz}->{local_time_types}->[ $index + 1 ]
              ->{abbrind};
        }
        else {
            $local_time_type->{abbr} =
              substr $self->{_tzdata}->{$tz}->{time_zone_abbreviation_strings},
              $local_time_type->{abbrind};
        }
        $local_time_type->{abbr} =~ s/\0+$//smx;
        $index += 1;
    }
    return;
}

sub _read_v1_tzfile {
    my ( $self, $handle, $path, $header, $tz ) = @_;
    $self->{_tzdata}->{$tz}->{transition_times} =
      $self->_read_transition_times( $handle, $path, $header->{timecnt},
        _SIZE_OF_TRANSITION_TIME_V1() );
    $self->{_tzdata}->{$tz}->{local_time_indexes} =
      $self->_read_local_time_indexes( $handle, $path, $header->{timecnt} );
    $self->{_tzdata}->{$tz}->{local_time_types} =
      $self->_read_local_time_types( $handle, $path, $header->{typecnt} );
    $self->{_tzdata}->{$tz}->{time_zone_abbreviation_strings} =
      $self->_read_time_zone_abbreviation_strings( $handle, $path,
        $header->{charcnt} );
    $self->_set_abbrs($tz);
    $self->{_tzdata}->{$tz}->{leap_seconds} =
      $self->_read_leap_seconds( $handle, $path, $header->{leapcnt},
        _SIZE_OF_LEAP_SECOND_V1() );
    $self->{_tzdata}->{$tz}->{is_std} =
      $self->_read_is_standard_time( $handle, $path, $header->{ttisstdcnt} );
    $self->{_tzdata}->{$tz}->{is_gmt} =
      $self->_read_is_gmt( $handle, $path, $header->{ttisstdcnt} );
    return;
}

sub _read_v2_tzfile {
    my ( $self, $handle, $path, $header, $tz ) = @_;

    if (   ( $header->{version} )
        && ( $header->{version} >= 2 )
        && ( defined $Config{'d_quad'} )
        && ( $Config{'d_quad'} eq 'define' ) )
    {
        $self->{_tzdata}->{$tz} = {};
        $header = $self->_read_header( $handle, $path );
        $self->{_tzdata}->{$tz}->{transition_times} =
          $self->_read_transition_times( $handle, $path, $header->{timecnt},
            _SIZE_OF_TRANSITION_TIME_V2() );
        $self->{_tzdata}->{$tz}->{local_time_indexes} =
          $self->_read_local_time_indexes( $handle, $path, $header->{timecnt} );
        $self->{_tzdata}->{$tz}->{local_time_types} =
          $self->_read_local_time_types( $handle, $path, $header->{typecnt} );
        $self->{_tzdata}->{$tz}->{time_zone_abbreviation_strings} =
          $self->_read_time_zone_abbreviation_strings( $handle, $path,
            $header->{charcnt} );
        $self->_set_abbrs($tz);
        $self->{_tzdata}->{$tz}->{leap_seconds} =
          $self->_read_leap_seconds( $handle, $path, $header->{leapcnt},
            _SIZE_OF_LEAP_SECOND_V2() );
        $self->{_tzdata}->{$tz}->{is_std} =
          $self->_read_is_standard_time( $handle, $path,
            $header->{ttisstdcnt} );
        $self->{_tzdata}->{$tz}->{is_gmt} =
          $self->_read_is_gmt( $handle, $path, $header->{ttisstdcnt} );
        $self->{_tzdata}->{$tz}->{tz_definition} =
          $self->_read_tz_definition( $handle, $path );
    }
    return;
}

sub _read_tzfile {
    my ($self) = @_;
    my $tz = $self->timezone();
    if (   ( exists $self->{_tzdata}->{$tz}->{no_tz_file} )
        && ( $self->{_tzdata}->{$tz}->{no_tz_file} ) )
    {
    }
    else {
        my $path = File::Spec->catfile( $self->directory, $tz );
        my $handle = FileHandle->new($path)
          or Carp::croak("Failed to open $path for reading:$EXTENDED_OS_ERROR");
        my @stat = stat $handle
          or Carp::croak("Failed to stat $path:$EXTENDED_OS_ERROR");
        my $last_modified = $stat[ _STAT_MTIME_IDX() ];
        if (   ( $self->{_tzdata}->{$tz}->{last_modified} )
            && ( $self->{_tzdata}->{$tz}->{last_modified} == $last_modified ) )
        {
        }
        elsif (( $_tzdata_cache->{$tz} )
            && ( $_tzdata_cache->{$tz}->{last_modified} )
            && ( $_tzdata_cache->{$tz}->{last_modified} == $last_modified ) )
        {
            $self->{_tzdata}->{$tz} = $_tzdata_cache->{$tz};
        }
        else {
            binmode $handle;
            my $header = $self->_read_header( $handle, $path );
            $self->_read_v1_tzfile( $handle, $path, $header, $tz );
            $self->_read_v2_tzfile( $handle, $path, $header, $tz );
            $self->{_tzdata}->{$tz}->{last_modified} = $last_modified;
            $_tzdata_cache->{$tz} = $self->{_tzdata}->{$tz};
        }
        close $handle
          or Carp::croak("Failed to close $path:$EXTENDED_OS_ERROR");
    }
    return;
}

sub reset_cache {
    my ($self) = @_;
    if ( ref $self ) {
        foreach my $key (qw(_tzdata _zonetab_last_modified _comments _zones)) {
            $self->{$key} = {};
        }
    }
    else {
        $_tzdata_cache  = {};
        $_zonetab_cache = {};
    }
    return;
}

1;
__END__
=head1 NAME

Time::Zone::Olson - Provides an interface to the Olson timezone database

=head1 VERSION

Version 0.13

=cut

=head1 SYNOPSIS

    use Time::Zone::Olson();

    my $time_zone = Time::Zone::Olson->new( timezone => 'Australia/Melbourne' ); # set timezone at creation time
    my $now = $time_zone->time_local($seconds, $minutes, $hours, $day, $month, $year); # convert for Australia/Melbourne time
    foreach my $area ($time_zone->areas()) {
        foreach my $location ($time_zone->locations($area)) {
            $time_zone->timezone("$area/$location");
            print scalar $time_zone->local_time($now); # output time in $area/$location local time
            warn scalar localtime($now) . " log message for sysadmin"; # but log in system local time
        }
    }

=head1 DESCRIPTION

Time::Zone::Olson is intended to provide a simple interface to the Olson database that is available on most UNIX systems.  It provides an interface to list common time zones, such as Australia/Melbourne that are stored in the zone.tab file, and localtime/Time::Local::timelocal replacements to translate times to and from the users timezone, without changing the timezone used by Perl.  This allows logging/etc to be conducted in the system's local time.

Time::Zone::Olson was designed to produce the same result as a 64bit copy of the L<date(1)|date(1)> command.

=head1 SUBROUTINES/METHODS

=head2 new

Time::Zone::Olson->new() will return a new timezone object.  It accepts a hash as a parameter with an optional C<timezone> key, which contains an Olson timezone value, such as 'Australia/Melbourne'.  The hash also allows a C<directory> key, with the file system location of the Olson timezone database as a value.

Both of these parameters default to C<$ENV{TZ}> and C<$ENV{TZDIR}> respectively.

=head2 areas

The areas() object method will return a list of the areas (such as Asia, Australia, Africa, America, Europe) from the zone.tab file.  The areas will be sorted alphabetically.

=head2 locations

The locations($area) object method will return a list of the locations (such as Melbourne, Perth, Hobart) for a specified area from the zone.tab file.  The locations will be sorted alphabetically.

=head2 comment

The comment($timezone) object method will return the matching comment from the zone.tab file for the timezone parameter.  For example, if C<"Australia/Melbourne"> was passed as a parameter, the L</comment> function would return C<"Victoria">

=head2 directory

This object method can be used to get or set the root directory of the Olson database, usually located at /usr/share/zoneinfo.

=head2 timezone

This object method can be used to get or set the timezone, which will affect all future calls to L</local_time> or L</time_local>.  The parameter for this method should be in the Olson format of a timezone, such as C<"Australia/Melbourne">.

=head2 equiv

This object method takes a timezone name as a parameter.  It then compares the transition times and offsets for the currently set timezone to the transition times and offsets for the specified timezone and returns true if they match exactly from the current time.  The second optional parameter can specify the start time to use when comparing the two time zones.

=head2 offset

This object method can be used to get or set the offset for all L</local_time> or L</time_local> calls.  The offset should be specified in minutes from GMT.

=head2 area

This object method will return the area component of the current timezone, such as Australia

=head2 location

This object method will return the location component of the current timezone, such as Melbourne

=head2 local_offset

This object method takes the same arguments as C<localtime> but returns the appropriate offset from GMT in minutes.  This can to used as a C<offset> parameter to a subsequent call to Time::Zone::Olson.

=head2 local_time

This object method has the same signature as the 64 bit version of the C<localtime> function.  That is, it accepts up to a 64 bit signed integer as the sole argument and returns the C<(seconds, minutes, hours, day, month, year, wday, yday, isdst)> definition for the timezone for the object.  The timezone used to calculate the local time may be specified as a parameter to the L</new> method or via the L</timezone> method.

=head2 time_local

This object method has the same signature as the 64 bit version of the C<Time::Local::timelocal> function.  That is, it accepts C<(seconds, minutes, hours, day, month, year, wday, yday, isdst)> as parameters in a list and returns the correct UNIX time in seconds according to the current timezone for the object.  The timezone used to calculate the local time may be specified as a parameter to the L</new> method or via the L</timezone> method. 

During a time zone change such as +11 GMT to +10 GMT, there will be two possible UNIX times that can result in the same local time.  In this case, like C<Time::Local::timelocal>, this function will return the lower of the two times.

=head2 transition_times

This object method can be used to get the list of transition times for the current timezone.  This method is only intended for testing the results of Time::Zone::Olson.

=head2 leap_seconds

This object method can be used to get the list of leap seconds for the current timezone.  This method is only intended for testing the results of Time::Zone::Olson.

=head2 reset_cache

This object or class method can be used to reset the cache.  This method is only intended for testing the results of Time::Zone::Olson.  In actual use, cached values are only used if the C<mtime> of the relevant files has not changed.

=head1 DIAGNOSTICS

=over

=item C<< %s is not a TZ file >>

The designated path did not have the C<TZif> prefix at the start of the file.  Maybe either the directory or the timezone name is incorrect?

=item C<< Failed to read header from %s:%s >>

The designated file encountered an error reading either the V1 or V2 headers

=item C<< Failed to read entire header from %s.  %d bytes were read instead of the expected %d >>

The designated file is shorter than expected

=item C<< %s is not an timezone in the existing Olson database >>

The designated timezone could not be found on the file system.  The timezone is expected to be in the designated directory + the timezone name, for example, /usr/share/zoneinfo/Australia/Melbourne

=item C<< %s does not have a valid format for a TZ timezone >>

The designated timezone name could not be matched by the regular expression for a timezone in Time::Zone::Olson

=item C<< Failed to close %s:%s >>

There has been a file system error while reading or closing the designated path

=item C<< Failed to open %s for reading:%s >>

There has been a file system error while opening the the designated path.  This could be permissions related, or the timezone in question doesn't exist?

=item C<< Failed to stat %s:%s >>

There has been a file system error while doing a L<stat|perlfunc/"stat"> on the designated path.  This could be permissions related, or the timezone in question doesn't exist?

=item C<< Failed to read %s from %s:%s >>

There has been a file system error while reading from the designated path.  The file could be corrupt?

=item C<< Failed to read all the %s from %s.  %d bytes were read instead of the expected %d >>

The designated file is shorter than expected.  The file could be corrupt?

=item C<< The tz defintion at the end of %s could not be read in %d bytes >>

The designated file is longer than expected.  Maybe the timezone version is greater than the currently recognized 3?

=item C<< Failed to read tz definition from %s:% >>

There has been a file system error while reading from the designated path.  The file could be corrupt?

=item C<< Failed to parse the tz defintion of %s from %s >>

This is probably a bug in Time::Zone::Olson in failing to parse the C<TZ> variable at the end of the file.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Time::Zone::Olson requires no configuration files or environment variables.  However, it will use the values of C<$ENV{TZ}> and C<$ENV{TZDIR}> as defaults for missing parameters.

=head1 DEPENDENCIES

Time::Zone::Olson requires Perl 5.6 or better.  For environments where the unpack 'q' parameter is not supported, the following module is also required

=over

=item *
L<Math::Int64|Math::Int64>

=back

=head1 INCOMPATIBILITIES

None reported

=head1 BUGS AND LIMITATIONS

On Win32 platforms, the Olson TZ database is usually unavailable.  In an attempt to provide a workable alternative, the Win32 Registry is interrogated and translated to allow Olson timezones (such as Australia/Melbourne) to be used on Win32 nodes.  Therefore, the use of Time::Zone::Olson should be cross-platform compatible, but the actual results may be different, depending on the compatibility of the Win32 Registry timezones and the Olson TZ database.

Please report any bugs or feature requests to C<bug-time-zone-olson at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Time-Zone-Olson>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

=over

=item *
L<DateTime::TimeZone|DateTime::TimeZone>

=item *
L<DateTime::TimeZone::Tzfile|DateTime::TimeZone::Tzfile>

=back

=head1 AUTHOR

David Dick, C<< <ddick at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 David Dick.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
