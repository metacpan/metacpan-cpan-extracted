package VM::EC2::VPC::NetworkAcl::Entry;

=head1 NAME

VM::EC2::VPC::NetworkAcl::Entry - VPC Network ACL entry

=head1 SYNOPSIS

  use VM::EC2;

 my $ec2      = VM::EC2->new(...);
 my $acl      = $ec2->describe_network_acls(-network_acl_id=>'acl-12345678');
 my @entries  = $acl->entries;

 # print outgoing icmp rules
 for my $e (@entries) {
     if ($e->egress && $e->protocol == 1) {  # icmp = 1
         print $e->ruleNumber,"\n",
               $e->ruleAction,"\n",
               $e->cidrBlock,"\n",
               $e->icmpType,"\n",
               $e->icmpCode,"\n";
     }
 }

 # print incoming tcp rules
 for my $e (@entries) {
     if (! $e->egress && $e->protocol == 6) {  # tcp = 6
         print $e->ruleNumber,"\n",
               $e->ruleAction,"\n",
               $e->cidrBlock,"\n",
               $e->port_from,'-',$e->port_to,"\n";
     }
 }

=head1 DESCRIPTION

This object represents an Amazon EC2 VPC network ACL entry

=head1 METHODS

These object methods are supported:

 ruleNumber     -- Specific rule number for the entry. ACL entries are
                   processed in ascending order by rule number.
 protocol       -- Protocol. A value of -1 means all protocols.
                   See: http://www.iana.org/assignments/protocol-numbers/protocol-numbers.xml
                   for a list of protocol numbers.
 ruleAction     -- Whether to allow or deny the traffic that matches the
                   rule.  Valid values:  allow | deny
 egress         -- Boolean flag to indicate an egress rule (rule is
                   applied to traffic leaving the subnet). Value of true
                   indicates egress.
 cidrBlock      -- The network range to allow or deny, in CIDR notation.
 icmpType       -- For the ICMP protocol, this is the ICMP type
 icmpCode       -- For the ICMP protocol, this is the ICMP code.
 portRangeFrom  -- For the TCP or UDP protocols, the starting range of ports the
                   rule applies to.
 portRangeTo    -- For the TCP or UDP protocols, the ending range of ports the
                   rule applies to.
 port_from      -- Alias for portRangeFrom
 port_to        -- Alias for portRangeTo

The object also supports the tags() method described in
L<VM::EC2::Generic>:

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
rule number

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Tag>
L<VM::EC2::VPC>
L<VM::EC2::VPC::NetworkAcl>

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
use Carp 'croak';

sub primary_id    { shift->ruleNumber }

sub valid_fields {
    my $self  = shift;
    return qw(ruleNumber protocol ruleAction egress cidrBlock icmpTypeCode portRange);
}

sub egress {
    my $self = shift;
    return $self->SUPER::egress eq 'true';
}

sub icmpType {
    my $self = shift;
    my $typecode = $self->icmpTypeCode;
    return $typecode->{type};
}

sub icmpCode {
    my $self = shift;
    my $typecode = $self->icmpTypeCode;
    return $typecode->{code};
}

sub portRangeFrom {
    my $self = shift;
    my $portRange = $self->portRange;
    return $portRange->{from};
}

sub port_from { shift->portRangeFrom }

sub portRangeTo {
    my $self = shift;
    my $portRange = $self->portRange;
    return $portRange->{to};
}

sub port_to { shift->portRangeTo }

1;

