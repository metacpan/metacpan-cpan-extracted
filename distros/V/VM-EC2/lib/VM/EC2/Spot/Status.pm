package VM::EC2::Spot::Status;

=head1 NAME

VM::EC2::Spot::Status - Object describing an Amazon EC2 spot instance status
message 

=head1 SYNOPSIS

See L<VM::EC2/SPOT INSTANCES>, and L<VM::EC2::Spot::InstanceRequest>.

=head1 DESCRIPTION

This object represents an Amazon EC2 spot instance status
message, which is returned by a VM::EC2::Spot::InstanceRequest
object's status() method. It provides information about
the spot instance request status.

=head1 METHODS

These object methods are supported:

 code              -- the status code of the request.
 updateTime        -- the time the status was stated.
 message           -- the description for the status code for the Spot request.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Spot::InstanceRequest>
L<VM::EC2::Error>

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
use VM::EC2::Group;
use base 'VM::EC2::Generic';

sub valid_fields {
    return qw(code updateTime message);
}

sub short_name { shift->code }

1;
