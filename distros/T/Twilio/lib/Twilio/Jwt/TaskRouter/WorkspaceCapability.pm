package Twilio::Jwt::TaskRouter::WorkspaceCapability;

use 5.016;
use warnings;

use parent 'Twilio::Jwt::TaskRouter::CapabilityToken';

our $VERSION = '2.002';

sub new {
  my ($class, $account_sid, $auth_token, $workspace_sid, $base_url, $base_ws_url) = @_;
  return $class->SUPER::new($account_sid, $auth_token, $workspace_sid, $workspace_sid, undef,
    $base_url, $base_ws_url);
}

sub setup_resource {
  my ($self) = @_;
  $self->{resource_url} = $self->{base_url};
  return;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Jwt::TaskRouter::WorkspaceCapability - A capability token for a workspace

=head1 SYNOPSIS

  my $capability = Twilio::Jwt::TaskRouter::WorkspaceCapability->new(
    $account_sid, $auth_token, $workspace_sid
  );

  print $capability->generate_token;

=head1 DESCRIPTION

See L<Twilio::Jwt::TaskRouter::CapabilityToken> for the other methods.

=head1 METHODS

=head2 new

  my $capability = Twilio::Jwt::TaskRouter::WorkspaceCapability->new(
    $account_sid, $auth_token, $workspace_sid, $base_url, $base_ws_url
  );

=head2 setup_resource

Sets the URL of the workspace.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
