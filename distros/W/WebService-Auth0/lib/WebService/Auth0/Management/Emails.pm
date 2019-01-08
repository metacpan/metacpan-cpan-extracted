package WebService::Auth0::Management::Emails;

use Moo;
extends 'WebService::Auth0::Management::Base';

sub path_suffix { 'emails' }

sub get {
  my ($self) = @_;
  return $self->GET($self->uri_for());
}

sub delete {
  my ($self) = @_;
  return $self->DELETE($self->uri_for());
}

sub configure {
  my ($self, $data) = @_;
  return $self->POST_JSON($self->uri_for(), $data);
}

sub update {
  my ($self, $data) = @_;
  return $self->PATCH_JSON($self->uri_for(), $data);
}

=head1 NAME

WebService::Auth0::Management::Emails - Users management API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

This class defines the following methods:

=head2 get

L<https://auth0.com/docs/api/management/v2#!/Emails/get_provider>

=head2 delete

L<https://auth0.com/docs/api/management/v2#!/Emails/delete_provider>

=head2 configure (\%params)

L<https://auth0.com/docs/api/management/v2#!/Emails/post_provider>

=head2 update (\%params)

L<https://auth0.com/docs/api/management/v2#!/Emails/patch_provider>

=head1 SEE ALSO
 
L<WebService::Auth0>, L<https://auth0.com>.

=head1 AUTHOR
 
    See L<WebService::Auth0>
  
=head1 COPYRIGHT & LICENSE
 
    See L<WebService::Auth0>

=cut

1;
