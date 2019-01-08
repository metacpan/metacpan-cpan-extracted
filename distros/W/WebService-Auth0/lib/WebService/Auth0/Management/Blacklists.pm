package WebService::Auth0::Management::Blacklists;

use Moo;
extends 'WebService::Auth0::Management::Base';
with 'WebService::Auth0::Management::Role::Search',
  'WebService::Auth0::Management::Role::All',
  'WebService::Auth0::Management::Role::Create';

sub path_suffix { 'blacklists' }

=head1 NAME

WebService::Auth0::Management::Blacklists - Users management API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

This class defines the following methods:

=head2 all

=head2 search (\%params)

L<https://auth0.com/docs/api/management/v2#!/Blacklists/get_tokens>

=head2 create ($params)

L<https://auth0.com/docs/api/management/v2#!/Blacklists/post_tokens>

=head1 SEE ALSO
 
L<WebService::Auth0>, L<https://auth0.com>.

=head1 AUTHOR
 
    See L<WebService::Auth0>
  
=head1 COPYRIGHT & LICENSE
 
    See L<WebService::Auth0>

=cut

1;
