package WebService::SendBird;

use strict;
use warnings;

use Mojo::UserAgent;
use Mojo::URL;

use WebService::SendBird::User;
use WebService::SendBird::GroupChat;

use Carp qw();

our $VERSION = '0.002';

# ABSTRACT: client to work with SendBird API

=head1 NAME

WebService::SendBird - unofficial support for the Sendbird API

=head1 SYNOPSIS

 use WebService::SendBird;

 my $api = WebService::SendBird->new(
     api_token => 'You_Api_Token_Here',
     app_id    => 'You_App_ID_Here',
 );

 my $user = $api->create_user(
     user_id     => 'my_chat_user_1',
     nickname    => 'pumpkin',
     profile_url => undef,
 );

 my $chat = $api->create_group_chat(
     user_ids => [ $user->user_id ],
 );

=head1 DESCRIPTION

Basic implementation for SendBird Platform API client, which helps to create users and group chats.

More information at L<Platform API Documentation|https://docs.sendbird.com/platform>

=cut

use constant DEFAULT_API_URL_TEMPLATE => 'https://api-%s.sendbird.com/v3';
use constant DEFAULT_REQUEST_TIMEOUT  => 15;

=head1 METHODS

=head2 new

Creates an instance of API client

=over 4

=item * C<api_token> - Master or Secondary API Token.

=item * C<app_id> - Sendbird Application ID.

=item * C<api_url> - URL to API end point. By default it will be generated from app_id.

=item * C<ua> - Custom http client for API requests, should have the same interface like L<Mojo::UserAgent>.

=item * C<timeout> - request timeout, default value 15 seconds

=back

=cut

sub new {
    my ($cls, %params) = @_;

    Carp::croak('Missing required argument: api_token')         unless $params{api_token};
    Carp::croak('Missing required argument: app_id or api_url') unless $params{app_id} || $params{api_url};

    my $self = +{
        api_token => $params{api_token},
        $params{ua}      ? (ua      => $params{ua})                      : (),
        $params{app_id}  ? (app_id  => $params{app_id})                  : (),
        $params{api_url} ? (api_url => Mojo::URL->new($params{api_url})) : (),
    };

    return bless $self, $cls;
}

=head2 app_id

Returns Application ID.

=cut

sub app_id { return shift->{app_id} }

=head2 api_token

Returns API Token

=cut

sub api_token { return shift->{api_token} }

=head2 api_url

Returns API endpoint url

=cut

sub api_url {
    my $self = shift;

    $self->{api_url} //= Mojo::URL->new(sprintf(DEFAULT_API_URL_TEMPLATE, $self->app_id));

    return $self->{api_url};
}

=head2 timeout

Return http request timeout value.

=cut

sub timeout { return shift->{timeout} || DEFAULT_REQUEST_TIMEOUT }

=head2 ua

Return User Agent for http request.

=cut

sub ua {
    my $self = shift;

    return $self->{ua} if $self->{ua};

    my $ua = Mojo::UserAgent->new();

    $ua->inactivity_timeout($self->timeout);
    $ua->proxy->detect;

    $self->{ua} = $ua;
    return $self->{ua};
}

=head2 http_headers

Returns headers for API request.

=cut

sub http_headers {
    my $self = shift;

    return {
        'Content-Type' => 'application/json, charset=utf8',
        'Api-Token'    => $self->api_token,
    };
}

=head2 request

Sends request to Sendbird API

=cut

sub request {
    my ($self, $method, $path, $params) = @_;

    my $resp = $self->ua->start(
        $self->ua->build_tx($method, $self->_url_for($path), $self->http_headers, uc($method) eq 'GET' ? (form => $params) : (json => $params),));

    if ($resp->result->is_error) {
        my $details = $resp->result->{content}{asset}{content} // $resp->result->message;
        Carp::croak('Fail to make request to SB API: ' . $details);
    }

    my $data;
    eval {
        $data = $resp->result->json;
        1;
    } or do {
        Carp::croak('Fail to parse response from SB API: ' . $@);
    };

    Carp::croak('Fail to make request to SB API: ' . $data->{message}) if $data->{error};

    return $data;
}

=head2 create_user

Creates a user at SendBird

=over 4

=item * C<user_id> - Unique User Identifier

=item * C<nickname> - User nickname

=item * C<profile_url> - user profile url. Could be C<undef> or empty.

=back

Information about extra parameters could be found at L<API Documentation|https://docs.sendbird.com/platform/user#3_create_a_user>

Method returns an instance of L<WebService::SendBird::User>

=cut

sub create_user {
    my ($self, %params) = @_;

    Carp::croak('profile_url is missed') unless exists $params{profile_url};
    $params{$_} or Carp::croak("$_ is missed") for (qw(user_id nickname));

    my $resp = $self->request(
        POST => 'users',
        \%params
    );

    return WebService::SendBird::User->new(%$resp, api_client => $self);
}

=head2 view_user

Gets information about a user from SendBird

=over 4

=item * C<user_id> - Unique User Identifier

=back

Information about extra parameters could be found at L<API Documentation|https://docs.sendbird.com/platform/user#3_view_a_user>

Method returns an instance of L<WebService::SendBird::User>

=cut

sub view_user {
    my ($self, %params) = @_;

    my $user_id = delete $params{user_id} or Carp::croak('user_id is missed');

    my $resp = $self->request(
        GET => "users/$user_id",
        \%params
    );

    return WebService::SendBird::User->new(%$resp, api_client => $self);
}

=head2 create_group_chat

Creates a group chat room

Information about parameters could be found at L<API Documentation|https://docs.sendbird.com/platform/group_channel#3_create_a_channel>

Method returns an instance of L<WebService::SendBird::GroupChat>

=cut

sub create_group_chat {
    my ($self, %params) = @_;

    my $resp = $self->request(
        POST => "group_channels",
        \%params
    );

    return WebService::SendBird::GroupChat->new(%$resp, api_client => $self);
}

=head2 view_group_chat

Gets information about a group chat from SendBird

=over 4

=item * C<channel_url> - Unique Chat Identifier

=back

Information about parameters could be found at L<API Documentation|https://docs.sendbird.com/platform/group_channel#3_view_a_channel>

Method returns an instance of L<WebService::SendBird::GroupChat>

=cut

sub view_group_chat {
    my ($self, %params) = @_;
    my $channel_url = delete $params{channel_url} or Carp::croak('channel_url is missed');

    my $resp = $self->request(
        GET => "group_channels/$channel_url",
        \%params
    );

    return WebService::SendBird::GroupChat->new(%$resp, api_client => $self);
}

#Private methods

#Returns full URL for requested path
sub _url_for {
    my ($self, $path) = @_;

    return join q{/} => ($self->api_url, $path);
}

1;
