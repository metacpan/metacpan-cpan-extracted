package WebService::Auth0::Management::Logs;

use Moo;
extends 'WebService::Auth0::Management::Base';
with 'WebService::Auth0::Management::Role::Search',
  'WebService::Auth0::Management::Role::Get';

sub path_suffix { 'logs' }

=head1 NAME

WebService::Auth0::Management::Logs- Users management API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

This class defines the following methods:

=head2 search (\%params)

L<https://auth0.com/docs/api/management/v2#!/Logs/get_logs>

=head2 get ($id)

L<https://auth0.com/docs/api/management/v2#!/Logs/get_logs_by_id>

=head1 SEE ALSO
 
L<WebService::Auth0>, L<https://auth0.com>.

=head1 AUTHOR
 
    See L<WebService::Auth0>
  
=head1 COPYRIGHT & LICENSE
 
    See L<WebService::Auth0>

=cut

1;
