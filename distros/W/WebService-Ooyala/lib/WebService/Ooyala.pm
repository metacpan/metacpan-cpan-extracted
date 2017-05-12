package WebService::Ooyala;

use 5.006;
use strict;
use warnings FATAL => 'all';
use URI::Escape qw(uri_escape);
use LWP::UserAgent;
use Carp qw(croak);
use Digest::SHA qw(sha256_base64);
use JSON;

=head1 NAME

WebService::Ooyala - Perl interface to Ooyala's API, currently only read
operations (GET requests) are supported

Support for create, update, and delete (PUT, POST, DELETE) operations will be added in future releases.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    my $ooyala = WebService::Ooyala->new({ api_key => $api_key, secret_key => $secret_key });

    # Grab all video assets (or at least the first page)
    my $data = $ooyala->get("assets");

    foreach my $video(@{$data->{items}}) {
        print "$video->{embed_code} $video->{name}\n";
    }

    # Get a particular video based on embed_code

    my $video = $data->get("assets/$embed_code");


=head1 SUBROUTINES/METHODS

=head2 new

Create a new WebService::Ooyala object with hashref of parameters

    my $ooyala = WebService::Ooyala->new( { api_key => $api_key, secret_key => $secret_key } );

Accepts the following parmeters

=over 4

=item * api_key

Required parameter. Ooyala api_key

=item * secret_key

Required parameter. Ooyala secret_key

=item * base_url

Optional parameter -- defaults to "api.ooyala.com"

=item * cache_base_url

Optional parameter - defaults to "cdn.api.ooyala.com" for GET requests

=item * expiration

Optional parametter for time to expire url for getting results from API with
this url -- defaults to 15 (seconds)

=item * api_version

Optional parameter - version of API being called -- defaults to "v2", but this
module also works for "v3" API requests by changing this parameter

=item * agent

Agent that acts like LWP::UserAgent used for making requests -- module defaults to creating its own if none is provide

=back

=cut

sub new {
	my($class, $params) = @_;
	$params ||= {};

	my $self = {};
	$self->{api_key}    = $params->{api_key};
	$self->{secret_key} = $params->{secret_key};

    croak "api_key and secret_key both need to be specified" unless $params->{api_key} && $params->{secret_key};

	$self->{base_url}   = $params->{base_url} || "api.ooyala.com";
	$self->{cache_base_url} =
		$params->{cache_base_url} || "cdn-api.ooyala.com";
	$self->{expiration}  = $params->{expiration}  || 15;
	$self->{api_version} = $params->{api_version} || "v2";
	$self->{agent} =
		LWP::UserAgent->new(
		agent => "perl/$], WebService::Ooyala/" . $VERSION);

	bless $self, $class;

}

=head2 get

$ooyala->get($path, $params)

$ooyala->get("assets");

$ooyala->get("assets", { limit => 5 })

$ooyala->get("assets", { limit => 5, where => "labels INCLUDES '$label'" })

Accepts the following parameters:

=over 4

=item * path - path of api request (after version part of api request)

=item * params - hashref of query parameters to be sent as part of API request

=back

-




=cut

sub get {
	my($self, $path, $params) = @_;
	return $self->send_request('GET', $path, '', $params);
}

=head2 expires

Calculates expiration time

$ooyala->expires()

=cut

sub expires {
	my($self) = @_;
	my $now_plus_window = time() + $self->{expiration};
	return $now_plus_window + 300 - ($now_plus_window % 300);
}

=head2 send_request

$ooyala->send_request($http_method, $relative_path, $body, $params);

$ooyala->send_request("GET", "assets", "", {})

Handles sending request to ooyala's API, suggest using simpler

$ooyala->get(..) (which calls this) from your application

=cut

sub send_request {
	my($self, $http_method, $relative_path, $body, $params) = @_;

	my $path = "/" . $self->{api_version} . "/" . $relative_path;

	my $json_body = {};

	my $url =
		$self->build_path_with_authentication_params($http_method, $path,
		$params, "");

	if (!$url) {
		croak "No url generated for request in send_request";
	}

	my $base_url;
	if ($http_method ne 'GET') {
		$base_url = $self->{base_url};
	} else {
		$base_url = $self->{cache_base_url};
	}

	my $resp;
	if ($http_method eq 'GET') {
		my $full_url = "https://" . $base_url . $url;
		$resp = $self->{agent}->get($full_url);

		unless ($resp->is_success) {
			croak "Failed to GET $full_url - " . $resp->status_line;
		}

		if ($resp->is_success) {
			return decode_json($resp->decoded_content);
		}
	} else {
		croak
			"Trying to call a method that is not implemented in send_request";
	}
}

=head2 generate_signature

    Generates signature needed to send API request based on payload

    $ooyala->($http_method, $path, $params, $body);

=cut

sub generate_signature {
	my($self, $http_method, $path, $params, $body) = @_;
	$body ||= '';

	my $signature = $self->{secret_key} . uc($http_method) . $path;

	foreach my $key (sort keys %$params) {
		$signature .= $key . "=" . $params->{$key};
	}

	$signature = sha256_base64($signature);
	return $signature;
}

=head2 build_path

    Builds path up with parameters

    $ooyala->build_path($path, $params(

=cut

sub build_path {
	my($self, $path, $params) = @_;
	my $url = $path . '?';
	foreach (keys %$params) {
		$url .= "&$_=" . uri_escape($params->{$_});
	}
	return $url;
}

=head2 build_path_with_authentication_params

    Builds path with authentication and expiration parameters

    $ooyala->build_path_with_authentication_params($http_method, $path,
    $params, $body);

=cut

sub build_path_with_authentication_params {
	my($self, $http_method, $path, $params, $body) = @_;

	$params ||= {};
	my $authentication_params = {%$params};
	$authentication_params->{api_key} = $self->{api_key};
	$authentication_params->{expires} = $self->expires();
	$authentication_params->{signature} =
		$self->generate_signature($http_method, $path,
		$authentication_params, $body);
	return $self->build_path($path, $authentication_params);

}

=head2 get_api_key

    Gets current ooyala api_key

    my $api_key = $ooylaa->get_api_key();

=cut

sub get_api_key {
	my $self = shift;
	return $self->{api_key};
}

=head2 set_api_key

    Sets current ooyala api_key

    $ooylaa->set_api_key($api_key);

=cut

sub set_api_key {
	my($self, $api_key) = @_;
	$self->{api_key} = $api_key;
}

=head2 get_secret_key

    Gets current ooyala secret_key

    my $secret_key = $ooyala->get_secret_key()

=cut

sub get_secret_key {
	my $self = shift;
	return $self->{secret_key};
}

=head2 set_secret_key

    Sets current ooyala secret_key

    $ooyala->set_secret_key($secret_key)

=cut

sub set_secret_key {
	my($self, $secret_key) = @_;
	$self->{secret_key} = $secret_key;
}

=head2 get_base_url

    Gets current base_url

    my $base_url = $ooyala->get_base_url();

=cut

sub get_base_url {
	my $self = shift;
	return $self->{base_url};
}

=head2 set_base_url

    Sets current base_url

    $ooyala->set_base_url($base_url)

=cut

sub set_base_url {
	my($self, $base_url) = @_;
	$self->{base_url} = $base_url;
}

=head2 get_cache_base_url

    Gets current cache_base_url

    my $cache_base_url = $ooyala->get_cache_base_url();

=cut

sub get_cache_base_url {
	my $self = shift;
	return $self->{cache_base_url};
}

=head2 set_cache_base_url

    Sets current cache_base_url

    $ooyala->set_cache_base_url($cache_base_url)

=cut

sub set_cache_base_url {
	my($self, $cache_base_url) = @_;
	$self->{cache_base_url} = $cache_base_url;
}

=head2 get_expiration

    Gets current expiration in seconds

    my $expiration = $ooyala->get_expiration();

=cut

sub get_expiration {
	my $self = shift;
	return $self->{expiration};
}

=head2 set_expiration

    Sets current expiration in seconds

    $ooyala->set_expiration($expiration);

=cut

sub set_expiration {
	my($self, $expiration) = @_;
	$self->{expiration} = $expiration;
}

=head2 del_expiration

    Sets current expiration time to 0

    $ooyala->del_expiration()

=cut

sub del_expiration {
	my $self = shift;
	$self->{expiration} = 0;
}

=head1 SEE ALSO

Code here is a port of L<Ooyala's Python SDK|https://github.com/ooyala/python-v2-sdk>

L<Ooyala API Documentation|http://support.ooyala.com/developers/documentation/concepts/book_api.html>

=head1 ACKNOWLEDGEMENTS

Thanks to Slashdot for support in release of this module -- early code for
this was developed as part of the Slashdot code base

=head1 AUTHOR

Tim Vroom, C<< <vroom at blockstackers.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-ooyala at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Ooyala>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Ooyala


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Ooyala>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Ooyala>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Ooyala>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Ooyala/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Tim Vroom.

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

1;    # End of WebService::Ooyala
