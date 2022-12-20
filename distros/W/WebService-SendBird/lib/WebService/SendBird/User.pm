package WebService::SendBird::User;

use strict;
use warnings;

use Carp;
use JSON::MaybeXS;

our $VERSION = '0.002';    ## VERSION

=head1 NAME

WebService::SendBird::User - SendBird User

=head1 SYNOPSIS

 use WebService::SendBird::User;

 my $user = WebService::SendBird::User->new(
     api_client => $api,
     user_id    => 'my_chat_user_1',
 );

 $user->update(nickname => 'cucumber');

 my $token_data = $user->issue_session_token;

=head1 DESCRIPTION

Class for SendBird User. Information about structure could be found at L<API Documentation|https://docs.sendbird.com/platform/user>

=cut

use constant REQUIRED_FIELDS => qw(
    api_client
    user_id
);

use constant OPTIONAL_FIELDS => qw(
    phone_number
    has_ever_logged_in
    session_tokens
    access_token
    discovery_keys
    is_online
    last_seen_at
    nickname
    profile_url
    metadata
);

{
    no strict 'refs';
    for my $field (REQUIRED_FIELDS, OPTIONAL_FIELDS) {
        *{__PACKAGE__ . '::' . $field} = sub { shift->{$field} };
    }
}

=head2 new

Creates an instance of SendBird User

=over 4

=item * C<api_client> - SendBird API client L<WebService::SendBird>.

=item * C<user_id> - Unique User Identifier

=back

=cut

sub new {
    my ($cls, %params) = @_;

    my $self = +{};
    $self->{$_} = delete $params{$_} or Carp::croak "$_ is missed" for (REQUIRED_FIELDS);

    $self->{$_} = delete $params{$_} for (OPTIONAL_FIELDS);

    return bless $self, $cls;
}

=head2 Getters

=over 4

=item * C<api_client>

=item * C<user_id>

=item * C<phone_number>

=item * C<has_ever_logged_in>

=item * C<session_tokens>

=item * C<access_token>

=item * C<discovery_keys>

=item * C<is_online>

=item * C<last_seen_at>

=item * C<nickname>

=item * C<profile_url>

=item * C<metadata>

=back

=cut

=head2 update

Updates the user at SendBird API

Information about parameters could be found at L<API Documentation|https://docs.sendbird.com/platform/user#3_update_a_user>

=cut

sub update {
    my ($self, %params) = @_;

    my $res = $self->api_client->request(
        PUT => 'users/' . $self->user_id,
        \%params
    );

    $self->{$_} = $res->{$_} for (OPTIONAL_FIELDS);

    return $self;
}

=head2 issue_session_token

Issues new session token and returns hash ref with token and expiration time of this token.

=cut

sub issue_session_token {
    my ($self) = @_;

    $self->update(issue_session_token => JSON::MaybeXS::true);

    my $tokens = $self->session_tokens // [];

    my ($latest_token) = sort { $b->{expires_at} <=> $a->{expires_at} } @$tokens;

    return $latest_token;
}

1;
