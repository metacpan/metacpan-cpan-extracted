package WWW::Challonge;
use WWW::Challonge::Tournament;
use LWP::UserAgent;
use Carp qw/carp croak/;
use JSON qw/to_json from_json/;

use 5.010;
use strict;
use warnings;

sub __handle_error;
sub __json_request;

=head1 NAME

WWW::Challonge - Perl wrapper for the Challonge API

=head1 VERSION

Version 1.01

=cut

our $VERSION = '1.01';
our $HOST = "https://api.challonge.com/v1";

=head1 SYNOPSIS

Access the Challonge API within Perl. Contains all the functions within the API,
as documented L<here|http:://api.challonge.com/v1>.

    use WWW::Challonge;

    my $c = WWW::Challonge->new($api_key)
    ...

=head1 SUBROUTINES/METHODS

=head2 new

Creates a new C<WWW::Challonge> object. Takes in an API key, which is required,
and optionally a preconfigured L<LWP::UserAgent> object, which is mostly used for
testing.

    my $c  = WWW::Challonge->new($api_key);
	my $c2 = WWW::Challonge->new({ key => $api_key, client => $my_client });

=cut

sub new
{
	# Get the arguments:
	my $class = shift;
	my $args = shift;

	my $key;
	my $client;

	# If the argument is a scalar, use it as the API key:
	if((! ref $args) && (defined $args))
	{
		$key = $args;

		# Create an LWP useragent to interface Challonge:
		$client = LWP::UserAgent->new;
	}
	elsif(ref $args eq "HASH")
	{
		croak "'client' must be a LWP::UserAgent object"
			unless((defined $args->{client}) &&
			(UNIVERSAL::isa($args->{client}, "LWP::UserAgent")));

		$client = $args->{client};
		$key = $args->{key} // "";
	}
	else
	{
		croak "Expected scalar or hashref";
	}

	# Try to get some content and check the response code:
	my $response = $client->get("$HOST/tournaments.json?api_key=$key");

	# Check for any errors:
	WWW::Challonge::__handle_error $response if($response->is_error);

	# Create and return the object:
	my $c = { key => $key, client => $client };
	bless $c, $class;
}

=head2 tournaments

Returns an arrayref of all C<WWW::Challonge::Tournament> objects owned by the
user authenticated with in the 'new' request (the logged in user, so to speak).
Takes a number of optional arguments: 

=over 4

=item state

Get tournaments based on their progress:

=over 4

=item all

Gets all tournaments regardless of state.

=item pending

Gets all tournaments that have yet to start.

=item in_progress

Gets all tournaments that have started but have not finished.

=item ended

Gets all tournaments that have finished.

=back

=item type

Gets all tournaments of the given type:

=over 4

=item single_elimination

=item double_elimination

=item round_robin

=item swiss

=back

=item created_after

Gets all the tournaments created after the given date. Can be given as an
ISO8601 date string or as a L<DateTime> object.

=item created_before

Gets all the tournaments created before the given date. Can be given as an
ISO8601 string or as a L<DateTime> object.

=item subdomain

Gets all tournaments created under the given subdomian.

=back

	my $tournies  = $c->tournaments;
	my $tournies2 = $c->tournaments({
		type => "double_elimination",
		created_after => "2015-03-18",
	});

=cut

sub tournaments
{
	my $self = shift;
	my $options = shift // {};

	# Get the key and the client:
	my $key = $self->{key};
	my $client = $self->{client};

	# The intial request URL:
	my $req = "$HOST/tournaments.json?api_key=$key";

	# Loop through the options (if any) and add them on:
	for my $option(keys %{$options})
	{
		# Validate the input:
		if($option =~ /^state$/)
		{
			if($options->{$option} !~ /^all|pending|in_progress|ended$/)
			{
				croak "Argument '" . $options->{$option} .
					"' for option '$option' is invalid";
			}
		}
		elsif($option =~ /^type$/)
		{
			if($options->{$option} !~ /^(single|double)_elimination|round_robin|swiss$/)
			{
				croak "Argument '" . $options->{$option} .
					"' for option '$option' is invalid";
			}
		}
		elsif($option =~ /^created_(before|after)$/)
		{
			if($options->{$option} !~ /^\d{4}-\d{2}-\d{2}$/)
			{
				croak "Argument '" . $options->{$option} .
					"' for option '$option' is invalid";
			}
		}
		elsif($option =~ /^subdomain$/)
		{
			if($options->{$option} !~ /^[a-zA-Z0-9_]*$/)
			{
				croak "Argument '" . $options->{$option} .
					"' for option '$option' is invalid";
			}
		}
		else
		{
			carp "Unknown option '$option'";
			return undef;
		}

		$req .= "&" . $option . "=" . $options->{$option};
	}

	# Make the request:
	my $response = $client->get($req);

	# Check for any errors:
	WWW::Challonge::__handle_error $response if($response->is_error);

	# Make a new tournament object for every tourney returned:
	my @tournaments;
	for my $tournament(@{from_json($response->decoded_content)})
	{
		push @tournaments, WWW::Challonge::Tournament->new($tournament,
			$key, $client);
	}

	# Return the array of tournaments:
	return \@tournaments;
}

=head2 tournament

Gets a single C<WWW::Challonge::Tournament> object by the given id or URL:

	my $tourney = $c->tournament("sample_tournament_1");

If the tournament has a subdomain (e.g. test.challonge.com/mytourney), simply
specify like so:

	my $tourney = $c->tournament("test-mytourney")

=cut

sub tournament
{
	my $self = shift;
	my $url = shift;

	# Give an error if no tournament is given:
	croak "No tournament specified" unless(defined $url);

	# Get the key and client:
	my $key = $self->{key};
	my $client = $self->{client};

	# Try to get the tournament:
	my $response = $client->get("$HOST/tournaments/$url.json?api_key=$key");

	# Check for any errors:
	WWW::Challonge::__handle_error $response if($response->is_error);

	# Otherwise create a tourney with the object and return it:
	my $tourney = WWW::Challonge::Tournament->new(
		from_json($response->decoded_content), $key, $client);
	return $tourney;
}

=head2 new_tournament

Creates a new tournament, and returns it as a C<WWW::Challonge::Tournament>
object. It takes an hashref of arguments. The name and URL are required, all
others are optional.

=over 4

=item name

A string containing the name of the tournament.

=item tournament_type

A string containing one of the following, detailing the type of tournament.

=over 4

=item single elimination (default)

=item double elimination

=item round robin

=item swiss

=back

=item url

The url of the tournament, containing only letters, numbers and underscores.

=item subdomain

The subdomain of the tournament (requires write access to the given subdomain).

=item description

The description of the tournament to be displayed above the bracket.

=item game_name

The name of the game or sport being played.

=item open_signup

True/false. Have Challonge host a sign-up page (otherwise, manually add
participants).

=item hold_third_place_match

True/false. Single elimination only. Hold a match for semifinals losers to
determine third place? Default is false.

=item pts_for_match_win

Decimal (to the nearest tenth). Number of points gained on winning a match.
Swiss only. Default is 1.0.

=item pts_for_match_tie

Decimal (to the nearest tenth). Number of points gained on drawing a match.
Swiss only. Default is 0.5.

=item pts_for_game_win

Decimal (to the nearest tenth). Number of points gained on winning a single
game within a match. Swiss only. Default is 0.0.

=item pts_for_game_tie

Decimal (to the nearest tenth). Number of points gained on drawing a single
game within a match. Swiss only. Default is 0.0.

=item pts_for_bye

Decimal (to the nearest tenth). Number of points gained on getting a bye.
Swiss only. Default is 1.0.

=item swiss_rounds

Integer. Number of swiss rounds to play. Swiss only. It is recommended that
the number of rounds is limited to no more than two thirds of the number of
players, otherwise an impossible pairing situation may occur and the
tournament may end prematurely.

=item ranked_by

How the tournament is ranked. Can be one of the following.

=over 4

=item match wins

=item game wins

=item points scored

=item points difference

=item custom

=back

=item rr_pts_for_match_win

Decimal (to the nearest tenth). Number of points gained by winning a match.
Round Robin 'custom' only. Default is 1.0.

=item rr_pts_for_match_tie

Decimal (to the nearest tenth). Number of points gained by drawing a match.
Round Robin 'custom' only. Default is 0.5.

=item rr_pts_for_game_win

Decimal (to the nearest tenth). Number of points gained by winning a single
game within a match. Round Robin 'custom' only. Default is 0.0.

=item rr_pts_for_game_tie

Decimal (to the nearest tenth). Number of points gained by drawing a single
game within a match. Round Robin 'custom' only. Default is 0.0.

=item accept_attachments

True/false. Allow match attachment uploads. Default is false.

=item hide_forum

True/false. Hide the forum tab on your Challonge page. Default is false.

=item show_rounds

True/false. Label each round about the bracket. Single and double elimination
only. Default is false.

=item private

True/false. Hide this tournament from the public browsable index and your
profile. Default is false.

=item notify_users_when_matches_open
r

True/false. Send registered Challonge users an email when matches open up
for them. Default is false.

=item nofity_users_when_the_tournament_ends

True/false. Send registered Challonge users an email with the results when
the tournament ends. Default is false.

=item sequential_pairings

True/false. Instead of following traditional seeding rules, make the pairings
go straight down the list of participants. For example, the first match will
be the first seed versus the second. Default is false.

=item signup_cap

Integer. The maximum number of participants. Any additional participants will
go on a waiting list.

=item start_at

DateTime. The planned time to start the tournament. Timezone defaults to
Eastern (EST).

=item check_in_duration

Integer. The length of the check-in window in minutes.

=back

	my $tournament = $c->new_tournament({
		name => "sample tournament",
		url => "sample_tournament_1",
		type => "double elimination"
	});

=cut

sub new_tournament
{
	my $self = shift;
	my $args = shift;

	# Get the key and client:
	my $key = $self->{key};
	my $client = $self->{client};

	# Fail if name and URL aren't given:
	if((! defined $args->{name}) || (! defined $args->{url}))
	{
		croak "Name and URL are required to create a tournament";
	}

	# Check the arguments and values are valid:
	return undef unless(WWW::Challonge::Tournament::__args_are_valid($args));

	# Encapsulate the API key and the arguments in a single hashref:
	my $params = { api_key => $key, tournament => $args };

	# Now we have all the arguments validated, send the POST request:
	my $response = $client->request(
		__json_request("$HOST/tournaments.json", "POST", $params));

	# Check for any errors:
	WWW::Challonge::__handle_error $response if($response->is_error);

	# Otherwise, make a tournament object and return it:
	my $t = WWW::Challonge::Tournament->new(
		from_json($response->decoded_content), $key, $client);
	return $t;
}

=head2 __handle_error

Used throughout the module to deal with when the Challonge API returns an
error of some kind. Takes a L<HTTP::Response> object.

=cut

sub __handle_error
{
	my $response = shift;

	# Determine if the response is JSON or not:
	eval { from_json($response->decoded_content) };
	unless($@)
	{
		for my $error(@{from_json($response->decoded_content)->{errors}})
		{
			croak "(" . $response->code . ") " . $error;
		}
	}
	else
	{
		croak "(" . $response->code . ") " . $response->decoded_content;
	}
}

=head2 __json_request

Transforms a URI, verb and hashref to a L<HTTP::Request> object to use for a
POST/PUT request with the hashref transformed to JSON.

=cut

sub __json_request
{
	my $uri = shift;
	my $action = shift;
	my $params = shift;

	my $req = HTTP::Request->new($action, $uri);
	$req->header('Content-Type' => 'application/json');
	$req->content(to_json($params));

	return $req;
}

=head1 AUTHOR

Alex Kerr, C<< <kirby at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-challonge at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Challonge>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Challonge

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Challonge>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Challonge>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Challonge>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Challonge/>

=back

=head1 SEE ALSO

=over 4

=item L<WWW::Challonge::Tournament>

=item L<WWW::Challonge::Participant>

=item L<WWW::Challonge::Match>

=item L<WWW::Challonge::Match::Attachment>

=back

=head1 ACKNOWLEDGEMENTS

Everyone on the L<Challonge|http://challonge.com> team for making such a great
service.

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Alex Kerr.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of WWW::Challonge
