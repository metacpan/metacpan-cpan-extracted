package VM::EC2::Error;

=head1 NAME

VM::EC2::Error - Object describing an error emitted by the Amazon API

=head1 SYNOPSIS

  use VM::EC2;

  $ec2      = VM::EC2->new(...);
  $instance = $ec2->describe_instance(-instance_id=>'invalid-name');
  die $ec2->error if $ec2->is_error;

=head1 DESCRIPTION

This object represents an error emitted by the Amazon API. VM::EC2
method calls may return undef under either of two conditions: the
request may simply have no results that satisfy it (for example,
asking to describe an instance whose ID does not exist), or an error
occurred due to invalid parameters or communication problems.

As described in L<VM::EC2>, the VM::EC2->is_error method returns true if
the last method call resulted in an error, and VM::EC2->error returns
the content of the error message.

=head1 METHODS

These object methods are supported:

 message -- the error message
 code    -- the error code

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the code
and message into a single string in the format "Message [Code]".

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>

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

use overload 
    '""'     => sub {
	my $self = shift;
	my $msg = $self->Message;
	$msg   =~ s/\.$//;
	my $code = $self->Code;
	return "[$code] $msg";},
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(Code Message);
}

# because the darn Error XML doesn't adhere
# to the conventions elsewhere, in which
# the initial letter of the tag is lowercase
sub code    {shift->payload->{Code}}   
sub message {shift->payload->{Message}}

1;
