use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 9;
use Test::NoWarnings;
use WQS::SPARQL::Query::Select;

# Test.
my $obj = WQS::SPARQL::Query::Select->new;
my $property_isbn = 'P957';
my $isbn = '80-239-7791-1';
my $sparql = $obj->select_value({$property_isbn => $isbn});
my $right_ret = <<"END";
SELECT ?item WHERE {
  ?item wdt:$property_isbn '$isbn'.
}
END
is($sparql, $right_ret, 'SPARQL select query with one statement.');

# Test.
my $property_instance = 'P31';
my $instance = 'Q5';
$property_isbn = 'P957';
$isbn = '80-239-7791-1';
$sparql = $obj->select_value({
	$property_instance => $instance,
	$property_isbn => $isbn,
});
$right_ret = <<"END";
SELECT ?item WHERE {
  ?item wdt:$property_instance wd:$instance.
  ?item wdt:$property_isbn '$isbn'.
}
END
is($sparql, $right_ret, 'SPARQL select query with two statements.');

# Test.
$property_instance = 'P31';
$instance = 'Q2085381';
my $property_official_name = 'P1448';
my $official_name = 'LIBRI, spol. s r.o.';
my $official_name_lang = 'cs';
$sparql = $obj->select_value({
	$property_instance => $instance,
	$property_official_name => $official_name.'@'.$official_name_lang,
});
$right_ret = <<"END";
SELECT ?item WHERE {
  ?item wdt:$property_instance wd:$instance.
  ?item wdt:$property_official_name '$official_name'\@$official_name_lang.
}
END
is($sparql, $right_ret, 'SPARQL select query with multilingual text.');

# Test.
$property_instance = 'P31';
my $subclass_instance = 'P279*';
$instance = 'Q2085381';
$sparql = $obj->select_value({
	$property_instance.'/'.$subclass_instance => $instance,
});
$right_ret = <<"END";
SELECT ?item WHERE {
  ?item wdt:$property_instance/wdt:$subclass_instance wd:$instance.
}
END
is($sparql, $right_ret, 'SPARQL select query with subclass.');

# Test.
$property_instance = 'bad';
$instance = 'Q2085381';
eval {
	$obj->select_value({
		$property_instance => $instance,
	});
};
is($EVAL_ERROR, "Bad property 'bad'.\n", "Bad property 'bad'.");
clean();

# Test.
$obj = WQS::SPARQL::Query::Select->new;
$property_isbn = 'P957';
my $foo = '?foo';
$sparql = $obj->select_value({
	$property_isbn => $foo,
}, [
	['?foo', '==', "'bar'"],
]);
$right_ret = <<"END";
SELECT ?item WHERE {
  ?item wdt:$property_isbn ?foo.
  FILTER(?foo == 'bar')
}
END
is($sparql, $right_ret, 'SPARQL select query with one statement.');

# Test.
$property_instance = 'P31';
$instance = 'Q5';
my $property_name = 'P1448';
my $name = "foo'bar'baz";
$sparql = $obj->select_value({
	$property_instance => $instance,
	$property_name => $name,
});
$right_ret = <<"END";
SELECT ?item WHERE {
  ?item wdt:$property_instance wd:$instance.
  ?item wdt:$property_name 'foo\\\'bar\\\'baz'.
}
END
is($sparql, $right_ret, 'SPARQL select query with two statements with escape sequences.');

# Test.
$property_instance = 'P31';
$instance = 'Q5';
$property_name = 'P1448';
$name = "foo'bar'baz\@cs";
$sparql = $obj->select_value({
	$property_instance => $instance,
	$property_name => $name,
});
$right_ret = <<"END";
SELECT ?item WHERE {
  ?item wdt:$property_instance wd:$instance.
  ?item wdt:$property_name 'foo\\\'bar\\\'baz'\@cs.
}
END
is($sparql, $right_ret, 'SPARQL select query with two statements with escape sequences plus lang.');
