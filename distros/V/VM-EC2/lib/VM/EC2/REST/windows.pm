package VM::EC2::REST::windows;

use strict;
use VM::EC2 '';   # important not to import anything!
package VM::EC2;  # add methods to VM::EC2

VM::EC2::Dispatch->register(GetPasswordData      => 'VM::EC2::Instance::PasswordData');

=head1 NAME VM::EC2::REST::windows

=head1 SYNOPSIS

 use VM::EC2 ':misc';

=head1 METHODS

These methods control several Windows platform-related
functions. However, only GetPasswordData is implemented by VM::EC2
(volunteers welcome).

Implemented:
 GetPasswordData

Unimplemented:
 BundleInstance
 CancelBundleTask
 DescribeBundleTasks

=cut

=head2 $password_data = $ec2->get_password_data($instance_id);

=head2 $password_data = $ec2->get_password_data(-instance_id=>$id);

For Windows instances, get the administrator's password as a
L<VM::EC2::Instance::PasswordData> object.

=cut

sub get_password_data {
    my $self = shift;
    my %args = VM::EC2::ParmParser->args(-instance_id=>@_);
    $args{-instance_id} or croak "Usage: get_password_data(-instance_id=>\$id)";
    my ($async,@params) = VM::EC2::ParmParser->format_parms(\%args,{single_parm=>'InstanceId'});
    return $self->call('GetPasswordData',@params);
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
