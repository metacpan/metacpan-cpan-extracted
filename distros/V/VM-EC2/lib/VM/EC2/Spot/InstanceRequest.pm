package VM::EC2::Spot::InstanceRequest;

=head1 NAME

VM::EC2::Spot::InstanceRequest - Object describing an Amazon EC2 spot instance request

=head1 SYNOPSIS

See L<VM::EC2/SPOT INSTANCES>.

=head1 DESCRIPTION

This object represents an Amazon EC2 spot instance request, which is
returned by VM::EC2->request_spot_instances() and
VM::EC2->describe_spot_instance_requests().

=head1 METHODS

These object methods are supported:

 spotInstanceRequestId       -- ID of this spot instance request

 spotPrice   -- The maximum hourly price for any spot
                instance launched under this request,
                in USD.

 type        -- The spot instance request type, one of
                'one-time' or 'persistent'.

 state       -- The state of this request, one of 'open',
                'closed', 'fulfilled', 'cancelled' or 'failed'.

 fault       -- Fault code for the request, if any, an
                instance of VM::EC2::Error.

 status      -- The status code and status message describing the
                Spot Instance request.

 validFrom   -- Start date and time of the request.

 validUntil  -- Date and time that the request expires.

 launchGroup -- Launch group of the instances run under this request.
                Instances in the same launch group are launched
                and terminated together.

 launchedAvailabilityZone -- Availability zone of launched instance.

 availabilityZoneGroup -- Availability zone group of the instances
                run under this request. Instances in the same
                availability zone group will always be launched
                into the same availability zone.

 launchSpecification -- Additional information for launching
                instances, represented as a VM::EC2::Spot::LaunchSpecificaton
                object.

 instanceId  -- The instance ID, if an instance has been launched as a 
                result of this request.

 createTime  -- The time and date when the spot instance request was
                created.

 productDescription -- The product description associated with this spot
                instance request.

=head1 Convenience Methods

This class supports the standard tagging interface. In addition it
provides the following convenience method:

=head2 $instance = $request->instance

If an instance was launched as a result of this request, the
instance() method will return the corresponding VM::EC2::Instance
object.

=head2 $state  = $request->current_status

Refreshes the request information and returns its status as a
VM::EC2::Spot::Status.  This will string interpolate as the status
code, such as "fulfilled". You may also call its object methods to
get the time of the last update and full message.

=head2 $state  = $request->current_state

Refreshes the request information and returns its state, such as "open".

=head2 $request->refresh

Refreshes the request information.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Spot::LaunchSpecification>
L<VM::EC2::Error>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2011 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use VM::EC2::Spot::LaunchSpecification;
use VM::EC2::Spot::Status;
use base 'VM::EC2::Generic';

sub valid_fields {
    my $self = shift;
    return qw(spotInstanceRequestId spotPrice type state fault status
              validFrom validUntil launchGroup availabilityZoneGroup
              launchedAvailabilityZone launchSpecification instanceId
              createTime productDescription);
}

sub primary_id {
    shift->spotInstanceRequestId;
}

sub status {
    my $self = shift;
    my $status = $self->SUPER::status;
    return VM::EC2::Spot::Status->new($status,$self->ec2,$self->xmlns,$self->requestId);
}

sub launchSpecification {
    my $self = shift;
    my $spec = $self->SUPER::launchSpecification;
    return VM::EC2::Spot::LaunchSpecification->new($spec,$self->ec2,$self->xmlns,$self->requestId);
}

sub instance {
    my $self = shift;
    my $instanceId = $self->instanceId or return;
    return $self->ec2->describe_instances($instanceId);
}

sub fault {
    my $self = shift;
    my $f    = $self->SUPER::fault or return;
    return VM::EC2::Error->new($f,$self->ec2);
}

sub refresh {
    my $self = shift;
    local $self->ec2->{raise_error} = 1;
    my $r    = $self->ec2->describe_spot_instance_requests($self->spotInstanceRequestId);
    %$self   = %$r if $r;
    return defined $r;
}

sub current_status {
    my $self = shift;
    $self->refresh;
    return $self->status;
}

sub current_state {
    my $self = shift;
    $self->refresh;
    return $self->state;
}

1;
