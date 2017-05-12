package VM::EC2::ELB::BackendServerDescription;

=head1 NAME

VM::EC2::ELB:BackendServerDescription - Load Balancer Backend Server Description

=head1 SYNOPSIS

 use VM::EC2;

 my $ec2    = VM::EC2->new(...);
 my $lb     = $ec2->describe_load_balancers('my-lb');
 my @descs  = $lb->BackendServerDescriptions;
 foreach my $desc (@descs) {
     print $desc->InstancePort,":\n";
     foreach ($desc->PolicyNames) {
         print $_,"\n";
     }
           
 }

=head1 DESCRIPTION

This object is used to describe the BackendServerDescription data type, which is
one of the response elements of the DescribeLoadBalancers API call.

=head1 METHODS

The following object methods are supported:
 
 InstancePort -- Returns the port on which the back-end server is listening.
 PolicyNames  -- Returns an array of policy names enabled for the back-end
                 server.

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

sub valid_fields {
    my $self = shift;
    return qw(InstancePort PolicyNames);
}

sub PolicyNames {
    my $self = shift;
    my $policies = $self->SUPER::PolicyNames or return;
    return @{$policies->{member}};
}

1;
