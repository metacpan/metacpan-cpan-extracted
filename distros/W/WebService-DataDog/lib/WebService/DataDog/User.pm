package WebService::DataDog::User;

use strict;
use warnings;

use base qw( WebService::DataDog );
use Carp qw( carp croak );
use Data::Dumper;
use Try::Tiny;


=head1 NAME

WebService::DataDog::User - Interface to User functions in DataDog's API.

=head1 VERSION

Version 1.0.3

=cut

our $VERSION = '1.0.3';


=head1 SYNOPSIS

This module allows you interact with the user endpoint of the DataDog API.

Per DataDog: "You can invite users to join DataDog using the API."


=head1 METHODS

=head2 invite()

Invite users to join the Datadog service.
	
	my $user = $datadog->build('User');
	$user->invite(
		emails => $email_list,  # A list of 1+ email addresses 
	);
	
	Example:
	$user->invite(
		emails => [ 'user@example.com', 'user2@emailme.com' ]
	);
	
Parameters:

=over 4

=item * emails 

List of email addresses that should receive invitations.

=back

=cut

sub invite 
{
	my ( $self, %args ) = @_;
	my $verbose = $self->verbose();
	
	# Check for mandatory parameters
	foreach my $arg ( qw( emails ) )
	{
		croak "ERROR - Argument '$arg' is required for invite()."
			if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
	}
	
	if ( defined $args{'emails'} )
	{
		if ( !Data::Validate::Type::is_arrayref( $args{'emails'} ) )
		{
			croak "ERROR - invalid 'emails' value. Must be an arrayref.";
		}
		
	}

	my $url = $WebService::DataDog::API_ENDPOINT . 'invite_users';
	
	my $data = {
		emails => $args{'emails'},
	};
	
	my $response = $self->_send_request(
		method => 'POST',
		url    => $url,
		data   => $data,
	);
	
	if ( !defined($response) )
	{
		croak "Fatal error. No response";
	}
	
	return $response;
}


1;
