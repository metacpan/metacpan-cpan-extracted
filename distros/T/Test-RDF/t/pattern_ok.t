use Test::Tester tests=>65;
use Test::RDF;
use RDF::Trine qw[iri variable literal statement];

check_test(
  sub {
    pattern_target(100);
  },
  {
    ok   => 0,
    name => 'Data is not an RDF::Trine::Model or RDF::Trine::Store.',
  },
  'pattern_target - invalid target'
);

check_test(
  sub {
    pattern_ok();
  },
  {
    ok   => 0,
    name => 'Pattern match',
    diag => 'No target defined for pattern match. Call pattern_target test first.',
  },
  'pattern_ok - uninitialised target'
);

check_test(
  sub {
    my $store = RDF::Trine::Store->temporary_store;
    pattern_target($store);
  },
  {
    ok   => 1,
    name => 'Data is an RDF::Trine::Store.',
  },
  'pattern_target - target store'
);

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
    pattern_ok(
      statement(variable('who'), $foaf->name, literal('Kjetil Kjernsmo')),
      statement(variable('who'), $foaf->page, iri('http://search.cpan.org/~kjetilk/')),
      );
  },
  {
    ok   => 1,
  },
  'pattern_ok - statement list'
);

check_test(
  sub {
    pattern_ok(
      RDF::Trine::Pattern->new(
        statement(variable('who'), $foaf->name, literal('Kjetil Kjernsmo')),
        statement(variable('who'), $foaf->page, iri('http://search.cpan.org/~kjetilk/')),
        ),
      );
  },
  {
    ok   => 1,
  },
  'pattern_ok - pattern'
);

check_test(
  sub {
    pattern_ok(
      statement(variable('who'), $foaf->name, literal('Kjetil Kjernsmo')),
      statement(variable('who'), $foaf->page, iri('http://search.cpan.org/~kjetilk/')),
      "FOO",
      );
  },
  {
    ok   => 1,
    name => 'FOO',
  },
  'pattern_ok - statement list plus message'
);

check_test(
  sub {
    pattern_ok(
      RDF::Trine::Pattern->new(
        statement(variable('who'), $foaf->name, literal('Kjetil Kjernsmo')),
        statement(variable('who'), $foaf->page, iri('http://search.cpan.org/~kjetilk/')),
        ),
      "FOO",
      );
  },
  {
    ok   => 1,
    name => 'FOO',
  },
  'pattern_ok - pattern plus message'
);

check_test(
  sub {
    pattern_ok(
      statement(variable('who'), $foaf->name, literal('Toby Inkster')),
      statement(variable('who'), $foaf->page, iri('http://search.cpan.org/~kjetilk/')),
      );
  },
  {
    ok   => 0,
	 diag => 'Pattern as a whole did not match'
  },
  'pattern_ok - statement list should fail'
);

check_test(
  sub {
    pattern_ok(
      RDF::Trine::Pattern->new(
        statement(variable('who'), $foaf->name, literal('Toby Inkster')),
        statement(variable('who'), $foaf->page, iri('http://search.cpan.org/~kjetilk/')),
        ),
      );
  },
  {
    ok   => 0,
	 diag => 'Pattern as a whole did not match'
  },
  'pattern_ok - pattern should fail'
);

check_test(
  sub {
    pattern_ok(
      RDF::Trine::Pattern->new(
        statement(variable('who'), $foaf->name, literal('DAHUT')),
        statement(variable('who'), $foaf->page, iri('http://search.cpan.org/~kjetilk/')),
        ),
      );
  },
  {
    ok   => 0,
	 diag => "Triples that had no results:\n(triple ?who <http://xmlns.com/foaf/0.1/name> \"DAHUT\")"
  },
  'pattern_ok - pattern should fail'
);

