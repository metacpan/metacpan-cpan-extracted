package WebService::Auth0::Management::Users;

use Moo;
extends 'WebService::Auth0::Management::Base';
with 'WebService::Auth0::Management::Role::Search',
  'WebService::Auth0::Management::Role::Create',
  'WebService::Auth0::Management::Role::Get',
  'WebService::Auth0::Management::Role::Update',
  'WebService::Auth0::Management::Role::Delete';

sub path_suffix { 'users' }

sub update_user_metadata {
  my ($self, $user_id, $data) = @_;
  return $self->update($user_id, +{user_metadata=>$data});
}

sub update_app_metadata {
  my ($self, $user_id, $data) = @_;
  return $self->update($user_id, +{app_metadata=>$data});
}

sub link_account {
  my ($self, $user_id, $data) = @_;
  return $self->POST_JSON($self->uri_for($user_id), $data);
}

sub unlink_account {
  my ($self, $user_id, $provider, $identity_id) = @_;
  my $uri = $self->uri_for($user_id,'identities', $provider, $identity_id);
  return $self->DELETE($uri);
}

sub get_enrollments {
  my ($self, $user_id) = @_;
  return $self->GET($self->uri_for($user_id, 'enrollments'))
}

sub delete_multifactor_by_provider {
  my ($self, $user_id, $provider) = @_;
  return $self->DELETE($self->uri_for($user_id, 'multifactor', $provider))
}

sub recovery_code_regeneration {
  my ($self, $user_id) = @_;
  return $self->POST($self->uri_for($user_id, 'recovery-code-regeneration'));
}

=head1 NAME

WebService::Auth0::Management::Users - Users management API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

This class defines the following methods:

=head2 search (\%params)

L<https://auth0.com/docs/api/management/v2#!/Users/get_users>

=head2 create (\%params)

L<https://auth0.com/docs/api/management/v2#!/Users/post_users>

=head2 get ($user_id)

L<https://auth0.com/docs/api/management/v2#!/Users/get_users_by_id>

=head2 delete ($user_id)

Delete a user.

L<https://auth0.com/docs/api/management/v2#!/Users/delete_users_by_id>

=head2 update ($user_id, \%params)

L<https://auth0.com/docs/api/management/v2#!/Users/patch_users_by_id>

=head2 update_user_metadata ($user_id, \%params)

=head2 update_app_metadata ($user_id, \%params)

Helper shortcuts to update the user or user application metadata

=head2 get_enrollments ($user_id)

L<https://auth0.com/docs/api/management/v2#!/Users/get_enrollments>

=head2 get_logs_by_user ($user_id)

L<https://auth0.com/docs/api/management/v2#!/Users/get_logs_by_user>

=head2 delete_multifactor_by_provider ($user_id, $provider)

L<https://auth0.com/docs/api/management/v2#!/Users/delete_multifactor_by_provider>

=head2 link_account ($id, \%params)

L<https://auth0.com/docs/api/management/v2#!/Users/post_identities>

=head2 unlink_account ($user_id, $provider, $target_id)

L<https://auth0.com/docs/api/management/v2#!/Users/delete_provider_by_user_id>

=head2 recovery_code_regeneration ($user_id)

L<https://auth0.com/docs/api/management/v2#!/Users/post_recovery_code_regeneration>

=head1 SEE ALSO
 
L<WebService::Auth0>, L<https://auth0.com>.

=head1 AUTHOR
 
    See L<WebService::Auth0>
  
=head1 COPYRIGHT & LICENSE
 
    See L<WebService::Auth0>

=cut

1;
