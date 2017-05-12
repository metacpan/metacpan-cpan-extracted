package VM::EC2::ELB::PolicyDescription;

=head1 NAME

VM::EC2::ELB::PolicyDescription - Load Balancer Policy

=head1 SYNOPSIS

 use VM::EC2;

 my $ec2     = VM::EC2->new(...);
 my $lb      = $ec2->describe_load_balancers(-load_balancer_name=>'my-lb');
 my @policy  = $lb->describe_policies;
 foreach (@policy) {
     print $_->PolicyName," : ",$_->PolicyTypeName,"\n";
 }

=head1 DESCRIPTION

This object is used to describe the result of a DescribeLoadBalancerPolicies
ELB API call.

=head1 METHODS

The following object methods are supported:
 
 PolicyName                   -- The policy name
 PolicyTypeName               -- A L<VM::EC2::ELB::PolicyTypeDescription> object
 PolicyAttributeDescriptions  -- A series of L<VM::EC2::ELB::PolicyAttribute>
                                 objects
 policy_attributes            -- Alias for PolicyAttributeDescriptions

=head1 STRING OVERLOADING

In string context, the object returns the Policy Name.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::ELB>
L<VM::EC2::ELB::Policies>
L<VM::EC2::ELB::PolicyAttribute>
L<VM::EC2::ELB::PolicyTypeDescription>

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
use VM::EC2::ELB::PolicyAttribute;

use overload
    '""'     => sub { shift->PolicyName },
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(PolicyAttributeDescriptions PolicyName PolicyTypeName);
}

sub PolicyAttributeDescriptions {
    my $self = shift;
    my $attr_desc = $self->SUPER::PolicyAttributeDescriptions;
    return map { VM::EC2::ELB::PolicyAttribute->new($_,$self->aws) } @{$attr_desc->{member}};
}

sub PolicyTypeName {
    my $self = shift;
    my $ptn = $self->SUPER::PolicyTypeName;
    return $self->aws->describe_load_balancer_policy_types($ptn);
}

sub policy_attributes { shift->PolicyAttributeDescriptions }

1;
