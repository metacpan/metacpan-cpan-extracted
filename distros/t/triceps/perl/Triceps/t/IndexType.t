#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The test for IndexType.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 125 };
use Triceps;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#########################

# the test of newPerlSorted() is in SortedIndexType.t

###################### newHashed #################################

$it1 = Triceps::IndexType->newHashed(key => [ "a", "b" ]);
ok(ref $it1, "Triceps::IndexType");
$res = $it1->print();
ok($res, "index HashedIndex(a, b, )");

$key = join(",", $it1->getKey());
ok($key, "a,b");

$res = eval { $it1->getTabtype(); };
ok(!defined $res);
ok($@, qr/^Triceps::IndexType::getTabtype: this index type does not belong to an initialized table type at/);

$res = $it1->getTabtypeSafe();
ok(!defined $res);

$it1 = eval { Triceps::IndexType->newHashed("key"); };
ok(!defined($it1));
ok($@, qr/^Usage: Triceps::IndexType::newHashed\(CLASS, optionName, optionValue, ...\), option names and values must go in pairs at/);

$it1 = eval { Triceps::IndexType->newHashed(zzz => [ "a", "b" ]); };
ok(!defined($it1));
ok($@, qr/^Triceps::IndexType::newHashed: unknown option 'zzz' at/);

$it1 = eval { Triceps::IndexType->newHashed(key => [ "a", "b" ], key => ["c"]); };
ok(!defined($it1));
ok($@, qr/^Triceps::IndexType::newHashed: option 'key' can not be used twice at/);

$it1 = eval { Triceps::IndexType->newHashed(key => { "a", "b" }); };
ok(!defined($it1));
ok($@, qr/^Triceps::IndexType::newHashed: option 'key' value must be an array reference at/);

$it1 = eval { Triceps::IndexType->newHashed(key => undef); };
ok(!defined($it1));
ok($@, qr/^Triceps::IndexType::newHashed: option 'key' value must be an array reference at/);

$it1 = eval { Triceps::IndexType->newHashed(); };
ok(!defined($it1));
ok($@, qr/^Triceps::IndexType::newHashed: the required option 'key' is missing at/);

###################### newFifo #################################

$it1 = Triceps::IndexType->newFifo();
ok(ref $it1, "Triceps::IndexType");
$res = $it1->print();
ok($res, "index FifoIndex()");

$it1 = Triceps::IndexType->newFifo(limit => 10, jumping => 1);
ok(ref $it1, "Triceps::IndexType");
$res = $it1->print();
ok($res, "index FifoIndex(limit=10 jumping)");

$it1 = Triceps::IndexType->newFifo(reverse => 1);
ok(ref $it1, "Triceps::IndexType");
$res = $it1->print();
ok($res, "index FifoIndex( reverse)");

@key = $it1->getKey();
ok($#key, -1);

$it1 = eval { Triceps::IndexType->newFifo("key"); };
ok(!defined($it1));
ok($@, qr/^Usage: Triceps::IndexType::newFifo\(CLASS, optionName, optionValue, ...\), option names and values must go in pairs at/);

$it1 = eval { Triceps::IndexType->newFifo(zzz => [ "a", "b" ]); };
ok(!defined($it1));
ok($@, qr/^Triceps::IndexType::newFifo: unknown option 'zzz' at/);

###################### equality #################################

$it1 = Triceps::IndexType->newHashed(key => [ "a", "b" ]);
ok(ref $it1, "Triceps::IndexType");
$res = $it1->getIndexId();
ok($res, &Triceps::IT_HASHED);

# uninitializedness of copies tested in Table.t
$it2 = $it1->copy();
ok(ref $it2, "Triceps::IndexType");
$res = $it1->equals($it2);
ok($res, 1);

$it3 = Triceps::IndexType->newHashed(key => [ "c", "d" ]);
ok(ref $it3, "Triceps::IndexType");
$it4 = Triceps::IndexType->newHashed(key => [ "e" ]);
ok(ref $it4, "Triceps::IndexType");
$it5 = Triceps::IndexType->newFifo();
ok(ref $it5, "Triceps::IndexType");
$res = $it5->getIndexId();
ok($res, &Triceps::IT_FIFO);

$res = $it1->equals($it2);
ok($res, 1);
$res = $it1->same($it2);
ok($res, 0);
$res = $it1->equals($it3);
ok($res, 0);
$res = $it1->equals($it4);
ok($res, 0);
$res = $it1->equals($it5);
ok($res, 0);

$res = $it1->match($it2);
ok($res, 1);
$res = $it1->match($it3);
ok($res, 0);
$res = $it1->match($it4);
ok($res, 0);
$res = $it1->match($it5);
ok($res, 0);

# hashed index checks the match with the rowtype translation
# if initialized
{
	my $xrt1 = Triceps::RowType->new(
		a => int32,
		b => int64,
	);
	ok(ref $xrt1, "Triceps::RowType");
	my $xrt2 = Triceps::RowType->new(
		d => int32,
		c => int64,
	);
	ok(ref $xrt2, "Triceps::RowType");
	# fits the difference between $it1 and $it3
	my $xrt3 = Triceps::RowType->new(
		c => int32,
		d => int64,
	);
	ok(ref $xrt3, "Triceps::RowType");

	my $xtt1 = Triceps::TableType->new($xrt1)->addSubIndex("primary", $it1);
	ok(ref $xtt1, "Triceps::TableType");
	ok($xtt1->initialize());
	my $xit1 = $xtt1->findSubIndex("primary");
	# $it3 ends up having the fields in an opposite order in $xtt2
	my $xtt2 = Triceps::TableType->new($xrt2)->addSubIndex("secondary", $it3);
	ok(ref $xtt2, "Triceps::TableType");
	ok($xtt2->initialize());
	my $xit2 = $xtt2->findSubIndex("secondary");
	# here the row type and index key result in the same order
	my $xtt3 = Triceps::TableType->new($xrt3)->addSubIndex("tertiary", $it3);
	ok(ref $xtt3, "Triceps::TableType");
	ok($xtt3->initialize());
	my $xit3 = $xtt3->findSubIndex("tertiary");

	ok($it1->equals($xit1));
	ok($it1->match($xit1));

	ok($it3->equals($xit2));
	ok($it3->match($xit2));
	ok($it3->equals($xit3));
	ok($it3->match($xit3));

	ok(!$xit1->equals($xit3));
	ok($xit1->match($xit3)); # after initialization the translation matches

	ok(!$xit1->equals($xit2));
	ok(!$xit1->match($xit2));

	ok(!$xit3->equals($xit2));
	ok(!$xit3->match($xit2));

	ok(!$xtt1->match($xtt2));
	ok($xtt1->match($xtt3));
}

###################### nested #################################

# reuse $it1..$it5 from the last tests, modify them

@res = $it2->getSubIndexes();
ok($#res, -1);

$it21 = $it2->addSubIndex(level2 => $it3->addSubIndex(level3 => $it5));
ok(ref $it21, "Triceps::IndexType");
$res = $it2->same($it21);
ok($res, 1);
$res = $it1->equals($it2);
ok($res, 0);
$res = $it1->match($it2);
ok($res, 0);
$res = $it2->print();
ok($res, "index HashedIndex(a, b, ) {\n  index HashedIndex(c, d, ) {\n    index FifoIndex() level3,\n  } level2,\n}");

my $flat2 = $it2->flatCopy();
ok(ref $flat2, "Triceps::IndexType");
ok($flat2->isLeaf());

@res = $it2->getSubIndexes();
ok($#res, 1);
ok($res[0], "level2");
ok(ref $res[1], "Triceps::IndexType");
$res = $it3->equals($res[1]);
ok($res, 1);

$it21 = $it2->addSubIndex(order => $it5);
ok(ref $it21, "Triceps::IndexType");
@res = $it2->getSubIndexes();
ok($#res, 3);
ok($res[0], "level2");
ok(ref $res[1], "Triceps::IndexType");
$res = $it3->equals($res[1]);
ok($res, 1);
ok($res[2], "order");
ok(ref $res[3], "Triceps::IndexType");
$res = $it5->equals($res[3]);
ok($res, 1);

$res = $it1->isLeaf();
ok($res, 1);
$res = $it2->isLeaf();
ok($res, 0);
$res = $it3->isLeaf(); 
ok($res, 0);

$it21 = $it2->findSubIndex("level2");
ok(ref $it21, "Triceps::IndexType");
$res = $it21->equals($it3); # equals but not the same, because the indexes get copied!
ok($res, 1);
$it22 = $it2->findSubIndex("level2");
$res = $it21->same($it22);
ok($res, 1);

$res = eval { $it2->findSubIndex("xxx"); };
ok(!defined($res));
ok($@, qr/^Triceps::IndexType::findSubIndex: unknown nested index 'xxx' at/);

$res = $it2->findSubIndexSafe("xxx");
ok(!defined($res));

$it6 = $it2->findSubIndex("level2")->findSubIndex("level3");
ok(ref $it6, "Triceps::IndexType");
$res = $it6->equals($it5);
ok($res, 1);
$res = $it6->print();
ok($res, "index FifoIndex()");

$it6 = $it3->findSubIndexById("IT_FIFO");
ok(ref $it6, "Triceps::IndexType");
$res = $it6->equals($it5);
ok($res, 1);

$it6 = $it3->findSubIndexById(&Triceps::IT_FIFO);
ok(ref $it6, "Triceps::IndexType");
$res = $it6->equals($it5);
ok($res, 1);

$it6 = eval { $it3->findSubIndexById(&Triceps::IT_ROOT); };
ok(!defined $it6);
ok($@, qr/^Triceps::IndexType::findSubIndexById: no nested index with type id 'IT_ROOT' \(0\) at/);

$it6 = eval { $it3->findSubIndexById(999); };
ok(!defined $it6);
ok($@, qr/^Triceps::IndexType::findSubIndexById: no nested index with type id '\?\?\?' \(999\) at/);

$it6 = eval { $it3->findSubIndexById("xxx"); };
ok(!defined $it6);
ok($@, qr/^Triceps::IndexType::findSubIndexById: unknown IndexId string 'xxx', if integer was meant, it has to be cast at/);

$it6 = $it2->getFirstLeaf();
ok(ref $it6, "Triceps::IndexType");
$res = $it6->equals($it5);

$it6 = $it5->getFirstLeaf();
ok(ref $it6, "Triceps::IndexType");
$res = $it6->equals($it5);

###################### other small stuff #################################

$res = $it2->isInitialized();
ok($res, 0);

###################### setting aggregator #################################

@def1 = (
	a => "uint8",
	b => "int32",
	c => "int64",
	d => "float64",
	e => "string",
);
$rt1 = Triceps::RowType->new( # used later
	@def1
);
ok(ref $rt1, "Triceps::RowType");

$res = $it1->getAggregator();
ok(!defined $res);

$agt1 = Triceps::AggregatorType->new($rt1, "agg", undef, sub { 0; } );
ok(ref $agt1, "Triceps::AggregatorType");

$res = $it1->setAggregator($agt1);
ok(ref $res, "Triceps::IndexType");
ok($it1->same($res));

$res = $it1->getAggregator();
ok(ref $res, "Triceps::AggregatorType"); 
ok($agt1->equals($res)); # can not check for sameness because it's a copy
$res2 = $it1->getAggregator();
ok($res->same($res2)); # each time returns a new reference to the same object

$res = $it1->print();
ok($res, "index HashedIndex(a, b, ) {\n  aggregator (\n    row {\n      uint8 a,\n      int32 b,\n      int64 c,\n      float64 d,\n      string e,\n    }\n  ) agg\n}");
$res = $it1->print(undef);
ok($res, "index HashedIndex(a, b, ) { aggregator ( row { uint8 a, int32 b, int64 c, float64 d, string e, } ) agg }");
