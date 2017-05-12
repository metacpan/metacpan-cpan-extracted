package VM::EC2::LaunchConfiguration;

=head1 NAME

VM::EC2::LaunchConfiguration - Object describing a Launch Configuration

=head1 SYNOPSIS

  use VM::EC2;

  $ec2  = VM::EC2->new(...);
  @lcs  = $ec2->describe_launch_configurations();

=head1 DESCRIPTION

This object represents a launch configuration. It is returned by
C<VM::EC2->describe_launch_configurations()>.

=head1 METHODS

These properties are supported:

  block_device_mappings
  created_time
  ebs_optimized
  iam_instance_profile
  image_id
  instance_monitoring
  instance_type
  kernel_id
  key_name
  launch_configuration_arn
  launch_configuration_name
  ramdisk_id
  security_groups
  spot_price
  user_data

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
    return qw(BlockDeviceMappings CreatedTime EbsOptimized IamInstanceProfile
      ImageId InstanceMonitoring InstanceType KernelId KeyName
      LaunchConfigurationARN LaunchConfigurationName RamdiskId SecurityGroups
      SpotPrice UserData
    );
}

# object methods

sub args {
    my $self = shift;
    my $default_param_name = shift;
    return unless @_;
    return @_ if $_[0] =~ /^-/;
    return ($default_param_name => \@_);
}

1;
