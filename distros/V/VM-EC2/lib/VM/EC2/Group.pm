package VM::EC2::Group;

=head1 NAME

VM::EC2::Group - Object describing an Amazon EC2 security group name

=head1 SYNOPSIS

  use VM::EC2;

  $ec2      = VM::EC2->new(...);
  $instance = $ec2->describe_instances(-instance_id=>'i-12345');
  my @groups = $instance->groups;
  for my $g (@groups) {
    my $id      = $g->groupId;
    my $name    = $g->groupName;

    # get the security group details
    my $sg      = $ec2->describe_security_group($g);
    my $permissions = $sg->ipPermissions;
  }

=head1 DESCRIPTION

This object represents the name and ID of a security group. It is
returned by an instance's groups() method. This object does not
provide any of the details about the security group, but you can use
it in a call to VM::EC2->describe_security_group() to get details about
the security group's allowed ports, etc.

=head1 METHODS

These object methods are supported:

 groupId   -- the group ID
 groupName -- the group's name

For convenience, the object also provides a permissions() method that
will return the fully detailed VM::EC2::SecurityGroup:

 $details = $group->permissions()

See L<VM::EC2::SecurityGroup>

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
groupId.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Object>
L<VM::EC2::Generic>
L<VM::EC2::SecurityGroup>

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

sub valid_fields {
    my $self  = shift;
    return $self->SUPER::valid_fields,
           qw(groupId groupName);
}

sub primary_id { shift->groupId }

sub groupName {
    my $self = shift;
    my $name = $self->SUPER::groupName;
    $name   =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg; # for some reason this is URI encoded!
    $name;
}

sub permissions {
    my $self = shift;
    return $self->{perm} if exists $self->{perm};
    my @sg   = $self->aws->describe_security_groups(-group_id=>$self->groupId);
    return unless @sg;
    die "more than one security group returned?" if @sg > 1;
    return $self->{perm} = $sg[0];
}

1;

