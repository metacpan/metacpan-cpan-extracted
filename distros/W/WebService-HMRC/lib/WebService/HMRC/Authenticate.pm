package WebService::HMRC::Authenticate;

use 5.006;
use Carp;
use List::Util 1.33;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use WebService::HMRC::Response;

extends 'WebService::HMRC::Request';

=head1 NAME

WebService::HMRC::Authenticate - Response object for the UK HMRC HelloWorld API

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use WebService:HMRC::Authenticate;

    my $auth = WebService::HMRC::Authenticate->new({
        base_url => 'https://test-api.service.hmrc.gov.uk/',
        client_id => $client_id,
        client_secret => $client_secret,
    });

    # Direct user to this url to authorise our application
    # They will be asked for Government Gateway credentials and
    # to approve access to the specified scope for our application.
    my $url = $auth->authorisation_url({
        scopes => ['read:vat', 'write:vat'],
        redirect_uri => 'urn:ietf:wg:oauth:2.0:oob',
        state => 'session-cookie-hash-or-similar-opaque-value',
    });

    # Once user has authorised our application, an authorisation code
    # is generated. This is either copy/pasted back into our application
    # by the user, or supplied via a callback uri. The
    # authorisation code is valid for 10 minutes.

    # Exchange access code for an access token.
    my $result = $auth->get_access_token({
        access_code => $access_code,
        redirect_uri => 'urn:ietf:wg:oauth:2.0:oob',
    });
    $result->is_success or warn "ERROR: ", $result->data->{message};

    # Has token expired?
    my $expired = ($auth->expires_epoch <= time);

    # The token can be refreshed as long as authority hasn't been revoked
    # for the application and was granted less than 18 months ago.
    # Typically an access token is valid for 4 hours.
    $auth->refresh_tokens;

    # The tokens can be retained and used by another instance
    my $new_auth = WebService::HMRC::Authenticate->new({
        client_id => $client_id,
        client_secret => $client_secret,
        access_token => $access_token,
        refresh_token => $refresh_token,
    })

    # Refreshing will then populate scope and expires_epoch properties
    $new_auth->refresh;

=head1 DESCRIPTION

This module is part of the L<WebService::HMRC> suite of Perl modules for
interacting with the UK's HMRC Making Tax Digital APIs.

It is generally used by other classes which implement bindings to HMRC APIs
rather than being used directly.

This module handles authentication with HMRC using OAuth2. For more detail
see:
L<https://developer.service.hmrc.gov.uk/api-documentation/docs/authorisation/user-restricted-endpoints>

To use this module, an application must first be registered with HMRC, who
will issue client and application credentials.

=head1 INSTALLATION AND TESTING

See documentation for L<WebService::HMRC>.
    
=head1 PROPERTIES

=head2 server_token

Secret server token issued by HMRC for the application using this module. Must be defined
to call application-restricted endpoints. 

=cut

has server_token => (
    is => 'rw',
    isa => 'Str',
    predicate => 'has_server_token',
);

=head2 client_id

The Client ID issued by HMRC for the application using this class.

=cut

has client_id => (
    is => 'rw',
    isa => 'Str',
    predicate => 'has_client_id',
);

=head2 client_secret

The Client Secret issued by HMRC for the application using this class.

=cut

has client_secret => (
    is => 'rw',
    isa => 'Str',
    predicate => 'has_client_secret',
);

=head2 access_token

The access token issued by HMRC. Updated automatically when a new token
is requested using access_token() or refresh_token() methods, or can be
set explicitly to use an existing token.

Access tokens are typically valid for four hours after issue or until
a refreshed token is requested.

=cut

has access_token => (
    is => 'rw',
    isa => 'Str',
    predicate => 'has_access_token',
    clearer => 'clear_access_token',
);

=head2 refresh_token

The refresh token issued by HMRC. Updated automatically when a new token
is requested using access_token() or refresh_token() methods, or can be
set explicitly to use an existing refresh_token.

Refresh tokens are typically valid for 18 months after the application was
last authorised by the user, unless revoked, or until a new refresh token
is requested.

=cut

has refresh_token => (
    is => 'rw',
    isa => 'Str',
    predicate => 'has_refresh_token',
    clearer => 'clear_refresh_token',
);

=head2 expires_epoch

Expiry time of the current access_token and refresh_token specified in seconds
since the perl epoch.

=cut

has expires_epoch => (
    is => 'rw',
    isa => 'Int',
    clearer => 'clear_expires_epoch',
);

=head2 scopes

Arrayref containing a list of scopes for which the current authorisation
tokens are valid. Scopes are specific and documented for each of HMRC's APIs.
For example 'read:vat' or 'write:employment'.

Updated according the the HMRC api response when a new token is requested using
access_token() or refresh_token() methods.

=cut

has scopes => (
    is => 'rw',
    isa => 'ArrayRef',
    predicate => 'has_scopes',
    clearer => 'clear_scopes',
);

=head1 METHODS

=head2 authorisation_url({ scopes => \@scopes, redirect_uri => $uri, [state => $state] })

Returns a URI object representing the url to which the a user should be
directed to authorise this application for the specified scopes. In string
context, this return value evaluates to a fully-qualified url.

=head3 Parameters:

=over

=item scopes

Reference to an array containing the scopes to which access is sought. The scope
names and their application are defined in the documentation for each api.

For example: ['read:employment', 'read:vat', 'write:vat']

=item redirect_uri

Where the user will be redirected once access is granted or denied. This must
have been associated with the application using the HMRC developer web site.
See:
L<https://developer.service.hmrc.gov.uk/api-documentation/docs/reference-guide#redirect-uris>

=item state

Optional parameter. The value specified here is returned as a parameter to the
redirect_uri and should be checked to ensure that the redirect is a genuine
response to our authorisation request.

=back

=cut

sub authorisation_url {

    my ($self, $args) = @_;

    defined $args->{scopes} or croak 'scopes not defined';
    defined $args->{redirect_uri} or croak 'redirect_uri not defined';
    $self->has_client_id or croak 'client_id property not defined for object';

    my $uri = $self->endpoint_url('/oauth/authorize');
    my $scope_string = join(' ', @{$args->{scopes}});
    my $query_params = {
        response_type => 'code',
        client_id => $self->client_id,
        scope => $scope_string,
        redirect_uri => $args->{redirect_uri}
    };

    # state is an optional parameter
    if(defined $args->{state}) {
        $query_params->{state} = $args->{state};
    }

    $uri->query_form($query_params);

    return $uri;
}


=head2 get_access_token({ access_code => $access_code, redirect_uri => $redirect_uri })

Exchanges the supplied access_code for an access_token.

Both client_id and client_secret object properties must be set before calling
this method.

The redirect_uri parameter must match that used when the access_code was 
requested.

Returns a WebService::HMRC::Response object.

The object's scopes, access_token, refresh_token and expires_epoch properties are
updated when this method is called.

See L<https://developer.service.hmrc.gov.uk/api-documentation/docs/authorisation/user-restricted-endpoints>
for more information about response data and possible error codes.

=cut

sub get_access_token {

    my ($self, $args) = @_;

    defined $args->{authorisation_code} or croak 'authorisation_code not defined';
    defined $args->{redirect_uri} or croak 'redirect_uri not defined';
    $self->has_client_id or croak 'client_id property not defined for object';
    $self->has_client_secret or croak 'client_secret property not defined for object';

    my $uri = $self->endpoint_url('/oauth/token');
    my $params = {
        grant_type => 'authorization_code',
        client_id => $self->client_id,
        client_secret => $self->client_secret,
        code => $args->{authorisation_code},
        redirect_uri => $args->{redirect_uri}
    };
    my $http_response = $self->ua->post($uri, $params);
    my $result = WebService::HMRC::Response->new(http => $http_response);
    $self->extract_tokens($result->data);

    return $result;
}


=head2 refresh_tokens()

Exchanges the current tokens for a new access_token

The properties client_id, client_secret object properties must be set before calling
this method.

The object's scopes, access_token, refresh_token and expires_epoch properties are
updated when this method is called.

Returns a WebService::HMRC::Response object. 

See L<https://developer.service.hmrc.gov.uk/api-documentation/docs/authorisation/user-restricted-endpoints>
for more information about response data and possible error codes.

=cut

sub refresh_tokens {

    my $self = shift;

    $self->has_refresh_token or croak 'refresh_token not defined for object';
    $self->has_client_id or croak 'client_id property not defined for object';
    $self->has_client_secret or croak 'client_secret not defined for object';

    my $uri = $self->endpoint_url('/oauth/token');
    my $params = {
        grant_type => 'refresh_token',
        client_id => $self->client_id,
        client_secret => $self->client_secret,
        refresh_token => $self->refresh_token,
    };
    my $http_response = $self->ua->post($uri, $params);
    my $result = WebService::HMRC::Response->new(http => $http_response);
    $self->extract_tokens($result->data);

    return $result;
}


=head2 extract_tokens($hashref)

Accepts a hashref representing a set of tokens, such as the response from
an hmrc token endpoint.

Updates the access_token, refresh_token and expires_epoch properties of this
class.

Returns true on success.

On error, clears the access_token, refresh_token, scopes and expires_epoch
properties and returns false.

A typical token hashref comprises:

    {
      'scope'         => 'read:vat read:employment',# API specific
      'token_type'    => 'bearer',                  # Always 'bearer'
      'expires_in'    => 14400,                     # seconds until expiration
      'refresh_token' => '806d848e5e78fee92c9a38e6b7a3',
      'access_token'  => '7d46efbcbff7892295894e21f940d118'
    }

The token will be rejected if token_type is not 'bearer'.

=cut

sub extract_tokens {

    my $self = shift;
    my $token = shift;

    return try {
        $token->{token_type} && $token->{token_type} eq 'bearer'
            or croak 'token type value is not `bearer`';
        $token->{expires_in} or croak 'expires_in parameter missing from token';
        $token->{expires_in} =~ m/^\d+$/ or croak 'expires_in value is not numeric';

        $self->expires_epoch(time + $token->{expires_in});
        $self->access_token($token->{access_token});
        $self->refresh_token($token->{refresh_token});
        $self->scopes( $self->split_scope_string($token->{scope}) );
        return 1;
    }
    catch {
        carp "Error parsing token: $_\n";
        $self->clear_expires_epoch;
        $self->clear_access_token;
        $self->clear_refresh_token;
        $self->clear_scopes;
        return 0;
    };
}


=head2 split_scope_string($string)

Given a string containing space-delimited authorisation scopes
(e.g. 'read:vat write:employment write_vat'), split into an array
of individual scope names.

Returns an array reference, or undef if the input is undefined.

=cut

sub split_scope_string {

    my $self = shift;
    my $string = shift;

    defined $string or croak 'scopes text string is unefined';

    my @scopes = split / /, $string;
    $self->scopes(\@scopes);

    return \@scopes;
}


=head2 has_scope($scope)

Returns true if the current authorisation tokens are associated with the
specified scope.

The scope of the current tokens is only known (and this method is therefore
only meaningful) after a call to `get_access_token()` or `refresh_tokens()`,
unless the scopes property has been explicitly initialised.

If the scope of the current tokens has not been initialised, this method will
croak.

=cut

sub has_scope {

    my $self = shift;
    my $scope = shift;

    $self->has_scopes
        or croak 'Token scopes are undetermined. Try calling refresh() method before testing scopes';

    return List::Util::any {$_ eq $scope} @{$self->scopes};
}


=head1 AUTHOR

Nick Prater <nick@npbroadcast.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-hmrc at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-HMRC>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::HMRC::Authenticate


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-HMRC>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-HMRC>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-HMRC/>

=back

=head1 ACKNOWLEDGEMENTS

This module was originally developed for use as part of the
L<LedgerSMB|https://ledgersmb.org/> open source accounting software.

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Nick Prater, NP Broadcast Limited.

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

__PACKAGE__->meta->make_immutable;
1;
