#!/usr/bin/perl

use strict;
use warnings;
use 5.10.1;

use JSON;
use LWP::UserAgent;
use LWP::Protocol::https;

package WebService::ShiftPlanning;

our $VERSION = 0.01;

=head1 NAME

WebService::ShiftPlanning - Minimal ShiftPlanning API call support for Perl

=head1 SYNOPSIS

  use WebService::ShiftPlanning;
  my $caller = WebService::ShiftPlanning->new;
  $caller->doLogin('username', 'password');
  use Data::Dumper;
  print ::Dumper($caller->doCall('GET', 'dashboard.onnow'));

=head1 DESCRIPTION

A basic API wrapper for ShiftPlanning, supporting authentication, making calls, and throwing exceptions on error.

=head1 METHODS

=head2 new

Create a new WebService::ShiftPlanning object.

Takes the http endpoint and api key as optional hash parameters.

  my $agent = WebService::ShiftPlanning->new();

  my $agent = WebService::ShiftPlanning->new(
     endpoint => 'https://www.shiftplanning.com/api/',
     key => '234243iyu23i4y23409872309470923740987234',
  );

=cut

sub new {
    my $class = shift;
    my %parms = (
        endpoint => 'https://www.shiftplanning.com/api/',
        key => undef,
        token => undef,
        @_
    );
    return bless \%parms,$class;
}

=head2 doLogin

Log in to shiftplanning.com

=cut

sub doLogin {
    my $self = shift;
    my ($username, $password) = @_;
    if (!defined($self->{key})) {
        die("You must specify your API key to the 'new' method; see perldoc WebService::ShiftPlanning");
    }
    my $ua = LWP::UserAgent->new();
    my $json = JSON::encode_json({
        key => $self->{key},
        request => {
            module => 'staff.login',
            method => 'GET',
            username => $username,
            password => $password
        }
    });
    # The request format is awful, it's application/x-www-form-urlencoded with
    # the json data in a single key 'data'. The API does not understand application/json
    my $response = $ua->post($self->{endpoint}, { data => $json } );
    if ($response->is_success) {
        # Shiftplanning API likes to return 200 OK with an error code embedded in the JSON result
        my(%r) = %{JSON::decode_json($response->decoded_content)};
        if ($r{'status'} == 1) {
            $self->{'token'} = $r{'token'};
        } else {
            die("Shiftplanning API error $r{status} with error $r{error} on login attempt; login failed.");
        }
    } else {
        die("HTTP error " . $response->code . ": " . $response->message . "; unable to login to shiftplanning");
    }
}

=head2 doCall

Make a ShiftPlanning API call. Usage:

  doCall(method, module, param => value);

eg:

  doCall('GET', 'dashboard.onnow');

Dies on HTTP error or on ShiftPlanning.com API error (non-1 status). Otherwise
returns Perl hash/array decoded from the JSON response from the server.

For the details of usage, you'll need to use the ShiftPlanning API docs.

=cut

sub doCall {
    my $self = shift;
    my ($method, $module, %request) = @_;
    my $ua = LWP::UserAgent->new();
    my $json = JSON::encode_json({
        token => $self->{token},
        key => $self->{key},
        module => $module,
        method => $method,
        request => \%request
    });
    my $response = $ua->post($self->{endpoint}, { data => $json } );
    if ($response->is_success) {
        my (%r) = %{JSON::decode_json($response->decoded_content)};
        if ($r{'status'} == 1) {
            # Request successful, return the json result
            return $r{'data'};
        } else {
            die("ShiftPlanning API error $r{status} with error $r{error} on request $method");
        }
    } else {
        die("HTTP error " . $response->code . ": " . $response->message . "; unable to perform request");
    }
}

1;
