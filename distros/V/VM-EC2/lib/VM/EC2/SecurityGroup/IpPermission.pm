package VM::EC2::SecurityGroup::IpPermission;

=head1 NAME

VM::EC2::SecurityGroup::IpPermission - Object describing a firewall rule in an EC2 security group.

=head1 SYNOPSIS

  $ec2      = VM::EC2->new(...);
  $sg       = $ec2->describe_security_groups(-name=>'My Group');

  my @rules = $sg->ipPermissions;
  for my $rule (@rules) {   # each rule is a VM::EC2::SecurityGroup::IpPermission
         $protocol = $rule->ipProtocol;
         $fromPort = $rule->fromPort;
         $toPort   = $rule->toPort;
         @ranges   = $rule->ipRanges;
         @groups   = $rule->groups;
  }

=head1 DESCRIPTION

This object is used to describe the firewall rules defined within an
Amazon EC2 security group. It is returned by the
L<VM::EC2::SecurityGroup> object's ipPermissions() and
ipPermissionsEgress() methods (these are also known as
inbound_permissions() and outbound_permissions()).

=head1 METHODS

=cut


use strict;
use base 'VM::EC2::Generic';
use VM::EC2::SecurityGroup::GroupPermission;

=head2 $protocol = $rule->ipProtocol

Return the IP protocol for this rule: one of "tcp", "udp" or "icmp".

=head2 $port = $rule->fromPort

Start of the port range defined by this rule, or the ICMP type
code. This will be a numeric value, like 80, or -1 to indicate all
ports/codes.

=head2 $port = $rule->toPort

End of the port range defined by this rule, or the ICMP type
code. This will be a numeric value, like 80, or -1 to indicate all
ports/codes.

=cut

sub valid_fields {
    qw(ipProtocol fromPort toPort groups ipRanges);
}

sub short_name {
    my $s = shift;
    local $^W = 0;
    my $from = ($s->ipRanges && (' FROM CIDR '.join(',',sort $s->ipRanges))) .
               ($s->groups && (' GRPNAME '.join(',',  sort $s->groups)));
    sprintf("%s(%s..%s)%s",$s->ipProtocol,$s->fromPort,$s->toPort,$from);
}

=head2 @ips = $rule->ipRanges

This method will return a list of the IP addresses that are allowed to
originate or receive traffic, provided that the rule defines IP-based
firewall filtering.

Each address is a CIDR (classless internet domain routing) address in
the form a.b.c.d/n, such as 10.23.91.0/24
(http://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing). The
"any" address is in the form 0.0.0.0/0.

=cut

sub ipRanges {
    my $self = shift;
    my $r    = $self->SUPER::ipRanges or return;
    return map {$_->{cidrIp}} @{$r->{item}};
}

=head2 @groups = $rule->groups

This method will return a list of the security groups that are allowed
to originate or receive traffic from instances assigned to this
security group, provided that the rule defines group-based traffic
filtering.

Each returned object is a L<VM::EC2::SecurityGroup::GroupPermission>,
not a L<VM::EC2::SecurityGroup>. The reason for this is that these
traffic filtering groups can include security groups owned by other
accounts

The GroupPermission objects define the methods userId(), groupId() and
groupName().

=cut

sub groups {
    my $self = shift;
    my $g    = $self->SUPER::groups or return;
    my @g    =  map { VM::EC2::SecurityGroup::GroupPermission->new($_,$self->aws) } @{$g->{item}};
    foreach (@g) {$_->ownerId($self->ownerId)};
    return @g;
}

sub ownerId {
    my $self = shift;
    my $d    = $self->{ownerId};
    $self->{ownerId} = shift if @_;
    $d;
}

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the rule
using the following templates:

TCP port 22 open to any host:

 "tcp(22..22) FROM CIDR 0.0.0.0/0"

TCP ports 23 through 39 open to the two class C networks 192.168.0.*
and 192.168.1.*:

 "tcp(23..29) FROM CIDR 192.168.0.0/24,192.168.1.0/24"

UDP port 80 from security group "default" owned by you and the group
named "farmville" owned by user 9999999:

 "udp(80..80) GRPNAME default,9999999/farmville"

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Instance>
L<VM::EC2::SecurityGroup>
L<VM::EC2::SecurityGroup::IpPermission>
L<VM::EC2::SecurityGroup::GroupPermission>

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

