package WL::Base;

=head1 NAME

WL::Base - Base class for Wayland objects

=head1 SYNOPSIS

  # Obtain an object instance
  my $display = $conn->get_display ();

  # Attach callbacks for events
  $display->{'WL::wl_display::error'} = sub {
      my ($self, $object, $code, $message) = @_;
      die $message;
  };

  # Issue a request
  my $registry = $display->get_registry ();

  # Rebless to attach event handlers
  bless $registry, 'MyRegistry';

  package MyRegistry;
  use base qw/WL::wl_registry/;

  # Implementation of an event handler
  sub global
  {
      my ($self, $id, $class, $version) = @_;
      warn "Object $id is of class $class version $version";
  }

=head1 DESCRIPTION

B<WL::Base> is a base class for Wayland protocol objects. It provides support
routines for common Wayland object actions and helper routines. It should not
be used directly.

Please consider this an alpha quality code, whose API can change at any time,
until we reach version 1.0.

=cut

use strict;
use warnings;

=head1 METHODS

=over 4

=item B<new> CONNECTION [ID]

Create a new object instance. This should not be used directly, as
L<WL::Connection> creates objects whenever needed.

First argument is the L<WL::Connection> instance while second, optional is the
object number. It only makes sense for remote objects, local objects get their
number allocated automatically.

=cut

sub new
{
	my $class = shift;
	my $conn = shift;
	my $id = shift;

	my $self = {};

	if ($id) {
		# Remote object
		$self->{id} = $id;
	} else {
		# New local object, allocate id
		push @{$conn->{objs}}, $self;
		$self->{id} = scalar @{$conn->{objs}} - 1;
	}
	$self->{conn} = $conn;

	return bless $self, $class;
}


=item B<call> OPCODE PAYLOAD [FILE]

Send a request. The payload is already serialized request body without opcode
and size part.

Optional file is an open file handle that would get passed with the request as
anciliary data.

=cut

sub call
{
	my $self = shift;
	my $opcode = shift;
	my $payload = shift;
	my $file = shift;

	my $conn = $self->{conn};
	my $id = $self->{id};
	$conn->send_request ($id, $opcode, $payload, $file);
}

=item B<AUTOLOAD> [...]

If an attempt was made to call a method that does not exist (this happend upon
event receipt), autoloader dispatches to a function reference if a property
named like the event exists.

This makes it possible to attach event handlers without subclassing (it is
still possible to implement event handlers in subclasses though).

=cut

our $AUTOLOAD;
sub AUTOLOAD
{
	my $self = shift;
	die "No $AUTOLOAD" unless exists $self->{$AUTOLOAD};
	$self->{$AUTOLOAD}($self, @_);
}

=back

=head1 FUNCTIONS

=over 4

=item B<nv2fixed> NUMBER

This is a helper routine that serializes a Perl numeric value to a Wayland 24.8
fixed format number.

=cut

sub nv2fixed
{
	my $nv = shift;

	my $sign = $nv < 0;
	my $whole = abs(int($nv)) & 0x7fffff;
	my $decimal = abs($nv-int($nv)) * 1000;
	$decimal /= 10 if $decimal > 0xff;

	return $sign << 31 | $whole << 8 | $decimal
}

=item B<fixed2nv> FIXED

This is a helper routine that deserializes a Wayland 24.8 fixed format number
to a Perl numeric value.

=cut

sub fixed2nv
{
	my $fixed = shift;

	sprintf ("%s%d.%d", $fixed & 0x80000000 ? '-' : '',
		$fixed >> 8 & 0x7fffff, $fixed & 0xff);
}

=back

=head1 SEE ALSO

=over

=item *

L<http://wayland.freedesktop.org/> -- Wayland project web site

=item *

L<WL::Connection> -- Estabilish a Wayland connection

=back

=head1 COPYRIGHT

Copyright 2013 Lubomir Rintel

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHORS

Lubomir Rintel C<lkundrak@v3.sk>

=cut

1;
