use Test::Tester tests => 118;

use Test::RDF;

use RDF::Trine;

my $model = RDF::Trine::Model->temporary_model;
my $parser = RDF::Trine::Parser->new( 'turtle' );
$parser->parse_into_model( 'http://example.org', '</foo> <http://www.w3.org/2000/01/rdf-schema#label> "This is a Another test"@en ; a </Bar> .', $model);


check_test(
	   sub {
	     has_subject('http://example.org/foo', $model, 'Has correct subject URI');
	   },
	   {
	    ok => 1,
	    name => 'Has correct subject URI',
	   }
);



check_test(
	   sub {
	     has_subject('http://example.com/foo', $model, 'Has not correct subject URI');
	   },
	   {
	    ok => 0,
	    name => 'Has not correct subject URI',
	    diag => 'No matching URIs found in model'
	   }
);

check_test(
	   sub {
	     has_subject('"This is a Another test"@en', $model, 'Has literal not subject');
	   },
	   {
	    ok => 0,
	    name => 'Has literal not subject',
	    diag => 'No matching URIs found in model'
	   }
);

check_test(
	   sub {
	     has_predicate('http://www.w3.org/2000/01/rdf-schema#label', $model, 'Has correct predicate URI');
	   },
	   {
	    ok => 1,
	    name => 'Has correct predicate URI',
	   }
);

check_test(
	   sub {
	     has_predicate('http://example.com/foo', $model, 'Has not correct predicate URI');
	   },
	   {
	    ok => 0,
	    name => 'Has not correct predicate URI',
	    diag => 'No matching URIs found in model'
	   }
);

check_test(
	   sub {
	     has_object_uri('http://example.org/Bar', $model, 'Has correct object URI');
	   },
	   {
	    ok => 1,
	    name => 'Has correct object URI',
	   }
);

check_test(
	   sub {
	     has_object_uri('http://example.com/Bar', $model, 'Has not correct object URI');
	   },
	   {
	    ok => 0,
	    name => 'Has not correct object URI',
	    diag => 'No matching URIs found in model'
	   }
);

check_test(
	   sub {
	     has_object_uri('"This is a Another test"@en', $model, 'Has literal not URI');
	   },
	   {
	    ok => 0,
	    name => 'Has literal not URI',
	    diag => 'No matching URIs found in model'
	   }
);


check_test(
	   sub {
	     has_uri('http://example.org/foo', $model, 'Has correct subject URI');
	   },
	   {
	    ok => 1,
	    name => 'Has correct subject URI',
	   }
);

check_test(
	   sub {
	     has_uri('http://www.w3.org/2000/01/rdf-schema#label', $model, 'Has correct predicate URI');
	   },
	   {
	    ok => 1,
	    name => 'Has correct predicate URI',
	   }
);

check_test(
	   sub {
	     has_uri('http://example.org/Bar', $model, 'Has correct object URI');
	   },
	   {
	    ok => 1,
	    name => 'Has correct object URI',
	   }
);


check_test(
	   sub {
	     has_uri('http://example.com/foo', $model, 'Has not correct URI');
	   },
	   {
	    ok => 0,
	    name => 'Has not correct URI',
	    diag => 'No matching URIs found in model'
	   }
);

check_test(
	   sub {
	     has_uri('"This is a Another test"@en', $model, 'Has a literal');
	   },
	   {
	    ok => 0,
	    name => 'Has a literal',
	    diag => 'No matching URIs found in model'
	   }
);


check_test(
	   sub {
	     hasnt_uri('http://example.org/foo', $model, 'Has correct subject URI');
	   },
	   {
	    ok => 0,
		 diag => 'Matching URIs found in model',
	    name => 'Has correct subject URI',
	   }
);

check_test(
	   sub {
	     hasnt_uri('http://www.w3.org/2000/01/rdf-schema#label', $model, 'Has correct predicate URI');
	   },
	   {
	    ok => 0,
		 diag => 'Matching URIs found in model',
	    name => 'Has correct predicate URI',
	   }
);

check_test(
	   sub {
	     hasnt_uri('http://example.org/Bar', $model, 'Has correct object URI');
	   },
	   {
	    ok => 0,
		 diag => 'Matching URIs found in model',
	    name => 'Has correct object URI',
	   }
);


check_test(
	   sub {
	     hasnt_uri('http://example.com/foo', $model, 'Has not correct URI');
	   },
	   {
	    ok => 1,
	    name => 'Has not correct URI',
	   }
);

check_test(
	   sub {
	     hasnt_uri('"This is a Another test"@en', $model, 'Has a literal');
	   },
	   {
	    ok => 1,
	    name => 'Has a literal',
	   }
);

