package WebService::Auth0::Management::ResourceServers;

use Moo;
extends 'WebService::Auth0::Management::Base';
with 'WebService::Auth0::Management::Role::All',
  'WebService::Auth0::Management::Role::Create',
  'WebService::Auth0::Management::Role::Get',
  'WebService::Auth0::Management::Role::Update',
  'WebService::Auth0::Management::Role::Delete';

sub path_suffix { 'resource-servers' }

=head1 NAME

WebService::Auth0::Management::ResourceServers - Users management API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

This class defines the following methods:

=head2 all

L<https://auth0.com/docs/api/management/v2#!/Resource_Servers/get_resource_servers>

=head2 create (\%params)

L<https://auth0.com/docs/api/management/v2#!/Resource_Servers/post_resource_servers>

=head2 get ($id)

L<https://auth0.com/docs/api/management/v2#!/Resource_Servers/get_resource_servers_by_id>

=head2 delete ($id)

L<https://auth0.com/docs/api/management/v2#!/Resource_Servers/delete_resource_servers_by_id>

=head2 update ($id, \%params)

L<https://auth0.com/docs/api/management/v2#!/Resource_Servers/patch_resource_servers_by_id>

=head1 SEE ALSO
 
L<WebService::Auth0>, L<https://auth0.com>.

=head1 AUTHOR
 
    See L<WebService::Auth0>
  
=head1 COPYRIGHT & LICENSE
 
    See L<WebService::Auth0>

=cut

1;
