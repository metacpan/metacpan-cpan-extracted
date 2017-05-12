package VM::EC2::REST::security_group;

use strict;
use VM::EC2 '';   # important not to import anything!
package VM::EC2;  # add methods to VM::EC2

VM::EC2::Dispatch->register(
    DescribeSecurityGroups   => 'fetch_items,securityGroupInfo,VM::EC2::SecurityGroup',
    CreateSecurityGroup      => 'VM::EC2::SecurityGroup',
    DeleteSecurityGroup      => 'boolean',
    AuthorizeSecurityGroupIngress  => 'boolean',
    AuthorizeSecurityGroupEgress   => 'boolean',
    RevokeSecurityGroupIngress  => 'boolean',
    RevokeSecurityGroupEgress   => 'boolean',
    );

=head1 NAME VM::EC2::REST::security_group

=head1 SYNOPSIS

 use VM::EC2 ':standard';

=head1 METHODS

The methods in this section allow you to query and manipulate security
groups (firewall rules). See L<VM::EC2::SecurityGroup> for functionality
that is available through these objects.

Implemented:
 AuthorizeSecurityGroupEgress (EC2-VPC only)
 AuthorizeSecurityGroupIngress
 CreateSecurityGroup
 DeleteSecurityGroup
 DescribeSecurityGroups
 RevokeSecurityGroupEgress (EC2-VPC only)
 RevokeSecurityGroupIngress

Unimplemented:
 (none)


=head2 @sg = $ec2->describe_security_groups(@group_ids)

=head2 @sg = $ec2->describe_security_groups(%args);

=head2 @sg = $ec2->describe_security_groups(\%filters);

Searches for security groups (firewall rules) matching the provided
filters and return a series of VM::EC2::SecurityGroup objects.

In the named-argument form you can provide the following optional
arguments:

 -group_name      A single group name or an arrayref containing a list
                   of names

 -name            Shorter version of -group_name

 -group_id        A single group id (i.e. 'sg-12345') or an arrayref
                   containing a list of ids

 -filter          Filter on tags and other attributes.

The -filter argument name can be omitted if there are no other
arguments you wish to pass.

The full list of security group filters can be found at:
http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSecurityGroups.html

=cut

sub describe_security_groups {
    my $self = shift;
    my %args = $self->args(-group_id=>@_);
    $args{-group_name} ||= $args{-name};
    my @params = map { $self->list_parm($_,\%args) } qw(GroupName GroupId);
    push @params,$self->filter_parm(\%args);
    return $self->call('DescribeSecurityGroups',@params);
}

=head2 $group = $ec2->create_security_group(-group_name=>$name,
                                            -group_description=>$description,
                                            -vpc_id     => $vpc_id
    )

Create a security group. Arguments are:

 -group_name              Name of the security group (required)
 -group_description       Description of the security group (required)
 -vpc_id                  Virtual private cloud security group ID
                           (required for VPC security groups)

For convenience, you may use -name and -description as aliases for
-group_name and -group_description respectively. 

If succcessful, the method returns an object of type
L<VM::EC2::SecurityGroup>.

=cut

sub create_security_group {
    my $self = shift;
    my %args = @_;
    $args{-group_name}        ||= $args{-name};
    $args{-group_description} ||= $args{-description};
    $args{-group_name} && $args{-group_description}
    or croak "create_security_group() requires -group_name and -group_description arguments";

    my @param;
    push @param,$self->single_parm($_=>\%args) foreach qw(GroupName GroupDescription VpcId);
    my $g = $self->call('CreateSecurityGroup',@param) or return;
    return eval {
            my $sg;
            local $SIG{ALRM} = sub {die "timeout"};
            alarm(60);
            until ($sg = $self->describe_security_groups($g)) { sleep 1 }
            alarm(0);
            $sg;
    };
}

=head2 $boolean = $ec2->delete_security_group($group_id)

=head2 $boolean = $ec2->delete_security_group(-group_id   => $group_id,
                                              -group_name => $name);

Delete a security group. Arguments are:

 -group_name              Name of the security group
 -group_id                ID of the security group

Either -group_name or -group_id is required. In the single-argument
form, the method deletes the security group given by its id.

If succcessful, the method returns true.

=cut

sub delete_security_group {
    my $self = shift;
    my %args = $self->args(-group_id=>@_);
    $args{-group_name} ||= $args{-name};
    my @param = $self->single_parm(GroupName=>\%args);
    push @param,$self->single_parm(GroupId=>\%args);
    return $self->call('DeleteSecurityGroup',@param);
}

=head2 $boolean = $ec2->update_security_group($security_group)

Add one or more incoming firewall rules to a security group. The rules
to add are stored in a L<VM::EC2::SecurityGroup> which is created
either by describe_security_groups() or create_security_group(). This method combines
the actions AuthorizeSecurityGroupIngress,
AuthorizeSecurityGroupEgress, RevokeSecurityGroupIngress, and
RevokeSecurityGroupEgress.

For details, see L<VM::EC2::SecurityGroup>. Here is a brief summary:

 $sg = $ec2->create_security_group(-name=>'MyGroup',-description=>'Example group');

 # TCP on port 80 for the indicated address ranges
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

 $result = $ec2->update_security_group($sg);

or more simply:

 $result = $sg->update();

=cut

sub update_security_group {
    my $self = shift;
    my $sg   = shift;
    my $group_id = $sg->groupId;
    my $result = 1;
    
    for my $action (qw(Authorize Revoke)) {
	for my $direction (qw(Ingress Egress)) {
	    my @permissions = $sg->_uncommitted_permissions($action,$direction) or next;
	    my $call  = "${action}SecurityGroup${direction}";
	    my @param = (GroupId=>$group_id);
	    push @param,$self->_security_group_parm(\@permissions);
	    my $r = $self->call($call=>@param);
	    $result &&= $r;
	}
    }
    return $result;
}

sub _security_group_parm {
    my $self = shift;
    my $permissions = shift;
    my @param;

    for (my $i=0;$i<@$permissions;$i++) {
	my $perm = $permissions->[$i];
	my $n = $i+1;
	push @param,("IpPermissions.$n.IpProtocol"=>$perm->ipProtocol);
	push @param,("IpPermissions.$n.FromPort"  => $perm->fromPort);
	push @param,("IpPermissions.$n.ToPort"    => $perm->toPort);
	my @cidr = $perm->ipRanges;
	for (my $i=0;$i<@cidr;$i++) {
	    my $m = $i+1;
	    push @param,("IpPermissions.$n.IpRanges.$m.CidrIp"=>$cidr[$i]);
	}
	my @groups = $perm->groups;
	for (my $i=0;$i<@groups;$i++) {
	    my $m = $i+1;
	    my $group = $groups[$i];
	    if (defined $group->groupId) {
		push @param,("IpPermissions.$n.Groups.$m.GroupId"  => $group->groupId);
	    } else {
		push @param,("IpPermissions.$n.Groups.$m.UserId"   => $group->userId);
		push @param,("IpPermissions.$n.Groups.$m.GroupName"=> $group->groupName);
	    }
	}
    }
    return @param;
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
