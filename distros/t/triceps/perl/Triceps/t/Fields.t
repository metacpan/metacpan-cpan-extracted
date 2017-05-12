#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# Test of the field list processing.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 46 };
use Triceps;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#########################
# fields()

@res = &Triceps::Fields::filter("Caller", [ 'abc', 'def' ], undef);
ok(join(",", map { defined $_? $_ : "-" } @res), "abc,def"); # all positive if no patterns

@res = &Triceps::Fields::filter("Caller", [ 'abc', 'def', 'ghi' ], [ 'abc', 'def' ] );
ok(join(",", map { defined $_? $_ : "-" } @res), "abc,def,-");

@res = &Triceps::Fields::filter("Caller", [ 'abc', 'def', 'ghi' ], [ '!abc' ] );
ok(join(",", map { defined $_? $_ : "-" } @res), "-,-,-"); # check for default being "throwaway" even with purely negative
@res = &Triceps::Fields::filter("Caller", [ 'abc', 'def', 'ghi' ], [ ] );
ok(join(",", map { defined $_? $_ : "-" } @res), "-,-,-"); # empty pattern means throw away everything

@res = &Triceps::Fields::filter("Caller", [ 'abc', 'def', 'ghi' ], [ '!abc', '.*' ] );
ok(join(",", map { defined $_? $_ : "-" } @res), "-,def,ghi");

@res = &Triceps::Fields::filter("Caller", [ 'abc', 'adef', 'gahi' ], [ '!abc', 'a.*' ] );
ok(join(",", map { defined $_? $_ : "-" } @res), "-,adef,-"); # first match wins, and check front anchoring

@res = &Triceps::Fields::filter("Caller", [ 'abc', 'adef', 'gahi' ], [ '...' ] );
ok(join(",", map { defined $_? $_ : "-" } @res), "abc,-,-"); # anchoring

@res = &Triceps::Fields::filter("Caller", [ 'abc', 'def', 'ghi' ], [ '!a.*', '.*' ] );
ok(join(",", map { defined $_? $_ : "-" } @res), "-,def,ghi"); # negative pattern

@res = &Triceps::Fields::filter("Caller", [ 'abc', 'def', 'ghi' ], [ '.*/second_$&' ] );
ok(join(",", map { defined $_? $_ : "-" } @res), "second_abc,second_def,second_ghi"); # substitution

@res = &Triceps::Fields::filter("Caller", [ 'abc', 'defg', 'ghi' ], [ '(.).(.)/$1x$2' ] );
ok(join(",", map { defined $_? $_ : "-" } @res), "axc,-,gxi"); # anchoring and numbered sub-expressions

# missing fields in fields()
eval {
	@res = &Triceps::Fields::filter("Caller", [ 'abc', 'def', 'ghi' ], [ 'cba', 'fed' ] );
};
ok($@, qr/Caller: result definition error:
  the field in definition 'cba' is not found
  the field in definition 'fed' is not found
The available fields are:
  abc, def, ghi
/);

eval {
	@res = &Triceps::Fields::filter("Caller", [ 'abc', 'def', 'ghi' ], [ 'cba/abc', '!fed' ] );
};
ok($@, qr/Caller: result definition error:
  the field in definition 'cba\/abc' is not found
  the field in definition '!fed' is not found
The available fields are:
  abc, def, ghi
/);
#print STDERR "$@\n";

#########################
# filterToPairs() - touch-test, since it works through filter()

@res = &Triceps::Fields::filterToPairs("Caller", [ 'abc', 'defg', 'ghi' ], [ '(.).(.)/$1x$2' ] );
ok(join(",", map { defined $_? $_ : "-" } @res), "abc,axc,ghi,gxi"); # anchoring and numbered sub-expressions

eval {
	@res = &Triceps::Fields::filterToPairs("Caller", [ 'abc', 'def', 'ghi' ], [ 'cba/abc', '!fed' ] );
};
ok($@, qr/Caller: result definition error:
  the field in definition 'cba\/abc' is not found
  the field in definition '!fed' is not found
The available fields are:
  abc, def, ghi
/);

#########################
# makeTranslation()

# the row types and translations that will be reused
my $tr_rt1 = Triceps::RowType->new(
	abc => 'string',
	def => 'int32[]',
	ghi => 'uint8[]',
);
ok(ref $tr_rt1, "Triceps::RowType");
my $tr_row11 = $tr_rt1->makeRowArray("tabc", [1, 2, 3], "tghi");
ok(ref $tr_row11, "Triceps::Row");
my $tr_pairs1a = [ 'def', 'f2', 'abc', 'f1' ];

my $tr_rt2 = Triceps::RowType->new(
	one => 'string',
	two => 'float64[]',
	three => 'uint8',
);
my $tr_row21 = $tr_rt2->makeRowArray("tone", [1.5, 2.5], "x");
ok(ref $tr_row21, "Triceps::Row");
ok(ref $tr_rt2, "Triceps::RowType");
my $tr_pairs2a = [ 'one', 'field1', 'two', 'field2' ];

{
	my $src;
	my ($rt, $func) = Triceps::Fields::makeTranslation(
		rowTypes => [ $tr_rt1, $tr_rt2 ],
		filterPairs => [ $tr_pairs1a, $tr_pairs2a ],
		saveCodeTo => \$src,
	);
	ok(ref $rt, "Triceps::RowType");
	my $def =join(', ',  $rt->getdef());
	ok($def, "f2, int32[], f1, string, field1, string, field2, float64[]");
	ok($src =~ '^\n\t*sub');
	my $res = &$func($tr_row11, $tr_row21);
	ok(ref $res, "Triceps::Row");
	my $p = $res->printP();
	#print "$p\n";
	ok($p, 'f2=["1", "2", "3"] f1="tabc" field1="tone" field2=["1.5", "2.5"] ');

	# call the function with bad number of args
	$res = eval { &$func($tr_row11) };
	ok(!defined $res);
	ok($@ =~ '^template internal error in Triceps::Fields::makeTranslation: result translation expected 2 row args, received 1 at');
}
{
	# with 1 type
	my ($rt, $func) = Triceps::Fields::makeTranslation(
		rowTypes => [ $tr_rt2 ],
		filterPairs => [ $tr_pairs2a ],
	);
	ok(ref $rt, "Triceps::RowType");
	my $def =join(', ',  $rt->getdef());
	ok($def, "field1, string, field2, float64[]");
	my $res = &$func($tr_row21);
	ok(ref $res, "Triceps::Row");
	my $p = $res->printP();
	#print "$p\n";
	ok($p, 'field1="tone" field2=["1.5", "2.5"] ');
}

{
	# missing mandatory args
	eval { 
		Triceps::Fields::makeTranslation(
			filterPairs => [ $tr_pairs1a, $tr_pairs2a ],
		);
	};
	ok($@, qr/^Option 'rowTypes' must be specified for class 'Triceps::Fields' at/);

	eval { 
		Triceps::Fields::makeTranslation(
			rowTypes => [ $tr_rt1, $tr_rt2 ],
		);
	};
	ok($@, qr/^Option 'filterPairs' must be specified for class 'Triceps::Fields' at/);

	# args size mismatch
	eval { 
		Triceps::Fields::makeTranslation(
			rowTypes => [ $tr_rt1, $tr_rt2 ],
			filterPairs => [ $tr_pairs1a ],
		);
	};
	ok($@, qr/^Triceps::Fields::makeTranslation: the arrays of row types and filter pairs must be of the same size, got 2 and 1 elements at/);

	# duplicate fields in the result
	eval { 
		Triceps::Fields::makeTranslation(
			rowTypes => [ $tr_rt1, $tr_rt2 ],
			filterPairs => [ $tr_pairs1a, [ 'one', 'f1', 'two', 'f2' ] ],
		);
	};
	#print "$@\n";
	ok($@, qr/^Triceps::Fields::makeTranslation: Invalid result row type specification:
  Triceps::RowType::new: incorrect specification:
    duplicate field name 'f1' for fields 3 and 2
    duplicate field name 'f2' for fields 4 and 1
  Triceps::RowType::new: The specification was: \{
    f2 => int32\[\]
    f1 => string
    f1 => string
    f2 => float64\[\]
  \} at/);

	# error in the auto-generated code
	eval {
		my ($rt, $func) = Triceps::Fields::makeTranslation(
			rowTypes => [ $tr_rt2 ],
			filterPairs => [ $tr_pairs2a ],
			_simulateCodeError => 1,
		);
	};
	#print "$@\n";
	ok($@, qr/^Triceps::Fields::makeTranslation: error in compilation of the generated function:
  syntax error at \(eval \d+\) line \d+, near "\}\)
"
function text:
     2 sub \{ # \(\@rows\)
/);

}

#########################
# isArrayType()
ok(!&Triceps::Fields::isArrayType("int32"));
ok(&Triceps::Fields::isArrayType("int32[]"));
ok(!&Triceps::Fields::isArrayType("string"));
ok(!&Triceps::Fields::isArrayType("uint8"));
ok(!&Triceps::Fields::isArrayType("uint8[]"));

#########################
# isStringType()
ok(&Triceps::Fields::isStringType("uint8"));
ok(&Triceps::Fields::isStringType("uint8[]"));
ok(&Triceps::Fields::isStringType("string"));
ok(!&Triceps::Fields::isStringType("int32"));
ok(!&Triceps::Fields::isStringType("int64[]"));
ok(!&Triceps::Fields::isStringType("float64"));
