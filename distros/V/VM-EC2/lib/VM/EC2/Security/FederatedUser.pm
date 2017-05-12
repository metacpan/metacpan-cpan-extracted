package VM::EC2::Security::FederatedUser;

=head1 NAME

VM::EC2::Security::FederatedUser -- Federated user object

=head1 SYNOPSIS

 use VM::EC2;
 use VM::EC2::Security::Policy;

  # on your side of the connection
 $ec2 = VM::EC2->new(...);  # as usual
 my $policy = VM::EC2::Security::Policy->new;
 $policy->allow('DescribeImages','RunInstances');

 my $token = $ec2->get_federation_token(-name     => 'TemporaryUser',
                                        -duration => 60*60*3, # 3 hrs, as seconds
                                        -policy   => $policy);

 my $user = $token->federated_user;
 print $user->arn,"\n";
 print $user->federated_user_id,"\n";

=head1 DESCRIPTION

This object forms part of the VM::EC2::Security::Token object, which
is created when you need to grant temporary access to some or all of
your AWS resources to someone who does not have an AWS account.

=head1 METHODS

 arn()   --          Return the Amazon Resource Name unique identifier (ARN)
                        associated with the temporary user, e.g. 
                        arn:aws:sts::123451234512345:federated-user/fred

 federatedUserId() -- Return the user ID for this temporary user, e.g.
                        123451234512345:fred                         

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate as the
ARN.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>

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

sub valid_fields {
    my $self = shift;
    return qw(Arn FederatedUserId);
}

sub short_name {shift->arn}

1;
