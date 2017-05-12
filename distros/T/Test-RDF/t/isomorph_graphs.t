use Test::Tester tests => 26;

use Test::RDF;

check_test(
	   sub {
	     my $model1 = RDF::Trine::Model->temporary_model;
	     my $model2 = RDF::Trine::Model->temporary_model;
	     my $parser = RDF::Trine::Parser->new( 'turtle' );
	     $parser->parse_into_model( 'http://example.org', '</foo> <http://www.w3.org/2000/01/rdf-schema#label> "This is a Another test"@en .', $model1);
	     $parser->parse_into_model( 'http://example.org', '</foo> <http://www.w3.org/2000/01/rdf-schema#label> "This is a Another test"@en .', $model2);
	     isomorph_graphs($model1, $model2, 'Compare Turtle exact matches' );
	   },
	   {
	    ok => 1,
	    name => 'Compare Turtle exact matches',
	   }
);


check_test(
	   sub {
	     my $model1 = RDF::Trine::Model->temporary_model;
	     my $model2 = RDF::Trine::Model->temporary_model;
	     my $parser1 = RDF::Trine::Parser->new( 'turtle' );
	     my $parser2 = RDF::Trine::Parser->new( 'rdfxml' );
	     $parser1->parse_into_model( 'http://example.org', '</foo> <http://www.w3.org/2000/01/rdf-schema#label> "This is a Another test"@en .', $model1);
	     $parser2->parse_into_model( 'http://example.org', '<?xml version="1.0" encoding="utf-8"?><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"><rdf:Description rdf:about="/foo"><ns0:label xmlns:ns0="http://www.w3.org/2000/01/rdf-schema#" xml:lang="en">This is a Another test</ns0:label></rdf:Description></rdf:RDF>', $model2);
	     isomorph_graphs($model1, $model2, 'Compare RDF/XML and Turtle');
	   },
	   {
	    ok => 1,
	    name => 'Compare RDF/XML and Turtle',
	   }
);


check_test(
	   sub {
	     my $model1 = RDF::Trine::Model->temporary_model;
	     my $model2 = RDF::Trine::Model->temporary_model;
	     my $parser = RDF::Trine::Parser->new( 'turtle' );
	     $parser->parse_into_model( 'http://example.org', '</foo> <http://www.w3.org/2000/01/rdf-schema#label> "This is a Another test"@en .', $model1);
	     $parser->parse_into_model( 'http://example.org', '</foo> <http://www.w3.org/2000/01/rdf-schema#label> "This is a test"@en .', $model2);
	     isomorph_graphs($model1, $model2, 'Compare Turtle exact matches, with error' );
	   },
	   {
	    ok => 0,
	    name => 'Compare Turtle exact matches, with error',
	    diag => "Graphs differ:\nnon-blank triples don't match: \$VAR1 = '(triple <http://example.org/foo> <http://www.w3.org/2000/01/rdf-schema#label> \"This is a Another test\"\@en)';\n\$VAR2 = '(triple <http://example.org/foo> <http://www.w3.org/2000/01/rdf-schema#label> \"This is a test\"\@en)';"
	   }
);


check_test(
	   sub {
	     my $model1 = RDF::Trine::Model->temporary_model;
	     my $model2 = RDF::Trine::Model->temporary_model;
	     my $parser1 = RDF::Trine::Parser->new( 'turtle' );
	     my $parser2 = RDF::Trine::Parser->new( 'rdfxml' );
	     $parser1->parse_into_model( 'http://example.org', '</foo> <http://www.w3.org/2000/01/rdf-schema#label> "This is a Another test"@en .', $model1);

	     $parser2->parse_into_model( 'http://example.org', '<?xml version="1.0" encoding="utf-8"?><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"><rdf:Description rdf:about="/foo"><ns0:label xmlns:ns0="http://www.w3.org/2000/01/rdf-schema#" xml:lang="en">This is a test</ns0:label></rdf:Description></rdf:RDF>', $model2);
	     isomorph_graphs($model1, $model2, 'Compare RDF/XML and Turtle, with error');
	   },
	   {
	    ok => 0,
	    name => 'Compare RDF/XML and Turtle, with error',
	    diag => "Graphs differ:\nnon-blank triples don't match: \$VAR1 = '(triple <http://example.org/foo> <http://www.w3.org/2000/01/rdf-schema#label> \"This is a Another test\"\@en)';\n\$VAR2 = '(triple <http://example.org/foo> <http://www.w3.org/2000/01/rdf-schema#label> \"This is a test\"\@en)';"
	   }
);
