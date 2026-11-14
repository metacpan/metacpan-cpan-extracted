package Twilio::Jwt::TaskRouter::TaskQueueCapability;

use 5.016;
use warnings;

use parent 'Twilio::Jwt::TaskRouter::CapabilityToken';

our $VERSION = '2.002';

sub new {
  my ($class, $account_sid, $auth_token, $workspace_sid, $task_queue_sid, $base_url, $base_ws_url)
    = @_;
  return $class->SUPER::new($account_sid, $auth_token, $workspace_sid, $task_queue_sid, undef,
    $base_url, $base_ws_url);
}

sub setup_resource {
  my ($self) = @_;
  $self->{resource_url} = "$self->{base_url}/TaskQueues/$self->{channel_id}";
  return;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Jwt::TaskRouter::TaskQueueCapability - A capability token for a task queue

=head1 SYNOPSIS

  my $capability = Twilio::Jwt::TaskRouter::TaskQueueCapability->new(
    $account_sid, $auth_token, $workspace_sid, $task_queue_sid
  );

  print $capability->generate_token;

=head1 DESCRIPTION

See L<Twilio::Jwt::TaskRouter::CapabilityToken> for the other methods.

=head1 METHODS

=head2 new

  my $capability = Twilio::Jwt::TaskRouter::TaskQueueCapability->new(
    $account_sid, $auth_token, $workspace_sid, $task_queue_sid, $base_url, $base_ws_url
  );

=head2 setup_resource

Sets the URL of the task queue.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
