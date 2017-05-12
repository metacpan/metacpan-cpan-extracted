package WebService::DataDog::Dashboard;

use strict;
use warnings;

use base qw( WebService::DataDog );
use Carp qw( carp croak );
use Try::Tiny;
use Data::Dumper;

=head1 NAME

WebService::DataDog::Dashboard - Interface to Dashboard/Timeboard functions in DataDog's API.

=head1 VERSION

Version 1.0.3

=cut

our $VERSION = '1.0.3';


=head1 SYNOPSIS

This module allows you interact with the Dashboard endpoint of the DataDog API.

Per DataDog: "The Dashboards end point allow you to programmatically create,
update delete and query dashboards."


=head1 METHODS

=head2 get_all_dashboards()

Deprecated. Please use retrieve_all() instead.

=cut

sub get_all_dashboards
{
	my ( $self, %args ) = @_;
	
	carp "get_all_dashboards() is deprecated. Please use retrieve_all() instead.";
	
	return $self->retrieve_all( %args );
}


=head2 retrieve_all()

Retrieve details for all user-created dashboards/timeboards ( does not include
system-generated or integration dashboards ).

	my $dashboard = $datadog->build('Dashboard');
	my $dashboard_list = $dashboard->retrieve_all();
	
Parameters: None

=cut

sub retrieve_all
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();
	
	my $url = $WebService::DataDog::API_ENDPOINT . 'dash';
	
	my $response = $self->_send_request(
		method => 'GET',
		url    => $url,
		data   => { '' => [] }
	);
	
	if ( !defined($response) || !defined($response->{'dashes'}) )
	{
		croak "Fatal error. No response or 'dashes' missing from response.";
	}
	
	return $response->{'dashes'};
}


=head2 get_dashboard()

Deprecated. Please use retrieve() instead.

=cut

sub get_dashboard
{
	my ( $self, %args ) = @_;
	
	carp "get_dashboard() is deprecated. Please use retrieve() instead.";
	
	return $self->retrieve( %args );
}


=head2 retrieve()

Retrieve details for specified user-created dashboards/timeboards ( does not work for
system-generated or integration dashboards/timeboards ).

	my $dashboard = $datadog->build('Dashboard');
	my $dashboard_data = $dashboard->retrieve( id => $dash_id );
	
Parameters: 

=over 4

=item * id

Id of dashboard/timeboard you want to retrieve the details for.

=back

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
	croak "ERROR - invalid 'id' >" . $args{'id'} . "<. Dashboard id must be a number."
		unless $args{'id'} =~ /^\d+$/;
	
	my $url = $WebService::DataDog::API_ENDPOINT . 'dash' . '/' . $args{'id'};
	my $response;
	
	try
	{
		$response = $self->_send_request(
			method => 'GET',
			url    => $url,
			data   => { '' => [] }
		);
	}
	catch
	{
		if ( /404/ )
		{
			croak "Unknown dashboard id >" . $args{'id'} . "<";
		}
		else
		{
			croak "Error occurred while trying to retrieve details of dashboard  >" . $args{'id'} . "<. Error: $_";
		}
	};
	
	if ( !defined($response) || !defined($response->{'dash'}) )
	{
		croak "Fatal error. No response or 'dash' missing from response.";
	}
	
	return $response;
}


=head2 update_dashboard()

Deprecated. Please use update() instead.

=cut

sub update_dashboard
{
	my ( $self, %args ) = @_;
	
	carp("update_dashboard() is deprecated. Please use update() instead.");
	
	return $self->update( %args );
	
}


=head2 update()

Update details for specified user-created dashboard/timeboard ( does not work for
system-generated or integration dashboards/timeboards ).
Supply at least one of the arguments 'title', 'description', 'graphs'.
Any argument not supplied will remain unchanged within the dashboard.

WARNING: If you only specify a new graph to add to the dashboard, you WILL
LOSE ALL EXISTING GRAPHS.  Your 'graphs' section must include ALL graphs
that you want to be part of a dashboard.

	my $dashboard = $datadog->build('Dashboard');
	$dashboard->update(
		id          => $dash_id,
		title       => $dash_title,
		description => $dash_description,
		graphs      => $graphs,
	);
	
Parameters:

=over 4

=item * id

Id of dashboard you want to update.

=item * title

Optional. Specify updated title for specified dashboard.

=item * description

Optional. Specify updated description for specified dashboard.

=item * graphs

Optional. Specify updated graph definition for specified dashboard.

=back

=cut

sub update
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();
	
	$self->_error_checks(
		mode => 'update',
		data => \%args,
	);

	my $url = $WebService::DataDog::API_ENDPOINT . 'dash' . '/' . $args{'id'};
	
	my $response;
	# Try to pull up details on specified dashboard before attempting updates
	try
	{
		$response = $self->_send_request(
			method => 'GET',
			url    => $url,
			data   => { '' => [] }
		);
	}
	catch
	{
		croak "Error retrieving details on dashboard id >" . $args{'id'} . "<. Are you sure this is the correct dashboard id?";
	};
	
	if ( !defined($response) || !defined($response->{'dash'}) )
	{
		croak "Fatal error. No response or 'dash' missing from response.";
	}
	
	my $dash_original_details = $response->{'dash'};
	
	$response = undef;
	
	my $data = 
	{
		id => $args{'id'}
	};
	
	# Build required API arguments, using original details for anything that user
	#   has not supplied
	$data->{'title'} = defined $args{'title'}
		? $args{'title'} 
		: $dash_original_details->{'title'};
	
	$data->{'description'} = defined $args{'description'}
		? $args{'description'}
		: $dash_original_details->{'description'};
		
	$data->{'graphs'} = defined $args{'graphs'}
		? $args{'graphs'} 
		: $dash_original_details->{'graphs'};
	
	$response = $self->_send_request(
			method => 'PUT',
			url    => $url,
			data   => $data,
		);
	
	return;
}


=head2 create()

Create new DataDog dashboard/timeboard with 1+ graphs.
If successful, returns created dashboard/timeboard id.

	my $dashboard = $datadog->build('Dashboard');
	my $dashboard_id = $dashboard->create(
		title       => $dash_title,
		description => $dash_description,
		graphs      => $graphs,
	);
	
	Example:
	my $new_dashboard_id = $dashboard->create(
		title       => "TEST DASH",
		description => "test dashboard",
		graphs      =>
		[
			{
				title => "Sum of Memory Free",
				definition =>
				{
					events   =>[],
					requests => [
						{ q => "sum:system.mem.free{*}" }
					]
				},
				viz => "timeseries"
			},
		],
	);
	
Parameters:

=over 4

=item * title

Specify title for new dashboard.

=item * description

Specify description for new dashboard.

=item * graphs

Specify graph definition for new dashboard.

=over 4

=item * title

Title of graph.

=item * definition

Definition of graph.

=over 4

=item * events

Overlay any events from the event stream.

=item * requests

Metrics you want to graph.

=back

=item * viz

Visualisation of graph. Valid values: timeseries (default), treemap.

=back

=back

=cut

sub create
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();
	
	$self->_error_checks(
		mode => 'create',
		data => \%args,
	);

	my $url = $WebService::DataDog::API_ENDPOINT . 'dash';
	
	my $data = 
	{
		title       => $args{'title'},
		description => $args{'description'},
		graphs      => $args{'graphs'},
	};
	
	my $response = $self->_send_request(
			method => 'POST',
			url    => $url,
			data   => $data,
		);
	
	if ( !defined($response) || !defined($response->{'dash'}) )
	{
		croak "Fatal error. No response or 'dash' missing from response.";
	}
	
	return $response->{'dash'}->{'id'};
}


=head2 delete_dashboard()

Deprecated. Please use delete() instead.

=cut

sub delete_dashboard
{
	my ( $self, %args ) = @_;
	
	carp "delete_dashboard() is deprecated. Please use delete() instead.";
	
	return $self->delete( %args );
}


=head2 delete()

Delete specified user-created dashboard. 
NOTE: You cannot remove system-generated or integration dashboards.

	my $dashboard = $datadog->build('Dashboard');
	$dashboard->delete( id => $dash_id );
	
	
Parameters:

=over 4

=item * id

Dashboard id you want to delete.

=back

=cut

sub delete
{
	my ( $self, %args ) = @_;
	
	my $verbose = $self->verbose();
	
	# Check for mandatory parameters
	foreach my $arg ( qw( id ) )
	{
		croak "ERROR - Argument '$arg' is required for delete()."
			if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
	}
	
	# Check that id specified is a number
	croak "ERROR - invalid 'id' >" . $args{'id'} . "<. Dashboard id must be a number."
		unless $args{'id'} =~ /^\d+$/;
	
	my $url = $WebService::DataDog::API_ENDPOINT . 'dash' . '/' . $args{'id'};
	
	my $should_croak;
	try
	{
		$self->_send_request(
			method => 'DELETE',
			url    => $url,
			data   => { '' => [] }
		);
	}
	catch
	{
		if ( /404/ )
		{
			$should_croak = "Error 404 deleting dashboard id >" . $args{'id'} . "<. Are you sure this is the correct dashboard id?";
		}
	};
	croak $should_croak if $should_croak;
	
	return;
}


=head1 INTERNAL FUNCTIONS

=head2 _error_checks()

Common error checking for creating/updating dashboards/timeboards.

=cut

sub _error_checks
{
	my ( $self, %arguments ) = @_;
	my $verbose = $self->verbose();
	
	my $mode = $arguments{'mode'};
	my %args = %{ $arguments{'data'} };
	
	if ( $mode eq "update" )
	{
		# Check for mandatory parameters
		foreach my $arg ( qw( id ) )
		{
			croak "ERROR - Argument '$arg' is required for update()."
				if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
		}
		
		# Check that id specified is a number
		croak "ERROR - invalid 'id' >" . $args{'id'} . "<. Dashboard id must be a number."
			unless $args{'id'} =~ /^\d+$/;
		
		# Check that one update field was supplied
		if ( !defined( $args{'title'} ) && !defined( $args{'description'} ) && !defined( $args{'graphs'} ) )
		{
			croak "ERROR - you must supply at least one of the following arguments: title, description, graphs";
		}
	}
	elsif ( $mode eq "create" )
	{
		# Check for mandatory parameters
		foreach my $arg ( qw( title description graphs ) )
		{
			croak "ERROR - Argument '$arg' is required for create()."
				if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
		}
	}
	
	if ( defined( $args{'title'} ) && $args{'title'} eq '' )
	{
		croak "ERROR - you cannot have a blank dashboard title.";
	}
	
	# Check that title is <= 80 characters. Per Carlo @DDog. Undocumented?
	croak( "ERROR - invalid 'title' >" . $args{'title'} . "<. Title must be 80 characters or less." )
		if ( defined( $args{'title'} ) && length( $args{'title'} ) > 80 );
	
	# Check that description is <= 4000 characters. Per Carlo @DDog. Undocumented?
	croak( "ERROR - invalid 'description' >" . $args{'description'} . "<. Description must be 4000 characters or less." )
		if ( defined( $args{'description'} ) && length( $args{'description'} ) > 4000 );
	
	#TODO better graph error checking
	# ?? disallow any 'graph' section changes without additional config/force/etc?
	# - compare new definition vs existing. warn if any graphs are removed. print old definition?
	# - make sure all graph fields are specified: 
	#  title,  (255 char limit)
	#  definition: events, requests   (4000 char limit)
	#  viz?? (docs show it included in example, but not listed in fields, required or optional)
	if ( defined ( $args{'graphs'} ) )
	{
		croak "ERROR - 'graphs' argument must be an arrayref"
			if !Data::Validate::Type::is_arrayref( $args{'graphs'} );
		
		croak "ERROR - at least one graph definition is required for create()"
			if scalar( @{ $args{'graphs'} } == 0 );
			
		foreach my $graph_item ( @{ $args{'graphs'} } )
		{
			# Check for mandatory parameters
			foreach my $argument ( qw( title definition ) )
			{
				croak "ERROR - Argument '$argument' is required within each graph for create()."
					if !defined( $graph_item->{$argument} ) || ( $graph_item->{$argument} eq '' );
			}
		}
	}
	
	return;
}


1;
