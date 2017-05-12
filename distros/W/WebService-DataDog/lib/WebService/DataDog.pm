package WebService::DataDog;

use strict;
use warnings;

use Data::Dumper;
use LWP::UserAgent qw();
use HTTP::Request qw();
use JSON qw();
use Class::Load qw();
use Carp qw( carp croak );
use Data::Validate::Type qw();


our $API_ENDPOINT = "https://app.datadoghq.com/api/v1/";


=head1 NAME

WebService::DataDog - Interface to DataDog's REST API.


=head1 VERSION

Version 1.0.3

=cut

our $VERSION = '1.0.3';


=head1 SYNOPSIS

This module allows you to interact with DataDog, a service that will "Capture
metrics and events, then graph, filter, and search to see what's happening and
how systems interact." This module encapsulates all the communications with the
REST API provided by DataDog to offer a Perl interface to metrics, dashboards,
events, alerts, etc.

Requests that write data require reporting access and require an API key.
Requests that read data require full access and additionally require an
application key.

	use WebService::DataDog;

	# Create an object to communicate with DataDog
	my $datadog = WebService::DataDog->new(
		api_key         => 'your_api_key_here',
		application_key => 'your_application_key',
	);

	# For metrics functions, first build a metrics object
	my $metric = $datadog->build('Metric');

	# To post metrics (past or present)
	# NOTE: only use 'value' OR 'data_points', but not both.
	$metric->emit(
		name        => $metric_name,
		type        => $metric_type,  # Optional - gauge|counter. Default=gauge.
		value       => $metric_value, # For posting a single data point, time 'now'
		data_points => $data_points,  # 1+ data points, with timestamps
		host        => $hostname,     # Optional - host that produced the metric
		tags        => $tag_list,     # Optional - tags associated with the metric
	);

	# For dashboard/timeboard functions, first build a dashboard object
	my $dashboard = $datadog->build('Dashboard');

	# Create a new dashboard
	my $dashboard_id = $dashboard->create(
		title       => $dash_title,
		description => $dash_description,
		graphs      => $graphs,
	);

	# Delete a user-created dashboard that you don't need anymore
	$dashboard->delete( id => $dash_id );

	# To make any changes to an existing user-created dashboard:
	# Specify dash_id and any combination of title, description, graphs
	$dashboard->update(
		id          => $dash_id,
		title       => $dash_title,
		description => $dash_description,
		graphs      => $graphs,
	);

	# For event functions, first build an event object
	my $event = $datadog->build('Event');

	# To search the event stream
	my $event_list = $event->search(
		start     => $start_time,
		end       => $end_time, # Optional - default 'now'
		priority  => $priority, # Optional - low|normal
		sources   => $sources,  # Optional - list of sources. Ex: Datadog, Github, Pingdom, Webmetrics
		tags      => $tag_list, # Optional - list of tags associated with the event
	);

	# Find all events in the last 48 hours.
	my $event_list = $event->search(
		start => time() - ( 48 * 60 * 60 ),
	);

	# To get all details of a specific event
	my $event_data = $event->retrieve( id => $event_id );

	# To post a new event to the event stream
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

	# Submit a user event, with timestamp of `now`.
	$event->create(
		title            => 'Test event',
		text             => 'Testing posting to event stream',
		source_type_name => 'user',
	);

	# For alert functions, first build an alert object
	my $alert = $datadog->build('Alert');

	# Get list, with details, of all alerts
	my $alert_list = $alert->retrieve_all();

	# Create a new alert
	my $alert_id = $alert->create(
		query    => $query,      # Metric query to alert on
		name     => $alert_name, # Optional. default=dynamic, based on query
		message  => $message,    # Optional. default=None
		silenced => $boolean,    # Optional. default=0
	);

	# Retrieve details on a specific alert
	my $alert_data = $alert->retrieve( id => $alert_id );

	# Update an existing alert
	$alert->update(
		id       => $alert_id,   # ID of alert to modify
		query    => $query,      # Metric query to alert on
		name     => $alert_name, # Optional.
		message  => $message,    # Optional.
		silenced => $boolean,    # Optional.
	);

	# Mute all alerts at once. Example usage: system maintenance.
	$alert->mute_all();

	# Unmute all alerts at once. Example usage: completed system maintenance.
	$alert->unmute_all();

	# For tag functions, first build a tag object
	my $tag = $datadog->build('Tag');

	# Retrieve a mapping of tags to hosts.
	my $tag_host_list = $tag->retrieve_all();

	# Return a list of tags for the specified host.
	my $tag_list = $tag->retrieve( host => $host_name_or_id );

	# Update tags for specified host.
	$tag->update(
		host => $host,  # name/ID of host to modify
		tags => $tag_list, # Updated full list of tags to apply to host
	);

	# Add tags to specified host.
	$tag->add(
		host => $host,  # name/ID of host to modify
		tags => $tag_list, # Updated full list of tags to apply to host
	);

	# Delete all tags from the specified host.
	$tag->delete( host => $host );

	# For search, first build a search object
	my $search = $datadog->build('Search');

	my $search_results = $search->retrieve(
		term  => $search_term,
		facet => [ 'hosts', 'metrics' ] #optional
	);
	
	# For graph snapshots, first build a graph object
	my $graph = $datadog->build('Graph');
	
	my $snapshot_url = $graph->snapshot(
		metric_query => $metric_query,
		start        => $start_timestamp,
		end          => $end_timestamp,
		event_query  => $event_query, # optional -- default=None
	);
	
=cut


=head1 METHODS

=head2 new()

Create a new DataDog object that will be used as the interface with
DataDog's API

	use WebService::DataDog;

	# Create an object to communicate with DataDog
	my $datadog = WebService::DataDog->new(
		api_key         => 'your_api_key_here',
		application_key => 'your_application_key',
		verbose         => 1,
	);

Creates a new object to communicate with DataDog.

Parameters:

=over 4

=item * api_key

DataDog API key. Found at L<https://app.datadoghq.com/account/settings>

=item * application_key

DataDog application key.  Multiple keys can be generated per account.  Generate/View existing at
L<https://app.datadoghq.com/account/settings>

=item * verbose

Optional.  Set to 1 to see debugging output of request/response interaction with DataDog service.

=back

=cut

sub new
{
	my ( $class, %args ) = @_;

	# Check for mandatory parameters
	foreach my $arg ( qw( api_key application_key ) )
	{
		croak "Argument '$arg' is required to create the WebService::DataDog object"
			if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
	}

	# Create the object
	my $self = bless(
		{
			api_key         => $args{'api_key'},
			application_key => $args{'application_key'},
			verbose         => defined $args{'verbose'} ? $args{'verbose'} : 0,
		},
		$class,
	);

	return $self;
}


=head2 build()

Create a WebService::DataDog::* object with the correct connection parameters.

		# Use the factory to get a WebService::DataDog::* object with
		# the correct DataDog connection parameters.
		my $metric = $datadog->build( 'Metric' );

Parameters:

=over

=item *

The submodule name, such as Metric for WebService::DataDog::Metric.

=back

=cut

sub build
{
		my ( $self, $module ) = @_;

		# Check required arguments
		croak 'Please specify the name of the module to build'
			if !defined( $module ) || ( $module eq '' );

		# Load the class corresponding to the submodule requested.
		my $class = __PACKAGE__ . '::' . $module;
		Class::Load::load_class( $class ) || croak "Failed to load $class, double-check the class name";

		# Instantiate a new object of that class. Since it's a subclass
		# of WebService::DataDog, we pass all the non-hidden properties
		# of the datadog object to build it.
		my $object = $class->new(
			map { $_ => $self->{$_} }
			grep { substr( $_, 0, 1 ) ne '_' }
			keys %$self
		);

		return $object;
}


=head2 verbose()

Get or set the 'verbose' property.

	my $verbose = $self->verbose();
	$self->verbose( 1 );

=cut

sub verbose
{
	my ( $self, $value ) = @_;

	if ( defined $value && $value =~ /^[01]$/ )
	{
		$self->{'verbose'} = $value;
	}
	else
	{
		return $self->{'verbose'};
	}

	return;
}



=head1 RUNNING TESTS

By default, only basic tests that do not require a connection to DataDog's
platform are run in t/.

To run the developer tests, you will need to do the following:

=over 4

=item * Sign up to become a DataDog customer ( if you are not already), at
L<https://app.datadoghq.com/signup>. Free trial accounts are available.

=item * Generate an application key at
L<https://app.datadoghq.com/account/settings#api>

=back

You can now create a file named DataDogConfig.pm in your own directory, with
the following content:

	package DataDogConfig;

	sub new
	{
		return
		{
			api_key         => 'your_api_key',
			application_key => 'your_application_key',
			verbose         => 0, # Enable this for debugging output
		};
	}

	1;

You will then be able to run all the tests included in this distribution, after
adding the path to DataDogConfig.pm to your library paths.




=head1 INTERNAL METHODS

=head2 _send_request()


=cut
sub _send_request ## no critic qw( Subroutines::ProhibitUnusedPrivateSubroutines )
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();

	# Check for mandatory parameters
	foreach my $arg ( qw( data method url ) )
	{
		croak "Argument '$arg' is needed to send a request with the WebService::DataDog object"
			if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
	}

	my $url = $args{'url'};
	my $method = $args{'method'};

	# Add authentication info
	if ( $url =~ /\?/ )  # Some endpoints will already have URL params...
	{
		$url .= '&api_key=' . $self->{'api_key'} . '&application_key=' . $self->{'application_key'};
	}
	else
	{
		$url .= '?api_key=' . $self->{'api_key'} . '&application_key=' . $self->{'application_key'};
	}

	my $request;
	if ( $method =~ /\A(?:GET|POST|DELETE|PUT)\z/x )
	{
		$request = HTTP::Request->new( $method => $url );
	}
	else
	{
		croak "The method >$method< is not supported. Not sending request.";
	}

	carp "Sending request to URL >" . ( defined( $url ) ? $url : '' ) . "< via method >$method<"
		if $verbose;


	my $json_in = JSON::encode_json( $args{'data'} );
	carp "Sending JSON request >" . ( defined( $json_in ) ? $json_in : '' ) . "<"
		if $verbose;

	$request->content_type('application/json');
	$request->content( $json_in );

	carp "Request object: ", Dumper( $request )
		if $verbose;

	my $user_agent = LWP::UserAgent->new();
	my $response = $user_agent->request($request);

	if (! $response->is_success() )
	{
		my $message = "Request failed:" . $response->status_line();
		my $content = $response->content();
		$message .= "\nResponse errors:" . Dumper($content);

		croak $message;
	}

	carp "Response >" . ( defined( $response ) ? $response->content() : '' ) . "<"
		if $verbose;

	# Try to parse JSON response, only if one was received.
	# Some functions, such as Dashboard::delete(), Alert::mute_all, Alert::unmute_all()
	# return nothing when successful, so there won't be anything to parse.
	my $json_out = defined( $response ) && defined( $response->content() ) && $response->content() ne ''
		? JSON::decode_json( $response->content() )
		: '';

	carp "JSON Response >" . ( defined( $json_out ) ? Dumper($json_out) : '' ) . "<"
		if $verbose;

	return $json_out;
}



=head1 AUTHOR

Jennifer Pinkham, C<< <jpinkham at cpan.org> >>.


=head1 BUGS

Please report any bugs or feature requests to C<bug-WebService-DataDog at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-DataDog>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc WebService::DataDog


You can also look for information at:

=over 4

=item * Github Bug/Issue tracker

L<https://github.com/jpinkham/webservice-datadog/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-DataDog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-DataDog>

=item * MetaCPAN

L<https://metacpan.org/release/WebService-DataDog>

=back


=head1 ACKNOWLEDGEMENTS

I originally developed this project for ThinkGeek (L<http://www.thinkgeek.com/>).
Thanks for allowing me to open-source it!

Special thanks for architecture advice, and code contributions, from Guillaume
Aubert L<http://search.cpan.org/~aubertg/>.

=head1 COPYRIGHT & LICENSE

Copyright 2015 Jennifer Pinkham.

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License version 3 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see http://www.gnu.org/licenses/

=cut

1;
