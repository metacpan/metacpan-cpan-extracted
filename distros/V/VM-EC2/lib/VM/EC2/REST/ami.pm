package VM::EC2::REST::ami;

use strict;
use VM::EC2 '';  # important not to import anything!
package VM::EC2;  # add methods to VM::EC2

VM::EC2::Dispatch->register(
    DescribeImages    => 'fetch_items,imagesSet,VM::EC2::Image',
    CreateImage             => sub { shift->{imageId} },
    RegisterImage           => sub { shift->{imageId} },
    DeregisterImage         => 'boolean',
    ModifyImageAttribute    => 'boolean',
    ResetImageAttribute     => 'boolean',
    CopyImage               => sub { shift->{imageId} },
    );

=head1 NAME VM::EC2::REST::ami

=head1 SYNOPSIS

use VM::EC2 ':standard';

=head1 METHODS

These are methods that allow you to fetch and manipulate Amazon Machine Images.

Implemented:
 CopyImage
 CreateImage
 DeregisterImage
 DescribeImageAttribute
 DescribeImages
 ModifyImageAttribute
 RegisterImage
 ResetImageAttribute

Unimplemented:
 (none)

=head1 EC2 AMAZON MACHINE IMAGES

The methods in this section allow you to query and manipulate Amazon
machine images (AMIs). See L<VM::EC2::Image>.

=head2 @i = $ec2->describe_images(@image_ids)

=head2 @i = $ec2->describe_images(-image_id=>\@id,-executable_by=>$id,
                                  -owner=>$id, -filter=>\%filters)

Return a series of VM::EC2::Image objects, each describing an
AMI. Optional arguments:

 -image_id        The id of the image, either a string scalar or an
                  arrayref.

 -executable_by   Filter by images executable by the indicated user account, or
                    one of the aliases "self" or "all".

 -owner           Filter by owner account number or one of the aliases "self",
                    "aws-marketplace", "amazon" or "all".

 -filter          Tags and other filters to apply

If there are no other arguments, you may omit the -filter argument
name and call describe_images() with a single hashref consisting of
the search filters you wish to apply.

The full list of image filters can be found at:
http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeImages.html

=cut

sub describe_images {
    my $self = shift;
    my %args = $self->args(-image_id=>@_);
    my @params;
    push @params,$self->list_parm($_,\%args) foreach qw(ExecutableBy ImageId Owner);
    push @params,$self->filter_parm(\%args);
    return $self->call('DescribeImages',@params);
}

=head2 $image = $ec2->create_image(-instance_id=>$id,-name=>$name,%other_args)

Create an image from an EBS-backed instance and return a
VM::EC2::Image object. The instance must be in the "stopped" or
"running" state. In the latter case, Amazon will stop the instance,
create the image, and then restart it unless the -no_reboot argument
is provided.

Arguments:

 -instance_id    ID of the instance to create an image from. (required)
 -name           Name for the image that will be created. (required)
 -description    Description of the new image.
 -no_reboot      If true, don't reboot the instance.
 -block_device_mapping
                 Block device mapping as a scalar or array ref. See 
                  run_instances() for the syntax.
 -block_devices  Alias of the above

=cut

sub create_image {
    my $self = shift;
    my %args = @_;
    $args{-instance_id} && $args{-name}
      or croak "Usage: create_image(-instance_id=>\$id,-name=>\$name)";
    $args{-block_device_mapping} ||= $args{-block_devices};
    my @param = $self->single_parm('InstanceId',\%args);
    push @param,$self->single_parm('Name',\%args);
    push @param,$self->single_parm('Description',\%args);
    push @param,$self->boolean_parm('NoReboot',\%args);
    push @param,$self->block_device_parm($args{-block_device_mapping});

    my $cv = $self->condvar;
    {
	local $VM::EC2::ASYNC = 1;
	$self->call('CreateImage',@param)->cb(
	    sub {
		my $img_id = shift->recv;
		my $timer; $timer = AnyEvent->timer(after    => 0.5,
						    interval => 1,
						    cb => sub {
							my $di = $self->describe_images_async($img_id);
							$di->cb(sub {
							    if (my $img = shift->recv) {
								$cv->send($img);
								undef $timer;
							    }});
						    });
	    });
    }
    return $VM::EC2::ASYNC ? $cv : $cv->recv;
}

=head2 $image = $ec2->register_image(-name=>$name,%other_args)

Register an image, creating an AMI. This can be used to create an AMI
from a S3-backed instance-store bundle, or to create an AMI from a
snapshot of an EBS-backed root volume.

Required arguments:

 -name                 Name for the image that will be created.

Arguments required for an EBS-backed image:

 -root_device_name     The root device name, e.g. /dev/sda1
 -block_device_mapping The block device mapping strings, including the
                       snapshot ID for the root volume. This can
                       be either a scalar string or an arrayref.
                       See run_instances() for a description of the
                       syntax.
 -block_devices        Alias of the above.

Arguments required for an instance-store image:

 -image_location      Full path to the AMI manifest in Amazon S3 storage.

Common optional arguments:

 -description         Description of the AMI
 -architecture        Architecture of the image ("i386" or "x86_64")
 -kernel_id           ID of the kernel to use
 -ramdisk_id          ID of the RAM disk to use
 -virtualization_type Type of virtualization ("paravirtual" or "hvm")
                      Default is "paravirtual"
 -sriov_net_support   Set to "simple" to enable enhanced networking for the AMI
 
While you do not have to specify the kernel ID, it is strongly
recommended that you do so. Otherwise the kernel will have to be
specified for run_instances().

Note: Immediately after registering the image you can add tags to it
and use modify_image_attribute to change launch permissions, etc.

=cut

sub register_image {
    my $self = shift;
    my %args = @_;

    $args{-name} or croak "register_image(): -name argument required";
    $args{-block_device_mapping} ||= $args{-block_devices};
    if (!$args{-image_location}) {
	$args{-root_device_name} && $args{-block_device_mapping}
	or croak "register_image(): either provide -image_location to create an instance-store AMI\nor both the -root_device_name && -block_device_mapping arguments to create an EBS-backed AMI.";
    }

    my @param;
    for my $a (qw(Name RootDeviceName ImageLocation Description
                  Architecture KernelId RamdiskId VirtualizationType 
                  SriovNetSupport)) {
	push @param,$self->single_parm($a,\%args);
    }
    push @param,$self->block_device_parm($args{-block_devices} || $args{-block_device_mapping});

    return $self->call('RegisterImage',@param);
}

=head2 $result = $ec2->deregister_image($image_id)

Deletes the registered image and returns true if successful.

=cut

sub deregister_image {
    my $self = shift;
    my %args  = $self->args(-image_id => @_);
    my @param = $self->single_parm(ImageId=>\%args);
    return $self->call('DeregisterImage',@param);
}

=head2 @data = $ec2->describe_image_attribute($image_id,$attribute)

This method returns image attributes. Only one attribute can be
retrieved at a time. The following is the list of attributes that can be
retrieved:

 description            -- scalar
 kernel                 -- scalar
 ramdisk                -- scalar
 launchPermission       -- list of scalar
 productCodes           -- array
 blockDeviceMapping     -- list of hashref
 sriovNetSupport        -- scalar

All of these values can be retrieved more conveniently from the
L<VM::EC2::Image> object returned from describe_images(), so there is
no attempt to parse the results of this call into Perl objects. In
particular, 'blockDeviceMapping' is returned as a raw hashrefs (there
also seems to be an AWS bug that causes fetching this attribute to return an
AuthFailure error).

Please see the VM::EC2::Image launchPermissions() and
blockDeviceMapping() methods for more convenient ways to get this
data.

=cut

sub describe_image_attribute {
    my $self = shift;
    @_ == 2 or croak "Usage: describe_image_attribute(\$instance_id,\$attribute_name)";
    my ($instance_id,$attribute) = @_;
    my @param  = (ImageId=>$instance_id,Attribute=>$attribute);
    my $result = $self->call('DescribeImageAttribute',@param);
    return $result && $result->attribute($attribute);
}


=head2 $boolean = $ec2->modify_image_attribute($image_id,-$attribute_name=>$value)

This method changes image attributes. The first argument is the image
ID, and this is followed by the attribute name and the value to change
it to.

The following is the list of attributes that can be set:

 -launch_add_user         -- scalar or arrayref of UserIds to grant launch permissions to
 -launch_add_group        -- scalar or arrayref of Groups to remove launch permissions from
                               (only currently valid value is "all")
 -launch_remove_user      -- scalar or arrayref of UserIds to remove from launch permissions
 -launch_remove_group     -- scalar or arrayref of Groups to remove from launch permissions
 -product_code            -- scalar or array of product codes to add
 -description             -- scalar new description

You can abbreviate the launch permission arguments to -add_user,
-add_group, -remove_user, -remove_group, etc.

Only one attribute can be changed in a single request.

For example:

  $ec2->modify_image_attribute('ami-12345',-product_code=>['abcde','ghijk']);

The result code is true if the attribute was successfully modified,
false otherwise. In the latter case, $ec2->error() will provide the
error message.

To make an image public, specify -launch_add_group=>'all':

  $ec2->modify_image_attribute('i-12345',-launch_add_group=>'all');

Also see L<VM::EC2::Image> for shortcut methods. For example:

 $image->add_authorized_users(1234567,999991);

=cut

sub modify_image_attribute {
    my $self = shift;
    my $image_id = shift or croak "Usage: modify_image_attribute(\$imageId,%param)";
    my %args   = @_;

    # shortcuts
    foreach (qw(add_user remove_user add_group remove_group)) {
	$args{"-launch_$_"} ||= $args{"-$_"};
    }

    my @param  = (ImageId=>$image_id);
    push @param,$self->value_parm('Description',\%args);
    push @param,$self->list_parm('ProductCode',\%args);
    push @param,$self->launch_perm_parm('Add','UserId',   $args{-launch_add_user});
    push @param,$self->launch_perm_parm('Remove','UserId',$args{-launch_remove_user});
    push @param,$self->launch_perm_parm('Add','Group',    $args{-launch_add_group});
    push @param,$self->launch_perm_parm('Remove','Group', $args{-launch_remove_group});
    return $self->call('ModifyImageAttribute',@param);
}

=head2 $boolean = $ec2->reset_image_attribute($image_id,$attribute_name)

This method resets an attribute of the given snapshot to its default
value. The valid attributes are:

 launchPermission


=cut

sub reset_image_attribute {
    my $self = shift;
    @_      == 2 or 
	croak "Usage: reset_image_attribute(\$imageId,\$attribute_name)";
    my ($image_id,$attribute) = @_;
    my %valid = map {$_=>1} qw(launchPermission);
    $valid{$attribute} or croak "attribute to reset must be one of ",join(' ',map{"'$_'"} keys %valid);
    return $self->call('ResetImageAttribute',
		       ImageId    => $image_id,
		       Attribute  => $attribute);
}

=head2 $image = $ec2->copy_image(-source_region   => $src,
                                 -source_image_id => $id,
                                 -name            => $name,
                                 -description     => $desc,
                                 -client_token    => $token)

Initiates the copy of an AMI from the specified source region to the
region in which the API call is executed.

Required arguments:

 -source_region       -- The ID of the AWS region that contains the AMI to be
                         copied (source).

 -source_image_id     -- The ID of the Amazon EC2 AMI to copy.

Optional arguments:

 -name                -- The name of the new EC2 AMI in the destination region.

 -description         -- A description of the new AMI in the destination region.

 -client_token        -- Unique, case-sensitive identifier you provide to ensure
                         idempotency of the request.

Returns a L<VM::EC2::Image> object on success;

=cut

sub copy_image {
    my $self = shift;
    my %args = @_;
    $args{-description} ||= $args{-desc};
    $args{-source_region} ||= $args{-region};
    $args{-source_image_id} ||= $args{-image_id};
    $args{-source_region} or croak "copy_image(): -source_region argument required";
    $args{-source_image_id} or croak "copy_image(): -source_image_id argument required";
    my @params;
    push @params, $self->single_parm($_,\%args)
        foreach qw(SourceRegion SourceImageId Name Description ClientToken);
    my $image_id = $self->call('CopyImage',@params) or return;
    return eval {
            my $image;
            local $SIG{ALRM} = sub {die "timeout"};
            alarm(60);
            until ($image = $self->describe_images($image_id)) { sleep 1 }
            alarm(0);
            $image;
    };
}


=head1 SEE ALSO

L<VM::EC2>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2011 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut


1;
