package WWW::Challonge::Participant;

use 5.010;
use strict;
use warnings;
use WWW::Challonge;
use Carp qw/carp croak/;
use JSON qw/to_json from_json/;

sub __is_kill;
sub __args_are_valid;

=head1 NAME

WWW::Challonge::Participant - A class representing a single participant within
a Challonge tournament.

=head1 VERSION

Version 1.01

=cut

our $VERSION = '1.01';

=head1 SUBROUTINES/METHODS

=head2 new

Takes a hashref representing the participant, the API key and the REST client
and turns it into an object. This is mostly used by the module itself, to
create a new participant within a tournament see
L<WWW::Challonge::Tournament/new_participant>.

	my $p = WWW::Challonge::Participant->new($participant, $key, $client);

=cut

sub new
{
	my $class = shift;
	my $participant = shift;
	my $key = shift;
	my $client = shift;

	my $p =
	{
		alive => 1,
		client => $client,
		participant => $participant->{participant},
		key => $key,
	};
	bless $p, $class;
}

=head2 update

Updates specific attributes of a participant. For a full list, see
L<WWW::Challonge::Tournament/new_participant>. Unlike that method, however,
all arguments are optional.

	$p->update({
		name => "test2",
		seed => 1
	});

=cut

sub update
{
	my $self = shift;
	my $args = shift;

	# Do not operate on a dead participant:
	return __is_kill unless($self->{alive});

	# Die on no errors:
	croak "No arguments given" unless(defined $args);

	# Get the key, REST client, tournament url and id:
	my $key = $self->{key};
	my $client = $self->{client};
	my $url = $self->{participant}->{tournament_id};
	my $id = $self->{participant}->{id};
	my $HOST = $WWW::Challonge::HOST;

	# Check the arguments and values are valid:
	return undef unless(WWW::Challonge::Participant::__args_are_valid($args));

	# Add the API key and put everything else in a 'participant' hash:
	my $params = { api_key => $key, participant => $args };

	# Make the PUT request:
	my $response = $client->request(WWW::Challonge::__json_request(
		"$HOST/tournaments/$url/participants/$id.json", "PUT", $params));

	# Check for any errors:
	WWW::Challonge::__handle_error $response if($response->is_error);

	return 1;
}

=head2 check_in

Checks in the participant to the tournament.

	$p->check_in;

=cut

sub check_in
{
	my $self = shift;

	# Do not operate on a dead participant:
	return __is_kill unless($self->{alive});

	# Get the key, REST client, tournament url and id:
	my $key = $self->{key};
	my $client = $self->{client};
	my $url = $self->{participant}->{tournament_id};
	my $id = $self->{participant}->{id};
	my $HOST = $WWW::Challonge::HOST;

	# Add the API key:
	my $params = { api_key => $key };

	# Make the POST call:
	my $response = $client->request(WWW::Challonge::__json_request(
		"$HOST/tournaments/$url/participants/$id/check_in.json", "POST",
		$params));

	# Check for any errors:
	WWW::Challonge::__handle_error $response if($response->is_error);

	return 1;
}

=head2 destroy

If the tournament has not started, deletes the associated participant. If the
tournament has started, the participant is marked inactive and their matches
are automatically forfeited.

	$p->destroy;

	# $p still contains the participant, but any future operations will fail:
	$p->update({ name => "test2" }); # ERROR!

=cut

sub destroy
{
	my $self = shift;

	# Do not operate on a dead participant:
	return __is_kill unless($self->{alive});

	# Get the key, REST client, tournament url and id:
	my $key = $self->{key};
	my $client = $self->{client};
	my $url = $self->{participant}->{tournament_id};
	my $id = $self->{participant}->{id};
	my $HOST = $WWW::Challonge::HOST;

	# Make the DELETE call:
	my $response = $client->delete(
		"$HOST/tournaments/$url/participants/$id.json?api_key=$key");

	# Check for any errors:
	WWW::Challonge::__handle_error $response if($response->is_error);

	# If so, set the alive key to false to prevent further operations:
	$self->{alive} = 0;

	return 1;
}

=head2 randomize

Randomises the seeds among participants. Only applicable before a tournament
has started. Affects all participants in the tournament.

	$p->randomize;

=cut

sub randomize
{
	my $self = shift;

	# Do not operate on a dead participant:
	return __is_kill unless($self->{alive});

	# Get the key, REST client and tournament url:
	my $key = $self->{key};
	my $client = $self->{client};
	my $url = $self->{participant}->{tournament_id};
	my $HOST = $WWW::Challonge::HOST;

	# Add the API key:
	my $params = { api_key => $key };

	# Make the POST call:
	my $response = $client->request(WWW::Challonge::__json_request(
		"$HOST/tournaments/$url/participants/randomize.json", "POST", $params));

	# Check for any errors:
	WWW::Challonge::__handle_error $response if($response->is_error);

	return 1;
}

=head2 attributes

Gets all the attributes of the participant in hashref and returns it. Contains
the following fields.

=over 4

=item active

=item attached_participatable_portrait_url

=item can_check_in

=item challonge_email_address_verified

=item challonge_username

=item checked_in

=item checked_in_at

=item confirm_remove

=item created_at

=item display_name_with_invitation_email_address

=item email_hash

=item final_rank

=item group_id

=item icon

=item id

=item invitation_id

=item invitation_pending

=item invite_email

=item misc

=item name

=item on_waiting_list

=item participatable_or_invitation_attached

=item reactivatable

=item removable

=item seed

=item tournament_id

=item updated_at

=item username

=back

	my $attr = $p->attributes;
	print $attr->{name}, "\n";

=cut

sub attributes
{
	my $self = shift;

	# Do not operate on a dead participant:
	return __is_kill unless($self->{alive});

	# Get the key, REST client, tournament url and id:
	my $key = $self->{key};
	my $client = $self->{client};
	my $url = $self->{participant}->{tournament_id};
	my $id = $self->{participant}->{id};
	my $HOST = $WWW::Challonge::HOST;

	# Get the most recent version:
	my $response = $client->get(
		"$HOST/tournaments/$url/participants/$id.json?api_key=$key");

	# Check for any errors:
	WWW::Challonge::__handle_error $response if($response->is_error);

	# If so, save it and then return it:
	$self->{participant} = from_json($response->decoded_content)->{participant};
	return $self->{participant};
}

=head2 __is_kill

Returns an error explaining that the current tournament has been destroyed and
returns undef, used so a function doesn't attempt to operate on a tournament
that has been successfully destroyed.

=cut

sub __is_kill
{
	croak "Participant has been destroyed";
	return undef;
}

=head2 __args_are_valid

Checks if the passed arguments and values are valid for creating or updating
a tournament.

=cut

sub __args_are_valid
{
	my $args = shift;

	# Check it is a hashref:
	unless(ref $args eq "HASH")
	{
		carp "Argument must be a hashref";
		return undef;
	}

	# The possible parameters, grouped together by the kind of input they take.
	my %valid_args = (
		string => [
			"name",
			"challonge_username",
			"email",
			"misc",
		],
		integer => [
			"seed",
		],
	);

	# Validate the inputs:
	for my $arg(@{$valid_args{string}})
	{
		next unless(defined $args->{$arg});
		# Most of the string-based arguments require individual validation
		# based on what they are:
		if($arg =~ /^misc$/)
		{
			if(length $args->{$arg} > 255)
			{
				croak "'$arg' input is too long (max. 255 characters)";
			}
		}
	}
	for my $arg(@{$valid_args{integer}})
	{
		next unless(defined $args->{$arg});
		# Make sure the argument is an integer:
		if($args->{$arg} !~ /^\d*$/)
		{
			croak "Value '" . $args->{$arg} . "' is not a valid integer for " .
				"argument '" . $arg . "'";
			return undef;
		}
	}

	# Finally, check if there are any unrecognised arguments, but just ignore
	# them instead of erroring out:
	my @accepted_inputs = (
		@{$valid_args{string}},
		@{$valid_args{integer}},
	);
	my $is_valid = 0;
	for my $arg(keys %{$args})
	{
		for my $valid_arg(@accepted_inputs)
		{
			if($arg eq $valid_arg)
			{
				$is_valid = 1;
				last;
			}
		}
		carp "Ignoring unknown argument '" . $arg . "'" unless($is_valid);
		$is_valid = 0;
	}
	return 1;
}

=head1 AUTHOR

Alex Kerr, C<< <kirby at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-challonge at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Challonge::Participant>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Challonge::Participant

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Challonge>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Challonge>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Challonge>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Challonge>

=back

=head1 SEE ALSO

=over 4

=item L<WWW::Challonge>

=item L<WWW::Challonge::Tournament>

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

1; # End of WWW::Challonge::Participant
