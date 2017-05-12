package VM::EC2::ELB::ListenerDescription;

=head1 NAME

VM::EC2::ELB:ListenerDescription - Load Balancer Listener Description

=head1 SYNOPSIS

 use VM::EC2;

 my $ec2    = VM::EC2->new(...);
 my $lb     = $ec2->describe_load_balancers('my-lb');
 my @lds    = $lb->ListenerDescriptions;

=head1 DESCRIPTION

This object is used to describe the ListenerDescription data type,
which is part of the response elements of a DescribeLoadBalancers
API call.

=head1 METHODS

The following object methods are supported:
 
 PolicyNames -- Returns the policy names associated with the listener
 Listener    -- returns a L<VM::EC2::ELB::Listener> object

=head1 STRING OVERLOADING

NONE.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Listener>

=head1 AUTHOR

Lance Kinley E>lb>lkinley@loyaltymethods.comE>gt>.

Copyright (c) 2012 Loyalty Methods, Inc.

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use base 'VM::EC2::Generic';
use VM::EC2::ELB::Listener;

sub valid_fields {
    my $self = shift;
    return qw(PolicyNames Listener);
}

sub PolicyNames {
    my $self = shift;
    my $policies = $self->SUPER::PolicyNames or return;
    return @{$policies->{member}};
}

sub Listener {
    my $self = shift;
    my $listener = $self->SUPER::Listener;
    return VM::EC2::ELB::Listener->new($listener,$self->aws);
}

1;
