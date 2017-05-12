package VM::EC2::Instance::State::Change;

=head1 NAME

VM::EC2::Instance::State::Change - Represent an EC2 instance's change in state.

=head1 SYNOPSIS

     # find all stopped instances
    @instances = $ec2->describe_instances(-filter=>{'instance-state-name'=>'stopped'});

    # start them
    @state_change = $ec2->start_instances(@instances)
 
    foreach my $sc (@state_change) {
        my $instanceId    = $sc->instanceId;
        my $currentState  = $sc->currentState;
        my $previousState = $sc->previousState;
    }

    # poll till the first instance is running
    sleep 2 until $state_change[0]->current_status eq 'running';

=head1 DESCRIPTION

This object represents a state change in an Amazon EC2 instance.  It
is returned by VM::EC2 start_instances(), stop_instances(),
terminate_instances(), reboot_instances() and the corresponding
VM::EC2::Instance methods. In addition, this object is returned by
calls to VM::EC2::Instance->instanceState().

=head1 METHODS

These object methods are supported:
 
 instanceId      -- The instanceId.
 currentState    -- The instanceId's current state AT THE TIME
                     THE STATECHANGE OBJECT WAS CREATED. One of
                     "terminated", "running", "stopped", "stopping",
                     "shutting-down".
 previousState   -- The instanceID's previous state AT THE TIME
                     THE STATECHANGE OBJECT WAS CREATED.

Note that currentState and previousState return a
VM::EC2::Instance::State object, which provides both string-readable
forms and numeric codes representing the state.

In addition, the method provides the following convenience method:

=head2 $state = $state_change->current_status()

This method returns the current state of the instance. This is the
correct method to call if you are interested in knowing what the
instance is doing right now.

=head2 STRING OVERLOADING

In a string context, the method will return the string representation of
currentState.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::State>
L<VM::EC2::Instance>

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
use base 'VM::EC2::Generic';
use Carp 'croak';
use VM::EC2::Instance::State;

use overload '""' => sub {shift()->currentState},
    fallback      => 1;

sub valid_fields {
    my $self = shift;
    return qw(instanceId currentState previousState);
}
sub currentState {
    return VM::EC2::Instance::State->new(shift->SUPER::currentState);
}
sub previousState {
    return VM::EC2::Instance::State->new(shift->SUPER::previousState);
}
sub current_status {
    my $self = shift;
    my $ec2  = $self->aws;
    my $id   = $self->instanceId;
    my ($instance) = $ec2->describe_instances(-instance_id=>$id);
    $instance or croak "invalid instance: $id";
    return $instance->instanceState;
}

1;
