package VM::EC2::Image;

=head1 NAME

VM::EC2::Image - Object describing an Amazon Machine Image (AMI)

=head1 SYNOPSIS

  use VM::EC2;

  $ec2     = VM::EC2->new(...);
  $image   = $ec2->describe_images(-image_id=>'ami-12345');

  $state   = $image->imageState;
  $owner   = $image->imageOwnerId;
  $rootdev = $image->rootDeviceName;
  @devices = $image->blockDeviceMapping;
  $tags    = $image->tags;

  @instances = $image->run_instances(-min_count=>10);

=head1 DESCRIPTION

This object represents an Amazon Machine Image (AMI), and is returned
by VM::EC2->describe_images(). In addition to methods to query the
image's attributes, the run_instances() method allows you to launch
and configure EC2 instances based on the AMI.

=head1 METHODS

These object methods are supported:

 imageId       -- AMI ID
 imageLocation -- Location of the AMI
 imageState    -- Current state of the AMI. One of "available",
                  "pending" or "failed". Only "available" AMIs
                  can be launched.
 imageOwnerId  -- AWS account ID of the image owner.
 isPublic      -- Returns true if this image has public launch
                  permissions. Note that this is a Perl boolean,
                  and not the string "true".
 productCodes  -- A list of product codes associated with the image.
 architecture  -- The architecture of the image.
 imageType     -- The image type (machine, kernel or RAM disk).
 kernelId      -- The kernel associated with the image.
 ramdiskId     -- The RAM disk associated with the image.
 platform      -- "Windows" for Windows AMIs, otherwise undef.
 sriovNetSupport -- Specifies whether enhanced networking is enabled.
                    "simple" if enabled.
 stateReason   -- Explanation of a "failed" imageState. This is
                  a VM::EC2::Instance::State::Reason
                  object.
 imageOwnerAlias -The AWS account alias (e.g. "self") or AWS
                  account ID that owns the AMI.
 name          -- Name of the AMI provided during image creation.
 description   -- Description of the AMI provided during image
                  creation.
 rootDeviceType -- The root device type. One of "ebs" or
                  "instance-store".
 rootDeviceName -- Name of the root device, e.g. "/dev/sda1"
 blockDeviceMapping -- List of block devices attached to this
                   image. Each element is a
                   VM::EC2::BlockDevice.
 virtualizationType -- One of "paravirtual" or "hvm".
 hypervisor     -- One of "ovm" or "xen"

In addition, the object supports the tags() method described in
L<VM::EC2::Generic>:

 print "ready for production\n" if $image->tags->{Released};

=head2 @instances = $image->run_instances(%args)

The run_instance() method will launch one or more instances based on
this AMI. The method takes all the arguments recognized by
VM::EC2->run_instances(), except for the -image_id argument. The
method returns a list of VM::EC2::Instance objects, which you may
monitor periodically until they are up and running.

All arguments are optional. See run_instances() in L<VM::EC2> for 
more information.

  -min_count         Minimum number of instances to launch [1]
  -max_count         Maximum number of instances to launch [1]
  -key_name          Name of the keypair to use
  -security_group_id Security group ID to use for this instance.
                     Use an arrayref for multiple group IDs
  -security_group    Security group name to use for this instance.
                     Use an arrayref for multiple values.
  -user_data         User data to pass to the instances. Do NOT base64
                     encode this. It will be done for you.
  -instance_type     Type of the instance to use. See below for a
                     list.
  -placement_zone    The availability zone you want to launch the
                     instance into. Call $ec2->regions for a list.
  -placement_group   An existing placement group to launch the
                     instance into. Applicable to cluster instances
                     only.
  -placement_tenancy Specify 'dedicated' to launch the instance on a
                     dedicated server. Only applicable for VPC
                     instances.
  -kernel_id         ID of the kernel to use for the instances,
                     overriding the kernel specified in the image.
  -ramdisk_id        ID of the ramdisk to use for the instances,
                     overriding the ramdisk specified in the image.
  -block_devices     Specify block devices to map onto the instances,
                     overriding the values specified in the image.
                     This can be a scalar string or an arrayref for
                     multiple mappings:
                     Example: 
                     ['/dev/sdb=ephemeral0','/dev/sdc=snap-12345:80:false']
  -monitoring        Pass a true value to enable detailed monitoring.
  -subnet_id         ID of the subnet to launch the instance
                     into. Only applicable for VPC instances.
  -termination_protection  Pass true to lock the instance so that it
                     cannot be terminated using the API. Use
                     modify_instance() to unset this if youu wish to
                     terminate the instance later.
  -disable_api_termination -- Same as above.
  -shutdown_behavior Pass "stop" (the default) to stop the instance
                     and save its disk state when "shutdown" is called
                     from within the instance. Stopped instances can
                     be restarted later. Pass "terminate" to
                     instead terminate the instance and discard its
                     state completely.
  -instance_initiated_shutdown_behavior -- Same as above.
  -private_ip_address Assign the instance to a specific IP address
                     from a VPC subnet (VPC only).
  -client_token      Unique identifier that you can provide to ensure
                     idempotency of the request. You can use
                     $ec2->token() to generate a suitable identifier.
                     See http://docs.amazonwebservices.com/AWSEC2/
                         latest/UserGuide/Run_Instance_Idempotency.html

Note that after launching an instance, you may need to wait a few
seconds before adding tags to it or performing other operations.

See L<VM::EC2> for details.

=head2 $boolean = $image->make_public($public)

Change the isPublic flag. Provide a true value to make the image
public, a false one to make it private.

=head2 $state  = $image->current_status

Refreshes the object and then calls imageState() to return one of
"pending", "available" or "failed." You can use this to monitor an
image_creation process in progress.

=head2 @user_ids = $image->launchPermissions

Returns a list of user IDs with launch permission for this
image. Note that the AWS API calls this
"launchPermission", but this module makes it plural to emphasize that
the result is a list.

=head2 @user_ids = $image->authorized_users

The same as launchPermissions.

=head2 $boolean = $image->add_authorized_users($id1,$id2,...)

=head2 $boolean = $image->remove_authorized_users($id1,$id2,...)

These methods add and remove user accounts which have launch
permissions for the image. The result code indicates whether the list
of user IDs were successfully added or removed.

=head2 $boolean = $image->add_authorized_users($id1,$id2,...)

=head2 $boolean = $image->remove_authorized_users($id1,$id2,...)

=head2 $boolean = $image->reset_authorized_users

These methods add and remove user accounts which have launch
permissions for the image. The result code indicates whether the list
of user IDs were successfully added or removed.

reset_authorized_users() resets the list users authored to launch
instances from this image to empty, effectively granting launch
privileges to the owner only.

See also authorized_users().

=head2 $copy = $image->copy(-region => $region, -name => $name, -description => $desc)

Copies the image to another region.

Required arguments:

 -region           The region to copy to

Optional arguments:

 -name             The name of the image.

 -description      The description of the image.

 -client_token     Unique identifier to ensure idempotency of the request

=head2 $image->refresh

This method will refresh the object from AWS, updating all values to
their current ones. You can call it after tagging or otherwise
changing image attributes.

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
imageId.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::BlockDevice>
L<VM::EC2::StateReason>
L<VM::EC2::Instance>
L<VM::EC2::Tag>

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
use VM::EC2::BlockDevice;
use VM::EC2::Image::LaunchPermission;
use VM::EC2::Instance::State::Reason;
use VM::EC2::ProductCode;

use Carp 'croak';

sub valid_fields {
    my $self = shift;
    return qw(imageId imageLocation imageState imageOwnerId isPublic
              productCodes architecture imageType kernelId ramdiskId
              platform sriovNetSupport stateReason imageOwnerAlias name
              description rootDeviceType rootDeviceName blockDeviceMapping
              virtualizationType tagSet hypervisor);
}

sub primary_id { shift->imageId }

sub stateReason {
    my $self  = shift;
    my $state = $self->SUPER::stateReason;
    return VM::EC2::Instance::State::Reason->new($state);

}

sub productCodes {
    my $self = shift;
    if (@_) {
	$self->aws->modify_image_attribute($self,-product_code=>\@_);
    } else {
	my $codes = $self->SUPER::productCodes or return;
	return map {VM::EC2::ProductCode->new($_)} @{$codes->{item}};
    }
}

sub blockDeviceMapping {
    my $self = shift;
    my $mapping = $self->SUPER::blockDeviceMapping or return;
    return map { VM::EC2::BlockDevice->new($_,$self->aws)} @{$mapping->{item}};
}

sub launchPermissions {
    my $self = shift;
    return map {VM::EC2::Image::LaunchPermission->new($_,$self->aws)}
        $self->aws->describe_image_attribute($self->imageId,'launchPermission');
}

sub isPublic {
    my $self = shift;
    return $self->SUPER::isPublic eq 'true';
}

sub make_public {
    my $self = shift;
    @_ == 1 or croak "Usage: VM::EC2::Image->make_public(\$boolean)";
    my $public = shift;
    my @arg    = $public ? (-launch_add_group=>'all') : (-launch_remove_group=>'all');
    my $result = $self->aws->modify_image_attribute($self->imageId,@arg) or return;
    $self->payload->{isPublic} = $public ? 'true' : 'false';
    return $result
}

sub authorized_users { shift->launchPermissions }

sub add_authorized_users {
    my $self = shift;
    @_ or croak "Usage: VM::EC2::Image->add_authorized_users(\@userIds)";
    return $self->aws->modify_image_attribute($self->imageId,-launch_add_user=>\@_);
}

sub remove_authorized_users {
    my $self = shift;
    @_ or croak "Usage: VM::EC2::Image->remove_authorized_users(\@userIds)";
    return $self->aws->modify_image_attribute($self->imageId,-launch_remove_user=>\@_);
}

sub reset_authorized_users {
    my $self = shift;
    $self->aws->reset_image_attribute($self->imageId,'launchPermission');
}

sub run_instances {
    my $self = shift;
    my %args = @_;
    croak "$self is unavailable for launching because its state is ",$self->imageState
	      unless $self->imageState eq 'available';
    $args{-image_id} = $self->imageId;
    $self->aws->run_instances(%args);
}

sub current_status {
    my $self = shift;
    $self->refresh;
    return $self->imageState;
}

sub current_status_async {
    my $self = shift;
    my $to_caller = VM::EC2->condvar;

    my $cv = $self->aws->describe_images_async(-image_id=>$self->imageId);

    $cv->cb(sub {
	my $i = shift->recv;
	$to_caller->send($i->imageState)
	    });

    return $to_caller;
}


sub refresh {
    my $self = shift;
    my $i   = shift;
    ($i) = $self->aws->describe_images(-image_id=>$self->imageId) unless $i;
    %$self  = %$i if $i;
    return defined $i;
}

sub copy {
    my $self = shift;
    my %args = @_;
    my $image_id = $self->imageId;
    my $name = $args{-name};
    my $desc = $args{-description} || $args{-desc};
    my $token = $args{-client_token} || $args{-token};
    my $region = $args{-region} or croak "copy(): -region argument required";
    my $orig_region = $self->aws->region;
    # set region to dest region in ec2 object
    $self->aws->region($region);
    my $image = $self->aws->copy_image(-source_region=>$orig_region, -source_image_id=>$image_id, -name => $name, -description=>$desc, -client_token => $token);
    # set region back
    $self->aws->region($orig_region);
    return $image;
}

1;
