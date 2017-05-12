package VM::EC2::ELB::PolicyAttribute;

=head1 NAME

VM::EC2::ELB::PolicyAttribute - Elastic Load Balancer Policy Attribute

=head1 SYNOPSIS

 use VM::EC2;

 my $ec2       = VM::EC2->new(...);
 my @policies  = $ec2->describe_load_balancer_policies(-load_balancer_name=>'my-lb');
 foreach my $p (@policies) {
     my @attr = $p->policy_attributes;
     foreach (@attr) {
        print $_,"\n";
     }
 }
 
=head1 DESCRIPTION

This object is used to describe the ELB PolicyAttribute data type, which is
part of the result of a DescribeLoadBalancerPolicies API call.

=head1 METHODS

The following object methods are supported:
 
 AttributeName  -- Policy Attribute Name
 AttributeValue -- Policy Attribute Value

=head1 STRING OVERLOADING

In string context, the object will return an attribute name=value pair.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::ELB>
L<VM::EC2::ELB::Policies>

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

use overload
    '""'     => sub {
        my $self = shift;
        return $self->AttributeName . '=' . $self->AttributeValue},
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(AttributeName AttributeValue);
}

1;
