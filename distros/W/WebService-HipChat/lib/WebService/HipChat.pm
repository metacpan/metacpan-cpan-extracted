package WebService::HipChat;
use Moo;
with 'WebService::Client';

our $VERSION = '0.2001'; # VERSION

use Carp qw(croak);
use MIME::Entity;
use JSON qw(encode_json);

has auth_token => ( is => 'ro', required => 1 );

has '+base_url' => ( default => 'https://api.hipchat.com/v2' );

sub BUILD {
    my ($self) = @_;
    $self->ua->default_header(Authorization => "Bearer " . $self->auth_token);
}

sub get_rooms {
    my ($self, %args) = @_;
    return $self->get("/room", $args{query} || {});
}

sub get_room {
    my ($self, $room) = @_;
    croak '$room is required' unless $room;
    return $self->get("/room/$room");
}

sub create_room {
    my ($self, $data) = @_;
    croak '$data is required' unless 'HASH' eq ref $data;
    return $self->post("/room", $data);
}

sub update_room {
    my ($self, $room, $data) = @_;
    croak '$room is required' unless $room;
    croak '$data is required' unless 'HASH' eq ref $data;
    return $self->put("/room/$room", $data);
}

sub set_topic {
    my ($self, $room, $topic) = @_;
    croak '$room is required' unless $room;
    croak '$topic is required' unless $topic;
    if ( 'HASH' eq ref $topic ) {
        $topic = $topic->{topic} or croak '$topic is required';
    }
    return $self->put("/room/$room/topic", { topic => $topic });
}

sub delete_room {
    my ($self, $room) = @_;
    croak '$room is required' unless $room;
    return $self->delete("/room/$room");
}

sub send_notification {
    my ($self, $room, $data) = @_;
    croak '$room is required' unless $room;
    croak '$data is required' unless 'HASH' eq ref $data;
    return $self->post("/room/$room/notification", $data);
}

sub get_webhooks {
    my ($self, $room, %args) = @_;
    croak '$room is required' unless $room;
    return $self->get("/room/$room/webhook", $args{query} || {});
}

sub get_webhook {
    my ($self, $room, $webhook_id) = @_;
    croak '$room is required' unless $room;
    croak '$webhook_id is required' unless $webhook_id;
    return $self->get("/room/$room/webhook/$webhook_id")
}

sub create_webhook {
    my ($self, $room, $data) = @_;
    croak '$room is required' unless $room;
    croak '$data is required' unless 'HASH' eq ref $data;
    return $self->post("/room/$room/webhook", $data);
}

sub delete_webhook {
    my ($self, $room, $webhook_id) = @_;
    croak '$room is required' unless $room;
    croak '$webhook_id is required' unless $webhook_id;
    return $self->delete("/room/$room/webhook/$webhook_id");
}

sub get_members {
    my ($self, $room, %args) = @_;
    croak '$room is required' unless $room;
    return $self->get("/room/$room/member", $args{query} || {});
}

sub add_member {
    my ($self, $room, $user) = @_;
    croak '$room is required' unless $room;
    croak '$user is required' unless $user;
    return $self->put("/room/$room/member/$user", {});
}

sub remove_member {
    my ($self, $room, $user) = @_;
    croak '$room is required' unless $room;
    croak '$user is required' unless $user;
    return $self->delete("/room/$room/member/$user");
}

sub get_users {
    my ($self, %args) = @_;
    return $self->get("/user", $args{query} || {});
}

sub get_user {
    my ($self, $user) = @_;
    croak '$user is required' unless $user;
    return $self->get("/user/$user");
}

sub delete_user {
    my ($self, $user) = @_;
    croak '$user is required' unless $user;
    return $self->delete("/user/$user");
}

sub send_private_msg {
    my ($self, $user, $data) = @_;
    croak '$user is required' unless $user;
    croak '$data is required' unless 'HASH' eq ref $data;
    return $self->post("/user/$user/message", $data);
}

sub send_room_msg {
    my ($self, $room, $data) = @_;
    croak '$room is required' unless $room;
    croak '$data is required' unless 'HASH' eq ref $data;
    return $self->post("/room/$room/message", $data);
}

sub get_private_history {
    my ($self, $user, %args) = @_;
    croak '$user is required' unless $user;
    return $self->get("/user/$user/history", $args{query} || {});
}

sub get_emoticons {
    my ($self, %args) = @_;
    return $self->get("/emoticon", $args{query} || {});
}

sub get_emoticon {
    my ($self, $emoticon) = @_;
    croak '$emoticon is required' unless $emoticon;
    return $self->get("/emoticon/$emoticon");
}

sub get_room_history {
    my ($self, $room, %args) = @_;
    croak '$room is required' unless $room;
    return $self->get("/room/$room/history/latest", $args{query} || {});
}

sub share_link {
    my ($self, $room, $data) = @_;
    croak '$room is required' unless $room;
    croak '$data is required' unless 'HASH' eq ref $data;
    return $self->post("/room/$room/share/link", $data);
}

sub next {
    my ($self, $data) = @_;
    croak '$data is required' unless 'HASH' eq ref $data;
    my $next = $data->{links}{next} or return undef;
    return $self->get($next);
}

sub share_file {
    my ($self, $destination, $data) = @_;
    croak '$destination is required' unless $destination;
    croak '$data is required' unless 'HASH' eq ref $data;

    # Users may be referenced by '@' name OR email address per
    # https://www.hipchat.com/docs/apiv2/method/share_file_with_user
    my $api_type  = ( $destination =~ /\@/ ) ? 'user' : 'room';
    my $msg       = $data->{message};
    my $file      = $data->{file};

    if (! -f $file) {
        warn "File '$file' doesn't exist\n";
        return;
    }

    my $boundary = 'boundary1234567890';

    my $Mime = MIME::Entity->build(
        Type     => 'multipart/related',
        Boundary => $boundary,
    );

    if ( $msg ) {
        my $msg_json = encode_json({ message => $msg });
        $Mime->attach(
            Type     => 'application/json',
            Encoding => '7bit',
            Data     => $msg_json,
        );
    }

    $Mime->attach(
        Path        => $file,
        Disposition => 'attachment; name="file"'
    );

    $Mime->make_multipart();

    return $self->post("/$api_type/$destination/share/file",
        $Mime->stringify_body(),
        headers => {
            'content_type' => "multipart/related; boundary=\"$boundary\"",
        },
    );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::HipChat

=head1 VERSION

version 0.2001

=head1 SYNOPSIS

    my $hc = WebService::HipChat->new(auth_token => 'abc');
    $hc->send_notification('Room42', { color => 'green', message => 'allo' });

    # get paged results:
    my $res = $hc->get_emoticons;
    my @emoticons = @{ $res->{items} };
    while ($res = $hc->next($res)) {
        push @emoticons, @{ $res->{items} };
    }

=head1 DESCRIPTION

This module provides bindings for the
L<HipChat API v2|https://www.hipchat.com/docs/apiv2>.
It also provides the command line utility L<hipchat-send>.

=head1 METHODS

All methods return a hashref.
The C<$room> param can be the id or name of the room.
The C<$user> param can be the id, email address, or @mention name of the user.
If a resource does not exist for the given parameters, undef is returned.

=head2 get_rooms

    get_rooms()
    get_rooms(query => { 'start-index' => 0, 'max-results' => 100 });

Example response:

    {
      items => [
        {
          id => 2,
          links => {
            self => "https://hipchat.com/v2/room/2",
            webhooks => "https://hipchat.com/v2/room/2/webhook",
          },
          name => "General Discussion",
        },
        {
          id => 3,
          links => {
            self => "https://hipchat.com/v2/room/3",
            webhooks => "https://hipchat.com/v2/room/3/webhook",
          },
          name => "Important Stuff",
        },
      links => { self => "https://hipchat.com/v2/room" },
      maxResults => 100,
      startIndex => 0,
    }

=head2 get_room

    get_room($room)

Example response:

    {
      created => "2014-06-25T02:28:04",
      guest_access_url => undef,
      id => 2,
      is_archived => 0,
      is_guest_accessible 0,
      last_active => "2014-07-19T02:40:55+00:00",
      links => {
        self => "https://hipchat.com/v2/room/2",
        webhooks => "https://hipchat.com/v2/room/2/webhook",
      },
      name => "General Discussion",
      owner => {
        id => 1,
        links => { self => "https://hipchat.com/v2/user/1" },
        mention_name => "bob",
        name => "Bob Williams",
      },
      participants => [],
      privacy => "public",
      statistics => {
        links => { self => "https://hipchat.com/v2/room/2/statistics" },
      },
      topic => "hipchat commands",
      xmpp_jid => "1_general_discussion\@conf.btf.hipchat.com",
    }

=head2 create_room

    create_room({ name => 'monkeys' })

Example response:

    {
      id => 46,
      links => { self => "https://hipchat.com/v2/room/46" },
    }

=head2 update_room

    update_room($room, {
        is_archived         => JSON::false,
        is_guest_accessible => JSON::false,
        name                => "Jokes",
        owner               => { id => 17 },
        privacy             => "public",
        topic               => "funny jokes",
    });

=head2 set_topic

    set_topic($room, 'new topic');

=head2 delete_room

    delete_room($room)

=head2 send_notification

    send_notification($room, { color => 'green', message => 'allo' });

=head2 get_webhooks

    get_webhooks($room)
    get_webhooks($room, query => { 'start-index' => 0, 'max-results' => 100 });

Example response:

    {
      items => [
        {
          event => "room_message",
          id => 1,
          links => { self => "https://hipchat.com/v2/room/API/webhook/1" },
          name => "hook1",
          pattern => undef,
          url => "http://yourdomain.org/hipchat-webhook",
        },
      ],
      links => { self => "https://hipchat.com/v2/room/API/webhook" },
      maxResults => 100,
      startIndex => 0,
    }

=head2 get_webhook

    get_webhook($room, $webhook_id);

=head2 create_webhook

    create_webhook($room, {
        url   => 'http://yourdomain.org/hipchat-webhook'
        event => 'room_message',
        name  => 'hook1',
    });

=head2 delete_webhook

    delete_webhook($room, $webhook_id);

=head2 send_private_msg

    send_private_msg($user, { message => 'allo' });

=head2 send_room_msg

    send_room_msg($room, { message => 'allo' });

=head2 get_private_history

    $hc->get_private_history($user)
    $hc->get_private_history($user, query => { 'max-results' => 5 });

Example response:

   {
    items        [
        [0] {
            date       "2014-11-13T10:48:33.322506+00:00",
            from       {
                id             123456,
                links          {
                    self   "https://api.hipchat.com/v2/user/123456"
                },
                mention_name   "Bob",
                name           "Bob Williams"
            },
            id         "38988c8c-9120-44ce-87c5-6731a7a3b6",
            mentions   [],
            message    "heres a message and a link http://www.sun.com/",
            type       "message"
        },
        [1] {
            date       "2014-11-13T10:49:02.377436+00:00",
            from       {
                id             123456,
                links          {
                    self   "https://api.hipchat.com/v2/user/123456"
                },
                mention_name   "Bob",
                name           "Bob Williams"
            },
            id         "c1f47537-6506-4f46-b820-eaade5adc5",
            mentions   [],
            message    "A message",
            type       "message"
        }
    ],
    links        {
        self   "https://api.hipchat.com/v2/user/123456/history"
    },
    maxResults   5,
    startIndex   0
   }

=head2 get_members

    get_members($room);
    get_members($room, query => { 'start-index' => 0, 'max-results' => 100 });

Example response:

    {
      items => [
        {
          id => 73,
          links => { self => "https://hipchat.com/v2/user/73" },
          mention_name => "momma",
          name => "Yo Momma",
        },
        {
          id => 23,
          links => { self => "https://hipchat.com/v2/user/23" },
          mention_name => "jackie",
          name => "Jackie Chan",
        },
      ],
      links => { self => "https://hipchat.com/v2/room/Test/member" },
      maxResults => 100,
      startIndex => 0,
    }

=head2 add_member

Adds a user to a room.

    add_member($room, $user);

=head2 remove_member

Removes a user from a room.

    remove_member($room, $user);

=head2 get_users

    get_users()
    get_users(query => { 'start-index' => 0, 'max-results' => 100 });

Example response:

    {
      items => [
        {
          id => 1,
          links => { self => "https://hipchat.com/v2/user/1" },
          mention_name => "magoo",
          name => "Matt Wondercookie",
        },
        {
          id => 3,
          links => { self => "https://hipchat.com/v2/user/3" },
          mention_name => "racer",
          name => "Brian Wilson",
        },
      ],
      links => { self => "https://hipchat.com/v2/user" },
      maxResults => 100,
      startIndex => 0,
    }

=head2 get_user

    get_user($user)

Example response:

    {
      created        => "2014-06-20T03:00:28",
      email          => 'matt@foo.com',
      group          => {
                          id => 1,
                          links => { self => "https://hipchat.com/v2/group/1" },
                          name => "Everyone",
                        },
      id             => 1,
      is_deleted     => 0,
      is_group_admin => 1,
      is_guest       => 0,
      last_active    => 1405718128,
      links          => { self => "https://hipchat.com/v2/user/1" },
      mention_name   => "magoo",
      name           => "Matt Wondercookie",
      photo_url      => "https://hipchat.com/files/photos/1/abc.jpg",
      presence       => {
                          client => {
                            type => "http://hipchat.com/client/linux",
                            version => 98,
                          },
                          idle => 3853,
                          is_online => 1,
                          show => "away",
                        },
      timezone       => "America/New_York",
      title          => "Hacker",
      xmpp_jid       => '1_1@chat.hipchat.com',
    }

=head2 delete_user

    delete_user($user)

=head2 get_emoticons

    get_emoticons()
    get_emoticons(query => { 'start-index' => 0, 'max-results' => 100 });

Example response:

    {
      items => [
        {
          id => 166,
          links => { self => "https://hipchat.com/v2/emoticon/166" },
          shortcut => "dog",
          url => "https://hipchat.com/files/img/emoticons/1/dog.png",
        },
      ],
      links => { self => "https://hipchat.com/v2/emoticon" },
      maxResults => 100,
      startIndex => 0,
    }

=head2 get_emoticon

    get_emoticon()

Example response:

    {
      creator => {
        id => 11,
        links => { self => "https://hipchat.com/v2/user/11" },
        mention_name => "bob",
        name => "Bob Ray",
      },
      height => 30,
      id => 203,
      links => { self => "https://hipchat.com/v2/emoticon/203" },
      shortcut => "dog",
      url => "https://hipchat.com/files/img/emoticons/1/dog.png",
      width => 30,
    }

=head2 get_room_history

    $hc->get_room_history($room)
    $hc->get_room_history($room, { 'max-results' => 5 });

Example response:

   {
    items        [
        [0] {
            date       "2014-11-13T10:48:33.322506+00:00",
            from       {
                id             123456,
                links          {
                    self   "https://api.hipchat.com/v2/user/123456"
                },
                mention_name   "Bob",
                name           "Bob Williams"
            },
            id         "38988c8c-9120-44ce-87c5-6731a7a3b6",
            mentions   [],
            message    "heres a message and a link http://www.sun.com/",
            type       "message"
        },
        [1] {
            date       "2014-11-13T10:49:02.377436+00:00",
            from       {
                id             123456,
                links          {
                    self   "https://api.hipchat.com/v2/user/123456"
                },
                mention_name   "Bob",
                name           "Bob Williams"
            },
            id         "c1f47537-6506-4f46-b820-eaade5adc5",
            mentions   [],
            message    "A message",
            type       "message"
        }
    ],
    links        {
        self   "https://api.hipchat.com/v2/room/XXX/history/latest"
    },
    maxResults   2,
    startIndex   0
   }

=head2 share_link

    $hc->share_link($room, { message => 'msg', link => 'http://www.sun.com' });

=head2 share_file

    $hc->share_file($destination, { message => 'msg', file => '/tmp/file.png' });

Shares files with $destination, whether that be a room OR a user. If sent to a user, make sure it is their '@' name OR email address. Otherwise we'll think it is a room.
For example: '@JohnQPublic' OR 'johnq@public.test instead of 'SomeRoom'

=head2 next

    next($data)

Returns the next page of data for paginated responses.

Example:

    my $res = $hc->get_emoticons;
    my @emoticons = @{ $res->{items} };
    while ($res = $hc->next($res)) {
        push @emoticons, @{ $res->{items} };
    }

=head1 CONTRIBUTORS

=over

=item *

Andy Baugh <L<https://github.com/troglodyne>>

=item *

Chris C. <L<https://github.com/centreti>>

=item *

Chris Hughes <L<https://github.com/chrisspang>>

=item *

Ken-ichi Mito <L<https://github.com/mittyorz>>

=item *

Tim Man <L<https://github.com/teebszet>>

=back

=head1 AUTHOR

Naveed Massjouni <naveed@vt.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Naveed Massjouni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
