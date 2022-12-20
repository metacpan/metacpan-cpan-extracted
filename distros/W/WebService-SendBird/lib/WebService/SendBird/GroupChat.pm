package WebService::SendBird::GroupChat;

use strict;
use warnings;

use Carp;
use JSON::MaybeXS ();
use WebService::SendBird::User;

our $VERSION = '0.002';    ## VERSION

=head1 NAME

WebService::SendBird::GroupChat - SendBird Group Chat

=head1 SYNOPSIS

 use WebService::SendBird::Group;

 my $chat = WebService::SendBird::User->new(
     api_client  => $api,
     channel_url => 'chat_room_1',
 );

 $chat->update(name => 'Gossips');

=head1 DESCRIPTION

Class for SendBird Group Channel. Information about structure could be found at L<API Documentation|https://docs.sendbird.com/platform/group_channel>

=cut

use constant REQUIRED_FIELDS => qw(
    api_client
    channel_url
);

use constant OPTIONAL_FIELDS => qw(
    is_broadcast
    name
    is_access_code_required
    is_super
    joined_member_count
    is_public
    cover_url
    unread_mention_count
    is_created
    is_distinct
    is_ephemeral
    freeze
    data
    is_discoverable
    last_message
    sms_fallback_interval_sec
    custom_type
    unread_message_count
    created_at
    member_count
    sms_fallback_enabled
    max_length_message
    members
);

{
    no strict 'refs';
    for my $field (REQUIRED_FIELDS, OPTIONAL_FIELDS) {
        *{__PACKAGE__ . '::' . $field} = sub { shift->{$field} };
    }
}

=head2 new

Creates an instance of SendBird Group Chat

=over 4

=item * C<api_client> - SendBird API client L<WebService::SendBird>.

=item * C<channel_url> - Unique Channel Identifier

=back

=cut

sub new {
    my ($cls, %params) = @_;

    my $self = +{};
    $self->{$_} = delete $params{$_} or Carp::croak "$_ is missed" for (REQUIRED_FIELDS);

    $self->{$_} = delete $params{$_} for (OPTIONAL_FIELDS);

    $self->{members} //= [];
    my @obj_members = map { WebService::SendBird::User->new(%$_, api_client => $self->{api_client}) } @{$self->{members}};
    $self->{members} = \@obj_members;

    return bless $self, $cls;
}

=head2 Getters

=over 4

=item * C<api_client>

=item * C<channel_url>

=item * C<is_broadcast>

=item * C<name>

=item * C<is_access_code_required>

=item * C<is_super>

=item * C<joined_member_count>

=item * C<is_public>

=item * C<cover_url>

=item * C<unread_mention_count>

=item * C<is_created>

=item * C<is_distinct>

=item * C<is_ephemeral>

=item * C<freeze>

=item * C<data>

=item * C<is_discoverable>

=item * C<last_message>

=item * C<sms_fallback_interval_sec>

=item * C<custom_type>

=item * C<unread_message_count>

=item * C<created_at>

=item * C<member_count>

=item * C<sms_fallback_enabled>

=item * C<max_length_message>

=item * C<members>

=back

=cut

=head2 update

Updates the group channel at SendBird API

Information about parameters could be found at L<API Documentation|https://docs.sendbird.com/platform/group_channel#3_update_a_channel>

=cut

sub update {
    my ($self, %params) = @_;

    my $res = $self->api_client->request(
        PUT => 'group_channels/' . $self->channel_url,
        \%params
    );

    $self->{$_} = $res->{$_} for qw(OPTIONAL_FIELDS);

    return $self;
}

=head2 set_freeze

Freeze or unfreeze the channel.

See L<https://sendbird.com/docs/chat/v3/platform-api/guides/group-channel#2-freeze-a-channel>.

=cut

sub set_freeze {
    my ($self, $freeze) = @_;

    $freeze = $freeze ? JSON::MaybeXS::true : JSON::MaybeXS::false;

    my $res = $self->api_client->request(
        PUT => 'group_channels/' . $self->channel_url . '/freeze',
        {freeze => $freeze});

    $self->{freeze} = $res->{freeze};
    return $self;
}

1;
