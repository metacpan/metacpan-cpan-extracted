package VMPS::Server;
use base qw[ Net::Server::PreFork ];
use VMPS::Packet;

use warnings;
use strict;

=head1 NAME

VMPS::Server - VLAN Membership Policy Server

This package implements a VMPS server.  For more information on VMPS
itself, consult the Cisco web site:

    http://www.cisco.com/

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

    package My::VMPSServer;
    use base qw/VMPS::Server/;

    sub vmps_request{ ... }

    __PACKAGE__->run();

=head1 HANDLING REQUESTS

=head2 vmps_request()

Child modules should implement the vmps_request method.  The method should
return a VMPS::Packet response object.  The default behavior is to reject
all requests.  For more info, see L<VMPS::Packet>.

    sub vmps_request {
        my ($this, $packet, $from_ip) = @_;
        ....
        return $packet->reply(...);
    }

=cut

sub vmps_request {
    my ($this, $packet, $from_ip) = @_;
    return $packet->reject;
}

=head1 DEFAULTS

The module listens on the "vqp" port (1589/udp), on all interfaces.

=cut

sub default_values {
    return {
        port => '1589',
        host => '*',
        proto => 'udp',
    }
}

#################################################################

sub process_request {
    my $this = shift;
    my $client = $this->{server}{client}->peerhost();
    my $dgram = $this->{server}{udp_data};

    my $request = eval { VMPS::Packet->_decode($dgram) };
    if ($@)
    {
        $this->log(1, "(Request from $client) $@");
        return;
    }

    eval {
        my $reply = $this->vmps_request($request, $client);

        $reply = $request->reject
            unless ($reply and UNIVERSAL::isa($reply, 'VMPS::Packet'));

        my $reply_pkt = $reply->_encode;
        $this->{server}{client}->send($reply_pkt);
    };
    if ($@)
    {
        $this->log(1, "(Reply to $client) $@");
        return;
    }
}

#################################################################

=head1 CUSTOMIZING

This module inherits its behavior from L<Net::Server>.  Sub-classes may
implement any of the hooks/arguments from Net::Server in order to
customize their behavior.  For more information, see the documentation for
L<Net::Server>.

=head1 AUTHOR

kevin brintnall, C<< <kbrint at rufus.net> >>

=head1 ACKNOWLEDGEMENTS

The packet handling code is based on VQP spec documentation from the
OpenVMPS project.  For more information, see:

    http://vmps.sourceforge.net/

=head1 COPYRIGHT & LICENSE

Copyright 2008 kevin brintnall, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of VMPS::Server
