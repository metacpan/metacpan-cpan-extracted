package VM::EC2::REST::zone;

use strict;
use VM::EC2 '';  # important not to import anything!
package VM::EC2;  # add methods to VM::EC2

VM::EC2::Dispatch->register(
    DescribeRegions   => 'fetch_items,regionInfo,VM::EC2::Region',
    DescribeAvailabilityZones  => 'fetch_items,availabilityZoneInfo,VM::EC2::AvailabilityZone',
);

=head1 NAME VM::EC2::REST::zone

=head1 SYNOPSIS

 use VM::EC2 qw(:standard);

=head1 EC2 REGIONS AND AVAILABILITY ZONES

This section describes methods that allow you to fetch information on
EC2 regions and availability zones. These methods return objects of
type L<VM::EC2::Region> and L<VM::EC2::AvailabilityZone>.

Implemented:
 DescribeAvailabilityZones
 DescribeRegions

Unimplemented:
 (none)

=head2 @regions = $ec2->describe_regions(@list)

=head2 @regions = $ec2->describe_regions(-region_name=>\@list)

Describe regions and return a list of VM::EC2::Region objects. Call
with no arguments to return all regions. You may provide a list of
regions in either of the two forms shown above in order to restrict
the list returned. Glob-style wildcards, such as "*east") are allowed.

=cut

sub describe_regions {
    my $self = shift;
    my %args = $self->args('-region_name',@_);
    my @params = $self->list_parm('RegionName',\%args);
    push @params,$self->filter_parm(\%args);
    return $self->call('DescribeRegions',@params);
}

=head2 @zones = $ec2->describe_availability_zones(@names)

=head2 @zones = $ec2->describe_availability_zones(-zone_name=>\@names,-filter=>\%filters)

Describe availability zones and return a list of
VM::EC2::AvailabilityZone objects. Call with no arguments to return
all availability regions. You may provide a list of zones in either
of the two forms shown above in order to restrict the list
returned. Glob-style wildcards, such as "*east") are allowed.

If you provide a single argument consisting of a hashref, it is
treated as a -filter argument. In other words:

 $ec2->describe_availability_zones({state=>'available'})

is equivalent to

 $ec2->describe_availability_zones(-filter=>{state=>'available'})

Availability zone filters are described at
http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeAvailabilityZones.html

=cut

sub describe_availability_zones {
    my $self = shift;
    my %args = $self->args('-zone_name',@_);
    my @params = $self->list_parm('ZoneName',\%args);
    push @params,$self->filter_parm(\%args);
    return $self->call('DescribeAvailabilityZones',@params);
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
