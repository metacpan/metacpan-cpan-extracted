package WebService::Auth0::Management::UserBlocks;

use Moo;
extends 'WebService::Auth0::Management::Base';
with 'WebService::Auth0::Management::Role::Search',
  'WebService::Auth0::Management::Role::All',
  'WebService::Auth0::Management::Role::Delete',
  'WebService::Auth0::Management::Role::Get',
  'WebService::Auth0::Management::Role::Update',

sub path_suffix { 'user-blocks' }

sub get_by_email {
  my ($self, $email) = @_;
  return $self->search({email=>$email});
}

sub get_by_username {
  my ($self, $username) = @_;
  return $self->search({username=>$username});
}

sub get_by_phone_number {
  my ($self, $phone_number) = @_;
  return $self->search({phone_number=>$phone_number});
}

sub delete_by {
  my ($self, $query) = @_;
  return $self->DELETE($self->uri_for($query));
}

sub delete_by_email {
  my ($self, $email) = @_;
  return $self->delete_by({email=>$email});
}

sub delete_by_username {
  my ($self, $username) = @_;
  return $self->delete_by({username=>$username});
}

sub delete_by_phone_number {
  my ($self, $phone_number) = @_;
  return $self->delete_by({phone_number=>$phone_number});
}

=head1 NAME

WebService::Auth0::Management::UserBlocks - Users management API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

This class defines the following methods:

=head2 search (\%query)

=head2 get_by_phone_number ($phone_number)

=head2 get_by_username ($username)

=head2 get_by_email ($email)

L<https://auth0.com/docs/api/management/v2#!/User_Blocks/get_user_blocks>

=head2 delete_by (\%query)

=head2 delete_by_phone_number ($phone_number)

=head2 delete_by_username ($username)

=head2 delete_by_email ($email)

L<https://auth0.com/docs/api/management/v2#!/User_Blocks/delete_user_blocks>

=head2 create (\%params)

L<https://auth0.com/docs/api/management/v2#!/Rules/post_rules>

=head2 get ($id)

L<https://auth0.com/docs/api/management/v2#!/Rules/get_rules_by_id>

=head2 delete ($id)

L<https://auth0.com/docs/api/management/v2#!/Rules/delete_rules_by_id>

=head2 update ($id, \%params)

L<https://auth0.com/docs/api/management/v2#!/Rules/patch_rules_by_id>

=head2 all ($user_id)

L<https://auth0.com/docs/api/management/v2#!/User_Blocks/get_user_blocks_by_id>

=head2 delete ($user_id)

L<https://auth0.com/docs/api/management/v2#!/User_Blocks/delete_user_blocks_by_id>

=head1 SEE ALSO
 
L<WebService::Auth0>, L<https://auth0.com>.

=head1 AUTHOR
 
    See L<WebService::Auth0>
  
=head1 COPYRIGHT & LICENSE
 
    See L<WebService::Auth0>

=cut

1;
