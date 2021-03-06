package WebService::Gitter;
$WebService::Gitter::VERSION = '2.2.0';
#ABSTRACT: An interface to Gitter REST API via Perl 5.

use strict;
use warnings;

use Moo;
use Function::Parameters;
with 'WebService::Client';

has api_key => (
    is       => 'ro',
    required => 1
);

has '+base_url' => ( default => 'https://api.gitter.im/v1' );

method get_me() {

    return $self->get( "/user/me?access_token=" . $self->api_key );
}

method list_groups() {

    return $self->get( "/groups?access_token=" . $self->api_key );
}

method rooms_under_group($group_id) {

    return $self->get(
        "/groups/$group_id/rooms?access_token=" . $self->api_key );
}

method rooms( : $q = '' ) {
    return $self->get( "/rooms?access_token=" . $self->api_key . "&q=$q" );
}

method room_from_uri( : $uri ) {
    return $self->post( "/rooms?access_token=" . $self->api_key,
        { uri => $uri } );
}

method join_room( $room_id, $user_id ) {
    return $self->post( "/user/$user_id/rooms?access_token=" . $self->api_key,
        { id => $room_id } );
}

method remove_user_from_room( $room_id, $user_id ) {
    return $self->delete(
        "/rooms/$room_id/users/$user_id?access_token=" . $self->api_key );
}

method update_room( $room_id,
    : $topic   = '',
    : $noindex = 'false',
    : $tags    = '' )
{
    return $self->put(
        "/rooms/$room_id?access_token=" . $self->api_key,
        { topic => $topic, noindex => $noindex, tags => $tags }
    );
}

method delete_room($room_id) {
    return $self->delete( "/rooms/$room_id?access_token=" . $self->api_key );
}

method room_users( $room_id, : $q = '', : $skip = 0, : $limit = 30 ) {
    return $self->get( "/rooms/$room_id/users?access_token="
          . $self->api_key
          . "&skip=$skip"
          . "&limit=$limit" )
      if not $q;

    return $self->get( "/rooms/$room_id/users?access_token="
          . $self->api_key . "&q=$q"
          . "&skip=$skip"
          . "&limit=$limit" )
      if $q;
}

method list_messages(
      $room_id,
    : $skip     = 0,
    : $beforeId = '',
    : $afterId  = '',
    : $aroundId = '',
    : $limit    = 30,
    : $q        = ''
  )
{
    return $self->get( "/rooms/$room_id/chatMessages?access_token="
          . $self->api_key
          . "&skip=$skip"
          . "&beforeId=$beforeId"
          . "&afterId=$afterId"
          . "&aroundId=$aroundId"
          . "&limit=$limit"
          . "&q=$q" );
}

method single_message( $room_id, $message_id ) {
    return $self->get( "/rooms/$room_id/chatMessages/$message_id"
          . "?access_token="
          . $self->api_key );
}

method send_message( $room_id, : $text ) {
    return $self->post(
        "/rooms/$room_id/chatMessages?access_token=" . $self->api_key,
        { text => $text } );
}

method update_message( $room_id, $message_id, : $text ) {
    return $self->put(
        "/rooms/$room_id/chatMessages/$message_id?access_token="
          . $self->api_key,
        { text => $text }
    );
}

method unread_items( $user_id, $room_id ) {
    return $self->get(
        "/user/$user_id/rooms/$room_id/unreadItems?access_token="
          . $self->api_key );
}

method mark_unread_items( $user_id, $room_id, @chat_ids ) {
    return $self->post(
        "/user/$user_id/rooms/$room_id/unreadItems?access_token="
          . $self->api_key,
        { chat => @chat_ids }
    );
}

method orgs($user_id) {
    return $self->get( "/user/$user_id/orgs?access_token=" . $self->api_key );
}

method repos($user_id) {
    return $self->get( "/user/$user_id/repos?access_token=" . $self->api_key );
}

method channels($user_id) {
    return $self->get(
        "/user/$user_id/channels?access_token=" . $self->api_key );
}

1;

=pod

=encoding UTF-8

=head1 NAME

WebService::Gitter - An interface to Gitter REST API via Perl 5.

=head1 VERSION

version 2.2.0

=head1 SYNOPSIS

    use strict;
    use warnings;
    use WebService::Gitter;

    my $git = WebService::Gitter->new(api_key => 'secret');

    # Get current authenticated user.
    $git->get_me;

    # List groups belonging to the authenticated user.
    $git->list_groups;

    # List all rooms belonging to the group/community.
    $git->rooms_under_group($group_id);

    # List all rooms belonging to the searched user.
    $git->rooms(q => $query);

    # List room data via URI.
    $git->room_from_uri(uri => $room_uri);

    # Join a room.
    $git->join_room($room_id, $user_id);

    # Leave/remove user from a room.
    $git->remove_user_from_room($room_id, $user_id);

    # Update room.
    $git->update_room($room_id, topic => $topic, noindex => $noindex, tags => $tags);

    # Delete room.
    $git->delete_room($room_id);

    # List all users in a room.
    $git->room_users($room_id, q => $query, skip => $skip_n, limit => $limit_n);

    # List all messages in a room.
    $git->list_messages($room_id, skip => $skip_n, beforeId => $beforeId,
    afterId => $afterId, aroundId => $aroundId, limit => $limit_n,
    q => $query);

    # Get single message in a room using its message ID.
    $git->single_message($room_id, $message_id);

    # Send message/text to a room.
    $git->send_message($room_id, text => $text);

    # Update message/text in a room.
    $git->update_message($room_id, $message_id, text => $new_text);

    # Retrieve unread items and mentions from a room.
    $git->unread_items($user_id, $room_id);

    # Use to mark chat messages as read.
    $git->mark_unread_items($user_id, $room_id, @chat_ids);

    # List of the user's GitHub Repositories and their respective Room if available.
    $git->orgs($user_id);

    # List of the user's GitHub Repositories and their respective Room if available.
    $git->repos($user_id);

    # List of Gitter channels nested under the current user.
    $git->channels($user_id);

=begin html

<p>
<a href="https://travis-ci.org/faraco/WebService-Gitter">
<img src="https://api.travis-ci.org/faraco/WebService-Gitter.svg?branch=master" alt="Travis status" />
</a>


<a href="https://kritika.io/users/faraco/repos/1212629170881351/heads/master/">
<img src="https://kritika.io/users/faraco/repos/1212629170881351/heads/master/status.svg"/>
</a>
</p>

=end html

=head1 NOTE

This module does not support Faye endpoint and streaming API..yet. Currently as of writing this, the Gitter's API is
 still in beta and likely to break backward compatibility in the future.

=head2 Methods

=over 4

=item C<new(api_key =E<gt> 'your_api_key')>

Description: Set Pixabay API key.

=item C<get_me>

Description: Get current authenticated user.

Returns: Authenticated user data.

=item C<list_groups>

Description: List joined groups by the authenticated user.

Returns: Authenticated user joined groups data.

=item C<rooms_under_group($group_id)>

Description: List all rooms belonging to the group/community.

Parameter: B<REQUIRED> C<$group_id> - Group/community ID.

Returns: All rooms data belonging to the particular community.

=item C<rooms(q =E<gt> $query)>

Description: List all rooms belonging to the searched user.

Parameter: B<OPTIONAL> C<$query> - Search/query string.

Returns: All rooms data belonging to the user.

=item C<room_from_uri(uri =E<gt> $room_uri)>

Description: List room data via URI.

Parameter: B<REQUIRED> C<$room_uri> - Room URI.

Returns: Room from URI response message.

=item C<join_room($room_id, $user_id)>

Description: Join a room.

Parameter: B<REQUIRED> C<$room_id> - Room ID.

Parameter: B<REQUIRED> C<$user_id> - User ID.

Returns: Join room message response.

=item C<remove_user_from_room($room_id, $user_id)>

Description: Remove a user from a room.
This can be self-inflicted to leave the the room and remove room from your left menu.

Parameter: B<REQUIRED> C<$room_id> - Room ID.

Parameter: B<REQUIRED> C<$user_id> - User ID.

Returns: Remove user from a room response message.

=item C<update_room($room_id, topic =E<gt> $topic, noindex =E<gt> $noindex, tags =E<gt> $tags)>

Description: Update room.

Parameter: B<REQUIRED> C<$room_id> - Room ID.

Parameter: B<OPTIONAL> C<$topic> - Room topic.

Parameter: B<OPTIONAL> C<$noindex> - (false, true) Whether the room is indexed by search engines.

Parameter: B<OPTIONAL> C<$tags> - 'tag1, tag2, etc' Tags that define the room.

Returns: Update room response message.

=item C<delete_room($room_id)>

Description: Delete room.

Parameter: B<REQUIRED> C<$room_id> - Room ID.

Returns: Delete room response message.

=item C<room_users($room_id, q =E<gt> $query, skip =E<gt> $skip_n, limit =E<gt> $limit_n)>

Description: List all users in a room.

Note: By default, it will skip 0 and return only 30 users data.

Parameter: B<REQUIRED> C<$room_id> - Room ID.

Parameter: B<OPTIONAL> C<$query> - User's search/query string.

Parameter: B<OPTIONAL> C<$skip_n> - Skip n users.

Parameter: B<OPTIONAL> C<$limit_n> - Set return limit.

Returns: All users data belonging to the room.

=item C<list_messages($room_id, skip =E<gt> $skip_n, beforeId =E<gt> $beforeId,
afterId =E<gt> $afterId, aroundId =E<gt> $aroundId, limit =E<gt> $limit_n,
q =E<gt> $query)>

Description: List all messages in a room.

Note: By default, it will skip 0 and return only 30 users data.

Parameter: B<REQUIRED> C<$room_id> - Room ID.

Parameter: B<OPTIONAL> C<$skip_n> - Skip n messages (constrained to 5000 or less).

Parameter: B<OPTIONAL> C<$beforeId> - Get messages before beforeId.

Parameter: B<OPTIONAL> C<$afterId> - Get messages after afterId.

Parameter: B<OPTIONAL> C<$aroundId> - Get messages after aroundId.

Parameter: B<OPTIONAL> C<$limit_n> - Maximum number of messages to return (constrained to 100 or less).

Parameter: B<OPTIONAL> C<$query> - Search query.

Returns: List of messages in a room.

=item C<single_message($room_id, $message_id)>

Description: Get single message in a room using its message ID.

Parameter: B<REQUIRED> C<$room_id> - Room ID.

Parameter: B<REQUIRED> C<$message_id> - Message ID.

Returns: Retrieve a single message using its ID.

=item C<send_message($room_id, text =E<gt> $text)>

Description: Send message/text to a room.

Parameter: B<REQUIRED> C<$room_id> - Room ID.

Parameter: B<REQUIRED> C<$text> - Text to send.

Returns: Retrieve send message response.

=item C<update_message($room_id, $message_id, text =E<gt> $new_text)>

Description: Update message/text in a room.

Parameter: B<REQUIRED> C<$room_id> - Room ID.

Parameter: B<REQUIRED> C<$message_id> - Message ID.

Parameter: B<REQUIRED> C<$new_text> - Text to replace old message.

Returns: Retrieve update message response.

=item C<unread_items($user_id, $room_id)>

Description: Retrieve unread items and mentions from a room.

Parameter: B<REQUIRED> C<$user_id> - User ID.

Parameter: B<REQUIRED> C<$room_id> - Room ID.

Returns: Unread items response.

=item C<mark_unread_items($user_id, $room_id, @chat_ids)>

Description: Mark chat messages as read.

Parameter: B<REQUIRED> C<$user_id> - User ID.

Parameter: B<REQUIRED> C<$room_id> - Room ID.

Parameter: B<REQUIRED> C<@chat_ids> - List of chat ids to mark as read.

Returns: Marked chat_ids/items response.

=item C<orgs($user_id)>

Description: List of the user's GitHub Repositories and their respective Room if available.

B<Note>: It'll return private repositories if the current user has granted Gitter privileges to access them.

Parameter: B<REQUIRED> C<$user_id> - User ID.

Returns: User's organizations response.

=item C<repos($user_id)>

Description: List of the user's GitHub Repositories and their respective Room if available.

B<Note>: It'll return private repositories if the current user has granted Gitter privileges to access them.

Parameter: B<REQUIRED> C<$user_id> - User ID.

Returns: User's repositories list data response.

=item C<channels($user_id)>

Description: List of Gitter channels nested under the current user.

Parameter: B<REQUIRED> C<$user_id> - User ID.

Returns: User's channel list response.

=back

=head1 SEE ALSO

L<Gitter API documentation|https://developer.gitter.im/docs/welcome>

L<Function::Parameters>

L<WebService::Client>

=head1 AUTHOR

faraco <skelic3@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2018 by faraco.

This is free software, licensed under:

  The MIT (X11) License

=cut

__END__
pod

