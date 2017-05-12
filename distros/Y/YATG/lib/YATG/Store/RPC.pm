package YATG::Store::RPC;
{
  $YATG::Store::RPC::VERSION = '5.140510';
}

use strict;
use warnings FATAL => 'all';

use RPC::Serialized::Client::INET;

sub store {
    my $config = shift;

    my $server = $config->{rpc_serialized_client_inet}
                    ->{'io_socket_inet'}->{'PeerAddr'};
    print "Connecting to storage server at [$server]\n" if
        $ENV{YATG_DEBUG} || $config->{yatg}->{debug};

    # get connection to RPC server
    my $yc = eval {
        RPC::Serialized::Client::INET->new(
            $config->{rpc_serialized_client_inet}
        )
    } or die "yatg: FATAL: storage server at [$server] failed: $@\n";

    # send results
    eval { $yc->yatg_store($config, @_) } or warn $@;
}

1;

# ABSTRACT: Back-end module to store polled data over the network


__END__
=pod

=head1 NAME

YATG::Store::RPC - Back-end module to store polled data over the network

=head1 VERSION

version 5.140510

=head1 DESCRIPTION

This module implements part of a callback handler used to store SNMP data to
disk on a remote networked host.

There is not a lot to describe - it's a very lightweight call which throws
data to an instance of L<YATG::Store::Disk> on another system, so read the
manual page for that module for more information.

You must of course configure C<yatg_updater> with the location of the RPC
service (see below).

Also see L<RPC::Serialized::Handler::YATG::Store> for guidance on setting up
the remote RPC server.

The parameter signature for the C<store> subroutine is the same as that for
C<YATG::Store::Disk::store()>.

=head1 CONFIGURATION

In the main C<yatg_updater> configuration, you need to specify the location of
the remote RPC service. Follow the example in the bundled C<yatg.yml> example
file.

You can also override some default settings of L<RPC::Serialized>. For
instance the default serializer is set to L<YAML::Syck> so to change that try:

 rpc_serialized_client_inet:
    data_serializer:
        serializer: 'JSON::Syck'

=head1 SEE ALSO

=over 4

=item L<RPC::Serialized>

=back

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

