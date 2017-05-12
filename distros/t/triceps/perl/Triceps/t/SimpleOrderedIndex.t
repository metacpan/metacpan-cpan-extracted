#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The test for SimpleOrderedIndex.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 37 };
use Triceps;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#########################
# common definitions

my $u1 = Triceps::Unit->new("u1");
ok(ref $u1, "Triceps::Unit");

my @def1 = (
	a => "uint8",
	b => "uint8[]",
	c => "int64",
	d => "float64[]",
	e => "string",
);
my $rt1 = Triceps::RowType->new( # used later
	@def1
);
ok(ref $rt1, "Triceps::RowType");


#########################
# a successfull construction

{
	my $it1 = Triceps::SimpleOrderedIndex->new(
		c => "ASC",
		e => "DESC",
	);
	ok(ref $it1, "Triceps::SimpleOrderedIndex");
	my $it2 = Triceps::SimpleOrderedIndex->new(
		a => "ASC",
		c => "desC", # mixed-case
		b => "asc", # data will have all NULLs, will have no effect
	);
	ok(ref $it2, "Triceps::SimpleOrderedIndex");

	my $tt1 = Triceps::TableType->new($rt1)
		->addSubIndex("byCE", $it1)
		->addSubIndex("byAC", $it2)
	;
	ok(ref $tt1, "Triceps::TableType");

	my $xit1 = $tt1->findSubIndex("byCE");
	ok(ref $xit1, "Triceps::IndexType"); # the class identity gets lost
	my $xit2 = $tt1->findSubIndex("byAC");
	ok(ref $xit2, "Triceps::IndexType");

	$res = $tt1->print();
	#print $res;
	ok($res, "table (\n  row {\n    uint8 a,\n    uint8[] b,\n    int64 c,\n    float64[] d,\n    string e,\n  }\n) {\n  index PerlSortedIndex(SimpleOrder c ASC, e DESC, ) byCE,\n  index PerlSortedIndex(SimpleOrder a ASC, c desC, b asc, ) byAC,\n}");

	$res = $tt1->initialize();
	ok($res);

	my $t1 = $u1->makeTable($tt1, "t1");
	ok(ref $t1, "Triceps::Table");

	# make some records and stick them in, put pseudo-numeric values into the strings
	my $r1 = $rt1->makeRowHash(a => "100", c => 1, e => "90");
	ok(ref $r1, "Triceps::Row");
	my $r2 = $rt1->makeRowHash(a => "90", c => 1, e => "100");
	ok(ref $r2, "Triceps::Row");
	my $r3 = $rt1->makeRowHash(a => "100", c => 2, e => "90");
	ok(ref $r3, "Triceps::Row");
	my $r4 = $rt1->makeRowHash(a => "90", c => 2, e => "100");
	ok(ref $r4, "Triceps::Row");

	# insert them in a mixed order
	ok($t1->insert($r2));
	ok($t1->insert($r3));
	ok($t1->insert($r1));
	ok($t1->insert($r4));

	my $iter;
	# check the order in byCE
	$iter = $t1->beginIdx($xit1);
	ok($iter->getRow()->same($r1));
	$iter = $iter->nextIdx($xit1);
	ok($iter->getRow()->same($r2));
	$iter = $iter->nextIdx($xit1);
	ok($iter->getRow()->same($r3));
	$iter = $iter->nextIdx($xit1);
	ok($iter->getRow()->same($r4));
	$iter = $iter->nextIdx($xit1);
	ok($iter->isNull());

	# check the order in byAC
	$iter = $t1->beginIdx($xit2);
	ok($iter->getRow()->same($r3));
	$iter = $iter->nextIdx($xit2);
	ok($iter->getRow()->same($r1));
	$iter = $iter->nextIdx($xit2);
	ok($iter->getRow()->same($r4));
	$iter = $iter->nextIdx($xit2);
	ok($iter->getRow()->same($r2));
	$iter = $iter->nextIdx($xit2);
	ok($iter->isNull());
}

#########################
# errors

{
	my $tt1 = Triceps::TableType->new($rt1)
		->addSubIndex("sorted", 
			Triceps::SimpleOrderedIndex->new(
				z => "XASC",
				d => "DESC",
			)
		);
	ok(ref $tt1, "Triceps::TableType");
	$res = eval { $tt1->initialize(); };
	ok(!defined $res);
	ok($@, 
qr/^index error:
  nested index 1 'sorted':
    unknown direction 'XASC' for field 'z', use 'ASC' or 'DESC'
    no field 'z' in the row type
    can not order by the field 'd', it has an array type 'float64\[\]', not supported yet
    the row type is:
    row \{
      uint8 a,
      uint8\[\] b,
      int64 c,
      float64\[\] d,
      string e,
    \} at/);
}

#########################
# test a weird field name

{
	my $rt2 = Triceps::RowType->new(
		'a"b' => "int32"
	);
	ok(ref $rt2, "Triceps::RowType");
	my $tt1 = Triceps::TableType->new($rt2)
		->addSubIndex("sorted", 
			Triceps::SimpleOrderedIndex->new(
				'a"b' => "ASC",
			)
		);
	ok(ref $tt1, "Triceps::TableType");
	$res = $tt1->print();
	#print $res, "\n";
	ok($res, "table (\n  row {\n    int32 a\"b,\n  }\n) {\n  index PerlSortedIndex(SimpleOrder a\\\"b ASC, ) sorted,\n}");

	$res = $tt1->initialize();
	ok($res);

	my $tt2 = Triceps::TableType->new($rt2)
		->addSubIndex("sorted", 
			Triceps::SimpleOrderedIndex->new(
				'a"b' => "A'SC",
			)
		);
	$res = $tt2->print();
	#print $res, "\n";
	ok($res, "table (\n  row {\n    int32 a\"b,\n  }\n) {\n  index PerlSortedIndex(SimpleOrder a\\\"b A\\'SC, ) sorted,\n}");
}

