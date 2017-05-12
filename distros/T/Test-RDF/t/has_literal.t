use Test::Tester tests => 80;

use Test::RDF;

use RDF::Trine;

my $model = RDF::Trine::Model->temporary_model;
my $parser = RDF::Trine::Parser->new( 'turtle' );
$parser->parse_into_model( 'http://example.org', '</foo> <http://www.w3.org/2000/01/rdf-schema#label> "This is a Another test"@en ; </title> "A test" ; </number> 42 ; a </Bar> .', $model);

check_test(
	   sub {
	     has_literal('A test', undef, undef, $model, 'Simple literal');
	   },
	   {
	    ok => 1,
	    name => 'Simple literal',
	   }
);

check_test(
	   sub {
	     has_literal('A test', 'en', undef, $model, 'Not a simple literal');
	   },
	   {
	    ok => 0,
	    name => 'Not a simple literal',
	    diag => 'No matching literals found in model'
	   }
);


check_test(
	   sub {
	     has_literal('42', undef, 'http://www.w3.org/2001/XMLSchema#integer', $model, 'Just an integer');
	   },
	   {
	    ok => 1,
	    name => 'Just an integer',
	   }
);

check_test(
	   sub {
	     has_literal('42', undef, undef, $model, 'Not a simple literal');
	   },
	   {
	    ok => 0,
	    name => 'Not a simple literal',
	    diag => 'No matching literals found in model'
	   }
);

check_test(
	   sub {
	     has_literal('42', 'en', 'http://www.w3.org/2001/XMLSchema#integer', $model, 'Not a simple literal');
	   },
	   {
	    ok => 0,
	    name => 'Not a simple literal',
	    diag => "Invalid literal:\n\n\tLiteral values cannot have both language and datatype"
	   }
);

check_test(
	   sub {
	     has_literal('42', 'en', undef, $model, 'Not a simple literal');
	   },
	   {
	    ok => 0,
	    name => 'Not a simple literal',
	    diag => 'No matching literals found in model'
	   }
);

check_test(
	   sub {
	     has_literal('This is a Another test', 'en', undef, $model, 'Language literal');
	   },
	   {
	    ok => 1,
	    name => 'Language literal',
	   }
);

check_test(
	   sub {
	     has_literal('This is a Another test', 'en', undef, $model, 'Language literal');
	   },
	   {
	    ok => 1,
	    name => 'Language literal',
	   }
);

check_test(
	   sub {
	     has_literal('This is a Another test', 'no', undef, $model, 'Literal with wrong language');
	   },
	   {
	    ok => 0,
	    name => 'Literal with wrong language',
	    diag => 'No matching literals found in model'
	   }
);

check_test(
	   sub {
	     has_literal('This is a Another test', 'en', 'http://www.w3.org/2001/XMLSchema#integer', $model, 'Literal with language and datatype');
	   },
	   {
	    ok => 0,
	    name => 'Literal with language and datatype',
	    diag => "Invalid literal:\n\n\tLiteral values cannot have both language and datatype"
	   }
);

check_test(
	   sub {
	     has_literal('http://example.com/Bar', undef, undef, $model, 'Has a URI');
	   },
	   {
	    ok => 0,
	    name => 'Has a URI',
	    diag => 'No matching literals found in model'
	   }
);

check_test(
	   sub {
	     has_literal('"This is a Another test"@en', undef, undef, $model, 'Has a string not literal');
	   },
	   {
	    ok => 0,
	    name => 'Has a string not literal',
	    diag => 'No matching literals found in model'
	   }
);

