package VM::EC2::VPC::VpnTunnelTelemetry;

=head1 NAME

VM::EC2::VPC::TunnelTelemetry - Virtual Private Cloud VPN tunnel telemetry

=head1 SYNOPSIS

 use VM::EC2;

 my $ec2       = VM::EC2->new(...);
 my $vpn       = $ec2->describe_vpn_connections(-vpn_connection_id=>'vpn-12345678');
 my $telemetry = $vpn->vpn_telemetry;
 print $telemetry->status,"\n";

=head1 DESCRIPTION

This object represents an Amazon EC2 VPC route, and is returned by
VM::EC2->describe_vpn_connections()

=head1 METHODS

These object methods are supported:

 outsideIpAddress             -- The Internet-routable IP address of the virtual
                                 private gateway's outside interface.
 status                       -- The status of the VPN tunnel.
                                 Valid values: UP | DOWN
 lastStatusChange             -- The date and time of the last change in status.
 statusMessage                -- If an error occurs, a description of the error.
 acceptedRouteCount           -- The number of accepted routes.

The object also supports the tags() method described in
L<VM::EC2::Generic>:

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
status.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Tag>
L<VM::EC2::VPC>
L<VM::EC2::VPC::VpnConnection>

=head1 AUTHOR

Lance Kinley E<lt>lkinley@loyaltymethods.comE<gt>.

Copyright (c) 2012 Loyalty Methods, Inc.

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use base 'VM::EC2::Generic';
use VM::EC2::VPC::VpnTunnelTelemetry;
use Carp 'croak';

sub primary_id { shift->status }

sub valid_fields {
    my $self  = shift;
    return qw(outsideIpAddress status lastStatusChange statusMessage acceptedRouteCount);
}

1;

