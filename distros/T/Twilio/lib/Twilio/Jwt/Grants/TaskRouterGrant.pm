package Twilio::Jwt::Grants::TaskRouterGrant;

use 5.016;
use warnings;

use parent 'Twilio::Jwt::Grants::Grant';

our $VERSION = '2.002';

sub get_grant_key { return 'task_router' }

sub payload_fields { return qw(workspace_sid worker_sid role) }

sub get_workspace_sid { return $_[0]{workspace_sid} }
sub get_worker_sid    { return $_[0]{worker_sid} }
sub get_role          { return $_[0]{role} }

sub set_workspace_sid {
  my ($self, $sid) = @_;
  $self->{workspace_sid} = $sid;
  return $self;
}

sub set_worker_sid {
  my ($self, $sid) = @_;
  $self->{worker_sid} = $sid;
  return $self;
}

sub set_role {
  my ($self, $role) = @_;
  $self->{role} = $role;
  return $self;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Jwt::Grants::TaskRouterGrant - Lets a client work with TaskRouter

=head1 SYNOPSIS

  my $grant = Twilio::Jwt::Grants::TaskRouterGrant->new;
  $grant->set_workspace_sid($workspace_sid);
  $grant->set_worker_sid($worker_sid);
  $grant->set_role('worker');

  $token->add_grant($grant);

=head1 DESCRIPTION

See L<Twilio::Jwt::AccessToken>. Each C<set_> method returns the grant.

=head1 METHODS

=head2 get_grant_key

Returns C<task_router>.

=head2 payload_fields

Returns the fields of the grant.

=head2 get_workspace_sid

=head2 set_workspace_sid

=head2 get_worker_sid

=head2 set_worker_sid

=head2 get_role

=head2 set_role

Read and change each value.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
