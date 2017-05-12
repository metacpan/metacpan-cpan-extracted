package VM::EC2::REST::spot_instance;

use strict;
use VM::EC2 '';   # important not to import anything!
package VM::EC2;  # add methods to VM::EC2

VM::EC2::Dispatch->register(
    CancelSpotInstanceRequests        => 'fetch_items,spotInstanceRequestSet,VM::EC2::Spot::InstanceRequest',
    CreateSpotDatafeedSubscription    => 'fetch_one,spotDatafeedSubscription,VM::EC2::Spot::DatafeedSubscription',
    DeleteSpotDatafeedSubscription    => 'boolean',
    DescribeSpotDatafeedSubscription  => 'fetch_one,spotDatafeedSubscription,VM::EC2::Spot::DatafeedSubscription',
    DescribeSpotInstanceRequests      => 'fetch_items,spotInstanceRequestSet,VM::EC2::Spot::InstanceRequest',
    DescribeSpotPriceHistory          => 'fetch_items_iterator,spotPriceHistorySet,VM::EC2::Spot::PriceHistory,spot_price_history',
    RequestSpotInstances              => 'fetch_items,spotInstanceRequestSet,VM::EC2::Spot::InstanceRequest',
    );

=head1 NAME VM::EC2::REST::spot_instance

=head1 SYNOPSIS

 use VM::EC2 ':misc';

=head1 METHODS

These methods allow you to request spot instances and manipulate spot
data feed subscriptions.

Implemented:
 CancelSpotInstanceRequests
 CreateSpotDatafeedSubscription
 DeleteSpotDatafeedSubscription
 DescribeSpotDatafeedSubscription
 DescribeSpotInstanceRequests
 DescribeSpotPriceHistory
 RequestSpotInstances

Unimplemented:
 (none)

=cut

=head2 $subscription = $ec2->create_spot_datafeed_subscription($bucket,$prefix)

This method creates a spot datafeed subscription. Provide the method with the
name of an S3 bucket associated with your account, and a prefix to be appended
to the files written by the datafeed. Spot instance usage logs will be written 
into the requested bucket, and prefixed with the desired prefix.

If no prefix is specified, it defaults to "SPOT_DATAFEED_";

On success, a VM::EC2::Spot::DatafeedSubscription object is returned;

Only one datafeed is allowed per account;

=cut

sub create_spot_datafeed_subscription {
    my $self = shift;
    my ($bucket,$prefix) = @_;
    $bucket or croak "Usage: create_spot_datafeed_subscription(\$bucket,\$prefix)";
    $prefix ||= 'SPOT_DATAFEED_';
    my @param = (Bucket => $bucket,
		 Prefix => $prefix);
    return $self->call('CreateSpotDatafeedSubscription',@param);
}

=head2 $boolean = $ec2->delete_spot_datafeed_subscription()

This method delete's the current account's spot datafeed
subscription, if any. It takes no arguments.

On success, it returns true.

=cut

sub delete_spot_datafeed_subscription {
    my $self = shift;
    return $self->call('DeleteSpotDatafeedSubscription');
}

=head2 $subscription = $ec2->describe_spot_datafeed_subscription()

This method describes the current account's spot datafeed
subscription, if any. It takes no arguments.

On success, a VM::EC2::Spot::DatafeedSubscription object is returned;

=cut

sub describe_spot_datafeed_subscription {
    my $self = shift;
    return $self->call('DescribeSpotDatafeedSubscription');
}

=head2 @spot_price_history = $ec2->describe_spot_price_history(@filters)

This method applies the specified filters to spot instances and
returns a list of instances, timestamps and their price at the
indicated time. Each spot price history point is represented as a
VM::EC2::Spot::PriceHistory object.

Option arguments are:

 -start_time      Start date and time of the desired history
                  data, in the form yyyy-mm-ddThh:mm:ss (GMT).
                  The Perl DateTime module provides a convenient
                  way to create times in this format.

 -end_time        End date and time of the desired history
                  data.

 -instance_type   The instance type, e.g. "m1.small", can be
                  a scalar value or an arrayref.

 -product_description  The product description. One of "Linux/UNIX",
                  "SUSE Linux"  or "Windows". Can be a scalar value
                  or an arrayref.

 -availability_zone A single availability zone, such as "us-east-1a".

 -max_results     Maximum number of rows to return in a single
                  call.

 -next_token      Specifies the next set of results to return; used
                  internally.

 -filter          Hashref containing additional filters to apply, 

The following filters are recognized: "instance-type",
"product-description", "spot-price", "timestamp",
"availability-zone". The '*' and '?' wildcards can be used in filter
values, but numeric comparison operations are not supported by the
Amazon API. Note that wildcards are not generally allowed in the
standard options. Hence if you wish to get spot price history in all
availability zones in us-east, this will work:

 $ec2->describe_spot_price_history(-filter=>{'availability-zone'=>'us-east*'})

but this will return an invalid parameter error:

 $ec2->describe_spot_price_history(-availability_zone=>'us-east*')

If you specify -max_results, then the list of history objects returned
may not represent the complete result set. In this case, the method
more_spot_prices() will return true. You can then call
describe_spot_price_history() repeatedly with no arguments in order to
retrieve the remainder of the results. When there are no more results,
more_spot_prices() will return false.

 my @results = $ec2->describe_spot_price_history(-max_results       => 20,
                                                 -instance_type     => 'm1.small',
                                                 -availability_zone => 'us-east*',
                                                 -product_description=>'Linux/UNIX');
 print_history(\@results);
 while ($ec2->more_spot_prices) {
    @results = $ec2->describe_spot_price_history
    print_history(\@results);
 }

=cut

sub more_spot_prices {
    my $self = shift;
    return $self->{spot_price_history_token} &&
           !$self->{spot_price_history_stop};
}

sub describe_spot_price_history {
    my $self = shift;
    my @parms;

    if (!@_ && $self->{spot_price_history_token} && $self->{price_history_args}) {
	@parms = (@{$self->{price_history_args}},NextToken=>$self->{spot_price_history_token});
    }

    else {
	my %args = $self->args('-filter',@_);
	push @parms,$self->single_parm($_,\%args)
	    foreach qw(StartTime EndTime MaxResults AvailabilityZone);
	push @parms,$self->list_parm($_,\%args)
	    foreach qw(InstanceType ProductDescription);
	push @parms,$self->filter_parm(\%args);

	if ($args{-max_results}) {
	    $self->{spot_price_history_token} = 'xyzzy'; # dummy value
	    $self->{price_history_args} = \@parms;
	}
    }

    return $self->call('DescribeSpotPriceHistory',@parms);
}

=head2 @requests = $ec2->request_spot_instances(%args)

This method will request one or more spot instances to be launched
when the current spot instance run-hour price drops below a preset
value and terminated when the spot instance run-hour price exceeds the
value.

On success, will return a series of VM::EC2::Spot::InstanceRequest
objects, one for each instance specified in -instance_count.

=over 4

=item Required arguments:

  -spot_price        The desired spot price, in USD.

  -image_id          ID of an AMI to launch

  -instance_type     Type of the instance(s) to launch, such as "m1.small"
 
=item Optional arguments:

  -instance_count    Maximum number of instances to launch (default 1)

  -type              Spot instance request type; one of "one-time" or "persistent"

  -valid_from        Date/time the request becomes effective, in format
                       yyyy-mm-ddThh:mm:ss. Default is immediately.

  -valid_until       Date/time the request expires, in format 
                       yyyy-mm-ddThh:mm:ss. Default is to remain in
                       effect indefinitely.

  -launch_group      Name of the launch group. Instances in the same
                       launch group are started and terminated together.
                       Default is to launch instances independently.

  -availability_zone_group  If specified, all instances that are given
                       the same zone group name will be launched into the 
                       same availability zone. This is independent of
                       the -availability_zone argument, which specifies
                       a particular availability zone.

  -key_name          Name of the keypair to use

  -security_group_id Security group ID to use for this instance.
                     Use an arrayref for multiple group IDs

  -security_group    Security group name to use for this instance.
                     Use an arrayref for multiple values.

  -user_data         User data to pass to the instances. Do NOT base64
                     encode this. It will be done for you.

  -availability_zone The availability zone you want to launch the
                     instance into. Call $ec2->regions for a list.
  -zone              Short version of -availability_aone.

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
                     See run_instances() for the syntax of this argument.

  -block_device_mapping  Alias for -block_devices.

  -network_interfaces  Same as the -network_interfaces option in run_instances().

  -monitoring        Pass a true value to enable detailed monitoring.

  -subnet            The ID of the Amazon VPC subnet in which to launch the
                      spot instance (VPC only).

  -subnet_id         deprecated

  -addressing_type   Deprecated and undocumented, but present in the
                       current EC2 API documentation.

  -iam_arn           The Amazon resource name (ARN) of the IAM Instance Profile (IIP)
                       to associate with the instances.

  -iam_name          The name of the IAM instance profile (IIP) to associate with the
                       instances.

  -ebs_optimized     If true, request an EBS-optimized instance (certain
                       instance types only).


=cut

sub request_spot_instances {
    my $self = shift;
    my %args = @_;
    $args{-spot_price}       or croak "-spot_price argument missing";
    $args{-image_id}         or croak "-image_id argument missing";
    $args{-instance_type}    or croak "-instance_type argument missing";

    $args{-availability_zone} ||= $args{-zone};
    $args{-availability_zone} ||= $args{-placement_zone};

    my @p = map {$self->single_parm($_,\%args)}
            qw(SpotPrice InstanceCount Type ValidFrom ValidUntil LaunchGroup AvailabilityZoneGroup Subnet);

    # oddly enough, the following args need to be prefixed with "LaunchSpecification."
    my @launch_spec = map {$self->single_parm($_,\%args)}
            qw(ImageId KeyName UserData AddressingType InstanceType KernelId RamdiskId SubnetId);
    push @launch_spec, map {$self->list_parm($_,\%args)}  qw(SecurityGroup SecurityGroupId);
    push @launch_spec, ('EbsOptimized'=>'true')           if $args{-ebs_optimized};
    push @launch_spec, $self->block_device_parm($args{-block_devices}||$args{-block_device_mapping});
    push @launch_spec, $self->iam_parm(\%args);
    push @launch_spec, $self->network_interface_parm(\%args);

    while (my ($key,$value) = splice(@launch_spec,0,2)) {
	push @p,("LaunchSpecification.$key" => $value);
    }
    
    # a few more oddballs
    push @p,('LaunchSpecification.Placement.AvailabilityZone'=> $args{-availability_zone})
	if $args{-availability_zone};
    push @p,('Placement.GroupName'       =>$args{-placement_group})   if $args{-placement_group};
    push @p,('LaunchSpecification.Monitoring.Enabled'   => 'true')    if $args{-monitoring};
    push @p,('LaunchSpecification.UserData' =>
	     encode_base64($args{-user_data},''))                     if $args{-user_data};
    return $self->call('RequestSpotInstances',@p);
}

=head2 @requests = $ec2->cancel_spot_instance_requests(@request_ids)

This method cancels the pending requests. It does not terminate any
instances that are already running as a result of the requests. It
returns a list of VM::EC2::Spot::InstanceRequest objects, whose fields
will be unpopulated except for spotInstanceRequestId and state.

=cut

sub cancel_spot_instance_requests {
    my $self = shift;
    my %args = $self->args('-spot_instance_request_id',@_);
    my @parm = $self->list_parm('SpotInstanceRequestId',\%args);
    # possible bug in AWS: some cancelled instances repeated in list 
    my %c =  map {$_=>$_} $self->call('CancelSpotInstanceRequests',@parm);
    return values %c;
}


=head2 @requests = $ec2->describe_spot_instance_requests(@spot_instance_request_ids)

=head2 @requests = $ec2->describe_spot_instance_requests(\%filters)

=head2 @requests = $ec2->describe_spot_instance_requests(-spot_instance_request_id=>\@ids,-filter=>\%filters)

This method will return information about current spot instance
requests as a list of VM::EC2::Spot::InstanceRequest objects.

Optional arguments:

 -spot_instance_request_id   -- Scalar or arrayref of request Ids.

 -filter                     -- Tags and other filters to apply.

There are many filters available, described fully at
http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/index.html?ApiReference-ItemType-SpotInstanceRequestSetItemType.html:

    availability-zone-group
    create-time
    fault-code
    fault-message
    instance-id
    launch-group
    launch.block-device-mapping.delete-on-termination
    launch.block-device-mapping.device-name
    launch.block-device-mapping.snapshot-id
    launch.block-device-mapping.volume-size
    launch.block-device-mapping.volume-type
    launch.group-id
    launch.image-id
    launch.instance-type
    launch.kernel-id
    launch.key-name
    launch.monitoring-enabled
    launch.ramdisk-id
    launch.network-interface.network-interface-id
    launch.network-interface.device-index
    launch.network-interface.subnet-id
    launch.network-interface.description
    launch.network-interface.private-ip-address
    launch.network-interface.delete-on-termination
    launch.network-interface.group-id
    launch.network-interface.group-name
    launch.network-interface.addresses.primary
    product-description
    spot-instance-request-id
    spot-price
    state
    status-code
    status-message
    tag-key
    tag-value
    tag:<key>
    type
    launched-availability-zone
    valid-from
    valid-until

=cut


sub describe_spot_instance_requests {
    my $self = shift;
    my %args = $self->args('-spot_instance_request_id',@_);
    my @params = $self->list_parm('SpotInstanceRequestId',\%args);
    push @params,$self->filter_parm(\%args);
    return $self->call('DescribeSpotInstanceRequests',@params);
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
