package VM::EC2::ScalingPolicy;

=head1 NAME

VM::EC2::ScalingPolicy - Object describing an AutoScaling Policy

=head1 SYNOPSIS

  use VM::EC2;

  $ec2  = VM::EC2->new(...);
  @pols = $ec2->describe_policies();

  $pol  = $pols[0];
  $type = $pol->adjustment_type;

=head1 DESCRIPTION

This object represents an AutoScaling Policy. It's returned by
C<VM::EC2->describe_policies()>.

=head1 METHODS

These properties are supported:

  adjustment_type          -- Specifies whether the ScalingAdjustment is an absolute number or a percentage of the current capacity. Valid values are ChangeInCapacity, ExactCapacity, and PercentChangeInCapacity
  alarms                   -- A list of CloudWatch Alarms related to the policy
  auto_scaling_group_name  -- The name of the Auto Scaling group associated with this scaling policy
  cooldown                 -- The amount of time, in seconds, after a scaling activity completes before any further trigger-related scaling activities can start
  min_adjustment_step      -- Changes the DesiredCapacity of the Auto Scaling group by at least the specified number of instances
  policy_arn               -- The Amazon Resource Name (ARN) of the policy
  policy_name              -- The name of the scaling policy
  scaling_adjustment       -- The number associated with the specified adjustment type. A positive value adds to the current capacity and a negative value removes from the current capacity
  name                     -- Alias for policy_name

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
    return qw(AdjustmentType Alarms AutoScalingGroupName Cooldown 
      MinAdjustmentStep PolicyARN PolicyName ScalingAdjustment
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

sub name { shift->policy_name }

1;
