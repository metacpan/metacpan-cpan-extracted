use strict;
use warnings;

package WebService::Gitter;

use Moo;
use LWP::UserAgent;
use JSON::MaybeXS;

#ABSTRACT: An interface to Gitter REST API via Perl 5.
our $VERSION = '0.5.2'; # VERSION

# The API/Token key
has token_pass => (
    is       => 'ro',
    required => 1
);

# We set up timeout for 30 seconds.
my $ua = LWP::UserAgent->new;
$ua->timeout(30);
$ua->env_proxy;

# these are for the Gitter api links
my $url_rooms = 'https://api.gitter.im/v1/rooms';
my $url_user  = 'https://api.gitter.im/v1/user';

# This method send a GET request to a server to get authentication data as the authenticated user.
sub current_user {
    my $self = shift;

    my $req = $ua->get( "$url_user/me?access_token=" . $self->token_pass );

    if ( $req->is_success ) {
        decode_json $req->decoded_content;

    }

    else {
        die $req->status_line;
    }

}

# List users in the room
sub room_users {
    my ( $self, $id ) = @_;
    my $req =
      $ua->get( $url_user . "/$id/rooms?access_token=" . $self->token_pass );

    if ( $req->is_success ) {
        decode_json $req->decoded_content;
    }

    else {
        die $req->status_line;
    }
}

# List user (you) joined rooms. 
sub rooms {
    my $self = shift;

    my $req = $ua->get( "$url_rooms?access_token=" . $self->token_pass );

    if ( $req->is_success ) {
        decode_json $req->decoded_content;

    }

    else {
        die $req->status_line;
    }
}

# Return room ID by passing room name/room uri
sub room_id {
    my ( $self, $uri ) = @_;

    my $req = HTTP::Request->new( POST => $url_rooms );
    $req->header( 'Content-Type'  => 'application/json' );
    $req->header( 'Accept'        => 'application/json' );
    $req->header( 'Authorization' => 'Bearer ' . $self->token_pass );
    $req->content( encode_json( { uri => $uri } ) );

    my $resp = $ua->request($req);

    if ( $resp->is_success ) {
        decode_json $resp->decoded_content;
    }

    else {
        print 'HTTP POST error code: ' . $resp->code . "\n";
        print 'HTTP POST error message: ' . $resp->message . "\n";
    }
}


# Send message to the room id
sub send_message {
    my ( $self, $message, $room_id ) = @_;

    my $req = HTTP::Request->new( POST => "$url_rooms/$room_id/chatMessages" );
    $req->header( 'Content-Type'  => 'application/json' );
    $req->header( 'Accept'        => 'application/json' );
    $req->header( 'Authorization' => 'Bearer ' . $self->token_pass );
    $req->content( encode_json( { text => $message } ) );

    my $resp = $ua->request($req);

    if ( $resp->is_success ) {
        decode_json $resp->decoded_content;
    }

    else {
        print 'HTTP error code: ' . $resp->code . "\n";
        print 'HTTP error message: ' . $resp->message . "\n";
    }
}

# List all messages in the room you on (via name/uri). You can set the returned messages limit for the room you chose.
# By default, the messages limit are 5.
sub messages {
    my ( $self, $room_id, $limit ) = @_;

    $limit = 5 if not defined $limit;

    my $req =
      HTTP::Request->new(
        GET => "$url_rooms/$room_id/chatMessages?limit=$limit" );
    $req->header( 'Accept'        => 'application/json' );
    $req->header( 'Authorization' => 'Bearer ' . $self->token_pass );

    my $resp = $ua->request($req);

    if ( $resp->is_success ) {
        decode_json $resp->decoded_content;

    }

    else {
        die $resp->status_line;
    }
}

=pod

=encoding UTF-8

=head1 NAME

WebService::Gitter - An interface to Gitter REST API via Perl 5.

=head1 VERSION

version 0.5.2

=head1 SYNOPSIS

	use WebService::Gitter;
	
	my $client = WebService::Gitter->new(token_pass => 'my_api_or_token_key');
	
	$client->current_user;
	$client->rooms;
	$client->room_id('gitterHQ/nodejs');
	$client->room_users('the_user_id');
	$client->send_message('my_text', 'room_id');
	$client->messages('room_id', limit_messages_in_number);

=head1 DESCRIPTION

An interface to Gitter REST API (v1). The methods will return a parsed L<JSON> into hash.. That is up to your freedom on specifically accessing each element in the hash.

To access specific element in the JSON hash, for example:

	$client->current_user->{'id'};

I<B<NOTE>> You need to include 'I<B<use Data::Dumper>>' in your script to print the whole hash map. 

=head1 METHODS

=head2 new(token_pass => $api_key)

You need to be registered at Gitter to get an api key. Take a look at L<https://developer.gitter.im/login> for further information.

=head2 current_user

This will return the authenticated user (you) info in decoded JSON. To see the response data, you can:

    print Dumper $obj->current_user

and it will print the returned HASH map.

=head2 rooms

This will return the joined rooms by authenticated user (you) info in JSON through HASH.
To see the response data, you can:

    print Dumper $obj->rooms;

and it will print the returned HASH map.

=head2 room_id($room_name)

I<$room_name> arguments is the room name, eg I<B<FreecodeCamp/FreeCodeCamp>>.

This method will return the room ID of the specified room name in JSON through HASH.
To see the response data, you can:

    print Dumper $obj->room_id($room_uri);

and it will print the returned HASH map.

=head2 room_users($room_id)

I<$room_id> is the room ID. You can get this by running the L</room_id($room_uri)> method.

This method will return the users in the specified room in JSON through HASH. To see the response data, you can:

    print Dumper $obj->room_users($room_id);

and it will print the returned HASH map.

=head2 send_message($text, $room_id)

I<$text> is your text message, eg I<B<'HI!'>>. I<$room_id> is the room ID you want to send message to. You can get the room ID by running:

    print Dumper $obj->room_id($room_name/uri);

This method will send the message to the specified room through the room ID. To see the response data, you can:

    print Dumper $obj->send_message($text, $room_id);

and it will print the returned HASH map.

=head2 messages($room_id, $limit_number)

I<$room_id> is your room targeted room ID. To find the room ID, you can run:

    print Dumper $obj->room_id($room_name);

The I<$limit_number> is your total messages to be retrieved.

This method will retrieve messages from targeted room. To see the respose data, you can run:

    print Dumper $obj->messages($room_id, $limit_number);

=head1 SEE ALSO

L<LWP::UserAgent>

L<Data::Dumper>

L<JSON::MaybeXS>

L<Gitter API Wiki for developer page|https://developer.gitter.im/docs/welcome>

=head1 AUTHOR

faraco <skelic3@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by faraco.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


1;
