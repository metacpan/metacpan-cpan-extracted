package VM::EC2::REST::network_acl;

use strict;
use VM::EC2 '';  # important not to import anything!
package VM::EC2;  # add methods to VM::EC2

VM::EC2::Dispatch->register(
    CreateNetworkAcl                  => 'fetch_one,networkAcl,VM::EC2::VPC::NetworkAcl',
    CreateNetworkAclEntry             => 'boolean',
    DeleteNetworkAcl                  => 'boolean',
    DeleteNetworkAclEntry             => 'boolean',
    DescribeNetworkAcls               => 'fetch_items,networkAclSet,VM::EC2::VPC::NetworkAcl',
    ReplaceNetworkAclAssociation      => sub { shift->{newAssociationId} },
    ReplaceNetworkAclEntry            => 'boolean',
    );

my $VEP = 'VM::EC2::ParmParser';

=head1 NAME VM::EC2::REST::network_acl

=head1 SYNOPSIS

 use VM::EC2 ':vpc'

=head1 METHODS

These methods allow you to create and manipulate VPC Network Access
Control Lists.

Implemented:
 CreateNetworkAcl
 CreateNetworkAclEntry
 DeleteNetworkAcl
 DeleteNetworkAclEntry
 DescribeNetworkAcls
 ReplaceNetworkAclAssociation
 ReplaceNetworkAclEntry

Unimplemented:
 (none)

=head2 @acls = $ec2->describe_network_acls(-network_acl_id=>\@ids, -filter=>\%filters)

=head2 @acls = $ec2->describe_network_acls(\@network_acl_ids)

=head2 @acls = $ec2->describe_network_acls(%filters)

Provides information about network ACLs.

Returns a series of L<VM::EC2::VPC::NetworkAcl> objects.

Optional parameters are:

 -network_acl_id      -- ID of the network ACL(s) to return information on. 
                         This can be a string scalar, or an arrayref.

 -filter              -- Tags and other filters to apply.

The filter argument is a hashreference in which the keys are the
filter names, and the values are the match strings. Some filters
accept wildcards.

There are a number of filters, which are listed in full at
http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeNetworkAcls.html

Here is a alpha-sorted list of filter names: 
association.association-id, association.network-acl-id,
association.subnet-id, default, entry.cidr, entry.egress,
entry.icmp.code, entry.icmp.type, entry.port-range.from,
entry.port-range.to, entry.protocol, entry.rule-action,
entry.rule-number, network-acl-id, tag-key, tag-value,
tag:key, vpc-id

=cut

sub describe_network_acls {
    my $self = shift;
    my %args = $VEP->args(-network_acl_id,@_);
    my @params = $VEP->format_parms(\%args,
                                    {
                                        list_parm   => 'NetworkAclId',
                                        filter_parm => 'Filter',
                                    });
    return $self->call('DescribeNetworkAcls',@params);
}

=head2 $acl = $ec2->create_network_acl(-vpc_id=>$vpc_id)

=head2 $acl = $ec2->create_network_acl($vpc_id)

Creates a new network ACL in a VPC. Network ACLs provide an optional layer of 
security (on top of security groups) for the instances in a VPC.

Arguments:

 -vpc_id            -- The VPC ID to create the ACL in

Retuns a VM::EC2::VPC::NetworkAcl object on success.

=cut

sub create_network_acl {
    my $self = shift;
    my %args = $VEP->args(-vpc_id,@_);
    $args{-vpc_id} or
        croak "create_network_acl(): -vpc_id argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm => 'VpcId',
                                    });
    return $self->call('CreateNetworkAcl',@params);
}

=head2 $boolean = $ec2->delete_network_acl(-network_acl_id=>$id)

=head2 $boolean = $ec2->delete_network_acl($id)

Deletes a network ACL from a VPC. The ACL must not have any subnets associated
with it. The default network ACL cannot be deleted.

Arguments:

 -network_acl_id    -- The ID of the network ACL to delete

Returns true on successful deletion.

=cut

sub delete_network_acl {
    my $self = shift;
    my %args = $VEP->args(-network_acl_id,@_);
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm => 'NetworkAclId',
                                    });
    return $self->call('DeleteNetworkAcl',@params);
}

=head2 $boolean = $ec2->create_network_acl_entry(%args)

Creates an entry (i.e., rule) in a network ACL with the rule number you
specified. Each network ACL has a set of numbered ingress rules and a 
separate set of numbered egress rules. When determining whether a packet
should be allowed in or out of a subnet associated with the ACL, Amazon 
VPC processes the entries in the ACL according to the rule numbers, in 
ascending order.

Arguments:

 -network_acl_id       -- ID of the ACL where the entry will be created
                          (Required)
 -rule_number          -- Rule number to assign to the entry (e.g., 100).
                          ACL entries are processed in ascending order by
                          rule number.  Positive integer from 1 to 32766.
                          (Required)
 -protocol             -- The IP protocol the rule applies to. You can use
                          -1 to mean all protocols.  See
                          http://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
                          for a list of protocol numbers. (Required)
 -rule_action          -- Indicates whether to allow or deny traffic that
                           matches the rule.  allow | deny (Required)
 -egress               -- Indicates whether this rule applies to egress
                          traffic from the subnet (true) or ingress traffic
                          to the subnet (false).  Default is false.
 -cidr_block           -- The CIDR range to allow or deny, in CIDR notation
                          (e.g., 172.16.0.0/24). (Required)
 -icmp_code            -- For the ICMP protocol, the ICMP code. You can use
                          -1 to specify all ICMP codes for the given ICMP
                          type.  Required if specifying 1 (ICMP) for protocol.
 -icmp_type            -- For the ICMP protocol, the ICMP type. You can use
                          -1 to specify all ICMP types.  Required if
                          specifying 1 (ICMP) for the protocol
 -port_range_from      -- The first port in the range.  Required if specifying
                          6 (TCP) or 17 (UDP) for the protocol.
 -port_range_to        -- The last port in the range.  Required if specifying
                          6 (TCP) or 17 (UDP) for the protocol.

 -port_from            -- Alias for -port_range_from

 -port_to              -- Alias for -port_range_to

Returns true on successful creation.

=cut

sub create_network_acl_entry {
    my $self = shift;
    my %args = @_;
    $args{-network_acl_id} or
        croak "create_network_acl_entry(): -network_acl_id argument missing";
    $args{-rule_number} or
        croak "create_network_acl_entry(): -rule_number argument missing";
    defined $args{-protocol} or
        croak "create_network_acl_entry(): -protocol argument missing";
    $args{-rule_action} or
        croak "create_network_acl_entry(): -rule_action argument missing";
    $args{-cidr_block} or
        croak "create_network_acl_entry(): -cidr_block argument missing";
    $args{-port_range_from} ||= $args{-port_from};
    $args{-port_range_to} ||= $args{-port_to};
    if ($args{-protocol} == 1) {
        defined $args{-icmp_type} && defined $args{-icmp_code} or
        croak "create_network_acl_entry(): -icmp_type or -icmp_code argument missing";
    }
    elsif ($args{-protocol} == 6 || $args{-protocol} == 17) {
        defined $args{-port_range_from} or
            croak "create_network_acl_entry(): -port_range_from argument missing";
        $args{-port_range_to} = $args{-port_range_from} if ! defined $args{-port_range_to};
    }
    $args{-egress} ||= $args{-egress} ? 'true' : 'false';
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm => [qw(NetworkAclId RuleNumber Protocol
                                                           RuleAction Egress CidrBlock Icmp.Code
                                                           Icmp.Type PortRange.From PortRange.To)],
                                    });
    return $self->call('CreateNetworkAclEntry',@params);
}

=head2 $success = $ec2->delete_network_acl_entry(-network_acl_id=>$id,
                                                 -rule_number   =>$int,
                                                 -egress        =>$bool)

Deletes an ingress or egress entry (i.e., rule) from a network ACL.

Arguments:

 -network_acl_id       -- ID of the ACL where the entry will be created

 -rule_number          -- Rule number of the entry (e.g., 100).

Optional arguments:

 -egress    -- Whether the rule to delete is an egress rule (true) or ingress 
               rule (false).  Default is false.

Returns true on successful deletion.

=cut

sub delete_network_acl_entry {
    my $self = shift;
    my %args = @_;
    $args{-network_acl_id} or
        croak "delete_network_acl_entry(): -network_acl_id argument missing";
    $args{-rule_number} or
        croak "delete_network_acl_entry(): -rule_number argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm => [qw(NetworkAclId RuleNumber Egress)],
                                    });
    return $self->call('DeleteNetworkAclEntry',@params);
}

=head2 $assoc_id = $ec2->replace_network_acl_association(-association_id=>$assoc_id,
                                                         -network_acl_id=>$id)

Changes which network ACL a subnet is associated with. By default when you
create a subnet, it's automatically associated with the default network ACL.

Arguments:

 -association_id    -- The ID of the association to replace

 -network_acl_id    -- The ID of the network ACL to associated the subnet with

Returns the new association ID.

=cut

sub replace_network_acl_association {
    my $self = shift;
    my %args = @_;
    $args{-association_id} or
        croak "replace_network_acl_association(): -association_id argument missing";
    $args{-network_acl_id} or
        croak "replace_network_acl_association(): -network_acl_id argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm => [qw(AssociationId NetworkAclId)],
                                    });
    return $self->call('ReplaceNetworkAclAssociation',@params);
}

=head2 $success = $ec2->replace_network_acl_entry(%args)

Replaces an entry (i.e., rule) in a network ACL.

Arguments:

 -network_acl_id       -- ID of the ACL where the entry will be created
                          (Required)
 -rule_number          -- Rule number of the entry to replace. (Required)
 -protocol             -- The IP protocol the rule applies to. You can use
                          -1 to mean all protocols.  See
                          http://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
                          for a list of protocol numbers. (Required)
 -rule_action          -- Indicates whether to allow or deny traffic that
                           matches the rule.  allow | deny (Required)
 -egress               -- Indicates whether this rule applies to egress
                          traffic from the subnet (true) or ingress traffic
                          to the subnet (false).  Default is false.
 -cidr_block           -- The CIDR range to allow or deny, in CIDR notation
                          (e.g., 172.16.0.0/24). (Required)
 -icmp_code            -- For the ICMP protocol, the ICMP code. You can use
                          -1 to specify all ICMP codes for the given ICMP
                          type.  Required if specifying 1 (ICMP) for protocol.
 -icmp_type            -- For the ICMP protocol, the ICMP type. You can use
                          -1 to specify all ICMP types.  Required if
                          specifying 1 (ICMP) for the protocol
 -port_range_from      -- The first port in the range.  Required if specifying
                          6 (TCP) or 17 (UDP) for the protocol.
 -port_range_to        -- The last port in the range.  Only required if
                          specifying 6 (TCP) or 17 (UDP) for the protocol and
                          is a different port than -port_range_from.

 -port_from            -- Alias for -port_range_from

 -port_to              -- Alias for -port_range_from

Returns true on successful replacement.

=cut

sub replace_network_acl_entry {
    my $self = shift;
    my %args = @_;
    $args{-network_acl_id} or
        croak "replace_network_acl_entry(): -network_acl_id argument missing";
    $args{-rule_number} or
        croak "replace_network_acl_entry(): -rule_number argument missing";
    $args{-protocol} or
        croak "replace_network_acl_entry(): -protocol argument missing";
    $args{-rule_action} or
        croak "replace_network_acl_entry(): -rule_action argument missing";
    $args{-port_range_from} ||= $args{-port_from};
    $args{-port_range_to} ||= $args{-port_to};
    if ($args{-protocol} == 1) { 
        defined $args{-icmp_type} && defined $args{-icmp_code} or
        croak "replace_network_acl_entry(): -icmp_type or -icmp_code argument missing";
    }
    elsif ($args{-protocol} == 6 || $args{-protocol} == 17) {
        defined $args{-port_range_from} or
            croak "create_network_acl_entry(): -port_range_from argument missing";
        $args{-port_range_to} = $args{-port_range_from} if ! defined $args{-port_range_to};
    }
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm => [qw(NetworkAclId RuleNumber Protocol
                                                           RuleAction Egress CidrBlock Icmp.Code
                                                           Icmp.Type PortRange.From PortRange.To)],
                                    });
    return $self->call('ReplaceNetworkAclEntry',@params);
}

=head1 SEE ALSO

L<VM::EC2>

=head1 AUTHOR

Lance Kinley E<lt>lkinley@loyaltymethods.comE<gt>.
Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2012 Loyalty Methods, Inc.
Copyright (c) 2012 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

1;
