package Twilio::Jwt::TaskRouter::WorkerCapability;

use 5.016;
use warnings;

use parent 'Twilio::Jwt::TaskRouter::CapabilityToken';

our $VERSION = '2.001';

sub new {
  my ($class, $account_sid, $auth_token, $workspace_sid, $worker_sid, $base_url, $base_ws_url) = @_;

  my $self = $class->SUPER::new($account_sid, $auth_token, $workspace_sid, $worker_sid, undef,
    $base_url, $base_ws_url);

  $self->{tasks_url}               = "$self->{base_url}/Tasks/**";
  $self->{activity_url}            = "$self->{base_url}/Activities";
  $self->{worker_reservations_url} = "$self->{resource_url}/Reservations/**";

  $self->allow($self->{activity_url},            'GET', undef, undef);
  $self->allow($self->{tasks_url},               'GET', undef, undef);
  $self->allow($self->{worker_reservations_url}, 'GET', undef, undef);
  return $self;
}

sub setup_resource {
  my ($self) = @_;
  $self->{resource_url} = "$self->{base_url}/Workers/$self->{channel_id}";
  return;
}

sub allow_activity_updates {
  my ($self) = @_;
  $self->allow($self->{resource_url}, 'POST', {}, { ActivitySid => { required => \1 } });
  return;
}

sub allow_reservation_updates {
  my ($self) = @_;
  $self->allow($self->{tasks_url},               'POST');
  $self->allow($self->{worker_reservations_url}, 'POST');
  return;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Jwt::TaskRouter::WorkerCapability - A capability token for a worker

=head1 SYNOPSIS

  my $capability = Twilio::Jwt::TaskRouter::WorkerCapability->new(
    $account_sid, $auth_token, $workspace_sid, $worker_sid
  );
  $capability->allow_activity_updates;
  $capability->allow_reservation_updates;

  print $capability->generate_token;

=head1 DESCRIPTION

See L<Twilio::Jwt::TaskRouter::CapabilityToken> for the other methods. A worker
can also read the activities, the tasks and its own reservations.

=head1 METHODS

=head2 new

  my $capability = Twilio::Jwt::TaskRouter::WorkerCapability->new(
    $account_sid, $auth_token, $workspace_sid, $worker_sid, $base_url, $base_ws_url
  );

=head2 allow_activity_updates

Lets the worker change its activity.

=head2 allow_reservation_updates

Lets the worker update tasks and its reservations.

=head2 setup_resource

Sets the URL of the worker.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
