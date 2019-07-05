package Time::Moment::Role::TimeZone;

use Role::Tiny;
use Carp ();
use Time::Local ();

our $VERSION = '0.003';

requires qw(epoch offset with_offset_same_instant with_offset_same_local
  utc_rd_as_seconds utc_rd_values local_rd_as_seconds local_rd_values utc_year);

sub with_time_zone_offset_same_instant {
  my ($self, $tz) = @_;
  Carp::croak "Invalid time zone object $tz" unless defined $tz and $tz->can('offset_for_datetime');
  return $self->with_offset_same_instant($tz->offset_for_datetime($self) / 60);
}

sub with_time_zone_offset_same_local {
  my ($self, $tz) = @_;
  Carp::croak "Invalid time zone object $tz" unless defined $tz and $tz->can('offset_for_local_datetime');
  my ($offset, $error);
  { local $@;
    unless (eval { $offset = $tz->offset_for_local_datetime($self); 1 }) {
      $error = $@ || 'Error';
    }
  }
  Carp::croak $error if defined $error;
  return $self->with_offset_same_local($offset / 60);
}

sub with_system_offset_same_instant {
  my ($self) = @_;
  my $time = $self->epoch;
  my @localtime = localtime $time;
  $localtime[5] += 1900 if $localtime[5] >= 0; # avoid timegm year heuristic
  my $offset = Time::Local::timegm_nocheck(@localtime) - $time;
  return $self->with_offset_same_instant($offset / 60);
}

sub with_system_offset_same_local {
  my ($self) = @_;
  my $time = $self->epoch + $self->offset * 60;
  my @gmtime = gmtime $time;
  $gmtime[5] += 1900 if $gmtime[5] >= 0; # avoid timelocal year heuristic
  my $offset = $time - Time::Local::timelocal_nocheck(@gmtime);
  return $self->with_offset_same_local($offset / 60);
}

1;

=head1 NAME

Time::Moment::Role::TimeZone - Adjust Time::Moment with time zone objects

=head1 SYNOPSIS

  use Time::Moment;
  use Role::Tiny ();
  use DateTime::TimeZone;

  my $class = Role::Tiny->create_class_with_roles('Time::Moment', 'Time::Moment::Role::TimeZone');

  my $tz = DateTime::TimeZone->new(name => 'America/New_York');
  my $tm = $class->from_epoch(1000212360)->with_time_zone_offset_same_instant($tz);

  use DateTime::TimeZone::Olson 'olson_tz';

  my $tz = olson_tz('Europe/Oslo');
  my $tm = Time::Moment->new(year => 2012, month => 3, day => 4, hour => 13, minute => 7, second => 42);
  Role::Tiny->apply_roles_to_object($tm, 'Time::Moment::Role::TimeZone');
  $tm = $tm->with_time_zone_offset_same_local($tz);

  my $tm = $class->from_epoch(1522095272)->with_system_offset_same_instant;

  my $tm = $class->new_from_string('2009-05-02T12:15:30Z')->with_system_offset_same_local;

=head1 DESCRIPTION

This role provides convenience methods to return a new L<Time::Moment> object
adjusted according to a L<DateTime::TimeZone>/
L<::Tzfile|DateTime::TimeZone::Tzfile>-compatible time zone object, as in
L<Time::Moment/"TIME ZONES">. See L</"CAVEATS"> regarding usage with date math.

=head1 METHODS

=head2 with_time_zone_offset_same_instant

  my $same_instant = $tm->with_time_zone_offset_same_instant($tz);

Returns a L<Time::Moment> of the same instant, but at an offset from UTC
according to the given time zone object at that instant.

=head2 with_time_zone_offset_same_local

  my $same_local = $tm->with_time_zone_offset_same_local($tz);

Returns a L<Time::Moment> of the same local time, with an offset from UTC
according to the given time zone object at that local time.

If the local time of the L<Time::Moment> object is ambiguous in the given time
zone (such as when Daylight Savings Time ends), the time zone object will
usually use the earliest time. If the local time does not exist (such as when
Daylight Savings Time starts), the time zone object will usually throw an
exception.

=head2 with_system_offset_same_instant

  my $same_instant = $tm->with_system_offset_same_instant;

As in L</"with_time_zone_offset_same_instant">, but using the system local time
zone via L<perlfunc/"localtime">.

=head2 with_system_offset_same_local

  my $same_local = $tm->with_system_offset_same_local;

As in L</"with_time_zone_offset_same_local">, but using the system local time
zone via L<Time::Local/"timelocal">.

If the local time of the L<Time::Moment> object is ambiguous in the system
local time zone (such as when Daylight Savings Time ends), L<Time::Local> will
use the earliest time. If the local time does not exist (such as when Daylight
Savings Time starts), L<Time::Local> will use the time one hour later.

=head1 CAVEATS

L<Time::Moment> does not store a time zone; these methods only set the offset
and local time for the instantaneous moment represented by the object. After
doing date math with the object, new times may need to be corrected, based on
whether the date math was intended to be done relative to the absolute or local
time.

  my $tm = $class->now_utc->with_time_zone_offset_same_instant($tz); # now in $tz
  my $next_day = $tm->plus_days(1)->with_time_zone_offset_same_local($tz); # 1 day from now in $tz
  my $24h_later = $tm->plus_days(1)->with_time_zone_offset_same_instant($tz); # 24 hours from now in $tz

  my $tm = $class->now; # now in system local time
  my $next_day = $tm->plus_days(1)->with_system_offset_same_local; # 1 day from now in system local time
  my $24h_later = $tm->plus_days(1)->with_system_offset_same_instant; # 24 hours from now in system local time

Note that L</"with_time_zone_offset_same_local"> may throw an exception here if
the new local time does not exist in that time zone (e.g. between 2 and 3 AM at
the start of Daylight Savings Time).

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 CONTRIBUTORS

=over

=item Christian Hansen (chansen)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Time::Moment>, L<DateTime::TimeZone>, L<DateTime::TimeZone::Olson>
