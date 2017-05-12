package ZMQ::Declare::Device::Runtime;
{
  $ZMQ::Declare::Device::Runtime::VERSION = '0.03';
}
use 5.008001;
use Moose;

use Scalar::Util ();
use Carp ();
use ZeroMQ qw(:all);

use ZMQ::Declare;
use ZMQ::Declare::Device;

# "declare-time" progenitor
has 'device' => (
  is => 'rw',
  isa => 'ZMQ::Declare::Device',
  required => 1,
  handles => [qw(name)],
);

has 'sockets' => (
  is => 'ro',
  isa => 'HashRef[ZeroMQ::Socket]',
  default => sub {{}},
);

has 'context' => (
  is => 'rw',
  isa => 'ZeroMQ::Context',
);

sub get_socket_by_name {
  my $self = shift;
  my $name = shift;
  my $sock = $self->sockets->{$name};
  Carp::croak("Cannot find socket for name '$name'")
    if not defined $sock;
  return $sock;
}


no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

ZMQ::Declare::Device::Runtime - The runtime pitch on a ZMQ::Declare Device object

=head1 SYNOPSIS

  use ZMQ::Declare;
  ... see ZMQ::Declare and ZMQ::Declare::ZDCF ...
  my $runtime = $device->make_runtime;
  # or:
  $device->implementation(\&main_loop);
  $device->run;
  
  sub main_loop {
    my ($runtime) = @_;
    my $in_sock = $runtime->get_socket_by_name("listener");
    my $out_sock = $runtime->get_socket_by_name("distributor");

    while (...) {...} # actual main loop
  }

=head1 DESCRIPTION

This object represents a full set of run-time 0MQ objects for a 0MQ
device. It contains a 0MQ threading context and 0MQ sockets that are
bound or connected to their endpoints.

Try not to share this across forks, see the C<nforks> option to the C<run()>
method of a C<ZMQ::Declare::Device>.

While there's a constructor, the typical way to obtain a runtime device
object is to call the C<run()> or C<make_runtime()> methods on an
abstract L<ZMQ::Declare::Device>.

=head1 INSTANCE PROPERTIES

=head2 device

Each C<ZMQ::Declare::Device::Runtime> object holds a reference to
its generating C<ZMQ::Declare::Device>, its abstract, declare-time
progenitor, so to speak.

=head2 context

The threading context for this runtime.

=head2 sockets

A hashref of socket names to L<ZeroMQ::Socket> objects.
See also: C<get_socket_by_name()>

=head1 METHODS

=head2 new

Constructor taking named parameters. See C<ZMQ::Declare::Device::run()>
and C<ZMQ::Declare::Device::make_runtime()> instead.

=head2 get_socket_by_name

Takes a socket name as first argument. Returns the socket of
that name or throws and exception if it doesn't exist.

=head1 SEE ALSO

L<ZMQ::Declare>, L<ZMQ::Declare::Device>

L<ZeroMQ>

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011,2012 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
