package WebService::Instagram;

use 5.006;
use strict;
use warnings;

use JSON;
use LWP::UserAgent;
use URI;
use Carp;
use Data::Dumper;
use HTTP::Request;
use Safe::Isa;

our $VERSION = '0.09';

use constant AUTHORIZE_URL 	=> 'https://api.instagram.com/oauth/authorize?';
use constant ACCESS_TOKEN_URL 	=> 'https://api.instagram.com/oauth/access_token?';

$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;

sub new {
	my ($class, $self) = @_;
	$self->{browser} ||= LWP::UserAgent->new();
	unless ( $self->{browser}->$_isa('LWP::UserAgent') ) {
		carp 'Browser is not a LWP::UserAgent';
	}
	bless $self, $class;
	return $self;
}

sub get_auth_url { 
	my $self = shift;
	carp "User already authorized with code: $self->{code}" if $self->{code};
	my @auth_fields = qw(client_id redirect_uri response_type);
	$self->{response_type} = 'code';
	foreach ( @auth_fields ) {
		confess "ERROR: $_ required for generating authorization URL." if (!defined $_);
	}
	#print Dumper $self->{client_id};

	my $uri = URI->new( AUTHORIZE_URL );
	$uri->query_form(
		map { $_ => $self->{$_} } @auth_fields,
	);

	return $uri->as_string();
}

sub set_code {
	my $self = shift;
	$self->{code} = shift || confess "Code not provided";
	return $self;
}

sub get_access_token {
	my $self = shift;
	my @access_token_fields = qw(client_id redirect_uri grant_type client_secret code);
	$self->{grant_type} = 'authorization_code';
	foreach ( @access_token_fields ) {
		confess "ERROR: $_ required for building access token." if (!defined $_);
	}
	my $params = {};
	@$params{ @access_token_fields } = @$self{ @access_token_fields };	
	
	my $uri = URI->new( ACCESS_TOKEN_URL );
        my $req = new HTTP::Request POST => $uri->as_string; 
        $uri->query_form($params);
        $req->content_type('application/x-www-form-urlencoded'); 
        $req->content($uri->query); 
        my $res = from_json($self->{browser}->request($req)->content); 
#	print Dumper $res;
#	$self->{access_token} = $res->{access_token};
	return $res->{access_token};
}

sub set_access_token {
	my $self = shift;
	$self->{access_token} = shift || die "No access token provided";
}

sub request {
	my ( $self, $url, $params ) = @_;
	croak "access_token not passed" unless defined $self->{access_token} ;
	$params->{access_token} = $self->{access_token};
	my $uri = URI->new( $url );
        $uri->query_form($params);
	my $response = $self->{browser}->get($uri->as_string);
	my $ret = $response->decoded_content;
	return decode_json $ret;
}

1; # End of WebService::Instagram
__END__

=head1 NAME

WebService::Instagram - Simple Interface to Instagram oAuth API

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

=head2 Step 1: Get the authorization URL:

Get the AUTH URL to authenticate,

	use WebService::Instagram;

	my $instagram = WebService::Instagram->new(
		{
			client_id	=> 'xxxxxxxxxxxxxxx',
			client_secret	=> 'xxxxxxxxxxxxxxx',
			redirect_uri	=> 'http://domain.com',
		}
	);

	my $auth_url = $instagram->get_auth_url();
	print Dumper $auth_url;

=head2 Step 2: Let the User authorize the API

Go to the above calculated URL in the browser, authenticate and save the code returned by the browser after authentication. You will need this to get access_token in Step 3.

The returned URL is usually of the form www.returnuri.com/?code=xxxxxxxxxxx

=head2 Step 3: Get and Set Access Token

Now using the code, fetch the access_token and set it to the object,

 	$instagram->set_code( $code ); #$code is fetched from Step 2.
	my $access_token = $instagram->get_access_token();

	#Set the access_token to $instagram object
	$instagram->set_access_token( $access_token );

=head2 Step 4: Fetch API Resources

Fetch the protected resource.
	
	#Get information about the owner of the access_token.
	my $search_result = $instagram->request( 'https://api.instagram.com/v1/users/self' );

=head1 SUBROUTINES/METHODS

=head2 get_auth_url

Returns the authorization URL that the user has to authorize against. Once authorized, the browser appends the C<code> along to the redirect URL which will used for obtaining access_token later.
=cut

=head2 get_access_token

Once you have the C<code>, you are ready to get the access_token. 

=cut

=head2 request

Since you now have the access token, you can request all the resources on behalf of the API. 
=cut

=head1 AUTHOR

Daya Sagar Nune, C<< <dayanune at cpan.org> >>

=head1 SUPPORT

This module's source and other documentation is hosted at: L<https://github.com/odem5442/WebService-Instagram>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Daya Sagar Nune.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
