package VM::EC2::REST::security_token;

use strict;
use VM::EC2 '';  # important not to import anything!
package VM::EC2;  # add methods to VM::EC2

VM::EC2::Dispatch->register(
    GetFederationToken                => 'fetch_one,GetFederationTokenResult,VM::EC2::Security::Token',
    GetSessionToken                   => 'fetch_one,GetSessionTokenResult,VM::EC2::Security::Token',
    );

sub sts_call {
    my $self = shift;
    local $self->{endpoint} = 'https://sts.amazonaws.com';
    local $self->{version}  = '2011-06-15';
    $self->call(@_);
}

=head1 NAME VM::EC2::REST::security_token

=head1 SYNOPSIS

 use VM::EC2 qw(:standard);

=head1 EC2 REGIONS AND AVAILABILITY ZONES

AWS security tokens provide a way to grant temporary access to
resources in your EC2 space without giving them permanent
accounts. They also provide the foundation for mobile services and
multifactor authentication devices (MFA).

Used in conjunction with VM::EC2::Security::Policy and
VM::EC2::Security::Credentials, you can create a temporary user who is
authenticated for a limited length of time and pass the credentials to
him or her via a secure channel. He or she can then create a
credentials object to access your AWS resources.

Here is an example:

 # on your side of the connection
 $ec2 = VM::EC2->new(...);  # as usual
 my $policy = VM::EC2::Security::Policy->new;
 $policy->allow('DescribeImages','RunInstances');
 my $token = $ec2->get_federation_token(-name     => 'TemporaryUser',
                                        -duration => 60*60*3, # 3 hrs, as seconds
                                        -policy   => $policy);
 my $serialized = $token->credentials->serialize;
 send_data_to_user_somehow($serialized);

 # on the temporary user's side of the connection
 my $serialized = get_data_somehow();
 my $token = VM::EC2::Security::Credentials->new_from_serialized($serialized);
 my $ec2   = VM::EC2->new(-security_token => $token);
 print $ec2->describe_images(-owner=>'self');

For temporary users who are not using the Perl VM::EC2 API, you can
transmit the required fields individually:

 my $credentials   = $token->credentials;
 my $access_key_id = $credentials->accessKeyId;
 my $secret_key    = $credentials->secretKey;
 my $session_token = $credentials->sessionToken;
 send_data_to_user_somehow($session_token,
                           $access_key_id,
                           $secret_key);

Calls to get_federation_token() return a VM::EC2::Security::Token
object. This object contains two sub-objects, a
VM::EC2::Security::Credentials object, and a
VM::EC2::Security::FederatedUser object. The Credentials object
contains a temporary access key ID, secret access key, and session
token which together can be used to authenticate to the EC2 API.  The
FederatedUser object contains the temporary user account name and ID.

See L<VM::EC2::Security::Token>, L<VM::EC2::Security::FederatedUser>,
L<VM::EC2::Security::Credentials>, and L<VM::EC2::Security::Policy>.

Implemented:
 GetFederationToken
 GetSessionToken

Unimplemented:
 (none)

=cut

=head2 $token = $ec2->get_federation_token($username)

=head2 $token = $ec2->get_federation_token(-name=>$username,@args)

This method creates a new temporary user under the provided username
and returns a VM::EC2::Security::Token object that contains temporary
credentials for the user, as well as information about the user's
account. Other options allow you to control the duration for which the
credentials will be valid, and the policy the controls what resources
the user is allowed to access.

=over 4

=item Required arguments:

 -name The username

The username must comply with the guidelines described in
http://docs.amazonwebservices.com/IAM/latest/UserGuide/LimitationsOnEntities.html:
essentially all alphanumeric plus the characters [+=,.@-].

=item Optional arguments:

 -duration_seconds Length of time the session token will be valid for,
                    expressed in seconds. 

 -duration         Same thing, faster to type.

 -policy           A VM::EC2::Security::Policy object, or a JSON string
                     complying with the IAM policy syntax.

The duration must be no shorter than 1 hour (3600 seconds) and no
longer than 36 hours (129600 seconds). If no duration is specified,
Amazon will default to 12 hours. If no policy is provided, then the
user will not be able to execute B<any> actions.

Note that if the temporary user wishes to create a VM::EC2 object and
specify a region name at create time
(e.g. VM::EC2->new(-region=>'us-west-1'), then the user must have
access to the DescribeRegions action:

 $policy->allow('DescribeRegions')

Otherwise the call to new() will fail.

=back

=cut

sub get_federation_token {
    my $self = shift;
    my %args = $self->args('-name',@_);
    $args{-name} or croak "Usage: get_federation_token(-name=>\$name,\@more_args)";
    $args{-duration_seconds} ||= $args{-duration};
    my @p = map {$self->single_parm($_,\%args)} qw(Name DurationSeconds Policy);
    return $self->sts_call('GetFederationToken',@p);
}

=head2 $token = $ec2->get_session_token(%args)

This method creates a temporary VM::EC2::Security::Token object for an
anonymous user. The token has no policy associated with it, and can be
used to run any of the EC2 actions available to the user who created
the token. Optional arguments allow the session token to be used in
conjunction with MFA devices.

=over 4

=item Required arguments:

none

=item Optional arguments:

 -duration_seconds Length of time the session token will be valid for,
                    expressed in seconds.

 -duration         Same thing, faster to type.

 -serial_number    The identification number of the user's MFA device,
                     if any.

 -token_code       The code provided by the MFA device, if any.

If no duration is specified, Amazon will default to 12 hours.

See
http://docs.amazonwebservices.com/IAM/latest/UserGuide/Using_ManagingMFA.html
for information on using AWS in conjunction with MFA devices.

=back

=cut

sub get_session_token {
    my $self = shift;
    my %args = @_;
    my @p = map {$self->single_parm($_,\%args)} qw(SerialNumber DurationSeconds TokenCode);
    return $self->sts_call('GetSessionToken',@p);
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
