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
our $VERSION   = '0.002';

my $bearer_predicate = 'http://example.org/httplist/param#bearer'; # TODO: Define proper URI

sub http_req_res_list_location : Test : Plan(1)  {
  my ($self, $args) = @_;
  my @requests = @{$args->{'-special'}->{'http-requests'}}; # Unpack for readability
  my @expected_responses = @{$args->{'-special'}->{'http-responses'}};
  my @regex_fields = @{$args->{'-special'}->{'regex-fields'}};
  my @matches;
  subtest $args->{'-special'}->{description} => sub {
	 plan tests => scalar @requests;
	 my $ua = LWP::UserAgent->new;
	 subtest "First request" => sub {
		my $request_no = 0;
		my $request = $requests[$request_no];
		if ($args->{$bearer_predicate}) {
		  $request->header( 'Authorization' => _create_authorization_field($args->{$bearer_predicate}, $request->uri));
		}

		my $response = $ua->request( $request );
		my $expected_response = $expected_responses[$request_no];
		my $regex_fields = $regex_fields[$request_no];
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
		
		#		subtest "Request-response #" . ($i+1) =>
		_subtest_compare_req_res($request, $response, $expected_response);
		# }
	 };

	 subtest "Second request" => sub {
		my $request_no = 1;
		my $request = $requests[$request_no];
		unless (defined($request->uri)) {
		  # ASSUME: RequestURI was not given, it has to be derived from the previous request through a match
		  # ASSUME: The first match of the previous request is the relative URI to be used for the this request
		  # ASSUME: The base URI is the RequestURI for the previous request
		  my $uri = URI->new_abs($matches[$request_no-1]->[0], $requests[$request_no-1]->uri);
		  $request->uri($uri);
		}
		if ($args->{$bearer_predicate}) {
		  $request->header( 'Authorization' => _create_authorization_field($args->{$bearer_predicate}, $request->uri));
		}
		my $response = $ua->request($request);
		my $expected_response = $expected_responses[$request_no];
		_subtest_compare_req_res($request, $response, $expected_response);
	 };
  };
}

sub http_req_res_list : Test : Plan(1)  {
  my ($self, $args) = @_;
  my @requests = @{$args->{'-special'}->{'http-requests'}}; # Unpack for readability
  my $ua = LWP::UserAgent->new;
  subtest $args->{'-special'}->{description} => sub {
	 plan tests => scalar @requests;
	 for (my $i=0; $i <= $#requests; $i++) {
		my $request = $requests[$i];
		if ($args->{$bearer_predicate}) {
		  $request->header( 'Authorization' => _create_authorization_field($args->{$bearer_predicate}, $request->uri));
		}
		my $response = $ua->request( $request );
		my $expected_response = ${$args->{'-special'}->{'http-responses'}}[$i];
		subtest "Request-response #" . ($i+1) =>
		  \&_subtest_compare_req_res, $request, $response, $expected_response; #Callback syntax isn't pretty, admittedly
	 }
  };
}


sub _subtest_compare_req_res {
  my ($request, $response, $expected_response) = @_;
  isa_ok($response, 'HTTP::Response');
  if ($expected_response->code) {
	 is($response->code, $expected_response->code, "Response code is " . $expected_response->code)
		|| note 'Returned content: ' . $response->as_string;
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

=head2 Test scripts

This package provides C<tests/httplists.t> which runs tests over the
fixture table in C<tests/data/http-list.ttl>. The test script requires the
environment variable C<SOLID_REMOTE_BASE> to be set to the base URL
that any relative URLs in the fixture tables will be resolved
against. Thus, the fixture tables themselves are independent of the
host that will run them.

To run the test script in the clone of this package, invoke it like this:

  SOLID_REMOTE_BASE="https://kjetiltest4.dev.inrupt.net/" prove -l tests/basic.t




=head2 C<< http_req_res_list >>

Runs a list of HTTP request response pairs, checking response against the response.

=head3 Parameters

=over

=item * C<test:requests>

An RDF list of requests that will be executed towards the server in C<SOLID_REMOTE_BASE>.

=item * C<test:responses>

An RDF list of responses that will be used as corresponding expected responses in the tests.

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

=item 3. That all headers given in the expected response matches a header in the actual response.

=back


=head2 C<< http_req_res_list_location >>

Runs a list of two HTTP request response pairs, using a regular
expression from the first request to set the request URL of the
second. To be detailed.


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

=head1 SEE ALSO

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

