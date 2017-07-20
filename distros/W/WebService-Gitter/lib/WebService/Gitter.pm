package WebService::Gitter;
use strict;
use warnings;
use v5.10;
use Moo;
use Function::Parameters;
use Data::Dumper 'Dumper';

with 'WebService::Client';
#ABSTRACT: An interface to Gitter REST API via Perl 5.
our $VERSION = '1.1.0'; # VERSION

# token_key
has api_key => (
    is       => 'ro',
    required => 1
);

has '+base_url' => (
	default => 'https://api.gitter.im/v1'
);

# user resources

# get current logged in user
method me() {
    return $self->get("/user/me?access_token=" . $self->api_key);
}

# show data structure of the method that returns JSON
method show_dst($method_name) {
    print Dumper $method_name;
}

# groups resources
# list user's groups
method groups() {
	return $self->get("/groups?access_token=" . $self->api_key);
}

method rooms_under_group($group_id) {
	return $self->get("/groups/$group_id/rooms?access_token=" . $self->api_key);
}

# rooms resources
# list user's rooms
method rooms($q = "") {	
	# if empty
	if (!$q) {
		return $self->get("/rooms?access_token=" . $self->api_key);
	}

	return $self->get("/rooms?access_token="
		. $self->api_key
		. "&q="
		. $q);
}

# TODO add optional parameters
method room_users($room_id) {
	return $self->get("/rooms/$room_id/users?access_token=" . $self->api_key
	);
}

# messages resource
# list all message in the room
method list_messages($room_id) {
	return $self->get("/rooms/$room_id/chatMessages?access_token=" . $self->api_key);;
}

method single_message($room_id, $message_id) {
	return $self->get("/rooms/$room_id/chatMessages/$message_id"
		. "?access_token="
		. $self->api_key);
}

method send_message($room_id, $text) {
	return $self->post("/rooms/$room_id/chatMessages?access_token=" . $self->api_key, { text => $text });
}

1;

=pod

=encoding UTF-8

=head1 NAME

WebService::Gitter - An interface to Gitter REST API via Perl 5.

=head1 VERSION

version 1.1.0

=head1 SYNOPSIS

	use strict;
	use warnings;
	use WebService::Gitter;

	my $git = WebService::Gitter->new(api_key => 'secret');

    # user methods
	# get current logged in user
	$git->me();

	# show data structure
	$git->show_dst($method_name);
	
	# group methods
	# list groups
	$git->groups();

	# list rooms under group
	$git->rooms_under_group();

	# room methods	
	# list rooms
	$git->rooms();

	# list all users in the room
	$git->room_users($room_id);

	# messages methods
	# list all messages in the room
	$git->list_messages($room_id);

	# get single message from message id
	$git->single_message($room_id, $message_id);

	# send message to a room/channel
	$git->send_message($room_id, $text_to_send);

=head1 SEE ALSO

L<Gitter API documentation|https://developer.gitter.im/docs/welcome>

=head1 AUTHOR

faraco <skelic3@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by faraco.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
pod

