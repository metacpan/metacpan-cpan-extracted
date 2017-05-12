package WebService::DataDog::Comment;

use strict;
use warnings;

use base qw( WebService::DataDog );
use Carp qw( carp croak );
use Data::Dumper;
use Try::Tiny;


=head1 NAME

WebService::DataDog::Comment - Interface to Comment functions in DataDog's API.

=head1 VERSION

Version 1.0.3

=cut

our $VERSION = '1.0.3';


=head1 SYNOPSIS

This module allows you interact with the Comment endpoint of the DataDog API.

Per DataDog: "Comments are how discussion happens on Datadog. You can create,
edit, delete and reply to comments. Comments are essentially special forms of
events that appear in the stream. They can start a new discussion thread or
optionally, reply in another thread."

NOTE: the 'handle' parameter must specify a user on the "team"
(https://app.datadoghq.com/account/team) associated with
your account, otherwise your update will fail with a 400 or 404 error


=head1 METHODS

=head2 create()

Create a new comment. This includes both starting a new thread as well as
replying to an existing comment (specified with the 'related_event_id' parameter).
	
	my $comment = $datadog->build('Comment');
	$comment->create(
		message          => $message,  # the comment text
		handle           => $handle,   # optional - handle of the user making the comment
FIXTHIS!		related_event_id => $event_id, # optional - the id of another comment or event to reply to
	);
	
	Example:
	$comment->create(
		message => 'My message goes here',
		handle  => 'user@example.com',
	);
	
Parameters:

=over 4

=item * message

Text of the comment.

=item * handle

Handle of the user making the comment.

=item * related_event_id   FIXTHIS!

The id of another comment or event to reply to.

=back

=cut

sub create
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();
	
	# Check for mandatory parameters
	foreach my $arg ( qw( message ) )
	{
		croak "ERROR - Argument '$arg' is required for create()."
			if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
	}
	
	if ( defined $args{'related_event_id'} && $args{'related_event_id'} !~ /^\d+$/ )
	{
		croak "ERROR - 'related_event_id' must be an integer";
	}

	my $url = $WebService::DataDog::API_ENDPOINT . 'comments';
	
	my $data = {
		message          => $args{'message'},
		handle           => defined $args{'handle'} ? $args{'handle'} : undef,
		related_event_id => defined $args{'related_event_id'} ? $args{'related_event_id'} : undef,
	};
	
	my $response = $self->_send_request(
		method => 'POST',
		url    => $url,
		data   => $data,
	);
	
	if ( !defined($response) || !defined($response->{'comment'}) )
	{
		croak "Fatal error. No response or 'comment' missing from response.";
	}
	
	return $response->{'comment'};
}


=head2 update()

Modify an existing comment.
	
	my $comment = $datadog->build('Comment');
	$comment->update(
		comment_id => $comment_id # id of existing comment
		message    => $message,   # comment text
		handle     => $handle,    # optional - handle of the user making the comment
	);
	
	Example:
	$comment->update(
		comment_id => $existing_comment,
		message    => 'My message goes here',
		handle     => 'user@example.com',
	);
	
Parameters:

=over 4

=item * comment_id

ID of existing comment.

=item * message

Text of the comment.

=item * handle

Handle of the user making the comment.

=back

=cut

sub update
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();
	
	# Check for mandatory parameters
	foreach my $arg ( qw( comment_id message ) )
	{
		croak "ERROR - Argument '$arg' is required for update()."
			if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
	}
	
	my $url = $WebService::DataDog::API_ENDPOINT . 'comments/' . $args{'comment_id'};
	
	my $data = {
		message    => $args{'message'},
		handle     => defined $args{'handle'} ? $args{'handle'} : undef,
	};
	
	my $response = $self->_send_request(
		method => 'PUT',
		url    => $url,
		data   => $data,
	);
	
	if ( !defined($response) || !defined($response->{'comment'}) )
	{
		croak "Fatal error. No response or 'comment' missing from response.";
	}
	
	return $response->{'comment'};
}


=head2 delete()

Delete an existing comment.
	
	my $comment = $datadog->build('Comment');
	$comment->delete( comment_id => $existing_comment );
	
Parameters:

=over 4

=item * comment_id

ID of existing comment to be deleted.

=back

=cut

sub delete
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();
	
	# Check for mandatory parameters
	foreach my $arg ( qw( comment_id ) )
	{
		croak "ERROR - Argument '$arg' is required for delete()."
			if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
	}
	
	my $url = $WebService::DataDog::API_ENDPOINT . 'comments/' . $args{'comment_id'};
	
	my $response = $self->_send_request(
		method => 'DELETE',
		url    => $url,
		data   => {},
	);
	
	return;
}


1;
