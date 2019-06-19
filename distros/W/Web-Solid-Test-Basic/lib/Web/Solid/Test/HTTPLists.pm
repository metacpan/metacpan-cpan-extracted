package Web::Solid::Test::HTTPLists;

use 5.010001;
use strict;
use warnings;
use parent 'Test::FITesque::Fixture';
use Test::More;
use LWP::UserAgent;
use Test::Deep;
use Test::RDF;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.001';

sub http_req_res_list_unauthenticated : Test : Plan(1)  {
  my ($self, $args) = @_;
  my @requests = @{$args->{'http-requests'}}; # Unpack for readability
  subtest 'Request-responses' => sub {
	 plan tests => scalar @requests;
	 for (my $i=0; $i <= $#requests; $i++) {
		subtest "Request-response #" . ($i+1) => sub {
		  my $ua = LWP::UserAgent->new;
		  my $response = $ua->request( $requests[$i] );
		  my $expected_response = ${$args->{'http-responses'}}[$i];
		  isa_ok($response, 'HTTP::Response');
		  if ($expected_response->code) {
			 is($response->code, $expected_response->code, "Response code is " . $expected_response->code)
				|| note 'Returned content: ' . $response->content;
		  }
		  my @expected_header_fields = $expected_response->header_field_names;
		  if (scalar @expected_header_fields) {
			 subtest 'Testing all headers' => sub {
				plan tests => scalar @expected_header_fields;
				foreach my $expected_header_field (@expected_header_fields) { # TODO: Date-fields may fail
				  is($response->header($expected_header_field), $expected_response->header($expected_header_field), "$expected_header_field is the same for both");
				}
			 };
		  } else {
			 note "No expected headers set";
		  }
		};
	 }
  };
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




=head2 C<< http_req_res_list_unauthenticated >>

Runs a list of HTTP request response pairs, checking response against the response.

=head3 Parameters

=over

=item * C<test:requests>

An RDF list of requests that will be executed towards the server in C<SOLID_REMOTE_BASE>.

=item * C<test:responses>

An RDF list of responses that will be used as corresponding expected responses in the tests.


=back

=head3 Environment

None

=head3 Implements

=over

=item 1. That responses are L<HTTP::Response> objects.

=item 2. That the response code matches the expected one if given.

=item 3. That all headers given in the expected response matches a header in the actual response.

=back



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

