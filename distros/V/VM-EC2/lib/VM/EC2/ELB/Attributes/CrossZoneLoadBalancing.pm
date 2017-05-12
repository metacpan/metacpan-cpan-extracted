package VM::EC2::ELB::Attributes::CrossZoneLoadBalancing;

=head1 NAME

VM::EC2::ELB:Attributes::CrossZoneLoadBalancing - Object describing the
CrossZoneLoadBalancing attribute of an Elastic Load Balancer.

=head1 SYNOPSIS

 use VM::EC2;

 my $ec2           = VM::EC2->new(...);
 my $lb            = $ec2->describe_load_balancer_attributes('my-lb');
 my $cross_zone    = $lb->CrossZoneLoadBalancing;

=head1 DESCRIPTION

This object is returned as part of the DescribeLoadBalancerAttributes API call.

=head1 METHODS

The following object methods are supported:
 
 Enabled                  --  Specifies whether cross-zone load balancing is
                              enabled for the load balancer

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
instance state.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::ELB>

=head1 AUTHOR

Lance Kinley E<lt>lkinley@loyaltymethods.comE<gt>.

Copyright (c) 2014 Loyalty Methods, Inc.

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
        my $string = "Cross Zone Load Balancing:\n";
        if ($self->Enabled) {
            $string .= " ENABLED";
        } else {
            $string .= " DISABLED";
        }
        return $string},
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(Enabled);
}

sub Enabled {
    my $self = shift;
    my $enabled = $self->SUPER::Enabled;
    return $enabled eq 'true';
}

1;
