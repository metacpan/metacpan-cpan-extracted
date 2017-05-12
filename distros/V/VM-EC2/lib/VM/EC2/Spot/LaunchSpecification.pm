package VM::EC2::Spot::LaunchSpecification;

=head1 NAME

VM::EC2::Spot::LaunchSpecification - Object describing an Amazon EC2 spot instance launch specification

=head1 SYNOPSIS

See L<VM::EC2/SPOT INSTANCES>, and L<VM::EC2::Spot::InstanceRequest>.

=head1 DESCRIPTION

This object represents an Amazon EC2 spot instance launch
specification, which is returned by a VM::EC2::Spot::InstanceRequest
object's launchSpecification() method. It provides information about
the spot instance request.

=head1 METHODS

These object methods are supported:

 imageId           -- the ID of the image to be used for the request
 keyName           -- the ssh keyname for instances created by the request
 groupSet          -- a list of VM::EC2::Group objects representing the launch 
                      groups for spot instances created under this request.
 addressingType    -- Deprecated and undocumented, but present in the EC2 API
 instanceType      -- type of instances created by the request
 placement         -- availability zone for instances created by the request
 kernelId          -- kernel ID to be used for instances launched by the request
 ramdiskId         -- ramdisk ID to be used for instances launched by the request
 blockDeviceMapping -- List of VM::EC2::BlockDevice::Mapping objects describing
                      the block devices to be attached to instances launched by the
                      request.
 monitoring        -- A true value if detailed monitoring was requested for these
                      instances.
 subnetId          -- Subnet ID in which to place instances launched under this
                      request (VPC only).

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Spot::InstanceRequest>
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
use VM::EC2::Group;
use base 'VM::EC2::Generic';

sub valid_fields {
    return qw(imageId keyName groupSet addressingType instanceType
              placement kernelId ramdiskId blockDeviceMapping monitoring
              subnetId);
}

sub blockDeviceMapping {
    my $self = shift;
    my $mapping = $self->SUPER::blockDeviceMapping or return;
    my @mapping = map { VM::EC2::BlockDevice::Mapping->new($_,$self->ec2)} @{$mapping->{item}};
    foreach (@mapping) { $_->instance($self) }
    return @mapping;
}

sub monitoring {
    my $self = shift;
    my $monitoring = $self->SUPER::monitoring or return;
    return $monitoring->{enabled} eq 'true';
}

sub groupSet {
    my $self = shift;
    my $groupSet = $self->SUPER::groupSet;
    return map {VM::EC2::Group->new($_,$self->aws,$self->xmlns,$self->requestId)}
        @{$groupSet->{item}};
}

1;
