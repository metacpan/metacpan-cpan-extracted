package ZMQ::Declare::Types;
{
  $ZMQ::Declare::Types::VERSION = '0.03';
}
use 5.008001;
use strict;
use warnings;

use Moose::Util::TypeConstraints;
use JSON ();
use ZeroMQ::Constants qw(:all);

my %zdcf_socket_types = (
  pub => ZMQ_PUB,
  sub => ZMQ_SUB,
  push => ZMQ_PUSH,
  pull => ZMQ_PULL,
  req => ZMQ_REQ,
  rep => ZMQ_REP,
  pair => ZMQ_PAIR,
  xreq => ZMQ_XREQ,
  xrep => ZMQ_XREP,
  router => ZMQ_XREP, # TODO rename constants?
  dealer => ZMQ_XREQ, # TODO rename constants?

  # not official, just aliases
  upstream => ZMQ_UPSTREAM,
  downstream => ZMQ_DOWNSTREAM,
);

sub zdcf_sock_type_to_number {
  my ($class, $type) = @_;
  return $zdcf_socket_types{$type};
}

enum 'ZMQDeclareSocketConnectType' => [qw(connect bind)];

my %zdcf_settable_sockopts = (
  hwm => ZMQ_HWM,
  swap => ZMQ_SWAP,
  affinity => ZMQ_AFFINITY,
  identity => ZMQ_IDENTITY,
  subscribe => ZMQ_SUBSCRIBE,
  rate => ZMQ_RATE,
  recovery_ivl => ZMQ_RECONNECT_IVL,
  mcast_loop => ZMQ_MCAST_LOOP,
  sndbuf => ZMQ_SNDBUF,
  rcvbuf => ZMQ_RCVBUF,
);

sub zdcf_settable_sockopt_type_to_number {
  my $class = shift;
  return $zdcf_settable_sockopts{shift()};
}


1;
__END__

=head1 NAME

ZMQ::Declare::Types - Type definitions for ZMQ::Declare

=head1 SYNOPSIS

  use ZMQ::Declare;

=head1 DESCRIPTION

=head1 SEE ALSO

L<ZeroMQ>

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011,2012 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
