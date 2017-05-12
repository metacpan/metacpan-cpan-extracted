#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# A test of join between two tables.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 173 };
use Triceps;
use Carp;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# (continues the discussion from LookupJoin)
############################# helper functions ###########################

# helper function to feed the input data to a label
sub feedInput # ($label, $opcode, @$dataArray)
{
	my ($label, $opcode, $dataArray) = @_;
	my $unit = $label->getUnit();
	my $rt = $label->getType();
	foreach my $tuple (@$dataArray) {
		# print STDERR "feed [" . join(", ", @$tuple) . "]\n";
		my $rowop = $label->makeRowop($opcode, $rt->makeRowArray(@$tuple));
		$unit->schedule($rowop);
	}
}

# convert a data set to a string
sub dataToString # (@dataSet)
{
	my $res;
	foreach my $tuple (@_) {
		$res .= "(" . join(", ", @$tuple) . ")\n";
	}
	return $res;
}

############################# accounts table definition ###########################
# (copied from LookupJoin.t)

# look-up data
@defAccounts = ( # account translation map
	source => "string", # external system that sent us a transaction
	external => "string", # its name of the account of the transaction
	internal => "int32", # our internal account id
);
$rtAccounts = Triceps::RowType->new(
	@defAccounts
);
ok(ref $rtAccounts, "Triceps::RowType");
	
# the accounts table
$ttAccounts = Triceps::TableType->new($rtAccounts)
	# muliple indexes can be defined for different purposes
	# (though of course each extra index adds overhead)
	->addSubIndex("lookupSrcExt", # quick look-up by source and external id
		Triceps::IndexType->newHashed(key => [ "source", "external" ])
	)
	->addSubIndex("iterateSrc", # for iteration in order grouped by source
		Triceps::IndexType->newHashed(key => [ "source" ])
		->addSubIndex("iterateSrcExt", 
			Triceps::IndexType->newHashed(key => [ "external" ])
		)
	)
	->addSubIndex("lookupIntGroup", # quick look-up by internal id (to multiple externals)
		Triceps::IndexType->newHashed(key => [ "internal" ])
		->addSubIndex("lookupInt", Triceps::IndexType->newFifo())
	)
; 
ok(ref $ttAccounts, "Triceps::TableType");
# remember the index for quick lookup
$idxAccountsLookup = $ttAccounts->findSubIndex("lookupSrcExt");
ok(ref $idxAccountsLookup, "Triceps::IndexType");

$res = $ttAccounts->initialize();
ok($res, 1);

# the accounts table with duplicates
$ttAccountsDup = Triceps::TableType->new($rtAccounts)
	->addSubIndex("lookupSrcExt", # quick look-up by source and external id
		Triceps::IndexType->newHashed(key => [ "source", "external" ])
		# this works for the default lookups because the data will be the exact duplicates!
		->addSubIndex("dup", Triceps::IndexType->newFifo())
	)
; 
ok(ref $ttAccountsDup, "Triceps::TableType");
$res = $ttAccountsDup->initialize();
ok($res, 1);

#######################################################################
# 3. A table-to-table join.
# It's the next step of complexity that still has serious limitations:
# joining only two tables, and no self-joins.
# It's implemented in a simple way by tying together 2 LookupJoins.

# This will work by producing multiple join results in parallel.
# There are 2 pairs of tables (an account table and 2 separate transaction tables),
# with assorted joins defined on them. As the data is fed to the tables, all
# joins generate and record the results.

$vu3 = Triceps::Unit->new("vu3");
ok(ref $vu3, "Triceps::Unit");

# this will record the results, per case
my %result;

# the accounts table type is also reused from example (1)
$tAccounts3 = $vu3->makeTable($ttAccounts, "Accounts");
ok(ref $tAccounts3, "Triceps::Table");

$tAccounts3dup = $vu3->makeTable($ttAccountsDup, "Accounts");
ok(ref $tAccounts3dup, "Triceps::Table");

# add a chance to act betfore the account table gets modified, for self-join
$beforeAcct3 = $vu3->makeDummyLabel($ttAccounts->rowType(), "beforeAcct3");
ok(ref $beforeAcct3, "Triceps::Label");

$inacct3 = $vu3->makeDummyLabel($ttAccounts->rowType(), "inacct3");
ok(ref $inacct3, "Triceps::Label");

$inacct3->chain($beforeAcct3);
$inacct3->chain($tAccounts3->getInputLabel());

# duplicate the rows for the accounts-dup

my $inacctDup = $vu3->makeLabel($tAccounts3->getRowType(), "inacctDup", undef, sub { 
	my $newrop = $tAccounts3dup->getInputLabel()->adopt($_[1]);
	$vu3->call($newrop);
	$vu3->call($newrop);
});
ok(ref $inacctDup, "Triceps::Label");
$inacct3->chain($inacctDup);

# the incoming transactions table here adds an extra id field
@defTrans3 = ( # a transaction received
	id => "int32", # transaction id
	acctSrc => "string", # external system that sent us a transaction
	acctXtrId => "string", # its name of the account of the transaction
	amount => "int32", # the amount of transaction (int is easier to check)
);
$rtTrans3 = Triceps::RowType->new(
	@defTrans3
);
ok(ref $rtTrans3, "Triceps::RowType");

# the "honest" transaction table
$ttTrans3 = Triceps::TableType->new($rtTrans3)
	# muliple indexes can be defined for different purposes
	# (though of course each extra index adds overhead)
	->addSubIndex("primary", 
		Triceps::IndexType->newHashed(key => [ "id" ])
	)
	->addSubIndex("byAccount", # for joining by account info
		Triceps::IndexType->newHashed(key => [ "acctSrc", "acctXtrId" ])
		->addSubIndex("data", Triceps::IndexType->newFifo())
	)
	->addSubIndex("byAccountBackwards", # for joining by account info
		Triceps::IndexType->newHashed(key => [ "acctXtrId", "acctSrc", ])
		->addSubIndex("data", Triceps::IndexType->newFifo())
	)
; 
ok(ref $ttTrans3, "Triceps::TableType");
ok($ttTrans3->initialize());
$tTrans3 = $vu3->makeTable($ttTrans3, "Trans");
ok(ref $tTrans3, "Triceps::Table");
$intrans3 = $tTrans3->getInputLabel();
ok(ref $intrans3, "Triceps::Label");

# the transaction table that has the join index as the primary key,
# as a hypothetical case that allows to test the logic dependent on it
$ttTrans3p = Triceps::TableType->new($rtTrans3)
	->addSubIndex("byAccount", # for joining by account info
		Triceps::IndexType->newHashed(key => [ "acctSrc", "acctXtrId" ])
	)
; 
ok(ref $ttTrans3p, "Triceps::TableType");
ok($ttTrans3p->initialize());
$tTrans3p = $vu3->makeTable($ttTrans3p, "Trans");
ok(ref $tTrans3p, "Triceps::Table");
$intrans3p = $tTrans3p->getInputLabel();
ok(ref $intrans3p, "Triceps::Label");

# a common label for feeding input data for both transaction tables
$labtrans3 = $vu3->makeDummyLabel($rtTrans3, "input3");
ok(ref $labtrans3, "Triceps::Label");
$labtrans3->chain($intrans3);
$labtrans3->chain($intrans3p);

# for debugging, collect the table results
my $res_acct;
my $labAccounts3 = $vu3->makeLabel($tAccounts3->getRowType(), "labAccounts3", undef, sub { $res_acct .= $_[1]->printP() . "\n" } );
ok(ref $labAccounts3, "Triceps::Label");
$tAccounts3->getOutputLabel()->chain($labAccounts3);

my $res_acct_dup;
my $labAccounts3dup = $vu3->makeLabel($tAccounts3->getRowType(), "labAccounts3dup", undef, sub { $res_acct_dup .= $_[1]->printP() . "\n" } );
ok(ref $labAccounts3dup, "Triceps::Label");
$tAccounts3dup->getOutputLabel()->chain($labAccounts3dup);

my $res_trans;
my $labTrans3 = $vu3->makeLabel($tTrans3->getRowType(), "labTrans3", undef, sub { $res_trans .= $_[1]->printP() . "\n" } );
ok(ref $labTrans3, "Triceps::Label");
$tTrans3->getOutputLabel()->chain($labTrans3);

my $res_transp;
my $labTrans3p = $vu3->makeLabel($tTrans3p->getRowType(), "labTrans3p", undef, sub { $res_transp .= $_[1]->printP() . "\n" } );
ok(ref $labTrans3p, "Triceps::Label");
$tTrans3p->getOutputLabel()->chain($labTrans3p);

################################################################
# functions that wrap the join creation and wiring

sub wirejoin($$) # (name, join)
{
	my ($name, $join) = @_;

	ok(ref $join, "Triceps::JoinTwo") || confess "join creation failed";

	my $outlab = $vu3->makeLabel($join->getResultRowType(), "out$name", undef, sub { $result{$name} .= $_[1]->printP() . "\n" } );
	ok(ref $outlab, "Triceps::Label") || confess "label creation failed";
	$join->getOutputLabel()->chain($outlab);
}

################################################################

# create the joins
# inner
# (also save the joiners)
my($codeLeft, $codeRight);
wirejoin("3a", Triceps::JoinTwo->new(
	name => "join3a",
	leftTable => $tTrans3,
	rightTable => $tAccounts3,
	leftIdxPath => ["byAccount"],
	rightIdxPath => ["lookupSrcExt"],
	leftFields => undef, # copy all
	rightFields => [ '.*/ac_$&' ], # copy all with prefix ac_
	fieldsUniqKey => "none",
	type => "inner",
	leftSaveJoinerTo => \$codeLeft,
	rightSaveJoinerTo => \$codeRight,
));
ok($codeLeft =~ /^\s+sub # \(\$inLabel, \$rowop, \$self\)/);
ok($codeRight =~ /^\s+sub # \(\$inLabel, \$rowop, \$self\)/);

# outer - with leaf index on left, and fields backwards
wirejoin("3b", Triceps::JoinTwo->new(
	name => "join3b",
	leftTable => $tTrans3p,
	rightTable => $tAccounts3,
	leftIdxPath => ["byAccount"],
	rightIdxPath => ["lookupSrcExt"],
	leftFields => undef, # copy all
	rightFields => [ '.*/ac_$&' ], # copy all with prefix ac_
	fieldsLeftFirst => 0,
	fieldsUniqKey => "none",
	type => "outer",
));

# left
# and along the way test an explicit "by"
wirejoin("3c", Triceps::JoinTwo->new(
	name => "join3c",
	leftTable => $tTrans3,
	rightTable => $tAccounts3,
	leftIdxPath => ["byAccountBackwards"],
	rightIdxPath => ["lookupSrcExt"],
	leftFields => undef, # copy all
	rightFields => [ '.*/ac_$&' ], # copy all with prefix ac_
	fieldsUniqKey => "none",
	by => [ 
		"acctXtrId" => "external", 
		"acctSrc" => "source"
	],
	type => "left",
));

# right - with leaf index on left, and indexes looked up automatically from byLeft,
# and along the way test an explicit "byLeft"
wirejoin("3d", Triceps::JoinTwo->new(
	name => "join3d",
	leftTable => $tTrans3p,
	rightTable => $tAccounts3,
	# leftIdxPath => ["byAccount"],
	# rightIdxPath => ["lookupSrcExt"],
	leftFields => undef, # copy all
	rightFields => [ '.*/ac_$&' ], # copy all with prefix ac_
	fieldsUniqKey => "none",
	byLeft => [ "acctXtrId/external", "acctSrc/source" ],
	type => "right",
));

# inner - overrideSimpleMinded
wirejoin("3e", Triceps::JoinTwo->new(
	name => "join3e",
	leftTable => $tTrans3,
	rightTable => $tAccounts3,
	leftIdxPath => ["byAccount"],
	rightIdxPath => ["lookupSrcExt"],
	leftFields => undef, # copy all
	rightFields => [ '.*/ac_$&' ], # copy all with prefix ac_
	fieldsUniqKey => "none",
	type => "inner",
	overrideSimpleMinded => 1,
));

# left - overrideSimpleMinded
wirejoin("3f", Triceps::JoinTwo->new(
	name => "join3f",
	leftTable => $tTrans3,
	rightTable => $tAccounts3,
	leftIdxPath => ["byAccount"],
	rightIdxPath => ["lookupSrcExt"],
	leftFields => undef, # copy all
	rightFields => [ '.*/ac_$&' ], # copy all with prefix ac_
	fieldsUniqKey => "none",
	type => "left",
	overrideSimpleMinded => 1,
));

# right - overrideSimpleMinded
wirejoin("3g", Triceps::JoinTwo->new(
	name => "join3g",
	leftTable => $tTrans3,
	rightTable => $tAccounts3,
	leftIdxPath => ["byAccount"],
	rightIdxPath => ["lookupSrcExt"],
	leftFields => undef, # copy all
	rightFields => [ '.*/ac_$&' ], # copy all with prefix ac_
	fieldsUniqKey => "none",
	type => "right",
	overrideSimpleMinded => 1,
));

# full outer (same as 3b) but with filtering on the input labels
# (this is a bad example with inconsistent filtering, a good one would filter
# by a key field, same on both sides, by the same condition)

my $lbLeft3h = $vu3->makeDummyLabel($tTrans3p->getRowType(), "lbLeft3h");
my $lbFilterLeft3h = $vu3->makeLabel($tTrans3p->getRowType(), "lbFilterLeft3h", undef, sub {
	my $rowop = $_[1];
	my $row = $rowop->getRow();
	if ($row->get("id") != 1) {
		$vu3->call($lbLeft3h->makeRowop($rowop->getOpcode(), $row));
	}
});
$tTrans3p->getOutputLabel()->chain($lbFilterLeft3h);
my $lbRight3h = $vu3->makeDummyLabel($tAccounts3->getRowType(), "lbRight3h");
my $lbFilterRight3h = $vu3->makeLabel($tAccounts3->getRowType(), "lbFilterRight3h", undef, sub {
	my $rowop = $_[1];
	my $row = $rowop->getRow();
	if ($row->get("external") ne "42") {
		$vu3->call($lbRight3h->makeRowop($rowop->getOpcode(), $row));
	}
});
$tAccounts3->getOutputLabel()->chain($lbFilterRight3h);
wirejoin("3h", Triceps::JoinTwo->new(
	name => "join3h",
	leftTable => $tTrans3p,
	leftFromLabel => $lbLeft3h,
	rightTable => $tAccounts3,
	rightFromLabel => $lbRight3h,
	leftIdxPath => ["byAccount"],
	rightIdxPath => ["lookupSrcExt"],
	leftFields => undef, # copy all
	rightFields => [ '.*/ac_$&' ], # copy all with prefix ac_
	fieldsUniqKey => "none",
	fieldsLeftFirst => 0,
	type => "outer",
));

#########################################################################
# tests of fieldsUniqKey

# full outer (same as 3b) but with fieldsUniqKey==manual
wirejoin("3i", Triceps::JoinTwo->new(
	name => "join3i",
	leftTable => $tTrans3p,
	rightTable => $tAccounts3,
	leftIdxPath => ["byAccount"],
	rightIdxPath => ["lookupSrcExt"],
	leftFields => undef, # copy all
	rightFields => [ '.*/ac_$&' ], # copy all with prefix ac_
	fieldsLeftFirst => 0,
	fieldsUniqKey => "manual",
	type => "outer",
	#leftSaveJoinerTo => \$codeLeft,
	#rightSaveJoinerTo => \$codeRight,
));
#print "left:\n$codeLeft\n";
#print "right:\n$codeRight\n";

# full outer (same as 3b) but with fieldsUniqKey==right
wirejoin("3j", Triceps::JoinTwo->new(
	name => "join3j",
	leftTable => $tTrans3p,
	rightTable => $tAccounts3,
	leftIdxPath => ["byAccount"],
	rightIdxPath => ["lookupSrcExt"],
	leftFields => undef, # copy all
	rightFields => [ '.*/ac_$&' ], # copy all with prefix ac_
	fieldsLeftFirst => 0,
	fieldsUniqKey => "right",
	type => "outer",
	leftSaveJoinerTo => \$codeLeft,
	rightSaveJoinerTo => \$codeRight,
));

# full outer (same as 3b) but with fieldsUniqKey==left
wirejoin("3k", Triceps::JoinTwo->new(
	name => "join3k",
	leftTable => $tTrans3p,
	rightTable => $tAccounts3,
	leftIdxPath => ["byAccount"],
	rightIdxPath => ["lookupSrcExt"],
	leftFields => undef, # copy all
	rightFields => [ '.*/ac_$&' ], # copy all with prefix ac_
	fieldsLeftFirst => 0,
	fieldsUniqKey => "left",
	type => "outer",
	leftSaveJoinerTo => \$codeLeft,
	rightSaveJoinerTo => \$codeRight,
));

# full outer (same as 3b) but with fieldsUniqKey==first and fieldsLeftFirst==0
wirejoin("3l", Triceps::JoinTwo->new(
	name => "join3l",
	leftTable => $tTrans3p,
	rightTable => $tAccounts3,
	leftIdxPath => ["byAccount"],
	rightIdxPath => ["lookupSrcExt"],
	leftFields => undef, # copy all
	rightFields => [ '.*/ac_$&' ], # copy all with prefix ac_
	fieldsLeftFirst => 0,
	fieldsUniqKey => "right",
	type => "outer",
	leftSaveJoinerTo => \$codeLeft,
	rightSaveJoinerTo => \$codeRight,
));

# full outer (same as 3b) but with fieldsUniqKey==first and fieldsLeftFirst==1
wirejoin("3m", Triceps::JoinTwo->new(
	name => "join3m",
	leftTable => $tTrans3p,
	rightTable => $tAccounts3,
	leftIdxPath => ["byAccount"],
	rightIdxPath => ["lookupSrcExt"],
	leftFields => undef, # copy all
	rightFields => [ '.*/ac_$&' ], # copy all with prefix ac_
	fieldsLeftFirst => 1,
	fieldsUniqKey => "left",
	type => "outer",
	leftSaveJoinerTo => \$codeLeft,
	rightSaveJoinerTo => \$codeRight,
));

##########################################################################
# a self-join of accounts table

wirejoin("3n", Triceps::JoinTwo->new(
	name => "join3n",
	leftTable => $tAccounts3,
	rightTable => $tAccounts3,
	leftIdxPath => ["lookupIntGroup"],
	rightIdxPath => ["lookupIntGroup"],
	rightFields => [ '.*/rt_$&' ], # copy all with prefix rt_
	type => "inner",
));

##########################################################################
# tests of non-leaf index in oppositeOuter

# right - with non-leaf index on the left
wirejoin("3o", Triceps::JoinTwo->new(
	name => "join3o",
	leftTable => $tTrans3,
	rightTable => $tAccounts3,
	leftIdxPath => ["byAccount"],
	rightIdxPath => ["lookupSrcExt"],
	leftFields => undef, # copy all
	rightFields => [ '.*/ac_$&' ], # copy all with prefix ac_
	fieldsUniqKey => "none",
	type => "right",
));

# left - with non-leaf index on the right (mirror or 3o)
wirejoin("3p", Triceps::JoinTwo->new(
	name => "join3p",
	leftTable => $tAccounts3,
	rightTable => $tTrans3,
	leftIdxPath => ["lookupSrcExt"],
	rightIdxPath => ["byAccount"],
	leftFields => [ '.*/ac_$&' ], # copy all with prefix ac_
	rightFields => undef, # copy all
	fieldsLeftFirst => 0,
	fieldsUniqKey => "none",
	type => "left",
));

# outer - with non-leaf index on both sides
# (achieved through an account table containing everything in duplicate)
wirejoin("3q", Triceps::JoinTwo->new(
	name => "join3q",
	leftTable => $tTrans3,
	rightTable => $tAccounts3dup,
	leftIdxPath => ["byAccount"],
	rightIdxPath => ["lookupSrcExt"],
	leftFields => undef, # copy all
	rightFields => [ '.*/ac_$&' ], # copy all with prefix ac_
	fieldsUniqKey => "none",
	type => "outer",
));

# self-join, like 3n but an outer join
wirejoin("3r", Triceps::JoinTwo->new(
	name => "join3r",
	leftTable => $tAccounts3,
	rightTable => $tAccounts3,
	leftIdxPath => ["lookupIntGroup"],
	rightIdxPath => ["lookupIntGroup"],
	rightFields => [ '.*/rt_$&' ], # copy all with prefix rt_
	type => "outer",
));

##########################################################################
# now send the data

# helper function to feed the input data to a mix of labels
# @param dataArray - ref to an array of row descriptions, each of which is a ref to array of:
#    label, opcode, ref to array of fields
sub feedMixedInput # (@$dataArray)
{
	my $dataArray = shift;
	foreach my $entry (@$dataArray) {
		my ($label, $opcode, $tuple) = @$entry;
		my $unit = $label->getUnit();
		my $rt = $label->getType();
		my $rowop = $label->makeRowop($opcode, $rt->makeRowArray(@$tuple));
		$unit->schedule($rowop);
	}
}

@data3 = (
	[ $labtrans3, &Triceps::OP_INSERT, [ 1, "source1", "999", 100 ] ], 
	[ $inacct3, &Triceps::OP_INSERT, [ "source1", "999", 1 ] ],
	[ $inacct3, &Triceps::OP_INSERT, [ "source1", "2011", 2 ] ],
	[ $inacct3, &Triceps::OP_INSERT, [ "source1", "42", 3 ] ],
	[ $inacct3, &Triceps::OP_INSERT, [ "source2", "ABCD", 1 ] ],
	[ $labtrans3, &Triceps::OP_INSERT, [ 2, "source2", "ABCD", 200 ] ], 
	[ $labtrans3, &Triceps::OP_INSERT, [ 3, "source3", "ZZZZ", 300 ] ], 
	[ $labtrans3, &Triceps::OP_INSERT, [ 4, "source1", "999", 400 ] ], 
	[ $inacct3, &Triceps::OP_DELETE, [ "source1", "999", 1 ] ],
	[ $inacct3, &Triceps::OP_INSERT, [ "source1", "999", 4 ] ],
	[ $labtrans3, &Triceps::OP_INSERT, [ 4, "source1", "2011", 500 ] ], # will displace the original record in tTrans3
	[ $labtrans3, &Triceps::OP_DELETE, [ 2, "source2", "ABCD", 200 ] ], 
);

&feedMixedInput(\@data3);
$vu3->drainFrame();
ok($vu3->empty());

ok ($result{"3a"}, 
'join3a.rightLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="1" 
join3a.leftLookup.out OP_INSERT id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3a.leftLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="1" 
join3a.rightLookup.out OP_DELETE id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="1" 
join3a.rightLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="1" 
join3a.rightLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="4" 
join3a.rightLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="4" 
join3a.leftLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="4" 
join3a.leftLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="2011" amount="500" ac_source="source1" ac_external="2011" ac_internal="2" 
join3a.leftLookup.out OP_DELETE id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" ac_source="source2" ac_external="ABCD" ac_internal="1" 
');
ok ($result{"3b"}, 
'join3b.leftLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3b.rightLookup.out OP_DELETE id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3b.rightLookup.out OP_INSERT ac_source="source1" ac_external="999" ac_internal="1" id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3b.rightLookup.out OP_INSERT ac_source="source1" ac_external="2011" ac_internal="2" 
join3b.rightLookup.out OP_INSERT ac_source="source1" ac_external="42" ac_internal="3" 
join3b.rightLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3b.leftLookup.out OP_DELETE ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3b.leftLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" 
join3b.leftLookup.out OP_INSERT id="3" acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
join3b.leftLookup.out OP_DELETE ac_source="source1" ac_external="999" ac_internal="1" id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3b.leftLookup.out OP_INSERT ac_source="source1" ac_external="999" ac_internal="1" 
join3b.leftLookup.out OP_DELETE ac_source="source1" ac_external="999" ac_internal="1" 
join3b.leftLookup.out OP_INSERT ac_source="source1" ac_external="999" ac_internal="1" id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3b.rightLookup.out OP_DELETE ac_source="source1" ac_external="999" ac_internal="1" id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3b.rightLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3b.rightLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3b.rightLookup.out OP_INSERT ac_source="source1" ac_external="999" ac_internal="4" id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3b.leftLookup.out OP_DELETE ac_source="source1" ac_external="2011" ac_internal="2" 
join3b.leftLookup.out OP_INSERT ac_source="source1" ac_external="2011" ac_internal="2" id="4" acctSrc="source1" acctXtrId="2011" amount="500" 
join3b.leftLookup.out OP_DELETE ac_source="source2" ac_external="ABCD" ac_internal="1" id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" 
join3b.leftLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" 
');
ok ($result{"3c"}, 
'join3c.leftLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3c.rightLookup.out OP_DELETE id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3c.rightLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="1" 
join3c.leftLookup.out OP_INSERT id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3c.leftLookup.out OP_INSERT id="3" acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
join3c.leftLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="1" 
join3c.rightLookup.out OP_DELETE id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="1" 
join3c.rightLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3c.rightLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="1" 
join3c.rightLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3c.rightLookup.out OP_DELETE id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3c.rightLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="4" 
join3c.rightLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3c.rightLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="4" 
join3c.leftLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="4" 
join3c.leftLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="2011" amount="500" ac_source="source1" ac_external="2011" ac_internal="2" 
join3c.leftLookup.out OP_DELETE id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" ac_source="source2" ac_external="ABCD" ac_internal="1" 
');
ok ($result{"3d"}, 
'join3d.rightLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="1" 
join3d.rightLookup.out OP_INSERT ac_source="source1" ac_external="2011" ac_internal="2" 
join3d.rightLookup.out OP_INSERT ac_source="source1" ac_external="42" ac_internal="3" 
join3d.rightLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3d.leftLookup.out OP_DELETE ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3d.leftLookup.out OP_INSERT id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3d.leftLookup.out OP_DELETE id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="1" 
join3d.leftLookup.out OP_INSERT ac_source="source1" ac_external="999" ac_internal="1" 
join3d.leftLookup.out OP_DELETE ac_source="source1" ac_external="999" ac_internal="1" 
join3d.leftLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="1" 
join3d.rightLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="1" 
join3d.rightLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="4" 
join3d.leftLookup.out OP_DELETE ac_source="source1" ac_external="2011" ac_internal="2" 
join3d.leftLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="2011" amount="500" ac_source="source1" ac_external="2011" ac_internal="2" 
join3d.leftLookup.out OP_DELETE id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3d.leftLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" 
');
ok ($result{"3e"}, 
'join3e.rightLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="1" 
join3e.leftLookup.out OP_INSERT id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3e.leftLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="1" 
join3e.rightLookup.out OP_DELETE id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="1" 
join3e.rightLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="1" 
join3e.rightLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="4" 
join3e.rightLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="4" 
join3e.leftLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="4" 
join3e.leftLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="2011" amount="500" ac_source="source1" ac_external="2011" ac_internal="2" 
join3e.leftLookup.out OP_DELETE id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" ac_source="source2" ac_external="ABCD" ac_internal="1" 
');
ok ($result{"3f"}, 
'join3f.leftLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3f.rightLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="1" 
join3f.leftLookup.out OP_INSERT id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3f.leftLookup.out OP_INSERT id="3" acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
join3f.leftLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="1" 
join3f.rightLookup.out OP_DELETE id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="1" 
join3f.rightLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="1" 
join3f.rightLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="4" 
join3f.rightLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="4" 
join3f.leftLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="4" 
join3f.leftLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="2011" amount="500" ac_source="source1" ac_external="2011" ac_internal="2" 
join3f.leftLookup.out OP_DELETE id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" ac_source="source2" ac_external="ABCD" ac_internal="1" 
');
ok ($result{"3g"}, 
'join3g.rightLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="1" 
join3g.rightLookup.out OP_INSERT ac_source="source1" ac_external="2011" ac_internal="2" 
join3g.rightLookup.out OP_INSERT ac_source="source1" ac_external="42" ac_internal="3" 
join3g.rightLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3g.leftLookup.out OP_INSERT id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3g.leftLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="1" 
join3g.rightLookup.out OP_DELETE id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="1" 
join3g.rightLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="1" 
join3g.rightLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="4" 
join3g.rightLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="4" 
join3g.leftLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="4" 
join3g.leftLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="2011" amount="500" ac_source="source1" ac_external="2011" ac_internal="2" 
join3g.leftLookup.out OP_DELETE id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" ac_source="source2" ac_external="ABCD" ac_internal="1" 
');
# the result is inconsistent because of the filtering not being consistent
ok ($result{"3h"}, 
'join3h.rightLookup.out OP_DELETE id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3h.rightLookup.out OP_INSERT ac_source="source1" ac_external="999" ac_internal="1" id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3h.rightLookup.out OP_INSERT ac_source="source1" ac_external="2011" ac_internal="2" 
join3h.rightLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3h.leftLookup.out OP_DELETE ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3h.leftLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" 
join3h.leftLookup.out OP_INSERT id="3" acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
join3h.leftLookup.out OP_DELETE ac_source="source1" ac_external="999" ac_internal="1" 
join3h.leftLookup.out OP_INSERT ac_source="source1" ac_external="999" ac_internal="1" id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3h.rightLookup.out OP_DELETE ac_source="source1" ac_external="999" ac_internal="1" id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3h.rightLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3h.rightLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3h.rightLookup.out OP_INSERT ac_source="source1" ac_external="999" ac_internal="4" id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3h.leftLookup.out OP_DELETE ac_source="source1" ac_external="2011" ac_internal="2" 
join3h.leftLookup.out OP_INSERT ac_source="source1" ac_external="2011" ac_internal="2" id="4" acctSrc="source1" acctXtrId="2011" amount="500" 
join3h.leftLookup.out OP_DELETE ac_source="source2" ac_external="ABCD" ac_internal="1" id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" 
join3h.leftLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" 
');
ok ($result{"3i"}, 
'join3i.leftLookup.out OP_INSERT ac_source="source1" ac_external="999" id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3i.rightLookup.out OP_DELETE ac_source="source1" ac_external="999" id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3i.rightLookup.out OP_INSERT ac_source="source1" ac_external="999" ac_internal="1" id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3i.rightLookup.out OP_INSERT ac_source="source1" ac_external="2011" ac_internal="2" acctSrc="source1" acctXtrId="2011" 
join3i.rightLookup.out OP_INSERT ac_source="source1" ac_external="42" ac_internal="3" acctSrc="source1" acctXtrId="42" 
join3i.rightLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" acctSrc="source2" acctXtrId="ABCD" 
join3i.leftLookup.out OP_DELETE ac_source="source2" ac_external="ABCD" ac_internal="1" acctSrc="source2" acctXtrId="ABCD" 
join3i.leftLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" 
join3i.leftLookup.out OP_INSERT ac_source="source3" ac_external="ZZZZ" id="3" acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
join3i.leftLookup.out OP_DELETE ac_source="source1" ac_external="999" ac_internal="1" id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3i.leftLookup.out OP_INSERT ac_source="source1" ac_external="999" ac_internal="1" acctSrc="source1" acctXtrId="999" 
join3i.leftLookup.out OP_DELETE ac_source="source1" ac_external="999" ac_internal="1" acctSrc="source1" acctXtrId="999" 
join3i.leftLookup.out OP_INSERT ac_source="source1" ac_external="999" ac_internal="1" id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3i.rightLookup.out OP_DELETE ac_source="source1" ac_external="999" ac_internal="1" id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3i.rightLookup.out OP_INSERT ac_source="source1" ac_external="999" id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3i.rightLookup.out OP_DELETE ac_source="source1" ac_external="999" id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3i.rightLookup.out OP_INSERT ac_source="source1" ac_external="999" ac_internal="4" id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3i.leftLookup.out OP_DELETE ac_source="source1" ac_external="2011" ac_internal="2" acctSrc="source1" acctXtrId="2011" 
join3i.leftLookup.out OP_INSERT ac_source="source1" ac_external="2011" ac_internal="2" id="4" acctSrc="source1" acctXtrId="2011" amount="500" 
join3i.leftLookup.out OP_DELETE ac_source="source2" ac_external="ABCD" ac_internal="1" id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" 
join3i.leftLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" acctSrc="source2" acctXtrId="ABCD" 
');
ok ($result{"3j"}, 
'join3j.leftLookup.out OP_INSERT ac_source="source1" ac_external="999" id="1" amount="100" 
join3j.rightLookup.out OP_DELETE ac_source="source1" ac_external="999" id="1" amount="100" 
join3j.rightLookup.out OP_INSERT ac_source="source1" ac_external="999" ac_internal="1" id="1" amount="100" 
join3j.rightLookup.out OP_INSERT ac_source="source1" ac_external="2011" ac_internal="2" 
join3j.rightLookup.out OP_INSERT ac_source="source1" ac_external="42" ac_internal="3" 
join3j.rightLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3j.leftLookup.out OP_DELETE ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3j.leftLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" id="2" amount="200" 
join3j.leftLookup.out OP_INSERT ac_source="source3" ac_external="ZZZZ" id="3" amount="300" 
join3j.leftLookup.out OP_DELETE ac_source="source1" ac_external="999" ac_internal="1" id="1" amount="100" 
join3j.leftLookup.out OP_INSERT ac_source="source1" ac_external="999" ac_internal="1" 
join3j.leftLookup.out OP_DELETE ac_source="source1" ac_external="999" ac_internal="1" 
join3j.leftLookup.out OP_INSERT ac_source="source1" ac_external="999" ac_internal="1" id="4" amount="400" 
join3j.rightLookup.out OP_DELETE ac_source="source1" ac_external="999" ac_internal="1" id="4" amount="400" 
join3j.rightLookup.out OP_INSERT ac_source="source1" ac_external="999" id="4" amount="400" 
join3j.rightLookup.out OP_DELETE ac_source="source1" ac_external="999" id="4" amount="400" 
join3j.rightLookup.out OP_INSERT ac_source="source1" ac_external="999" ac_internal="4" id="4" amount="400" 
join3j.leftLookup.out OP_DELETE ac_source="source1" ac_external="2011" ac_internal="2" 
join3j.leftLookup.out OP_INSERT ac_source="source1" ac_external="2011" ac_internal="2" id="4" amount="500" 
join3j.leftLookup.out OP_DELETE ac_source="source2" ac_external="ABCD" ac_internal="1" id="2" amount="200" 
join3j.leftLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" 
');
ok ($result{"3k"}, 
'join3k.leftLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3k.rightLookup.out OP_DELETE id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3k.rightLookup.out OP_INSERT ac_internal="1" id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3k.rightLookup.out OP_INSERT ac_internal="2" acctSrc="source1" acctXtrId="2011" 
join3k.rightLookup.out OP_INSERT ac_internal="3" acctSrc="source1" acctXtrId="42" 
join3k.rightLookup.out OP_INSERT ac_internal="1" acctSrc="source2" acctXtrId="ABCD" 
join3k.leftLookup.out OP_DELETE ac_internal="1" acctSrc="source2" acctXtrId="ABCD" 
join3k.leftLookup.out OP_INSERT ac_internal="1" id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" 
join3k.leftLookup.out OP_INSERT id="3" acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
join3k.leftLookup.out OP_DELETE ac_internal="1" id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3k.leftLookup.out OP_INSERT ac_internal="1" acctSrc="source1" acctXtrId="999" 
join3k.leftLookup.out OP_DELETE ac_internal="1" acctSrc="source1" acctXtrId="999" 
join3k.leftLookup.out OP_INSERT ac_internal="1" id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3k.rightLookup.out OP_DELETE ac_internal="1" id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3k.rightLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3k.rightLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3k.rightLookup.out OP_INSERT ac_internal="4" id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3k.leftLookup.out OP_DELETE ac_internal="2" acctSrc="source1" acctXtrId="2011" 
join3k.leftLookup.out OP_INSERT ac_internal="2" id="4" acctSrc="source1" acctXtrId="2011" amount="500" 
join3k.leftLookup.out OP_DELETE ac_internal="1" id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" 
join3k.leftLookup.out OP_INSERT ac_internal="1" acctSrc="source2" acctXtrId="ABCD" 
');
ok ($result{"3l"}, 
'join3l.leftLookup.out OP_INSERT ac_source="source1" ac_external="999" id="1" amount="100" 
join3l.rightLookup.out OP_DELETE ac_source="source1" ac_external="999" id="1" amount="100" 
join3l.rightLookup.out OP_INSERT ac_source="source1" ac_external="999" ac_internal="1" id="1" amount="100" 
join3l.rightLookup.out OP_INSERT ac_source="source1" ac_external="2011" ac_internal="2" 
join3l.rightLookup.out OP_INSERT ac_source="source1" ac_external="42" ac_internal="3" 
join3l.rightLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3l.leftLookup.out OP_DELETE ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3l.leftLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" id="2" amount="200" 
join3l.leftLookup.out OP_INSERT ac_source="source3" ac_external="ZZZZ" id="3" amount="300" 
join3l.leftLookup.out OP_DELETE ac_source="source1" ac_external="999" ac_internal="1" id="1" amount="100" 
join3l.leftLookup.out OP_INSERT ac_source="source1" ac_external="999" ac_internal="1" 
join3l.leftLookup.out OP_DELETE ac_source="source1" ac_external="999" ac_internal="1" 
join3l.leftLookup.out OP_INSERT ac_source="source1" ac_external="999" ac_internal="1" id="4" amount="400" 
join3l.rightLookup.out OP_DELETE ac_source="source1" ac_external="999" ac_internal="1" id="4" amount="400" 
join3l.rightLookup.out OP_INSERT ac_source="source1" ac_external="999" id="4" amount="400" 
join3l.rightLookup.out OP_DELETE ac_source="source1" ac_external="999" id="4" amount="400" 
join3l.rightLookup.out OP_INSERT ac_source="source1" ac_external="999" ac_internal="4" id="4" amount="400" 
join3l.leftLookup.out OP_DELETE ac_source="source1" ac_external="2011" ac_internal="2" 
join3l.leftLookup.out OP_INSERT ac_source="source1" ac_external="2011" ac_internal="2" id="4" amount="500" 
join3l.leftLookup.out OP_DELETE ac_source="source2" ac_external="ABCD" ac_internal="1" id="2" amount="200" 
join3l.leftLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" 
');
ok ($result{"3m"}, 
'join3m.leftLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3m.rightLookup.out OP_DELETE id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3m.rightLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_internal="1" 
join3m.rightLookup.out OP_INSERT acctSrc="source1" acctXtrId="2011" ac_internal="2" 
join3m.rightLookup.out OP_INSERT acctSrc="source1" acctXtrId="42" ac_internal="3" 
join3m.rightLookup.out OP_INSERT acctSrc="source2" acctXtrId="ABCD" ac_internal="1" 
join3m.leftLookup.out OP_DELETE acctSrc="source2" acctXtrId="ABCD" ac_internal="1" 
join3m.leftLookup.out OP_INSERT id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" ac_internal="1" 
join3m.leftLookup.out OP_INSERT id="3" acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
join3m.leftLookup.out OP_DELETE id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_internal="1" 
join3m.leftLookup.out OP_INSERT acctSrc="source1" acctXtrId="999" ac_internal="1" 
join3m.leftLookup.out OP_DELETE acctSrc="source1" acctXtrId="999" ac_internal="1" 
join3m.leftLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_internal="1" 
join3m.rightLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_internal="1" 
join3m.rightLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3m.rightLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3m.rightLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_internal="4" 
join3m.leftLookup.out OP_DELETE acctSrc="source1" acctXtrId="2011" ac_internal="2" 
join3m.leftLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="2011" amount="500" ac_internal="2" 
join3m.leftLookup.out OP_DELETE id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" ac_internal="1" 
join3m.leftLookup.out OP_INSERT acctSrc="source2" acctXtrId="ABCD" ac_internal="1" 
');
ok ($result{"3n"}, 
'join3n.rightLookup.out OP_INSERT source="source1" external="999" internal="1" rt_source="source1" rt_external="999" 
join3n.rightLookup.out OP_INSERT source="source1" external="2011" internal="2" rt_source="source1" rt_external="2011" 
join3n.rightLookup.out OP_INSERT source="source1" external="42" internal="3" rt_source="source1" rt_external="42" 
join3n.leftLookup.out OP_INSERT source="source2" external="ABCD" internal="1" rt_source="source1" rt_external="999" 
join3n.rightLookup.out OP_INSERT source="source1" external="999" internal="1" rt_source="source2" rt_external="ABCD" 
join3n.rightLookup.out OP_INSERT source="source2" external="ABCD" internal="1" rt_source="source2" rt_external="ABCD" 
join3n.leftLookup.out OP_DELETE source="source1" external="999" internal="1" rt_source="source1" rt_external="999" 
join3n.leftLookup.out OP_DELETE source="source1" external="999" internal="1" rt_source="source2" rt_external="ABCD" 
join3n.rightLookup.out OP_DELETE source="source2" external="ABCD" internal="1" rt_source="source1" rt_external="999" 
join3n.rightLookup.out OP_INSERT source="source1" external="999" internal="4" rt_source="source1" rt_external="999" 
');
ok ($result{"3o"}, 
'join3o.rightLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="1" 
join3o.rightLookup.out OP_INSERT ac_source="source1" ac_external="2011" ac_internal="2" 
join3o.rightLookup.out OP_INSERT ac_source="source1" ac_external="42" ac_internal="3" 
join3o.rightLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3o.leftLookup.out OP_DELETE ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3o.leftLookup.out OP_INSERT id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3o.leftLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="1" 
join3o.rightLookup.out OP_DELETE id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="1" 
join3o.rightLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="1" 
join3o.rightLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="4" 
join3o.rightLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="4" 
join3o.leftLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="4" 
join3o.leftLookup.out OP_DELETE ac_source="source1" ac_external="2011" ac_internal="2" 
join3o.leftLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="2011" amount="500" ac_source="source1" ac_external="2011" ac_internal="2" 
join3o.leftLookup.out OP_DELETE id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3o.leftLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" 
');
ok ($result{"3p"}, 
'join3p.leftLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="1" 
join3p.leftLookup.out OP_INSERT ac_source="source1" ac_external="2011" ac_internal="2" 
join3p.leftLookup.out OP_INSERT ac_source="source1" ac_external="42" ac_internal="3" 
join3p.leftLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3p.rightLookup.out OP_DELETE ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3p.rightLookup.out OP_INSERT id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3p.rightLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="1" 
join3p.leftLookup.out OP_DELETE id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="1" 
join3p.leftLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="1" 
join3p.leftLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="4" 
join3p.leftLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="4" 
join3p.rightLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="4" 
join3p.rightLookup.out OP_DELETE ac_source="source1" ac_external="2011" ac_internal="2" 
join3p.rightLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="2011" amount="500" ac_source="source1" ac_external="2011" ac_internal="2" 
join3p.rightLookup.out OP_DELETE id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3p.rightLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" 
');
ok ($result{"3q"}, 
'join3q.leftLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3q.rightLookup.out OP_DELETE id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3q.rightLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="1" 
join3q.rightLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="1" 
join3q.rightLookup.out OP_INSERT ac_source="source1" ac_external="2011" ac_internal="2" 
join3q.rightLookup.out OP_INSERT ac_source="source1" ac_external="2011" ac_internal="2" 
join3q.rightLookup.out OP_INSERT ac_source="source1" ac_external="42" ac_internal="3" 
join3q.rightLookup.out OP_INSERT ac_source="source1" ac_external="42" ac_internal="3" 
join3q.rightLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3q.rightLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3q.leftLookup.out OP_DELETE ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3q.leftLookup.out OP_INSERT id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3q.leftLookup.out OP_DELETE ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3q.leftLookup.out OP_INSERT id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3q.leftLookup.out OP_INSERT id="3" acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
join3q.leftLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="1" 
join3q.leftLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="1" 
join3q.rightLookup.out OP_DELETE id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="1" 
join3q.rightLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="1" 
join3q.rightLookup.out OP_DELETE id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="1" 
join3q.rightLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3q.rightLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="1" 
join3q.rightLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3q.rightLookup.out OP_DELETE id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3q.rightLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="4" 
join3q.rightLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3q.rightLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="4" 
join3q.rightLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="4" 
join3q.rightLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="4" 
join3q.leftLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="4" 
join3q.leftLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="4" 
join3q.leftLookup.out OP_DELETE ac_source="source1" ac_external="2011" ac_internal="2" 
join3q.leftLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="2011" amount="500" ac_source="source1" ac_external="2011" ac_internal="2" 
join3q.leftLookup.out OP_DELETE ac_source="source1" ac_external="2011" ac_internal="2" 
join3q.leftLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="2011" amount="500" ac_source="source1" ac_external="2011" ac_internal="2" 
join3q.leftLookup.out OP_DELETE id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3q.leftLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3q.leftLookup.out OP_DELETE id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3q.leftLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" 
');
# this was the expected output of 3q with the non-dupped accounts table, for reference
my $nondup3q = 'join3q.leftLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3q.rightLookup.out OP_DELETE id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3q.rightLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="1" 
join3q.rightLookup.out OP_INSERT ac_source="source1" ac_external="2011" ac_internal="2" 
join3q.rightLookup.out OP_INSERT ac_source="source1" ac_external="42" ac_internal="3" 
join3q.rightLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3q.leftLookup.out OP_DELETE ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3q.leftLookup.out OP_INSERT id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3q.leftLookup.out OP_INSERT id="3" acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
join3q.leftLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="1" 
join3q.rightLookup.out OP_DELETE id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="1" 
join3q.rightLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3q.rightLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="1" 
join3q.rightLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3q.rightLookup.out OP_DELETE id="1" acctSrc="source1" acctXtrId="999" amount="100" 
join3q.rightLookup.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" ac_source="source1" ac_external="999" ac_internal="4" 
join3q.rightLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" 
join3q.rightLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="4" 
join3q.leftLookup.out OP_DELETE id="4" acctSrc="source1" acctXtrId="999" amount="400" ac_source="source1" ac_external="999" ac_internal="4" 
join3q.leftLookup.out OP_DELETE ac_source="source1" ac_external="2011" ac_internal="2" 
join3q.leftLookup.out OP_INSERT id="4" acctSrc="source1" acctXtrId="2011" amount="500" ac_source="source1" ac_external="2011" ac_internal="2" 
join3q.leftLookup.out OP_DELETE id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" ac_source="source2" ac_external="ABCD" ac_internal="1" 
join3q.leftLookup.out OP_INSERT ac_source="source2" ac_external="ABCD" ac_internal="1" 
';
ok ($result{"3r"}, 
'join3r.leftLookup.out OP_INSERT source="source1" external="999" internal="1" 
join3r.rightLookup.out OP_DELETE source="source1" external="999" internal="1" 
join3r.rightLookup.out OP_INSERT source="source1" external="999" internal="1" rt_source="source1" rt_external="999" 
join3r.leftLookup.out OP_INSERT source="source1" external="2011" internal="2" 
join3r.rightLookup.out OP_DELETE source="source1" external="2011" internal="2" 
join3r.rightLookup.out OP_INSERT source="source1" external="2011" internal="2" rt_source="source1" rt_external="2011" 
join3r.leftLookup.out OP_INSERT source="source1" external="42" internal="3" 
join3r.rightLookup.out OP_DELETE source="source1" external="42" internal="3" 
join3r.rightLookup.out OP_INSERT source="source1" external="42" internal="3" rt_source="source1" rt_external="42" 
join3r.leftLookup.out OP_INSERT source="source2" external="ABCD" internal="1" rt_source="source1" rt_external="999" 
join3r.rightLookup.out OP_INSERT source="source1" external="999" internal="1" rt_source="source2" rt_external="ABCD" 
join3r.rightLookup.out OP_INSERT source="source2" external="ABCD" internal="1" rt_source="source2" rt_external="ABCD" 
join3r.leftLookup.out OP_DELETE source="source1" external="999" internal="1" rt_source="source1" rt_external="999" 
join3r.leftLookup.out OP_DELETE source="source1" external="999" internal="1" rt_source="source2" rt_external="ABCD" 
join3r.rightLookup.out OP_DELETE source="source2" external="ABCD" internal="1" rt_source="source1" rt_external="999" 
join3r.leftLookup.out OP_INSERT source="source1" external="999" internal="4" 
join3r.rightLookup.out OP_DELETE source="source1" external="999" internal="4" 
join3r.rightLookup.out OP_INSERT source="source1" external="999" internal="4" rt_source="source1" rt_external="999" 
');
#print STDERR $result{"3n"};

# for debugging
#print STDERR $result3f;
#print STDERR "---- acct ----\n";
#print STDERR $res_acct;
#print STDERR "---- acctDup ----\n";
#print STDERR $res_acct_dup;
#print STDERR "---- trans ----\n";
#print STDERR $res_trans;
#print STDERR "---- transp ----\n";
#print STDERR $res_transp;
#print STDERR "---- acct dump ----\n";
#for (my $rh = $tAccounts3->beginIdx($idxAccountsLookup); !$rh->isNull(); $rh = $tAccounts3->nextIdx($idxAccountsLookup, $rh)) {
#	print STDERR $rh->getRow()->printP(), "\n";
#}


#########
# getters

{
	my $join = Triceps::JoinTwo->new( 
		name => "join",
		leftTable => $tTrans3,
		rightTable => $tAccounts3,
		leftIdxPath => ["byAccount"],
		rightIdxPath => ["lookupSrcExt"],
		leftFields => [ ".*" ],
		byLeft => [ "acctSrc/source", "acctXtrId/external" ],
	);
	ok(ref $join, "Triceps::JoinTwo");

	my $res;
	$res = $join->getResultRowType();
	ok(ref $res, "Triceps::RowType");
	$res = $join->getOutputLabel();
	ok(ref $res, "Triceps::Label");

	ok($join->getUnit()->same($tTrans3->getUnit()));
	ok($join->getName(), "join");
	ok($join->getLeftTable()->same($tTrans3));
	ok($join->getRightTable()->same($tAccounts3));
	ok(join(",", @{$join->getLeftIdxPath()}), "byAccount");
	ok(join(",", @{$join->getRightIdxPath()}), "lookupSrcExt");

	ok(join(",", @{$join->getLeftFields()}), ".*");
	ok(join(",", @{$join->getRightFields()}), '!source,!external,.*'); # amended by fieldsUniqKey

	ok($join->getFieldsLeftFirst(), 1); # the default
	ok($join->getFieldsUniqKey(), "first"); # the default

	ok(join(",", @{$join->getBy()}), "acctSrc,source,acctXtrId,external");
	ok(join(",", @{$join->getByLeft()}), "acctSrc/source,acctXtrId/external,!.*");

	ok($join->getType(), "inner"); # the default
	ok($join->getOverrideSimpleMinded(), 0); # the default
	ok($join->getOverrideKeyTypes(), 0); # the default
}
{
	my $join = Triceps::JoinTwo->new( 
		name => "join",
		leftTable => $tTrans3,
		rightTable => $tAccounts3,
		leftIdxPath => ["byAccount"],
		rightIdxPath => ["lookupSrcExt"],
		type => "outer",
		fieldsUniqKey => "none",
		fieldsLeftFirst => 10,
		overrideSimpleMinded => 11,
		overrideKeyTypes => 12,
	);
	ok(ref $join, "Triceps::JoinTwo");

	ok(! defined $join->getLeftFields());
	ok(! defined $join->getRightFields());

	ok($join->getFieldsLeftFirst(), 10);
	ok($join->getFieldsUniqKey(), "none");

	ok(! defined $join->getBy());
	ok(! defined $join->getByLeft());

	ok($join->getType(), "outer"); # the default
	ok($join->getOverrideSimpleMinded(), 11); # the default
	ok($join->getOverrideKeyTypes(), 12); # the default
}

#########
# fnReturn
{
	my $join = Triceps::JoinTwo->new( 
		name => "join",
		leftTable => $tTrans3,
		rightTable => $tAccounts3,
		leftIdxPath => ["byAccount"],
		rightIdxPath => ["lookupSrcExt"],
		type => "outer",
		fieldsUniqKey => "none",
		fieldsLeftFirst => 10,
		overrideSimpleMinded => 11,
		overrideKeyTypes => 12,
	);
	ok(ref $join, "Triceps::JoinTwo");

	my $out = $join->getOutputLabel();
	ok(!$out->hasChained());

	my $ret = $join->fnReturn();
	ok(ref $ret, "Triceps::FnReturn");
	ok($ret->getName(), "join.fret");
	ok($out->hasChained());
	my @chain = $out->getChain();
	ok($chain[0]->same($ret->getLabel("out")));
	# On repeated calls gets the exact same object.
	ok($ret, $join->fnReturn());
}

#########
# tests for errors

sub tryMissingOptValue # (optName)
{
	my %opt = (
		name => "join3a",
		leftTable => $tTrans3,
		rightTable => $tAccounts3,
		leftIdxPath => ["byAccount"],
		rightIdxPath => ["lookupSrcExt"],
	);
	delete $opt{$_[0]};
	eval {
		Triceps::JoinTwo->new(%opt);
	}
}

&tryMissingOptValue("name");
ok($@, qr/^Option 'name' must be specified for class 'Triceps::JoinTwo'/);
&tryMissingOptValue("leftTable");
ok($@, qr/^Option 'leftTable' must be specified for class 'Triceps::JoinTwo'/);
&tryMissingOptValue("rightTable");
ok($@, qr/^Option 'rightTable' must be specified for class 'Triceps::JoinTwo'/);

sub tryBadOptValue # (optName, optValue, ...)
{
	my %opt = (
		name => "join3a",
		leftTable => $tTrans3,
		rightTable => $tAccounts3,
		leftIdxPath => ["byAccount"],
		rightIdxPath => ["lookupSrcExt"],
	);
	while ($#_ >= 1) {
		if (defined $_[1]) {
			$opt{$_[0]} = $_[1];
		} else {
			delete $opt{$_[0]};
		}
		shift; shift;
	}
	eval {
		Triceps::JoinTwo->new(%opt);
	}
}

&tryBadOptValue(leftTable => 9);
ok($@, qr/^Option 'leftTable' of class 'Triceps::JoinTwo' must be a reference to 'Triceps::Table', is ''/);
&tryBadOptValue(rightTable => 9);
ok($@, qr/^Option 'rightTable' of class 'Triceps::JoinTwo' must be a reference to 'Triceps::Table', is ''/);
&tryBadOptValue(leftFromLabel => 9);
ok($@, qr/^Option 'leftFromLabel' of class 'Triceps::JoinTwo' must be a reference to 'Triceps::Label', is ''/);
&tryBadOptValue(rightFromLabel => 9);
ok($@, qr/^Option 'rightFromLabel' of class 'Triceps::JoinTwo' must be a reference to 'Triceps::Label', is ''/);
&tryBadOptValue(leftIdxPath => [$vu3]);
ok($@, qr/^Option 'leftIdxPath' of class 'Triceps::JoinTwo' must be a reference to 'ARRAY' '', is 'ARRAY' 'Triceps::Unit'/);
&tryBadOptValue(rightIdxPath => [$vu3]);
ok($@, qr/^Option 'rightIdxPath' of class 'Triceps::JoinTwo' must be a reference to 'ARRAY' '', is 'ARRAY' 'Triceps::Unit'/);
&tryBadOptValue(leftFields => 9);
ok($@, qr/^Option 'leftFields' of class 'Triceps::JoinTwo' must be a reference to 'ARRAY', is ''/);
&tryBadOptValue(rightFields => 9);
ok($@, qr/^Option 'rightFields' of class 'Triceps::JoinTwo' must be a reference to 'ARRAY', is ''/);
&tryBadOptValue(by => 9);
ok($@, qr/^Option 'by' of class 'Triceps::JoinTwo' must be a reference to 'ARRAY', is ''/);
&tryBadOptValue(byLeft => 9);
ok($@, qr/^Option 'byLeft' of class 'Triceps::JoinTwo' must be a reference to 'ARRAY', is ''/);
&tryBadOptValue(leftSaveJoinerTo => 9);
ok($@, qr/^Option 'leftSaveJoinerTo' of class 'Triceps::JoinTwo' must be a reference to a scalar, is ''/);
&tryBadOptValue(rightSaveJoinerTo => 9);
ok($@, qr/^Option 'rightSaveJoinerTo' of class 'Triceps::JoinTwo' must be a reference to a scalar, is ''/);

&tryBadOptValue("leftIdxPath" => undef);
ok($@, qr/^Option 'leftIdxPath' must be present if both 'by' and 'byLeft' are absent at/);
&tryBadOptValue("rightIdxPath" => undef);
ok($@, qr/^Option 'rightIdxPath' must be present if both 'by' and 'byLeft' are absent at/);

&tryBadOptValue(
	by => [ "acctSrc", "source", "acctXtrId", "external" ],
	byLeft => [ "acctSrc/source", "acctXtrId/external" ]);
ok($@, qr/^Triceps::JoinTwo::new: must have only one of options by or byLeft, got both by and byLeft/);

{
	$vu4 = Triceps::Unit->new("vu4");
	ok(ref $vu4, "Triceps::Unit");
	$tAccounts4 = $vu4->makeTable($ttAccounts, "Accounts");
	ok(ref $tAccounts4, "Triceps::Table");
	$tTrans4 = $vu4->makeTable($ttTrans3, "Trans");
	ok(ref $tTrans4, "Triceps::Table");

	&tryBadOptValue(rightTable => $tAccounts4);
	ok($@, qr/^Both tables must have the same unit, got 'vu3' and 'vu4'/);

	&tryBadOptValue(rightFromLabel => $tAccounts4->getOutputLabel());
	ok($@, qr/^The rightFromLabel unit does not match rightTable, 'vu4' vs 'vu3'/);
	&tryBadOptValue(leftFromLabel => $tTrans4->getOutputLabel());
	ok($@, qr/^The leftFromLabel unit does not match leftTable, 'vu4' vs 'vu3'/);
}

&tryBadOptValue(type => "xxx");
ok($@, qr/^Unknown value 'xxx' of option 'type', must be one of inner|left|right|outer/);

&tryBadOptValue(rightFromLabel => $tTrans3->getOutputLabel());
ok($@, qr/^The rightFromLabel row type does not match rightTable,
in label:
  row {
    int32 id,
    string acctSrc,
    string acctXtrId,
    int32 amount,
  }
in table:
  row {
    string source,
    string external,
    int32 internal,
  }
/);
&tryBadOptValue(leftFromLabel => $tAccounts3->getOutputLabel());
ok($@, qr/^The leftFromLabel row type does not match leftTable,
in label:
  row {
    string source,
    string external,
    int32 internal,
  }
in table:
  row {
    int32 id,
    string acctSrc,
    string acctXtrId,
    int32 amount,
  }
/);

&tryBadOptValue(leftIdxPath => [ "lookupIntGroup", "lookupInt" ]);
ok($@, qr/^Triceps::TableType::findIndexKeyPath: unable to find the index type at path 'lookupIntGroup', table type is:
table \(
  row {
    int32 id,
    string acctSrc,
    string acctXtrId,
    int32 amount,
  }
\) {
  index HashedIndex\(id, \) primary,
  index HashedIndex\(acctSrc, acctXtrId, \) {
    index FifoIndex\(\) data,
  } byAccount,
  index HashedIndex\(acctXtrId, acctSrc, \) {
    index FifoIndex\(\) data,
  } byAccountBackwards,
}/);

&tryBadOptValue(rightIdxPath => [ "lookupIntGroup", "lookupInt" ]);
ok($@, qr/^Triceps::TableType::findIndexKeyPath: the index type at path 'lookupIntGroup.lookupInt' does not have a key, table type is:
table \(
  row {
    string source,
    string external,
    int32 internal,
  }
\) {
  index HashedIndex\(source, external, \) lookupSrcExt,
  index HashedIndex\(source, \) {
    index HashedIndex\(external, \) iterateSrcExt,
  } iterateSrc,
  index HashedIndex\(internal, \) {
    index FifoIndex\(\) lookupInt,
  } lookupIntGroup,
}/);

&tryBadOptValue(rightIdxPath => ["iterateSrc"]);
ok($@, qr/^The count of key fields in left and right indexes doesnt match
  left:  \(acctSrc, acctXtrId\)
  right: \(source\)/);
&tryBadOptValue(by => [ "acctSrc", "source" ]);
ok($@, qr/^The count of key fields in the indexes and option 'by' does not match
  left:  \(acctSrc, acctXtrId\)
  right: \(source, external\)
  by: \(acctSrc, source\)/);
&tryBadOptValue(byLeft => [ "acctSrc/source" ]);
ok($@, qr/^The count of key fields in the indexes and option 'byLeft' does not match
  left:  \(acctSrc, acctXtrId\)
  right: \(source, external\)
  by: \(acctSrc, source\)/);

&tryBadOptValue(by => [ "id", "source", "acctXtrId", "external" ]);
ok($@, qr/^Option 'by' contains a left-side field 'id' that is not in the index key,
  left key: \(acctSrc, acctXtrId\)
  by: \(id, source, acctXtrId, external\)/);
&tryBadOptValue(by => [ "acctSrc", "source", "acctXtrId", "internal" ]);
ok($@, qr/^Option 'by' contains a right-side field 'internal' that is not in the index key,
  right key: \(source, external\)
  by: \(acctSrc, source, acctXtrId, internal\)/);
&tryBadOptValue(byLeft => [ "id/source", "acctXtrId/external" ]);
ok($@, qr/^Option 'byLeft' contains a left-side field 'id' that is not in the index key,
  left key: \(acctSrc, acctXtrId\)
  by: \(id, source, acctXtrId, external\)/);
&tryBadOptValue(byLeft => [ "acctSrc/source", "acctXtrId/internal" ]);
ok($@, qr/^Option 'byLeft' contains a right-side field 'internal' that is not in the index key,
  right key: \(source, external\)
  by: \(acctSrc, source, acctXtrId, internal\)/);

{
	my $rtVaried = Triceps::RowType->new(
		a => "uint8",
		aa => "uint8[]",
		b => "int32",
		bb => "int32[]",
		c => "int64",
		cc => "int64[]",
		d => "float64",
		dd => "float64[]",
		e => "string",
	);
	ok(ref $rtVaried, "Triceps::RowType");
		
	my $ttVaried = Triceps::TableType->new($rtVaried)
		->addSubIndex("a",
			Triceps::IndexType->newHashed(key => [ "a" ])
		)
		->addSubIndex("aa",
			Triceps::IndexType->newHashed(key => [ "aa" ])
		)
		->addSubIndex("b",
			Triceps::IndexType->newHashed(key => [ "b" ])
		)
		->addSubIndex("bb",
			Triceps::IndexType->newHashed(key => [ "bb" ])
		)
		->addSubIndex("c",
			Triceps::IndexType->newHashed(key => [ "c" ])
		)
		->addSubIndex("cc",
			Triceps::IndexType->newHashed(key => [ "cc" ])
		)
		->addSubIndex("e",
			Triceps::IndexType->newHashed(key => [ "e" ])
		)
	; 
	ok(ref $ttVaried, "Triceps::TableType");

	$res = $ttVaried->initialize();
	ok($res, 1);

	my $t1 = $vu3->makeTable($ttVaried, "t1");
	ok(ref $t1, "Triceps::Table");
	my $t2 = $vu3->makeTable($ttVaried, "t2");
	ok(ref $t2, "Triceps::Table");

	&tryBadOptValue(
		leftTable => $t1,
		leftIdxPath => [ "a" ],
		rightTable => $t2,
		rightIdxPath => [ "b" ],
	);
	ok($@, qr/^Mismatched field types in the join condition: left a uint8, right b int32/);

	&tryBadOptValue(
		leftTable => $t1,
		leftIdxPath => [ "c" ],
		rightTable => $t2,
		rightIdxPath => [ "b" ],
	);
	ok($@, qr/^Mismatched field types in the join condition: left c int64, right b int32/);

	&tryBadOptValue(
		leftTable => $t1,
		leftIdxPath => [ "bb" ],
		rightTable => $t2,
		rightIdxPath => [ "b" ],
	);
	ok($@, qr/^Mismatched field types in the join condition: left bb int32\[\], right b int32/);

	&tryBadOptValue(
		leftTable => $t1,
		leftIdxPath => [ "bb" ],
		rightTable => $t2,
		rightIdxPath => [ "b" ],
		overrideKeyTypes => 1,
	);
	ok($@, qr/^Mismatched array and scalar fields in the join condition: left bb int32\[\], right b int32/);

	&tryBadOptValue(
		leftTable => $t1,
		leftIdxPath => [ "a" ],
		rightTable => $t2,
		rightIdxPath => [ "aa" ],
	);
	ok($@, qr/^Mismatched field types in the join condition: left a uint8, right aa uint8\[\]/);

	&tryBadOptValue(
		leftTable => $t1,
		leftIdxPath => [ "e" ],
		rightTable => $t2,
		rightIdxPath => [ "aa" ],
	);
	ok($@, qr/^Mismatched field types in the join condition: left e string, right aa uint8\[\]/);

	# now test the good ones
	my $join;

	$join = Triceps::JoinTwo->new(
		name => "join",
		leftTable => $t1,
		leftIdxPath => [ "c" ],
		rightTable => $t2,
		rightIdxPath => [ "b" ],
		rightFields => [ "!.*" ],
		overrideKeyTypes => 1,
	);
	ok(ref $join, "Triceps::JoinTwo");

	$join = Triceps::JoinTwo->new(
		name => "join",
		leftTable => $t1,
		leftIdxPath => [ "a" ],
		rightTable => $t2,
		rightIdxPath => [ "aa" ],
		rightFields => [ "!.*" ],
		overrideKeyTypes => 1,
	);
	ok(ref $join, "Triceps::JoinTwo");

	$join = Triceps::JoinTwo->new(
		name => "join",
		leftTable => $t1,
		leftIdxPath => [ "e" ],
		rightTable => $t2,
		rightIdxPath => [ "aa" ],
		rightFields => [ "!.*" ],
		overrideKeyTypes => 1,
	);
	ok(ref $join, "Triceps::JoinTwo");
}

&tryBadOptValue(fieldsUniqKey => "xxx");
ok($@, qr/^Unknown value 'xxx' of option 'fieldsUniqKey', must be one of none|manual|left|right|first/);
#print STDERR "$@\n";

#########
# clearing
# MUST BE LAST because it will destroy everything in the unit

{
	my $join = Triceps::JoinTwo->new( 
		name => "join",
		leftTable => $tTrans3,
		rightTable => $tAccounts3,
		leftIdxPath => ["byAccount"],
		rightIdxPath => ["lookupSrcExt"],
	);
	ok(ref $join, "Triceps::JoinTwo");
	ok(exists $join->{unit});

	$vu3->clearLabels();
	ok(!exists $join->{unit});
}

