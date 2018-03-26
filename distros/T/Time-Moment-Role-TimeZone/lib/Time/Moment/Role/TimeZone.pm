package Time::Moment::Role::TimeZone;

use Role::Tiny;
use Carp ();

our $VERSION = '0.001';

requires qw(with_offset_same_instant with_offset_same_local
  utc_rd_as_seconds utc_rd_values local_rd_as_seconds local_rd_values utc_year);

sub with_time_zone_offset_same_instant {
  my ($self, $tz) = @_;
  Carp::croak "Unknown time zone object $tz" unless defined $tz and $tz->can('offset_for_datetime');
  return $self->with_offset_same_instant($tz->offset_for_datetime($self) / 60);
}

sub with_time_zone_offset_same_local {
  my ($self, $tz) = @_;
  Carp::croak "Unknown time zone object $tz" unless defined $tz and $tz->can('offset_for_local_datetime');
  return $self->with_offset_same_local($tz->offset_for_local_datetime($self) / 60);
}

1;

=head1 NAME

Time::Moment::Role::TimeZone - Adjust Time::Moment with time zone objects

=head1 SYNOPSIS

  use Role::Tiny ();
  use DateTime::TimeZone;

  my $tz = DateTime::TimeZone->new(name => 'America/New_York');
  my $class = Role::Tiny->create_class_with_roles('Time::Moment', 'Time::Moment::Role::TimeZone');
  my $tm = $class->from_epoch(1000212360)->with_time_zone_offset_same_instant($tz);

  use Time::Moment;
  use Role::Tiny ();
  use DateTime::TimeZone::Olson 'olson_tz';

  my $tz = olson_tz('Europe/Oslo');
  my $tm = Time::Moment->new(year => 2012, month => 3, day => 4, hour => 13, minute => 7, second => 42);
  Role::Tiny->apply_roles_to_object($tm, 'Time::Moment::Role::TimeZone');
  $tm = $tm->with_time_zone_offset_same_local($tz);

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

=head1 CAVEATS

L<Time::Moment> does not store a time zone; these methods only set the offset
and local time for the instantaneous moment represented by the object. After
doing date math with the object, new times may need to be corrected, based on
whether the date math was intended to be done relative to the absolute or local
time.

  my $tm = $class->now->with_time_zone_offset_same_instant($tz); # now in $tz
  my $next_day = $tm->plus_days(1)->with_time_zone_offset_same_local($tz); # 1 day from now in $tz
  my $24h_later = $tm->plus_days(1)->with_time_zone_offset_same_instant($tz); # 86400 seconds from now in $tz

Note that C<with_time_zone_offset_same_local> may throw an exception here if
the new local time does not exist in that time zone (e.g. between 2 and 3 AM on
the start of Daylight Savings Time).

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Time::Moment>, L<DateTime::TimeZone>, L<DateTime::TimeZone::Olson>
