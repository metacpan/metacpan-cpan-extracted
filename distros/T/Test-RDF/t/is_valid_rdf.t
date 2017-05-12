use Test::Tester tests => 23;
use Test::More;
use Test::RDF;

check_test(
	   sub {
	     is_valid_rdf('</foo> <http://www.w3.org/2000/01/rdf-schema#label> "This is a Another test"@en .', 'turtle', 'Valid turtle');
	   },
	   {
	    ok => 1,
	    name => 'Valid turtle'
	   }
);

check_test(
	   sub {
	     is_valid_rdf('', 'turtle', 'Pass empty string' );
	   },
	   {
	    ok => 0,
	    name => 'Pass empty string',
	    diag => 'No input was given.'
	   }
);

{
  my ($premature, @results) = run_tests(
	   sub {
	     is_valid_rdf('</foo> <http://www.w3.org/2000/01/rdf-schema#label> "This is a Another test@en .', 'turtle', 'Valid turtle');
	   });
  is($results[0]->{ok}, 0, 'Not Valid turtle');
  like($results[0]->{diag}, qr/Input was not valid RDF:\n\n\t(No tokens|Redland error: syntax error at '"'|Got '"' while expecting string character at 1:[5-8]\d)/, 'Error message is correct');
}

check_test(
	   sub {
	     is_valid_rdf('<?xml version="1.0" encoding="utf-8"?><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"><rdf:Description rdf:about="/foo"><ns0:label xmlns:ns0="http://www.w3.org/2000/01/rdf-schema#" xml:lang="en">This is a Another test</ns0:label></rdf:Description></rdf:RDF>', 'rdfxml', 'Valid RDF/XML');
	   },
	   {
	    ok => 1,
	    name => 'Valid RDF/XML',
	   }
);

{
  my ($premature, @results) = run_tests(
	   sub {
	     is_valid_rdf('<?xml version="1.0" encoding="utf-8"?><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"><rdf:Description rdf:about="/foo"><label xmlns:ns0="http://www.w3.org/2000/01/rdf-schema#" xml:lang="en">This is a Another test</label></rdf:Description></rdf:RDF>', 'rdfxml', 'Valid RDF/XML');
	   });
  is($results[0]->{ok}, 0, 'Not Valid RDF/XML');
  like($results[0]->{diag}, qr/Input was not valid RDF:\n\n\t(Unknown namespace: |Redland error: Using an element 'Description' without a namespace is forbidden.)/, 'Error message is correct');
}

