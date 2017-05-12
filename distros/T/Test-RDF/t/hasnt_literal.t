use Test::Tester tests => 83;

use Test::RDF;

use RDF::Trine;

my $model = RDF::Trine::Model->temporary_model;
my $parser = RDF::Trine::Parser->new( 'turtle' );
$parser->parse_into_model( 'http://example.org', '</foo> <http://www.w3.org/2000/01/rdf-schema#label> "This is a Another test"@en ; </title> "A test" ; </number> 42 ; a </Bar> .', $model);

check_test(
	   sub {
	     hasnt_literal('A new test', undef, undef, $model, 'Simple literal');
	   },
	   {
	    ok => 1,
	    name => 'Simple literal',
	   }
);

check_test(
	   sub {
	     hasnt_literal('A test', 'en', undef, $model, 'Not a simple literal');
	   },
	   {
	    ok => 1,
	    name => 'Not a simple literal',
	   }
);

check_test(
	   sub {
	     hasnt_literal('A test', undef, undef, $model, 'Not a simple literal');
	   },
	   {
	    ok => 0,
	    name => 'Not a simple literal',
	    diag => 'Matching literals found in model'
	   }
);


check_test(
	   sub {
	     hasnt_literal('42', undef, 'http://www.w3.org/2001/XMLSchema#integer', $model, 'Just an integer');
	   },
	   {
	    ok => 0,
	    name => 'Just an integer',
	    diag => 'Matching literals found in model'
	   }
);

check_test(
	   sub {
	     hasnt_literal('42', undef, undef, $model, 'Not a integer simple literal');
	   },
	   {
	    ok => 1,
	    name => 'Not a integer simple literal',
	   }
);

check_test(
	   sub {
	     hasnt_literal('42', 'en', 'http://www.w3.org/2001/XMLSchema#integer', $model, 'Integer with lang and datatype');
	   },
	   {
	    ok => 0,
	    name => 'Integer with lang and datatype',
	    diag => "Invalid literal:\n\n\tLiteral values cannot have both language and datatype"
	   }
);

check_test(
	   sub {
	     hasnt_literal('42', 'en', undef, $model, 'Literal integer with lang');
	   },
	   {
	    ok => 1,
	    name => 'Literal integer with lang',
	   }
);

check_test(
	   sub {
	     hasnt_literal('This is a Another test', 'en', undef, $model, 'Language literal');
	   },
	   {
	    ok => 0,
	    name => 'Language literal',
	    diag => 'Matching literals found in model'
	   }
);

check_test(
	   sub {
	     hasnt_literal('This is not Another test', 'en', undef, $model, 'Language literal');
	   },
	   {
	    ok => 1,
	    name => 'Language literal',
	   }
);

check_test(
	   sub {
	     hasnt_literal('This is a Another test', 'no', undef, $model, 'Literal with wrong language');
	   },
	   {
	    ok => 1,
	    name => 'Literal with wrong language',
	   }
);

check_test(
	   sub {
	     hasnt_literal('This is a Another test', 'en', 'http://www.w3.org/2001/XMLSchema#integer', $model, 'Literal with language and datatype');
	   },
	   {
	    ok => 0,
	    name => 'Literal with language and datatype',
	    diag => "Invalid literal:\n\n\tLiteral values cannot have both language and datatype"
	   }
);

check_test(
	   sub {
	     hasnt_literal('http://example.com/Bar', undef, undef, $model, 'Has a URI');
	   },
	   {
	    ok => 1,
	    name => 'Has a URI',
	   }
);

check_test(
	   sub {
	     hasnt_literal('"This is a Another test"@en', undef, undef, $model, 'Has a string not literal');
	   },
	   {
	    ok => 1,
	    name => 'Has a string not literal',
	   }
);

