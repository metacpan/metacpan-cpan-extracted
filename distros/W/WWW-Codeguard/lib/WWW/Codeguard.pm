package WWW::Codeguard;

use strict;
use warnings FATAL => 'all', NONFATAL => 'uninitialized';

use Carp qw(croak);
use English qw(-no_match_vars);
use JSON;

=head1 NAME

WWW::Codeguard - Perl interface to interact with the Codeguard API

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

This module provides you with an perl interface to interact with the Codeguard API. This is really just the base class that returns the proper object to use.
Depending on the params you pass, it will return either the 'Partner' object, or the 'User' object.

	use WWW::Codeguard;

	my $partner_api = WWW::Codeguard->new(
		{
			api_url => $api_url,
			partner => {
				partner_key => $partner_key,
			},
		}
	);

	my $user_api = WWW::Codeguard->new(
		{
			api_url => $api_url,
			user => {
				api_key       => $user_api_key,
				api_secret    => $user_api_secret,
				access_secret => $user_access_secret,
				access_token  => $user_access_token,
			},
		}
	);

=cut

=head1 Object Initialization

B<Input> takes an hashref of params. The hashref should contain:

	api_url
	partner => $hashref_containing_the_partner_options
	user => $hashref_containing_the_user_options

If both 'partner' and 'user' options are specified, then you should use it an array context to get back both objects:

	my ($partner_api, $user_api) = WWW::Codeguard->new(
		{
			api_url => $api_url,
			partner => {
				partner_key => $partner_key,
			},
			user => {
				api_key       => $user_api_key,
				api_secret    => $user_api_secret,
				access_secret => $user_access_secret,
				access_token  => $user_access_token,
			},
		}
	);

If array context is not specified, then it will only return the partner api object even if both objects were created.

=cut

sub new {

	my ($class, $opts) = @_;
	unless ( $opts and UNIVERSAL::isa($opts, 'HASH') and (exists $opts->{partner} or exists $opts->{user}) ) {
		croak ('Object initialization failed. Invalid params passed to constructor.');
	}

	my ($partner_obj, $user_obj);
	if ( exists $opts->{partner} and UNIVERSAL::isa($opts->{partner}, 'HASH') ) {
		require WWW::Codeguard::Partner;
		$partner_obj = WWW::Codeguard::Partner->new($opts->{api_url}, $opts->{partner});
	}

	if ( exists $opts->{user} and UNIVERSAL::isa($opts->{user}, 'HASH') ) {
		require WWW::Codeguard::User;
		$user_obj = WWW::Codeguard::User->new($opts->{api_url}, $opts->{user});
	}

	# If called in an array content, return both;
	# if not just return which ever one is not undef.
	return wantarray ? ($partner_obj, $user_obj) : $partner_obj || $user_obj;
}

=head1 METHODS

Partner methods are documented in L<WWW::Codeguard::Partner>

User methods are documented in L<WWW::Codeguard::User>

=cut

=head2 get_error

Returns the current value in $self->{_error}.

=cut

sub get_error { shift->{_error}; }

=head2 get_api_url

Returns the current value in $self->{api_url}.

=cut

sub get_api_url { shift->{api_url}; }

sub VERSION { return $WWW::Codeguard::VERSION; }

# Internal Methods

sub _do_method {

	my ($self, $name, $params) = @_;
	if (defined $params and not UNIVERSAL::isa($params, 'HASH')) {
		$self->_error('$params passed has to be a HASHREF', 1);
	}

	$self->_sanitize_params($name, $params) or
		$self->_error('Failed to sanitize params: "'.$self->get_error.'" - The parameters passed in were: '."\n".$self->_stringify_hash($params), 1);

	return $self->_dispatch_request($name, $params);
}

sub _dispatch_request {

	my ($self, $action, $params) = @_;
	my $base_url = $self->get_api_url() or
		return $self->_error('Failed to fetch api_url', 1);

	my $request      = $self->_create_request($action, $params);
	my $api_response = $self->{_ua}->request($request);
	if (my $output = $api_response->decoded_content) {
		my $json = eval { decode_json($output); }
			or return $self->_error('Invalid API reponse received (unable to decode json): '.$api_response->status_line, 1);
		return $json;
	} else {
		return $self->_error('Invalid API reponse received (no json received): '.$api_response->status_line, 1);
	}
	return;
}

sub _sanitize_params {

	my ($self, $action, $params) = @_;
	my $required_params = $self->_fetch_required_params($action, $params) or return $self->_error( 'Unknown action specified: ' . $action );
	my $optional_params = $self->_fetch_optional_params($action);

	if (my $check = _check_params($params, $required_params, $optional_params) ) {
		my $error;
		$error .= 'Missing required parameter(s): ' . join (', ', @{ $check->{'required_params'} } ).' ; '
			if $check->{'required_params'};
		$error .= 'Blank parameter(s): ' . join (', ', @{ $check->{'blank_params'} } ).' ; '
			if $check->{'blank_params'};
		$self->_error($error);
		return;
	}

	return 1;
}

sub _set_content {

	my ($self, $request, $params) = @_;
	if ('GET' ne $request->method) {
		my $json = eval {
			encode_json( $params );
		} or $self->_error('Failed to encode json payload for request', 1);
		$request->content($json);
	}
	return;
}

=head2 _check_params

B<Input>: Three hashrefs that contain the following in the specified order:

	1) the hashref to the params that need to be checked.
	2) the hashref to the 'required' set of params
	3) the hashref to the 'optional' set of params

B<Outupt>: Undef if everything is good. If errors are detected, it will return a hashref that has two arrays:

	'required_params' - which will list the required params that are missing. And
	'blank_params'    - which will list the params that have blank values specified for them.

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
	}

	foreach my $required_param ( keys %{ $required_params } ) {
		if (not (exists $params_to_check->{ $required_param } and defined $params_to_check->{ $required_param } ) ) {
			push @{ $output->{'required_params'} }, $required_param;
		}
	}

	return $output;
}

sub _stringify_hash {

	my $self    = shift;
	my $hashref = shift;
	my $string;
	while (my ($key, $value) = each %{$hashref}) {
		$string .= $key.'='.$value.', ';
	}
	$string =~ s/, $//;
	return $string;
}

=head2 _error

Internal method that is used to report and set $self->{_error}.

Will croak if a true second argument is passed. Example:

	$self->_error($msg, 1); 

=cut

sub _error {

	my ($self, $msg, $croak) = @_;
	$self->{_error} = $msg;
	if ($croak) {
		croak $msg;
	}
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

1; # End of WWW::Codeguard
