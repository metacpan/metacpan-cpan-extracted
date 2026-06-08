package Time::TZif;
use strict;
use warnings;
use v5.10;

our $VERSION = '0.90';

use Carp              qw[croak];
use Time::Str::Util   qw[range_bounds
                         upper_bound
                         valid_tzdb_timezone];
use Time::TZif::POSIX qw[];

my %ValidPolicy = (
  earlier => 1, later => 1, std => 1, dst => 1, reject => 1
);

use constant TZIF_MAGIC     => 0x545A6966;
use constant TZIF_MAX_TIMES => 2400;
use constant TZIF_MAX_TYPES => 256;
use constant TZIF_MAX_CHARS => 256;

use constant HAS_QUAD => eval { my $x = pack('q>', 0); 1 };

sub new {
  (@_ & 1 && @_ >= 3) or croak q/Usage: Time::TZif->new(path => $path)/;
  my ($class, %p) = @_;

  my (%state, $path);

  while (my ($key, $v) = each %p) {
    if ($key eq 'path') {
      $path = $v;
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

  (defined $path)
    or croak q/Parameter 'path' is required/;

  open(my $fh, '<:raw', $path)
    or croak qq/Unable to parse TZif: could not open '$path': '$!'/;

  $state{path}             = $path;
  $state{modified_time}    = (stat $fh)[9];
  $state{gap_policy}     //= 'reject';
  $state{overlap_policy} //= 'reject';

  my $self = bless \%state, $class;
  $self->_parse($fh);
  close($fh);
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

sub path {
  @_ == 1 or croak q/Usage: $tz->path()/;
  return $_[0]->{path};
}

sub modified_time {
  @_ == 1 or croak q/Usage: $tz->modified_time()/;
  return $_[0]->{modified_time};
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
    return _with($self, gap_policy => $policy, _posix_tz => undef);
  }
  return $self;
}

sub with_overlap_policy {
  @_ == 2 or croak q/Usage: $tz->with_overlap_policy($policy)/;
  my ($self, $policy) = @_;

  (defined $policy && exists $ValidPolicy{$policy})
    or croak qq/Invalid policy value/;

  if ($policy ne $self->{overlap_policy}) {
    return _with($self, overlap_policy => $policy, _posix_tz => undef);
  }
  return $self;
}

sub _posix_tz {
  my ($self) = @_;
  return $self->{_posix_tz} //= Time::TZif::POSIX->new(
    tz_string      => $self->{posix_tz},
    gap_policy     => $self->{gap_policy},
    overlap_policy => $self->{overlap_policy},
  );
}

sub _readn {
  my ($fh, $len) = @_;
  my $got = read($fh, my $buf, $len);
  (defined $got)
    or croak qq/Unable to parse TZif: could not read from filehandle: '$!'/;
  ($got == $len)
    or croak qq/Unable to parse TZif: premature end of data (got: $got, expected: $len)/;
  return $buf;
}

sub _parse {
  my ($self, $fh) = @_;

  my ($magic, $version, @counts) = unpack('N a x15 N6', _readn($fh, 44));

  ($magic == TZIF_MAGIC)
    or croak q/Unable to parse TZif: not a TZif file/;

  my ($isutcnt, $isstdcnt, $leapcnt, $timecnt, $typecnt, $charcnt) = @counts;

  if (HAS_QUAD && ($version eq '2' || $version eq '3')) {
    # Skip v1 data block
    my $v1_size = $timecnt * 4
                + $timecnt
                + $typecnt * 6
                + $charcnt
                + $leapcnt * 8
                + $isstdcnt
                + $isutcnt;

    _readn($fh, $v1_size) if $v1_size;

    # Parse v2/v3 header
    ($magic, $version, @counts) = unpack('N a x15 N6', _readn($fh, 44));

    ($magic == TZIF_MAGIC)
      or croak q/Unable to parse TZif: invalid v2\/v3 header/;

    ($isutcnt, $isstdcnt, $leapcnt, $timecnt, $typecnt, $charcnt) = @counts;

    $self->_parse_data($fh, $timecnt, $typecnt, $charcnt,
                       $leapcnt, $isstdcnt, $isutcnt, 8);

    # Read POSIX TZ string footer
    my $nl = _readn($fh, 1);
    ($nl eq "\n")
      or croak q/Unable to parse TZif: expected newline before POSIX TZ string/;

    my $posix_tz = '';
    while (1) {
      my $byte = eval { _readn($fh, 1) };
      last unless defined $byte;
      last if $byte eq "\n";
      $posix_tz .= $byte;
    }
    $self->{posix_tz} = $posix_tz if length $posix_tz;
  }
  else {
    $self->_parse_data($fh, $timecnt, $typecnt, $charcnt,
                       $leapcnt, $isstdcnt, $isutcnt, 4);
  }

  my $times = $self->{times};
  if ($self->{posix_tz} && @$times) {
    $self->{max_time_utc}   = $times->[-1];
    $self->{max_time_local} = $times->[-1] + 86400;
  }
  else {
    $self->{max_time_utc}   = ~0;
    $self->{max_time_local} = ~0;
  }
}

sub _parse_data {
  my ($self, $fh, $timecnt, $typecnt, $charcnt,
      $leapcnt, $isstdcnt, $isutcnt, $time_size) = @_;

  ($typecnt >= 1)
    or croak q/Unable to parse TZif: must have at least one type/;
  ($timecnt <= TZIF_MAX_TIMES)
    or croak qq/Unable to parse TZif: too many transitions times: $timecnt (max: @{[TZIF_MAX_TIMES]})/;
  ($typecnt <= TZIF_MAX_TYPES)
    or croak qq/Unable to parse TZif: too many type records: $typecnt (max: @{[TZIF_MAX_TYPES]})/;
  ($charcnt <= TZIF_MAX_CHARS)
    or croak qq/Unable to parse TZif: too many abbreviation characters: $charcnt (max: @{[TZIF_MAX_CHARS]})/;

  my $time_fmt = ($time_size == 8) ? 'q>' : 'l>';

  # Transition times
  my @times = unpack("(${time_fmt})*", _readn($fh, $timecnt * $time_size));

  # Transition type indices
  my @type_indices = unpack('C*', _readn($fh, $timecnt));

  foreach my $idx (@type_indices) {
    ($idx < $typecnt)
      or croak qq/Unable to parse TZif: invalid type index: $idx (max: @{[$typecnt - 1]})/;
  }

  # Type info records: 6 bytes each (offset[4] + dst[1] + abbridx[1])
  my @types;
  for (my $i = 0; $i < $typecnt; $i++) {
    my ($offset, $dst, $abbridx) = unpack 'l> C C', _readn($fh, 6);

    ($offset > -86400 && $offset < 86400)
      or croak qq/Unable to parse TZif: invalid UTC offset: $offset/;
    ($dst == 0 || $dst == 1)
      or croak qq/Unable to parse TZif: invalid DST flag: $dst/;
    ($abbridx < $charcnt)
      or croak qq/Unable to parse TZif: invalid abbreviation index: $abbridx/;

    $types[$i] = [$offset, $dst, $abbridx];
  }

  # Abbreviation characters (NUL-terminated strings)
  my $abbr_buf = _readn($fh, $charcnt);
  my %abbrs;
  {
    my $pos = 0;
    foreach my $str (split /\x00/, $abbr_buf, -1) {
      $abbrs{$pos} = $str;
      $pos += 1 + length $str;
    }
  }

  # Skip remaining: leap seconds, std/wall, ut/local indicators
  my $leap_rec_size = ($time_size == 8) ? 12 : 8;
  my $skip = $leapcnt * $leap_rec_size + $isstdcnt + $isutcnt;
  _readn($fh, $skip) if $skip;

  # Resolve abbreviation indices to strings
  foreach my $type (@types) {
    $type->[2] = $abbrs{ $type->[2] } // '';
  }

  # Find first standard (non-DST) type as the default for pre-transition times
  my $first_std = $types[0];
  foreach my $type (@types) {
    if (!$type->[1]) {
      $first_std = $type;
      last;
    }
  }

  # Build resolved type array with sentinel:
  #   types[0]   = default type (first standard type)
  #   types[i+1] = type that takes effect at transition times[i]
  my @resolved = ($first_std);
  foreach my $idx (@type_indices) {
    push @resolved, $types[$idx];
  }

  $self->{times} = \@times;
  $self->{types} = \@resolved;
}

# Internal method - not part of the public API. May change or be removed without notice.
sub _transition_times {
  @_ == 1 or croak q/Usage: $tz->_transition_times()/;
  my ($self) = @_;
  return wantarray ? @{ $self->{times} } : [ @{ $self->{times} } ];
}

sub offset_for_utc {
  @_ == 2 or croak q/Usage: $tz->offset_for_utc($time)/;
  my ($self, $time) = @_;
  if ($time <= $self->{max_time_utc}) {
    return $self->{types}[ upper_bound($self->{times}, $time) ][0];
  }
  else {
    return $self->_posix_tz->offset_for_utc($time);
  }
}

sub type_info_for_utc {
  @_ == 2 or croak q/Usage: $tz->type_info_for_utc($time)/;
  my ($self, $time) = @_;
  if ($time <= $self->{max_time_utc}) {
    my $type = $self->{types}[ upper_bound($self->{times}, $time) ];
    return @$type;
  }
  else {
    return $self->_posix_tz->type_info_for_utc($time);
  }
}

sub offset_for_local {
  @_ >= 2 or croak q/Usage: $tz->offset_for_local($time, %opts)/;
  my ($self, $time) = @_;
  if ($time > $self->{max_time_local}) {
    return shift->_posix_tz->offset_for_local(@_);
  }
  my $type = &_resolve_local;
  return $type->[0];
}

sub type_info_for_local {
  @_ >= 2 or croak q/Usage: $tz->type_info_for_local($time, %opts)/;
  my ($self, $time) = @_;
  if ($time > $self->{max_time_local}) {
    return shift->_posix_tz->type_info_for_local(@_);
  }
  my $type = &_resolve_local;
  return @$type;
}

sub _resolve_local {
  (@_ & 1) == 0 or croak q/Usage: $tz->offset_for_local($time, %opts)/;
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

  my $times = $self->{times};
  my $types = $self->{types};

  # No transitions
  return $types->[0] unless @$times;

  # Find transitions within ±24 hours of the local time.
  # Since UTC offsets are bounded by (-86400, 86400), any transition
  # that could affect this local time must fall within this range.
  my ($lo, $hi) = range_bounds($times, $time - 86400, $time + 86400);

  # No transitions nearby
  return $types->[$lo] if $lo >= $hi;

  my $result_idx = $lo;

  for (my $i = $lo; $i < $hi; $i++) {
    my $boundary = $time - $times->[$i];
    my $prev     = $types->[$i];
    my $next     = $types->[$i + 1];
    my $prev_off = $prev->[0];
    my $next_off = $next->[0];

    if ($prev_off < $next_off) {
      # Spring forward: gap in [T + prev_off, T + next_off)
      if ($prev_off <= $boundary && $boundary < $next_off) {
        $gap_policy //= $self->{gap_policy};
        return _apply_policy($gap_policy, $prev, $next,
          'Unable to resolve local time: non-existing time (gap)');
      }
      $result_idx = $i + 1 if $boundary >= $next_off;
    }
    elsif ($prev_off > $next_off) {
      # Fall back: overlap in [T + next_off, T + prev_off)
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
