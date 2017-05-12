package WWW::TVMaze;

use 5.006;
use strict;
use warnings;
use Mouse;
use LWP::UserAgent;
use JSON::XS;
use DateTime;
use Params::Validate qw(:all);

=head1 NAME

WWW::TVMaze - Interface to TVMaze API

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.06';

has '_endpoint' => (
	isa => 'Str',
	is  =>'ro',
	default => 'http://api.tvmaze.com'
);

has 'error' => (
	isa => 'Maybe[Str]',
	is  => 'rw',
	default => undef,
);

has 'http_status' => (
	isa => 'Maybe[Str]',
	is  =>'rw',
	default => undef,
);


=head1 SYNOPSIS

This module allows you to user TVMaze API (L<http://www.tvmaze.com/api>)

	use WWW::TVMaze;

	my $tv_maze = WWW::TVMaze->new();

	my $shows = $tv_maze->show_search('Arrow');


=head1 METHODS

=head2 shows

	my $show = $tv_maze->shows($id);

Returns a show by its ID


=head2 show_search

	my $shows = $tv_maze->show_search($search_keyword);

Returns a list of shows that match your search keyword


=head2 show_single_search

	my $show = $tv_maze->show_single_search($search_keyword);

Returns a single show that match your search keyword

=head2 show_lookup

	my $show = $tv_maze->show_lookup( $id, $id_type ); # $id_type can be 'tvrage' or 'thetvdb' or 'imdb'

Returns a show by its TVRage ID or by its THETVDB ID

=head2 show_seasons

	my $seasons = $tv_maze->show_seasons($show_id);

Returns all seasons of a show. Each season contains the number; the name (available for shows that give a title to each season, episode order (the total amount of episodes that will be released in the season); premiere and end date; network or web channel that specific season premiered on; and its image and summary.

=head2 show_episode_list

	my $ep_list = $tv_maze->show_episode_list($show_id, $include_specials); # $include_specials can be 0 or 1 and is optional;

Returns a complete list of episodes for a given show. by defauls specials are not included

=head2 show_cast

	my $cast = $tv_maze->show_cast($show_id);

Returns a list of main cast for a given show

=head2 show_akas

	my $akas = $tv_maze->show_akas($show_id);

Returns a list of AKA's for a show

=head2 show_index

	my $index = $tv_maze->show_index($page);  ## $page is optional, pagination starts on page 0

Returns all TV Maze shows , 250 results per page

=head2 episode_by_number

	my $ep = $tv_maze->episode_by_number($show_id, $season, $ep_number);

Returns a show episode

=head2 episodes_by_date

	my $eps = $tv_maze->episodes_by_date($show_id, $date);

Returns a list of episodes for a given show aired on a given date


=head2 schedule

	my $schedule = $tv_maze->schedule($country_code, $date); # $country_code is an ISO 3166-1 code of the country, $date an ISO 8601 formatted date, both parameters are optional, defaults to 'US' and current day

Returns a complete list of episodes for the date and country provided


=head2 full_schedule

	my $schedule = $tv_maze->full_schedule();

Returns a list of all future episodes known to TVmaze


=head2 people_search

	my $people = $tv_maze->people_search($search_keyword);

Returns a list of persons that match your search keyword


=head2 people

	my $people = $tv_maze->people($id);

Returns a person by its ID


=head2 person_cast_credits

	my $person_credits = $tv_maze->person_cast_credits($person_id, $emded_show); # $embed_show is optional, can be 1 or 0;

Returns alll show-level cast credits for a person

=head2 person_crew_credits

	my $person_credits = $tv_maze->person_crew_credits($person_id, $emded_show); # $embed_show is optional, can be 1 or 0;

Returns alll show-level crew credits for a person

=head2 updates

	my $updates = $tv_maze->updates();

Returns a list of all the shows in the database with a timestamp of when they were last updated


=head2 error

	my $error = $tv_maze->error();

Returns the last error

=head2 http_status

	my $http_status = $tv_maze->http_status();

Returns the last HTTP status received
=cut


sub shows {
	my ($self, $id) = @_;
	shift @_;
	validate_pos(@_, { type => SCALAR  } );

	return $self->_request('shows/' . $id);
}

sub show_search {
	my ($self, $search) = @_;
	shift @_;
	validate_pos(@_ , { type => SCALAR } );
	return $self->_request('search/shows?q=' . $search);
}


sub show_single_search {
	my ($self, $search) = @_;
	shift @_;
	validate_pos(@_ , { type => SCALAR } );
	return $self->_request('singlesearch/shows?q=' . $search);
}


sub show_lookup {
	my ($self, $id, $id_type) = @_;
	shift @_;
	validate_pos (@_ , { type => SCALAR }, { type => SCALAR, regex => qr/^tvrage$|^thetvdb$|^imdb$/ } );
	return $self->_request('lookup/shows?' . $id_type .'=' . $id);
}



sub people_search {
	my ($self, $search) = @_;
	shift @_;
	validate_pos(@_ , { type => SCALAR } );
	return $self->_request('search/people?q=' . $search);
}



sub schedule {
	my ($self, $country_code, $date) = @_;
	shift @_;
	validate_pos(@_ , { type => SCALAR, optional => 1 , regex => qr/^\w{2}$/}, { type => SCALAR , optional => 1 , regex => qw/\d{4}-\d{2}-\d{2}$/ } );
	$country_code ||= 'US';
	$date         ||= DateTime->now->ymd('-');
	return $self->_request('schedule?country=' . $country_code . '&date=' .$date);
}


sub full_schedule {
	my ($self) = @_;
	return $self->_request('schedule/full');
}


sub show_seasons {
	my ($self, $tvmaze_id) = @_;
	shift @_;
	validate_pos(@_, { type => SCALAR });
	return $self->_request('shows/' . $tvmaze_id  .'/seasons');
}

sub show_episode_list {
	my ($self, $tvmaze_id, $specials) = @_;
	shift @_;
	validate_pos(@_, { type => SCALAR }, { type => BOOLEAN , optional => 1  } );
	$specials ||= 0;
	return $self->_request('shows/' . $tvmaze_id .'/episodes?specials=' . $specials);
}


sub episode_by_number {
	my ($self, $tvmaze_id, $season, $number) = @_;
	shift @_;
	validate_pos(@_, { type => SCALAR },  { type => SCALAR , optional => 1, regex => qr/^\d+$/ }, { type => SCALAR , optional => 1, regex => qr/^\d+$/ } );
	$season ||= 1;
	$number ||= 1;
	return $self->_request('shows/' . $tvmaze_id . '/episodebynumber?season=' . $season .'&number=' . $number);
}


sub episodes_by_date {
	my ($self, $tvmaze_id, $date) = @_;

	if ($date !~/^\d{4}-\d{2}-\d{2}$/) {
		$self->error('invalid date');
		return undef;
	}
	return $self->_request('shows/' . $tvmaze_id .'/episodesbydate?date=' . $date);
}




sub show_cast {
	my ($self, $tvmaze_id) = @_;
	return $self->_request('shows/' . $tvmaze_id .'/cast');
}


sub show_akas {
	my ($self, $tvmaze_id) = @_;
	return $self->_request('shows/' . $tvmaze_id .'/akas');
}




sub show_index {
	my ($self, $page) = @_;
	$page ||= 0;
	return $self->_request('shows?page=' . $page);
}



sub people {
	my ($self, $tvmaze_id) = @_;
	return $self->_request('people/' . $tvmaze_id);
}



sub person_cast_credits {
	my ($self, $tvmaze_id, $embed) = @_;
	return $self->_request('people/' . $tvmaze_id .'/castcredits' . ( $embed ? '?embed=show' : '' ));
}


sub person_crew_credits {
	my ($self, $tvmaze_id, $embed) = @_;
	return $self->_request('people/' . $tvmaze_id .'/crewcredits' . ( $embed ? '?embed=show' : '' ));
}



sub updates {
	my ($self) = @_;
	return $self->_request('updates/shows');
}





sub _request {
	my ($self, $uri) = @_;

	my $ua = LWP::UserAgent->new();
	my $url = $self->_endpoint .'/' . $uri;
	my $response = $ua->get($url);

	$self->http_status($response->code);

	if (!$response->is_success) {
		$self->error('request error');
		return {};
	}

	my $data = {};
	eval {
		$data = decode_json($response->decoded_content);
	};
	if ($@) {
		$self->error('problem decoding json');
		return undef;
	}
	return $data;
}







=head1 AUTHOR

Bruno Martins, C<< <bscmartins at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests at L<https://github.com/bmartins/WWW-TVMaze>




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::TVMaze



=head1 LICENSE AND COPYRIGHT

Copyright 2015 Bruno Martins.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WWW::TVMaze
