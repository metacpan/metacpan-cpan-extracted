package WebService::DataDog::Event;

use strict;
use warnings;

use base qw( WebService::DataDog );
use Carp qw( carp croak );
use Data::Dumper;


=head1 NAME

WebService::DataDog::Event - Interface to Event functions in DataDog's API.

=head1 VERSION

Version 1.0.3

=cut

our $VERSION = '1.0.3';


=head1 SYNOPSIS

This module allows you interact with the Event endpoint of the DataDog API.

Per DataDog: "The events service allows you to programatically post events to
the stream and fetch events from the stream."


=head1 METHODS

=head2 search()

Search the event stream using specified parameters.

	my $event = $datadog->build('Event');
	my $event_list = $event->search(
		start     => $start_time,
		end       => $end_time, # Optional - default 'now'
		priority  => $priority, # Optional - low|normal
		sources   => $sources,  # Optional - list of sources. Ex: Datadog, Github, Pingdom, Webmetrics
		tags      => $tag_list, # Optional - list of tags associated with the event
	);
	
	Examples:
	+ Find all events in the last 48 hours.
	my $event_list = $event->search(
		start => time() - ( 48 * 60 * 60 ),
	);
	
	+ Find all events in the last 24 hours tagged with 'env:prod'.
	my $event_list = $event->search(
		start => time() - ( 24 * 60 * 60 ),
		end   => time(),
		tags  => [ 'env:prod' ],
	);
	
Parameters:

=over 4

=item * start

The start of the date/time range to be searched. UNIX/Epoch/POSIX time.

=item * end

Optional. The end of the date/time range to be searched. UNIX/Epoch/POSIX time.
Default = now.

=item * priority

Optional. Event priority level. Accepted values: low, normal.

=item * sources

Optional. List of sources that generated events.

=item * tags

Optional. List of tags associated with the events.

=back

=cut

sub search
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();

	# Perform various error checks before attempting to search events
	$self->_search_error_checks( %args );
	
	my $url = $WebService::DataDog::API_ENDPOINT . 'events' . '?';
		
	$url .= 'start=' . $args{'start'};
	$url .= '&end=' . ( defined $args{'end'} ? $args{'end'} : time() );
	
	if ( defined( $args{'priority'} ) )
	{
		$url .= '&priority=' . $args{'priority'};
	}
	
	if ( defined( $args{'tags'} ) )
	{
		$url .= '&tags=' . ( join( ',', @{ $args{'tags'} } ) );
	}
	
	if ( defined( $args{'sources'} ) )
	{
		$url .= '&sources=' . ( join( ',', @{ $args{'sources'} } ) );
	}
	
	my $response = $self->_send_request(
		method => 'GET',
		url    => $url,
		data   => { '' => [] }
	);
	
	if ( !defined($response) || !defined($response->{'events'}) )
	{
		croak "Fatal error. No response or 'events' missing from response.";
	}
	
	return $response->{'events'};
}


=head2 get_event()

Deprecated. Please use retrieve() instead.

=cut

sub get_event
{
	my ( $self, %args ) = @_;
	
	carp "get_event() is deprecated. Please use retrieve() instead.";
	
	return $self->retrieve( %args );
}


=head2 retrieve()

Get details of specified event.
NOTE: Receiving a 404 response likely means the requested event id does not exist.

	my $event = $datadog->build('Event');
	my $event_data = $event->retrieve( id => $event_id );
=cut

sub retrieve
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();
	
	# Check for mandatory parameters
	foreach my $arg ( qw( id ) )
	{
		croak "ERROR - Argument '$arg' is required."
			if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
	}
	
	# Check that id specified is a number
	croak "ERROR - Event id must be a number. You specified >" . $args{'id'} . "<"
		unless $args{'id'} =~ /^\d+$/;
	
	my $url = $WebService::DataDog::API_ENDPOINT . 'events' . '/' . $args{'id'};
	my $response = $self->_send_request(
		method => 'GET',
		url    => $url,
		data   => { '' => [] }
	);
	
	if ( !defined($response) || !defined($response->{'event'}) )
	{
		croak "Fatal error. No response or 'event' missing from response.";
	}
	
	return $response->{'event'};
}


=head2 post_event()

Deprecated. Please use create() instead.

=cut

sub post_event
{
	my ( $self, %args ) = @_;
	
	carp "post_event() is deprecated. Please use create() instead.";
	
	return $self->create( %args );
}


=head2 create()

Post event to DataDog event stream. This will overlay red areas on all dashboards,
corresponding to each event.  Example uses: code pushes, server/service restarts, etc.

Per DataDog: "This end point allows you to post events to the stream. You can
tag them, set priority and event aggregate them with other events."

	my $event = $datadog->build('Event');
	$event->create(
		title            => $event_title,               
		text             => $event_text,  # Body/Description of the event.
		date_happened    => $timestamp,   # Optional, default "now"
		priority         => $priority,    # Optional. normal|low
		related_event_id => $event_id,    # Optional, id of aggregate event
		tags             => $tag_list,    # Optional - tags to apply to event (easy to search by)
		alert_type       => $alert_type,  # Optional. error|warning|info|success
		aggregation_key  => $agg_key,     # Optional. Arbitrary string to use for aggregation.
		source_type_name => $source_type, # Optional. nagios|hudson|jenkins|user|my apps|feed|chef|puppet|git|bitbucket|fabric|capistrano
	);
	
	Examples:
	+ Submit a user event, with timestamp of `now`.
	$event->create(
		title            => 'Test event',
		text             => 'Testing posting to event stream',
		source_type_name => 'user',
	);
	
Parameters:

=over 4

=item * title

The event title.

=item * text

Optional. Event body/description.

=item * date_happened

Optional. Default value 'now'. POSIX/Unix time.

=item * priority

Optional. Allowed values: normal, low.

=item * related_event_id

Optional. The id of the aggregate event.

=item * tags

Optional. List of tags associated with the event.

=item * alert_type

Optional. "error", "warning", "info" or "success"

=item * aggregation_key

Optional. An arbitrary string to use for aggregation.

=item * source_type_name

Optional. The type of event being posted. Allowed values: nagios, hudson,
jenkins, user, my apps, feed, chef, puppet, git, bitbucket, fabric, capistrano

=back

=cut

sub create
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();
	
	# Perform various error checks before attempting to send metrics
	$self->_create_error_checks( %args );
	
	my $data = {
		title => $args{'title'},
		text  => $args{'text'},
	};
	
	if ( defined( $args{'date_happened'} ) )
	{
		$data->{'date_happened'} = $args{'date_happened'};
	}
	
	if ( defined $args{'priority'} )
	{
		$data->{'priority'} = $args{'priority'};
	}
	
	if ( defined( $args{'related_event_id'} ) )
	{
		$data->{'related_event_id'} = $args{'related_event_id'};
	}
	
	if ( defined( $args{'tags'} ) )
	{
		$data->{'tags'} = $args{'tags'};
	}
	
	if ( defined( $args{'alert_type'} ) )
	{
		$data->{'alert_type'} = $args{'alert_type'};
	}
	
	if ( defined( $args{'source_type_name'} ) )
	{
		$data->{'source_type_name'} = $args{'source_type_name'};
	}
	
	my $url = $WebService::DataDog::API_ENDPOINT . 'events';
	
	my $response = $self->_send_request(
		method => 'POST',
		url    => $url,
		data   => $data,
	);
	
	croak "ERROR - did not receive 'status: ok'. Response:", Dumper($response)
		unless $response->{'status'} eq "ok";
		
	return;
}


=head1 INTERNAL FUNCTIONS

=head2 _search_error_checks()

Error checking for search()

=cut

sub _search_error_checks
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();
	
	# Check for mandatory parameters
	foreach my $arg ( qw( start ) )
	{
		croak "Argument '$arg' is required for search()"
			if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
	}
	
	# Check that 'start' is valid
	croak "ERROR - invalid 'start' value >" . $args{'start'} . "<. Must be POSIX/Unixtime"
		unless ( $args{'start'} =~ /^\d{10,}$/ ); #min 10 digits, allowing for older data back to 1/1/2000
	
	# Check that 'end' is valid
	if ( defined $args{'end'} )
	{
		croak "ERROR - invalid 'end' value >" . $args{'end'} . "<. Must be POSIX/Unixtime"
		unless ( $args{'end'} =~ /^\d{10,}$/ ); #min 10 digits, allowing for older data back to 1/1/2000
	}
	
	# Check that 'priority' is valid
	if ( defined $args{'priority'} )
	{
		croak "ERROR - invalid 'priority' value >" . $args{'priority'} . "<. Allowed values: low, normal."
			unless ( lc( $args{'priority'} ) eq "low" || lc( $args{'priority'} ) eq "normal" );
	}
	
	# Check that 'tags' is valid
	if ( defined( $args{'tags'} ) )
	{
		if ( !Data::Validate::Type::is_arrayref( $args{'tags'} ) )
		{
			croak "ERROR - invalid 'tags' value. Must be an arrayref.";
		}
	}
	
	# Check that 'sources' is valid
	if ( defined( $args{'sources'} ) )
	{
		if ( !Data::Validate::Type::is_arrayref( $args{'sources'} ) )
		{
			croak "ERROR - invalid 'sources' value. Must be an arrayref.";
		}
	}
	
	return;
}


=head2 _create_error_checks()

Error checking for create()

=cut

sub _create_error_checks
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();
	
	# Check for mandatory parameters
	foreach my $arg ( qw( title text ) )
	{
		croak "Argument '$arg' is required for create()"
			if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
	}
	
	# Check that title is <= 100 characters. Per Carlo @ DDog. Undocumented?
	croak( "ERROR - invalid 'title' >" . $args{'title'} . "<. Title must be 100 characters or less." )
		if ( length( $args{'title'} ) > 100 );
	
	# Check that 'date_happened' is valid
	if ( defined( $args{'date_happened'} ) )
	{
		croak "ERROR - invalid 'date_happened' >" . $args{'date_happened'} . "<. Must be POSIX/Unixtime"
			unless ( $args{'date_happened'} =~ /^\d{10,}$/ ); #min 10 digits, allowing for older data back to 1/1/2000
	}
	
	# Check that 'priority' is valid
	if ( defined $args{'priority'} )
	{
		croak "ERROR - invalid 'priority' >" . $args{'priority'} . "<. Allowed values: low, normal."
			unless ( lc( $args{'priority'} ) eq "low" || lc( $args{'priority'} ) eq "normal" );
	}
	
	# Check that 'related_event_id' is valid
	if ( defined( $args{'related_event_id'} ) )
	{
		croak "ERROR - invalid 'related_event_id' >" . $args{'related_event_id'} . "<"
			unless $args{'related_event_id'} =~ /^\d+$/;
	}
	
	# Check that 'tags' is valid
	if ( defined( $args{'tags'} ) )
	{
		if ( !Data::Validate::Type::is_arrayref( $args{'tags'} ) )
		{
			croak "ERROR - invalid 'tags' value. Must be an arrayref.";
		}
	}
	
	# Check that 'alert_type' is valid
	if ( defined( $args{'alert_type'} ) )
	{
		croak "ERROR - invalid 'alert_type' >" . $args{'alert_type'} . "<. Allowed values: error, warning, info, success"
			unless $args{'alert_type'} =~ /^error|warning|info|success$/;
	}
	
	# Check that 'source_type_name' is valid
	if ( defined( $args{'source_type_name'} ) )
	{
		croak "ERROR - invalid 'source_type_name' >" . $args{'source_type_name'} . "<. Allowed values: nagios|hudson|jenkins|user|my apps|feed|chef|puppet|git|bitbucket|fabric|capistrano"
			unless $args{'source_type_name'} =~ /^nagios|hudson|jenkins|user|my apps|feed|chef|puppet|git|bitbucket|fabric|capistrano$/; ## no critic qw( RegularExpressions::RequireExtendedFormatting RegularExpressions::ProhibitComplexRegexes )
	}
	
	return;
}


1;
