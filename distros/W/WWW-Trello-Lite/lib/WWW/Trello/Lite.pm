=pod

=head1 NAME

WWW::Trello::Lite - Simple wrapper around the Trello web service.

=head1 SYNOPSIS

  # Get the currently open lists from a given board...
  my $trello = WWW::Trello::Lite->new(
      key   => 'invalidkey',
      token => 'invalidtoken'
  );
  my $lists = $trello->get( "boards/$id/lists" )

  # Add a new card...
  $trello->post( "cards", {name => 'New card', idList => $id} );

=head1 DESCRIPTION

L<Trello|https://www.trello.com> manages lists of I<stuff>.
L<Trello|https://www.trello.com> provides an API for remote control.
B<WWW::Trello::Lite> provides Perl scripts easy access to the API. I use it
to add cards on my to-do list.

Translating the Trello API documentation into functional calls is straight
forward.

  # Trello API documentation says:
  # GET /1/cards/[card_id]
  my $card = $trello->get( "cards/$id" );

The first word (I<GET>, I<POST>, I<PUT>, I<DELETE>) becomes the method call.
Ignore the number. That is the Trello API version number. B<WWW::Trello::Lite>
handles that for you automatically.

The rest of the API URL slides into the first parameter of the method.

Some API calls, such as this one, also accept B<Arguments>. Pass the arguments
as a hash reference in the second parameter. The argument name is a key. And
the argument value is the value.

  # Trello API documentation says:
  # GET /1/cards/[card_id]
  my $card = $trello->get( "cards/$id", {attachments => 'true'} );

=cut

package WWW::Trello::Lite;
use strict;
use warnings;

use Moose;
with 'Role::REST::Client';

use 5.008;
our $VERSION = '1.00';

use URI::Escape;


=head1 METHODS & ATTRIBUTES

=head3 get / delete / post / put

The method name corresponds with the first word in the Trello API
documentation. It tells Trello what you are trying to do. Each method expects
two parameters:

=over

=item 1. URL

The URL (minus the server name) for the API call. You can also leave off the
version number. Begin with the item such as I<boards> or I<cards>.

=item 2. arguments

An optional hash reference of arguments for the API call. The class
automatically adds your development key and token. It is not necessary to
include them in the arguments.

=back

See the corresponding method in L<Role::REST::Client> for information about the
return value.

=cut

around qw/get delete put post/ => sub {
	my ($original, $self, $url, $arguments, @the_rest) = @_;

	$arguments = {} unless defined $arguments;
	$arguments->{key  } = $self->key;
	$arguments->{token} = $self->token;

	# Only "$api" is part of the URL. The token and key are escaped by the REST
	# function when it builds the full URL.
	my $api = uri_escape( $self->version );

	return $self->$original( "$api/$url", $arguments, @the_rest );
};


=head3 key

This attribute accepts your L<Trello|https://www.trello.com> developer key.
L<Trello|https://www.trello.com> requires that all users of the API have a
unique key. Please refer to the L<Trello|https://www.trello.com> API
documentation to obtain a key.

=cut

has 'key' => (
	is  => 'rw',
	isa => 'Str',
);


=head3 server

This attribute holds the URL to the L<Trello|https://www.trello.com> web
server. The class sets this for you. You can read the value from this attribute
if your code wants to know the URL for some reason.

=cut

has '+server' => (
	default  => 'https://api.trello.com/',
);


=head3 token

This attribute holds the L<Trello|https://www.trello.com> authorization token.
The authorization token tells L<Trello|https://www.trello.com> that this script
can modify your boards and lists.

For example, I use these scripts in C<cron> jobs. So I generate a forever token
once, then code it into the script.

=cut

has 'token' => (
	is  => 'rw',
	isa => 'Str',
);


=head3 version

This attribute tells L<Trello|https://www.trello.com> that we are using version
1 of the API. L<Trello|https://www.trello.com> supports API changes by
including the version number in each request. Currently there is only one
version. This atribute lets the object handle future versions without any code
changes.

You may pass the version to the constructor, if the default value of B<1> does
not meet your needs.

=cut

has 'version' => (
	default => 1,
	is      => 'rw',
	isa     => 'Int',
);


=head1 BUGS/CAVEATS/etc

B<WWW::Trello::Lite> is not associated with L<Trello|https://www.trello.com>
or L<Fog Creek Software|http://www.fogcreek.com/> in any way.

B<WWW::Trello::Lite> is a very simplistic wrapper around the Trello API. It
provides no validity checks and does not create nice objects for each item. You
get the raw data as decoded from JSON.

=head1 AUTHOR

Robert Wohlfarth <rbwohlfarth@gmail.com>

=head1 SEE ALSO

L<Role::REST::Client>, L<Role::REST::Client::Response>

=head1 LICENSE

Copyright 2013  Robert Wohlfarth

You can redistribute and/or modify this module under the same terms as Perl
itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

1;
