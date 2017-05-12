package VM::EC2::ELB::HealthCheck;

=head1 NAME

VM::EC2::ELB:HealthCheck - Load Balancer Health Check Parameters

=head1 SYNOPSIS

  use VM::EC2;

  $lb = $ec2->describe_load_balancers('my-lb');
  my $hc                   = $lb->HealthCheck;
  my $interval             = $hc->Interval;
  my $target               = $hc->Target;
  my $healthy_threshold    = $hc->HealthyThreshold;
  my $unhealthy_threshold  = $hc->UnhealthyThreshold;
  my $timeout              = $hc->Timeout;

=head1 DESCRIPTION

This object is used to describe the parameters used to perform
healthchecks on a load balancer. Generally you will not call
this directly, as all its methods are passed through by the
VM::EC2::ELB object returned from the HealthCheck() call.

=head1 METHODS

The following object methods are supported:
 
 Interval           -- The time interval between health checks
 Target             -- The target protocol protocol and port of the check
 HealthyThreshold   -- The number of successive positive health checks that 
                       need to be completed to be marked as healthy
 UnhealthyThreshold -- The number of successive negative health checks that
                       need to be completed to be marked as unhealthy
 Timeout            -- The time interval of what is considered a timeout

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate object
parameters as a series of Key:Value strings

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Snapshot>
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

# allow pretty print of parameters when printing the object
use overload
    '""'     => sub {
        my $self = shift;
        return "Target: " . $self->Target . "\nInterval: " . $self->Interval .
           "\nHealthyThreshold: " . $self->HealthyThreshold .
           "\nUnhealthyThreshold: " . $self->UnhealthyThreshold .
           "\nTimeout: " . $self->Timeout},
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(HealthyThreshold Interval Target Timeout UnhealthyThreshold);
}

1;
