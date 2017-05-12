package WebService::DataDog::Graph;

use strict;
use warnings;

use base qw( WebService::DataDog );
use Carp qw( carp croak );
use Data::Dumper;
use Try::Tiny;


=head1 NAME

WebService::DataDog::Graph - Interface to Graph functions in DataDog's API.

=head1 VERSION

Version 1.0.3

=cut

our $VERSION = '1.0.3';


=head1 SYNOPSIS

This module allows you interact with the graph endpoint of the DataDog API.

Per DataDog: "You can take graph snapshots using the API"


=head1 METHODS

=head2 snapshot()

Take a graph snapshot.
	
	my $graph = $datadog->build('Graph');
	my $snapshot_url = $graph->snapshot(
		metric_query => $metric_query,
		start        => $start_timestamp,
		end          => $end_timestamp,
		event_query  => $event_query, # optional -- default=None
	);
	
	Example:
	my $snapshot_url = $graph->snapshot(
		metric_query => "system.load.1{*}",
		start        => 1388632282
		end          => 1388718682
	);
	
Parameters:

=over 4

=item * metric_query

Metric query to capture in the graph.

=item * start

The POSIX timestamp of the start of the query.

=item * end

The POSIX timestamp of the end of the query.

=item * event_query

A query that will add event bands to the graph.

=back

=cut

sub snapshot 
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();
	
	# Check for mandatory parameters
	foreach my $arg ( qw( metric_query start end ) )
	{
		croak "ERROR - Argument '$arg' is required for snapshot()."
			if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
	}
	
	# Check for valid parameters
	foreach my $arg ( qw( start end ) )
	{
		croak "ERROR - Argument '$arg' must be an integer, required for snapshot()."
			if $args{$arg} !~ /^\d+$/;
	}
	
	my $url = $WebService::DataDog::API_ENDPOINT . 'graph/snapshot?';
	$url .= 'metric_query=' . $args{'metric_query'} . '&';
	$url .= 'start=' . $args{'start'} . '&';
	$url .= 'end=' . $args{'end'};
	
	if ( defined( $args{'event_query'} ) && $args{'event_query'} ne '' )
	{
		$url .= '&event_query=' . $args{'event_query'};
	}
	
	my $response = $self->_send_request(
		method => 'GET',
		url    => $url,
		data   => { '' => [] }
	);
	
	if ( !defined($response) )
	{
		croak "Fatal error. No response.";
	}
	
	if ( !defined($response->{'snapshot_url'}) || $response->{'snapshot_url'} eq '' )
	{
		croak "Fatal error. Missing or invalid snapshot_url.";
	}
	
	return $response->{'snapshot_url'};
}


1;
