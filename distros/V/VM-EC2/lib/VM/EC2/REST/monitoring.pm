package VM::EC2::REST::monitoring;

use strict;
use VM::EC2 '';  # important not to import anything!
package VM::EC2;  # add methods to VM::EC2

VM::EC2::Dispatch->register(
    MonitorInstances     => 'fetch_items,instancesSet,VM::EC2::Instance::MonitoringState',
    UnmonitorInstances   => 'fetch_items,instancesSet,VM::EC2::Instance::MonitoringState',
    );

=head1 NAME VM::EC2::REST::monitoring

=head1 SYNOPSIS

 use VM::EC2 ':misc';

=head1 METHODS

These methods enable the monitoring/unmonitoring of instances.

=head2 @monitoring_state = $ec2->monitor_instances(@list_of_instanceIds)

=head2 @monitoring_state = $ec2->monitor_instances(-instance_id=>\@instanceIds)

This method enables monitoring for the listed instances and returns a
list of VM::EC2::Instance::MonitoringState objects. You can
later use these objects to activate and inactivate monitoring.

=cut

sub monitor_instances {
    my $self = shift;
    my %args = $self->args('-instance_id',@_);
    my @params = $self->list_parm('InstanceId',\%args);
    return $self->call('MonitorInstances',@params);
}

=head2 @monitoring_state = $ec2->unmonitor_instances(@list_of_instanceIds)

=head2 @monitoring_state = $ec2->unmonitor_instances(-instance_id=>\@instanceIds)

This method disables monitoring for the listed instances and returns a
list of VM::EC2::Instance::MonitoringState objects. You can
later use these objects to activate and inactivate monitoring.

=cut

sub unmonitor_instances {
    my $self = shift;
    my %args = $self->args('-instance_id',@_);
    my @params = $self->list_parm('InstanceId',\%args);
    return $self->call('UnmonitorInstances',@params);
}

=head1 SEE ALSO

L<VM::EC2>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2011 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut


1;
