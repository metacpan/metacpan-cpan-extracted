package WWW::Codeguard::Partner;

use strict;
use warnings FATAL => 'all', NONFATAL => 'uninitialized';

use parent qw(WWW::Codeguard);

use JSON;
use LWP::UserAgent;
use HTTP::Request;

=head1 NAME

WWW::Codeguard::Partner - Perl interface to interact with the Codeguard API as a 'partner'.

=cut

=head1 SYNOPSIS

This module provides you with an perl interface to interact with the Codeguard API and perform the 'partner' level calls.

	use WWW::Codeguard::Partner;

	my $api = WWW::Codeguard::Partner->new(
		$api_url,
		{
			partner_key => $partner_key,
			verify_hostname => 1,
		}
	);

	$api->create_user($params_for_create_user);
	$api->list_user($params_for_list_user);
	$api->delete_user($params_for_delete_user);

=cut

sub new {

	my $class = shift;
	my $self  = {};
	bless $self, $class;
	$self->_initialize(@_);
	return $self;
}

sub _initialize {

	my ($self, $api_url, $opts) = @_;

	$self->{api_url}     = $api_url;
	$self->{partner_key} = delete $opts->{partner_key} or $self->_error('partner_key is a required parameter', 1);

	# initialize the UA
	$self->{_ua} = LWP::UserAgent->new(
		agent    => 'WWW-Codeguard-Partner '.$self->VERSION,
		ssl_opts => {
			verify_hostname => (exists $opts->{verify_hostname}? $opts->{verify_hostname} : 1),
		},
	);

	return $self;
}

=head1 METHODS

Each of these map to a call on Codeguard's Partner API.
 
=cut

=head2 create_user

This allows you to create an account, on to which you can add website/database resources. Params should be a hashref that contains the following attributes:

Required: The request will not succeed without these attributes.

	name
	email

Optional Attributes:

	password
	time_zone
	partner_data - This is a string that can be used to store user-specific information, that the partner may use to identify the user (such as package id, etc)
	plan_id

=cut

sub create_user {

	my ($self, $params) = @_;
	return $self->_do_method('create_user', $params);
}

=head2 list_user

This allows you to fetch information for a user. Params should be a hashref that contains the following attributes:

Required:

	user_id

Optional:

	None

=cut

sub list_user {

	my ($self, $params) = @_;
	return $self->_do_method('list_user', $params);
}

=head2 delete_user

This method is used to delete existing users that were created using the specified partner_key. Parters can not delete users created by other partners.

B<Note:> Deleting a user resource will also delete all associated Website and Database records.

Params should be a hashref that contains the following attributes:

Required:

	user_id

Optional Attributes:

	None

=cut

sub delete_user {

	my ($self, $params) = @_;
	return $self->_do_method('delete_user', $params);
}

=head2 change_user_plan

This method is used to change an existing user's plan. Params should be a hashref that contains the following attributes:

Required:

	user_id
	plan_id

Optional Attributes

	None

=cut

sub change_user_plan {

	my ($self, $params) = @_;
	return $self->_do_method('change_user_plan', $params);
}

=head2 user_quota_report

Required:

	None

Optional:

	None

Returns an array of Users who are using more than their allowed disk quota.

B<Note>: Full User models are not included. Only the Attributes listed below are returned:

=over 4

=item * email         - User email address.

=item * package       - CodeGuard plan ID associated with this user.

=item * quota         - Allowed quota in bytes.

=item * usage         - Disk usage in bytes.

=item * percent_usage - Percent of quota used. This can be > 100%.

=item * signup_date   - Date of User account creation.

=item * overage_date  - Date the user was notified or 'Not yet notified' if a notification has not yet occurred.

=back

=cut

sub user_quota_report {

	my ($self, $params) = @_;
	return $self->_do_method('user_quota_report', $params);
}

=head1 Accessors

Basic accessor methods to retrieve the current settings

=cut

=head2 get_partner_key

Returns the partner_key of the object instance.

=cut

sub get_partner_key { shift->{partner_key}; }

# Internal Methods

sub _create_request {

	my ($self, $action, $params) = @_;
	my $action_map = {
		'change_user_plan'  => 'POST',
		'create_user'       => 'POST',
		'delete_user'       => 'DELETE',
		'list_user'         => 'GET',
		'user_quota_report' => 'GET',
	};
	my $request = HTTP::Request->new( $action_map->{$action} );
	$request->header('Content-Type' => 'application/json' );
	$self->_set_content($request, $params);
	$self->_set_uri($action, $request, $params);
	return $request;
}

sub _set_uri {

	my ($self, $action, $request, $params) = @_;
	my $base_url = $self->get_api_url();
	my $uri_map = {
		'change_user_plan'  => '/users/'.($params->{user_id} || '').'/plan',
		'create_user'       => '/users',
		'delete_user'       => '/users/'.($params->{user_id} || ''),
		'list_user'         => '/users/'.($params->{user_id} || ''),
		'user_quota_report' => '/partners/user_quota_report',
	};
	$request->uri($base_url.$uri_map->{$action}.'?api_key='.$self->get_partner_key);
	return;
}

sub _fetch_required_params {

	my ($self, $action, $params) = @_;
	my $required_keys_map = {
		'create_user'       => { map { ($_ => 1) } qw(name email) },
		'list_user'         => { map { ($_ => 1) } qw(user_id) },
		'change_user_plan'  => { map { ($_ => 1) } qw(user_id plan_id) },
		'user_quota_report' => { },
	};
	$required_keys_map->{delete_user} = $required_keys_map->{list_user};
	return $required_keys_map->{$action};
}

sub _fetch_optional_params {

	my ($self, $action) = @_;
	my $optional_keys_map = {
		'create_user' => { map { ($_ => 1) } qw(password time_zone partner_data plan_id) },
	};
	return $optional_keys_map->{$action};
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
