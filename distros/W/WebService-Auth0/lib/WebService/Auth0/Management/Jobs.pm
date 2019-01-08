package WebService::Auth0::Management::Jobs;

use Moo;
extends 'WebService::Auth0::Management::Base';
with 'WebService::Auth0::Management::Role::Get',

sub path_suffix { 'jobs' }

sub errors {
  my ($self, $job_id) = @_;
  return $self->GET($self->uri_for($job_id, 'errors'));
}

sub user_imports {
  my ($self, $params) = @_;
  return $self->POST_JSON($self->uri_for('user-imports'), $params);
}

sub verification_email {
  my ($self, $params) = @_;
  return $self->POST_JSON($self->uri_for('verification-email'), $params);
}

=head1 NAME

WebService::Auth0::Management::Jobs - Users management API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

This class defines the following methods:

=head2 get ($job_id)

Get a job by ID

L<https://auth0.com/docs/api/management/v2#!/Jobs/get_jobs_by_id>

=head2 errors ($job_id)

Errors associated with a $job_id

L<https://auth0.com/docs/api/management/v2#!/Jobs/get_errors>

=head2 user_imports

L<https://auth0.com/docs/api/management/v2#!/Jobs/post_users_imports>

=head2 verification_email

L<https://auth0.com/docs/api/management/v2#!/Jobs/post_verification_email>

=head1 SEE ALSO
 
L<WebService::Auth0>, L<https://auth0.com>.

=head1 AUTHOR
 
    See L<WebService::Auth0>
  
=head1 COPYRIGHT & LICENSE
 
    See L<WebService::Auth0>

=cut

1;
