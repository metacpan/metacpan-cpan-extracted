use 5.014;
use strict;
use warnings;

package Test::FITesque::RDF;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.016';

use Moo;
use Attean::RDF;
use Path::Tiny;
use URI::NamespaceMap;
use Test::FITesque::Test;
use Types::Standard qw(InstanceOf);
use Types::Namespace qw(Iri Namespace);
use Types::Path::Tiny qw(Path);
use Carp qw(carp croak);
use Data::Dumper;
use HTTP::Request;
use HTTP::Response;
use LWP::UserAgent;
use Try::Tiny;
use Attean::SimpleQueryEvaluator;

has source => (
					is      => 'ro',
					isa     => Path, # TODO: Generalize to URLs
					required => 1,
					coerce  => 1,
				  );


has base_uri => (
					  is => 'ro',
					  isa => Iri,
					  coerce => 1,
					  default => sub { 'http://localhost/' }
					  );

has suite => (
				  is => 'lazy',
				  isa => InstanceOf['Test::FITesque::Suite'],
				 );

sub _build_suite {
  my $self = shift;
  my $suite = Test::FITesque::Suite->new();
  foreach my $test (@{$self->transform_rdf}) {
	 $suite->add(Test::FITesque::Test->new({ data => $test}));
  }
  return $suite;
}



sub transform_rdf {
  my $self = shift;
  my $ns = URI::NamespaceMap->new(['deps', 'dc', 'rdf']);
  $ns->add_mapping(test => 'http://ontologi.es/doap-tests#');
  $ns->add_mapping(http => 'http://www.w3.org/2007/ont/http#');
  $ns->add_mapping(httph => 'http://www.w3.org/2007/ont/httph#');
  $ns->add_mapping(dqm => 'http://purl.org/dqm-vocabulary/v1/dqm#');
  $ns->add_mapping(nfo => 'http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#');
  my $parser = Attean->get_parser(filename => $self->source)->new( base => $self->base_uri );
  my $model = Attean->temporary_model;

  my $graph_id = iri('http://example.org/graph'); # TODO: Use a proper URI for graph

  my $file_iter;
  try {
	 $file_iter = $parser->parse_iter_from_io( $self->source->openr_utf8 );
  } catch {
	 croak 'Failed to parse ' . $self->source . " due to $_";
  };
  $model->add_iter($file_iter->as_quads($graph_id));

  my $tests_uri_iter = $model->objects(undef, iri($ns->test->fixtures->as_string))->materialize; # TODO: Implement coercions in Attean
  if (scalar $tests_uri_iter->elements == 0) {
	 croak "No tests found in " . $self->source;
  }

  if ($model->holds($tests_uri_iter->peek, iri($ns->rdf->first->as_string), undef, $graph_id)) {
	 # Then, the object is a list. This supports either unordered
	 # objects or lists, not both. This could be changed by iterating
	 # in the below loop, but I don't see much point to it.
	 $tests_uri_iter = $model->get_list( $graph_id, $tests_uri_iter->peek);
  }
  my @data;

  while (my $test_uri = $tests_uri_iter->next) {
	 my @instance;
	 my $params_base_term = $model->objects($test_uri, iri($ns->test->param_base->as_string))->next;
	 my $params_base;
	 if ($params_base_term) {
		$params_base = URI::Namespace->new($params_base_term);
		$ns->guess_and_add($params_base);
	 }
	 my $test_bgp = bgp(triplepattern($test_uri, iri($ns->test->test_script->as_string), variable('script_class')),
							  triplepattern(variable('script_class'), iri($ns->deps->iri('test-requirement')->as_string), variable('handler')), # Because Perl doesn't support dashes in method names
							  triplepattern(variable('script_class'), iri($ns->nfo->definesFunction->as_string), variable('method')),
							  triplepattern($test_uri, iri($ns->test->purpose->as_string), variable('description')),
							  triplepattern($test_uri, iri($ns->test->params->as_string), variable('paramid')));

	 my $e = Attean::SimpleQueryEvaluator->new( model => $model, default_graph => $graph_id, ground_blanks => 1 );
	 my $test_iter = $e->evaluate( $test_bgp, $graph_id); # Each row will correspond to one test

	 while (my $test = $test_iter->next) {
		push(@instance, [$test->value('handler')->value]);
		my $method = $test->value('method')->value;
		my $params_iter = $model->get_quads($test->value('paramid')); # Get the parameters for each test
		my $params;
		$params->{'-special'} = {description => $test->value('description')->value}; # Description should always be present
		while (my $param = $params_iter->next) {
		  # First, see if there are HTTP request-responses that can be constructed
		  my $pairs_head = $model->objects($param->subject, iri($ns->test->steps->as_string))->next;
		  my @pairs;

		  if ($pairs_head) {
			 # There exists a list of HTTP requests and responses
			 my $steps_iter = $model->get_list($graph_id, $pairs_head);
			 while (my $pairs_subject = $steps_iter->next) {
				my $pairs_bgp = bgp(triplepattern($pairs_subject, iri($ns->test->request->as_string), variable('request')),
										  triplepattern($pairs_subject, iri($ns->test->response_assertion->as_string), variable('response_assertion')));
				my $pair_iter = $e->evaluate( $pairs_bgp, $graph_id); # Each row will correspond to one request-response pair
				my $result;
				# Within each pair, there will be both requests and responses
				my $req = HTTP::Request->new;
				my $res = HTTP::Response->new;
				my $regex_headers = {};
				while (my $pair = $pair_iter->next) {
				  # First, do requests
				  my $req_entry_iter = $model->get_quads($pair->value('request'));
				  while (my $req_data = $req_entry_iter->next) {
					 my $local_header = $ns->httph->local_part($req_data->predicate);
					 if ($req_data->predicate->equals($ns->http->method)) {
						$req->method($req_data->object->value);
					 } elsif ($req_data->predicate->equals($ns->http->requestURI)) {
						$req->uri($req_data->object->as_string);
					 } elsif ($req_data->predicate->equals($ns->http->content)) {
						if ($req_data->object->is_literal) {
						  $req->content($req_data->object->value); # TODO: might need encoding
						} elsif ($req_data->object->is_iri) {
						  # If the http:content predicate points to a IRI, the framework will retrieve content from there
						  my $ua = LWP::UserAgent->new;
						  my $content_response = $ua->get(URI->new($req_data->object->as_string));
						  if ($content_response->is_success) {
							 $req->content($content_response->decoded_content); # TODO: might need encoding
						  } else {
							 croak "Could not retrieve content from " . $req_data->object->as_string . " . Got " . $content_response->status_line;
						  }
						} else {
						  croak 'Unsupported object ' . $req_data->object->as_string . " in " . $self->source;
						}
					 } elsif (defined($local_header)) {
						$req->push_header(_find_header($local_header) => $req_data->object->value);
					 }
				  }

				  # Now, do asserted responses
				  my $res_entry_iter = $model->get_quads($pair->value('response_assertion'));
				  while (my $res_data = $res_entry_iter->next) {
					 my $local_header = $ns->httph->local_part($res_data->predicate);
					 if ($res_data->predicate->equals($ns->http->status)) {
						$res->code($res_data->object->value);
					 } elsif (defined($local_header)) {
						my $cleaned_header = _find_header($local_header);
						$res->push_header($cleaned_header => $res_data->object->value);
						if ($res_data->object->is_literal && $res_data->object->datatype->as_string eq $ns->dqm->regex->as_string) { # TODO: don't use string comparison when Attean does the coercion
						  $regex_headers->{$cleaned_header} = 1;
						}
					 }
				  }
				}
				$result = { 'request' => $req,
								'response' => $res,
								'regex-fields' => $regex_headers };
				
				push(@pairs, $result);
			 }
			 $params->{'-special'}->{'http-pairs'} = \@pairs;
		  }
		  if ($param->object->is_literal || $param->object->is_iri) {
			 my $key = $param->predicate->as_string;
			 if (defined($params_base) && $params_base->local_part($param->predicate)) {
				$key = $params_base->local_part($param->predicate)
			 }
			 my $value = $param->object->value;
			 if ($param->object->is_iri) {
				$value = URI->new($param->object->as_string)
			 }
			 $params->{$key} = $value;
		  }
		}
		push(@instance, [$method, $params])
	 }
	 carp 'Test was listed as ' . $test_uri->as_string . ' but not fully described' unless scalar @instance;
	 push(@data, \@instance);
  }
  return \@data;
}

sub _find_header {
  my $local_header = shift;
  $local_header =~ s/_/-/g; # Some heuristics for creating HTTP headers
  $local_header =~ s/\b(\w)/\u$1/g;
  return $local_header;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Test::FITesque::RDF - Formulate Test::FITesque fixture tables in RDF

=head1 SYNOPSIS

  my $suite = Test::FITesque::RDF->new(source => $file)->suite;
  $suite->run_tests;

See C<t/integration-basic.t> for a full test script example.


=head1 DESCRIPTION

This module enables the use of Resource Description Framework to
describe fixture tables. It will take the filename of an RDF file and
return a L<Test::FITesque::Suite> object that can be used to run
tests.

The RDF serves to identify the implementation of certain fixtures, and
can also supply parameters that can be used by the tests, e.g. input
parameters or expectations. See L<Test::FITesque> for more on how the
fixtures are implemented.

=head2 ATTRIBUTES AND METHODS

This module implements the following attributes and methods:

=over

=item C<< source >>

Required attribute to the constructor. Takes a L<Path::Tiny> object
pointing to the RDF file containing the fixture tables. The value will
be converted into an appropriate object, so a string can also be
supplied.

=item C<< suite >>

Will return a L<Test::FITesque::Suite> object, based on the RDF data supplied to the constructor.

=item C<< transform_rdf >>

Will return an arrayref containing tests in the structure used by
L<Test::FITesque::Test>. Most users will rather call the C<suite>
method than to call this method directly.

=item C<< base_uri >>

A L<IRI> to use in parsing the RDF fixture tables to resolve any relative URIs.

=back

=head2 REQUIRED RDF

The following must exist in the test description (see below for an example and prefix expansions):

=over

=item C<< test:fixtures >>

The object(s) of this predicate lists the test fixtures that will run
for this test suite. May take an RDF List. Links to the test
descriptions, which follow below.


=item C<< test:test_script >>

The object of this predicate points to information on how the actual
test will be run. That is formulated in a separate resource which
requires two predicates, C<< deps:test-requirement >> predicate, whose
object contains the class name of the implementation of the tests; and
C<< nfo:definesFunction >> whose object is a string which matches the
actual function name within that class.

=item C<< test:purpose >>

The object of this predicate provides a literal description of the test.

=item C<< test:params >>

The object of this predicate links to the parameters, which may have
many different shapes. See below for examples.

=back

=head2 PARAMETERIZATION

This module seeks to parameterize the tests, and does so using mostly
the C<test:params> predicate above. This is passed on as a hashref to
the test scripts.

There are two main ways currently implemented, one creates key-value
pairs, and uses predicates and objects for that respectively, in
vocabularies chosen by the test writer. The other main way is create
lists of HTTP requests and responses.

If the object of a test parameter is a literal, it will be passed as a
plain string, if it is a L<Attean::IRI>, it will be passed as a L<URI>
object.

Additionally, a special parameter C<-special> is passed on for
internal framework use. The leading dash is not allowed as the start
character of a local name, and therefore chosen to avoid conflicts
with other parameters.

The literal given in C<test:purpose> above is passed on as with the
C<description> key in this hashref.

=head2 RDF EXAMPLE

The below example starts with prefix declarations. Then, the
tests in the fixture table are listed explicitly. Only tests mentioned
using the C<test:fixtures> predicate will be used. Tests may be an RDF
List, in which case, the tests will run in the specified sequence, if
not, no sequence may be assumed.

Then, two test fixtures are declared. The actual implementation is
referenced through C<test:test_script> for both functions.

The C<test:params> predicate is used to link the parameters that will
be sent as a hashref into the function. The <test:purpose> predicate
is required to exist outside of the parameters, but will be included
as a parameter as well, named C<description> in the C<-special>
hashref.

There are two mechanisms for passing parameters to the test scripts,
one is simply to pass arbitrary key-value pairs, the other is to pass
lists of HTTP request-response objects. Both mechanisms may be used.

=head3 Key-value parameters

The key of the hashref passed as arguments will be the local part of
the predicate used in the description (i.e. the part after the colon
in e.g. C<my:all>). It is up to the test writer to mint the URIs of
the parameters.

The test writer may optionally use a C<param_base> to indicate the
namespace, in which case the the local part is resolved by the
framework, using L<URI::NamespaceMap>. If C<param_base> is not given,
the full URI will be passed to the test script.


 @prefix test: <http://ontologi.es/doap-tests#> .
 @prefix deps: <http://ontologi.es/doap-deps#>.
 @prefix dc:   <http://purl.org/dc/terms/> .
 @prefix my:   <http://example.org/my-parameters#> .
 @prefix nfo:  <http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#> .
 @prefix :     <http://example.org/test#> .


 :test_list a test:FixtureTable ;
    test:fixtures :test1, :test2 .

 :test1 a test:AutomatedTest ;
    test:param_base <http://example.org/my-parameters#> ;
    test:purpose "Echo a string"@en ;
    test:test_script <http://example.org/simple#string_found> ;
    test:params [ my:all "counter-clockwise dahut" ] .

 :test2 a test:AutomatedTest ;
    test:param_base <http://example.org/my-parameters#> ;
    test:purpose "Multiply two numbers"@en ;
    test:test_script <http://example.org/multi#multiplication> ;
    test:params [
        my:factor1 6 ;
        my:factor2 7 ;
        my:product 42
    ] .

 <http://example.org/simple#string_found> a nfo:SoftwareItem ;
    nfo:definesFunction "string_found" ;
    deps:test-requirement "Internal::Fixture::Simple"^^deps:CpanId .

 <http://example.org/multi#multiplication> a nfo:SoftwareItem ;
    nfo:definesFunction "multiplication" ;
    deps:test-requirement "Internal::Fixture::Multi"^^deps:CpanId .



=head3 HTTP request-response lists

To allow testing HTTP-based interfaces, this module also allows the
construction of an ordered list of HTTP requests and response pairs.
With those, the framework will construct L<HTTP::Request> and
L<HTTP::Response> objects. In tests scripts, the request
objects will typically be passed to the L<LWP::UserAgent> as input,
and then the response from the remote server will be compared with the
asserted L<HTTP::Response>s made by the test fixture.

We will go through an example in chunks:

 @prefix test: <http://ontologi.es/doap-tests#> .
 @prefix deps: <http://ontologi.es/doap-deps#>.
 @prefix httph:<http://www.w3.org/2007/ont/httph#> .
 @prefix http: <http://www.w3.org/2007/ont/http#> .
 @prefix nfo:  <http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#> .
 @prefix :     <http://example.org/test#> .

 :test_list a test:FixtureTable ;
    test:fixtures :public_writeread_unauthn_alt .

 :public_writeread_unauthn_alt a test:AutomatedTest ;
    test:purpose "To test if we can write first using HTTP PUT then read with GET"@en ;
    test:test_script <http://example.org/httplist#http_req_res_list_unauthenticated> ;
    test:params [
        test:steps (
            [
                test:request :public_writeread_unauthn_alt_put_req ;
                test:response_assertion :public_writeread_unauthn_alt_put_res
            ]
            [
                test:request :public_writeread_unauthn_alt_get_req ;
                test:response_assertion :public_writeread_unauthn_alt_get_res
            ]
        )
    ] .

 <http://example.org/httplist#http_req_res_list_unauthenticated> a nfo:SoftwareItem ;
    deps:test-requirement "Example::Fixture::HTTPList"^^deps:CpanId ;
    nfo:definesFunction "http_req_res_list_unauthenticated" .



In the above, after the prefixes, a single test is declared using the
C<test:fixtures> predicate, linking to a description of the test. The
test is then described as an <test:AutomatedTest>, and it's purpose is
declared. It then links to its concrete implementation, which is given
in the last three triples in the above.

Then, the parameterization is started. In this example, there are two
HTTP request-response pairs, which are given as a list object to the
C<test:steps> predicate.

To link the request, the C<test:request> predicate is used, to link
the asserted response, the C<test:response_assertion> predicate is
used.

Next, we look into the actual request and response messages linked from the above:

 :public_writeread_unauthn_alt_put_req a http:RequestMessage ;
    http:method "PUT" ;
    httph:content_type "text/turtle" ;
    http:content "</public/foobar.ttl#dahut> a <http://example.org/Cryptid> ." ;
    http:requestURI </public/foobar.ttl> .

 :public_writeread_unauthn_alt_put_res a http:ResponseMessage ;
    http:status 201 .

 :public_writeread_unauthn_alt_get_req a http:RequestMessage ;
    http:method "GET" ;
    http:requestURI </public/foobar.ttl> .

 :public_writeread_unauthn_alt_get_res a http:ResponseMessage ;
    httph:accept_post  "text/turtle", "application/ld+json" ;
    httph:content_type "text/turtle" .

These should be self-explanatory, but note that headers are given with
lower-case names and underscores. They will be transformed to headers
by replacing underscores with dashes and upcase the first letters.

This module will transform the above to data structures that are
suitable to be passed to L<Test::Fitesque>, and the above will appear as

 {
	'-special' => {
						'http-pairs' => [
                                   {
										      'request'  => ... ,
										      'response' => ... ,
                                   },
                                   { ... }
                                  ]
										 },
						'description' => 'To test if we can write first using HTTP PUT then read with GET'
					  },
 }


Note that there are more examples in this module's test suite in the
C<t/data/> directory.

You may maintain client state in a test script (i.e. for one
C<test:AutomatedTest>, as it is simply one script, so the result of
one request may be used to influence the next. Server state can be
relied on between different tests by using an C<rdf:List> of test
fixtures if it writes something into the server, there is nothing in
the framework that changes that.

To use data from one response to influence subsequent requests, the
framework supports datatyping literals with the C<dqm:regex> datatype,
for example:

 :check_acl_location_res a http:ResponseMessage ;
    httph:link '<(.*?)>;\\s+rel="acl"'^^dqm:regex ;
    http:status 200 .

This makes it possible to use a Perl regular expression, which can be
executed in a test script if desired. If present, it will supply
another hashref to the C<http-pairs> key with the key C<regex-fields>
containing hashrefs with the header field that had a correspondiing
object datatyped regex as key and simply C<1> as value.

=head1 TODO

Separate the implementation-specific details (such as C<deps:test-requirement>)
from the actual fixture tables.

=head1 BUGS

Please report any bugs to
L<https://github.com/kjetilk/p5-test-fitesque-rdf/issues>.

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

