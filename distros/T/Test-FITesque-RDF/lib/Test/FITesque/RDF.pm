use 5.014;
use strict;
use warnings;

package Test::FITesque::RDF;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.010';

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
  if (scalar $tests_uri_iter->elements == 0) { # TODO: Better to check if there are fixture table entries that has no test
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

	 my $algebra = Attean::Algebra::Query->new(children => [$test_bgp]); # TODO: generalize the next 4 lines in Attean
	 my $planner = Attean::IDPQueryPlanner->new();
	 my $plan = $planner->plan_for_algebra($algebra, $model, $graph_id);
	 my $test_iter = $plan->evaluate($model); # Each row will correspond to one test

	 while (my $test = $test_iter->next) {
		push(@instance, [$test->value('handler')->value]);
		my $method = $test->value('method')->value;
		my $params_iter = $model->get_quads($test->value('paramid')); # Get the parameters for each test
		my $params = {description => $test->value('description')->value}; # Description should always be present
		while (my $param = $params_iter->next) {
		  # First, see if there are HTTP request-responses that can be constructed
		  my $req_head = $model->objects($param->subject, iri($ns->test->requests->as_string))->next;
		  my $res_head = $model->objects($param->subject, iri($ns->test->responses->as_string))->next;
		  my @requests;
		  my @responses;

		  if ($req_head && $res_head) { # TODO: Test role?
			 # There is a list of HTTP requests and responses
			 my $req_iter = $model->get_list($graph_id, $req_head);
			 while (my $req_subject = $req_iter->next) {
				my $req = HTTP::Request->new;
				my $req_entry_iter = $model->get_quads($req_subject);
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
						my $ua = LWP::UserAgent->new;
						my $content_response = $ua->get($req_data->object);
						if ($content_response->is_success) {
						  $req->content($content_response->decoded_content); # TODO: might need encoding
						} else {
						  croak "Could not retrieve content from " . $req_data->object->as_string . " . Got " . $content_response->status_line;
						}
					 }
				  } elsif (defined($local_header)) {
					 $req->push_header(_find_header($local_header, $req_data));
				  }
				}
				push(@requests, $req);
			 }
			 $params->{'http-requests'} = \@requests;

			 my $res_iter = $model->get_list($graph_id, $res_head);
			 while (my $res_subject = $res_iter->next) {
				my $res = HTTP::Response->new;
				my $res_entry_iter = $model->get_quads($res_subject);
				while (my $res_data = $res_entry_iter->next) {
				  my $local_header = $ns->httph->local_part($res_data->predicate);
				  if ($res_data->predicate->equals($ns->http->status)) {
					 $res->code($res_data->object->value);
				  } elsif (defined($local_header)) {
					 $res->push_header(_find_header($local_header, $res_data));
				  }
				}
				push(@responses, $res);
			 }
			 $params->{'http-responses'} = \@responses;
		  }
		  if ($param->object->is_literal || $param->object->is_iri) {
			 my $key = $param->predicate->as_string;
			 if (defined($params_base) && $params_base->local_part($param->predicate)) {
				$key = $params_base->local_part($param->predicate)
			 }
			 my $value = $param->object->value;
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
  my ($local_header, $data) = @_;
  $local_header =~ s/_/-/g; # Some heuristics for creating HTTP headers
  $local_header =~ s/\b(\w)/\u$1/g;
  return ($local_header => $data->object->value)
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
actual function name withing that class.

=item C<< test:purpose >>

The object of this predicate provides a literal description of the test.

=item C<< test:params >>

The object of this predicate links to the parameters, which may have
many different shapes. See below for examples.

=back

=head2 RDF EXAMPLE

The below example starts with prefix declarations. Since this is a
pre-release, some of the prefixes are preliminary examples. Then, the
tests in the fixture table are listed explicitly. Only tests mentioned
using the C<test:fixtures> predicate will be used. Tests may be an RDF
List, in which case, the tests will run in the specified sequence, if
not, no sequence may be assumed.

Then, two test fixtures are declared. The actual implementation is
referenced through C<test:test_script> for both functions.

The C<test:params> predicate is used to link the parameters that will
be sent as a hashref into the function. The <test:purpose> predicate
is required to exist outside of the parameters, but will be included
as a parameter as well, named C<description>.

There are two mechanisms for passing parameters to the test scripts,
one is simply to pass arbitrary key-value pairs, the other is to pass
lists of HTTP request-response objects. Both mechanisms may be used.

=head3 Key-value parameters

The key of the hashref passed as arguments will be the local part of
the predicate used in the description (i.e. the part after the colon
in e.g. C<my:all>). It is up to the test writer to mint the URIs of
the parameters, and the C<param_base> is used to set indicate the
namespace, so that the local part can be resolved, if wanted. The
resolution itself happens in L<URI::NamespaceMap>.

 @prefix test: <http://ontologi.es/doap-tests#> .
 @prefix deps: <http://ontologi.es/doap-deps#>.
 @prefix my:   <http://example.org/my-parameters#> .
 @prefix nfo:  <http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#> .


 <#test-list> a test:FixtureTable ;
    test:fixtures <#test1>, <#test2> . 

 <#test1> a test:AutomatedTest ;
    test:param_base <http://example.org/my-parameters#> ;
    test:purpose "Echo a string"@en ;    
    test:test_script <http://example.org/simple#string_found> ;
    test:params [ my:all "counter-clockwise dahut" ] .
        
 <#test2> a test:AutomatedTest ;
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
construction of two ordered lists, one with HTTP requests, the other
with HTTP responses. With those, the framework will construct
L<HTTP::Request> and L<HTTP::Response> objects respectively. In tests
scripts, the request objects will typically be passed to the
L<LWP::UserAgent> as input, and then the response from the remote
server will be compared with the expected L<HTTP::Response>s made by
the test fixture.

This gets more complex, please see the test data file
C<t/data/http-list.ttl> file for example.

You may maintain client state in a test script (i.e. for one
C<test:AutomatedTest>, as it is simply one script, so the result of
one request may be used to influence the next. Server state can be
relied on between different tests by using an C<rdf:List> of test
fixtures if it writes something into the server, there is nothing in
the framework that changes that.

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

