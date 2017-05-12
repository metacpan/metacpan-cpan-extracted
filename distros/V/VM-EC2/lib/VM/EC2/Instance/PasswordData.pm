package VM::EC2::Instance::PasswordData;

=head1 NAME

VM::EC2::PasswordData - Object describing the administrative password stored in an EC2 Windows instance

=head1 SYNOPSIS

  use VM::EC2;

  $ec2      = VM::EC2->new(...);
  $instance = $ec2->describe_instances(-instance_id=>'i-12345');
  $pass     = $instance->password_data;
  print $pass->password,"\n";
  print $pass->timestamp,"\n"

=head1 DESCRIPTION

This object represents the administrative password stored in a Windows
EC2 instance.  It is returned by calling either
VM::EC2->get_password_data or a VM::EC2::Instance object's
password_data() method.

=head1 METHODS

These object methods are supported:
 
 instanceId    -- ID of the instance
 timestamp     -- The time the data was last updated.
 passwordData  -- The password of the instance.
 password()    -- Same as passwordData().

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
password.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
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
use overload '""'     => 'password',
             fallback => 1;

sub valid_fields {
    my $self  = shift;
    return $self->SUPER::valid_fields,
           qw(requestId instanceId timestamp passwordData);
}

sub password {shift->passwordData}

1;
