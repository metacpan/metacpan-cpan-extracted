package VM::EC2::ASG;

=head1 NAME

VM::EC2::ASG - Object describing an AutoScaling Group

=head1 SYNOPSIS

  use VM::EC2;

  $ec2  = VM::EC2->new(...);
  @asgs = $ec2->describe_autoscaling_groups();

  $asg  = $asgs[0];
  $name = $asg->auto_scaling_group_name;
  @azs  = $asg->availability_zones;

=head1 DESCRIPTION

This object represents an AutoScaling Group. It is returned by
C<VM::EC2->describe_autoscaling_groups()>.

=head1 METHODS

These properties are supported:

  auto_scaling_group_arn    -- ARN of the group
  auto_scaling_group_name   -- Name
  availability_zones        -- Zones in which this group auto scale
  created_time              -- Time of creation
  default_cooldown
  desired_capacity
  enabled_metrics
  health_check_type
  health_check_grace_period
  instance                  -- List of instances active in this group
  launch_configuration      -- Launch configuration name
  load_balancer_names       -- List of load balancers
  max_size
  min_size
  placement_group
  status
  suspended_processes
  tags
  termination_policies
  vpc_zone_identifier

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>

=head1 AUTHOR

Jose Luis Martinez

=cut

use strict;
use base 'VM::EC2::Generic';

sub valid_fields {
    my $self = shift;
    return qw(AutoScalingGroupARN AutoScalingGroupName AvailabilityZones
      CreatedTime DefaultCooldown DesiredCapacity EnabledMetrics
      HealthCheckGracePeriod HealthCheckType Instances LaunchConfigurationName
      LoadBalancerNames MaxSize MinSize PlacementGroup Status
      SuspendedProcesses Tags TerminationPolicies VPCZoneIdentifier
    );
}

# object methods

sub args {
    my $self               = shift;
    my $default_param_name = shift;
    return unless @_;
    return @_ if $_[0] =~ /^-/;
    return ($default_param_name => \@_);
}

1;
