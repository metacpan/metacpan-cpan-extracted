package Tomba::Client;

use 5.026001;
use strict;
use warnings;
use LWP::UserAgent;
use URI;
use JSON qw(encode_json decode_json);
use URI::Escape qw(uri_escape);
use Carp qw(croak);

our $VERSION = '1.1.1';

# Tomba base url
use constant DEFAULT_BASE_URL => 'https://api.tomba.io/v1';

# Account path
use constant ACCOUNT_PATH => "/me";
# Usage path
use constant USAGE_PATH => "/usage";
# Logs path
use constant LOGS_PATH => "/logs";
# Search path
use constant SEARCH_PATH => "/domain-search";
# Finder path
use constant FINDER_PATH => "/email-finder";
# Enrichment path
use constant ENRICHMENT_PATH => "/enrich";
# Author path
use constant AUTHOR_PATH => "/author-finder";
# Linkedin path
use constant LINKEDIN_PATH => "/linkedin";
# Verifier path
use constant VERIFIER_PATH => "/email-verifier";
# Email Sources path
use constant SOURCES_PATH => "/email-sources";
# Email Count path
use constant COUNT_PATH => "/email-count";
# Domain status path
use constant STATUS_PATH => "/domain-status";
# Autocomplete path
use constant AUTOCOMPLETE_PATH => "/domain-suggestions";
# Phone Finder path
use constant PHONE_FINDER_PATH => "/phone-finder";
# Phone Validator path
use constant PHONE_VALIDATOR_PATH => "/phone-validator";
# Email Format path
use constant EMAIL_FORMAT_PATH => "/email-format";
# Location path
use constant LOCATION_PATH => "/location";
# Similar path
use constant SIMILAR_PATH => "/similar";
# Technology path
use constant TECHNOLOGY_PATH => "/technology";
# Person Find (Clearbit-compatible)
use constant PERSON_FIND_PATH => "/people/find";
# Company Find (Clearbit-compatible)
use constant COMPANY_FIND_PATH => "/companies/find";
# Combined Find (Clearbit-compatible)
use constant COMBINED_FIND_PATH => "/combined/find";
# Companies search (Reveal)
use constant COMPANIES_SEARCH_PATH => "/reveal/search";
# Keys path
use constant KEYS_PATH => "/keys";
# Flag path
use constant FLAG_PATH => "/flag";
# Leads path
use constant LEADS_PATH => "/leads";
# Leads Lists path
use constant LEADS_LISTS_PATH => "/leads_lists";
# Attributes path
use constant ATTRIBUTES_PATH => "/attributes";

# Bulk type paths
use constant BULK_SEARCH_PATH    => "/bulk/search";
use constant BULK_FINDER_PATH    => "/bulk/finder";
use constant BULK_VERIFIER_PATH  => "/bulk/verifier";
use constant BULK_ENRICH_PATH    => "/bulk/enrich";
use constant BULK_AUTHOR_PATH    => "/bulk/author";
use constant BULK_LINKEDIN_PATH  => "/bulk/linkedin";
use constant BULK_COMPANY_PATH   => "/bulk/company";
use constant BULK_PHONE_FINDER_PATH    => "/bulk/phone-finder";
use constant BULK_PHONE_VALIDATOR_PATH => "/bulk/phone-validator";
use constant BULK_SIMILAR_PATH         => "/bulk/similar";

#-------------------------------------------------------------------------------

=head1 NAME

Tomba::Client - Base HTTP client for the Tomba.io API

=head1 SYNOPSIS

  use Tomba::Client;

  my $client = Tomba::Client->new("ta_xxxxx", "ts_xxxxx");

  # GET request
  my $result = $client->call("/me");

  # POST request
  my $result = $client->post("/leads", { email => "test@example.com" });

=head1 DESCRIPTION

This module provides the base HTTP client used by all Tomba service modules.
It handles authentication, request construction, and JSON parsing.

Normally you would not use this module directly; instead use
L<Tomba::Finder> or the individual service modules (L<Tomba::Account>,
L<Tomba::Domain>, etc.) which inherit from this class.

=cut

#-------------------------------------------------------------------------------
# Constructor
#-------------------------------------------------------------------------------

=head2 new

  my $client = Tomba::Client->new($api_key, $api_secret);
  my $client = Tomba::Client->new($api_key, $api_secret, $base_url);

Creates a new Tomba::Client instance.

See L<https://docs.tomba.io/authentication>

=cut

sub new {
    my ($class, $apiKey, $apiSecret, $baseUrl) = @_;

    my $self = {};

    $self->{baseUrl} = $baseUrl || DEFAULT_BASE_URL;

    if (length($apiKey) < 39) {
        croak "Invalid Tomba api key";
    } else {
        $self->{apiKey} = $apiKey;
    }

    if (length($apiSecret) < 39) {
        croak "Invalid Tomba api secret";
    } else {
        $self->{apiSecret} = $apiSecret;
    }

    bless $self, $class;

    return $self;
}

#-------------------------------------------------------------------------------
# HTTP Methods
#-------------------------------------------------------------------------------

=head2 call

  my $result = $client->call($path, $params);

Makes a GET request to the Tomba API.

  Arg 1: Str $path - the path portion of the URL to request
  Arg 2: HashRef $params - a hashref of query parameters to include in the URL
  Returns: JSON response as a Perl hashref, or undef on error

=cut

sub call {
    my ($self, $path, $params) = @_;

    $self->{ua} = LWP::UserAgent->new;
    $self->{ua}->default_headers(HTTP::Headers->new(
        'X-Tomba-Key'    => $self->{apiKey},
        'X-Tomba-Secret' => $self->{apiSecret},
        'Accept'         => 'application/json',
        'Content-Type'   => 'application/json',
    ));
    $self->{ua}->agent("Tomba-Finder/Perl/$VERSION");
    $self->{ua}->timeout(120);

    my $url = $self->{baseUrl} . $path;

    if ($params && ref($params) eq 'HASH' && %$params) {
        $url .= '?' . join('&', map { uri_escape($_) . '=' . uri_escape($params->{$_}) } keys %$params);
    }

    my $response = $self->{ua}->get($url);
    my $content = $response->decoded_content;
    if ($response->is_success) {
        $self->{body} = decode_json($content);
    } else {
        $self->{body} = eval { decode_json($content) } || { status => $response->code, message => $content };
    }

    my $rate_limit = _parse_rate_limit_headers($response);

    return { data => $self->{body}, rate_limit => $rate_limit };
}

=head2 call_raw

  my $result = $client->call_raw($path, $params);

Makes a GET request to the Tomba API and returns the raw response body
as a string without JSON decoding. Useful for endpoints that return
non-JSON content such as CSV downloads.

  Arg 1: Str $path - the path portion of the URL to request
  Arg 2: HashRef $params - a hashref of query parameters to include in the URL
  Returns: HashRef with raw response string in 'data' and rate_limit info

=cut

sub call_raw {
    my ($self, $path, $params) = @_;

    $self->{ua} = LWP::UserAgent->new;
    $self->{ua}->default_headers(HTTP::Headers->new(
        'X-Tomba-Key'    => $self->{apiKey},
        'X-Tomba-Secret' => $self->{apiSecret},
        'Accept'         => 'application/json',
        'Content-Type'   => 'application/json',
    ));
    $self->{ua}->agent("Tomba-Finder/Perl/$VERSION");
    $self->{ua}->timeout(120);

    my $url = $self->{baseUrl} . $path;

    if ($params && ref($params) eq 'HASH' && %$params) {
        $url .= '?' . join('&', map { uri_escape($_) . '=' . uri_escape($params->{$_}) } keys %$params);
    }

    my $response = $self->{ua}->get($url);

    my $rate_limit = _parse_rate_limit_headers($response);

    return { data => $response->decoded_content, rate_limit => $rate_limit };
}

=head2 post

  my $result = $client->post($path, $body, $params);

Makes a POST request to the Tomba API with a JSON body.

  Arg 1: Str $path - the path portion of the URL
  Arg 2: HashRef $body - a hashref to be encoded as JSON in the request body
  Arg 3: HashRef $params (optional) - query parameters
  Returns: JSON response as a Perl hashref, or undef on error

=cut

sub post {
    my ($self, $path, $body, $params) = @_;
    return $self->_request('POST', $path, $body, $params);
}

=head2 put

  my $result = $client->put($path, $body, $params);

Makes a PUT request to the Tomba API with a JSON body.

  Arg 1: Str $path - the path portion of the URL
  Arg 2: HashRef $body - a hashref to be encoded as JSON in the request body
  Arg 3: HashRef $params (optional) - query parameters
  Returns: JSON response as a Perl hashref, or undef on error

=cut

sub put {
    my ($self, $path, $body, $params) = @_;
    return $self->_request('PUT', $path, $body, $params);
}

=head2 delete_request

  my $result = $client->delete_request($path, $params);

Makes a DELETE request to the Tomba API.

  Arg 1: Str $path - the path portion of the URL
  Arg 2: HashRef $params (optional) - query parameters
  Returns: JSON response as a Perl hashref, or undef on error

=cut

sub delete_request {
    my ($self, $path, $params) = @_;
    return $self->_request('DELETE', $path, undef, $params);
}

# Internal method for POST/PUT/DELETE requests
sub _request {
    my ($self, $method, $path, $body, $params) = @_;

    $self->{ua} = LWP::UserAgent->new;
    $self->{ua}->default_headers(HTTP::Headers->new(
        'X-Tomba-Key'    => $self->{apiKey},
        'X-Tomba-Secret' => $self->{apiSecret},
        'Accept'         => 'application/json',
        'Content-Type'   => 'application/json',
    ));
    $self->{ua}->agent("Tomba-Finder/Perl/$VERSION");
    $self->{ua}->timeout(120);

    my $url = $self->{baseUrl} . $path;

    if ($params && ref($params) eq 'HASH' && %$params) {
        $url .= '?' . join('&', map { uri_escape($_) . '=' . uri_escape($params->{$_}) } keys %$params);
    }

    my $json_body = '';
    if ($body && ref($body) eq 'HASH') {
        $json_body = encode_json($body);
    }

    my $response;
    if ($method eq 'POST') {
        $response = $self->{ua}->post($url, Content => $json_body);
    } elsif ($method eq 'PUT') {
        $response = $self->{ua}->put($url, Content => $json_body);
    } elsif ($method eq 'DELETE') {
        my $req = HTTP::Request->new(DELETE => $url);
        $req->header('X-Tomba-Key'    => $self->{apiKey});
        $req->header('X-Tomba-Secret' => $self->{apiSecret});
        $req->header('Accept'         => 'application/json');
        $req->header('Content-Type'   => 'application/json');
        $response = $self->{ua}->request($req);
    }

    my $content = $response->decoded_content;
    if ($content && length($content) > 0) {
        $self->{body} = eval { decode_json($content) } || { status => $response->code, message => $content };
    } else {
        $self->{body} = { status => $response->code };
    }

    my $rate_limit = _parse_rate_limit_headers($response);

    return { data => $self->{body}, rate_limit => $rate_limit };
}

# Internal: extract rate-limit headers from an HTTP::Response
sub _parse_rate_limit_headers {
    my ($response) = @_;
    my @header_names = qw(
        x-second-rate-limit
        x-minute-rate-limit
        x-daily-rate-limit
        x-minute-request-left
        x-daily-request-left
        x-minute-reset-seconds
        x-daily-reset-seconds
        Retry-After
        RateLimit-Policy
        RateLimit
    );
    my %rate_limit;
    for my $name (@header_names) {
        my $val = $response->header($name);
        if (defined $val) {
            $rate_limit{lc($name)} = $val;
        }
    }
    return \%rate_limit;
}

1;
__END__

=head1 AUTHOR

Mohamed Ben rebia, E<lt>b.mohamed@tomba.ioE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2023 Mohamed Benrebia <b.mohamed@tomba.io>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
