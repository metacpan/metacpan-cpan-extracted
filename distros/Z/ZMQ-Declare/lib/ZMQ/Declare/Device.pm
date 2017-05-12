package ZMQ::Declare::Device;
{
  $ZMQ::Declare::Device::VERSION = '0.03';
}
use 5.008001;
use Moose;

use POSIX ":sys_wait_h";
use Time::HiRes qw(sleep);
use Scalar::Util ();
use Carp ();
use ZeroMQ qw(:all);

use ZMQ::Declare;
use ZMQ::Declare::Device::Runtime;
use ZMQ::Declare::ZDCF;

has 'name' => (
  is => 'rw',
  isa => 'Str',
  required => 1,
);

has 'typename' => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has 'implementation' => (
  is => 'rw',
);

has 'application' => (
  is => 'ro',
  isa => 'ZMQ::Declare::Application',
  required => 1,
  handles => [qw(spec)],
);

has '_device_tree_ref' => (
  is => 'rw',
  isa => 'HashRef',
  weak_ref => 1,
  builder => "_fetch_device_tree_ref",
  lazy => 1,
);
sub _fetch_device_tree_ref {
  my $self = shift;
  # FIXME strictly speaking, this breaks application encapsulation
  return $self->application->_app_tree_ref->{devices}{ $self->name };
}


sub run {
  my $self = shift;
  my %args = @_;

  my $callback = $self->implementation;
  Carp::croak("Need 'implementation' CODE reference to run ZMQ::Declare::Device '" . $self->name . "'")
    if not defined $callback or not ref($callback) eq 'CODE';

  if ($args{nforks} and $args{nforks} > 1) {
    $self->_fork_runtimes(\%args, $callback);
  }
  else {
    $callback->($self->make_runtime);
  }

  return ();
}

sub _fork_runtimes {
  my ($self, $args, $callback) = @_;

  my $nforks = $args->{nforks};

  my @pids;
  FORK: foreach my $i (1..$nforks) {
    my $pid = fork();
    if ($pid) { push @pids, $pid; }
    else { @pids = (); last FORK; }
  }

  if (@pids) { # parent
    my %pids = map {$_ => 1} @pids;
    while (keys %pids) {
      my $kid;
      do {
        $kid = waitpid(-1, WNOHANG);
        delete $pids{$kid} if $kid > 0;
      } while $kid > 0;
      sleep(0.1);
    }
  }
  else { # kid
    $callback->($self->make_runtime);
    exit(0);
  }
  return();
}

sub make_runtime {
  my $self = shift;
  # Note: Do not store non-weak refs to the runtime in the component.
  #       That wouldn't make a lot of sense anyway, since at least
  #       conceptually, one could have N runtime objects for the same
  #       Device.
  my $rt = ZMQ::Declare::Device::Runtime->new(device => $self);

  my $app = $self->application;
  my $cxt = $app->get_context();

  $rt->context($cxt);
  $self->_make_device_sockets($rt);

  return $rt;
}


# creates the runtime sockets
sub _make_device_sockets {
  my $self = shift;
  my $dev_runtime = shift;

  my $dev_spec = $self->_device_tree_ref;
  Carp::croak("Could not find ZDCF entry for device '".$dev_runtime->name."'")
    if not defined $dev_spec or not ref($dev_spec) eq 'HASH';

  my $cxt = $dev_runtime->context;
  my @socks;
  my $sockets = $dev_spec->{sockets} || {};
  foreach my $sockname (keys %$sockets) {
    my $sock_spec = $sockets->{$sockname};
    my $socket = $self->_setup_socket($cxt, $sock_spec);
    push @socks, [$socket, $sock_spec];
    $dev_runtime->sockets->{$sockname} = $socket;
  }

  $self->_init_sockets(\@socks, "bind");
  $self->_init_sockets(\@socks, "connect");

  return();
}

sub _setup_socket {
  my ($self, $cxt, $sock_spec) = @_;

  my $type = $sock_spec->{type};
  my $typenum = ZMQ::Declare::Types->zdcf_sock_type_to_number($type);
  my $sock = $cxt->socket($typenum);

  # FIXME figure out whether some of these options *must* be set after the connects
  my $opt = $sock_spec->{option} || {};
  foreach my $opt_name (keys %$opt) {
    my $opt_num = ZMQ::Declare::Types->zdcf_settable_sockopt_type_to_number($opt_name);
    $sock->setsockopt($opt_num, $opt->{$opt_name});
  }

  return $sock;
}

sub _init_sockets {
  my ($self, $socks, $connecttype) = @_;

  foreach my $sock_n_spec (@$socks) {
    my ($sock, $spec) = @$sock_n_spec;
    $self->_init_socket_conn($sock, $spec, $connecttype);
  }
}

sub _init_socket_conn {
  my ($self, $sock, $spec, $connecttype) = @_;

  my $conn_spec = $spec->{$connecttype};
  return if not $conn_spec;

  my @endpoints = (ref($conn_spec) eq 'ARRAY' ? @$conn_spec : $conn_spec);
  $sock->$connecttype($_) for @endpoints;
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

ZMQ::Declare::Device - A ZMQ::Declare Device object

=head1 SYNOPSIS

  use ZMQ::Declare;
  # See synopsis for ZMQ::Declare

=head1 DESCRIPTION

Instances of this class represent a single 0MQ device. With less 0MQ
jargon, that means they represent a single component of your network
of things that interact using 0MQ sockets.

You typically obtain these objects by calling the C<device> method
on a L<ZMQ::Declare::Application> object. It is important to note that a
C<ZMQ::Declare::Device> object contains B<no runtime 0MQ components
like sockets or 0MQ contexts and maintains no network connections>.
This is to say that you can create and use C<ZMQ::Declare::Device>
in an abstract, offline way.

Shit gets real once you call the C<run()> or C<make_runtime> methods
on a C<ZMQ::Declare::Device>: Those methods will (the former implicitly,
the latter explicitly) construct a C<ZMQ::Declare::Device::Runtime>
object, create a threading context, create sockets, and make connections.

The C<ZMQ::Declare::Device::Runtime> object will then hold the actual
references to the underlying 0MQ objects.

This clear split should make it easy for users to know when they are
handling live or abstract devices.

=head1 PROPERTIES

These are accessible with normal mutator methods.

=head2 name

The name of the device. This is required to be unique in a ZDCF context
and cannot be I<context>.

=head2 typename

The type of the device that's represented by the object. Types starting
with I<z> are reserved for core 0MQ devices.

The device type is optional as of ZDCF spec version 1.0.

Read-only.

=head2 implementation

The code-reference that is to be invoked by the C<run()> method of the
object. This needs to be set by the user before calling C<run()>.
The code-reference will be called by C<run()> with a
C<ZMQ::Declare::Device::Runtime> object as first argument.

=head2 application

A reference to the underlying C<ZMQ::Declare::Application> object.

Read-only.

=head1 METHODS

=head2 new

Constructor taking named arguments (see properties above).
Typically, you should obtain your C<ZMQ::Declare::Device>
objects by calling C<device($devicename)> on a
L<ZMQ::Declare::Application> object instead of using C<new()>.

=head2 run

Requires that an implementation has been set previously (see
the C<implementation> property above).

Accepts named arguments and currently only accepts the C<nforks>
option which, if it is larger or equal to two, will fork off
C<nforks> child processes before doing any further setup.
The parent will return from C<run()> after all children have
been reaped. Each child will perform the actions described below.

Calls C<make_runtime> to obtain a new L<ZMQ::Declare::Device::Runtime>.

Then, it invokes the CODE reference that is stored in the implementation
property and passes the C<ZMQ::Declare::Device::Runtime> object
as first argument.

=head2 make_runtime

Creates a L<ZMQ::Declare::Device::Runtime> object to hold a 0MQ
threading context and all 0MQ socket objects. It sets up the
context, creates the sockets, configures the sockets, binds
the sockets to bind-endpoints, then finally connects the sockets to
connect-endpoints.

Returns the Runtime object. Once that object goes out of scope, all
connections will be disconnected.

=head1 SEE ALSO

L<ZeroMQ>

L<ZMQ::Declare>,
L<ZMQ::Declare::Device::Runtime>,
L<ZMQ::Declare::Application>

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011,2012 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
