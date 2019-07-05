package Time::Moment::Role::Strptime;

use Role::Tiny;
use Carp ();
use Time::Piece;

our $VERSION = '0.001';

requires 'from_object';

sub strptime {
  my ($class, $str, $format) = @_;
  my ($obj, $error);
  {
    local $@;
    eval { $obj = $class->from_object(Time::Piece->strptime($str, $format)); 1 }
      or $error = $@;
  }
  if (defined $error) {
    die $error if ref $error or $error =~ m/\n(?!\z)/;
    $error =~ s/ at .+? line [0-9]+\.\n\z//;
    Carp::croak $error;
  }
  return $obj;
}

1;

=head1 NAME

Time::Moment::Role::Strptime - strptime constructor for Time::Moment

=head1 SYNOPSIS

  use Time::Moment;
  use Role::Tiny ();

  my $class = Role::Tiny->create_class_with_roles('Time::Moment', 'Time::Moment::Role::Strptime');
  my $moment = $class->strptime('2019-06-01', '%Y-%m-%d');

=head1 DESCRIPTION

This role composes the L</strptime> method, which parses the input string
according to a L<strptime(3)> format, and constructs a L<Time::Moment> object.

By default the returned L<Time::Moment> object is in UTC (possibly adjusted
by a parsed offset); to interpret the parsed time in another time zone, you can
use L<Time::Moment::Role::TimeZone>:

  use Time::Moment;
  use Role::Tiny ();

  my $class = Role::Tiny->create_class_with_roles('Time::Moment',
    'Time::Moment::Role::Strptime', 'Time::Moment::Role::TimeZone');
  my $moment = $class->strptime($input, $format)->with_system_offset_same_local;

  use DateTime::TimeZone::Olson 'olson_tz';
  my $tz = olson_tz('America/Los_Angeles');
  my $moment = $class->strptime($input, $format)->with_time_zone_offset_same_local($tz);

=head1 METHODS

=head2 strptime

  my $moment = $class->strptime($input, $format);

Parses the input string according to the L<strptime(3)> format, and returns a
L<Time::Moment> object in UTC. Throws an exception on parsing or out-of-bounds
errors.

Currently, L<Time::Piece> is used to implement C<strptime> portably, but this
is considered an implementation detail.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Time::Moment>
