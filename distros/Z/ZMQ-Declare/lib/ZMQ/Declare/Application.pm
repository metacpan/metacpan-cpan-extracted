package ZMQ::Declare::Application;
{
  $ZMQ::Declare::Application::VERSION = '0.03';
}
use 5.008001;
use Moose;

use Carp ();
use ZeroMQ qw(:all);

use ZMQ::Declare;
use ZMQ::Declare::ZDCF;

has 'name' => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has 'spec' => (
  is => 'ro',
  isa => 'ZMQ::Declare::ZDCF',
  required => 1,
);

has '_app_tree_ref' => (
  is => 'rw',
  isa => 'HashRef',
  weak_ref => 1,
  builder => "_fetch_app_tree_ref",
  lazy => 1,
);
sub _fetch_app_tree_ref {
  my $self = shift;
  return $self->spec->tree->{apps}{ $self->name };
}

has '_runtime_context' => (
  is => 'rw',
  isa => 'ZeroMQ::Context',
  weak_ref => 1,
);

sub device {
  my ($self, $name) = @_;

  # For convenience: default to using application name for device if none provided
  $name = $self->name if not defined $name;

  my $app_spec = $self->_app_tree_ref;
  my $dev_spec = $app_spec->{devices}{$name};
  if (not defined $dev_spec) {
    Carp::croak("Unknown device name '$name' in application '" . $self->name . "'");
  }

  my $typename = $dev_spec->{type};
  $typename = '' if not defined $typename;

  return ZMQ::Declare::Device->new(
    name => $name,
    application => $self,
    typename => $typename,
  );
}

sub device_names {
  my $self = shift;
  my $ref = $self->_app_tree_ref;
  return keys %{ $ref->{devices} };
}

# runtime context
sub get_context {
  my ($self) = @_;
  my $cxt = $self->_runtime_context;
  return $cxt if defined $cxt;

  my $app_tree = $self->_app_tree_ref;
  my $context_struct = $app_tree->{context};
  my $iothreads = defined $context_struct ? $context_struct->{iothreads} : 1;
  $cxt = ZeroMQ::Context->new($iothreads);
  $self->_runtime_context($cxt);

  return $cxt;
}



no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

ZMQ::Declare::Application - A ZMQ::Declare Application object

=head1 SYNOPSIS

  use ZMQ::Declare;
  # See synopsis for ZMQ::Declare

=head1 DESCRIPTION

A C<ZMQ::Declare::Application> object represents any number of 0MQ devices
that share the same 0MQ threading context. As such, an application conceptually
maps to a single process.

=head1 PROPERTIES

These are accessible with normal mutator methods.

=head2 name

The name of the application. This is required to be unique in a ZDCF file.

Read-only.

=head2 spec

A reference to the underlying ZDCF specification object.

Read-only.

=head1 METHODS

=head2 new

Constructor taking named arguments (see properties above).
Typically, you should obtain your C<ZMQ::Declare::Application>
objects by calling C<application($application_name)> on a
L<ZMQ::Declare::ZDCF> object instead of using C<new()>.

=head2 device

Given a device name, creates a L<ZMQ::Declare::Device> object from
the information stored in the application and returns that object.

This C<ZMQ::Declare::Device> object is what you can use to actually
implement 0MQ devices that are configured through ZDCF.
Note that creating a C<ZMQ::Declare::Device> object does B<not>
create any 0MQ contexts, sockets, or connections yet, you need
to call C<make_runtime()> or C<run()> on the device for that.

As a convenience, the device name defaults to the application name
if none is provided. This is to cater to the cases of simple
applications that have only one device that needs not have a
different name than the application itself.

=head2 device_names

Returns a list (not a reference) of device names that are known to
the application.

=head2 get_context

Creates a L<ZeroMQ::Context> object from the application and returns
it. In other words, this creates the actual threading context of
0MQ. Generally, this is called indirectly by using the C<device>
method to obtain a C<ZMQ::Declare::Device> object and then
calling the C<run> or C<make_runtime> methods on that.

Repeated calls to C<get_context> will return the same threading
context object.

=head1 SEE ALSO

L<ZeroMQ>

L<ZMQ::Declare::ZDCF>, L<ZMQ::Declare::Device>

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011,2012 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
