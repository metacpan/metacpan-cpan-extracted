package Time::LeapSecond;
use strict;
use warnings;
use v5.10.1;

use Carp                qw[croak];
use Exporter            qw[import];
use List::Util          qw[min];
use Time::Str::Calendar qw[ymd_to_rdn];
use Time::Str::Token    qw[parse_month];
use Time::Str::Util     qw[upper_bound
                           find_tzdb_directory];

BEGIN {
  our $VERSION     = '0.89';
  our @EXPORT_OK   = qw[ posix_tai_offset
                         posix_to_tai
                         tai_to_posix
                         rdn_leap_correction
                         load_leapseconds_tzdb
                         load_leapseconds_iers
                         parse_leapseconds_tzdb
                         parse_leapseconds_iers ];
  our %EXPORT_TAGS = ( all => \@EXPORT_OK );
}

# TAI-UTC offset in seconds in effect before the first leap second
use constant TAI_UTC_BASE => 10;

use constant RDN_UNIX_EPOCH => 719163;      # 1970-01-01
use constant SECS_PER_DAY   => 86400;
use constant NTP_UNIX_DELTA => 2208988800;  # 1900-01-01T00:00:00Z

# Tables describing the leap second history, indexed in parallel and in
# ascending order, all populated by _load_tables() (from the system leap
# seconds file when available, otherwise from the built-in fallback below):
#
#   @DAYS        - Rata Die day number of the day that carries each leap
#                  second, used by rdn_leap_correction().
#   @TIMES       - POSIX epoch at which each leap second takes effect: the
#                  midnight immediately following the inserted (or, for a
#                  negative leap second, the removed) 23:59:xx second. Kept as
#                  plain epochs so it can be reused from XS.
#   @TAI_TIMES   - TAI epoch at which each offset step takes effect, used by
#                  tai_to_posix(). It is $TIMES[$i] plus the smaller of the
#                  two surrounding offsets: for a positive leap second that is
#                  the old offset, so the inserted 23:59:60 folds onto the
#                  preceding 23:59:59 (matching tz/TZif); for a negative one
#                  it is the new offset, leaving a gap at the removed second.
#   @OFFSETS     - cumulative TAI-UTC offset in seconds, with one more entry
#                  than @TIMES: $OFFSETS[0] is the base offset before the
#                  first leap second and $OFFSETS[$k] the offset after $k leap
#                  seconds. Indexing it by the number of leaps at or before a
#                  time (the result of upper_bound) avoids any special case
#                  for "before the first leap second". Successive entries
#                  differ by +1 (positive leap second) or -1 (negative one).
#   @CORRECTIONS - the +1/-1 change carried by each leap second, aligned with
#                  @OFFSETS: $CORRECTIONS[0] is 0 (the no-correction base) and
#                  $CORRECTIONS[$k] the change applied by the $k-th leap
#                  second, so rdn_leap_correction() can index it directly.
#

our (
  @TIMES, @OFFSETS, @CORRECTIONS, # Part of the public API
  @TAI_TIMES, @DAYS
);

# Build the leap second tables from a parsed (days, corrections) pair: @$days
# holds the Rata Die day number of each leap day in ascending order and
# @$corrections the +1/-1 change carried by each. Accumulates the running
# TAI-UTC offset (so @OFFSETS gets one more entry than @DAYS/@TIMES, with the
# base offset at index 0), derives the UTC transition epoch of each leap
# second and the TAI instant at which its offset step takes effect (the
# smaller of the surrounding offsets, so a positive leap second folds onto the
# preceding 23:59:59 as tz/TZif does), and installs all five tables. Returns
# the number of leap seconds installed.
sub _load_tables {
  my ($days, $corrections) = @_;
  my (@times, @offsets, @tai_times);
  my $offset = TAI_UTC_BASE;
  push @offsets, $offset;
  for my $i (0 .. $#$days) {
    my $prev = $offset;
    $offset += $corrections->[$i];
    my $time = ($days->[$i] + 1 - RDN_UNIX_EPOCH) * SECS_PER_DAY;
    push @times,     $time;
    push @offsets,   $offset;
    push @tai_times, $time + min($prev, $offset);
  }
  @DAYS        = @$days;
  @TIMES       = @times;
  @OFFSETS     = @offsets;
  @TAI_TIMES   = @tai_times;
  @CORRECTIONS = (0, @$corrections);
  return scalar @TIMES;
}

sub posix_tai_offset {
  @_ == 1 or croak q/Usage: posix_tai_offset(posix)/;
  my ($posix) = @_;
  return $OFFSETS[ upper_bound(\@TIMES, $posix) ];
}

sub posix_to_tai {
  @_ == 1 or croak q/Usage: posix_to_tai(posix)/;
  my ($posix) = @_;
  return $posix + posix_tai_offset($posix);
}

sub tai_to_posix {
  @_ == 1 or croak q/Usage: tai_to_posix(tai)/;
  my ($tai) = @_;
  return $tai - $OFFSETS[ upper_bound(\@TAI_TIMES, $tai) ];
}

sub rdn_leap_correction {
  @_ == 1 or croak q/Usage: rdn_leap_correction(rdn)/;
  my ($rdn) = @_;
  my $i = upper_bound(\@DAYS, $rdn);
  return $i > 0 && $DAYS[$i - 1] == $rdn ? $CORRECTIONS[$i] : 0;
}

{
  my $LeapLine_Rx = qr{
    (?(DEFINE)
      (?<MonthName> (?i: Jan|Feb|Mar|Apr|May|Jun|
                         Jul|Aug|Sep|Oct|Nov|Dec ))
      (?<Time>      [0-9]{2} [:] [0-9]{2} [:] [0-9]{2})
      (?<Sign>      [+-])
      (?<RollStat>  [RS])
    )
    \A
    Leap \s+
    (?<year>  [0-9]{4})      \s+
    (?<month> (?&MonthName)) \s+
    (?<day>   [0-9]{1,2})    \s+
    (?<time>  (?&Time))      \s+
    (?<corr>  (?&Sign))      \s+
    (?<rs>    (?&RollStat))
    \s*
    \z
  }x;

  sub parse_leapseconds_tzdb {
    @_ == 1 or croak q/Usage: parse_leapseconds_tzdb(path)/;
    my ($path) = @_;

    open(my $fh, '<', $path)
      or croak qq/Unable to parse leap seconds: could not open '$path': '$!'/;

    my (@days, @corrections);
    while (my $line = <$fh>) {
      next if $line !~ /\A Leap \b/x; # ignore other directives

      ($line =~ $LeapLine_Rx)
        or croak qq/Unable to parse leap seconds: malformed line: '$line'/;

      my $corr = $+{corr} eq '+' ? 1 : -1;

      # A positive leap second inserts 23:59:60; a negative one removes
      # 23:59:59. Anything else is not a leap second transition.
      my $expected = $corr > 0 ? '23:59:60' : '23:59:59';
      ($+{time} eq $expected)
        or croak qq/Unable to parse leap seconds: unexpected leap second time '$+{time}'/;

      my $rdn = ymd_to_rdn($+{year}, parse_month($+{month}), $+{day});
      croak qq/Unable to parse leap seconds: entries out of order at $+{year}-$+{month}-$+{day}/
        if @days && $rdn <= $days[-1];

      push @days,        $rdn;
      push @corrections, $corr;
    }
    close($fh);

    return (\@days, \@corrections);
  }
}

{
  my $IersLine_Rx = qr{
    (?(DEFINE)
      (?<Stamp>  [0-9]+)
      (?<Offset> [0-9]+)
    )
    \A \s*
    (?<ntp> (?&Stamp))  \s+
    (?<off> (?&Offset))
    \s* (?: [#] .* )? 
    \z
  }x;

  sub parse_leapseconds_iers {
    @_ == 1 or croak q/Usage: parse_leapseconds_iers(path)/;
    my ($path) = @_;

    open(my $fh, '<', $path)
      or croak qq/Unable to parse leap seconds: could not open '$path': '$!'/;

    # The IERS file lists the absolute TAI-UTC offset at each NTP epoch,
    # starting with the base row at 1972-01-01. Read in file order (which must
    # be ascending), anchor on that base row, and turn each subsequent change
    # into a +1/-1 correction on the day that carries the leap second. The base
    # row must state TAI_UTC_BASE so that reconstructing absolute offsets from
    # corrections is exact; a truncated file would not.
    my (@days, @corrections);
    my $base     = TAI_UTC_BASE;
    my $prev     = $base;
    my $prev_ntp;
    my $anchored = 0;
    while (my $line = <$fh>) {
      chomp $line;
      next if $line =~ /\A \s* (?: [#] | \z )/x;

      ($line =~ $IersLine_Rx)
        or croak qq/Unable to parse leap seconds: malformed line: '$line'/;

      my ($ntp, $off) = ($+{ntp}, $+{off});
      croak qq/Unable to parse leap seconds: entries out of order at NTP $ntp/
        if defined $prev_ntp && $ntp <= $prev_ntp;
      $prev_ntp = $ntp;

      ($ntp % SECS_PER_DAY == 0)
        or croak qq/Unable to parse leap seconds: NTP $ntp is not a UTC midnight/;

      unless ($anchored) {
        ($off == $base)
          or croak qq/Unable to parse leap seconds: table does not start at the base offset $base (got $off)/;
        $anchored = 1;
        $prev     = $off;
        next;
      }

      my $delta = $off - $prev;
      (abs($delta) == 1)
        or croak qq/Unable to parse leap seconds: unexpected offset step $delta at NTP $ntp/;

      # The leap second falls on the day before the transition midnight.
      my $rdn = int(($ntp - NTP_UNIX_DELTA) / SECS_PER_DAY) + RDN_UNIX_EPOCH - 1;
      push @days,        $rdn;
      push @corrections, $delta;
      $prev = $off;
    }
    close($fh);

    return (\@days, \@corrections);
  }
}

sub _tzdb_path {
  my $dir = find_tzdb_directory();
  return defined $dir ? "$dir/leapseconds" : undef;
}

sub _iers_path {
  my $dir = find_tzdb_directory();
  return defined $dir ? "$dir/leap-seconds.list" : undef;
}

sub load_leapseconds_tzdb {
  @_ <= 1 or croak q/Usage: load_leapseconds_tzdb([path])/;
  my ($path) = @_;

  # In auto mode (no path) a missing system file is not an error: keep the
  # built-in fallback. An explicit path, or a present-but-unreadable or
  # malformed file, propagates as an exception.
  my $explicit = defined $path;
  $path //= _tzdb_path();
  unless ($explicit) {
    return undef unless defined $path && -f $path;
  }

  my ($days, $corrections) = parse_leapseconds_tzdb($path);
  @$days
    or croak qq/Unable to parse leap seconds: no entries found in '$path'/;

  return _load_tables($days, $corrections);
}

sub load_leapseconds_iers {
  @_ <= 1 or croak q/Usage: load_leapseconds_iers([path])/;
  my ($path) = @_;

  my $explicit = defined $path;
  $path //= _iers_path();
  unless ($explicit) {
    return undef unless defined $path && -f $path;
  }

  my ($days, $corrections) = parse_leapseconds_iers($path);
  @$days
    or croak qq/Unable to parse leap seconds: no entries found in '$path'/;

  return _load_tables($days, $corrections);
}

# Populate the tables at load time. Try the system TZDB leap seconds file
# first; if it is missing, unreadable, or malformed, fall back to the
# built-in table below so that "use Time::LeapSecond" never dies. The
# fallback is the Rata Die day number of every leap second to date; every
# one has been positive (+1), and it is installed through the same
# _load_tables() path as a parsed file.
{
  my @fallback = (
    720074,  # 1972-06-30
    720258,  # 1972-12-31
    720623,  # 1973-12-31
    720988,  # 1974-12-31
    721353,  # 1975-12-31
    721719,  # 1976-12-31
    722084,  # 1977-12-31
    722449,  # 1978-12-31
    722814,  # 1979-12-31
    723361,  # 1981-06-30
    723726,  # 1982-06-30
    724091,  # 1983-06-30
    724822,  # 1985-06-30
    725736,  # 1987-12-31
    726467,  # 1989-12-31
    726832,  # 1990-12-31
    727379,  # 1992-06-30
    727744,  # 1993-06-30
    728109,  # 1994-06-30
    728658,  # 1995-12-31
    729205,  # 1997-06-30
    729754,  # 1998-12-31
    732311,  # 2005-12-31
    733407,  # 2008-12-31
    734684,  # 2012-06-30
    735779,  # 2015-06-30
    736329,  # 2016-12-31
  );
  local $@;
  unless (eval { load_leapseconds_tzdb() }) {
    _load_tables(\@fallback, [ (1) x @fallback ]);
  }
}

1;
