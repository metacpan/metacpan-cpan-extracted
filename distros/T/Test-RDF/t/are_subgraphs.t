use Test::Tester tests => 52;

use Test::RDF;

check_test(
	   sub {
	     my $model1 = RDF::Trine::Model->temporary_model;
	     my $model2 = RDF::Trine::Model->temporary_model;
	     my $parser = RDF::Trine::Parser->new( 'turtle' );
	     $parser->parse_into_model( 'http://example.org', '</foo> <http://www.w3.org/2000/01/rdf-schema#label> "This is a Another test"@en .', $model1);
	     $parser->parse_into_model( 'http://example.org', '</foo> <http://www.w3.org/2000/01/rdf-schema#label> "This is a Another test"@en .', $model2);
	     are_subgraphs($model1, $model2, 'Compare Turtle exact matches' );
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
	     my $parser = RDF::Trine::Parser->new( 'turtle' );
	     $parser->parse_into_model( 'http://example.org', '</foo> <http://www.w3.org/2000/01/rdf-schema#label> "This is a Another test"@en ; <http://www.w3.org/2000/01/rdf-schema#comment> "With more" .', $model1);
	     $parser->parse_into_model( 'http://example.org', '</foo> <http://www.w3.org/2000/01/rdf-schema#label> "This is a Another test"@en .', $model2);
	     are_subgraphs($model1, $model2, 'Compare Turtle with extra in model1' );
	   },
	   {
	    ok => 0,
	    name => 'Compare Turtle with extra in model1',
	    diag => "Graph not subgraph: invocant had too many blank node statements to be a subgraph of argument\nHint: There are 2 statement(s) in model1 and 1 statement(s) in model2"
	   }
);


check_test(
	   sub {
	     my $model1 = RDF::Trine::Model->temporary_model;
	     my $model2 = RDF::Trine::Model->temporary_model;
	     my $parser = RDF::Trine::Parser->new( 'turtle' );
	     $parser->parse_into_model( 'http://example.org', '</foo> <http://www.w3.org/2000/01/rdf-schema#label> "This is a Another test"@en ; <http://www.w3.org/2000/01/rdf-schema#comment> "With more" .', $model1);
	     $parser->parse_into_model( 'http://example.org', '</foo> <http://www.w3.org/2000/01/rdf-schema#foo> "This is a Another test"@en ; <http://www.w3.org/2000/01/rdf-schema#comment> "With other" .', $model2);

	     are_subgraphs($model1, $model2, 'Compare Turtle with extra in both' );
	   },
	   {
	    ok => 0,
	    name => 'Compare Turtle with extra in both',
	    diag => "Hint: There are 2 statement(s) in model1 and 2 statement(s) in model2"
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
	     are_subgraphs($model1, $model2, 'Compare RDF/XML and Turtle');
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
	     $parser->parse_into_model( 'http://example.org', '</foo> <http://www.w3.org/2000/01/rdf-schema#label> "This is a Another test"@en ; <http://www.w3.org/2000/01/rdf-schema#comment> "With more" .', $model2);
	     are_subgraphs($model1, $model2, 'Compare Turtle with extra in model2' );
	   },
	   {
	    ok => 1,
	    name => 'Compare Turtle with extra in model2',
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
	     are_subgraphs($model1, $model2, 'Compare RDF/XML and Turtle');
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
	     are_subgraphs($model1, $model2, 'Compare Turtle exact matches, with error' );
	   },
	   {
	    ok => 0,
	    name => 'Compare Turtle exact matches, with error',
	    diag => "Hint: There are 1 statement(s) in model1 and 1 statement(s) in model2"
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
	     are_subgraphs($model1, $model2, 'Compare RDF/XML and Turtle, with error');
	   },
	   {
	    ok => 0,
	    name => 'Compare RDF/XML and Turtle, with error',
	    diag => "Hint: There are 1 statement(s) in model1 and 1 statement(s) in model2"
	   }
);
