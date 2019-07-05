package Time::FFI::tm;

use strict;
use warnings;
use Carp 'croak';
use FFI::Platypus::Record;
use Module::Runtime 'require_module';
use Time::Local;

our $VERSION = '0.002';

my @tm_members = qw(tm_sec tm_min tm_hour tm_mday tm_mon tm_year tm_wday tm_yday tm_isdst);

record_layout(
  (map { (int => $_) } @tm_members),
  long   => 'tm_gmtoff',
  string => 'tm_zone',
);

sub from_list {
  my ($class, @args) = @_;
  my %attr = map { ($tm_members[$_] => $args[$_]) } 0..$#tm_members;
  return $class->new(\%attr);
}

sub to_list {
  my ($self) = @_;
  return map { $self->$_ } @tm_members;
}

sub to_object {
  my ($self, $class, $islocal) = @_;
  require_module $class;
  require Time::FFI;
  if ($class->isa('Time::Piece')) {
    if ($islocal) {
      my $epoch = Time::FFI::mktime $self;
      return $class->localtime($epoch);
    } else {
      my $year = $self->tm_year;
      $year += 1900 if $year >= 0; # avoid timegm year heuristic
      my $epoch = timegm((map { $self->$_ } qw(tm_sec tm_min tm_hour tm_mday tm_mon)), $year);
      return $class->gmtime($epoch);
    }
  } elsif ($class->isa('Time::Moment')) {
    my $moment = $class->new(
      year   => $self->tm_year + 1900,
      month  => $self->tm_mon + 1,
      day    => $self->tm_mday,
      hour   => $self->tm_hour,
      minute => $self->tm_min,
      second => $self->tm_sec,
    );
    return $moment unless $islocal;
    my $epoch = Time::FFI::mktime $self;
    return $moment->with_offset_same_local(($moment->epoch - $epoch) / 60);
  } elsif ($class->isa('DateTime')) {
    return $class->new(
      year   => $self->tm_year + 1900,
      month  => $self->tm_mon + 1,
      day    => $self->tm_mday,
      hour   => $self->tm_hour,
      minute => $self->tm_min,
      second => $self->tm_sec,
      time_zone => $islocal ? 'local' : 'UTC',
    );
  } else {
    croak "Cannot convert to unrecognized object class $class";
  }
}

1;

=head1 NAME

Time::FFI::tm - POSIX tm record structure

=head1 SYNOPSIS

  use Time::FFI::tm;

  my $tm = Time::FFI::tm->new(
    tm_year => 95, # years since 1900
    tm_mon  => 0,  # 0 == January
    tm_mday => 1,
    tm_hour => 13,
    tm_min  => 25,
    tm_sec  => 59,
  );

  my $tm = Time::FFI::tm->from_list(CORE::localtime(time));

  my $epoch = POSIX::mktime($tm->to_list);

  my $datetime = $tm->to_object('DateTime', 1);

=head1 DESCRIPTION

This L<FFI::Platypus::Record> class represents the C<tm> struct defined by
F<time.h> and used by functions such as L<mktime(3)> and L<strptime(3)>.

=head1 ATTRIBUTES

=head2 tm_sec

=head2 tm_min

=head2 tm_hour

=head2 tm_mday

=head2 tm_mon

=head2 tm_year

=head2 tm_wday

=head2 tm_yday

=head2 tm_isdst

=head2 tm_gmtoff

=head2 tm_zone

The integer components of the C<tm> struct are stored as settable attributes
that default to 0. The C<tm_gmtoff> and C<tm_zone> attributes may not be
available on all systems. The C<tm_zone> attribute is a read-only string.

=head1 METHODS

=head2 new

  my $tm = Time::FFI::tm->new;
  my $tm = Time::FFI::tm->new(tm_year => $year, ...);
  my $tm = Time::FFI::tm->new({tm_year => $year, ...});

Construct a new B<Time::FFI::tm> object representing a C<tm> struct.

=head2 from_list

  my $tm = Time::FFI::tm->from_list($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);

Construct a new B<Time::FFI::tm> object from the passed list of values, in the
same order returned by L<perlfunc/localtime>.

=head2 to_list

  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = $tm->to_list;

Return the list of values in the structure, in the same order returned by
L<perlfunc/localtime>.

=head2 to_object

  my $piece    = $tm->to_object('Time::Piece', $islocal);
  my $moment   = $tm->to_object('Time::Moment', $islocal);
  my $datetime = $tm->to_object('DateTime', $islocal);

Return an object of the specified class. If a true value is passed as the
second argument, the time will be interpreted in the local time zone; otherwise
it will be interpreted as UTC. Currently L<Time::Piece>, L<Time::Moment>, and
L<DateTime> (or subclasses) are recognized.

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
