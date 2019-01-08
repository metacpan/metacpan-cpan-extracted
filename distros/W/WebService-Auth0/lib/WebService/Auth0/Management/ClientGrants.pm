package WebService::Auth0::Management::ClientGrants;

use Moo;
extends 'WebService::Auth0::Management::Base';
with 'WebService::Auth0::Management::Role::Search',
  'WebService::Auth0::Management::Role::Create',
  'WebService::Auth0::Management::Role::Update',
  'WebService::Auth0::Management::Role::Delete';

sub path_suffix { 'client-grants' }

sub all { return shift->search(+{}) }

=head1 NAME

WebService::Auth0::Management::Users - Users management API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

This class defines the following methods:

=head2 search (\%params)

L<https://auth0.com/docs/api/management/v2#!/Client_Grants/get_client_grants>

Either get all the client grants, or search for client grants filterd by
audience.

=head2 all 

Gets all the client grants.  Is basically a shortcut for '->search(+{})'.  See
L<https://auth0.com/docs/api/management/v2#!/Client_Grants/get_client_grants> for
more.

=head2 create (\%params)

L<https://auth0.com/docs/api/management/v2#!/Client_Grants/post_client_grants>

=head2 delete ($client_grant_id)

L<https://auth0.com/docs/api/management/v2#!/Client_Grants/delete_client_grants_by_id>

=head2 update ($client_grant_id, \%params)

L<https://auth0.com/docs/api/management/v2#!/Users/patch_users_by_id>

=head1 SEE ALSO
 
L<WebService::Auth0>, L<https://auth0.com>.

=head1 AUTHOR
 
    See L<WebService::Auth0>
  
=head1 COPYRIGHT & LICENSE
 
    See L<WebService::Auth0>

=cut

1;
