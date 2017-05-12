package VM::EC2::Snapshot::CreateVolumePermission;

=head1 NAME

VM::EC2::Snapshot::CreateVolumePermission - Object describing AMI create volume permissions

=head1 SYNOPSIS

  use VM::EC2;

  $ec2       = VM::EC2->new(...);
  $snapshot  = $ec2->describe_snapshots('snap-12345');
  @users     = $image->createVolumePermissions;
  for (@users) {
    $group = $_->group;
    $user  = $_->userId;
  }

=head1 DESCRIPTION

This object represents an Amazon volume snapshot create volume
permission, and is return by VM::EC2::Snapshot createVolumePermissions().

=head1 METHODS

These object methods are supported:

 group      -- Name of a group with launch permissions. Only
               valid value is "all"
 userId     -- Name of a user with launch permissions.

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
userId. If the userId is blank, then interpolates as the group.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Snapshot>

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
use base 'VM::EC2::Image::LaunchPermission';


1;
