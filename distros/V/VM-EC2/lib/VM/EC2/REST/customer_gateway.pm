package VM::EC2::REST::customer_gateway;

use strict;
use VM::EC2 '';  # important not to import anything!
package VM::EC2;  # add methods to VM::EC2

VM::EC2::Dispatch->register(
    DescribeCustomerGateways          => 'fetch_items,customerGatewaySet,VM::EC2::VPC::CustomerGateway',
    CreateCustomerGateway             => 'fetch_one,customerGateway,VM::EC2::VPC::CustomerGateway',
    DeleteCustomerGateway             => 'boolean',
    );

my $VEP = 'VM::EC2::ParmParser';

=head1 NAME VM::EC2::REST::customer_gateway

=head1 SYNOPSIS

 use VM::EC2 ':vpc';

=head1 METHODS

These methods control customer gateways for AWS VPNs.

Implemented:
 CreateCustomerGateway
 DeleteCustomerGateway
 DescribeCustomerGateways

Unimplemented:
 (none)

=head2 @gtwys = $ec2->describe_customer_gateways(-customer_gateway_id=>\@ids,
                                                 -filter             =>\%filters)

=head2 @gtwys = $ec2->describe_customer_gateways(\@customer_gateway_ids)

=head2 @gtwys = $ec2->describe_customer_gateways(%filters)

Provides information on VPN customer gateways.

Returns a series of VM::EC2::VPC::CustomerGateway objects.

Optional parameters are:

 -customer_gateway_id    ID of the gateway(s) to return information on. 
                         This can be a string scalar, or an arrayref.

 -filter                 Tags and other filters to apply.

The filter argument is a hashreference in which the keys are the filter names,
and the values are the match strings. Some filters accept wildcards.

There are a number of filters, which are listed in full at
http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeCustomerGateways.html

Here is a alpha-sorted list of filter names: bgp-asn, customer-gateway-id, 
ip-address, state, type, tag-key, tag-value, tag:key

=cut

sub describe_customer_gateways {
    my $self = shift;
    my %args = $VEP->args(-customer_gateway_id,@_);
    my @params = $VEP->format_parms(\%args,
                                    {
                                        list_parm   => 'CustomerGatewayId',
                                        filter_parm => 'Filter',
                                    });
    return $self->call('DescribeCustomerGateways',@params);
}

=head2 $cust_gtwy = $ec2->create_customer_gateway(-type      =>$type,
                                                  -ip_address=>$ip,
                                                  -bgp_asn   =>$asn)

Provides information to AWS about a VPN customer gateway device. The customer 
gateway is the appliance at the customer end of the VPN connection (compared 
to the virtual private gateway, which is the device at the AWS side of the 
VPN connection).

Arguments:

 -ip_address     -- The IP address of the customer gateway appliance

 -bgp_asn        -- The Border Gateway Protocol (BGP) Autonomous System Number
                    (ASN) of the customer gateway

 -type           -- Optional as there is only currently (2012-06-15 API) only
                    one type (ipsec.1)

 -ip             -- Alias for -ip_address

Returns a L<VM::EC2::VPC::CustomerGateway> object on success.

=cut

sub create_customer_gateway {
    my $self = shift;
    my %args = @_;
    $args{-type} ||= 'ipsec.1';
    $args{-ip_address} ||= $args{-ip};
    $args{-ip_address} or
        croak "create_customer_gateway(): -ip_address argument missing";
    $args{-bgp_asn} or
        croak "create_customer_gateway(): -bgp_asn argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm => [qw(Type IpAddress BgpAsn)],
                                    });
    return $self->call('CreateCustomerGateway',@params);
}

=head2 $success = $ec2->delete_customer_gateway(-customer_gateway_id=>$id)

=head2 $success = $ec2->delete_customer_gateway($id)

Deletes a VPN customer gateway. You must delete the VPN connection before 
deleting the customer gateway.

Arguments:

 -customer_gateway_id     -- The ID of the customer gateway to delete

Returns true on successful deletion.

=cut

sub delete_customer_gateway {
    my $self = shift;
    my %args = $VEP->args(-customer_gateway_id,@_);
    $args{-customer_gateway_id} or
        croak "delete_customer_gateway(): -customer_gateway_id argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm => 'CustomerGatewayId',
                                    });
    return $self->call('DeleteCustomerGateway',@params);
}

=head1 SEE ALSO

L<VM::EC2>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2011 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut


1;
