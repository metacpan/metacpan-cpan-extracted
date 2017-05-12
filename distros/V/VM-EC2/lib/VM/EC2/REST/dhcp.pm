package VM::EC2::REST::dhcp;

use strict;
use VM::EC2 '';  # important not to import anything!
package VM::EC2;  # add methods to VM::EC2

VM::EC2::Dispatch->register(
    DescribeDhcpOptions               => 'fetch_items,dhcpOptionsSet,VM::EC2::VPC::DhcpOptions,nokey',
    CreateDhcpOptions                 => 'fetch_one,dhcpOptions,VM::EC2::VPC::DhcpOptions,nokey',
    DeleteDhcpOptions                 => 'boolean',
    AssociateDhcpOptions              => 'boolean',
    );

=head1 NAME VM::EC2::REST::dhcp

=head1 SYNOPSIS

 use VM::EC2 qw(:vpn);

=head1 METHODS

These methods manage DHCP Option objects, which can then be applied to
a VPC to configure the DHCP options applied to running instances. You
get these methods when you import the tag ":vpn".

Implemented:
 AssociateDhcpOptions
 CreateDhcpOptions
 DeleteDhcpOptions
 DescribeDhcpOptions

Unimplemented;
 (none)

=head2 $options = $ec2->create_dhcp_options(\%configuration_list)

This method creates a DhcpOption object, The single required argument is a
configuration list hash (which can be passed either as a hashref or a
flattened hash) with one or more of the following keys:

 -domain_name            Domain name for instances running in this VPC.

 -domain_name_servers    Scalar or arrayref containing up to 4 IP addresses of
                         domain name servers for this VPC.

 -ntp_servers            Scalar or arrayref containing up to 4 IP addresses
                         of network time protocol servers

 -netbios_name_servers   Scalar or arrayref containing up to 4 IP addresses for
                         NetBIOS name servers.

 -netbios_node_type      The NetBios node type (1,2,4 or 8). Amazon recommends
                         using "2" at this time.

On successful completion, a VM::EC2::VPC::DhcpOptions object will be
returned. This can be associated with a VPC using the VPC object's
set_dhcp_options() method:

 $vpc     = $ec2->create_vpc(...);
 $options = $ec2->create_dhcp_options(-domain_name=>'test.com',
                                      -domain_name_servers=>['204.16.255.55','216.239.34.10']);
 $vpc->set_dhcp_options($options);

=cut

# { 'domain-name-servers' => ['192.168.2.1','192.168.2.2'],'domain-name'=>'example.com'}
sub create_dhcp_options {
    my $self = shift;
    my %args;
    if (@_ == 1 && ref $_[0] eq 'HASH') {
	%args = %{$_[0]};
    } else {
	%args = @_;
    }
    my @parm;
    my $count = 1;
    for my $key (sort keys %args) {
	my $value  = $args{$key};
	my @values = ref $value && ref $value eq 'ARRAY' ? @$value : $value;
	$key =~ s/^-//;
	$key =~ s/_/-/g;
	my $item = 1;
	push @parm,("DhcpConfiguration.$count.Key"  => $key);
	push @parm,("DhcpConfiguration.$count.Value.".$item++ => $_) foreach @values;
	$count++;
    }
    return $self->call('CreateDhcpOptions',@parm);
}

=head2 $success = $ec2->delete_dhcp_options($dhcp_id)

Delete the indicated DHCPOptions, returning true if successful. You
may also use the named argument -dhcp_options_id..

=cut

sub delete_dhcp_options {
    my $self = shift;
    my %args  = $self->args(-dhcp_options_id => @_);
    my @param = $self->single_parm(DhcpOptionsId=>\%args);
    return $self->call('DeleteDhcpOptions',@param);
}

=head2 @options = $ec2->describe_dhcp_options(@option_ids)

=head2 @options = $ec2->describe_dhcp_options(\%filters)

=head2 @options = $ec2->describe_dhcp_options(-dhcp_options_id=>$id,
                                              -filter         => \%filters)

This method returns a list of VM::EC2::VPC::DhcpOptions objects, which
describe a set of DHCP options that can be assigned to a VPC. Called
with no arguments, it returns all DhcpOptions. Pass a list of option
IDs or a filter hashref in order to restrict the search.

Optional arguments:

 -dhcp_options_id     Scalar or arrayref of DhcpOption IDs.
 -filter              Hashref of filters.

Available filters are described at
http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeDhcpOptions.html.

=cut

sub describe_dhcp_options {
    my $self = shift;
    my %args  = $self->args(-dhcp_options_id => @_);
    my @parm   = $self->list_parm('DhcpOptionsId',\%args);
    push @parm,  $self->filter_parm(\%args);
    return $self->call('DescribeDhcpOptions',@parm);
}

=head2 $success = $ec2->associate_dhcp_options($vpc_id => $dhcp_id)

=head2 $success = $ec2->associate_dhcp_options(-vpc_id => $vpc_id,-dhcp_options_id => $dhcp_id)

Associate a VPC ID with a DHCP option set. Pass an ID of 'default' to
restore the default DHCP options for the VPC.

=cut

sub associate_dhcp_options {
    my $self = shift;
    my %args;
    if ($_[0] !~ /^-/ && @_ == 2) {
	@args{qw(-vpc_id -dhcp_options_id)} = @_;
    } else {
	%args = @_;
    }
    $args{-vpc_id} && $args{-dhcp_options_id}
      or croak "-vpc_id and -dhcp_options_id must be specified";
    my @param    = $self->single_parm(DhcpOptionsId=> \%args);
    push @param,   $self->single_parm(VpcId        => \%args);
    return $self->call('AssociateDhcpOptions',@param);
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
