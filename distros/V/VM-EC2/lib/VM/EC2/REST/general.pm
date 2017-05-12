package VM::EC2::REST::general;

use strict;
use VM::EC2 '';  # important not to import anything!
package VM::EC2;  # add methods to VM::EC2

VM::EC2::Dispatch->register(
    GetConsoleOutput     => 'VM::EC2::Instance::ConsoleOutput',
    DescribeAccountAttributes => 'fetch_items,accountAttributeSet,VM::EC2::AccountAttributes',
    );


my $VEP = 'VM::EC2::ParmParser';

=head1 NAME VM::EC2::REST::general

=head1 SYNOPSIS

 use VM::EC2 'general';

=head1 METHODS

These are EC2 methods that Amazon calls "general".

Implemented:
 GetConsoleOutput
 DescribeAccountAttributes

Unimplemented:
 (none)

=head2 $output = $ec2->get_console_output(-instance_id=>'i-12345')

=head2 $output = $ec2->get_console_output('i-12345');

Returns the console output of the indicated instance. The output is
actually a VM::EC2::ConsoleOutput object, but it is
overloaded so that when treated as a string it will appear as a
large text string containing the  console output. When treated like an
object it provides instanceId() and timestamp() methods.

=cut

sub get_console_output {
    my $self = shift;
    my %args = $VEP->args(-instance_id,@_);
    $args{-instance_id} or croak "Usage: get_console_output(-instance_id=>\$id)";
    my @params = $VEP->format_parms(\%args,
        {
            single_parm => [ 'InstanceId' ]
        }
    );
    return $self->call('GetConsoleOutput',@params);
}

=head2 @attrs = $ec2->describe_account_attributes(-attribute_name => \@attr_list)

=head2 @attrs = $ec2->describe_account_attributes(@attr_list)

=head2 @attrs = $ec2->describe_account_attributes($attr)

Describes the specified attribute of your AWS account.

Require Argument:

 -attribute_name              The attribute to describe

    Supported attributes:

      supported-platforms     Whether your account can launch instances into EC2-Classic
                              and EC2-VPC, or only into EC2-VPC. For more information,
                              see http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-supported-platforms.html

      default-vpc             ID of the default VPC for your account, or none. For more information, see
                              http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/default-vpc.html

Returns an array of L<VM::EC2::AccountAttributes> objects.

=cut

sub describe_account_attributes {
    my $self = shift;
    my %args = $VEP->args(-attribute_name,@_);
    $args{-attribute_name} or croak "describe_account_attributes(): missing -attribute_name argument";
    my @params = $VEP->format_parms(\%args,
        {
            list_parm => [ 'AttributeName' ]
        }
    );
    return $self->call('DescribeAccountAttributes',@params);
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
