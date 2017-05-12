package VM::EC2::REST::placement_group;

use strict;
use VM::EC2 '';  # important not to import anything!
package VM::EC2;  # add methods to VM::EC2

VM::EC2::Dispatch->register(
    CreatePlacementGroup              => 'boolean',
    DeletePlacementGroup              => 'boolean',
    DescribePlacementGroups           => 'fetch_items,placementGroupSet,VM::EC2::PlacementGroup',
    );

=head1 NAME VM::EC2::REST::placement_group

=head1 SYNOPSIS

 use VM::EC2 ':hpc'

=head1 METHODS

Placement groups provide low latency and high-bandwidth connectivity
between cluster instances within a single Availability Zone. Create
a placement group and then launch cluster instances into it. Instances
launched within a placement group participate in a full-bisection
bandwidth cluster appropriate for HPC applications.

Implemented:
 CreatePlacementGroup
 DeletePlacementGroup
 DescribePlacementGroups

=head2 @groups = $ec2->describe_placement_groups(@group_names)

=head2 @groups = $ec2->describe_placement_groups(\%filters)

=head2 @groups = $ec2->describe_placement_groups(-group_name=>\@ids,-filter=>\%filters)

This method will return information about cluster placement groups
as a list of VM::EC2::PlacementGroup objects.

Optional arguments:

 -group_name         -- Scalar or arrayref of placement group names.

 -filter             -- Tags and other filters to apply.

The filters available are described fully at:
http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribePlacementGroups.html

    group-name
    state
    strategy

=cut

sub describe_placement_groups {
    my $self = shift;
    my %args = $self->args('-group_name',@_);
    my @params = $self->list_parm('GroupName',\%args);
    push @params,$self->filter_parm(\%args);
    return $self->call('DescribePlacementGroups',@params);
}

=head2 $success = $ec2->create_placement_group($group_name)

=head2 $success = $ec2->create_placement_group(-group_name=>$name,-strategy=>$strategy)

Creates a placement group that cluster instances are launched into.

Required arguments:
 -group_name          -- The name of the placement group to create

Optional:
 -strategy            -- As of 2012-12-23, the only available option is 'cluster'
                         so the parameter defaults to that.

Returns true on success.

=cut

sub create_placement_group {
    my $self = shift;
    my %args = $self->args('-group_name',@_);
    $args{-strategy} ||= 'cluster';
    my @params  = $self->single_parm('GroupName',\%args);
    push @params, $self->single_parm('Strategy',\%args);
    return $self->call('CreatePlacementGroup',@params);
}

=head2 $success = $ec2->delete_placement_group($group_name)

=head2 $success = $ec2->delete_placement_group(-group_name=>$group_name)

Deletes a placement group from the account.

Required arguments:
 -group_name          -- The name of the placement group to delete

Returns true on success.

=cut

sub delete_placement_group {
    my $self = shift;
    my %args = $self->args('-group_name',@_);
    my @params  = $self->single_parm('GroupName',\%args);
    return $self->call('DeletePlacementGroup',@params);
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
