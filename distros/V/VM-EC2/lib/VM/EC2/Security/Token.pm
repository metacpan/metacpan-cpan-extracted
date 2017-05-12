package VM::EC2::Security::Token;

=head1 NAME

VM::EC2::Security::Token - Temporary security token object

=head1 SYNOPSIS

 use VM::EC2;
 use VM::EC2::Security::Policy

 # under your account
 $ec2 = VM::EC2->new(...);  # as usual
 my $policy = VM::EC2::Security::Policy->new;
 $policy->allow('DescribeImages','RunInstances');
 my $token = $ec2->get_federation_token(-name     => 'TemporaryUser',
                                        -duration => 60*60*3, # 3 hrs, as seconds
                                        -policy   => $policy);
 print $token->sessionToken,"\n";
 print $token->accessKeyId,"\n";
 print $token->secretAccessKey,"\n";
 print $token->federatedUser,"\n";

 my $serialized = $token->credentials->serialize;

 # get the serialized token to the temporary user
 send_data_to_user_somehow($serialized); 

 # under the temporary user's account
 my $serialized = get_data_somehow();

 # create a copy of the token from its serialized form
 my $token = VM::EC2::Security::Credentials->new_from_serialized($serialized);

 # open a new EC2 connection with this token. User will be
 # able to run all the methods specified in the policy.
 my $ec2   = VM::EC2->new(-security_token => $token);
 print $ec2->describe_images(-owner=>'self');

 # convenience routine; will return a VM::EC2 object authorized
 # to use the current token
 my $ec2   = $token->new_ec2;
 print $ec2->describe_images(-owner=>'self');

=head1 DESCRIPTION

VM::EC2::Security::Token objects allow you to grant a user access to
some or all of your EC2 resources for a limited period of time. The
user does not have to have his own AWS account.

Token objects are returned by calls to VM::EC2->get_federation_token()
and get_session_token(). The former call is used to create a temporary
user with privileges restricted to those listed in the accompanying
policy (a VM::EC2::Security::Policy object). The latter call is used
in conjunction with multi-factor authentication devices, such as smart
cards. The tokens returned by get_session_token() are not associated
with a user account nor a policy, and grant privileges to all EC2
actions and resources. Both federation and session tokens have an
expiry time between a few seconds and 36 hours.

A VM::EC2::Security::Credentials object contained within the token
contains the temporary secret access key, acess key ID, and a session
token string that unlocks the access key. The credentials object can
be serialized into a form suitable for sending to a user via a secure
channel, such as SSL or S/MIME e-mail, and unserialized at the
receiving end into a copy of the original credentials object. 

Either the token object, or its contained credentials object can be
used passed to VM::EC2->new() via the B<-security_token> parameter in
order to gain access to EC2 resources.

=head1 METHODS

 credentials()     -- The VM::EC2::Security::Credentials object
                        that contains the session token, access key ID,
                        and secret key.

 federatedUser()  -- the VM::EC2::Security::FederatedUser object that
                        contains information about the temporary user
                        account.

 packedPolicySize() -- A percentage value indicating the size of the policy in
                         packed form relative to the maximum allowed size. 
                         Policies in excess of 100% will be rejected by the
                         service.

 secret_access_key()-- Convenience method that calls the credentials object's
                        secret_access_key() method.

 access_key_id() --    Convenience method that calls the credentials object's
                        access_key_id() method.

 session_token() --    Convenience method that calls the credentials object's
                        session_token() method.

 new_ec2(@args)  --    Convenience method that returns a VM::EC2 object authorized
                        with the current token. You may pass any of the arguments
                        accepted by VM::EC2->new(), except that -access_key and 
                        -secret_key will be ignored if present.

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate as the
session token, and can be used for the -security_token parameter in
VM::EC2->new().

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Security::Credentials>
L<VM::EC2::Security::FederatedUser>

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
use VM::EC2::Security::FederatedUser;
use VM::EC2::Security::Credentials;

sub valid_fields {
    my $self = shift;
    return qw(Credentials FederatedUser PackedPolicySize);
}

sub new_ec2 {
    shift->credentials->new_ec2(@_);
}

sub credentials { 
    my $self = shift;
    return VM::EC2::Security::Credentials->new($self->SUPER::credentials,undef);
}

sub federated_user { 
    my $self = shift;
    my $user = $self->SUPER::federated_user or return;
    return VM::EC2::Security::FederatedUser->new($user,undef);
}

sub secret_access_key { shift->credentials->SecretAccessKey }
sub access_key_id     { shift->credentials->AccessKeyId     }
sub session_token     { shift->credentials->SessionToken     }
sub secretAccessKey   { shift->secret_access_key }
sub accessKeyId       { shift->access_key_id     }
sub sessionToken      { shift->session_token     }

sub short_name { shift->session_token; }

1;
