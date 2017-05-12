use Test::Tester tests=>43;
use Test::RDF;
use RDF::Trine qw[iri variable literal statement];

my $model;
check_test(
  sub {
    pattern_target($model = RDF::Trine::Model->new);
  },
  {
    ok   => 1,
    name => 'Data is an RDF::Trine::Model.',
  },
  'pattern_target - target model'
);

RDF::Trine::Parser->new('turtle')->parse_into_model('http://example.org', <<'TURTLE', $model);
@prefix foaf: <http://xmlns.com/foaf/0.1/> .

[] a foaf:Person ;
  foaf:name "Kjetil Kjernsmo" ;
  foaf:page <http://search.cpan.org/~kjetilk/> .
[] a foaf:Person ;
  foaf:name "Toby Inkster" ;
  foaf:page <http://search.cpan.org/~tobyink/> .
TURTLE

my $foaf = RDF::Trine::Namespace->new('http://xmlns.com/foaf/0.1/');

check_test(
  sub {
    pattern_fail(
      statement(variable('who'), $foaf->name, literal('Kjetil Kjernsmo')),
      statement(variable('who'), $foaf->page, iri('http://search.cpan.org/~kjetilk/')),
      );
  },
  {
    ok   => 0,
  },
  'pattern_fail - statement list'
);

check_test(
  sub {
    pattern_fail(
      RDF::Trine::Pattern->new(
        statement(variable('who'), $foaf->name, literal('Kjetil Kjernsmo')),
        statement(variable('who'), $foaf->page, iri('http://search.cpan.org/~kjetilk/')),
        ),
      );
  },
  {
    ok   => 0,
  },
  'pattern_fail - pattern'
);

check_test(
  sub {
    pattern_fail(
      statement(variable('who'), $foaf->name, literal('Kjetil Kjernsmo')),
      statement(variable('who'), $foaf->page, iri('http://search.cpan.org/~kjetilk/')),
      "FOO",
      );
  },
  {
    ok   => 0,
    name => 'FOO',
  },
  'pattern_fail - statement list plus message'
);

check_test(
  sub {
    pattern_fail(
      RDF::Trine::Pattern->new(
        statement(variable('who'), $foaf->name, literal('Kjetil Kjernsmo')),
        statement(variable('who'), $foaf->page, iri('http://search.cpan.org/~kjetilk/')),
        ),
      "FOO",
      );
  },
  {
    ok   => 0,
    name => 'FOO',
  },
  'pattern_fail - pattern plus message'
);


check_test(
  sub {
    pattern_fail(
      statement(variable('who'), $foaf->name, literal('Toby Inkster')),
      statement(variable('who'), $foaf->page, iri('http://search.cpan.org/~kjetilk/')),
      );
  },
  {
    ok   => 1,
  },
  'pattern_fail - statement list should fail'
);

check_test(
  sub {
    pattern_fail(
      RDF::Trine::Pattern->new(
        statement(variable('who'), $foaf->name, literal('Toby Inkster')),
        statement(variable('who'), $foaf->page, iri('http://search.cpan.org/~kjetilk/')),
        ),
      );
  },
  {
    ok   => 1,
  },
  'pattern_fail - pattern should fail'
);

check_test(
  sub {
    pattern_fail(
      RDF::Trine::Pattern->new(
        statement(variable('who'), $foaf->name, literal('DAHUT')),
        statement(variable('who'), $foaf->page, iri('http://search.cpan.org/~kjetilk/')),
        ),
      );
  },
  {
    ok   => 1,
  },
  'pattern_fail - pattern should fail'
);

