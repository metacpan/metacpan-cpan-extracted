package VUser::Google::ApiProtocol::V2_0;
use warnings;
use strict;

use XML::Simple;
use LWP::UserAgent qw(:strict);
use HTTP::Request qw(:strict);
use Encode;
use Carp;

use Data::Dumper;

use Moose;
extends 'VUser::Google::ApiProtocol';

our $VERSION = '0.5.1';

has 'google_host' => (is => 'ro',
		     default => 'www.google.com'
		     );

has 'google_token_url' => (is => 'ro',
			   default => 'https://www.google.com/accounts/ClientLogin'
			   );

has 'max_token_age' => (is => 'ro',
			default => 86400
			);

# base url to the Google REST API
has 'google_baseurl' => (is => 'ro',
			 default => 'https://www.google.com/a/feeds/'
			 );

has 'google_apps_schema' => (is => 'ro',
			     default => 'http://schemas.google.com/apps/2006'
			     );

has 'success_code' => (is => 'ro',
		       default => 'Success(2000)'
		       );

has 'failure_code' => (is => 'ro',
		       default => 'Failure(2001)'
		       );

has 'max_name_length' => (is => 'ro', default => '40');

has 'max_username_length' => (is => 'ro', default => '30');

override 'Login' => sub {
    my $self = shift;

    #print STDERR "LOGIN: debug=".$self->debug."\n";

    $self->dprint("Relogin called");

    return 1 if $self->IsAuthenticated() and not $self->refresh_token();

    my $retval = 0;
    my $stats = $self->stats();
    $stats->{logins}++;

    ## Clear last results
    $self->_set_reply_headers('');
    $self->_set_reply_content('');
    $self->_set_result({});

    ## Create an LWP object to make the HTTP POST request
    my $lwp = LWP::UserAgent->new;

    if (defined $lwp) {
	$lwp->agent($self->useragent);
	$lwp->from($self->admin.'@'.$self->domain);

	# Submit the request with values for
	# accountType, Email and Passwd variables
	my $response = $lwp->post($self->google_token_url,
				  ['accountType' => 'HOSTED',
				   'Email' => $self->admin.'@'.$self->domain,
				   'Passwd' => $self->password,
				   'service' => 'apps'
				   ]
				  );

	# save the reply page
	$self->_set_reply_headers($response->headers->as_string);
	$self->_set_reply_content($response->content);

	if ($response->is_success) {
	    # Extract the authentication token from the response
	    foreach my $line (split(/\n/, $response->content)) {
		$self->dprint("RECV'd: $line");
		if ($line =~ m/^Auth=(.+)$/) {
		    $self->_set_authtoken($1);
		    $self->_set_authtime(time());
		    $self->dprint("Token found: %s", $self->authtoken);
		    # Clear refresh
		    $self->refresh_token(0);
		    $retval = 1;
		    last;
		}
	    }
	}
	else {
	    $self->dprint("Error in login: %s", $response->status_line);
	    $self->_set_result({reason => "Error in login: ".$response->status_line});
	}
    }
    else {
	$self->dprint("Error getting LWP object: $!");
	$self->_set_result({reason => "Error getting LWP object: $!"});
    }

    $self->_set_stats($stats);
    return $retval;
};

override 'IsAuthenticated' => sub {
    #get object reference
    my $self = shift();
    
    my $token_age = time - $self->authtime();
    if( $self->refresh_token() or ( $token_age > $self->max_token_age() ) ) {
	$self->dprint("Refresh token: %s; time-auth: %d; max_age: %d",
		      $self->refresh_token, $token_age, $self->max_token_age);
	return 0;
    }
    #we are still okay!
    return 1;

};

override 'Request' => sub {
    my $self = shift;

    my $retval = 0;

    $self->dprint( "*** REQUEST ***" );

    # relogin if needed
    $self->Login;

    # clear last results
    $self->_set_reply_headers('');
    $self->_set_reply_content('');
    $self->_set_result({});

    if (@_ != 2 and @_ != 3) {
	$self->_set_result({reason => 'Invalid number of arguments to Request()'});
	return 0;
    }

    # get paramters
    my ($method, $url, $body) = @_;
    $self->dprint("Method: $method; URL: $url");
    $self->dprint("Body: $body") if $body;

    ## Keep some stats
    my $stats = $self->stats;
    $stats->{requests}++;
    $stats->{rtime} = time;

    ## Check if we are authenticated to google
    if (not $self->IsAuthenticated()) {
	$self->dprint("Error autheticating");
	$self->_set_stats($stats);
	return 0;
    }

    ## Properly encode the body
    $body = encode('UTF-8', $body);

    ## Create an LWP object to make the HTTP POST request
    my $ua = LWP::UserAgent->new;
    if (not defined $ua) {
	$self->dprint("Cannot create LWP::UserAgent: $!");
	$self->_set_result({reason => "Cannotcreate LWP::UserAgent in Request: $!"});
	$self->_set_stats($stats);
	return 0;
    }

    #and create the request object where are we connecting to
    # v2.0 uses a diffent url based what's being done.
    # The API methods will construct the URL becuase action specific
    # information, such as domain and user, is embedded with it.
    # v2.0 use different methods depending on the action
    # It's up to the API methods to know which method to use
    my $req = HTTP::Request->new($method => $url);
    if (not defined $req) {
	$self->dprint("Cannot create HTTP::Request object: $!");
	$self->_set_result({reason => "Cannot create HTTP::Request object in Request(): $!"});
	$self->_set_stats($stats);
	return $retval;
    }

    # Set some user agent variables
    $ua->agent($self->useragent);
    $ua->from('<'.$self->admin.'@'.$self->domain.'>');

    # Submit the request
    $req->header('Accept' => 'application/atom+xml');
    $req->header('Content-Type' => 'application/atom+xml');
    if ($body) {
	$req->header('Content-Length' => length($body) );
    }
    $req->header('Connection' => 'Keep-Alive');
    $req->header('Host' => $self->google_host);
    $req->header('Authorization' => 'GoogleLogin auth='.$self->authtoken);

    # Assign the data to the request
    #  Perhaps if $method eq 'GET' or 'DELETE' would be better
    if ($body) {
	$req->content($body);
    }

    ## Execute the request
    my $response = $ua->request($req);
    $self->dprint(Data::Dumper::Dumper($response));

    # Save reply page
    $self->_set_reply_headers($response->headers->as_string);
    $self->_set_reply_content($response->content);

    # Check result
    if ($response->is_success) {
	$stats->{success}++;
	$self->dprint("Success in post:");

	my $xml = decode('UTF-8', $response->content);
	$self->dprint($xml);

	if ($xml) {
	    ## Parse the XML using XML::Simple
	    my $simple = XML::Simple->new(ForceArray => 1);
	    $self->_set_result($simple->XMLin($xml));
	    $self->dprint(Dumper($self->{result}));
	}
	else {
	    $self->_set_result({});
	}

	$self->dprint("Google API success!");
	$retval = 1;
    }
    else {
	# OK. Funky issue. When trying to get a user that doesn't exist,
	# Google throws a 400 error instead of returning a error document.
	
	# Google has fun. If there is a problem with the request,
	# google triggers a 400 error which then fails on ->is_success.
	# So, we need to check the content anyway to see if there is a
	# reason for the failure.
	$self->dprint("Google API failure!");
	my $xml = decode('UTF-8', $response->content);
	$self->dprint($xml);
	if ($xml) {
	    my $simple = XML::Simple->new(ForceArray => 1);
	    $self->_set_result($simple->XMLin($xml));
	    $self->dprint('Error result: %s', Dumper($self->result));
	}

	if (defined ($self->result()->{error}[0]{reason})) {
	    my $error = sprintf("Google API failure: %s - %s",
				$self->result()->{error}[0]{errorCode},
				$self->result()->{error}[0]{reason}
				);
	    $self->dprint($error);
	    my $res = $self->result;
	    $res->{reason} = $error;
	    $self->_set_result($res);
	}
	else {
	    $self->dprint("Error in post: %s", $response->status_line);
	    my $res = $self->result;
	    $res->{reason} = "Error in post: ".$response->status_line;
	    $self->_set_result($res);
	}
    }

    return $retval;
};

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

VUser::Google::ApiProtocol::V2_0 - Implements version 2.0 of the Google APIs.

=head1 SYSNOPSIS

 use VUser::Google::ApiProtocol::V2_0;
 
 ## Create a new connection
 my $google = VUser::Google::ApiProtocol::V2_0->new(
     domain   => 'your.google-apps-domain.com',
     admin    => 'admin_user',
     password => 'admin_user password',
 );
 
 ## Login to the Google Apps API
 # Login() uses the credentials provided in new()
 $google->Login();
 
 ## Create a new request
 # Create the URL to send to API request to.
 # See the API docs for the valid URLs
 my $url = "https://apps-apis.google.com/a/feeds/emailsettings/2.0/"
 $url   .= "your.google-apps-domain.com/username/label";
 
 # Create XML message to send to Google
 # See the API docs for the valid XML to send
 my $xml = '<?xml version="1.0" encoding="utf-8"?>...';
 
 # NB: The method (POST here) may be different depending on API call
 my $success = $google->Request('POST', $url, $xml);
 
 # Get the parsed response
 if ($success) {
     # $result is the XML reply parsed by XML::Simple
     my $result = $google->get_result;
 }
 else {
     # $result is the error message from google
     # parsed by XML::Simple with the addition of a
     # 'reason' key which contains the error.
     my $result = $google->get_result;
     die "Error: $result->{reason}";
 }

=head1 DESCRIPTION

Implements version 2.0 of the Google API. See L<VUser::Google::ApiProtocol>
for a list of members and methods.

=head1 SEE ALSO

L<VUser::Google::ApiProtocol>, L<XML::Simple>

=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

Adapted from code from Johan Reinalda <johan@reinalda.net>

=head1 LICENSE

Copyright (C) 2006 by Johan Reinalda, johan at reinalda dot net
Copyright (C) 2009 by Randy Smith, perlstalker at vuser dot org

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

If you make useful modification, kindly consider emailing then to me for inclusion in a future version of this module.

=cut
