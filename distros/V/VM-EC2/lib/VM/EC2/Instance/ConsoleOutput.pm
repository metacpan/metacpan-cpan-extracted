package VM::EC2::Instance::ConsoleOutput;

=head1 NAME

VM::EC2::ConsoleOutput - Object describing console output from
an Amazon EC2 instance

=head1 SYNOPSIS

  use VM::EC2;

  $ec2      = VM::EC2->new(...);
  $instance = $ec2->describe_instance(-instance_id=>'i-123456'); 

  my $out = $instance->console_output; 

  print $out,"\n"; 
  my $ts       = $out->timestamp; 
  my $instance = $out->instanceId;

=head1 DESCRIPTION

This object represents the output from the console of a Amazon EC2
instance. The instance may be running, pending or stopped. It is
returned by VM::EC2->get_console_output(), as well as
VM::EC2::Instance->console_output.

Please see L<VM::EC2::Generic> for methods shared by all VM::EC2
objects.

=head1 METHODS

These object methods are supported:

 requestId  -- ID of the request that generated this object
 instanceId -- ID of the instance that generated this output 
 timestamp -- Time that this output was generated 
 output    -- Text of the console output

=head1 STRING OVERLOADING

When used in a string context, this object will act as if its output()
method was called, allowing it to be printed or searched directly.

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
use base 'VM::EC2::Generic';
use MIME::Base64;

use overload '""' => 'output',
    fallback      => 1;

sub valid_fields {
    my $self  = shift;
    return $self->SUPER::valid_fields,
           qw(requestId instanceId timestamp output);
}

sub output {
    my $self = shift;
    my $out  = $self->SUPER::output;
    return decode_base64($out);
}

1;

