package VM::EC2::REST::reserved_instance;

use strict;
use VM::EC2 '';  # important not to import anything!
package VM::EC2;  # add methods to VM::EC2
require VM::EC2::ReservedInstance::ParmParser;

VM::EC2::Dispatch->register(
    CancelReservedInstancesListing     => 'fetch_items,reservedInstancesListingsSet,VM::EC2::ReservedInstance::Listing',
    CreateReservedInstancesListing     => 'fetch_items,reservedInstancesListingsSet,VM::EC2::ReservedInstance::Listing',
    DescribeReservedInstances          => 'fetch_items,reservedInstancesSet,VM::EC2::ReservedInstance',
    DescribeReservedInstancesListings  => 'fetch_items,reservedInstancesListingsSet,VM::EC2::ReservedInstance::Listing',
    DescribeReservedInstancesModifications =>
                                           'fetch_items,reservedInstancesModificationsSet,VM::EC2::ReservedInstance::Modification',
    DescribeReservedInstancesOfferings => 'fetch_items,reservedInstancesOfferingsSet,VM::EC2::ReservedInstance::Offering',
    ModifyReservedInstances            => sub { my ($data,$ec2) = @_;
						return $data->{reservedInstancesModificationId}; },
    PurchaseReservedInstancesOffering  => sub { my ($data,$ec2) = @_;
						my $ri_id = $data->{reservedInstancesId} or return;
						return $ec2->describe_reserved_instances($ri_id); },
    );

my $VEP = 'VM::EC2::ReservedInstance::ParmParser';

=head1 NAME VM::EC2::REST::reserved_instance

=head1 SYNOPSIS

 use VM::EC2 ':misc'

=head1 METHODS

These methods apply to describing, purchasing and using Reserved Instances.

Implemented:
 CancelReservedInstancesListing
 DescribeReservedInstances
 DescribeReservedInstancesListings
 DescribeReservedInstancesModifications
 DescribeReservedInstancesOfferings
 ModifyReservedInstances
 PurchaseReservedInstancesOffering
 CreateReservedInstancesListing

Unimplemented:
 (none)

=head2 @offerings = $ec2->describe_reserved_instances_offerings(@offering_ids)

=head2 @offerings = $ec2->describe_reserved_instances_offerings(%args)

This method returns a list of the reserved instance offerings
currently available for purchase. The arguments allow you to filter
the offerings according to a variety of filters. 

All arguments are optional. If no named arguments are used, then the
arguments are treated as Reserved Instance Offering IDs.
 
 -reserved_instances_offering_id  A scalar or arrayref of reserved
                                   instance offering IDs

 -instance_type                   The instance type on which the
                                   reserved instance can be used,
                                   e.g. "c1.medium"

 -availability_zone, -zone        The availability zone in which the
                                   reserved instance can be used.

 -product_description             The reserved instance description.
                                   Valid values are "Linux/UNIX",
                                   "Linux/UNIX (Amazon VPC)",
                                   "Windows", and "Windows (Amazon
                                   VPC)"

 -instance_tenancy                The tenancy of the reserved instance
                                   offering, either "default" or
                                   "dedicated". (VPC instances only)

 -offering_type                  The reserved instance offering type, one of
                                   "Heavy Utilization", "Medium Utilization",
                                   or "Light Utilization".

 -filter                          A set of filters to apply.

For available filters, see http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeReservedInstancesOfferings.html.

The returned objects are of type L<VM::EC2::ReservedInstance::Offering>

This can be combined with the Offering purchase() method as shown here:

 @offerings = $ec2->describe_reserved_instances_offerings(
          {'availability-zone'   => 'us-east-1a',
           'instance-type'       => 'c1.medium',
           'product-description' =>'Linux/UNIX',
           'duration'            => 31536000,  # this is 1 year
           });
 $offerings[0]->purchase(5) and print "Five reserved instances purchased\n";

=cut

sub describe_reserved_instances_offerings {
    my $self = shift;
    my %args = $VEP->args(-reserved_instances_offering_id,@_);
    $args{-availability_zone} ||= $args{-zone};
    my @param = $VEP->format_parms(\%args,
        {
            list_parm   => 'ReservedInstancesOfferingId',
            single_parm => [qw(ProductDescription InstanceType AvailabilityZone
                               InstanceTenancy OfferingType)],
            filter_parm => 'Filter',
        });
    return $self->call('DescribeReservedInstancesOfferings',@param);
}

=head $id = $ec2->purchase_reserved_instances_offering($offering_id)

=head $id = $ec2->purchase_reserved_instances_offering(%args)

Purchase one or more reserved instances based on an offering.

Arguments:

 -reserved_instances_offering_id, -id -- The reserved instance offering ID
                                         to purchase (required).

 -instance_count, -count              -- Number of instances to reserve
                                          under this offer (optional, defaults
                                          to 1).


Returns a Reserved Instances Id on success, undef on failure. Also see the purchase() method of
L<VM::EC2::ReservedInstance::Offering>.

=cut

sub purchase_reserved_instances_offering {
    my $self = shift;
    my %args = $VEP->args(-reserved_instances_offering_id,@_);
    $args{-reserved_instances_offering_id} ||= $args{-id};
    $args{-reserved_instances_offering_id} or 
	croak "purchase_reserved_instances_offering(): the -reserved_instances_offering_id argument is required";
    $args{-instance_count} ||= $args{-count};
    my @param = $VEP->format_parms(\%args,
        {
            single_parm => [qw(ReservedInstancesOfferingId InstanceCount)],
        });
    return $self->call('PurchaseReservedInstancesOffering',@param);
}

=head2 @res_instances = $ec2->describe_reserved_instances(@res_instance_ids)

=head2 @res_instances = $ec2->describe_reserved_instances(%args)

This method returns a list of the reserved instances that you
currently own.  The information returned includes the type of
instances that the reservation allows you to launch, the availability
zone, and the cost per hour to run those reserved instances.

All arguments are optional. If no named arguments are used, then the
arguments are treated as Reserved Instance IDs.
 
 -reserved_instances_id -- A scalar or arrayref of reserved
                           instance IDs

 -filter                -- A set of filters to apply.

For available filters, see http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeReservedInstances.html.

The returned objects are of type L<VM::EC2::ReservedInstance>

=cut

sub describe_reserved_instances {
    my $self = shift;
    my %args = $VEP->args(-reserved_instances_id,@_);
    my @param = $VEP->format_parms(\%args,
                                    {
                                        list_parm   => 'ReservedInstancesId',
                                        filter_parm => 'Filter',
                                    });
    return $self->call('DescribeReservedInstances',@param);
}

=head2 $id = $ec2->modify_reserved_instances(%args)

Modifies the Availability Zone, instance count, instance type, or network
platform (EC2-Classic or EC2-VPC) of your Reserved Instances. The Reserved
Instances to be modified must be identical, except for Availability Zone,
network platform, and instance type.

Required arguments:

 -reserved_instances_id         -- The IDs of the Reserved Instances to modify
                                   Can be scalar or arrayref.

 -target_configuration          -- The configuration settings for the Reserved
                                   Instances to modify

                                   Must be a hashref or arrayref of hashes with
                                   one or more of the following values:
                                     AvailabilityZone, Platform, InstanceType
                                   The following is also REQUIRED:
                                     InstanceCount

 -id                            -- Alias for -reserved_instances_id

Returns the reserved instances modification ID string.

=cut

sub modify_reserved_instances {
    my $self = shift;
    my %args = @_;
    $args{-reserved_instances_id} ||= $args{-id};
    $args{-reserved_instances_id} or 
	croak "modify_reserved_instances(): -reserved_instances_id argument required";
    $args{-target_configuration} or 
	croak "modify_reserved_instances(): -target_configuration argument required";
    my @param = $VEP->format_parms(\%args,
        {
            list_parm             => 'ReservedInstancesId',
            ri_target_config_parm => 'TargetConfiguration',
        });
    return $self->call('ModifyReservedInstances',@param);
}

=head2 @mods = $ec2->describe_reserved_instances_modifications(@ids)

=head2 @mods = $ec2->describe_reserved_instances_modifications(%args)

Describes the modifications made to your Reserved Instances.

All arguments are optional. If no named arguments are used, then the
arguments are treated as Reserved Instance Modification IDs.
 
 -reserved_instances_modification_id -- A scalar or arrayref of reserved
                                        instance modification IDs

 -filter                             -- A set of filters to apply.

 -id                                 -- Alias for -reserved_instances_modification_id

For available filters, see:
http://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeReservedInstancesModifications.html

The returned objects are of type L<VM::EC2::ReservedInstance::Modification>

=cut

sub describe_reserved_instances_modifications {
    my $self = shift;
    my %args = $VEP->args(-reserved_instances_modification_id,@_);
    $args{-reserved_instances_modification_id} ||= $args{-id};
    my @param = $VEP->format_parms(\%args,
        {
            list_parm   => 'ReservedInstancesModificationId',
            filter_parm => 'Filter',
        });
    return $self->call('DescribeReservedInstancesModifications',@param);
}

=head2 @list = $ec2->describe_reserved_instances_listings(%args)

Describes the account's Reserved Instance listings in the Reserved Instance
Marketplace.

All arguments are optional. If no named arguments are used, then the
arguments are treated as Reserved Instance Listing IDs.

 -reserved_instances_listing_id      -- A scalar or arrayref of reserved
                                        instance listing IDs

 -reserved_instances_id              -- A scalar or arrayref of reserved
                                        instance IDs 

 -filter                             -- A set of filters to apply.
 
For available filters, see:
http://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeReservedInstancesListings.html

The returned objects are of type L<VM::EC2::ReservedInstance::Listing>

=cut

sub describe_reserved_instances_listings {
    my $self = shift;
    my %args = $VEP->args(-reserved_instances_listing_id,@_);
    my @param = $VEP->format_parms(\%args,
        {
            list_parm   => [qw(ReservedInstancesListingId ReservedInstancesId)],
            filter_parm => 'Filter',
        });
    return $self->call('DescribeReservedInstancesListings',@param);
}

=head2 $listing = $ec2->cancel_reserved_instances_listing(%args)

Cancels the specified Reserved Instance listing in the Reserved Instance
Marketplace.

Required arguments:

 -reserved_instances_listing_id    -- The ID of the Reserved Instance listing
                                      to be canceled

Returns an object of type L<VM::EC2::ReservedInstance::Listing>

=cut

sub cancel_reserved_instances_listing {
    my $self = shift;
    my %args = $VEP->args(-reserved_instances_listing_id,@_);
    my @param = $VEP->format_parms(\%args,
        {
            single_parm => 'ReservedInstancesListingId',
        });
    return $self->call('CancelReservedInstancesListing',@param);
}

=head2 $listing = $ec2->create_reserved_instances_listing(%args)

Creates a listing for Amazon EC2 Reserved Instances to be sold in the Reserved
Instance Marketplace. Only one Reserved Instance listing may be created at a
time.

Required arguments:

 -reserved_instances_id   -- The ID of the active Reserved Instance

 -instance_count          -- The number of instances to be listed in the
                             Reserved Instance Marketplace. This number
                             should be less than or equal to the instance count
                             associated with the Reserved Instance ID specified

 -price_schedules         -- hashref containing term/price pairs for months
                             the Reserved Instance has remaining in its term

                             For example, with a RI with 11 months to go:

                             { 11 => 2.5,
                                8 => 2.0,
                                5 => 1.5,
                                3 => 0.7,
                                1 => 0.1 }

                             For months 11,10,9 the price is $2.50, 8,7,6 is
                             $2.00, 5,4 is $1.50, 3,2 is $0.70 and the last
                             month is $0.10.

                             For more details, see the API docs at:
http://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-CreateReservedInstancesListing.html
                             

 -client_token            -- Unique, case-sensitive identifier to ensure
                             idempotency of listings

Returns an object of type L<VM::EC2::ReservedInstance::Listing>

=cut

sub create_reserved_instances_listing {
    my $self = shift;
    my %args = $VEP->args(-reserved_instances_listing_id,@_);
    $args{-reserved_instances_id} or
	croak "create_reserved_instances_listing(): -reserved_instances_id argument required";
    $args{-instance_count} or
	croak "create_reserved_instances_listing(): -instance_count argument required";
    $args{-price_schedules} or
	croak "create_reserved_instances_listing(): -price_schedules argument required";
    $args{-client_token} or
	croak "create_reserved_instances_listing(): -client_token argument required";
    ref $args{-price_schedules} eq 'HASH' or
	croak "create_reserved_instances_listing(): -price_schedules argument must be hashref";

    my @param = $VEP->format_parms(\%args,
        {
            single_parm         => [qw(ReservedInstancesId InstanceCount
                                       ClientToken)],
            ri_price_sched_parm => 'PriceSchedules',
        });
    return $self->call('CreateReservedInstancesListing',@param);
}

=head1 SEE ALSO

L<VM::EC2>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Lance Kinley E<lt>lkinley@loyaltymethods.comE<gt>.

Copyright (c) 2011 Ontario Institute for Cancer Research

Copyright (c) 2014 Loyalty Methods, Inc.

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

1;
