package VM::EC2::NetworkInterface::Attachment;

=head1 NAME

VM::EC2::NetworkInterface::Attachment -- Object representing attachment of a network interface to an instance

=head1 SYNOPSIS

  use VM::EC2;
  my $ec2 = VM::EC2->new(...);
  my $instance = $ec2->describe_instances('i-123456');
  my @interfaces = $instance->network_interfaces();
  for my $i (@interfaces) {
     my $attachment = $i->attachment;
     my $att_id      = $attachment->attachmentId;
     my $ins_id      = $attachment->instanceId;
     my $instance    = $attachment->instance;
     my $device      = $attachment->device;
     my $status      = $attachment->status;
     my $time        = $attachment->attachmentTime;
     my $delete      = $attachment->deleteOnTermination;
  }

=head1 DESCRIPTION

This object describes the attachment of a elastic network interface
(ENI) to an instance, and allows you to manipulate the attachment.

Please see L<VM::EC2::Generic> for methods shared by all VM::EC2
objects.

=head1 METHODS

These object methods are supported:

 attachmentId          -- ID of the attachment
 instanceId            -- ID of the instance
 instanceOwnerId       -- ID of the owner of the instance
 deviceIndex           -- Ethernet device number, e.g. "0" for eth0
 status                -- Always "attached"; see below.
 attachmentTime        -- Time this ENI was attached to the instance, as a DateTime
 deleteOnTermination   -- If true, this ENI will be deleted when the instance terminates.

Amazon does not document the network interface attachment object well,
and many of these fields are inferred by inspection of EC2 REST
responses. In particular, the status field always seems to be
"attached", but there may be another state, such as "pending", which
is too short lived to be apparent.

In addition, this object supports the following convenience methods:

 instance    -- The VM::EC2::Instance to which the ENI is attached.

=head1 STRING OVERLOADING

When used in a string context, this object will be interpolated as the
attachmentId.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2012 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use base 'VM::EC2::Generic';

sub valid_fields { return qw(attachmentId instanceId instanceOwnerId deviceIndex status
                             attachTime deleteOnTermination) }

sub short_name { shift->attachmentId }

sub device { my $index = shift->deviceIndex; return "eth${index}"}

sub instance {
    my $self = shift;
    my $id   = $self->instanceId;
    return $self->aws->describe_instances($id);
}

sub deleteOnTermination {
    return shift->SUPER::deleteOnTermination =~ /true/i;
}


1;
