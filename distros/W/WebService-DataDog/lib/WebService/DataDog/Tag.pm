package WebService::DataDog::Tag;

use strict;
use warnings;

use base qw( WebService::DataDog );
use Carp qw( carp croak );
use Data::Dumper;
use Try::Tiny;


=head1 NAME

WebService::DataDog::Tag - Interface to Tag functions in DataDog's API.

=head1 VERSION

Version 1.0.3

=cut

our $VERSION = '1.0.3';


=head1 SYNOPSIS

This module allows you interact with the Tag endpoint of the DataDog API.

Per DataDog: "The tag end point allows you to tag hosts with keywords meaningful
to you - like role:database. All metrics sent from a host will have its tags
applied. When fetching and applying tags to a particular host, you can refer to
hosts by name (yourhost.example.com) or id (12345)."

NOTE: all methods, except retrieve_all(), operate on a per-host basis rather
than on a per-tag basis. You cannot rename a tag or delete a tag from all hosts,
through the DataDog API.


=head1 METHODS

=head2 retrieve_all()

Retrieve a mapping of tags to hosts.

	my $tag = $datadog->build('Tag');
	my $tag_host_list = $tag->retrieve_all();
	
Parameters: None

=cut

sub retrieve_all
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();
	
	my $url = $WebService::DataDog::API_ENDPOINT . 'tags/hosts';
	
	my $response = $self->_send_request(
		method => 'GET',
		url    => $url,
		data   => { '' => [] }
	);
	
	if ( !defined($response) || !defined($response->{'tags'}) )
	{
		croak "Fatal error. No response or 'tags' missing from response.";
	}
	
	return $response->{'tags'};
}


=head2 retrieve()

Return a list of tags for the specified host.
NOTE: a 404 response typically indicates you specified an incorrect/unknown
host name/id

	my $tag = $datadog->build('Tag');
	my $tag_list = $tag->retrieve( host => $host_name_or_id );
	
Parameters:

=over 4

=item * host

Hostname/host id you want to retrieve the tags for.

=back

=cut

sub retrieve
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();
	
	# Check for mandatory parameters
	foreach my $arg ( qw( host ) )
	{
		croak "ERROR - Argument '$arg' is required for retrieve()."
			if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
	}
	
	my $url = $WebService::DataDog::API_ENDPOINT . 'tags/hosts' . '/' . $args{'host'};
	
	my $response = $self->_send_request(
		method => 'GET',
		url    => $url,
		data   => { '' => [] }
	);
	
	if ( !defined($response) || !defined($response->{'tags'}) )
	{
		croak "Fatal error. No response or tag 'tags' missing from response.";
	}
	
	return $response->{'tags'};
}


=head2 update()

Update tags for specified host.
NOTE: a 404 response typically indicates you specified an incorrect host name/id.
WARNING: you must specify all tags that you want attached to this host, not
simply new ones you want to add ( use add() for that, instead ).
	
	my $tag = $datadog->build('Tag');
	$tag->update(
		host => $host,  # name/ID of host to modify
		tags => $tag_list, # Updated full list of tags to apply to host
	);
	
	Example:
	$tag->update(
		host => 'my.example.com',
		tags => [ 'tag1', 'tag2', 'tag3:val' ],
	);
	
Parameters:

=over 4

=item * host

Host name/id whose tags you want to modify.

=item * tags

List of tags to apply to host. This must be the full list you want applied,
including any already applied.

=back

=cut

sub update
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();
	
	# Check for mandatory parameters
	foreach my $arg ( qw( host tags ) )
	{
		croak "ERROR - Argument '$arg' is required for update()."
			if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
	}
	
	$self->_error_checks( %args );
	
	my $url = $WebService::DataDog::API_ENDPOINT . 'tags/hosts' . '/' . $args{'host'};
	
	my $response = $self->_send_request(
		method => 'PUT',
		url    => $url,
		data   => { tags => $args{'tags'} }
	);
	
	if ( !defined($response) || !defined($response->{'tags'}) )
	{
		croak "Fatal error. No response or tag 'tags' missing from response.";
	}
	
	return $response->{'tags'};
}



=head2 add()

Add tags to specified host.
NOTE: a 404 response typically indicates you specified an incorrect host name/id.
	
	my $tag = $datadog->build('Tag');
	$tag->add(
		host => $host,  # name/ID of host to modify
		tags => $tag_list, # Updated full list of tags to apply to host
	);
	
	Example:
	$tag->add(
		host => 'my.example.com',
		tags => [ 'tag3:val' ],
	);
	
Parameters:

=over 4

=item * host

Host name/id whose tags you want to modify.

=item * tags

List of new tags to apply to existing tags on specified host.

=back

=cut

sub add
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();
	
	# Check for mandatory parameters
	foreach my $arg ( qw( host tags ) )
	{
		croak "ERROR - Argument '$arg' is required for add()."
			if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
	}
	
	$self->_error_checks( %args );
	
	my $url = $WebService::DataDog::API_ENDPOINT . 'tags/hosts' . '/' . $args{'host'};
	
	my $response = $self->_send_request(
		method => 'POST',
		url    => $url,
		data   => { tags => $args{'tags'} }
	);
	
	if ( !defined($response) || !defined($response->{'tags'}) )
	{
		croak "Fatal error. No response or tag 'tags' missing from response.";
	}
	
	return $response->{'tags'};
}


=head2 delete()

Delete all tags from the specified host.

	my $tag = $datadog->build('Tag');
	$tag->delete( host => $host );
	
Parameters:

=over 4

=item * host

Host name/id whose tags you want to delete.

=back

=cut

sub delete
{
	my ( $self, %args ) = @_;
	
	my $verbose = $self->verbose();
	
	# Check for mandatory parameters
	foreach my $arg ( qw( host ) )
	{
		croak "ERROR - Argument '$arg' is required for delete()."
			if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
	}
	
	my $url = $WebService::DataDog::API_ENDPOINT . 'tags/hosts' . '/' . $args{'host'};
	
	$self->_send_request(
		method => 'DELETE',
		url    => $url,
		data   => { '' => [] }
	);
	
	return;
}


=head1 INTERNAL FUNCTIONS

=head2 _error_checks()

Common error checking for adding/updating tags.

=cut

sub _error_checks
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();
	
	# 'tags' argument is valid
	if ( !Data::Validate::Type::is_arrayref( $args{'tags'} ) )
	{
		croak "ERROR - invalid 'tags' value. Must be an arrayref.";
	}
	
	#TODO centralize this error checking, since it's nearly identical to Metric.pm
	foreach my $tag ( @{ $args{'tags'} } )
	{
		# must start with a letter
		croak( "ERROR - invalid tag >" . $tag . "< on host >" . $args{'host'} . "<. Tags must start with a letter, a-z. Not sending." )
			if ( $tag !~ /^[a-zA-Z]/ );
		
		# must be 200 characters max
		croak( "ERROR - invalid tag >" . $tag . "< on host >" . $args{'host'} . "<. Tags must be 200 characters or less. Not sending." )
			if ( length( $tag ) > 200 );
		
		# NOTE: This check isn't required by DataDog, they will allow this through.
		# However, this tag will not behave as expected in the graphs, if we were to allow it.
		croak( "ERROR - invalid tag >" . $tag . "< on host >" . $args{'host'} . "<. Tags should only contain a single colon (:). Not sending." )
			if ( $tag =~ /^\S+:\S+:/ );
	}
	
	return;
}


1;