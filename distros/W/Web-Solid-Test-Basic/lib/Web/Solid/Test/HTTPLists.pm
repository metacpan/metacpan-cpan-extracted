package Web::Solid::Test::HTTPLists;

use 5.010001;
use strict;
use warnings;
use parent 'Test::FITesque::Fixture';
use Test::More;
use LWP::UserAgent;
use Test::Deep;
use Test::RDF;
use Data::Dumper;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.006';

my $bearer_predicate = 'http://example.org/httplist/param#bearer'; # TODO: Define proper URI

sub http_req_res_list_regex_reuser : Test : Plan(1)  {
  my ($self, $args) = @_;
  my @pairs = @{$args->{'-special'}->{'http-pairs'}}; # Unpack for readability
  my @matches;
  subtest $args->{'-special'}->{description} => sub {
	 plan tests => scalar @pairs;
	 my $ua = LWP::UserAgent->new;
	 subtest "First request" => sub {
		my $request_no = 0;
		my $request = $pairs[$request_no]->{request};
		if ($args->{$bearer_predicate}) {
		  $request->header( 'Authorization' => _create_authorization_field($args->{$bearer_predicate}, $request->uri));
		}

		my $response = $ua->request( $request );
		my $expected_response = $pairs[$request_no]->{response};
		my $regex_fields = $pairs[$request_no]->{'regex-fields'};
		my @expected_header_fields = $expected_response->header_field_names;
		foreach my $expected_header_field (@expected_header_fields) { # TODO: Date-fields may fail if expectation is dynamic
		  if ($regex_fields->{$expected_header_field}) { # Then, we have a regular expression from the RDF to match
			 my $regex = $expected_response->header($expected_header_field);
			 like($response->header($expected_header_field), qr/$regex/, "\'$expected_header_field\'-header matches given regular expression");
			 my @res_matches = $response->header($expected_header_field) =~ m/$regex/;
			 push(@matches, \@res_matches);
			 $expected_response->remove_header($expected_header_field); # So that we can test the rest with reusable components
		  }
		}

		_subtest_compare_req_res($request, $response, $expected_response);

	 };

	 subtest "Second request" => sub {
		my $request_no = 1;
		my $request = $pairs[$request_no]->{request};
		unless (defined($request->uri)) {
		  # ASSUME: RequestURI was not given, it has to be derived from the previous request through a match
		  # ASSUME: The first match of the previous request is the relative URI to be used for the this request
		  # ASSUME: The base URI is the RequestURI for the previous request
		  my $uri = URI->new_abs($matches[$request_no-1]->[0], $pairs[$request_no-1]->{request}->uri);
		  $request->uri($uri);
		}
		if ($args->{$bearer_predicate}) {
		  $request->header( 'Authorization' => _create_authorization_field($args->{$bearer_predicate}, $request->uri));
		}
		my $response = $ua->request($request);
		my $expected_response = $pairs[$request_no]->{response};
		_subtest_compare_req_res($request, $response, $expected_response);
	 };
  };
}

sub http_req_res_list : Test : Plan(1)  {
  my ($self, $args) = @_;
  my @pairs = @{$args->{'-special'}->{'http-pairs'}}; # Unpack for readability
  my $ua = LWP::UserAgent->new;
  subtest $args->{'-special'}->{description} => sub {
	 plan tests => scalar @pairs;
	 my $counter = 1;
	 foreach my $pair (@pairs) {
		my $request = $pair->{request};
		_check_origin($request);
		if ($args->{$bearer_predicate}) {
		  $request->header( 'Authorization' => _create_authorization_field($args->{$bearer_predicate}, $request->uri));
		}
		my $response = $ua->request( $request );
		subtest "Request-response #" . ($counter) =>
		  \&_subtest_compare_req_res, $request, $response, $pair->{response}; #Callback syntax isn't pretty, admittedly
		$counter++;
	 }
  };
}


sub _subtest_compare_req_res {
  my ($request, $response, $expected_response) = @_;
  isa_ok($response, 'HTTP::Response');
  if ($expected_response->code) {
	 is($response->code, $expected_response->code, "Response code is " . $expected_response->code)
		|| note "Returned content:\n" . $response->as_string;
  }
  my @expected_header_fields = $expected_response->header_field_names;
  if (scalar @expected_header_fields) {
	 subtest 'Testing all headers' => sub {
		plan tests => scalar @expected_header_fields;
		foreach my $expected_header_field (@expected_header_fields) { # TODO: Date-fields may fail if expectation is dynamic
		  if (defined($response->header($expected_header_field))) {
			 # The following line is a hack to parse field values
			 # with multiple values. Comma-separated lists are a
			 # common occurence, but as of RFC7230, they are not
			 # defined in the HTTP standard itself, it is left to
			 # each individual spec to define the syntax if the
			 # field values, so it is an open world. It would
			 # therefore be inappropriate to implement just
			 # splitting by comma (and whitespace) in a general
			 # purpose framework, even though it will work in most
			 # cases. Since it works for us now it makes sense to
			 # implement it as such for now.  A more rigorous
			 # solution to the problem is in
			 # https://metacpan.org/pod/HTTP::Headers::ActionPack,
			 # which is an extensible framework for working with
			 # headers, and so, it can be used to implement syntax
			 # for headers that are seen.
			 my $tmp_h = HTTP::Headers->new($expected_header_field => [split(/,\s*/,$response->header($expected_header_field))]);
			 # TODO: Resolve relative URIs in the response
			 cmp_deeply([$tmp_h->header($expected_header_field)],
							supersetof($expected_response->header($expected_header_field)),
							"$expected_header_field is a superset as expected");
		  } else {
			 fail("Presence of $expected_header_field in response") # Easiest way to maintain correct number of tests and also not get a warning for a calling split on undef is to fail the test like this
		  }
		}
	 };
  } else {
	 note "No expected headers set";
  }
}

sub _create_authorization_field {
  my ($object, $request_url) = @_;
  if ($object->isa('URI')) {
	 my $ua = LWP::UserAgent->new;
	 # Construct the URI to retrieve bearer token from
	 my $bearer_url = $object;
	 if (defined($request_url)) {
	 # If the request URL (i.e. to the resource under test is given, then set audience
		my $aud_url = URI->new;
		$aud_url->scheme($request_url->scheme);
		$aud_url->authority($request_url->authority);
		$bearer_url->query("aud=$aud_url");
	 }
	 my $response = $ua->get($bearer_url);
	 BAIL_OUT 'Could not retrieve bearer token from ' . $bearer_url->as_string unless $response->is_success;
	 $object = $response->content;
  }
  return "Bearer $object";
}
 
sub _check_origin {
  my $request = shift;
  if ($request->header('Origin')) {
	 my $origin = URI->new($request->header('Origin'));
	 if ($origin->path) {
		note('Origin had path "' . $origin->path . '". Probably unproblematic. Using only scheme and authority');
		my $new_origin = URI->new;
		$new_origin->scheme($origin->scheme);
		$new_origin->authority($origin->authority);
		$request->header('Origin' => $new_origin->as_string);
	 }
  }
  return $request;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Web::Solid::Test::HTTPLists - Solid Tests using HTTP objects

=head1 SYNOPSIS

  use Test::FITesque::RDF;
  my $suite = Test::FITesque::RDF->new(source => $file, base_uri => $ENV{SOLID_REMOTE_BASE})->suite;
  $suite->run_tests;
  done_testing;

A script C<tests/httplists.t> can be used to launch some of these tests.

=head1 DESCRIPTION

=head2 Introduction

The basic idea with these tests is to simplify reuse and formulation
of fixture tables using the Resource Description Framework (RDF), in
this case using HTTP vocabularies to formulate lists of requests and
responses. It is in a very early stage, but there are running tests in
this module. See L<Web::Solid::Test::Basic> for more on the
philosophy.

This system is built on L<Test::FITesque::RDF>, which adds RDF fixture
tables to L<Test::FITesque>.

=head1 IMPLEMENTED TESTS

Apart from some author tests in this module, examples of actual tests
can be found in the L<Solid Test Suite|https://github.com/solid/test-suite>.


=head2 Test scripts

In general, tests are formulated in RDF fixture tables, which
parameterizes the test cases. This parameterization is then given to
the test scripts. It is intended therefore that only a small number of
fairly general test scripts will be needed to provide an extensive
test suite.

These are the test scripts implemented in this module:


=head2 C<< http_req_res_list >>

Runs a list of HTTP request response pairs, checking response against the response.

=head3 Parameters

=over

=item * C<test:steps>

A list of request-response pairs, declared using:

=over

=item * C<test:request>

An RDF list of requests that will be executed towards the server in C<SOLID_REMOTE_BASE>.

=item * C<test:response_assertion>

An RDF list of responses that will be used as corresponding expected responses in the tests.

=back

=item * C<http://example.org/httplist/param#bearer>

A bearer token that if present will be used to authenticate the
requests given by the above list. The object of this predicate can
either be a literal bearer token, or a URL, in which case, it will be
dereferenced and the content will be used as the bearer token.

=back

=head3 Environment

None

=head3 Implements

=over

=item 1. That responses are L<HTTP::Response> objects.

=item 2. That the response code matches the expected one if given.

=item 3. That all headers given in the asserted response matches a
header in the actual response.

=back


=head2 C<< http_req_res_list_regex_reuser >>

Runs a list of two HTTP request response pairs, using a regular
expression from the first request to set the request URL of the
second.

=head3 Parameters

Uses C<test:steps> like above.

Additionally, the first request may have a regular expression that can
be used to parse data for the next request. To examine the Link
header, a response message can be formulated like (note, it practice
it would be more complex):

 :check_acl_location_res a http:ResponseMessage ;
    httph:link '<(.*?)>;\\s+rel="acl"'^^dqm:regex ;
    http:status 200 .

The resulting match is placed in an array that will be used to set the
Request URI of the next request.


=head3 Environment

None

=head3 Implements

=over

=item 1. That the regular expression in the first request matches.

=item 2. That responses are L<HTTP::Response> objects.

=item 3. That the response code matches the expected one if given.

=item 4. That headers that are not matched as regular expression but
given in the asserted response matches a header in the actual
response.

=back


=head3 Assumptions

See the source for details.




=head1 NOTE

The parameters above are in the RDF formulated as actual full URIs,
but where the local part is used here and resolved by the
L<Test::FITesque::RDF> framework, see its documentation for details.

To run tests against a server that uses HTTPS but does not have a
valid certificate, such as a self-signed one, install
L<LWP::Protocol::https> and ignore errors by setting the environment
variable <PERL_LWP_SSL_VERIFY_HOSTNAME=0>


=head1 TODO

The namespaces used in the current fixture tables are examples, and
will be changed before an 1.0 release of the system.


=head1 BUGS

Please report any bugs to
L<https://github.com/kjetilk/p5-web-solid-test-basic/issues>.

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is Copyright (c) 2019 by Inrupt Inc.

This is free software, licensed under:

  The MIT (X11) License


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

