use 5.010001;
use strict;
use warnings;

package Test::FITesque::RDF;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.003';

use Moo;
use Attean::RDF;
use Path::Tiny;
use URI::NamespaceMap;
use Test::FITesque::Test;
use Types::Standard qw(InstanceOf);
use Types::Namespace qw(Iri Namespace);
use Types::Path::Tiny qw(Path);
use Data::Dumper;

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
  my $ns = URI::NamespaceMap->new(['deps', 'dc']);
  $ns->add_mapping(test => 'http://example.org/test-fixtures#'); # TODO: Get a proper URI
  my $parser = Attean->get_parser(filename => $self->source)->new( base => $self->base_uri );
  my $model = Attean->temporary_model;

  my $graph_id = iri('http://example.org/graph'); # TODO: Use a proper URI for graph
  $model->add_iter($parser->parse_iter_from_io( $self->source->openr_utf8 )->as_quads($graph_id));

  my $tests_uri_iter = $model->objects(undef, iri($ns->test->fixtures->as_string)); # TODO: Implement coercions in Attean
  # TODO: Support rdf:List here
  my @data;

  while (my $test_uri = $tests_uri_iter->next) {
	 my @instance;
	 my $params_base = URI::Namespace->new($model->objects($test_uri, iri($ns->test->param_base->as_string))->next);
	 $ns->guess_and_add($params_base);
	 my $test_bgp = bgp(triplepattern($test_uri, iri($ns->test->handler->as_string), variable('handler')),
							  triplepattern($test_uri, iri($ns->dc->identifier->as_string), variable('method')),
							  triplepattern($test_uri, iri($ns->test->params->as_string), variable('paramid')));

	 my $algebra = Attean::Algebra::Query->new(children => [$test_bgp]); # TODO: generalize the next 4 lines in Attean
	 my $planner = Attean::IDPQueryPlanner->new();
	 my $plan = $planner->plan_for_algebra($algebra, $model, $graph_id);
	 my $test_iter = $plan->evaluate($model); # Each row will correspond to one test

	 while (my $test = $test_iter->next) {
		push(@instance, [$test->value('handler')->value]);
		my $method = $test->value('method')->value;
		my $params_iter = $model->get_quads($test->value('paramid')); # Get the parameters for each test
		my $params;
		while (my $param = $params_iter->next) {
		  my $key = $params_base->local_part($param->predicate);
		  my $value = $param->object->value;
		  $params->{$key} = $value;
		}
		push(@instance, [$method, $params])
	 }
	 push(@data, \@instance);
  }
  return \@data;
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

=head2 RDF EXAMPLE

The below example starts with prefix declarations. Since this is a
pre-release, some of the prefixes are preliminary examples. Then, the
tests in the fixture table are listed explicitly. Only tests mentioned
using the C<test:fixtures> predicate will be used.

Then, two test fixtures are declared. The C<test:handler> predicate is
used to identify the class containing implementations, while
C<dc:identifier> is used to name the function within that class.

The C<test:params> predicate is used to link the parameters that will
be sent as a hashref into the function. The key of the hashref will be
the local part of the predicate used in the description (i.e. the part
after the colon in e.g. C<my:all>). It is up to the test writer to
mint the URIs of the parameters, and the C<param_base> is used to set
indicate the namespace, so that the local part can be resolved. The
resolution itself happens in L<URI::NamespaceMap>.


  @prefix test: <http://example.org/test-fixtures#> .
  @prefix deps: <http://ontologi.es/doap-deps#>.
  @prefix dc:   <http://purl.org/dc/terms/> .
  @prefix my:   <http://example.org/my-parameters#> .


  <#test-list> a test:FixtureTable ;
    test:fixtures <#test1>, <#test2> .

  <#test1> a test:Test ;
    test:handler "Internal::Fixture::Simple"^^deps:CpanId ;
    dc:identifier "string_found" ;
    test:param_base <http://example.org/my-parameters#> ;
    test:params [ my:all "counter-clockwise dahut" ] .

  <#test2> a test:Test ;
    test:handler "Internal::Fixture::Multi"^^deps:CpanId ;
    dc:identifier "multiplication" ;
    test:param_base <http://example.org/my-parameters#> ;
    test:params [
        my:factor1 6 ;
        my:factor2 7 ;
        my:product 42
    ] .




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

