package WWW::Codeguard::User;

use strict;
use warnings FATAL => 'all', NONFATAL => 'uninitialized';

use parent qw(WWW::Codeguard);

use JSON qw();
use Net::OAuth;
use LWP::UserAgent;
use HTTP::Request;

=head1 NAME

WWW::Codeguard::User - Perl interface to interact with the Codeguard API as a 'user'

=cut

=head1 SYNOPSIS

This module provides you with an perl interface to interact with the Codeguard API and perform the 'user' level calls.

	use WWW::Codeguard::User;

	my $api = WWW::Codeguard::User->new(
		$api_url,
		{
			api_secret      => $user_api_secret,
			api_key         => $user_api_key,
			access_secret   => $user_access_secret,
			access_token    => $user_access_token,
			verify_hostname => 1,
		}
	);

=cut

sub new {

	my $class = shift;
	my $self = {};
	bless $self, $class;
	$self->_initialize(@_);
	return $self;
}

sub _initialize {

	my ($self, $api_url, $opts) = @_;

	$self->{api_url} = $api_url;
	foreach my $key (qw(api_secret api_key access_secret access_token)) {
		$self->{$key} = delete $opts->{$key} or $self->_error($key.' is a required parameter', 1);
	}

	# initialize the UA
	$self->{_ua} = LWP::UserAgent->new(
		agent    => 'WWW-Codeguard-User '.$self->VERSION(),
		max_redirect => 0,
		ssl_opts => {
			verify_hostname => (exists $opts->{verify_hostname}? $opts->{verify_hostname} : 1),
		},
	);

	return $self;
}

=head1 METHODS

Each of these map to a call on Codeguard's User API.

=cut

=head2 create_website

This allows you to create a website resource under your User account. Params should be a hashref that contains the following attributes:

Required: The request will not succeed without these attributes.

	url
	hostname
	account
	password or key
	provider

Optional:

	dir_path
	port

=cut

sub create_website {

	my ($self, $params) = @_;
	return $self->_do_method('create_website', $params);
}

=head2 list_websites

This allows you to list the website resources under your User account. Params should be a hashref that contains the following attributes:

Required:

	None

Optional:

	None

=cut

sub list_websites {

	my ($self, $params) = @_;
	return $self->_do_method('list_websites', $params);
}

=head2 list_website_rules

This allows you to list the exclusion rules for a website resource under your User account. Params should be a hashref that contains the following attributes:

Required:

	website_id

Optional:

	None

=cut

sub list_website_rules {

	my ($self, $params) = @_;
	return $self->_do_method('list_website_rules', $params);
}

=head2 set_website_rules

This allows you to set the exclusion rules for a website resource under your User account. Params should be a hashref that contains the following attributes:

Required:

	website_id
	exclude_rules - must be an array ref with elements specifying what paths/files to ignore. Example:
	[
		'access-logs/*'
		'*error_log*'
		'*stats/*'
		'/path/to/a/folder/*'
		'/path/to/a/file.txt'
	]

Optional:

	None

=cut

sub set_website_rules {

	my ($self, $params) = @_;
	return $self->_do_method('set_website_rules', $params);
}

=head2 edit_website

This allows you to edit information for the specified website resource under your User account. Params should be a hashref that contains the following attributes:

Required:

	website_id

Optional:

	url
	monitor_frequency
	account
	password or key
	dir_path
	hostname
	disabled

=cut

sub edit_website {

	my ($self, $params) = @_;
	return $self->_do_method('edit_website', $params);
}

=head2 delete_website

This allows you to delete the specified website resource under your User account. Params should be a hashref that contains the following attributes:

Required:

	website_id

Optional:

	None

=cut

sub delete_website {

	my ($self, $params) = @_;
	return $self->_do_method('delete_website', $params);
}

=head2 enable_website

This allows you to enable a specified website resource under your User account. Params should be a hashref that contains the following attributes:

Required:

	website_id

Optional:

	None

=cut

sub enable_website {

	my ($self, $params) = @_;
	my $real_params = {
		UNIVERSAL::isa($params, 'HASH') ? ( website_id => $params->{website_id} ) : (),
	};

	$real_params->{disabled} = JSON::false;
	return $self->_do_method('edit_website', $real_params);
}

=head2 disable_website

This allows you to disable a specified website resource under your User account. Params should be a hashref that contains the following attributes:

Required:

	website_id

Optional:

	None

=cut

sub disable_website {

	my ($self, $params) = @_;
	$self->_sanitize_params('edit_website', $params) or
		$self->_error('Failed to sanitize params: "'.$self->get_error.'" - The parameters passed in were: '."\n".$self->_stringify_hash($params), 1);
	$params->{disabled} = JSON::true;
	return $self->_do_method('edit_website', $params);
}

=head2 create_database

This allows you to create a database resource under your User account. Params should be a hashref that contains the following attributes:

Required:

	server_address - MySQL Database Hostname or IP address.
	account        - MySQL username which has access to the database_name database.
	password       - MySQL password associated with account.
	                 Note: This parameter is only used during the create action. It is never returned by other API requests.
	port           - MySQL server port number for use with the server_name.
	database_name  - The name of the target database.

Optional:

	website_id          - Numeric ID of the parent Website record.
	                      If no website_id is provided, the Database will not be associated with any website resource.

B<Experimental features>: SSH functionality for DB backups is currently not fully functional on CodeGuard's side, and as such might not function as expected.

	authentication_mode - This can be one of two values: 'direct' or 'ssh'.
	                      The direct method will attempt to open a connection using a MySQL client on the specified server and port.
	                      The ssh method will create an SSH tunnel through server_name using the server_account and
	                      server_password credentials to connect to the database on server_name.

	server_account      - SSH username on server_address. Note: This field is only valid if the authenticationmode is ssh.
	                      Note: Required if authentication_mode is 'ssh'.

	server_password     - SSH password associated with server_account.
	                      Note: Required if authentication_mode is 'ssh'.

=cut

sub create_database {

	my ($self, $params) = @_;
	return $self->_do_method('create_database', $params);
}

=head2 list_databases

This allows you to fetch all Database Records owned by the user.

Required:

	None

Optional:

	None

=cut

sub list_databases {

	my ($self, $params) = @_;
	return $self->_do_method('list_databases', $params);
}

=head2 show_database

This allows you to fetch information for the specified database resource under your User account. Params should be a hashref that contains the following attributes:

Required:

	website_id
	database_id

Optional:

	None

=cut

sub show_database {

	my ($self, $params) = @_;
	return $self->_do_method('show_database', $params);
}

=head2 edit_database

This allows you to edit information for the specified database resource under your User account. Params should be a hashref that contains the following attributes:

Required:

	database_id

Optional:

	website_id
	server_address
	account
	password
	port
	database_name
	authentication_mode
	server_account
	server_password
	disabled

=cut

sub edit_database {

	my ($self, $params) = @_;
	return $self->_do_method('edit_database', $params);
}

=head2 delete_database

This allows you to delete the specified database resource under your User account. Params should be a hashref that contains the following attributes:

Required:

	database_id

Optional:

	None

=cut

sub delete_database {

	my ($self, $params) = @_;
	return $self->_do_method('delete_database', $params);
}

=head2 enable_database

This allows you to enable a specified database resource under your User account. Params should be a hashref that contains the following attributes:

Required:

	database_id

Optional:

	None

=cut

sub enable_database {

	my ($self, $params) = @_;
	my $real_params = {
		UNIVERSAL::isa($params, 'HASH') ? ( database_id => $params->{database_id} ) : (),
	};

	$real_params->{disabled} = JSON::false;
	return $self->_do_method('edit_database', $real_params);
}

=head2 disable_database

This allows you to disable a specified database resource under your User account. Params should be a hashref that contains the following attributes:

Required:

	database_id

Optional:

	None

=cut

sub disable_database {

	my ($self, $params) = @_;
	my $real_params = {
		UNIVERSAL::isa($params, 'HASH') ? ( database_id => $params->{database_id} ) : (),
	};

	$real_params->{disabled} = JSON::true;
	return $self->_do_method('edit_database', $real_params);
}

=head2 generate_login_link

This creates a login URL that can be used to access the Codeguard Dashboard for your User account.

Required:

	None

Optional:

	None

=cut

sub generate_login_link {

	my $self = shift;
	return $self->_set_uri('list_websites');
}

=head1 Accessors

Basic accessor methods to retrieve the current settings

=cut

=head2 get_api_secret

Returns the current value in $self->{api_secret}.

=cut

sub get_api_secret { shift->{api_secret}; }

=head2 get_api_key

Returns the current value in $self->{api_key}.

=cut

sub get_api_key { shift->{api_key}; }

=head2 get_access_secret

Returns the current value in $self->{access_secret}.

=cut

sub get_access_secret { shift->{access_secret}; }

=head2 get_access_token

Returns the current value in $self->{access_token}.

=cut

sub get_access_token { shift->{access_token}; }

# Internal Methods

sub _create_request {

	my ($self, $action, $params) = @_;
	my $action_map = {
		'create_website'     => 'POST',
		'list_websites'      => 'GET',
		'edit_website'       => 'PUT',
		'delete_website'     => 'DELETE',
		'list_website_rules' => 'GET',
		'set_website_rules'  => 'POST',
		'create_database'    => 'POST',
		'list_databases'     => 'GET',
		'show_database'      => 'GET',
		'edit_database'      => 'PUT',
		'delete_database'    => 'DELETE',
	};
	my $request = HTTP::Request->new( $action_map->{$action} );
	$request->header('Content-Type' => 'application/json' );
	$self->_set_uri($action, $request, $params);
	$self->_set_content($request, $params);
	return $request;
}

sub _set_uri {

	my ($self, $action, $request, $params) = @_;
	my $base_url = $self->get_api_url();
	my $uri_map  = {
		'create_website'     => '/websites',
		'list_websites'      => '/websites',
		'edit_website'       => '/websites/'.($params->{website_id} || ''),
		'delete_website'     => '/websites/'.($params->{website_id} || ''),
		'list_website_rules' => '/websites/'.($params->{website_id} || '').'/rules',
		'set_website_rules'  => '/websites/'.($params->{website_id} || '').'/rules',
		'create_database'    => '/database_backups',
		'list_databases'     => '/database_backups',
		'show_database'      => '/websites/'.($params->{website_id} || '').'/database_backups/'.($params->{database_id} || ''),
		'edit_database'      => '/database_backups/'.($params->{database_id} || ''),
		'delete_database'    => '/database_backups/'.($params->{database_id} || ''),
	};

	my $oauth_req = Net::OAuth->request('protected resource')->new(
		'consumer_key'     => $self->{api_key},
		'consumer_secret'  => $self->{api_secret},
		'token'            => $self->{access_token},
		'token_secret'     => $self->{access_secret},
		'signature_method' => 'HMAC-SHA1',
		'timestamp'        => time(),
		'nonce'            => _oauth_nonce(),
		'request_method'   => ($request) ? $request->method() : 'GET',
		'request_url'      => $base_url.$uri_map->{$action},
	);
	$oauth_req->sign;
	return ($request) ? $request->uri($oauth_req->to_url) : $oauth_req->to_url;
}

sub _fetch_required_params {

	my ($self, $action, $params) = @_;
	my $required_keys_map = {
		create_website     => { map { ($_ => 1) } qw(url hostname account provider) },
		list_websites      => { },
		list_website_rules => { map { ($_ => 1) } qw(website_id) },
		set_website_rules  => { map { ($_ => 1) } qw(website_id exclude_rules) },
		create_database    => { map { ($_ => 1) } qw(server_address account password port database_name) },
		list_databases     => { },
		#show_database      => { map { ($_ => 1) } qw(website_id database_id) },
        show_database      => { map { ($_ => 1) } qw(database_id) }, # Added in v0.03.
		edit_database      => { map { ($_ => 1) } qw(database_id) },
	};

	# The 'edit_website', and 'delete_website' calls have the same set of required params as the 'list_website_rules' call
	$required_keys_map->{edit_website} = $required_keys_map->{delete_website} = $required_keys_map->{list_website_rules};

	# The 'delete_database' call has the same set of required params as the 'edit_database' call
	$required_keys_map->{delete_database} = $required_keys_map->{edit_database};

	# if action is 'create_website',
	# then we check the $params
	# and mark either 'password' or 'key' as the required param.
	if ($action eq 'create_website') {
		if (exists $params->{key} and $params->{key}) {
			$required_keys_map->{create_website}->{key} = 1;
			delete $params->{password};
		} elsif (exists $params->{password} and $params->{password}) {
			$required_keys_map->{create_website}->{password} = 1;
		} else {
			# if neither key or password are present, then push a 'fake' value in, to indicate this.
			$required_keys_map->{create_website}->{'Key or Password'} = 1;
		}
	} elsif ($action eq 'create_database' and (exists $params->{authentication_mode} and $params->{authentication_mode} eq 'ssh')) {
		$required_keys_map->{create_database}->{server_account}  = 1;
		$required_keys_map->{create_database}->{server_password} = 1;
	}

	return $required_keys_map->{$action};
}

sub _fetch_optional_params {

	my ($self, $action) = @_;
	my $optional_keys_map = {
		create_website  => { map { ($_ => 1) } qw(port dir_path) },
		create_database => { map { ($_ => 1) } qw(website_id authentication_mode) },
		edit_website    => { map { ($_ => 1) } qw(url monitor_frequency account password key dir_path hostname disabled) },
        show_database   => { map { ($_ => 1) } qw(website_id) }, # Added in v0.03. 
		edit_database   => { map { ($_ => 1) } qw(server_address account password port database_name authentication_mode server_account server_password website_id disabled) },
	};
	return $optional_keys_map->{$action};
}

sub _oauth_nonce {

	my $nonce = '';
	$nonce .= sprintf("%02x", int(rand(255))) for 1..16;
	return $nonce;
}

=head1 AUTHOR

Rishwanth Yeddula, C<< <ryeddula at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-codeguard at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Codeguard>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the following perldoc commands.

    perldoc WWW::Codeguard
    perldoc WWW::Codeguard::Partner
    perldoc WWW::Codeguard::User


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Codeguard>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Codeguard>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Codeguard>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Codeguard/>

=back

=head1 ACKNOWLEDGMENTS

Thanks to L<Hostgator.com|http://hostgator.com/> for funding the development of this module and providing test resources.

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

1;
