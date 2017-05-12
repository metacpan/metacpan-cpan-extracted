package VM::EC2::VPC::NetworkAcl;

=head1 NAME

VM::EC2::VPC::NetworkAcl - Virtual Private Cloud network ACL

=head1 SYNOPSIS

 use VM::EC2;

 my $ec2      = VM::EC2->new(...);
 my @acls     = $ec2->describe_network_acls(-network_acl_id=>'acl-12345678');
  foreach my $acl (@acls) {
      my $vpc_id  = $acl->vpcId;
      my $default = $acl->default;
      my @entries = $acl->entries;
      my @assoc   = $acl->associations;
      ...
  }

 my $acl      = $ec2->create_network_acl_entry(...);
 

=head1 DESCRIPTION

This object represents an Amazon EC2 VPC network ACL, and is returned by
VM::EC2->describe_network_acls() and ->create_network_acl()

=head1 METHODS

These object methods are supported:

 networkAclId   -- The network ACL's ID.
 vpcId          -- The ID of the VPC the network ACL is in.
 default        -- Whether this is the default network ACL in the VPC.
 entrySet       -- A list of entries (rules) in the network ACL.
 associationSet -- A list of associations between the network ACL and
                   one or more subnets.
 tagSet         -- Tags assigned to the resource.
 associations   -- Alias for associationSet.
 entries        -- Alias for entrySet.

The object also supports the tags() method described in
L<VM::EC2::Generic>:

=head1 CONVENIENCE METHODS

=head2 $success = $acl->create_entry(%args)
=head2 $success = $acl->create_entry($acl_entry)

Creates an entry (i.e., rule) in a network ACL with the rule number you
specified. Each network ACL has a set of numbered ingress rules and a 
separate set of numbered egress rules. When determining whether a packet
should be allowed in or out of a subnet associated with the ACL, Amazon 
VPC processes the entries in the ACL according to the rule numbers, in 
ascending order.

Arguments:

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
 -port_from            -- The first port in the range.  Required if specifying
                          6 (TCP) or 17 (UDP) for the protocol.
 -port_to              -- The last port in the range.  Required if specifying
                          6 (TCP) or 17 (UDP) for the protocol.

Alternately, can pass an existing ACL entry object L<VM::EC2::VPC::NetworkAcl::Entry>
as the only argument for ease in copying entries from one ACL to another.

Returns true on successful creation.

=head2 $success = $acl->delete_entry(%args)
=head2 $success = $acl->delete_entry($acl_entry)

Deletes an ingress or egress entry (i.e., rule) from a network ACL.

Arguments:

 -network_acl_id       -- ID of the ACL where the entry will be created

 -rule_number          -- Rule number of the entry (e.g., 100).

Optional arguments:

 -egress    -- Whether the rule to delete is an egress rule (true) or ingress 
               rule (false).  Default is false.

Alternately, can pass an existing ACL entry object L<VM::EC2::VPC::NetworkAcl::Entry>
as the only argument to ease deletion of entries.

Returns true on successful deletion.

=head2 $success = replace_entry(%args)
=head2 $success = replace_entry($acl_entry)

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
 -port_from            -- The first port in the range.  Required if specifying
                          6 (TCP) or 17 (UDP) for the protocol.
 -port_to              -- The last port in the range.  Only required if
                          specifying 6 (TCP) or 17 (UDP) for the protocol and
                          is a different port than -port_from.

Alternately, can pass an existing ACL entry object L<VM::EC2::VPC::NetworkAcl::Entry>
as the only argument for ease in replacing entries from one ACL to another.
The rule number in the passed entry object must already exist in the ACL.

Returns true on successful replacement.

=head2 $association_id = $acl->associate($subnet_id)

Associates the ACL with a subnet in the same VPC.  Replaces
whatever ACL the subnet was associated with previously.

=head2 $association_id = $acl->disassociate($subnet_id)

Disassociates the ACL with a subnet in the same VPC.  The subnet
will then be associated with the default ACL.

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
networkAclId.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Tag>
L<VM::EC2::VPC>
L<VM::EC2::VPC::NetworkAcl::Entry>
L<VM::EC2::VPC::NetworkAcl::Association>

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
use VM::EC2::VPC::NetworkAcl::Entry;
use VM::EC2::VPC::NetworkAcl::Association;
use Carp 'croak';

sub primary_id { shift->networkAclId }

sub valid_fields {
    my $self  = shift;
    return qw(networkAclId vpcId default entrySet associationSet tagSet);
}

sub default {
    my $self = shift;
    my $entries = $self->SUPER::default;
    return $entries eq 'true';
}

sub entrySet {
    my $self = shift;
    my $entries = $self->SUPER::entrySet;
    return map { VM::EC2::VPC::NetworkAcl::Entry->new($_,$self->aws) } @{$entries->{item}};
}

sub entries { shift->entrySet }

sub associationSet {
    my $self = shift;
    my $assoc = $self->SUPER::associationSet;
    return map { VM::EC2::VPC::NetworkAcl::Association->new($_,$self->aws) } @{$assoc->{item}};
}

sub associations { shift->associationSet }

sub create_entry {
    my $self = shift;
    my %args;
    if (@_ == 1 && $_[0] !~ /^-/ && ref $_[0] eq 'VM::EC2::VPC::NetworkAcl::Entry') {
        my $entry = shift;
        $args{-rule_number} = $entry->ruleNumber;
        $args{-protocol} = $entry->protocol;
        $args{-rule_action} = $entry->ruleAction;
        $args{-egress} = $entry->egress;
        $args{-cidr_block} = $entry->cidrBlock;
        $args{-icmpType} = $entry->icmpType;
        $args{-icmpCode} = $entry->icmpCode;
        $args{-port_from} = $entry->portRangeFrom;
        $args{-port_to} = $entry->portRangeTo;
    }
    else {
        %args = @_;
    }
    $args{-network_acl_id} = $self->networkAclId;
    return $self->aws->create_network_acl_entry(%args);
}

sub delete_entry {
    my $self = shift;
    my %args;
    if (@_ == 1 && $_[0] !~ /^-/ && ref $_[0] eq 'VM::EC2::VPC::NetworkAcl::Entry') {
        my $entry = shift;
        $args{-rule_number} = $entry->ruleNumber;
        $args{-egress} = $entry->egress;
    }
    else {
        %args = @_;
    }
    $args{-network_acl_id} = $self->networkAclId;
    return $self->aws->delete_network_acl_entry(%args);
}

sub replace_entry {
    my $self = shift;
    my %args;
    if (@_ == 1 && $_[0] !~ /^-/ && ref $_[0] eq 'VM::EC2::VPC::NetworkAcl::Entry') {
        my $entry = shift;
        $args{-rule_number} = $entry->ruleNumber;
        $args{-protocol} = $entry->protocol;
        $args{-rule_action} = $entry->ruleAction;
        $args{-egress} = $entry->egress;
        $args{-cidr_block} = $entry->cidrBlock;
        $args{-icmpType} = $entry->icmpType;
        $args{-icmpCode} = $entry->icmpCode;
        $args{-port_from} = $entry->portRangeFrom;
        $args{-port_to} = $entry->portRangeTo;
    }
    else {
        %args = @_;
    }
    $args{-network_acl_id} = $self->networkAclId;
    return $self->aws->replace_network_acl_entry(%args);
}

sub associate {
    my $self = shift;
    my $subnet_id = shift or croak "usage: associate(\$subnet_id)";
    # get the acl the subnet is currently associated with in order the find the association id
    my $acl = $self->aws->describe_network_acls(-filter=>{ 'association.subnet-id' => $subnet_id})
        or croak "associate(): Cannot determine ACL for subnet $subnet_id";
    my ($association) = grep { $_->subnetId eq $subnet_id } $acl->associations;
    my $association_id = $association->networkAclAssociationId;
    my $network_acl_id = $self->networkAclId;
    return $self->aws->replace_network_acl_association(-association_id=>$association_id,-network_acl_id=>$network_acl_id);
}

sub disassociate {
    my $self = shift;
    my $subnet_id = shift or croak "usage: associate(\$subnet_id)";
    $self->default and croak "Cannot disassociate subnet from default ACL";
    # determine association id for this acl
    my ($association) = grep { $_->subnetId eq $subnet_id } $self->associations;
    my $association_id = $association->networkAclAssociationId;
    # determine default acl for this subnet
    my $default_acl = $self->aws->describe_network_acls(-filter=>{ 'default' => 'true', 'vpc-id' => $self->vpcId})
        or croak "disassociate(): Cannot determine default ACL";
    my $network_acl_id = $default_acl->networkAclId;
    return $self->aws->replace_network_acl_association(-association_id=>$association_id,-network_acl_id=>$network_acl_id);
}

1;
