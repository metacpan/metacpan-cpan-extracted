package WebService::DataDog::Alert;

use strict;
use warnings;

use base qw( WebService::DataDog );
use Carp qw( carp croak );
use Data::Dumper;
use Try::Tiny;


=head1 NAME

WebService::DataDog::Alert - Interface to Alert functions in DataDog's API.

=head1 VERSION

Version 1.0.3

=cut

our $VERSION = '1.0.3';


=head1 SYNOPSIS

This module allows you interact with the Alert endpoint of the DataDog API.

Per DataDog: "Alerts allow you to watch a particular metric query and receive a
notification when the value either exceeds or falls below the pre-defined threshold."


=head1 METHODS

=head2 retrieve_all()

Retrieve details for all alerts.

	my $alert = $datadog->build('Alert');
	my $alert_list = $alert->retrieve_all();
	
Parameters: None

=cut

sub retrieve_all
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();
	
	my $url = $WebService::DataDog::API_ENDPOINT . 'alert';
	
	my $response = $self->_send_request(
		method => 'GET',
		url    => $url,
		data   => { '' => [] }
	);
	
	if ( !defined($response) || !defined($response->{'alerts'}) )
	{
		croak "Fatal error. No response or 'alerts' missing from response.";
	}
	
	return $response->{'alerts'};
}


=head2 create()

Create new DataDog alert for specified metric query.
If successful, returns created alert id.

NOTE: 'silenced' seems to have no effect in create mode, but works fine in update/edit mode.

	my $alert = $datadog->build('Alert');
	my $alert_id = $alert->create(
		query    => $query,      # Metric query to alert on
		name     => $alert_name, # Optional. default=dynamic, based on query
		message  => $message,    # Optional. default=None
		silenced => $boolean,    # Optional. default=0
	);
	
	Example:
	my $alert_id = $alert->create(
			query    => "sum(last_1d):sum:system.net.bytes_rcvd{host:host0} > 100",
			name     => "Bytes received on host0",
			message  => "We may need to add web hosts if this is consistently high.",
		);
	
Parameters:

=over 4

=item * query

Metric query to alert on.

=item * name

Optional. Name of the alert. Default = dynamic, based on query.

=item * message

Optional. A message to include with notifications for this alert. Email
notifications can be sent to specific users by using the same '@username'
notation as events.

=item * silenced

Optional. Default = false. Whether the alert should notify by email and in the
event stream. An alert with 'silenced' set to True is effectively muted. The
alert will continue to detect state changes, but they will only be visible on
the alert list page.

=back

=cut

sub create
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();
	
	# Check for mandatory parameters
	foreach my $arg ( qw( query ) )
	{
		croak "ERROR - Argument '$arg' is required for create()."
			if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
	}
	
	# Error checks, common to create() and update()
	$self->_error_checks( %args );
	
	my $url = $WebService::DataDog::API_ENDPOINT . 'alert';
	
	my $data = 
	{
		query => $args{'query'},
	};
	
	if ( defined( $args{'name'} ) && $args{'name'} ne '' )
	{
		$data->{'name'} = $args{'name'};
	}
	
	if ( defined( $args{'message'} ) && $args{'message'} ne '' )
	{
		$data->{'message'} = $args{'message'};
	}
	
	if ( defined( $args{'silenced'} ) && $args{'silenced'} ne '' )
	{
		# You must use references to integers in order to have JSON.pm properly
		# encode these as JSON boolean values. Without this, JSON will encode integer
		# value as string...which is how I found this fix, when it happened to me.
		# Reference: http://stackoverflow.com/questions/1087308/why-cant-i-properly-encode-a-boolean-from-postgresql-via-jsonxs-via-perl
		$data->{'silenced'} = ( $args{'silenced'} == 0 ? \0: \1 );
	}
	
	my $response = $self->_send_request(
			method => 'POST',
			url    => $url,
			data   => $data,
		);
	
	if ( !defined($response) || !defined($response->{'state'}) || $response->{'state'} ne 'OK' )
	{
		croak "Fatal error. No response or missing/invalid state in response.";
	}
	
	return $response->{'id'};
}



=head2 retrieve()

Retrieve details for specified alert.
NOTE: a 404 response typically indicates you specified an incorrect alert id.

	my $alert = $datadog->build('Alert');
	my $alert_data = $alert->retrieve( id => $alert_id );
	
Parameters:

=over 4

=item * id

Id of alert you want to retrieve the details for.

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
	croak "ERROR - invalid 'id' >" . $args{'id'} . "<. Alert id must be a number."
		unless $args{'id'} =~ /^\d+$/;
	
	my $url = $WebService::DataDog::API_ENDPOINT . 'alert' . '/' . $args{'id'};
	
	my $response = $self->_send_request(
		method => 'GET',
		url    => $url,
		data   => { '' => [] }
	);
	
	if ( !defined($response) || !defined($response->{'id'}) )
	{
		croak "Fatal error. No response or alert 'id' missing from response.";
	}
	
	return $response;
}


=head2 update()

Update existing DataDog alert for specified alert id.
NOTE: a 404 response typically indicates you specified an incorrect alert id.

	my $alert = $datadog->build('Alert');
	$alert->update(
		id       => $alert_id,   # ID of alert to modify
		query    => $query,      # Metric query to alert on
		name     => $alert_name, # Optional.
		message  => $message,    # Optional.
		silenced => $boolean,    # Optional.
	);
	
	Example:
	# Change name of existing alert
	$alert->update(
		id    => $alert_id,
		name  => "Bytes received on host0",
	);
	
Parameters:

=over 4

=item * id

ID of alert you want to modify.

=item * query

Metric query to alert on.

=item * name

Optional. Name of the alert.

=item * message

Optional. A message to include with notifications for this alert. Email
notifications can be sent to specific users by using the same '@username'
notation as events.

=item * silenced

Optional.Whether the alert should notify by email and in the
event stream. An alert with 'silenced' set to True is effectively muted. The
alert will continue to detect state changes, but they will only be visible on
the alert list page.

=back

=cut

sub update
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();
	
	# Check for mandatory parameters
	foreach my $arg ( qw( id query ) )
	{
		croak "ERROR - Argument '$arg' is required for update()."
			if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
	}
	
	# Error checks, common to create() and update()
	$self->_error_checks( %args );
	
	my $original_alert = $self->retrieve( id => $args{'id'} );
	
	my $url = $WebService::DataDog::API_ENDPOINT . 'alert' . '/' . $args{'id'};
	
	# Populate with original details, otherwise the values will be lost
	my $data = 
	{
		query    => $args{'query'},
		name     => $original_alert->{'name'},
		message  => $original_alert->{'message'},
		silenced => $original_alert->{'silenced'},
	};
	
	# Overwrite original details with any updated fields
	if ( defined( $args{'name'} ) && $args{'name'} ne '' )
	{
		$data->{'name'} = $args{'name'};
	}
	
	if ( defined( $args{'message'} ) && $args{'message'} ne '' )
	{
		$data->{'message'} = $args{'message'};
	}
	
	if ( defined( $args{'silenced'} ) && $args{'silenced'} ne '' )
	{
		# You must use references to integers in order to have JSON.pm properly
		# encode these as JSON boolean values. Without this, JSON will encode integer
		# value as string...which is how I found this fix, when it happened to me.
		# Reference: http://stackoverflow.com/questions/1087308/why-cant-i-properly-encode-a-boolean-from-postgresql-via-jsonxs-via-perl
		$data->{'silenced'} = ( $args{'silenced'} == 0 ? \0: \1 );
	}
	
	my $response = $self->_send_request(
			method => 'PUT',
			url    => $url,
			data   => $data,
		);
	
	if ( !defined($response) || !defined($response->{'state'}) || $response->{'state'} ne 'OK' )
	{
		croak "Fatal error. No response or missing/invalid state in response.";
	}
	
	return;
}


=head2 mute_all()

Mute all alerts.
"Muting will prevent all alerts from notifying through email and posts to the
event stream. State changes will only be visible by checking the alert page."

	my $alert = $datadog->build('Alert');
	$alert->mute_all();
	
Parameters: None

=cut

sub mute_all
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();
	
	my $url = $WebService::DataDog::API_ENDPOINT . 'mute_alerts';
	
	$self->_send_request(
		method => 'POST',
		url    => $url,
		data   => { '' => [] }
	);
	
	return;
}


=head2 unmute_all()

Unmute all alerts.

	my $alert = $datadog->build('Alert');
	$alert->unmute_all();
	
Parameters: None

=cut

sub unmute_all
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();
	
	my $url = $WebService::DataDog::API_ENDPOINT . 'unmute_alerts';
	
	$self->_send_request(
		method => 'POST',
		url    => $url,
		data   => { '' => [] }
	);
	
	return;
}


=head2 delete()

Delete specified alert.

	my $alert = $datadog->build('Alert');
	$alert->delete( id => $alert_id );
	
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
	croak "ERROR - invalid 'id' >" . $args{'id'} . "<. Alert id must be a number."
		unless $args{'id'} =~ /^\d+$/;
	
	my $url = $WebService::DataDog::API_ENDPOINT . 'alert' . '/' . $args{'id'};
	
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
			$should_croak = "Error 404 deleting alert id >" . $args{'id'} . "<. Are you sure this is the correct alert id?";
		}
	};
	croak $should_croak if $should_croak;
	
	return;
}


=head1 INTERNAL FUNCTIONS

=head2 _error_checks()

Common error checking for creating/updating alerts.

=cut

sub _error_checks
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();
	
	# Check that name is <= 80 characters. Undocumented limitation.  A name of 81 chars results in '400 Bad Request'.
	croak( "ERROR - invalid 'name' >" . $args{'name'} . "<. Name must be 80 characters or less." )
		if ( defined( $args{'name'} ) && length( $args{'name'} ) > 80 );
	
	# Check that 'silenced' is a boolean.
	croak( "ERROR - invalid 'silenced' value >" . $args{'silenced'} . "<. Must specify 0 (false) or 1 (true).")
		if ( defined( $args{'silenced'} ) && $args{'silenced'} !~ /^[01]$/ );
	
	return;
}


1;
