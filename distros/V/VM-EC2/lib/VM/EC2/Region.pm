package VM::EC2::Region;

=head1 NAME

VM::EC2::Region - Object describing an Amazon region

=head1 SYNOPSIS

  use VM::EC2;

  $ec2       = VM::EC2->new(...);
  @regions   = $ec2->describe_regions();

  $region  = $regions[0];
  $name    = $region->regionName;
  $url     = $region->regionEndpoint;
  @zones   = $region->zones;

=head1 DESCRIPTION

This object represents an Amazon EC2 region, and is returned
by VM::EC2->describe_regions().

=head1 METHODS

These object methods are supported:

 regionName      -- Name of the region, e.g. "eu-west-1"
 regionEndpoint  -- URL endpoint for AWS API calls, e.g. 
                    "ec2.eu-west-1.amazonaws.com"
 zones           -- List of availability zones within this
                    region, as VM::EC2::AvailabilityZone
                    objects.

Note that you should prefix the endpoint with http:// or https://
before using it to change the VM::EC2 endpoint with the endpoint()
call. If you do not do so, then https:// will be assumed.

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
regionName.

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

sub primary_id {shift->regionName}

sub valid_fields {
    my $self = shift;
    return qw(regionName regionEndpoint);
}

sub zones {
    my $self = shift;
    my $aws  = $self->aws;
    # break encapsulation, but it is elegant this way
    local $aws->{endpoint} = 'https://'.$self->regionEndpoint;
    return $aws->describe_availability_zones(-filter=>{'region-name'=>$self});
}

1;
