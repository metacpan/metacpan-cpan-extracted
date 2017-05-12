package WWW::SEOGears;

use 5.008;
use strict;
use Carp qw(carp croak);
use Data::Dumper;
use English qw(-no_match_vars);
use List::Util qw(first);
use warnings FATAL => 'all';

use Date::Calc qw(Add_Delta_YMDHMS Today_and_Now);
use HTTP::Tiny;
use JSON qw(decode_json);
use URI::Escape qw(uri_escape);

=head1 NAME

WWW::SEOGears - Perl Interface for SEOGears API.

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.05';

## no critic (ProhibitConstantPragma)
use constant VALID_MONTHS => {
	'1'  => 'monthly',
	'12' => 'yearly',
	'24' => 'bi-yearly',
	'36' => 'tri-yearly'
};
## use critic

=head1 SYNOPSIS

This module provides you with an perl interface to interact with the Seogears API.

	use WWW::SEOGears;
	my $api = WWW::SEOGears->new( { 'brandname' => $brandname,
	                                'brandkey' => $brandkey,
	                                'sandbox' => $boolean 
	});
	$api->newuser($params_for_newuser);
	$api->statuscheck($params_for_statuscheck);
	$api->inactivate($params_for_inactivate);
	$api->update($params_for_update);
	$api->get_tempauth($params_for_update);

=head1 SUBROUTINES/METHODS

=head2 new

Constructor.

B<Input> takes a hashref that contains:

	Required:

	brandname  => Brandname as listed on seogears' end.
	brandkey   => Brandkey received from seogears.
	
	Will croak if the above keys are not present.

	Optional:
	sandbox    => If specified the sandbox API url is used instead of production.
	http_opts  => Hashref of options that are passed on to the HTTP::Tiny object that is used internally.
	              Example value: { 'agent' => 'WWW-SEOGears', 'timeout' => 20, 'verify_SSL' => 0, 'SSL_options' => {'SSL_verify_mode' => 0x00} }

	Deprecated (will be dropped in the upcoming update): Will emit a warning if used.
	lwp        => hash of options for LWP::UserAgent - will be converted to their corresponding HTTP::Tiny options.
	              Example value: {'parse_head' => 0, 'ssl_opts' => {'verify_hostname' => 0, 'SSL_verify_mode' => 0x00}}

=cut

sub new {

	my ($class, $opts) = @_;

	my $self = {};
	bless $self, $class;

	$self->{brandname} = delete $opts->{brandname} or croak('brandname is a required parameter');
	$self->{brandkey}  = delete $opts->{brandkey}  or croak('brandkey is a required parameter');

	# API urls
	$self->{authurl}  = 'https://seogearstools.com/api/auth.html';
	$self->{loginurl} = 'https://seogearstools.com/api/login.html';
	if (delete $opts->{sandbox}) {
		$self->{userurl} = 'https://seogearstools.com/api/user-sandbox.html';
	} else {
		$self->{userurl} = 'https://seogearstools.com/api/user.html';
	}

	# Set up the UA object for the queries
	my $http_opts;
	if (exists $opts->{lwp}) {
		carp(
			"*******************************************************************\n".
			"You are using the deprecated option: 'lwp' intended for LWP::UserAgent\n".
			"Please update your code to use http_opts instead, which takes in options for HTTP::Tiny\n".
			"The passed in options will be converted to HTTP::Tiny options, but not all options will translate to properly.\n".
			"This might cause unforeseen issues, so please test fully before using this in production.\n".
			"*******************************************************************\n".
			" "
		);
		$http_opts = _translate_lwp_to_http_opts($opts->{lwp});
	} elsif (exists $opts->{http_opts}) {
		$http_opts = $opts->{http_opts};
	}
	$http_opts->{agent} ||= 'WWW-SEOGears '.$VERSION;
	$self->{_ua}  = HTTP::Tiny->new(%{$http_opts});

	return $self;
}

=head2 newuser

Creates a new user via the 'action=new' API call.
Since the 'userid' and 'email' can be used to fetch details about the seogears account, storing these values locally is recommended.

B<Input> Requires that you pass in the following parameters for the call:

	userid    => '123456789'
	email     => 'test1@testing123.com'
	name      => 'Testing User'
	phone     => '1.5552223333'
	domain    => 'somedomain.com'
	rep       => 'rep@domain.com'
	placement => 'reg'
	pack      => '32'
	price     => '14.99'
	months    => '12'

Croaks if it is unable to sanitize the %params passed successfully, or the HTTP request to the API fails.

B<Output> Hash containing the data returned by the API:

	"success"   => 1
	"authkey"   => "GB0353566P163045n07157LUFGZntgqNF042MO692S19567CIGHj727437179300tE5nt8C362803K686Yrbj4643zausyiw"
	"bzid"      => "30928"
	"debuginfo" => "Success"
	"message"   => "New Account Created"

=cut

sub newuser {

	my ($self, $params) = @_;
	$self->_sanitize_params('new', $params) or $self->_error('Failed to sanitize params. "'.$self->get_error, 1);
	$params->{'brand'}    = $self->get_brandname;
	$params->{'brandkey'} = $self->get_brandkey;

	return $self->_make_request_handler('new', $params);
}

=head2 statuscheck

Fetches information about a user via the 'action=statuscheck' API call.

B<Input> Requires that you pass in the following parameters for the call:

	userid    => '123456789'
	email     => 'test1@testing123.com'

Croaks if it is unable to sanitize the %params passed successfully, or the HTTP request to the API fails.

B<Output> Hash containing the data returned by the API:

	"success"   =>  1,
	"inactive"  => "0"
	"authkey"   => "WO8407914M283278j87070OPWZGkmvsEG847ZB845Q28584YSBDt684478133472pV3ws1X655571X005Zlhh6810hsxjjka"
	"bzid"      => "30724"
	"brand"     => "brandname"
	"message"   => User is active. See variables for package details."
	"expdate"   => "2014-01-01 12:00:00"
	"debuginfo" => "User exists. See variables for status and package details."
	"pack"      => "32"
	"price"     => "14.99"
	"months"    => "12"

=cut

sub statuscheck {

	my ($self, $params) = @_;
	$self->_sanitize_params('statuscheck', $params) or $self->_error('Failed to sanitize params. "'.$self->get_error, 1);

	return $self->_make_request_handler('statuscheck', $params);
}

=head2 inactivate

Inactivates a user via the 'action=inactivate' API call.

B<Input> Requires that you pass in the following parameters for the call:

	"bzid"      => "30724"
	"authkey"   => "WO8407914M283278j87070OPWZGkmvsEG847ZB845Q28584YSBDt684478133472pV3ws1X655571X005Zlhh6810hsxjjka"

Croaks if it is unable to sanitize the %params passed successfully, or the HTTP request to the API fails.

B<Output> Hash containing the data returned by the API:

	'success'   => 1,
	'bzid'      => '30724',
	'debuginfo' => 'Success BZID30724 WO8407914M283278j87070OPWZGkmvsEG847ZB845Q28584YSBDt684478133472pV3ws1X655571X005Zlhh6810hsxjjka'

=cut

sub inactivate {

	my ($self, $params) = @_;
	$self->_sanitize_params('inactivate', $params) or $self->_error('Failed to sanitize params. "'.$self->get_error, 1);

	return $self->_make_request_handler('inactivate', $params);
}

=head2 activate

Activates a previously inactivated user via the 'action=activate' API call.

B<Input> Requires that you pass in the following parameters for the call:

	'bzid' => '32999'
	'authkey' => 'BC1052837T155165x75618ZUKZDlbpfMW795RS245L23288ORUUq323360091155yP1ng7E548072L030Zssq0043pldkebf'

Croaks if it is unable to sanitize the %params passed successfully, or the HTTP request to the API fails.

B<Output> Hash containing the data returned by the API:

	'success' => 1,
	'bzid' => '32999',
	'debuginfo' => 'Success BZID32999 BC1052837T155165x75618ZUKZDlbpfMW795RS245L23288ORUUq323360091155yP1ng7E548072L030Zssq0043pldkebf'

=cut

sub activate {

	my ($self, $params) = @_;
	$self->_sanitize_params('activate', $params) or $self->_error('Failed to sanitize params. "'.$self->get_error, 1);

	return $self->_make_request_handler('activate', $params);
}

=head2 update

Updates/Renews a user via the 'action=update' API call.

B<Input> Requires that you pass in the following parameters for the call:

	"bzid"      => "30724"
	"authkey"   => "WO8407914M283278j87070OPWZGkmvsEG847ZB845Q28584YSBDt684478133472pV3ws1X655571X005Zlhh6810hsxjjka"

	Optional params:
	"email"     => "newemail@testing123.com"
	"phone"     => "1.5552224444"
	"pack"      => "33"
	"months"    => "24"
	"price"     => "14.99"

If pack is specified, then a price must be specified along with it.

Croaks if it is unable to sanitize the %params passed successfully, or the HTTP request to the API fails.

B<Output> Hash containing the data returned by the API:

	'success' => 1,
	'bzid' => '30724',
	'debuginfo' => 'Success'

=cut

sub update {

	my ($self, $params) = @_;
	$self->_sanitize_params('update', $params) or $self->_error('Failed to sanitize params. "'.$self->get_error, 1);

	return $self->_make_request_handler('update', $params);
}

=head2 get_tempauth

Retrieves the tempauth key for an account from the API.

B<Input> Requires that you pass in the following parameters for the call:

	bzid      => '31037'
	authkey   => 'HH1815009C705940t76917IWWAQdvyoDR077CO567M05324BHUCa744638889409oM8kw5E097737M626Gynd3974rsetvzf'

Croaks if it is unable to sanitize the %params passed successfully, or the HTTP request to the API fails.

B<Output> Hash containing the data returned by the API:

	'success'     => 1,
	'bzid'        => '31037',
	'tempauthkey' => 'OU8937pI03R56Lz493j0958US34Ui9mgJG831JY756X0Tz04WGXVu762IuIxg7643vV6ju9M96J951V430Qvnw41b4qzgp2pu',
	'message'     => ''

=cut

sub get_tempauth {

	my ($self, $params) = @_;
	$self->_sanitize_params('auth', $params) or $self->_error('Failed to sanitize params. "'.$self->get_error, 1);

	return $self->_make_request_handler('auth', $params);
}

=head2 get_templogin_url

Generates the temporary login URL with which you can access the seogears' control panel. Essentially acts as a wrapper that stringifies the data returned by get_tempauth.

B<Input> Requires that you pass in either:

	userid    => '123456789'
	email     => 'test1@testing123.com'

Or

	bzid      => '31037'
	authkey   => 'HH1815009C705940t76917IWWAQdvyoDR077CO567M05324BHUCa744638889409oM8kw5E097737M626Gynd3974rsetvzf'

If the bzid/authkey are not provied, then it will attempt to look up the proper information using the userid and email provided.

Croaks if it is unable to sanitize the %params passed successfully, or the HTTP request to the API fails.

B<Output> Returns the login url that can be used to access the control panel on SEOgears.
Example: https://seogearstools.com/api/login.html?bzid=31037&tempauthkey=OU8937pI03R56Lz493j0958US34Ui9mgJG831JY756X0Tz04WGXVu762IuIxg7643vV6ju9M96J951V430Qvnw41b4qzgp2pu

=cut

sub get_templogin_url {

	my ($self, $params) = @_;

	if (not ($params->{bzid} and $params->{authkey}) ) {
		my $current_info = $self->statuscheck($params);
		if (not $current_info->{success}) {
			$self->_error("Failed to fetch current account information. Error: $current_info->{'debuginfo'}", 1);
		}
		$params = {'bzid' => $current_info->{'bzid'}, 'authkey' => $current_info->{'authkey'}};
	}

	my $tempauth = $self->get_tempauth($params);
	if (not $tempauth->{success}) {
		$self->_error("Failed to fetch tempauth key for account. Error: $tempauth->{'debuginfo'}", 1);
	}

	return $self->_get_apiurl('login')._stringify_params({'bzid' => $tempauth->{'bzid'}, 'tempauthkey' => $tempauth->{'tempauthkey'}});
}

=head2 get_userurl, get_authurl, get_loginurl

Return the corresponding api url that is being used.

=cut

sub get_userurl  { return shift->{'userurl'}; }
sub get_authurl  { return shift->{'authurl'}; }
sub get_loginurl { return shift->{'loginurl'}; }

=head2 get_error

Returns $self->{'error'}

=cut

sub get_error { return shift->{'error'}; }

=head2 get_brandname

Returns $self->{'brandname'}

=cut

sub get_brandname { return shift->{'brandname'}; }

=head2 get_brandkey

Returns $self->{'brandkey'}

=cut

sub get_brandkey { return shift->{'brandkey'}; }

=head1 Internal Subroutines

The following are not meant to be used directly, but are available if 'finer' control is required.

=cut

=head2 _make_request_handler

Wraps the call to _make_request and handles error checks.

B<INPUT> Takes the 'action' and sanitized paramaters hashref as input.

B<Output> Returns undef on failure (sets $self->{error} with the proper error). Returns a hash with the decoded json data from the API server if successful.

=cut

sub _make_request_handler {

	my $self   = shift;
	my $action = shift;
	my $params = shift;

	my $uri    = $self->_get_apiurl($action) or return $self->_error($self->get_error, 1);
	$uri      .= _stringify_params($params);

	my ($output, $error) = $self->_make_request($uri);
	if ($error) {
		$self->_error('Failed to process "'.$action.'" request. HTTP request failed: '.$error, 1);
	}

	my $json = eval{ decode_json($output); };
	if ($EVAL_ERROR){
		$self->_error('Failed to decode JSON - Invalid data returned from server: '.$output, 1);
	}

	return $json;
}

=head2 _make_request

Makes the HTTP request to the API server. 

B<Input> The full uri to perform the HTTP request on.

B<Output> Returns an array containing the http response, and error.
If the HTTP request was successful, then the error is blank.
If the HTTP request failed, then the response is blank and the error is the status line from the HTTP response.

=cut

sub _make_request {

	my $self = shift;
	my $uri  = shift;

	my $res = eval {
		local $SIG{ ALRM } = sub { croak 'connection timeout' };
		my $timeout = $self->{_ua}->timeout() || '30';
		alarm $timeout;
		$self->{_ua}->get($uri);
	};
	alarm 0;

	## no critic (EmptyQuotes BoundaryMatching DotMatchAnything RequireExtendedFormatting)
	if (
		# If $res is undef, then request() failed
		!$res
		# or if eval_error is set, then either the timeout alarm was triggered, or some other unforeseen error was caught.
		|| $EVAL_ERROR
		# or if the previous checks were good, and $ref is an object, then check to see if the status_line says that the connection timed out.
		|| ( ref $res && $res->{content} =~ m/^could not connect/i )
	) {
		# Return 'unable to connect' or whatever the eval_error was as the error.
		return ( '', $EVAL_ERROR ? $EVAL_ERROR : 'Unable to connect to server' );
	} elsif ( $res->{success} ) {
		# If the response is successful, then return the content.
		return ( $res->{content}, '' );
	} else {
		# If the response was not successful, and no evaled error was caught, then return the response status_line as the error.
		return ( '', $res->{status}.' - '.$res->{reason} );
	}
	## use critic
}

=head2 _stringify_params

Stringifies the content of a hash such that the output can be used as the URI body of a GET request.

B<Input> A hashref containing the sanatizied parameters for an API call.

B<Output> String with the keys and values stringified as so '&key1=value1&key2=value2'

=cut

sub _stringify_params {

	my $params = shift;
	my $url;
	foreach my $key (keys %{$params}) {
		## no critic (NoisyQuotes)
		$url .= '&'.$key.'='.uri_escape($params->{$key});
		## use critic
	}
	return $url;
}

=head2 _sanitize_params

sanitizes the data in the hashref passed for the action specified.

B<Input>  The 'action', and a hashref that has the data that will be sanitized.

B<Output> Boolean value indicating success. The hash is altered in place as needed.

=cut

sub _sanitize_params {

	my ($self, $action, $params) = @_;
	my $required_params = $self->_fetch_required_params($action) or return $self->_error( 'Unknown action specified: ' . $action );
	my $optional_params = $self->_fetch_optional_params($action);

	if (my $check = _check_params($params, $required_params, $optional_params) ) {
		my $error;
		if (ref $check eq 'HASH') {
			$error .= 'Missing required parameter(s): ' . join (', ', @{ $check->{'required_params'} } ).' ; '
				if $check->{'required_params'};
			$error .= 'Blank parameter(s): ' . join (', ', @{ $check->{'blank_params'} } ).' ; '
				if $check->{'blank_params'};
		} elsif (not ref $check) {
			$error = $check;
		}
		$self->_error($error);
		return;
	}

	return 1;
}

sub _fetch_required_params {

	my ($self, $action) = @_;
	my $required_keys_map = {
		'auth'        => { map { ($_ => 1) } qw(bzid authkey) },
		'login'       => { },
		'new'         => { map { ($_ => 1) } qw(userid name email phone domain rep pack placement price months) },
		'statuscheck' => { map { ($_ => 1) } qw(userid email) },
		'activate'    => { map { ($_ => 1) } qw(bzid authkey) },
		'inactivate'  => { map { ($_ => 1) } qw(bzid authkey) },
		'update'      => { map { ($_ => 1) } qw(bzid authkey) },
	};

	return $required_keys_map->{$action};
}

sub _fetch_optional_params {

	my ($self, $action) = @_;
	my $optional_keys_map = {
		'update' => { map { ($_ => 1) } qw(email expdate months pack phone price) },
	};

	return $optional_keys_map->{$action};
}

=head2 _check_params

B<Input>: Three hashrefs that contain the following in the specified order:

	1) the hashref to the params that need to be checked.
	2) the hashref to the 'required' set of params
	3) the hashref to the 'optional' set of params

B<Outupt>: Undef if everything is good. If errors are detected, it will:

	either return a hashref that has two arrays:
		'required_params' - which will list the required params that are missing. And
		'blank_params'    - which will list the params that have blank values specified for them.
	
	or a string with a specific error message.

This also 'prunes' the first hashref of params that are not specified in either the required or the optional hashrefs.

=cut 

sub _check_params {

	my ($params_to_check, $required_params, $optional_params) = @_;
	my $output;

	foreach my $param ( keys %{ $params_to_check } ) {
		if (not (exists $required_params->{$param} or exists $optional_params->{$param} ) ) {
			delete $params_to_check->{$param};
		} elsif (not length $params_to_check->{ $param } ) {
			push @{ $output->{'blank_params'} }, $param;
		}

		if ( $param eq 'months' ) {
			if ( _valid_months($params_to_check->{'months'}) ) {
				$params_to_check->{'expdate'} = _months_from_now($params_to_check->{'months'});
			} else {
				return 'Invalid value specified for \'months\' parameter: '.$params_to_check->{'months'};
			}
		}

		if ($param eq 'pack' and (not $params_to_check->{'price'}) ) {
			return 'Package ID paramater specified without a corresponding "price" parameter';
		}
	}

	foreach my $required_param ( keys %{ $required_params } ) {
		if (not (exists $params_to_check->{ $required_param } and defined $params_to_check->{ $required_param } ) ) {
			push @{ $output->{'required_params'} }, $required_param;
		}
	}

	return $output;
}

=head2 _valid_months

Returns true if the 'months' value specified is a valid. Currently, you can set renewals to occur on a monthly or yearly (upto 3 years), so the valid values are:

	1
	12
	24
	36

=cut

sub _valid_months {

	my $months = shift;
	if (VALID_MONTHS->{$months}) {
		return 1;
	}
	return;
}

=head2 _get_apiurl

Depending on the action passed, it will return the initial part of the URL that you can use along with the _stringify_params method to generate the full GET url.

Valid actions and the corresponding strings that are returned:

	'auth'        => get_authurl().'?'
	'login'       => get_loginurl().'?'
	'new'         => get_userurl().'?action=new'
	'statuscheck' => get_userurl().'?action=statuscheck'
	'inactivate'  => get_userurl().'?action=inactivate'
	'update'      => get_userurl().'?action=update'

If no valid action is specified, it will set the $self->{error} and return;

=cut

sub _get_apiurl {

	my $self   = shift;
	my $action = shift;

	## no critic (NoisyQuotes)
	my $uri_map = {
		'auth'        => $self->get_authurl().'?',
		'login'       => $self->get_loginurl().'?',
		'new'         => $self->get_userurl().'?action=new',
		'statuscheck' => $self->get_userurl().'?action=statuscheck',
		'activate'    => $self->get_userurl().'?action=activate',
		'inactivate'  => $self->get_userurl().'?action=inactivate',
		'update'      => $self->get_userurl().'?action=update',
	};
	## use critic

	if (not exists $uri_map->{$action} ) {
		$self->_error('Unknown action specified.');
		return;
	}
	return $uri_map->{$action};
}

=head2 _error

Internal method that is used to report and set $self->{'error'}.

It will croak if called with a true second argument. Such as:

	$self->_error($msg, 1);

=cut

sub _error {

	my ($self, $msg, $croak) = @_;
	$self->{'error'} = $msg;
	if ($croak) {
		croak $msg
	};
}

=head2 _months_from_now

Internal helper method that will calculate the expiration date thats x months in the future - calculated via Date::Calc's Add_Delta_YMDHMS().

=cut

sub _months_from_now {

	my $months = shift;
	my @date   = Add_Delta_YMDHMS( Today_and_Now(), 0, $months, 0, 0, 0, 0);
	return sprintf '%d-%02d-%02d %02d:%02d:%02d', @date;
}

=head2 _translate_lwp_to_http_opts

Helper method that translates the passed in LWP opts hashref to a corresponding HTTP::Tiny opts hashref.

=cut

sub _translate_lwp_to_http_opts {

	my $lwp_opts = shift;
	my $http_opts;

	foreach my $opt (qw(agent cookie_jar default_headers local_address max_redirect max_size proxy timeout ssl_opts)) {
		if ($opt eq 'default_headers' and ref $lwp_opts->{$opt} eq 'HTTP::Headers') {
			$http_opts->{$opt} = $lwp_opts->{$opt}->as_string;
		} elsif ($opt eq 'ssl_opts') {
			$http_opts->{verify_SSL}  = delete $lwp_opts->{$opt}->{'verify_hostname'} if exists $lwp_opts->{$opt}->{'verify_hostname'};
			$http_opts->{SSL_options} = $lwp_opts->{$opt} if keys %{$lwp_opts->{$opt}};
		} elsif (defined $lwp_opts->{$opt}) {
			$http_opts->{$opt} = $lwp_opts->{$opt};
		}
	}
	return $http_opts;
}

=head1 AUTHOR

Rishwanth Yeddula, C<< <ryeddula@cpan.org> >>

=head1 ACKNOWLEDGMENTS

Thanks to L<Hostgator.com|http://hostgator.com/> for funding the development of this module and providing test resources.

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-seogears at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-SEOGears>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc WWW::SEOGears

You can also review the API documentation provided by SEOgears for more information.

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-SEOGears>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-SEOGears>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-SEOGears>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-SEOGears/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Rishwanth Yeddula.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of WWW::SEOGears
