package YATG::Retrieve::RPC;
{
  $YATG::Retrieve::RPC::VERSION = '5.140510';
}

use strict;
use warnings FATAL => 'all';

use RPC::Serialized::Client::INET;

sub retrieve {
    my $config = shift;

    my $server = $config->{rpc_serialized_client_inet}
                    ->{'io_socket_inet'}->{'PeerAddr'};
    print "Connecting to storage server at [$server]\n"
        if $ENV{YATG_DEBUG} || $config->{yatg}->{'debug'};

    # get connection to RPC server
    my $yc = eval {
        RPC::Serialized::Client::INET->new(
            $config->{rpc_serialized_client_inet}
        )
    } or die "yatg: FATAL: storage server at [$server] failed: $@\n";

    # get data
    eval { $yc->yatg_retrieve($config, @_) } or warn $@;
}

1;

# ABSTRACT: Retrieve a set of polled data over the network


__END__
=pod

=head1 NAME

YATG::Retrieve::RPC - Retrieve a set of polled data over the network

=head1 VERSION

version 5.140510

=head1 DESCRIPTION

You can load this module to retrieve a set of data which has previously been
stored by L<YATG::Store::Disk> or L<YATG::Store::RPC>. An implementation of
this process is given in the CGI bundled with this distribution, which
displays results of SNMP polls.

There is not a lot to describe - it's a very lightweight call which throws
data to an instance of L<YATG::Retrieve::Disk> on another system, so read the
manual page for that module for more information.

You must of course configure C<yatg_updater> with the location of the RPC
service (see below).

Also see L<RPC::Serialized::Handler::YATG::Retrieve> for guidance on setting
up the remote RPC server.

The parameter signature for the C<retrieve> subroutine is the same as that for
C<YATG::Store::Retrieve::retrieve()>.

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

