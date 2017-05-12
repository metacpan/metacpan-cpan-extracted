package VM::EC2::ELB::InstanceState;

=head1 NAME

VM::EC2::ELB:InstanceState - Object describing the state of an instance 
attached to a load balancer.  It is the result of a DescribeInstanceHealth
API call.

=head1 SYNOPSIS

 use VM::EC2;

 my $ec2          = VM::EC2->new(...);
 my $lb           = $ec2->describe_load_balancers('my-lb');
 my @instance_ids = map { $_->InstanceId } $lb->Instances();
 my @states       = $lb->describe_instance_health(-instances => \@instance_ids);
 my @down_ids     = map { $_->InstanceId } grep { $_->State eq 'OutOfService' } @states;

=head1 DESCRIPTION

This object is used to describe the parameters returned by a
DescribeInstanceHealth API call.

=head1 METHODS

The following object methods are supported:
 
 InstanceId   -- The Instance ID of the instance attached to the load balancer
 State        -- Specifies the current status of the instance
 ReasonCode   -- Provides information about the cause of OutOfService instances.
                 Specifically, it indicates whether the cause is Elastic Load Balancing 
                 or the instance behind the load balancer
 Description  -- Description of why the instance is in the current state

The following convenience methods are supported:

 instance     -- Provides an L<VM::EC2::Instance> object

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
instance state.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::ELB>

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

sub valid_fields {
    my $self = shift;
    return qw(Description InstanceId ReasonCode State);
}

use overload
    '""'     => sub {
                        my $self = shift;
                        return $self->InstanceId . ': ' .
                               $self->State . ' (Reason: ' .
                               $self->ReasonCode . ')';
                    },
    fallback => 1;

sub instance {
    my $self = shift;
    return $self->aws->describe_instances($self->InstanceId);
}

1;
