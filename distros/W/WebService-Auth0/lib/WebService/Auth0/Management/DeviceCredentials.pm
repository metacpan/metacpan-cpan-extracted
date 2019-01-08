package WebService::Auth0::Management::DeviceCredentials;

use Moo;

extends 'WebService::Auth0::Management::Base';
with 'WebService::Auth0::Management::Role::All',
  'WebService::Auth0::Management::Role::Search',
  'WebService::Auth0::Management::Role::Create',
  'WebService::Auth0::Management::Role::Delete';

sub path_suffix { 'device-credentials' }

=head1 NAME

WebService::Auth0::Management::DeviceCredentials - Device Credential manager

=head1 SYNOPSIS

    NA

=head1 DESCRIPTION

    You can copy this template for making new management endpoints to help
    you get rolling faster.

=head1 METHODS

This class defines the following methods:

=head2 all

=head2 search

L<https://auth0.com/docs/api/management/v2#!/Device_Credentials/get_device_credentials> 

=head2 create

L<https://auth0.com/docs/api/management/v2#!/Device_Credentials/post_device_credentials>

=head2 delete

L<https://auth0.com/docs/api/management/v2#!/Device_Credentials/delete_device_credentials_by_id>

=head1 SEE ALSO
 
L<WebService::Auth0>, L<WebService::Auth0::Management::Base>,
L<https://auth0.com>.

=head1 AUTHOR
 
    See L<WebService::Auth0>
  
=head1 COPYRIGHT & LICENSE
 
    See L<WebService::Auth0>

=cut

1;
