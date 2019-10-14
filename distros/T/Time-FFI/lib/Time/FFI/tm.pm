package Time::FFI::tm;

use strict;
use warnings;
use Carp ();
use FFI::Platypus::Record ();
use Module::Runtime ();
use Time::Local ();

our $VERSION = '1.004';

my @tm_members = qw(tm_sec tm_min tm_hour tm_mday tm_mon tm_year tm_wday tm_yday tm_isdst);

FFI::Platypus::Record::record_layout(
  (map { (int => $_) } @tm_members),
  long   => 'tm_gmtoff',
  string => 'tm_zone',
);

sub from_list {
  my ($class, @args) = @_;
  my %attr = map { ($tm_members[$_] => $args[$_]) } 0..$#tm_members;
  return $class->new(\%attr);
}

sub from_object {
  my ($class, $obj, $islocal) = @_;
  require Time::FFI;
  if ($obj->can('epoch')) {
    return $islocal ? Time::FFI::localtime($obj->epoch) : Time::FFI::gmtime($obj->epoch);
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
  my ($self, $class, $islocal) = @_;
  Module::Runtime::require_module $class;
  my ($epoch, $new) = $self->_mktime($islocal);
  if ($class->isa('Time::Piece')) {
    return $islocal ? scalar $class->localtime($epoch) : scalar $class->gmtime($epoch);
  } elsif ($class->isa('Time::Moment')) {
    my $moment = $class->new(
      year   => $new->tm_year + 1900,
      month  => $new->tm_mon + 1,
      day    => $new->tm_mday,
      hour   => $new->tm_hour,
      minute => $new->tm_min,
      second => $new->tm_sec,
    );
    return $islocal ? $moment->with_offset_same_local(($moment->epoch - $epoch) / 60) : $moment;
  } elsif ($class->isa('DateTime')) {
    return $class->new(
      year   => $new->tm_year + 1900,
      month  => $new->tm_mon + 1,
      day    => $new->tm_mday,
      hour   => $new->tm_hour,
      minute => $new->tm_min,
      second => $new->tm_sec,
      time_zone => $islocal ? 'local' : 'UTC',
    );
  } else {
    Carp::croak "Cannot convert to unrecognized object class $class";
  }
}

sub epoch {
  my ($self, $islocal) = @_;
  my ($epoch, $new) = $self->_mktime($islocal);
  return $epoch;
}

sub normalized {
  my ($self, $islocal) = @_;
  my ($epoch, $new) = $self->_mktime($islocal);
  if ($islocal) {
    return $new;
  } else {
    require Time::FFI;
    return Time::FFI::gmtime($epoch);
  }
}
*with_extra = \&normalized;

sub _mktime {
  my ($self, $islocal) = @_;
  if ($islocal) {
    require Time::FFI;
    my %attr = map { ($_ => $self->$_) } qw(tm_sec tm_min tm_hour tm_mday tm_mon tm_year);
    $attr{tm_isdst} = -1;
    my $new = (ref $self)->new(\%attr);
    return (Time::FFI::mktime($new), $new);
  } else {
    my $year = $self->tm_year;
    $year += 1900 if $year >= 0; # avoid timegm year heuristic
    my @vals = ((map { $self->$_ } qw(tm_sec tm_min tm_hour tm_mday tm_mon)), $year);
    return (scalar Time::Local::timegm(@vals), $self);
  }
}

1;

=head1 NAME

Time::FFI::tm - POSIX tm record structure

=head1 SYNOPSIS

  use Time::FFI::tm;

  my $tm = Time::FFI::tm->new(
    tm_year  => 95, # years since 1900
    tm_mon   => 0,  # 0 == January
    tm_mday  => 1,
    tm_hour  => 13,
    tm_min   => 25,
    tm_sec   => 59,
    tm_isdst => -1, # allow DST status to be determined by the system
  );
  $tm->tm_mday($tm->tm_mday + 1); # add a day

  my $in_local = $tm->normalized(1);
  say $in_local->tm_isdst; # now knows if DST is active

  my $tm = Time::FFI::tm->from_list(CORE::localtime(time));

  my $epoch = POSIX::mktime($tm->to_list);
  my $epoch = $tm->epoch(1);

  my $tm = Time::FFI::tm->from_object(Time::Moment->now, 1);
  my $datetime = $tm->to_object('DateTime', 1);

=head1 DESCRIPTION

This L<FFI::Platypus::Record> class represents the C<tm> struct defined by
F<time.h> and used by functions such as L<mktime(3)> and L<strptime(3)>. This
is used by L<Time::FFI> to provide access to such structures.

The structure does not store an explicit time zone, so you must specify whether
to interpret it as local or UTC time whenever rendering it to or from an actual
date/time.

=head1 ATTRIBUTES

The integer components of the C<tm> struct are stored as settable attributes
that default to 0. Note that 0 is out of the standard range for the C<tm_mday>
value (often indicating the last day of the previous month), and C<tm_isdst>
should be set to a negative value if unknown, so these values should always be
specified explicitly.

=head2 tm_sec

Seconds [0,60].

=head2 tm_min

Minutes [0,59].

=head2 tm_hour

Hour [0,23].

=head2 tm_mday

Day of month [1,31].

=head2 tm_mon

Month of year [0,11].

=head2 tm_year

Years since 1900.

=head2 tm_wday

Day of week [0,6] (Sunday =0).

=head2 tm_yday

Day of year [0,365].

=head2 tm_isdst

Daylight Savings flag. (0: off, positive: on, negative: unknown)

=head2 tm_gmtoff

Seconds east of UTC. (May not be available on all systems)

=head2 tm_zone

Timezone abbreviation. (Read only string, may not be available on all systems)

=head1 METHODS

=head2 new

  my $tm = Time::FFI::tm->new;
  my $tm = Time::FFI::tm->new(tm_year => $year, ...);
  my $tm = Time::FFI::tm->new({tm_year => $year, ...});

Construct a new B<Time::FFI::tm> object representing a C<tm> struct.

=head2 from_list

  my $tm = Time::FFI::tm->from_list($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);

Construct a new B<Time::FFI::tm> object from the passed list of values, in the
same order returned by L<perlfunc/localtime>. Missing or undefined values will
be interpreted as the default of 0, but see L</ATTRIBUTES>.

=head2 from_object

  my $tm = Time::FFI::tm->from_object($obj, $islocal);

I<Since version 1.001>

Construct a new B<Time::FFI::tm> object from the passed datetime object, which
may be any object that implements an C<epoch> method returning the Unix epoch
timestamp. If a true value is passed as the second argument, the resulting
structure will represent the local time at that instant; otherwise it will
represent UTC. The original time zone and any fractional seconds will not be
represented in the resulting structure.

=head2 to_list

  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = $tm->to_list;

Return the list of values in the structure, in the same order returned by
L<perlfunc/localtime>.

=head2 to_object

  my $piece    = $tm->to_object('Time::Piece', $islocal);
  my $moment   = $tm->to_object('Time::Moment', $islocal);
  my $datetime = $tm->to_object('DateTime', $islocal);

Return an object of the specified class. If a true value is passed as the
second argument, the object will represent the time as interpreted in the local
time zone; otherwise it will be interpreted as UTC. Currently L<Time::Piece>,
L<Time::Moment>, and L<DateTime> (or subclasses) are recognized.

When interpreted as a local time, values outside the standard ranges are
accepted; this is not currently supported for UTC times.

=head2 epoch

  my $epoch = $tm->epoch($islocal);

I<Since version 1.000>

Translate the time structure into a Unix epoch timestamp (seconds since
1970-01-01 UTC). If a true value is passed, the timestamp will represent the
time as interpreted in the local time zone; otherwise it will be interpreted as
UTC.

When interpreted as a local time, values outside the standard ranges are
accepted; this is not currently supported for UTC times.

=head2 normalized

  my $new = $tm->normalized($islocal);

I<Since version 1.003>

Return a new B<Time::FFI::tm> object representing the same time, but with
C<tm_wday>, C<tm_yday>, C<tm_isdst>, and (if supported) C<tm_gmtoff> and
C<tm_zone> set appropriately. If a true value is passed, these values will be
set according to the time as interpreted in the local time zone; otherwise they
will be set according to the time as interpreted in UTC. Note that this does
not replace the need to pass C<$islocal> for future conversions.

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

L<Time::FFI>

=for Pod::Coverage with_extra
