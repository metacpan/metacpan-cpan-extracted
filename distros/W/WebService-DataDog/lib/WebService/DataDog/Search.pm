package WebService::DataDog::Search;

use strict;
use warnings;

use base qw( WebService::DataDog );
use Carp qw( carp croak );
use Data::Dumper;
use Try::Tiny;


=head1 NAME

WebService::DataDog::Search - Interface to Search functions in DataDog's API.

=head1 VERSION

Version 1.0.3

=cut

our $VERSION = '1.0.3';


=head1 SYNOPSIS

This module allows you interact with the Search endpoint of the DataDog API.

Per DataDog: "This end point allows you to search for entities in Datadog.
The currently searchable entities are: hosts, metrics"


=head1 METHODS

=head2 retrieve()

Return a list of search results for the specified term.

	my $search = $datadog->build('Search');
	my $search_results = $search->retrieve(
		term  => $search_term,
		facet => [ 'hosts', 'metrics' ] #optional
	);

Parameters:

=over 4

=item * term

Search term you want to retrieve results for.

=item * facet

Limit search results to matches of the specified type

=back

=cut

sub retrieve
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();

	# Check for mandatory parameters
	foreach my $arg ( qw( term ) )
	{
		croak "ERROR - Argument '$arg' is required for retrieve()."
			if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
	}

	my $url = $WebService::DataDog::API_ENDPOINT . 'search';


	if (
			defined $args{'facet'} &&
			$args{'facet'} ne 'hosts' &&
			$args{'facet'} ne 'metrics'
		)
	{
		croak 'ERROR - Invalid facet type >' . 	$args{'facet'} . "<. Allowed values: 'hosts', 'metrics'";
	}

	if ( $args{'facet'} )
	{
		$url .= '?q=' . $args{'facet'} . ':' . $args{'term'};
	}
	else
	{
		$url .= '?q=' . $args{'term'};
	}

	my $response = $self->_send_request(
		method => 'GET',
		url    => $url,
		data   => { '' => [] },
	);

	if ( !defined($response) || !defined($response->{'results'}) )
	{
		croak "Fatal error. No response or 'results' missing from response.";
	}

	return $response->{'results'};
}


1;
