package Time::TZif::POSIX;
use strict;
use warnings;
use v5.10;

our $VERSION = '0.89';

use Carp                qw[croak];
use Time::Str::Calendar qw[leap_year
                           month_days
                           nth_dow_in_month
                           ymd_to_dow
                           yd_to_md 
                           rdn_to_ymd];
use Time::Str::Time     qw[ gmtime_year
                            timegm_modern ];
use Time::Str::Util     qw[upper_bound
                           valid_tzdb_timezone];

my %ValidPolicy = (
  earlier => 1, later => 1, std => 1, dst => 1, reject => 1
);

use constant RDN_UNIX_EPOCH => 719163; # 1970-01-01

# POSIX TZ string (IEEE Std 1003.1)
#
#   std offset [dst [offset] , start [/time] , end [/time]]
#
# Examples:
#   EST5EDT,M3.2.0,M11.1.0          US Eastern
#   CET-1CEST,M3.5.0/2,M10.5.0/3    Central European
#   <+05>-5                         Fixed UTC+5
#   NZST-12NZDT,M9.5.0,M4.1.0/3     New Zealand
#
my $POSIX_TZ_Rx = qr{
  (?(DEFINE)
    (?<Name>   [A-Za-z]{3,} | [<][A-Za-z0-9+-]{3,}[>] )
    (?<Offset> [+-]? [0-9]{1,2} (?: [:][0-9]{2} (?: [:][0-9]{2} )? )? )
    (?<Time>   [+-]? [0-9]{1,3} (?: [:][0-9]{2} (?: [:][0-9]{2} )? )? )
    (?<Rule>   M [0-9]{1,2} [.] [1-5] [.] [0-6]
             | J [0-9]{1,3}
             |   [0-9]{1,3} )
  )

  \A
        (?<std_name>   (?&Name))         (?<std_offset> (?&Offset))
  (?:
        (?<dst_name>   (?&Name))         (?<dst_offset> (?&Offset) )?
    [,] (?<rule_start> (?&Rule)) (?: [/] (?<time_start> (?&Time))  )?
    [,] (?<rule_end>   (?&Rule)) (?: [/] (?<time_end>   (?&Time))  )?
  )?
  \z
}x;

my $Rule_Rx = qr{
  \A
  (?:
      M (?<month> [0-9]{1,2}) [.] (?<week> [1-5]) [.] (?<wday> [0-6])
    | J (?<jday>  [0-9]{1,3})
    |   (?<nday>  [0-9]{1,3})
  )
  \z
}x;

sub new {
  (@_ & 1 && @_ >= 3) or croak q/Usage: Time::TZif::POSIX->new(tz_string => $string)/;
  my ($class, %p) = @_;

  my (%state, $tz_string);

  while (my ($key, $v) = each %p) {
    if ($key eq 'tz_string') {
      $tz_string = $v;
    }
    elsif ($key eq 'name') {
      valid_tzdb_timezone($v)
        or croak qq/Invalid value for the parameter 'name'/;
      $state{name} = $v;
    }
    elsif ($key eq 'gap_policy') {
      (defined $v && exists $ValidPolicy{$v})
        or croak qq/Invalid policy value for the parameter 'gap_policy'/;
      $state{gap_policy} = $v;
    }
    elsif ($key eq 'overlap_policy') {
      (defined $v && exists $ValidPolicy{$v})
        or croak qq/Invalid policy value for the parameter 'overlap_policy'/;
      $state{overlap_policy} = $v;
    }
    else {
      croak qq/Unrecognised named parameter: '$key'/;
    }
  }

  (defined $tz_string)
    or croak q/Parameter 'tz_string' is required/;

  $state{tz_string}        = $tz_string;
  $state{gap_policy}     //= 'reject';
  $state{overlap_policy} //= 'reject';

  my $self = bless \%state, $class;
  $self->_parse($tz_string);
  return $self;
}

sub _with {
  my ($object, %with) = @_;
  return bless { %{$object}, %with }, ref $object;
}

sub name { 
  @_ == 1 or croak q/Usage: $tz->name()/;
  return $_[0]->{name};
}

sub tz_string {
  @_ == 1 or croak q/Usage: $tz->tz_string()/;
  return $_[0]->{tz_string};
}

sub gap_policy {
  @_ == 1 or croak q/Usage: $tz->gap_policy()/;
  return $_[0]->{gap_policy};
}

sub overlap_policy {
  @_ == 1 or croak q/Usage: $tz->overlap_policy()/;
  return $_[0]->{overlap_policy};
}

sub has_name {
  @_ == 1 or croak q/Usage: $tz->has_name()/;
  return exists $_[0]->{name};
}

sub with_name {
  @_ == 2 or croak q/Usage: $tz->with_name($name)/;
  my ($self, $name) = @_;

  valid_tzdb_timezone($name)
    or croak qq/Invalid name value/;

  if (!exists $self->{name} || $name ne $self->{name}) {
    return _with($self, name => $name);
  }
  return $self;
}

sub with_gap_policy {
  @_ == 2 or croak q/Usage: $tz->with_gap_policy($policy)/;
  my ($self, $policy) = @_;

  (defined $policy && exists $ValidPolicy{$policy})
    or croak qq/Invalid policy value/;

  if ($policy ne $self->{gap_policy}) {
    return _with($self, gap_policy => $policy);
  }
  return $self;
}

sub with_overlap_policy {
  @_ == 2 or croak q/Usage: $tz->with_overlap_policy($policy)/;
  my ($self, $policy) = @_;

  (defined $policy && exists $ValidPolicy{$policy})
    or croak qq/Invalid policy value/;

  if ($policy ne $self->{overlap_policy}) {
    return _with($self, overlap_policy => $policy);
  }
  return $self;
}

sub _parse_offset {
  my ($str) = @_;
  $str =~ /\A ([+-]?) ([0-9]{1,2}) (?: [:]([0-9]{2}) (?: [:]([0-9]{2}) )? )? \z/x
    or croak qq/Unable to parse POSIX TZ string: invalid offset '$str'/;
  my ($h, $m, $s) = ($2, $3 // 0, $4 // 0);
  ($h <= 24 && $m <= 59 && $s <= 59)
    or croak qq/Unable to parse POSIX TZ string: offset time is out of range: $str/;
  my $secs = $h * 3600 + $m * 60 + $s;
  return ($1 eq '-') ? -$secs : $secs;
}

sub _parse_rule_time {
  my ($str) = @_;
  $str =~ /\A ([+-]?) ([0-9]{1,3}) (?: [:]([0-9]{2}) (?: [:]([0-9]{2}) )? )? \z/x
    or croak qq/Unable to parse POSIX TZ string: invalid rule time '$str'/;
  my ($h, $m, $s) = ($2, $3 // 0, $4 // 0);
  ($h <= 167 && $m <= 59 && $s <= 59)
    or croak qq/Unable to parse POSIX TZ string: rule time is out of range: $str/;
  my $secs = $h * 3600 + $m * 60 + $s;
  return ($1 eq '-') ? -$secs : $secs;
}

sub _parse_rule {
  my ($rule_str, $time_str) = @_;

  my $time = defined $time_str ? _parse_rule_time($time_str) : 7200;

  $rule_str =~ $Rule_Rx
    or croak qq/Unable to parse POSIX TZ string: invalid rule '$rule_str'/;

  if (exists $+{month}) {
    my ($m, $w, $d) = @+{qw(month week wday)};
    ($m >= 1 && $m <= 12)
      or croak qq/Unable to parse POSIX TZ string: rule month out of range [1, 12]: $m/;
    my $nth = ($w == 5) ? -1 : $w;
    my $dow = 1 + ($d + 6) % 7;
    return { type => 'M', month => $m, nth => $nth, day => $dow, time => $time };
  }
  elsif (exists $+{jday}) {
    my $jday = $+{jday};
    ($jday >= 1 && $jday <= 365)
      or croak qq/Unable to parse POSIX TZ string: Julian day out of range [1, 365]: $jday/;
    return { type => 'J', day => $jday, time => $time };
  }
  else {
    my $nday = $+{nday};
    ($nday >= 0 && $nday <= 365)
      or croak qq/Unable to parse POSIX TZ string: zero-based day out of range [0, 365]: $nday/;
    return { type => 'N', day => $nday + 1, time => $time };
  }
}

sub _parse {
  my ($self, $str) = @_;

  $str =~ $POSIX_TZ_Rx
    or croak qq/Unable to parse POSIX TZ string: '$str'/;

  my %m = %+;

  (my $std_name = $m{std_name}) =~ s/[<>]//g;
  my $std_offset = -_parse_offset($m{std_offset});

  ($std_offset >= -86400 && $std_offset <= 86400)
    or croak qq/Unable to parse POSIX TZ string: standard offset out of range: $std_offset/;

  $self->{std_type} = [$std_offset, 0, $std_name];

  return unless defined $m{dst_name};

  (my $dst_name = $m{dst_name}) =~ s/[<>]//g;

  my $dst_offset = defined $m{dst_offset}
    ? -_parse_offset($m{dst_offset})
    : $std_offset + 3600;

  ($dst_offset >= -86400 && $dst_offset <= 86400)
    or croak qq/Unable to parse POSIX TZ string: daylight offset out of range: $dst_offset/;

  $self->{dst_type}  = [$dst_offset, 1, $dst_name];
  $self->{dst_start} = _parse_rule($m{rule_start}, $m{time_start});
  $self->{dst_end}   = _parse_rule($m{rule_end},   $m{time_end});

  # Precompute the type sequence for the 3-year transition window.
  # For a given POSIX TZ string, DST start always falls before or
  # after DST end within each year (northern vs southern hemisphere).
  # This order never changes between years, so we determine it once
  # here and reuse the fixed type array in _transitions_for_time().
  # A leap year is used to avoid day-of-year overflow with n=365 rules.
  my ($t0, $t1) = $self->_transitions_for_year(2024);
  if ($t0 <= $t1) {
    # Northern: start < end -> types alternate dst, std
    $self->{types_3y} = [$self->{std_type},
                         ($self->{dst_type}, $self->{std_type}) x 3];
  }
  else {
    # Southern: end < start -> types alternate std, dst
    $self->{types_3y} = [$self->{dst_type},
                         ($self->{std_type}, $self->{dst_type}) x 3];
  }

  # Detect whether transitions can fall outside the calendar year.
  # For each rule, compute the worst-case calendar date and check
  # whether rule_time - offset can push the UTC epoch past Jan 1.
  #
  # Forward (into next year):
  #   UTC = midnight(Dec D) + time - offset >= midnight(Jan 1)
  #      time - offset >= (32 - D) * 86400
  #
  # Backward (into previous year):
  #   UTC = midnight(Jan D) + time - offset < midnight(Jan 1)
  #      time - offset < -(D - 1) * 86400
  my $cross_year = 0;
  for my $pair (
    [$self->{dst_start}, $self->{std_type}[0]],
    [$self->{dst_end},   $self->{dst_type}[0]],
  ) {
    my ($r, $off) = @$pair;

    # Forward: rule in December pushing into next year
    my $max_day;
    if ($r->{type} eq 'M' && $r->{month} == 12) {
      $max_day = $r->{nth} == -1 ? 31 : $r->{nth} * 7;
    }
    elsif ($r->{type} ne 'M' && $r->{day} >= 359) {
      $max_day = 31;
    }
    if (defined $max_day) {
      $cross_year = 1 if $r->{time} - $off >= (32 - $max_day) * 86400;
    }

    # Backward: rule in January pushing into previous year
    my $min_day;
    if ($r->{type} eq 'M' && $r->{month} == 1) {
      $min_day = $r->{nth} == -1 ? 25 : ($r->{nth} - 1) * 7 + 1;
    }
    elsif ($r->{type} ne 'M' && $r->{day} <= 7) {
      $min_day = 1;
    }
    if (defined $min_day) {
      $cross_year = 1 if $r->{time} - $off < -($min_day - 1) * 86400;
    }

    last if $cross_year;
  }
  $self->{cross_year} = $cross_year;
}

# Resolves a transition rule to a UTC epoch for the given year.
# $offset is the UTC offset in effect before the transition (wall clock).
sub _rule_to_epoch {
  my ($self, $rule, $year, $offset) = @_;

  my ($month, $day);

  if ($rule->{type} eq 'M') {
    $month = $rule->{month};
    $day = nth_dow_in_month($year, $month, $rule->{nth}, $rule->{day});
  }
  elsif ($rule->{type} eq 'J') {
    my $doy = $rule->{day};
    $doy++ if $doy >= 60 && leap_year($year);
    ($month, $day) = yd_to_md($year, $doy);
  }
  else {
    my $doy = $rule->{day};
    $doy-- if $doy == 366 && !leap_year($year);
    ($month, $day) = yd_to_md($year, $doy);
  }

  # rule time is wall clock; subtract offset to convert to UTC
  return timegm_modern(0, 0, 0, $day, $month, $year) + $rule->{time} - $offset;
}

sub _transitions_for_year {
  my ($self, $year) = @_;

  my $t_start = $self->_rule_to_epoch(
    $self->{dst_start}, $year, $self->{std_type}[0]);
  my $t_end = $self->_rule_to_epoch(
    $self->{dst_end}, $year, $self->{dst_type}[0]);

  return ($t_start, $t_end);
}

# Returns \@times for the 3-year window around $time.
sub _transitions_window_for_year {
  my ($self, $year) = @_;

  my @times;
  for my $y ($self->{cross_year} ? ($year - 1, $year, $year + 1) : $year) {
    my ($t_start, $t_end) = $self->_transitions_for_year($y);
    if ($t_start <= $t_end) {
      push @times, $t_start, $t_end;
    }
    else {
      push @times, $t_end, $t_start;
    }
  }

  return \@times;
}

sub _transitions_for_time {
  my ($self, $time) = @_;

  my $year = gmtime_year($time);
  my $year_index = $year - 1990;
  my $cache = $self->{cache_years} //= [];
  my $times;

  if ($year_index >= 0 && $year_index < 50) {
    $times = $cache->[$year_index] //= $self->_transitions_window_for_year($year);
  }
  else {
    $times = $self->_transitions_window_for_year($year);
  }

  return ($times, $self->{types_3y});
}

sub _type_for_utc {
  my ($self, $time) = @_;

  return $self->{std_type} unless exists $self->{dst_start};

  my ($times, $types) = $self->_transitions_for_time($time);

  return $types->[ upper_bound($times, $time) ];
}

sub offset_for_utc {
  @_ == 2 or croak q/Usage: $tz->offset_for_utc($time)/;
  my ($self, $time) = @_;
  return $self->_type_for_utc($time)->[0];
}

sub type_info_for_utc {
  @_ == 2 or croak q/Usage: $tz->type_info_for_utc($time)/;
  my ($self, $time) = @_;
  return @{$self->_type_for_utc($time)};
}

sub offset_for_local {
  @_ >= 2 or croak q/Usage: $tz->offset_for_local($time, %opts)/;
  my $type = &_resolve_local;
  return $type->[0];
}

sub type_info_for_local {
  @_ >= 2 or croak q/Usage: $tz->type_info_for_local($time, %opts)/;
  my $type = &_resolve_local;
  return @$type;
}

sub _resolve_local {
  ((@_ & 1) == 0 && @_ >= 2) or croak q/Usage: $tz->offset_for_local($time, %opts)/;
  my ($self, $time, %p) = @_;

  my ($gap_policy, $overlap_policy);

  while (my ($key, $v) = each %p) {
    if ($key eq 'gap_policy') {
      (defined $v && exists $ValidPolicy{$v})
        or croak qq/Invalid policy value for the parameter 'gap_policy'/;
      $gap_policy = $v;
    }
    elsif ($key eq 'overlap_policy') {
      (defined $v && exists $ValidPolicy{$v})
        or croak qq/Invalid policy value for the parameter 'overlap_policy'/;
      $overlap_policy = $v;
    }
    else {
      croak qq/Unrecognised named parameter: '$key'/;
    }
  }

  return $self->{std_type} unless exists $self->{dst_start};

  my ($times, $types) = $self->_transitions_for_time($time);

  return $types->[0] unless @$times;

  my $result_idx = 0;

  for (my $i = 0; $i < @$times; $i++) {
    my $boundary = $time - $times->[$i];
    my $prev     = $types->[$i];
    my $next     = $types->[$i + 1];
    my $prev_off = $prev->[0];
    my $next_off = $next->[0];

    if ($prev_off < $next_off) {
      # Spring forward: gap in [prev_off, next_off)
      if ($prev_off <= $boundary && $boundary < $next_off) {
        $gap_policy //= $self->{gap_policy};
        return _apply_policy($gap_policy, $prev, $next,
          'Unable to resolve local time: non-existing time (gap)');
      }
      $result_idx = $i + 1 if $boundary >= $next_off;
    }
    elsif ($prev_off > $next_off) {
      # Fall back: overlap in [next_off, prev_off)
      if ($next_off <= $boundary && $boundary < $prev_off) {
        $overlap_policy //= $self->{overlap_policy};
        return _apply_policy($overlap_policy, $prev, $next,
          'Unable to resolve local time: ambiguous time (overlap)');
      }
      $result_idx = $i + 1 if $boundary >= $prev_off;
    }
    else {
      $result_idx = $i + 1 if $boundary >= $prev_off;
    }
  }

  return $types->[$result_idx];
}

sub _apply_policy {
  my ($policy, $prev, $next, $message) = @_;

  if    ($policy eq 'earlier') { return $prev }
  elsif ($policy eq 'later')   { return $next }
  elsif ($policy eq 'std') {
    return $prev->[1] ? $next : $prev;
  }
  elsif ($policy eq 'dst') {
    return $prev->[1] ? $prev : $next;
  }
  else {
    croak $message;
  }
}

1;
