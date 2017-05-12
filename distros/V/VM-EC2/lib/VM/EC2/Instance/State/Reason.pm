package VM::EC2::Instance::State::Reason;

=head1 NAME

VM::EC2::State::Reason - Object describing the reason for an EC2 instance state change

=head1 SYNOPSIS

  use VM::EC2;

  $ec2      = VM::EC2->new(...);
  $instance = $ec2->describe_instances(-instance_id=>'i-12345');
  $reason   = $instance->reason;
  $code     = $reason->code;
  $message  = $reason->message;

=head1 DESCRIPTION

This object represents the reason that an Amazon EC2 instance
underwent a state change. It is returned by calling the reason()
method of VM::EC2::Instance.

=head1 METHODS

These object methods are supported:
 
 code           -- The state change reason code.
 message        -- The state change reason method.

The following table lists the codes and messages (source:
http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-ItemType-StateReasonType.html):

   Code	                                        Message
   ----                                         -------
 Server.SpotInstanceTermination       A Spot Instance was terminated due 
                                      to an increase in the market price.

 Server.InternalError                 An internal error occurred during 
                                      instance launch, resulting in termination.

 Server.InsufficientInstanceCapacity  There was insufficient instance capacity 
                                      to satisfy the launch request.

 Client.InternalError                 A client error caused the instance to 
                                      terminate on launch.

 Client.InstanceInitiatedShutdown     The instance initiated shutdown by a shutdown -h 
                                      command issued from inside the instance.

 Client.UserInitiatedShutdown         The instance was shutdown by a user via an 
                                      API call.

 Client.VolumeLimitExceeded           The volume limit was exceeded.

 Client.InvalidSnapshot.NotFound      The specified snapshot was not found.

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
message.

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

use overload '""' => 'message',
    fallback      => 1;

sub new {
    my $self  = shift;
    my $state = shift;
    return bless \$state,ref $self || $self;
}

sub code    { ${shift()}->{code} }
sub message { ${shift()}->{message} }

1;
