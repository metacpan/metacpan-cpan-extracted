#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The test for PerlSortedIndexType.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 174 };
use Triceps;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#########################
# common definitions

$u1 = Triceps::Unit->new("u1");
ok(ref $u1, "Triceps::Unit");

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

#########################
# basic functions: sameness etc

sub f1 { return 0; }
sub f2 { return 0; }
sub f3 { return 0; }

{
	my $it1 = Triceps::IndexType->newPerlSorted("sort", \&f1, \&f2);
	ok(ref $it1, "Triceps::IndexType");
	ok($it1->same($it1));
	ok($it1->equals($it1));
	ok($it1->match($it1));

	my $it2 = Triceps::IndexType->newPerlSorted("sort2", \&f1, \&f2); # different name
	ok(ref $it2, "Triceps::IndexType");
	ok(!$it1->same($it2));
	ok(!$it1->equals($it2));
	ok($it1->match($it2));

	my $it3 = Triceps::IndexType->newPerlSorted("sort", \&f1, \&f2, "a"); # extra arg
	ok(ref $it3, "Triceps::IndexType");
	ok(!$it1->equals($it3));
	ok(!$it1->match($it3));

	my $it4 = Triceps::IndexType->newPerlSorted("sort", \&f1, undef); # diff compare
	ok(ref $it4, "Triceps::IndexType");
	ok(!$it1->equals($it4));
	ok(!$it1->match($it4));

	my $it5 = Triceps::IndexType->newPerlSorted("sort", undef, \&f2); # diff init
	ok(ref $it5, "Triceps::IndexType");
	ok(!$it1->equals($it5));
	ok(!$it1->match($it5));

	my $it6 = $it1->copy(); # copy
	ok(ref $it6, "Triceps::IndexType");
	ok(!$it1->same($it6));
	ok($it1->equals($it6));
	ok($it1->match($it6));

	my $it7 = Triceps::IndexType->newPerlSorted("sort", \&f2, \&f1); # diff functions
	ok(ref $it7, "Triceps::IndexType");
	ok(!$it1->same($it7));
	ok(!$it1->equals($it7));
	ok(!$it1->match($it7));

	my @keys = $it1->getKey();
	ok($#keys, -1);
}

#########################
# with no initializer, only comparator

$it1 = Triceps::IndexType->newPerlSorted("basic", undef, sub {
	#print STDERR "comparing\n";
	#print STDERR "      ", $_[0]->printP(), "\n";
	#print STDERR "      ", $_[1]->printP(), "\n";
	my $res = ($_[0]->get("b") <=> $_[1]->get("b")
		|| $_[0]->get("c") <=> $_[1]->get("c"));
	#print STDERR "      result $res\n";
	return $res;
});
ok(ref $it1, "Triceps::IndexType");
$res = $it1->print();
ok($res, "index PerlSortedIndex(basic)");

{
	my $tt1 = Triceps::TableType->new($rt1)
		->addSubIndex("primary", $it1)
	;
	ok(ref $tt1, "Triceps::TableType");

	$res = $tt1->print();
	ok($res, "table (\n  row {\n    uint8 a,\n    int32 b,\n    int64 c,\n    float64 d,\n    string e,\n  }\n) {\n  index PerlSortedIndex(basic) primary,\n}");

	$res = $tt1->initialize();
	ok($res, 1);

	my $t1 = $u1->makeTable($tt1, "t1");
	ok(ref $t1, "Triceps::Table");

	# insert rows in a backwards order
	my $r11 = $rt1->makeRowHash(b => 1, c => 1);
	my $r12 = $rt1->makeRowHash(b => 1, c => 2);
	my $r21 = $rt1->makeRowHash(b => 2, c => 1);
	my $r22 = $rt1->makeRowHash(b => 2, c => 2);

	ok($res = $t1->insert($r22));
	ok($res = $t1->insert($r21));
	ok($res = $t1->insert($r12));
	ok($res = $t1->insert($r11));

	# iterate, they should come in the sorted order
	$iter = $t1->begin();
	ok($r11->same($iter->getRow()));
	$iter = $iter->next();
	ok($r12->same($iter->getRow()));
	$iter = $iter->next();
	ok($r21->same($iter->getRow()));
	$iter = $iter->next();
	ok($r22->same($iter->getRow()));
	$iter = $iter->next();
	ok($iter->isNull());

	# do a successful find
	$iter = $t1->find($rt1->makeRowHash(b => 1, c => 2));
	ok($r12->same($iter->getRow()));

	# do an unsuccessful find
	$iter = $t1->find($rt1->makeRowHash(b => 1, c => 3));
	ok($iter->isNull());
};

#########################
# with no initializer, only comparator
# and comparator is specified as source code

$itsrc1 = Triceps::IndexType->newPerlSorted("basic", undef, '
	#print STDERR "comparing\n";
	#print STDERR "      ", $_[0]->printP(), "\n";
	#print STDERR "      ", $_[1]->printP(), "\n";
	my $res = ($_[0]->get("b") <=> $_[1]->get("b")
		|| $_[0]->get("c") <=> $_[1]->get("c"));
	#print STDERR "      result $res\n";
	return $res;
	'
);
ok(ref $itsrc1, "Triceps::IndexType");
$res = $itsrc1->print();
ok($res, "index PerlSortedIndex(basic)");

{
	my $tt1 = Triceps::TableType->new($rt1)
		->addSubIndex("primary", $itsrc1)
	;
	ok(ref $tt1, "Triceps::TableType");

	$res = $tt1->print();
	ok($res, "table (\n  row {\n    uint8 a,\n    int32 b,\n    int64 c,\n    float64 d,\n    string e,\n  }\n) {\n  index PerlSortedIndex(basic) primary,\n}");

	$res = $tt1->initialize();
	ok($res, 1);

	my $t1 = $u1->makeTable($tt1, "t1");
	ok(ref $t1, "Triceps::Table");

	# insert rows in a backwards order
	my $r11 = $rt1->makeRowHash(b => 1, c => 1);
	my $r12 = $rt1->makeRowHash(b => 1, c => 2);
	my $r21 = $rt1->makeRowHash(b => 2, c => 1);
	my $r22 = $rt1->makeRowHash(b => 2, c => 2);

	ok($res = $t1->insert($r22));
	ok($res = $t1->insert($r21));
	ok($res = $t1->insert($r12));
	ok($res = $t1->insert($r11));

	# iterate, they should come in the sorted order
	$iter = $t1->begin();
	ok($r11->same($iter->getRow()));
	$iter = $iter->next();
	ok($r12->same($iter->getRow()));
	$iter = $iter->next();
	ok($r21->same($iter->getRow()));
	$iter = $iter->next();
	ok($r22->same($iter->getRow()));
	$iter = $iter->next();
	ok($iter->isNull());

	# do a successful find
	$iter = $t1->find($rt1->makeRowHash(b => 1, c => 2));
	ok($r12->same($iter->getRow()));

	# do an unsuccessful find
	$iter = $t1->find($rt1->makeRowHash(b => 1, c => 3));
	ok($iter->isNull());
};

#########################
# with no initializer, only comparator, nested index,
# also test the copying

{
	# add a sub-index to the copy
	my $it2 = $it1->copy();
	$it2->addSubIndex("leaf", Triceps::IndexType->newFifo());

	my $tt1 = Triceps::TableType->new($rt1)
		->addSubIndex("primary", $it2)
	;
	ok(ref $tt1, "Triceps::TableType");

	$res = $tt1->initialize();
	ok($res, 1);

	# get back the copied object from the table type
	$it2 = $tt1->findSubIndex("primary");
	ok(ref $it2, "Triceps::IndexType");
	my $it3 = $it2->findSubIndex("leaf");
	ok(ref $it3, "Triceps::IndexType");

	{
		my $flat2 = $it2->flatCopy();
		ok(ref $flat2, "Triceps::IndexType");
		ok($flat2->isLeaf());
	}
	
	my $t1 = $u1->makeTable($tt1, "t1");
	ok(ref $t1, "Triceps::Table");

	# insert rows in a backwards order, with multiple copies of some
	my $r11 = $rt1->makeRowHash(b => 1, c => 1);
	my $r12 = $rt1->makeRowHash(b => 1, c => 2);
	my $r21 = $rt1->makeRowHash(b => 2, c => 1);
	my $r22 = $rt1->makeRowHash(b => 2, c => 2);

	ok($res = $t1->insert($r22));

	ok($res = $t1->insert($r21));
	ok($res = $t1->insert($r21));
	ok($res = $t1->insert($r21));

	ok($res = $t1->insert($r12));
	ok($res = $t1->insert($r11));

	# iterate, they should come in the sorted order
	$iter = $t1->begin();
	ok($r11->same($iter->getRow()));
	$iter = $iter->next();
	ok($r12->same($iter->getRow()));

	$iter = $iter->next();
	ok($r21->same($iter->getRow()));
	$iter = $iter->next();
	ok($r21->same($iter->getRow()));
	$iter = $iter->next();
	ok($r21->same($iter->getRow()));

	$iter = $iter->next();
	ok($r22->same($iter->getRow()));
	$iter = $iter->next();
	ok($iter->isNull());

	# do a successful find of group
	$iter = $t1->findIdx($it2, $rt1->makeRowHash(b => 2, c => 1));
	ok($r21->same($iter->getRow()));
	$iter2 = $iter->nextGroupIdx($it3);
	ok($r22->same($iter2->getRow()));

	# do an unsuccessful find of group
	$iter = $t1->findIdx($it2, $rt1->makeRowHash(b => 1, c => 3));
	ok($iter->isNull());
};

#########################
# test the catching of errors in comparator
# with no initializer, only comparator

# @param comp - the comparator function
# @return - a pair of error messages from two attempts to insert
sub testCompError # ($&comp)
{
	my $comp = shift; # pointer to the actual comparator
	my $it3 = Triceps::IndexType->newPerlSorted("bad", undef, $comp);
	ok(ref $it1, "Triceps::IndexType");

	$tt1 = Triceps::TableType->new($rt1)
		->addSubIndex("primary", $it3)
	;
	ok(ref $tt1, "Triceps::TableType");

	$res = $tt1->initialize();
	ok($res, 1);

	my $t1 = $u1->makeTable($tt1, "t1");
	ok(ref $t1, "Triceps::Table");

	my $r11 = $rt1->makeRowHash(b => 1, c => 1);
	my $r12 = $rt1->makeRowHash(b => 1, c => 2);

	# inserting the 1st row doesn't trigger a comparator
	ok($res = $t1->insert($r12));
	# insert 2nd row, to trigger the error messages

	eval { $t1->insert($r11); };
	my $msg1 = $@;
	eval { $t1->insert($r11); };
	my $msg2 = $@;
	return ($msg1, $msg2);
}

# test the errors
{
	# an outright death in comparator
	($res1, $res2) = testCompError(sub {
		die "test a death in PerlSortedIndex comparator\n";
	});
	ok($res1, qr/^Error in PerlSortedIndex\(bad\) comparator: test a death in PerlSortedIndex comparator/);
	ok($res2, qr/^Table is disabled due to the previous error:\n  Error in PerlSortedIndex\(bad\) comparator: test a death in PerlSortedIndex comparator/);

	# a string return value in comparator
	($res1, $res2) = testCompError(sub {
		return "zzz";
	});
	ok($res1, qr/^Error in PerlSortedIndex\(bad\) comparator: comparator returned a non-integer value/);
	ok($res2, qr/^Table is disabled due to the previous error:\n  Error in PerlSortedIndex\(bad\) comparator: comparator returned a non-integer value/);
};

#########################
# with only comparator and args

{
	# same as before but pass the field names as args
	my $it2 = Triceps::IndexType->newPerlSorted("withArgs", undef, sub {
		my $res = ($_[0]->get($_[2]) <=> $_[1]->get($_[2])
			|| $_[0]->get($_[3]) <=> $_[1]->get($_[3]));
		return $res;
	}, "b", "c");
	ok(ref $it2, "Triceps::IndexType");

	my $tt1 = Triceps::TableType->new($rt1)
		->addSubIndex("primary", $it2)
	;
	ok(ref $tt1, "Triceps::TableType");

	$res = $tt1->initialize();
	ok($res, 1);

	my $t1 = $u1->makeTable($tt1, "t1");
	ok(ref $t1, "Triceps::Table");

	# insert rows in a backwards order
	my $r11 = $rt1->makeRowHash(b => 1, c => 1);
	my $r12 = $rt1->makeRowHash(b => 1, c => 2);
	my $r21 = $rt1->makeRowHash(b => 2, c => 1);
	my $r22 = $rt1->makeRowHash(b => 2, c => 2);

	ok($res = $t1->insert($r22));
	ok($res = $t1->insert($r21));
	ok($res = $t1->insert($r12));
	ok($res = $t1->insert($r11));

	# iterate, they should come in the sorted order
	$iter = $t1->begin();
	ok($r11->same($iter->getRow()));
	$iter = $iter->next();
	ok($r12->same($iter->getRow()));
	$iter = $iter->next();
	ok($r21->same($iter->getRow()));
	$iter = $iter->next();
	ok($r22->same($iter->getRow()));
	$iter = $iter->next();
	ok($iter->isNull());

	# do a successful find
	$iter = $t1->find($rt1->makeRowHash(b => 1, c => 2));
	ok($r12->same($iter->getRow()));

	# do an unsuccessful find
	$iter = $t1->find($rt1->makeRowHash(b => 1, c => 3));
	ok($iter->isNull());
};

#########################
# with initializer

sub compareByFields # (r1, r2, fld1, fld2)
{
	my $res = ($_[0]->get($_[2]) <=> $_[1]->get($_[2])
		|| $_[0]->get($_[3]) <=> $_[1]->get($_[3]));
	return $res;
}

our $result;

sub setComparator # (tabt, idxt, rowt,  comparator, cmpargs...)
{
	my ($tabt, $idxt, $rowt, @comp) = @_;
	$result .= $tabt->print();
	$result .= "\n";
	$result .= $idxt->print();
	$result .= "\n";
	$result .= $rowt->print();
	$result .= "\n";
	$idxt->setComparator(@comp);
	return undef; # success
}

{
	my $it2 = Triceps::IndexType->newPerlSorted("withInit", \&setComparator, undef, 
		\&compareByFields, "b", "c");
	ok(ref $it2, "Triceps::IndexType");

	my $tt1 = Triceps::TableType->new($rt1)
		->addSubIndex("primary", $it2)
	;
	ok(ref $tt1, "Triceps::TableType");

	undef $result;
	$res = $tt1->initialize();
	ok($res, 1);
	#print STDERR $result;
	ok($result, 
'table (
  row {
    uint8 a,
    int32 b,
    int64 c,
    float64 d,
    string e,
  }
) {
  index PerlSortedIndex(withInit) primary,
}
index PerlSortedIndex(withInit)
row {
  uint8 a,
  int32 b,
  int64 c,
  float64 d,
  string e,
}
');

	# try to set the comparator again, after initialization
	$it2 = $tt1->findSubIndex("primary");
	ok(ref $it2, "Triceps::IndexType");
	$res = eval { $it2->setComparator(\&compareByFields); };
	ok(!defined $res);
	ok($@, qr/^Triceps::IndexType::setComparator: this index type is already initialized and can not be changed at/);

	my $t1 = $u1->makeTable($tt1, "t1");
	ok(ref $t1, "Triceps::Table");

	# insert rows in a backwards order
	my $r11 = $rt1->makeRowHash(b => 1, c => 1);
	my $r12 = $rt1->makeRowHash(b => 1, c => 2);
	my $r21 = $rt1->makeRowHash(b => 2, c => 1);
	my $r22 = $rt1->makeRowHash(b => 2, c => 2);

	ok($res = $t1->insert($r22));
	ok($res = $t1->insert($r21));
	ok($res = $t1->insert($r12));
	ok($res = $t1->insert($r11));

	# iterate, they should come in the sorted order
	$iter = $t1->begin();
	ok($r11->same($iter->getRow()));
	$iter = $iter->next();
	ok($r12->same($iter->getRow()));
	$iter = $iter->next();
	ok($r21->same($iter->getRow()));
	$iter = $iter->next();
	ok($r22->same($iter->getRow()));
	$iter = $iter->next();
	ok($iter->isNull());
};

#########################
# with initializer as a source code

undef $result;

{
	# the same code as in the last example, only now as source code
	my $it2 = Triceps::IndexType->newPerlSorted("withInit", '
		our $result;
		my ($tabt, $idxt, $rowt, @comp) = @_;
		$result .= $tabt->print();
		$result .= "\n";
		$result .= $idxt->print();
		$result .= "\n";
		$result .= $rowt->print();
		$result .= "\n";
		$idxt->setComparator(@comp);
		return undef; # success
	', undef, '
		my $res = ($_[0]->get($_[2]) <=> $_[1]->get($_[2])
			|| $_[0]->get($_[3]) <=> $_[1]->get($_[3]));
		return $res;
	', "b", "c");
	ok(ref $it2, "Triceps::IndexType");

	my $tt1 = Triceps::TableType->new($rt1)
		->addSubIndex("primary", $it2)
	;
	ok(ref $tt1, "Triceps::TableType");

	undef $result;
	$res = $tt1->initialize();
	ok($res, 1);
	#print STDERR $result;
	ok($result, 
'table (
  row {
    uint8 a,
    int32 b,
    int64 c,
    float64 d,
    string e,
  }
) {
  index PerlSortedIndex(withInit) primary,
}
index PerlSortedIndex(withInit)
row {
  uint8 a,
  int32 b,
  int64 c,
  float64 d,
  string e,
}
');

	# try to set the comparator again, after initialization
	$it2 = $tt1->findSubIndex("primary");
	ok(ref $it2, "Triceps::IndexType");
	$res = eval { $it2->setComparator(\&compareByFields); };
	ok(!defined $res);
	ok($@, qr/^Triceps::IndexType::setComparator: this index type is already initialized and can not be changed at/);

	my $t1 = $u1->makeTable($tt1, "t1");
	ok(ref $t1, "Triceps::Table");

	# insert rows in a backwards order
	my $r11 = $rt1->makeRowHash(b => 1, c => 1);
	my $r12 = $rt1->makeRowHash(b => 1, c => 2);
	my $r21 = $rt1->makeRowHash(b => 2, c => 1);
	my $r22 = $rt1->makeRowHash(b => 2, c => 2);

	ok($res = $t1->insert($r22));
	ok($res = $t1->insert($r21));
	ok($res = $t1->insert($r12));
	ok($res = $t1->insert($r11));

	# iterate, they should come in the sorted order
	$iter = $t1->begin();
	ok($r11->same($iter->getRow()));
	$iter = $iter->next();
	ok($r12->same($iter->getRow()));
	$iter = $iter->next();
	ok($r21->same($iter->getRow()));
	$iter = $iter->next();
	ok($r22->same($iter->getRow()));
	$iter = $iter->next();
	ok($iter->isNull());
};

#########################
# errors in initializer

sub errorOnInit # (tabt, idxt, rowt,  comparator, cmpargs...)
{
	return "initializer found an error!\nerror line 2";
}

sub dieOnInit # (tabt, idxt, rowt,  comparator, cmpargs...)
{
	die "initializer died!\n";
}

sub noComparator # (tabt, idxt, rowt,  comparator, cmpargs...)
{
	return undef; # success but did not set the comparator
}

{
	my $it2 = Triceps::IndexType->newPerlSorted("badInit", \&errorOnInit, undef);
	ok(ref $it2, "Triceps::IndexType");

	my $tt1 = Triceps::TableType->new($rt1)
		->addSubIndex("primary", $it2)
	;
	ok(ref $tt1, "Triceps::TableType");

	undef $result;
	$res = eval { $tt1->initialize(); };
	ok(!defined $res);
	ok($@, 
qr/^index error:
  nested index 1 'primary':
    initializer found an error!
    error line 2 at/);
}

{
	my $it2 = Triceps::IndexType->newPerlSorted("badInit", \&dieOnInit, undef);
	ok(ref $it2, "Triceps::IndexType");

	my $tt1 = Triceps::TableType->new($rt1)
		->addSubIndex("primary", $it2)
	;
	ok(ref $tt1, "Triceps::TableType");

	undef $result;
	$res = eval { $tt1->initialize(); };
	ok(!defined $res);
	ok($@, 
qr/^index error:
  nested index 1 'primary':
    initializer died! at/);
}

{
	my $it2 = Triceps::IndexType->newPerlSorted("badInit", \&noComparator, undef);
	ok(ref $it2, "Triceps::IndexType");

	my $tt1 = Triceps::TableType->new($rt1)
		->addSubIndex("primary", $it2)
	;
	ok(ref $tt1, "Triceps::TableType");

	undef $result;
	$res = eval { $tt1->initialize(); };
	ok(!defined $res);
	ok($@, 
qr/^index error:
  nested index 1 'primary':
    the mandatory comparator Perl function is not set by PerlSortedIndex\(badInit\) at/);
}

#########################
# errors in compilation of source code

{
	my $it2 = eval { Triceps::IndexType->newPerlSorted("badInit", '$zz++;', undef); };
	ok(!defined $it2);
	ok($@, 
qr/^Triceps::IndexType::newPerlSorted\(initialize\): failed to compile the source code
Compilation error: Global symbol \"\$zz\" requires explicit package name .*
The source code was:
  sub {
  \$zz\+\+;
  } at/);
}

{
	my $it2 = eval { Triceps::IndexType->newPerlSorted("badInit", undef, '$zz++;'); };
	ok(!defined $it2);
	ok($@, 
qr/^Triceps::IndexType::newPerlSorted\(compare\): failed to compile the source code
Compilation error: Global symbol \"\$zz\" requires explicit package name .*
The source code was:
  sub {
  \$zz\+\+;
  } at/);
}

{
	my $it2 = Triceps::IndexType->newPerlSorted("badInit", ' ', undef);
	ok(ref $it2, "Triceps::IndexType");

	ok(!defined eval { $it2->setComparator('$zz++;') });
	ok($@, 
qr/^Triceps::IndexType::setComparator: failed to compile the source code
Compilation error: Global symbol \"\$zz\" requires explicit package name .*
The source code was:
  sub {
  \$zz\+\+;
  } at/);
}

#########################
# both callbacks as undefs

{
	my $it2 = eval { Triceps::IndexType->newPerlSorted("badInit", undef, undef, "a"); };
	ok(!defined $it2);
	ok($@, qr/^Triceps::IndexType::newPerlSorted: at least one of init and comparator function arguments must be not undef at/);
}

#########################
# non-function as a callback

{
	my $it2;
	$it2 = eval { Triceps::IndexType->newPerlSorted("badInit", 1, undef, "a"); };
	ok(!defined $it2);
	ok($@, qr/^Triceps::IndexType::newPerlSorted\(initialize\): code must be a source code string or a reference to Perl function at/);

	$it2 = eval { Triceps::IndexType->newPerlSorted("badInit", undef, 1, "a"); };
	ok(!defined $it2);
	ok($@, qr/^Triceps::IndexType::newPerlSorted\(compare\): code must be a source code string or a reference to Perl function at/);
}
