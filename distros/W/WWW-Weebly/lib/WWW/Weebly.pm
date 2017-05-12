package WWW::Weebly;

use 5.006;
use strict;
use warnings FATAL => 'all', NONFATAL => 'uninitialized';

use Carp qw(croak);
use Data::Dumper;
use Digest::MD5 qw(md5_hex);
use English qw(-no_match_vars);
use List::Util qw(first);

use HTTP::Tiny;
use URI::Escape qw(uri_escape);

=head1 NAME

WWW::Weebly - Perl interface to interact with the Weebly API.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

This module provides you with an perl interface to interact with the Weebly API.

	use WWW::Weebly;
	my $api = WWW::Weebly->new(
		{
			'tid_seed'      => $seed_value_for_generating_tids,
			'weebly_secret' => $weebly_secret,
			'weebly_url'    => $weebly_baseurl,
		}
	);
	$api->new_user();
	$api->login($params_for_login);
	$api->enable_account($params_for_enable_account);
	$api->disable_account($params_for_disable_account);
	$api->delete_account($params_for_delete_account);
	$api->undelete_account($params_for_undelete_account);
	$api->upgrade_account($params_for_upgrade_account);
	$api->downgrade_account($params_for_downgrade_account);
	$api->has_service($params_for_has_service);

=cut

=head1 SUBROUTINES/METHODS

=head2 new()

B<Croaks> on errors.

B<Input> takes a hashref that contains:

	weebly_secret => The secret key that is used to generate auth tokens.
	weebly_url    => Specify the base URL that we should be querying.

	One of the following:

	tid_seed      => The value that will be appended to the current time() value to generate a transaction id.
	tid_sub       => If you wish to generate transaction ids in a different way, you can pass the coderef to the sub you wish to use here.

	Optional:
	http_opts     => Hashref of options that are passed on to the HTTP::Tiny object that is used internally.
	                 Example value: { 'agent' => 'WWW-Weebly', 'timeout' => 20, 'verify_SSL' => 'false', 'SSL_options' => {'SSL_verify_mode' => '0x00'} }

=cut

sub new {

	my ( $class, $opts ) = @_;

	my $self = {};
	bless $self, $class;

	$self->{ weebly_secret } = $opts->{ weebly_secret }
		or croak ( 'weebly_secret is a required parameter' );

	# Configure the proper tid_sub for transaction_id generation
	if ( defined $opts->{ tid_sub } and ref $opts->{ tid_sub } eq 'CODE' ) {
		$self->{ tid_sub } = $opts->{ tid_sub };
	} elsif ( defined $opts->{ tid_seed } and not ref $opts->{ tid_seed } ) {
		$self->{ tid_sub } = sub {
				require Time::HiRes;
				Time::HiRes->import(qw|gettimeofday|);
				return md5_hex $opts->{ tid_seed }, gettimeofday();
			};
	} else {
		croak ( 'Must specifiy either a coderef for tid_sub, or a value for tid_seed' );
	}

	# Configure weebly_url
	if ( defined $opts->{ weebly_url } ) {
		$self->{ weebly_url } = $opts->{ weebly_url };
	} else {
		croak ( 'Must specify which URL to query in weebly_url' );
	}

	# Initiate the UA objects for the queries
	my $http_opts = $opts->{ http_opts };
	if (not (exists $http_opts->{agent} and defined $http_opts->{agent}) ) {
		$http_opts->{agent} = 'WWW-Weebly'.$VERSION;
	}
	$self->{ _ua }  = HTTP::Tiny->new ( %{ $http_opts } );

	return $self;
}

=head2 new_user()

Dispatches a newuser call to the URL specified in $self->{weebly_url}.

B<Croaks> on errors.

B<Input>: None.

B<Returns> a hashref with the following keys otherwise:

	success => 1 or 0.
	new_id  => ID associated with the new account (only present on success).
	reason  => If the request fails, this will contain a text explanation of the failure as returned by Weebly.

=cut

sub new_user {
	return shift->_do_request ( 'newuser' );
}

=head2 login()

Dispatches a login call to the URL specified in $self->{weebly_url}.

Passes critical user account information to Weebly, such as the FTP info, account type (Basic/Premium), widget type, etc.

Generates a one-time use login url that allows the client to log-in to the Weebly editor.

B<Croaks> on errors.

B<Input>: hashref that contains the following information:

	user_id        => the user_id of the account.
	ftp_url        => FTP URL
	ftp_username   => FTP username
	ftp_password   => FTP password
	ftp_path       => FTP publish path
	property_name  => Property name used for the creating the website's foooter. Should be of the form: <a href='URL' target='_blank'>SITE_NAME</a>
	upgrade_url    => URL of the purchase manager
	publish_domain => Published site's FQDN (ie www.domain.com)
	platform       => 'Windows' or 'Unix'
	publish_upsell => Publish upsell URL (optional, placed in an 640px wide by 200px tall iframe on publish)

B<Returns> a hashref with the following keys otherwise:

	success   => 1 or 0.
	login_url => one-time login url for the account.
	reason    => If the request fails, this will contain a text explanation of the failure as returned by Weebly.

=cut

sub login {
	my ( $self, $params ) = @_;
	$self->_sanitize_params ( 'login', $params )
		or $self->_error ( qq{Failed to sanitize params. Error: }.$self->get_error, 1 );
	my $output = $self->_do_request ( 'login', $params );
	if ( $output->{ success } ) {
		$output->{ login_url } = $self->get_weebly_url () . '/weebly/login.php?t=' . delete $output->{ token };
	}
	return $output;
}

=head2 enable_account()

Dispatches a enableaccount call to the URL specified in $self->{weebly_url}.

This call enables a user account that has been previously disabled.

B<Croaks> on errors.

B<Input>: hashref that contains the following information:

	user_id     => the user_id of the account.

B<Returns> a hashref with the following keys:

	success => 1 or 0.
	reason  => If the request fails, this will contain a text explanation of the failure as returned by Weebly.

=cut

sub enable_account {
	my ( $self, $params ) = @_;
	$self->_sanitize_params ( 'enableaccount', $params )
		or $self->_error ( qq{Failed to sanitize params. Error: }.$self->get_error, 1 );
	return $self->_do_request ( 'enableaccount', $params );
}

=head2 disable_account()

Dispatches a disableaccount call to the URL specified in $self->{weebly_url}.

This call disables login to a user account. This account will be accounted for in user quota numbers.

It is possible to restore login capabilities to this account using enable_account().

B<Croaks> on errors.

B<Input>: hashref that contains the following information:

	user_id => the user_id of the account.

B<Returns> a hashref with the following keys:

	success => 1 or 0.
	reason  => If the request fails, this will contain a text explanation of the failure as returned by Weebly.

=cut

sub disable_account {
	my ( $self, $params ) = @_;
	$self->_sanitize_params ( 'disableaccount', $params )
		or $self->_error ( qq{Failed to sanitize params. Error: }.$self->get_error, 1 );
	return $self->_do_request ( 'disableaccount', $params );
}

=head2 delete_account()

Dispatches a deleteaccount call to the URL specified in $self->{weebly_url}.

This call deletes a user account. This account will not be accounted for in user quota numbers.

It is possible to restore this account using the Admin interface or via the undelete_account() call.

B<Croaks> on errors.

B<Input>: hashref that contains the following information:

	user_id => the user_id of the account.

B<Returns> a hashref with the following keys:

	success => 1 or 0.
	reason  => If the request fails, this will contain a text explanation of the failure as returned by Weebly.

=cut

sub delete_account {
	my ( $self, $params ) = @_;
	$self->_sanitize_params ( 'deleteaccount', $params )
		or $self->_error ( qq{Failed to sanitize params. Error: }.$self->get_error, 1 );
	return $self->_do_request ( 'deleteaccount', $params );
}

=head2 undelete_account()

Dispatches a undeleteaccount call to the URL specified in $self->{weebly_url}.

This call restores a deleted user account.

B<Croaks> on errors.

B<Input>: hashref that contains the following information:

	user_id => the user_id of the account.

B<Returns> a hashref with the following keys:

	success => 1 or 0.
	reason  => If the request fails, this will contain a text explanation of the failure as returned by Weebly.

=cut

sub undelete_account {
	my ( $self, $params ) = @_;
	$self->_sanitize_params ( 'undeleteaccount', $params )
		or $self->_error ( qq{Failed to sanitize params. Error: }.$self->get_error, 1 );
	return $self->_do_request ( 'undeleteaccount', $params );
}

=head2 upgrade_account()

Dispatches a upgradeaccount call to the URL specified in $self->{weebly_url}.

This call upgrades a user account with a given service.

B<Croaks> on errors.

B<Input>: hashref that contains the following information:

	user_id     => the user_id of the account.
	service_id  => the server_id to be added to the account.
	               Current service_ids that Weebly responds are: 'Weebly.proAccount', 'Weebly.eCommerce'
	term        => duration of the service in months.
	price       => price paid for the service.

B<Returns> a hashref with the following keys:

	success => 1 or 0.
	reason  => If the request fails, this will contain a text explanation of the failure as returned by Weebly.

=cut

sub upgrade_account {
	my ( $self, $params ) = @_;
	$self->_sanitize_params ( 'upgradeaccount', $params )
		or $self->_error ( qq{Failed to sanitize params. Error: }.$self->get_error, 1 );
	return $self->_do_request ( 'upgradeaccount', $params );
}

=head2 downgrade_account()

Dispatches a downgradeaccount call to the URL specified in $self->{weebly_url}.

This call can be used to check if the specified user_id has Pro or Ecommerce features enabled.

B<Croaks> on errors.

B<Input>: hashref that contains the following information:

	user_id     => the user_id of the account.
	service_id  => the server_id to be removed from the account.
	               Current service_ids that Weebly responds are: 'Weebly.proAccount', 'Weebly.eCommerce'

B<Returns> a hashref with the following key:

	success => 1 or 0.

=cut

sub downgrade_account {
	my ( $self, $params ) = @_;
	$self->_sanitize_params ( 'downgradeaccount', $params )
		or $self->_error ( qq{Failed to sanitize params. Error: }.$self->get_error, 1 );
	return $self->_do_request ( 'downgradeaccount', $params );
}

=head2 has_service()

Dispatches a hasservice call to the URL specified in $self->{weebly_url}.

This call can be used to check if the specified user_id has Pro or Ecommerce features enabled.

B<Croaks> on errors.

B<Input>: hashref that contains the following information:
	user_id     => the user_id of the account.
	service_id  => the server_id to check.
	               Current service_ids that Weebly responds are: 'Weebly.proAccount', 'Weebly.eCommerce'

B<Returns> a hashref with the following key:

	success => 1 or 0.

=cut

sub has_service {
	my ( $self, $params ) = @_;
	$self->_sanitize_params ( 'hasservice', $params )
		or $self->_error ( qq{Failed to sanitize params. Error: }.$self->get_error, 1 );
	return $self->_do_request ( 'hasservice', $params );
}

=head2 get_auth_token()

B<Input>: transaction id, action param, and userid param.

B<Returns> the md5_hex hash of the input params concatenated with $self->{weebly_secret},
to be used as the auth token in the API calls.

=cut

sub get_auth_token {

	my ( $self, @params ) = @_;
	@params = grep { defined } @params;
	return md5_hex ( $self->get_weebly_secret (), @params );
}

=head2 get_weebly_url()

B<Returns> the base url that will be queried, which is stored in $self->{weebly_url}.

=cut

sub get_weebly_url { return shift->{ 'weebly_url' }; }

=head2 get_weebly_secret()

B<Returns> $self->{weebly_secret}.

=cut

sub get_weebly_secret { return shift->{ 'weebly_secret' }; }

=head2 get_error()

B<Returns> $self->{'error'}

=cut

sub get_error { return shift->{ 'error' }; }

=head1 Internal Subroutines

The following are not meant to be used directly, but are available if 'finer' control is required.

=cut

=head2 _do_request()

Wraps the call to _make_request and handles error checks.

B<INPUT>

	Takes the 'action' and sanitized paramaters hashref as input.

B<Output>

	Returns undef on failure (sets $self->{error} with the proper error).
	Returns a hashref with the parsed data from the API server if successful.

=cut

sub _do_request {

	my $self   = shift;
	my $action = shift;
	my $params = shift;

	my $userid;
	my $uri = $self->_get_url ( $action )
		or return $self->_error ( 'Failed to fetch URL to query. Error: ' . $self->_get_error, 1 );

	if ( $params and ref $params eq 'HASH' ) {
		$userid = $params->{ 'user_id' };
		$uri .= _stringify_params ( $params );
	}

	$uri = $self->_add_auth ( $uri, $action, $userid );

	my ( $output, $error ) = $self->_make_request ( $uri );
	if ( $error ) {
		return $self->_error ( 'Failed to process "' . $action . '" request. HTTP request failed: ' . $error, 1 );
	}

	return $self->_error ( 'No output returned from the Weebly API. Failed fetching results from the following URI: '
						   . $uri, 1 )
		if not $output;

	$output = _parse_output ( $output );
	return $output;
}

=head2 _parse_output()

Parses the output from Weebly's API call, and returns it as a hash.

=cut

sub _parse_output {

	my @keys = split /;/, shift;
	my $output;
	foreach my $key ( @keys ) {
		my ( $k, $v ) = split /=/, $key, 2;
		if ( $k eq 'status' ) {
			$output->{ 'success' } = ( $v eq 'success' or $v eq 'true' ) ? 1 : 0;
		} else {
			$output->{ $k } = $v;
		}
	}
	return $output;
}

=head2 _get_url()

Depending on the action passed, it will return part of the URL that you can use along with the _stringify_params method to generate the full GET url.

B<Input>: action param

B<Returns>: get_weebly_url().'/weebly/api.php?action='.$action

=cut

sub _get_url {

	my $self   = shift;
	my $action = shift;

	return $self->get_weebly_url () . '/weebly/api.php?action=' . $action;
}

=head2 _add_auth()

Adds the neccessary transaction id (tid) and authentication tokens to the URI

=cut

sub _add_auth {

	my ( $self, $uri, $action, $userid ) = @_;
	my $tid = $self->_get_tid ();
	my $auth = $self->get_auth_token ( $tid, $action, $userid );
	$uri .= '&tid=' . $tid . '&auth=' . $auth;
	return $uri;
}

=head2 _get_tid()

B<Input>: None.

B<Returns> the tid value generated by the sub referenced in $self->{tid_sub}.

If a 'tid_seed' value was specified when the object was created,
then the value returned is the md5_hex hash of the tid_seed value
concatenated with time().

=cut

sub _get_tid { return shift->{ tid_sub }->(); }

=head2 _make_request()

Makes the HTTP request. 

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
		my $timeout = $self->{ _ua }->timeout () || '30';
		alarm $timeout;
		$self->{ _ua }->get ( $uri );
	};
	alarm 0;

	## no critic (EmptyQuotes BoundaryMatching DotMatchAnything)
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
		# If the response was not successful, and no evaled error was caught, then return the content as the error.
		return ( '', $res->{content});
	}
	## use critic
}

=head2 _sanitize_params()

Sanitizes the data in the hashref passed for the action specified.

B<Input>  The 'action', and a hashref that has the data that will be sanitized.

B<Output> Boolean value indicating success. The hash is altered in place as needed.

=cut

sub _sanitize_params {

	my $self   = shift;
	my $action = shift;
	my $params = shift;

	my $required_keys = {
		login => {
			map { ( $_ => 1 ) }
				qw(user_id ftp_url ftp_username ftp_password ftp_path property_name upgrade_url publish_domain platform publish_upsell)
		},
		upgradeaccount => { map { ( $_ => 1 ) } qw(user_id service_id term price) },
		hasservice     => { map { ( $_ => 1 ) } qw(user_id service_id) },
		enableaccount  => { map { ( $_ => 1 ) } qw(user_id) },
	};
	$required_keys->{ downgradeaccount } = $required_keys->{ hasservice };
	$required_keys->{ $_ } = $required_keys->{ enableaccount } for qw(disableaccount deleteaccount undeleteaccount);

	if ( not exists $required_keys->{ lc $action } ) {
		$self->_error ( 'Unknown action specified: ' . $action );
		return;
	}

	_uri_escape_values ( $params );
	_remove_unwanted_keys ( $params, $required_keys->{ lc $action } );

	# remove publish_upsell from the wanted list for 'login' calls - since its an optional param.
	delete $required_keys->{ login }->{ publish_upsell };

	# check the params passed with the wanted list
	if ( my $check = _check_required_keys ( $params, $required_keys->{ lc $action } ) ) {
		my $error;
		$error .= 'Missing required parameter(s): ' . join ( ', ', @{ $check->{ 'missing_params' } } ) . '; '
			if $check->{ 'missing_params' };
		$error .= 'Blank required parameter(s): ' . join ( ', ', @{ $check->{ 'blank_params' } } ) . '; '
			if $check->{ 'blank_params' };
		$self->_error ( $error );
		return;
	}

	return 1;
}

sub _uri_escape_values {

	my $params = shift;
	foreach my $key ( keys %{ $params } ) {
		if ( first { $key eq $_ } qw(property_name upgrade_url publish_upsell price) ) {
			$params->{ $key } = uri_escape ( $params->{ $key } );
		}
	}
	return;
}

=head2 _stringify_params()

Stringifies the content of a hash such that the output can be used as the URI body of a GET request.

B<Input> A hashref containing the sanatizied parameters for an API call.

B<Output> String with the keys and values stringified as so '&key1=value1&key2=value2'

=cut

sub _stringify_params {

	my $params = shift;
	my $url;
	foreach my $key ( keys %{ $params } ) {
		## no critic (NoisyQuotes)
		$url .= '&' . $key . '=' . $params->{ $key };
		## use critic
	}
	return $url;
}

=head2 _check_required_keys()

B<Input>

	First arg: Hashref that contains the data to be checked.
	Second arg: Hashref that holds the keys to check for.

B<Output>

A hash containing the 'missing_params' and 'blank_params', if any are found to be missing.

	If a required key is missing, it will be present in the missing_params array.
	If a required key has a blank value, it will be present in the blank_params array.

Returns undef, if no issues are found.

=cut

sub _check_required_keys {

	my $params_ref = shift;
	my $wanted_ref = shift;
	my $output;

	foreach my $wanted_key ( keys %{ $wanted_ref } ) {
		if ( not ( exists $params_ref->{ $wanted_key } and defined $params_ref->{ $wanted_key } ) ) {
			push @{ $output->{ 'missing_params' } }, $wanted_key;
		} elsif ( not length $params_ref->{ $wanted_key } ) {
			push @{ $output->{ 'blank_params' } }, $wanted_key;
		}
	}

	return $output;
}

=head2 _remove_unwanted_keys()

Deletes keys from the provided params hashref, if they are not listed in the hash for wanted keys.

B<Input>

	First arg: Hashref that contains the data to be checked. 
	Second arg: Hashref that holds the keys to check for.

B<Output>

	undef

=cut

sub _remove_unwanted_keys {

	my $params_ref = shift;
	my $wanted_ref = shift;

	foreach my $key ( keys %{ $params_ref } ) {
		if ( not $wanted_ref->{ $key } ) {
			delete $params_ref->{ $key };
		}
	}
	return;
}

=head2 _get_error()

Returns $self->{'error'}

=cut

sub _get_error { return shift->{ 'error' }; }

=head2 _error()

Internal method that is used to report and set $self->{'error'}.

It will croak if called with a true second argument. Such as:

	$self->_error($msg, 1);

=cut

sub _error {

	my ( $self, $msg, $croak ) = @_;
	$self->{ 'error' } = $msg;
	if ( $croak ) {
		croak $msg;
	}
}

=head1 AUTHOR

Rishwanth Yeddula, C<< <ryeddula at cpan.org> >>

=head1 ACKNOWLEDGMENTS

Thanks to L<Hostgator.com|http://hostgator.com/> for funding the development of this module and providing test resources.

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-weebly at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Weebly>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Weebly


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Weebly>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Weebly>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Weebly>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Weebly/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Rishwanth Yeddula.

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

1; # End of WWW::Weebly
