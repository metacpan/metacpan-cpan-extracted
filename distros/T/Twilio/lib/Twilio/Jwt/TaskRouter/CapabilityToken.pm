package Twilio::Jwt::TaskRouter::CapabilityToken;

use 5.016;
use warnings;

use Twilio::Exceptions::TwilioException;
use Twilio::Jwt::JWT;
use Twilio::Jwt::TaskRouter::Policy;

our $VERSION = '2.002';

my $BASE_URL    = 'https://taskrouter.twilio.com/v1';
my $BASE_WS_URL = 'https://event-bridge.twilio.com/v1/wschannels';
my $API_VERSION = 'v1';
my $DEFAULT_TTL = 3600;

sub new {
  my (
    $class,      $account_sid,  $auth_token, $workspace_sid,
    $channel_id, $resource_url, $base_url,   $base_ws_url
  ) = @_;

  my $self = bless {
    account_sid   => $account_sid,
    auth_token    => $auth_token,
    workspace_sid => $workspace_sid,
    channel_id    => $channel_id,
    friendly_name => $channel_id,
    resource_url  => $resource_url,
    base_url      => ($base_url // $BASE_URL) . '/Workspaces/' . ($workspace_sid // q{}),
    base_ws_url   => $base_ws_url // $BASE_WS_URL,
    policies      => [],
  }, $class;

  $self->_validate;
  $self->setup_resource if !defined $resource_url;

  # Every token can use its own event channel, and read its own resource.
  my $channel = join q{/}, $self->{base_ws_url}, $account_sid, $channel_id;
  $self->allow($channel,              'GET',  undef, undef);
  $self->allow($channel,              'POST', undef, undef);
  $self->allow($self->{resource_url}, 'GET',  undef, undef);
  return $self;
}

sub setup_resource { return }

sub add_policy_deconstructed {
  my ($self, $url, $method, @options) = @_;

  my $policy = Twilio::Jwt::TaskRouter::Policy->new($url, $method, @options);
  push @{ $self->{policies} }, $policy;
  return $policy;
}

# Leaving out a filter means an empty one, and passing undef leaves it out of the token.
sub allow {
  my ($self, $url, $method, @filters) = @_;
  $self->add_policy_deconstructed($url, $method, _filter(0, @filters), _filter(1, @filters), 1);
  return;
}

sub deny {
  my ($self, $url, $method, @filters) = @_;
  $self->add_policy_deconstructed($url, $method, _filter(0, @filters), _filter(1, @filters), 0);
  return;
}

sub allow_fetch_subresources {
  my ($self) = @_;
  $self->allow("$self->{resource_url}/**", 'GET');
  return;
}

sub allow_updates {
  my ($self) = @_;
  $self->allow($self->{resource_url}, 'POST');
  return;
}

sub allow_updates_subresources {
  my ($self) = @_;
  $self->allow("$self->{resource_url}/**", 'POST');
  return;
}

sub allow_delete {
  my ($self) = @_;
  $self->allow($self->{resource_url}, 'DELETE');
  return;
}

sub allow_delete_subresources {
  my ($self) = @_;
  $self->allow("$self->{resource_url}/**", 'DELETE');
  return;
}

sub generate_token {
  my ($self, $ttl, $extra_attributes) = @_;

  my $now     = time;
  my $channel = $self->{channel_id};
  my %payload = (
    version       => $API_VERSION,
    friendly_name => $self->{friendly_name},
    iss           => $self->{account_sid},
    exp           => $now + ($ttl // $DEFAULT_TTL),
    account_sid   => $self->{account_sid},
    channel       => $channel,
    workspace_sid => $self->{workspace_sid},
    ($channel =~ /\AWK/ ? (worker_sid    => $channel) : ()),
    ($channel =~ /\AWQ/ ? (taskqueue_sid => $channel) : ()),
    %{ $extra_attributes // {} },
  );
  $payload{policies} = [map { $_->to_hash } @{ $self->{policies} }];

  return Twilio::Jwt::JWT->encode(\%payload, $self->{auth_token});
}

sub _filter {
  my ($position, @filters) = @_;
  return $position < @filters ? $filters[$position] : {};
}

sub _validate {
  my ($self) = @_;

  my $account   = $self->{account_sid}   // q{};
  my $workspace = $self->{workspace_sid} // q{};
  my $channel   = $self->{channel_id};

  _fail("Invalid AccountSid provided: $account")     if $account   !~ /\AAC/;
  _fail("Invalid WorkspaceSid provided: $workspace") if $workspace !~ /\AWS/;
  _fail('ChannelId not provided')                    if !defined $channel;
  _fail("Invalid ChannelId provided: $channel")      if $channel !~ /\AW[SKQ]/;
  return;
}

sub _fail {
  my ($message) = @_;
  Twilio::Exceptions::TwilioException->throw($message);
  return;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Jwt::TaskRouter::CapabilityToken - A TaskRouter capability token

=head1 SYNOPSIS

  use Twilio::Jwt::TaskRouter::WorkerCapability;

  my $capability = Twilio::Jwt::TaskRouter::WorkerCapability->new(
    $account_sid, $auth_token, $workspace_sid, $worker_sid
  );
  $capability->allow_activity_updates;

  print $capability->generate_token(3600);

=head1 DESCRIPTION

The base class of L<Twilio::Jwt::TaskRouter::WorkerCapability>,
L<Twilio::Jwt::TaskRouter::TaskQueueCapability> and
L<Twilio::Jwt::TaskRouter::WorkspaceCapability>, which are the ones to use. Each
token can use its own event channel and read its own resource, and these methods
add more.

=head1 METHODS

=head2 new

  my $capability = Twilio::Jwt::TaskRouter::CapabilityToken->new(
    $account_sid, $auth_token, $workspace_sid, $channel_id,
    $resource_url, $base_url, $base_ws_url
  );

The last three are optional. It throws L<Twilio::Exceptions::TwilioException> when
a SID does not look right.

=head2 allow

  $capability->allow($url, $method, \%query_filter, \%post_filter);

Adds a policy that allows a request. A filter that is left out is empty, and an
undefined one is left out of the token.

=head2 deny

  $capability->deny($url, $method, \%query_filter, \%post_filter);

Adds a policy that denies a request.

=head2 add_policy_deconstructed

  my $policy = $capability->add_policy_deconstructed(
    $url, $method, \%query_filter, \%post_filter, $allow
  );

Adds a policy, and returns its L<Twilio::Jwt::TaskRouter::Policy>.

=head2 allow_fetch_subresources

=head2 allow_updates

=head2 allow_updates_subresources

=head2 allow_delete

=head2 allow_delete_subresources

Allow what each name says, on the resource of the token.

=head2 generate_token

  my $token = $capability->generate_token($ttl, \%extra_attributes);

Returns the token. C<$ttl> is in seconds, and defaults to 3600.

=head2 setup_resource

Sets the URL of the resource. Subclasses implement it.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
