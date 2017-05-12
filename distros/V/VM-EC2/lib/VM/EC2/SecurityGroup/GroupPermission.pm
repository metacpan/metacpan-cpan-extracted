package VM::EC2::SecurityGroup::GroupPermission;

=head1 NAME

VM::EC2::SecurityGroup::GroupPermission - Object describing an authorized group within a security group firewall rule

=head1 SYNOPSIS

  $ec2      = VM::EC2->new(...);
  $sg       = $ec2->describe_security_groups(-name=>'My Group');
  @rules = $sg->ipPermissions;
  $rule  = $rules[0];

  @groups = $rule->groups;
  for my $g (@groups) {
    $userId = $g->userId;
    $name   = $g>groupName;
    $id     = $g->groupId;
    $group_object = $g->security_group;
  }

=head1 DESCRIPTION

This object describes a security group whose instances are granted
permission to exchange data traffic with another group of
instances. It is returned by the groups() method of
L<VM::EC2::SecurityGroup::ipPermission>.

Note that this object is not the same as a bona fide
L<VM::EC2::SecurityGroup>, which has access to the group's firewall
rules. This object contains just the name, id and owner of a group
used within a firewall rule. For groups that belong to you, you can
get the full VM::EC2::SecurityGroup object by calling the
security_group() method. These details are not available to groups
that belong to other accounts.

=head1 METHODS

=cut


use strict;
use base 'VM::EC2::Generic';

=head2 $id = $group->groupId

Return the group's unique ID.

=head2 $id = $group->userId

Return the account ID of the owner of this group.

=head2 $id = $group->groupName

Return this group's name.

=cut

sub valid_fields {
    qw(userId groupId groupName);
}

=head2 $string = $group->short_name

Return a string for use in string overloading. See L</STRING
OVERLOADING>.

=cut

sub short_name {
    my $self = shift;
    my $name   = $self->groupName or return $self->groupId;
    my $userid = $self->userId;
    my $ownerid= $self->ownerId;
    my $gname  = $userid eq $ownerid ? $name : "$userid/$name";
    return $gname;
}

=head2 $sg = $group->security_group

For groups that belong to the current account, calls
VM::EC2->describe_security_groups() to turn the group name into a
L<VM::EC2::SecurityGroup>. For groups that belong to a different
account, will return undef, since describe_security_groups() on other
accounts is not allowed by Amazon.

=cut

sub security_group {
    my $self = shift;
    my $gid  = $self->groupId or return;
    return $self->aws->describe_security_groups($gid);
}

sub ownerId {
    my $self = shift;
    my $d    = $self->{ownerId};
    $self->{ownerId} = shift if @_;
    $d;
}

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the user
id and group name in the form "userId/groupName" for groups that
belong to other accounts, and the groupName alone in the case of
groups that belong to you.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::SecurityGroup>
L<VM::EC2::SecurityGroup::IpPermission>

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

