package VM::EC2::SecurityGroup;

=head1 NAME

VM::EC2::SecurityGroup - Object describing an Amazon EC2 security group

=head1 SYNOPSIS

  use VM::EC2;

  $ec2       = VM::EC2->new(...);
  @sg = $ec2->describe_security_groups;
  for my $sg (@sg) {
      $name = $sg->groupName;
      $id   = $sg->groupId;
      $desc = $sg->groupDescription;
      $tags = $sg->tags;
      @inbound_permissions  = $sg->ipPermissions;
      @outbound_permissions = $sg->ipPermissionsEgress;
      for $i (@inbound_permissions) {
         $protocol = $i->ipProtocol;
         $fromPort = $i->fromPort;
         $toPort   = $i->toPort;
         @ranges   = $i->ipRanges;
      }
  }

 $sg = $sg[0];

 # Add a new security rule
 $sg->authorize_incoming(-protocol  => 'tcp',
                         -port      => 80,
                         -source_ip => ['192.168.2.0/24','192.168.2.1/24'});

 # write it to AWS.
 $sg->update();

=head1 DESCRIPTION

This object is used to describe an Amazon EC2 security group. It is
returned by VM::EC2->describe_security_groups(). You may also obtain
this object by calling an Instance object's groups() method, and then
invoking one of the group's permissions() method. See
L<VM::EC2::Group>.

=head1 METHODS

The following object methods are supported:
 
 ownerId          -- Owner of this security group
 groupId          -- ID of this security group
 groupName        -- Name of this security group
 groupDescription -- Description of this group
 vpcId            -- Virtual Private Cloud ID, if applicable
 ipPermissions    -- A list of rules that govern incoming connections
                     to instances running under this security group.
                     Each rule is a
                     L<VM::EC2::SecurityGroup::IpPermission> object.
 ipPermissionsEgress -- A list of rules that govern outgoing connections
                     from instances running under this security group.
                     Each rule is a
                     L<VM::EC2::SecurityGroup::IpPermission object>.
                     This field is only valid for VPC groups.
 tags             -- Hashref containing tags associated with this group.
                     See L<VM::EC2::Generic>. 

For convenience, the following aliases are provided for commonly used methods:

 inbound_permissions  -- same as ipPermissions()
 outbound_permissions -- same as ipPermissionsEgress()
 name                 -- same as groupName()

See L<VM::EC2::SecurityGroup::IpPermission> for details on accessing
port numbers, IP ranges and other fields associated with incoming and
outgoing firewall rules.

=head1 MODIFYING FIREWALL RULES

To add or revoke firewall rules, call the authorize_incoming,
authorize_outgoing, revoke_incoming or revoke_outgoing() methods
one or more times. Each of these methods either adds or removes a
single firewall rule. After adding or revoking the desired rules, call
update() to write the modified group back to Amazon. The object will
change to reflect the new permissions.

=head2 $permission = $group->authorize_incoming(%args)

Add a rule for incoming firewall traffic. Arguments are as follows:

 -protocol        The protocol, either a string (tcp,udp,icmp) or
                   the corresponding protocol number (6, 17, 1).
                   Use -1 to indicate all protocols. (required)

 -port, -ports    The port or port range. When referring to a single
                   port, you may use either the port number or the
                   service name (e.g. "ssh"). For this to work the
                   service name must be located in /etc/services.
                   When specifying a port range, use "start..end" as
                   in "8000..9000". Note that this is a string that
                   contains two dots, and not two numbers separated
                   by the perl range operator. For the icmp protocol,
                   this argument corresponds to the ICMP type number.
                   (required).

 -group, -groups   Security groups to authorize. Instances that belong
                    to the named security groups will be allowed
                    access. You may specify either a single group or
                    a list of groups as an arrayref. The following
                    syntaxes are recognized:

                    "sg-12345"       authorize group with this groupId
                    "12345/my group" authorize group named "my group" 
                                      owned by user 12345
                     "my group"      authorize group named "my group"
                                      owned by yourself

 -source, -source_ip Authorize incoming traffic from an IP address, IP
                      address range, or set of such ranges. IP
                      addresses use the CIDR notation of a.b.c.d/mask,
                      as described in 
                      http://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing.
                      Pass an arrayref to simultaneously authorize
                      multiple CIDR ranges.

The result of this call is a L<VM::EC2::SecurityGroup::IpPermission>
object corresponding to the rule you defined. Note that the rule is
not written to Amazon until you call update().

Here are some examples:

 $sg->authorize_incoming(-protocol  => 'tcp',
                         -port      => 80,
                         -source_ip => ['192.168.2.0/24','192.168.2.1/24'});

 # TCP on ports 22 and 23 from anyone
 $sg->authorize_incoming(-protocol  => 'tcp',
                         -port      => '22..23',
                         -source_ip => '0.0.0.0/0');

 # ICMP on echo (ping) port from anyone
 $sg->authorize_incoming(-protocol  => 'icmp',
                         -port      => -1,
                         -source_ip => '0.0.0.0/0');

 # TCP to port 25 (mail) from instances belonging to
 # the "Mail relay" group belonging to user 12345678.
 $sg->authorize_incoming(-protocol  => 'tcp',
                         -port      => 25,
                         -group     => '12345678/Mail relay');

=head2 $permission = $group->authorize_outgoing(%args)

This is identical to authorize_incoming() except that the rule applies
to outbound traffic. Only VPC security groups can define outgoing
firewall rules.

=head2 $permission = $group->revoke_incoming($rule)

=head2 $permission = $group->revoke_incoming(%args)

This method revokes an incoming firewall rule. You can call it with a
single argument consisting of a
L<VM::EC2::SecurityGroup::IpPermission> object in order to revoke that
rule. Alternatively, when called with the named arguments listed for
authorize_incoming(), it will attempt to match an existing rule to the
provided arguments and queue it for deletion.

Here is an example of revoking all rules that allow ssh (port 22)
access:

 @ssh_rules = grep {$_->fromPort == 22} $group->ipPermissions;
 $group->revoke_incoming($_) foreach @ssh_rules;
 $group->update();

=head2 $boolean = $group->update()

This method will write all queued rule authorizations and revocations
to Amazon, and return a true value if successful. The method will
return false if any of the rule updates failed. You can examine the
VM::EC2 object's error_str() method to determine what went wrong, and
check the group object's ipPermissions() method to see what firewall
rules are currently defined.

=head2 $boolean = $group->write()

An alias for update()

=head2 $group->refresh()

This method refreshes the group information from Amazon. It is called
automatically by update().

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
groupId.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Instance>
L<VM::EC2::Group>
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

use strict;
use base 'VM::EC2::Generic';
use VM::EC2 'security_group';
use VM::EC2::SecurityGroup::IpPermission;
use Carp 'croak';

sub valid_fields {
    return qw(ownerId groupId groupName groupDescription vpcId ipPermissions ipPermissionsEgress tagSet);
}

sub primary_id { 
    my $self = shift;
    return $self->groupId || $self->groupName;
}

sub name { shift->groupName }

sub inbound_permissions  { shift->ipPermissions }
sub outbound_permissions { shift->ipPermissionsEgress }

sub ipPermissions {
    my $self = shift;
    my $p    = $self->SUPER::ipPermissions or return;
    my @p = map { VM::EC2::SecurityGroup::IpPermission->new($_,
							    $self->aws,
							    $self->xmlns,
							    $self->requestId)
    } @{$p->{item}};
    
    # tell ip permissions about the owner -- needed for the
    # group name string.
    my $owner = $self->ownerId;
    foreach (@p) {$_->ownerId($owner)}
    return @p;
}

sub ipPermissionsEgress {
    my $self = shift;
    my $p    = $self->SUPER::ipPermissionsEgress or return;
    my @p    = map { VM::EC2::SecurityGroup::IpPermission->new($_,$self->aws,$self->xmlns,$self->requestId)} 
           @{$p->{item}};

    # tell ip permissions about the owner -- needed for the
    # group name string.
    my $owner = $self->ownerId;
    foreach (@p) {$_->ownerId($owner)}
    return @p;
}

sub _uncommitted_permissions {
    my $self = shift;
    my ($action,$direction) = @_;   # e.g. 'Authorize','Ingress'
    my $perms = $self->{uncommitted}{$action}{$direction} or return;
    return values %$perms;
}

sub authorize_incoming {
    my $self = shift;
    my $permission = $self->_new_permission(@_);
    $self->{uncommitted}{Authorize}{Ingress}{$permission}=$permission;
}

sub authorize_outgoing {
    my $self = shift;
    my $permission = $self->_new_permission(@_);
    $self->{uncommitted}{Authorize}{Egress}{$permission}=$permission;
}

sub revoke_incoming {
    my $self = shift;
    my $permission = $_[0] =~ /^-[A-Za-z]/ ? $self->_new_permission(@_) : shift;
    if ($self->{uncommitted}{Authorize}{Ingress}{$permission}) {
	delete $self->{uncommitted}{Authorize}{Ingress}{$permission};
    }
    $self->{uncommitted}{Revoke}{Ingress}{$permission}=$permission;
}

sub revoke_outgoing {
    my $self = shift;
    my $permission = $_[0] =~ /^-[A-Za-z]/ ? $self->_new_permission(@_) : shift;
    if ($self->{uncommitted}{Authorize}{Egress}{$permission}) {
	delete $self->{uncommitted}{Authorize}{Egress}{$permission};
    }
    $self->{uncommitted}{Revoke}{Egress}{$permission}=$permission;
}

# write permissions out to AWS
sub update {
    my $self = shift;
    my $aws  = $self->aws;
    my $result = $aws->update_security_group($self);
    {
	local $aws->{error};  # so we can do a double-fetch
	$self->refresh;
    }
    return $result;
}

sub write { shift->update }

sub refresh {
    my $self = shift;
    my $i    = $self->aws->describe_security_groups($self->groupId);
    %$self   = %$i if $i;
    return defined $i;
}

sub _new_permission {
    my $self = shift;
    my %args = @_;

    my $data = {};  # xml

    my $protocol = lc $args{-protocol} or croak "-protocol argument required";
    $data->{ipProtocol} = $protocol;

    $args{-source_ip} ||= $args{-source};

    my $ports     = defined($args{-port}) ? $args{-port} : $args{-ports};
    my ($from_port,$to_port);
    if ($ports =~ /^(\d+)\.\.(\d+)$/) {
	$from_port = $1;
	$to_port   = $2;
    } elsif ($ports =~ /^-?\d+$/) {
	$from_port = $to_port = $ports;
    } elsif (my @p = getservbyname($ports,$protocol)) {
	$from_port = $to_port = $p[2];
    } else {
	croak "value of -port argument not recognized";
    }
    $data->{fromPort} = $from_port;
    $data->{toPort}   = $to_port;
    
    my $group  = $args{-groups} || $args{-group};
    my @groups = ref $group && ref $group eq 'ARRAY' ? @$group :$group ? ($group) : ();
    for my $g (@groups) {
	if ($g =~ /^sg-[a-f0-9]+$/) {
	    push @{$data->{groups}{item}},{groupId=>$g};
	} elsif (my ($userid,$groupname) = $g =~ m!(\d+)/(.+)!) {
	    push @{$data->{groups}{item}},{userId=>$userid,groupName=>$groupname};
	} else {
	    my $userid = $self->aws->account_id;
	    push @{$data->{groups}{item}},{userId=>$userid,groupName=>$g};
	}
    }

    my $address = $args{-source_ip};
    $address && $group and croak "the -source_ip and -group arguments are mutually exclusive";
    $address ||= '0.0.0.0/0' unless $group;

    my @addresses = ref $address && ref $address eq 'ARRAY' ? @$address 
                   :$address ? ($address) 
		   : ();
    foreach (@addresses) { $_ = '0.0.0.0/0' if $_ eq 'any' }
    $data->{ipRanges}{item} = [map {{cidrIp=>$_}} @addresses] if @addresses;

    my $sg = VM::EC2::SecurityGroup::IpPermission->new($data,$self->aws);
    $sg->ownerId($self->ownerId);
    return $sg;
}


1;
