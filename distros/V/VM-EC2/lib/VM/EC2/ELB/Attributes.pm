package VM::EC2::ELB::Attributes;

=head1 NAME

VM::EC2::ELB:Attributes - Object describing the attributes of an Elastic
Load Balancer.

=head1 SYNOPSIS

 use VM::EC2;

 my $ec2           = VM::EC2->new(...);
 my $lb            = $ec2->describe_load_balancer_attributes('my-lb');
 my $access_log    = $lb->AccessLog;
 my $conn_drain    = $lb->ConnectionDraining;
 my $conn_settings = $lb->ConnectionSettings;
 my $cross_zone    = $lb->CrossZoneLoadBalancing;

=head1 DESCRIPTION

This object is used to describe the parameters returned by a
DescribeLoadBalancerAttributes API call.

=head1 METHODS

The following object methods are supported:
 
 AccessLog                --  If enabled, the load balancer captures detailed
                              information of all the requests and delivers the
                              information to the Amazon S3 bucket that you
                              specify.

 ConnectionDraining       --  If enabled, the load balancer allows existing
                              requests to complete before the load balancer
                              shifts traffic away from a deregistered or
                              unhealthy back-end instance.

 ConnectionSettings       --  By default, the Elastic Load Balancer maintains a
                              60-second idle connection timeout for both front-
                              end and back-end connections of your load
                              balancer. If the ConnectionSettings attribute is
                              set, Elastic Load Balancing will allow the
                              connections to remain idle (no data is sent over
                              the connection) for the specified duration.

 CrossZoneLoadBalancing   --  If enabled, the load balancer routes the request
                              traffic evenly across all back-end instances
                              regardless of the Availability Zones.

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
use VM::EC2::ELB::Attributes::AccessLog;
use VM::EC2::ELB::Attributes::ConnectionDraining;
use VM::EC2::ELB::Attributes::ConnectionSettings;
use VM::EC2::ELB::Attributes::CrossZoneLoadBalancing;

use overload
    '""'     => sub {
        my $self = shift;
        my $string = $self->AccessLog . "\n";
        $string   .= $self->ConnectionDraining. "\n";
        $string   .= $self->ConnectionSettings. "\n";
        $string   .= $self->CrossZoneLoadBalancing;
        return $string},
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(AccessLog ConnectionDraining
              ConnectionSettings CrossZoneLoadBalancing);
}

sub AccessLog {
    my $self = shift;
    return VM::EC2::ELB::Attributes::AccessLog->new($self->SUPER::AccessLog,$self->aws);
}

sub ConnectionDraining {
    my $self = shift;
    return VM::EC2::ELB::Attributes::ConnectionDraining->new($self->SUPER::ConnectionDraining,$self->aws);
}

sub ConnectionSettings {
    my $self = shift;
    return VM::EC2::ELB::Attributes::ConnectionSettings->new($self->SUPER::ConnectionSettings,$self->aws);
}

sub CrossZoneLoadBalancing {
    my $self = shift;
    return VM::EC2::ELB::Attributes::CrossZoneLoadBalancing->new($self->SUPER::CrossZoneLoadBalancing,$self->aws);
}

1;
