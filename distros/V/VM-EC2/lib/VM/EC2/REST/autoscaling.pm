package VM::EC2::REST::autoscaling;

use strict;
use VM::EC2 '';  # important not to import anything!
package VM::EC2;  # add methods to VM::EC2

VM::EC2::Dispatch->register(
    DescribeLaunchConfigurations      => 'fetch_members,LaunchConfigurations,VM::EC2::LaunchConfiguration',
    DescribeAutoScalingGroups         => 'fetch_members,AutoScalingGroups,VM::EC2::ASG',
    DescribePolicies                  => 'fetch_members,ScalingPolicies,VM::EC2::ScalingPolicy',
    );

sub asg_call {
    my $self = shift;
    (my $endpoint = $self->{endpoint}) =~ s/ec2/autoscaling/;
    local $self->{endpoint} = $endpoint;
    local $self->{version}  = '2011-01-01';
    $self->call(@_);
}

=head1 NAME VM::EC2::REST::autoscaling

=head1 SYNOPSIS

 use VM::EC2 ':autoscaling';

=head1 METHODS

This module provides VM::EC2 methods for autoscaling groups and launch
configurations. Not all of the Amazon API is implemented, but the
most common functions are available.

Implemented:
 CreateAutoScalingGroup
 CreateLaunchConfiguration
 DeleteAutoScalingGroup
 DeleteLaunchConfiguration
 DeletePolicy
 DescribeAutoScalingGroups
 DescribeLaunchConfigurations
 DescribePolicies
 ExecutePolicy
 PutScalingPolicy
 ResumeProcesses
 SuspendProcesses
 UpdateAutoScalingGroup

Unimplemented:
 CreateOrUpdateTags
 DeleteNotificationConfiguration
 DeleteScheduledAction
 DeleteTags
 DescribeAdjustmentTypes
 DescribeAutoScalingInstances
 DescribeAutoScalingNotificationTypes
 DescribeMetricCollectionTypes
 DescribeNotificationConfigurations
 DescribeScalingActivities
 DescribeScalingProcessTypes
 DescribeScheduledActions
 DescribeTags
 DescribeTerminationPolicyTypes
 DisableMetricsCollection
 EnableMetricsCollection
 PutNotificationConfiguration
 PutScheduledUpdateGroupAction
 SetDesiredCapacity
 SetInstanceHealth
 TerminateInstanceInAutoScalingGroup

=head2 @lc = $ec2->describe_launch_configurations(-names => \@names);

=head2 @lc = $ec->describe_launch_configurations(@names);

Provides detailed information for the specified launch configuration(s).

Optional parameters are:

  -launch_configuration_names   Name of the Launch config.
                                  This can be a string scalar or an arrayref.

  -name  Alias for -launch_configuration_names

Returns a series of L<VM::EC2::LaunchConfiguration> objects.

=cut

sub describe_launch_configurations {
    my $self = shift;
    my %args = $self->args('-launch_configuration_names',@_);
    $args{-launch_configuration_names} ||= $args{-names};
    my @params = $self->list_parm('LaunchConfigurationNames',\%args);
    return $self->asg_call('DescribeLaunchConfigurations', @params);
}

=head2 $success = $ec2->create_launch_configuration(%args);

Creates a new launch configuration.

Required arguments:

  -name           -- scalar, name for the Launch config.
  -image_id       -- scalar, AMI id which this launch config will use
  -instance_type  -- scalar, instance type of the Amazon EC2 instance.

Optional arguments:

  -block_device_mappings  -- list of hashref
  -ebs_optimized          -- scalar (boolean). false by default
  -iam_instance_profile   -- scalar
  -instance_monitoring    -- scalar (boolean). true by default
  -kernel_id              -- scalar
  -key_name               -- scalar
  -ramdisk                -- scalar
  -security_groups        -- list of scalars
  -spot_price             -- scalar
  -user_data              -- scalar

Returns true on successful execution.

=cut

sub create_launch_configuration {
    my $self = shift;
    my %args = @_;
    my $name = $args{-name} or croak "-name argument is required";
    my $imageid = $args{-image_id} or croak "-image_id argument is required";
    my $itype = $args{-instance_type} or croak "-instance_type argument is required";

    my @params = (ImageId => $imageid, InstanceType => $itype, LaunchConfigurationName => $name);
    push @params, $self->member_list_parm('BlockDeviceMappings',\%args);
    push @params, $self->member_list_parm('SecurityGroups',\%args);
    push @params, $self->boolean_parm('EbsOptimized', \%args);
    push @params, ('UserData' =>encode_base64($args{-user_data},'')) if $args{-user_data};
    push @params, ('InstanceMonitoring.Enabled' => 'false')
        if (exists $args{-instance_monitoring} and not $args{-instance_monitoring});

    my @p = map {$self->single_parm($_,\%args) }
       qw(IamInstanceProfile KernelId KeyName RamdiskId SpotPrice);
    push @params, @p;

    return $self->asg_call('CreateLaunchConfiguration',@params);
}

=head2 $success = $ec2->delete_launch_configuration(-name => $name);

Deletes a launch config.

  -name     Required. Name of the launch config to delete

Returns true on success.

=cut

sub delete_launch_configuration {
    my $self = shift;
    my %args  = @_;
    my $name = $args{-name} or croak "-name argument is required";
    my @params = (LaunchConfigurationName => $name);
    return $self->asg_call('DeleteLaunchConfiguration', @params);
}

=head2 @asg = $ec2->describe_autoscaling_groups(-auto_scaling_group_names => \@names);

Returns information about autoscaling groups

  -auto_scaling_group_names     List of auto scaling groups to describe
  -names                        Alias of -auto_scaling_group_names

Returns a list of L<VM::EC2::ASG>.

=cut

sub describe_autoscaling_groups {
    my ($self, %args) = @_;
    $args{-auto_scaling_group_names} ||= $args{-names};
    my @params = $self->member_list_parm('AutoScalingGroupNames',\%args);
    return $self->asg_call('DescribeAutoScalingGroups', @params);
}

=head2 $success = $ec2->create_autoscaling_group(-name => $name, 
                                                -launch_config => $lc,
                                                -max_size => $max_size,
                                                -min_size => $min_size);

Creates a new autoscaling group.

Required arguments:

  -name             Name for the autoscaling group
  -launch_config    Name of the launch configuration to be used
  -max_size         Max number of instances to be run at once
  -min_size         Min number of instances

Optional arguments:

  -availability_zones   List of availability zone names
  -load_balancer_names  List of ELB names
  -tags                 List of tags to apply to the instances run
  -termination_policies List of policy names
  -default_cooldown     Time in seconds between autoscaling activities
  -desired_capacity     Number of instances to be run after creation
  -health_check_type    One of "ELB" or "EC2"
  -health_check_grace_period    Mandatory for health check type ELB. Number of
                                seconds between an instance is started and the
                                autoscaling group starts checking its health
  -placement_group      Physical location of your cluster placement group
  -vpc_zone_identifier  Strinc containing a comma-separated list of subnet 
                        identifiers

Returns true on success.

=cut

sub create_autoscaling_group {
    my $self = shift;
    my %args = @_;
    my $name = $args{-name} or croak "-name argument is required";
    my $lconfig = $args{-launch_config} or croak "-launch_config argument is required";
    my $max = $args{-max_size};
    croak "-max_size argument is required" if (not defined $max);
    my $min = $args{-min_size};
    croak "-min_size argument is required" if (not defined $min);

    my @params = (AutoScalingGroupName => $name, LaunchConfigurationName => $lconfig, MaxSize => $max,
                  MinSize => $max);
    push @params, $self->member_list_parm('AvailabilityZones',\%args);
    push @params, $self->member_list_parm('LoadBalancerNames',\%args);
    push @params, $self->member_list_parm('TerminationPolicies',\%args);
    push @params, $self->autoscaling_tags('Tags', \%args);

    my @p = map {$self->single_parm($_,\%args) }
       qw( DefaultCooldown DesiredCapacity HealthCheckGracePeriod HealthCheckType PlacementGroup
           VPCZoneIdentifier);
    push @params, @p;

    return $self->asg_call('CreateAutoScalingGroup',@params);
}

=head2 $success = $ec2->delete_autoscaling_group(-name => $name)

Deletes an autoscaling group.

  -name     Name of the autoscaling group to delete

Returns true on success.

=cut

sub delete_autoscaling_group {
    my $self = shift;
    my %args  = @_;
    my $name = $args{-name} or croak "-name argument is required";
    my @params = (AutoScalingGroupName => $name);
    push @params, $self->single_parm('ForceDelete',\%args);
    return $self->asg_call('DeleteAutoScalingGroup', @params);
}

=head2 $success = $ec2->update_autoscaling_group(-name => $name);

Updates an autoscaling group. Only required parameter is C<-name>

Optional arguments:

  -availability_zones       List of AZ's
  -termination_policies     List of policy names
  -default_cooldown
  -desired_capacity
  -health_check_type
  -health_check_grace_period
  -launch_configuration_name
  -placement_group
  -vpc_zone_identifier
  -max_size
  -min_size

Returns true on success;

=cut

sub update_autoscaling_group {
    my $self = shift;
    my %args = @_;

    my $name = $args{-name} or croak "-name argument is required";
    my @params = (AutoScalingGroupName => $name);

    push @params, $self->member_list_parm('AvailabilityZones',\%args);
    push @params, $self->member_list_parm('TerminationPolicies',\%args);

    my @p = map {$self->single_parm($_,\%args) }
       qw( DefaultCooldown DesiredCapacity HealthCheckGracePeriod
           HealthCheckType LaunchConfigurationName PlacementGroup
           VPCZoneIdentifier MaxSize MinSize );
    push @params, @p;

    return $self->asg_call('UpdateAutoScalingGroup',@params);
}

=head2 $success = $ec2->suspend_processes(-name => $asg_name,
                                          -scaling_processes => \@procs);

Suspend the requested autoscaling processes.

  -name                 Name of the autoscaling group
  -scaling_processes    List of process names to suspend. Valid processes are:
        Launch
        Terminate
        HealthCheck
        ReplaceUnhealty
        AZRebalance
        AlarmNotification
        ScheduledActions
        AddToLoadBalancer

Returns true on success.

=cut

sub suspend_processes {
    my ($self, %args) = @_;
    my $name = $args{-name} or croak "-name argument is required";
    my @params = (AutoScalingGroupName => $name);
    push @params, $self->member_list_parm('ScalingProcesses', \%args);
    return $self->asg_call('SuspendProcesses', @params);
}

=head2 $success = $ec2->resume_processes(-name => $asg_name,
                                         -scaling_processes => \@procs);

Resumes the requested autoscaling processes. It accepts the same arguments than
C<suspend_processes>.

Returns true on success.

=cut

sub resume_processes {
    my ($self, %args) = @_;
    my $name = $args{-name} or croak "-name argument is required";
    my @params = (AutoScalingGroupName => $name);
    push @params, $self->member_list_parm('ScalingProcesses', \%args);
    return $self->asg_call('ResumeProcesses', @params);
}

=head2 @arguments = $ec2->autoscaling_tags($argname, \%args)

=cut

sub autoscaling_tags {
    my $self = shift;
    my ($argname, $args) = @_;

    my $name = $self->canonicalize($argname);
    my @params;
    if (my $a = $args->{$name}||$args->{"-$argname"}) {
        my $c = 1;
        for my $tag (ref $a && ref $a eq 'ARRAY' ? @$a : $a) {
            my $prefix = "$argname.member." . $c++;
            while (my ($k, $v) = each %$tag) {
                push @params, ("$prefix.$k" => $v);
            }
        }
    }

    return @params;
}

=head2 @asg = $ec2->describe_policies(-auto_scaling_group_name => $name);

Returns information about autoscaling policies

  -auto_scaling_group_name      The name of the Auto Scaling group
  -policy_names                 An array of policy names or policy ARNs to be described. If this list is omitted, all policy names are described. If an auto scaling group name is provided, the results are limited to that group. The list of requested policy names cannot contain more than 50 items. If unknown policy names are requested, they are ignored with no error.
  -names                        Alias of -auto_scaling_group_names

Returns a list of L<VM::EC2::ScalingPolicy>.

=cut

sub describe_policies {
    my ($self, %args) = @_;
    $args{-auto_scaling_group_name} ||= $args{-name};
    my @params = $self->member_list_parm('PolicyNames',\%args);
    push @params, ('AutoScalingGroupName', $args{-auto_scaling_group_name})
        if ($args{-auto_scaling_group_name});
    return $self->asg_call('DescribePolicies', @params);
}


=head2 $success = $ec2->put_scaling_policy

Creates or updates a policy for an Auto Scaling group.

Required arguments:

  -policy_name             The name of the policy to update or create.
  -name                    Alias for -policy_name
  -auto_scaling_group_name The name or ARN of the Auto Scaling group.
  -scaling_adjustment      Number of instances by which to scale. 
  -adjustment_type         Specifies wheter -scaling_adjustment is an absolute 
                           number or a percentage of the current capacity.
                           Valid values are:
        ChangeInCapacity
        ExactCapacity
        PercentChangeInCapacity

Optional arguments:

  -cooldown             The amount of time, in seconds, after a scaling
                        activity completes and before the next scaling acitvity
                        can start. 
  -min_adjustment_step  Used with PercentChangeInCapacity as -adjustment_type.

Returns true on success

=cut

sub put_scaling_policy {
    my ($self, %args) = @_;
    $args{-policy_name} ||= $args{-name};
    my @params = map {$self->single_parm($_, \%args) }
        qw( AdjustmentType AutoScalingGroupName Cooldown MinAdjustmentStep
            PolicyName ScalingAdjustment );

    return $self->asg_call('PutScalingPolicy', @params);
}

=head2 $success = $ec2->delete_policy(-policy_name => $name)

Deletes a policy

Required arguments:

  -policy_name                  Name or ARN of the policy
  -name                         Alias for -policy_name
  -auto_scaling_group_name      Name of the Auto Scaling Group, required when
                                specifying policy by name (not by ARN)

Returns true on success

=cut

sub delete_policy {
    my ($self, %args) = @_;
    $args{-policy_name} ||= $args{-name};
    my @params = map { $self->single_parm($_, \%args) }
        qw( AutoScalingGroupName PolicyName );

    return $self->asg_call('DeletePolicy', @params);
}

=head2 $success = $ec2->execute_policy(-policy_name => $name)

Runs a policy

Required arguments:

  -policy_name                  Name or ARN of the policy
  -name                         Alias for -policy_name
  -auto_scaling_group_name      Name of the Auto Scaling Group, required when
                                specifying policy by name (not by ARN)

Optional arguments:

  -honor_cooldown               Set to true if you want AutoScaling to reject
                                the request when it is in cooldown

Returns true on success

=cut

sub execute_policy {
    my ($self, %args) = @_;
    $args{-policy_name} ||= $args{-name};
    my @params = map { $self->single_parm($_, \%args) }
        qw( AutoScalingGroupName HonorCooldown PolicyName );

    return $self->asg_call('ExecutePolicy', @params);
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
