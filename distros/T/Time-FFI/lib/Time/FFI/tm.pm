package Time::FFI::tm;

use strict;
use warnings;
use Carp ();
use FFI::Platypus::Record ();
use Module::Runtime ();
use Time::Local ();

our $VERSION = '2.002';

my @tm_members = qw(sec min hour mday mon year wday yday isdst);

FFI::Platypus::Record::record_layout_1(
  (map { (int => $_) } @tm_members),
  long   => 'gmtoff',
  string => 'zone',
);

{
  no strict 'refs';
  *{"tm_$_"} = \&$_ for @tm_members, 'gmtoff', 'zone';
}

sub from_list {
  my ($class, @args) = @_;
  my %attr = map { ($tm_members[$_] => $args[$_]) } 0..$#tm_members;
  return $class->new(\%attr);
}

sub from_object {
  my ($class, $obj) = @_;
  if ($obj->isa('Time::Piece')) {
    return $class->new(
      year  => $obj->year - 1900,
      mon   => $obj->mon - 1,
      mday  => $obj->mday,
      hour  => $obj->hour,
      min   => $obj->min,
      sec   => $obj->sec,
      isdst => -1,
    );
  } elsif ($obj->isa('Time::Moment')) {
    return $class->new(
      year  => $obj->year - 1900,
      mon   => $obj->month - 1,
      mday  => $obj->day_of_month,
      hour  => $obj->hour,
      min   => $obj->minute,
      sec   => $obj->second,
      isdst => -1,
    );
  } elsif ($obj->isa('DateTime')) {
    return $class->new(
      year  => $obj->year - 1900,
      mon   => $obj->month - 1,
      mday  => $obj->day,
      hour  => $obj->hour,
      min   => $obj->minute,
      sec   => $obj->second,
      isdst => -1,
    );
  } elsif ($obj->isa('Time::FFI::tm') or $obj->isa('Time::tm')) {
    my %attr = map { ($_ => $obj->$_) } qw(sec min hour mday mon year wday yday isdst);
    return $class->new(\%attr);
  } else {
    my $class = ref $obj;
    Carp::croak "Cannot convert from unrecognized object class $class";
  }
}

sub to_list {
  my ($self) = @_;
  return map { $self->$_ } @tm_members;
}

sub to_object {
  Carp::carp '->to_object is deprecated; use ->to_object_as_local or ->to_object_as_utc';
  return _to_object(@_);
}

sub to_object_as_local {
  my ($self, $class) = @_;
  return _to_object($self, $class, 1);
}

sub to_object_as_utc {
  my ($self, $class) = @_;
  return _to_object($self, $class, 0);
}

sub _to_object {
  my ($self, $class, $islocal) = @_;
  Module::Runtime::require_module $class;
  if ($class->isa('Time::Piece')) {
    my ($epoch) = $islocal ? _mktime($self) : _timegm($self);
    return $islocal ? scalar $class->localtime($epoch) : scalar $class->gmtime($epoch);
  } elsif ($class->isa('Time::Moment')) {
    my $tm = $self;
    my $epoch;
    ($epoch, $tm) = _mktime($self) if $islocal;
    my $moment = $class->new(
      year   => $tm->year + 1900,
      month  => $tm->mon + 1,
      day    => $tm->mday,
      hour   => $tm->hour,
      minute => $tm->min,
      second => $tm->sec,
    );
    return $islocal ? $moment->with_offset_same_local(($moment->epoch - $epoch) / 60) : $moment;
  } elsif ($class->isa('DateTime')) {
    my $tm = $self;
    (undef, $tm) = _mktime($self) if $islocal;
    return $class->new(
      year   => $tm->year + 1900,
      month  => $tm->mon + 1,
      day    => $tm->mday,
      hour   => $tm->hour,
      minute => $tm->min,
      second => $tm->sec,
      time_zone => $islocal ? 'local' : 'UTC',
    );
  } elsif ($class->isa('Time::FFI::tm') or $class->isa('Time::tm')) {
    my %attr = map { ($_ => $self->$_) } qw(sec min hour mday mon year wday yday isdst);
    return $class->new(%attr);
  } else {
    Carp::croak "Cannot convert to unrecognized object class $class";
  }
}

sub epoch {
  my ($self, $islocal) = @_;
  Carp::carp '->epoch is deprecated; use ->epoch_as_local or ->epoch_as_utc';
  my ($epoch) = $islocal ? _mktime($self) : _timegm($self);
  return $epoch;
}

sub epoch_as_local {
  my ($self) = @_;
  my ($epoch) = _mktime($self);
  return $epoch;
}

sub epoch_as_utc {
  my ($self) = @_;
  my ($epoch) = _timegm($self);
  return $epoch;
}

sub normalized {
  my ($self, $islocal) = @_;
  Carp::carp '->normalized is deprecated; use ->normalized_as_local or ->normalized_as_utc';
  return $islocal ? $self->normalized_as_local : $self->normalized_as_utc;
}
*with_extra = \&normalized;

sub normalized_as_local {
  my ($self) = @_;
  my (undef, $new) = _mktime($self);
  return $new;
}

sub normalized_as_utc {
  my ($self) = @_;
  my ($epoch) = _timegm($self);
  require Time::FFI;
  my $new = Time::FFI::gmtime($epoch);
  bless $new, ref $self;
  return $new;
}

sub _mktime {
  my ($self) = @_;
  require Time::FFI;
  my %attr = map { ($_ => $self->$_) } qw(sec min hour mday mon year);
  $attr{isdst} = -1;
  my $new = (ref $self)->new(\%attr);
  return (Time::FFI::mktime($new), $new);
}

sub _timegm {
  my ($self) = @_;
  my $year = $self->year;
  $year += 1900 if $year >= 0; # avoid timegm year heuristic
  my @vals = ((map { $self->$_ } qw(sec min hour mday mon)), $year);
  return scalar Time::Local::timegm(@vals);
}

1;

=head1 NAME

Time::FFI::tm - POSIX tm record structure

=head1 SYNOPSIS

  use Time::FFI::tm;

  my $tm = Time::FFI::tm->new(
    year  => 95, # years since 1900
    mon   => 0,  # 0 == January
    mday  => 1,
    hour  => 13,
    min   => 25,
    sec   => 59,
    isdst => -1, # allow DST status to be determined by the system
  );
  $tm->mday($tm->mday + 1); # add a day

  my $in_local = $tm->normalized_as_local;
  say $in_local->isdst; # now knows if DST is active

  my $tm = Time::FFI::tm->from_list(CORE::localtime(time));

  my $epoch = POSIX::mktime($tm->to_list);
  my $epoch = $tm->epoch_as_local;

  my $tm = Time::FFI::tm->from_object(Time::Moment->now);
  my $datetime = $tm->to_object_as_local('DateTime');

=head1 DESCRIPTION

This L<FFI::Platypus::Record> class represents the C<tm> struct defined by
F<time.h> and used by functions such as L<mktime(3)> and L<strptime(3)>. This
is used by L<Time::FFI> to provide access to such structures.

The structure does not store an explicit time zone, so you must specify whether
to interpret it as local or UTC time whenever rendering it to an actual
datetime.

=head1 ATTRIBUTES

The integer components of the C<tm> struct are stored as settable attributes
that default to 0.

Note that 0 is out of the standard range for the C<mday> value (often
indicating the last day of the previous month), and C<isdst> should be set to a
negative value if unknown, so these values should always be specified
explicitly.

Each attribute also has a corresponding alias starting with C<tm_> to match the
standard C<tm> struct member names.

=head2 sec

Seconds [0,60].

=head2 min

Minutes [0,59].

=head2 hour

Hour [0,23].

=head2 mday

Day of month [1,31].

=head2 mon

Month of year [0,11].

=head2 year

Years since 1900.

=head2 wday

Day of week [0,6] (Sunday =0).

=head2 yday

Day of year [0,365].

=head2 isdst

Daylight Savings flag. (0: off, positive: on, negative: unknown)

=head2 gmtoff

Seconds east of UTC. (May not be available on all systems)

=head2 zone

Timezone abbreviation. (Read only string, may not be available on all systems)

=head1 METHODS

=head2 new

  my $tm = Time::FFI::tm->new;
  my $tm = Time::FFI::tm->new(year => $year, ...);
  my $tm = Time::FFI::tm->new({year => $year, ...});

Construct a new B<Time::FFI::tm> object representing a C<tm> struct.

=head2 from_list

  my $tm = Time::FFI::tm->from_list($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);

Construct a new B<Time::FFI::tm> object from the passed list of time
attributes, in the same order returned by L<perlfunc/localtime>. Missing or
undefined values will be interpreted as the default of 0, but see
L</ATTRIBUTES>.

=head2 from_object

  my $tm = Time::FFI::tm->from_object($obj);

I<Current API since version 2.000.>

Construct a new B<Time::FFI::tm> object from the passed datetime object's local
datetime components. Currently L<Time::Piece>, L<Time::Moment>, L<DateTime>,
L<Time::tm>, and L<Time::FFI::tm> objects (and subclasses) are recognized. The
original time zone and any fractional seconds will not be represented in the
resulting structure.

=head2 to_list

  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = $tm->to_list;

Return the list of time attributes in the structure, in the same order returned
by L<perlfunc/localtime>.

=head2 to_object_as_local

=head2 to_object_as_utc

  my $piece    = $tm->to_object_as_local('Time::Piece');
  my $moment   = $tm->to_object_as_utc('Time::Moment');

I<Since version 2.002.>

Return an object of the specified class. Currently L<Time::Piece>,
L<Time::Moment>, and L<DateTime> (or subclasses) are recognized. Depending on
the method called, the time attributes are interpreted in the local time zone
or in UTC.

When interpreted as a local time, values outside the standard ranges are
accepted; this is not currently supported for UTC times.

You may also specify L<Time::tm> or L<Time::FFI::tm> (or subclasses), in which
case C<to_object_as_local> and C<to_object_as_utc> produce the same result with
the time attributes copied as-is.

=head2 epoch_as_local

=head2 epoch_as_utc

  my $epoch = $tm->epoch_as_local;
  my $epoch = $tm->epoch_as_utc

I<Since version 2.002.>

Translate the time structure into a Unix epoch timestamp (seconds since
1970-01-01 UTC). Depending on the method called, the time attributes are
interpreted in the local time zone or in UTC.

When interpreted as a local time, values outside the standard ranges are
accepted; this is not currently supported for UTC times.

=head2 normalized_as_local

=head2 normalized_as_utc

  my $new = $tm->normalized_as_local;
  my $new = $tm->normalized_as_utc;

I<Since version 2.002.>

Return a new B<Time::FFI::tm> object representing the same time, but with
C<wday>, C<yday>, C<isdst>, and (if supported) C<gmtoff> and C<zone> set
appropriately. Depending on the method called, the time attributes are
interpreted in the local time zone or in UTC.

When interpreted as a local time, values outside the standard ranges will also
be normalized; this is not currently supported for UTC times.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Time::FFI>, L<Time::tm>

=for Pod::Coverage with_extra to_object epoch normalized tm_sec tm_min tm_hour tm_mday tm_mon tm_year tm_wday tm_yday tm_isdst tm_gmtoff tm_zone
