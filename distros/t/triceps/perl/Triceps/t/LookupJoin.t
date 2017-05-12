#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# An use example of joins between a data stream and a table.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 248 };
use Triceps;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#########################

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

#######################################################################
# 1. A hardcoded manual left join using a primary key on the right.
# Performs the look-up of the internal "canonical" account ids from the
# external ones, coming from different system.

# incoming data:
@defInTrans = ( # a transaction received
	acctSrc => "string", # external system that sent us a transaction
	acctXtrId => "string", # its name of the account of the transaction
	amount => "int32", # the amount of transaction (int is easier to check)
);
$rtInTrans = Triceps::RowType->new(
	@defInTrans
);
ok(ref $rtInTrans, "Triceps::RowType");

@incomingData = (
	[ "source1", "999", 100 ], 
	[ "source2", "ABCD", 200 ], 
	[ "source3", "ZZZZ", 300 ], 
	[ "source1", "2011", 400 ], 
	[ "source2", "ZZZZ", 500 ], 
);

# result data:
@defOutTrans = ( # a transaction received
	@defInTrans, # just add a field to an existing definition
	acct => "int32", # our internal account id
);
$rtOutTrans = Triceps::RowType->new(
	@defOutTrans
);
ok(ref $rtOutTrans, "Triceps::RowType");

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
	
@accountData = (
	[ "source1", "999", 1 ],
	[ "source1", "2011", 2 ],
	[ "source1", "42", 3 ],
	[ "source2", "ABCD", 1 ],
	[ "source2", "QWERTY", 2 ],
	[ "source2", "UIOP", 4 ],
);

### here goes the code

$vu1 = Triceps::Unit->new("vu1");
ok(ref $vu1, "Triceps::Unit");

# this will record the results
my $result1;

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

$tAccounts = $vu1->makeTable($ttAccounts, "Accounts");
ok(ref $tAccounts, "Triceps::Table");

# function to perform the join
# @param resultLab - label to send the result
# @param enqMode - enqueueing mode for the result
sub join1 # ($label, $rowop, $resultLab, $enqMode)
{
	my ($label, $rowop, $resultLab, $enqMode) = @_;

	$result1 .= $rowop->printP() . "\n";

	my %rowdata = $rowop->getRow()->toHash(); # result easier to handle manually than from toArray
	my $intacct; # if lookup fails, may be undef, since it's a left join
	# perform the look-up
	my $lookupRow = $rtAccounts->makeRowHash(
		source => $rowdata{acctSrc},
		external => $rowdata{acctXtrId},
	);
	my $acctrh = $tAccounts->findIdx($idxAccountsLookup, $lookupRow);
	# if the translation is not found, in production it might be useful
	# to send the record to the error handling logic instead
	if (!$acctrh->isNull()) { 
		$intacct = $acctrh->getRow()->get("internal");
	}
	# create the result
	my $resultRow = $rtOutTrans->makeRowHash(
		%rowdata,
		acct => $intacct,
	);
	my $resultRowop = $resultLab->makeRowop($rowop->getOpcode(), # pass the opcode
		$resultRow);
	$resultLab->getUnit()->enqueue($enqMode, $resultRowop);
}

my $outlab1 = $vu1->makeLabel($rtOutTrans, "out", undef, sub { $result1 .= $_[1]->printP() . "\n" } );
ok(ref $outlab1, "Triceps::Label");

my $inlab1 = $vu1->makeLabel($rtInTrans, "in", undef, \&join1, $outlab1, &Triceps::EM_CALL);
ok(ref $inlab1, "Triceps::Label");

# fill the accounts table
&feedInput($tAccounts->getInputLabel(), &Triceps::OP_INSERT, \@accountData);
$vu1->drainFrame();
ok($vu1->empty());

# feed the data
&feedInput($inlab1, &Triceps::OP_INSERT, \@incomingData);
&feedInput($inlab1, &Triceps::OP_DELETE, \@incomingData);
$vu1->drainFrame();
ok($vu1->empty());

#print STDERR $result1;
$expect1 = 
'in OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" 
out OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" acct="1" 
in OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" 
out OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" acct="1" 
in OP_INSERT acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
out OP_INSERT acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
in OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" 
out OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" acct="2" 
in OP_INSERT acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
out OP_INSERT acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
in OP_DELETE acctSrc="source1" acctXtrId="999" amount="100" 
out OP_DELETE acctSrc="source1" acctXtrId="999" amount="100" acct="1" 
in OP_DELETE acctSrc="source2" acctXtrId="ABCD" amount="200" 
out OP_DELETE acctSrc="source2" acctXtrId="ABCD" amount="200" acct="1" 
in OP_DELETE acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
out OP_DELETE acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
in OP_DELETE acctSrc="source1" acctXtrId="2011" amount="400" 
out OP_DELETE acctSrc="source1" acctXtrId="2011" amount="400" acct="2" 
in OP_DELETE acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
out OP_DELETE acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
';
ok($result1, $expect1);

#######################################################################
# 2. A class for the straightforward stream-to-table lookup
# It had come out with a kind of wide functionality, so it would
# require multiple tests, marked by letters ("2a" etc.).
# The class is Triceps::LookupJoin.

# the data definitions and examples are shared with example (1)

$vu2 = Triceps::Unit->new("vu2");
ok(ref $vu2, "Triceps::Unit");

# this will record the results
my $result2;

# the accounts table type is also reused from example (1)
$tAccounts2 = $vu2->makeTable($ttAccounts, "Accounts");
ok(ref $tAccounts2, "Triceps::Table");

#########
# (2a) left join with an exactly-matching key that automatically triggers
# the limitOne flag to be true, using the direct lookup() call

$join2ab = Triceps::LookupJoin->new( # will be used in both (2a) and (2b)
	unit => $vu2,
	name => "join2ab",
	leftRowType => $rtInTrans,
	rightTable => $tAccounts2,
	rightIdxPath => ["lookupSrcExt"],
	rightFields => [ "internal/acct" ],
	by => [ "acctSrc" => "source", "acctXtrId" => "external" ],
	isLeft => 1,
	automatic => 0,
);
ok(ref $join2ab, "Triceps::LookupJoin");

sub calljoin2 # ($label, $rowop, $join, $resultLab)
{
	my ($label, $rowop, $join, $resultLab) = @_;

	$result2 .= $rowop->printP() . "\n";

	my $opcode = $rowop->getOpcode(); # pass the opcode

	my @resRows = $join->lookup($rowop->getRow());
	foreach my $resultRow( @resRows ) {
		$resultLab->getUnit()->call($resultLab->makeRowop($opcode, $resultRow));
	}
}

my $outlab2a = $vu2->makeLabel($join2ab->getResultRowType(), "out", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $outlab2a, "Triceps::Label");

my $inlab2a = $vu2->makeLabel($rtInTrans, "in", undef, \&calljoin2, $join2ab, $outlab2a);
ok(ref $inlab2a, "Triceps::Label");

# fill the accounts table
&feedInput($tAccounts2->getInputLabel(), &Triceps::OP_INSERT, \@accountData);
$vu2->drainFrame();
ok($vu2->empty());

# feed the data
&feedInput($inlab2a, &Triceps::OP_INSERT, \@incomingData);
&feedInput($inlab2a, &Triceps::OP_DELETE, \@incomingData);
$vu2->drainFrame();
ok($vu2->empty());

#print STDERR $result2;
# expect same result as in test 1
ok($result2, $expect1);

#########
# define the labels for (2b), doing it only once

my $outlab2b = $vu2->makeLabel($join2ab->getResultRowType(), "out", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $outlab2b, "Triceps::Label");

ok(ref $join2ab->getInputLabel(), "Triceps::Label");
ok(ref $join2ab->getOutputLabel(), "Triceps::Label");

# the output
$join2ab->getOutputLabel()->chain($outlab2b);

# this is purely to keep track of the input in the log
my $inlab2b = $vu2->makeLabel($rtInTrans, "in", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $inlab2b, "Triceps::Label");
$inlab2b->chain($join2ab->getInputLabel());


###############################################################
# Now repeat the test 2a and preparation for 2b but with fieldsMirrorKey==1, and 
# to see its result with a copy of all the fields on the right.

#########
# (2xa) left join with an exactly-matching key that automatically triggers
# the limitOne flag to be true, using the direct lookup() call

$join2xab = Triceps::LookupJoin->new( # will be used in both (2xa) and (2xb)
	unit => $vu2,
	name => "join2xab",
	leftRowType => $rtInTrans,
	rightTable => $tAccounts2,
	rightIdxPath => ["lookupSrcExt"],
	by => [ "acctSrc" => "source", "acctXtrId" => "external" ],
	isLeft => 1,
	automatic => 0,
	fieldsMirrorKey => 1,
);
ok(ref $join2xab, "Triceps::LookupJoin");

sub calljoin2x # ($label, $rowop, $join, $resultLab)
{
	my ($label, $rowop, $join, $resultLab) = @_;

	$result2 .= $rowop->printP() . "\n";

	my $opcode = $rowop->getOpcode(); # pass the opcode

	my @resRows = $join->lookup($rowop->getRow());
	foreach my $resultRow( @resRows ) {
		$resultLab->getUnit()->call($resultLab->makeRowop($opcode, $resultRow));
	}
}

my $outlab2xa = $vu2->makeLabel($join2xab->getResultRowType(), "out", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $outlab2xa, "Triceps::Label");

my $inlab2xa = $vu2->makeLabel($rtInTrans, "in", undef, \&calljoin2x, $join2xab, $outlab2xa);
ok(ref $inlab2xa, "Triceps::Label");

undef $result2;
# feed the data
&feedInput($inlab2xa, &Triceps::OP_INSERT, \@incomingData);
&feedInput($inlab2xa, &Triceps::OP_DELETE, \@incomingData);
$vu2->drainFrame();
ok($vu2->empty());

#print STDERR $result2;
$expect2xa = 
'in OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" 
out OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" source="source1" external="999" internal="1" 
in OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" 
out OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" source="source2" external="ABCD" internal="1" 
in OP_INSERT acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
out OP_INSERT acctSrc="source3" acctXtrId="ZZZZ" amount="300" source="source3" external="ZZZZ" 
in OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" 
out OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" source="source1" external="2011" internal="2" 
in OP_INSERT acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
out OP_INSERT acctSrc="source2" acctXtrId="ZZZZ" amount="500" source="source2" external="ZZZZ" 
in OP_DELETE acctSrc="source1" acctXtrId="999" amount="100" 
out OP_DELETE acctSrc="source1" acctXtrId="999" amount="100" source="source1" external="999" internal="1" 
in OP_DELETE acctSrc="source2" acctXtrId="ABCD" amount="200" 
out OP_DELETE acctSrc="source2" acctXtrId="ABCD" amount="200" source="source2" external="ABCD" internal="1" 
in OP_DELETE acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
out OP_DELETE acctSrc="source3" acctXtrId="ZZZZ" amount="300" source="source3" external="ZZZZ" 
in OP_DELETE acctSrc="source1" acctXtrId="2011" amount="400" 
out OP_DELETE acctSrc="source1" acctXtrId="2011" amount="400" source="source1" external="2011" internal="2" 
in OP_DELETE acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
out OP_DELETE acctSrc="source2" acctXtrId="ZZZZ" amount="500" source="source2" external="ZZZZ" 
';
ok($result2, $expect2xa);

#########
# define the labels for (2xb), doing it only once

my $outlab2xb = $vu2->makeLabel($join2xab->getResultRowType(), "out", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $outlab2xb, "Triceps::Label");

ok(ref $join2xab->getInputLabel(), "Triceps::Label");
ok(ref $join2xab->getOutputLabel(), "Triceps::Label");

# the output
$join2xab->getOutputLabel()->chain($outlab2xb);

# this is purely to keep track of the input in the log
my $inlab2xb = $vu2->makeLabel($rtInTrans, "in", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $inlab2xb, "Triceps::Label");
$inlab2xb->chain($join2xab->getInputLabel());



#########
# the other tests can be done in both automatic mode and not, so repeat both
sub automaticAndNot # ($auto)
{
my $auto = shift;

#########
# (2b) Exact same as 2a, even reuse the same join, but work through its labels

undef $result2;
# feed the data
&feedInput($inlab2b, &Triceps::OP_INSERT, \@incomingData);
&feedInput($inlab2b, &Triceps::OP_DELETE, \@incomingData);
$vu2->drainFrame();
ok($vu2->empty());

#print STDERR $result2;
# expect same result as in test 1, except for different label names
# (since when a rowop is printed, it prints the name of the label for which it was created)
$expect2b = $expect1;
$expect2b =~ s/out OP/join2ab.out OP/g;
ok($result2, $expect2b);


#########
# (2c) inner join with an exactly-matching key that automatically triggers
# the limitOne flag to be true, using the labels;
# along the way test byLeft

# reuses the same table, whih is already populated

$join2c = Triceps::LookupJoin->new(
	unit => $vu2,
	name => "join2c",
	leftRowType => $rtInTrans,
	rightTable => $tAccounts2,
	rightIdxPath => ["lookupSrcExt"],
	rightFields => [ "internal/acct" ],
	byLeft => [ "acctSrc/source", "acctXtrId/external" ],
	isLeft => 0,
	automatic => $auto,
);
ok(ref $join2c, "Triceps::LookupJoin");

my $outlab2c = $vu2->makeLabel($join2c->getResultRowType(), "out", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $outlab2c, "Triceps::Label");

ok(ref $join2c->getInputLabel(), "Triceps::Label");
ok(ref $join2c->getOutputLabel(), "Triceps::Label");

# the output
$join2c->getOutputLabel()->chain($outlab2c);

# this is purely to keep track of the input in the log
my $inlab2c = $vu2->makeLabel($rtInTrans, "in", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $inlab2c, "Triceps::Label");
$inlab2c->chain($join2c->getInputLabel());

undef $result2;
# feed the data
&feedInput($inlab2c, &Triceps::OP_INSERT, \@incomingData);
&feedInput($inlab2c, &Triceps::OP_DELETE, \@incomingData);
$vu2->drainFrame();
ok($vu2->empty());

#print STDERR $result2;
# now the rows with empty right side must be missing
$expect2c = 
'in OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" 
join2c.out OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" acct="1" 
in OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" 
join2c.out OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" acct="1" 
in OP_INSERT acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
in OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" 
join2c.out OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" acct="2" 
in OP_INSERT acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
in OP_DELETE acctSrc="source1" acctXtrId="999" amount="100" 
join2c.out OP_DELETE acctSrc="source1" acctXtrId="999" amount="100" acct="1" 
in OP_DELETE acctSrc="source2" acctXtrId="ABCD" amount="200" 
join2c.out OP_DELETE acctSrc="source2" acctXtrId="ABCD" amount="200" acct="1" 
in OP_DELETE acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
in OP_DELETE acctSrc="source1" acctXtrId="2011" amount="400" 
join2c.out OP_DELETE acctSrc="source1" acctXtrId="2011" amount="400" acct="2" 
in OP_DELETE acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
';
ok($result2, $expect2c);

#########
# (2d) inner join with limitOne = 0

# the accounts table will have 2 copies of each record, for tests (d) and (e)
$ttAccounts2de = Triceps::TableType->new($rtAccounts)
	# muliple indexes can be defined for different purposes
	# (though of course each extra index adds overhead)
	->addSubIndex("lookupSrcExt", # quick look-up by source and external id
		Triceps::IndexType->newHashed(key => [ "source", "external" ])
		->addSubIndex("fifo", Triceps::IndexType->newFifo())
	)
; 
ok(ref $ttAccounts2de, "Triceps::TableType");

$res = $ttAccounts2de->initialize();
ok($res, 1);

$tAccounts2de = $vu2->makeTable($ttAccounts2de, "Accounts2de");
ok(ref $tAccounts2de, "Triceps::Table");

# fill the accounts table
&feedInput($tAccounts2de->getInputLabel(), &Triceps::OP_INSERT, \@accountData);
@accountData2de = ( # the second records, with different internal accounts
	[ "source1", "999", 11 ],
	[ "source1", "2011", 12 ],
	[ "source1", "42", 13 ],
	[ "source2", "ABCD", 11 ],
	[ "source2", "QWERTY", 12 ],
	[ "source2", "UIOP", 14 ],
);
&feedInput($tAccounts2de->getInputLabel(), &Triceps::OP_INSERT, \@accountData2de);
$vu2->drainFrame();
ok($vu2->empty());

# inner join with no limit to 1 record
$join2d = Triceps::LookupJoin->new(
	unit => $vu2,
	name => "join2d",
	leftRowType => $rtInTrans,
	rightTable => $tAccounts2de,
	rightIdxPath => ["lookupSrcExt"],
	rightFields => [ "internal/acct" ],
	by => [ "acctSrc" => "source", "acctXtrId" => "external" ],
	isLeft => 0,
	automatic => $auto,
);
ok(ref $join2d, "Triceps::LookupJoin");

my $outlab2d = $vu2->makeLabel($join2d->getResultRowType(), "out", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $outlab2d, "Triceps::Label");

# the output
$join2d->getOutputLabel()->chain($outlab2d);

# this is purely to keep track of the input in the log
my $inlab2d = $vu2->makeLabel($rtInTrans, "in", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $inlab2d, "Triceps::Label");
$inlab2d->chain($join2d->getInputLabel());

undef $result2;
# feed the data
&feedInput($inlab2d, &Triceps::OP_INSERT, \@incomingData);
&feedInput($inlab2d, &Triceps::OP_DELETE, \@incomingData);
$vu2->drainFrame();
ok($vu2->empty());

#print STDERR $result2;
# now the rows with empty right side must be missing
$expect2d = 
'in OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" 
join2d.out OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" acct="1" 
join2d.out OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" acct="11" 
in OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" 
join2d.out OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" acct="1" 
join2d.out OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" acct="11" 
in OP_INSERT acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
in OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" 
join2d.out OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" acct="2" 
join2d.out OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" acct="12" 
in OP_INSERT acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
in OP_DELETE acctSrc="source1" acctXtrId="999" amount="100" 
join2d.out OP_DELETE acctSrc="source1" acctXtrId="999" amount="100" acct="1" 
join2d.out OP_DELETE acctSrc="source1" acctXtrId="999" amount="100" acct="11" 
in OP_DELETE acctSrc="source2" acctXtrId="ABCD" amount="200" 
join2d.out OP_DELETE acctSrc="source2" acctXtrId="ABCD" amount="200" acct="1" 
join2d.out OP_DELETE acctSrc="source2" acctXtrId="ABCD" amount="200" acct="11" 
in OP_DELETE acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
in OP_DELETE acctSrc="source1" acctXtrId="2011" amount="400" 
join2d.out OP_DELETE acctSrc="source1" acctXtrId="2011" amount="400" acct="2" 
join2d.out OP_DELETE acctSrc="source1" acctXtrId="2011" amount="400" acct="12" 
in OP_DELETE acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
';
ok($result2, $expect2d);

#########
# (2e) left join with limitOne = 0

# left join with no limit to 1 record
$join2e = Triceps::LookupJoin->new(
	unit => $vu2,
	name => "join2e",
	leftRowType => $rtInTrans,
	rightTable => $tAccounts2de,
	rightIdxPath => ["lookupSrcExt"],
	rightFields => [ "internal/acct" ],
	by => [ "acctSrc" => "source", "acctXtrId" => "external" ],
	isLeft => 1,
	automatic => $auto,
);
ok(ref $join2e, "Triceps::LookupJoin");

my $outlab2e = $vu2->makeLabel($join2e->getResultRowType(), "out", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $outlab2e, "Triceps::Label");

# the output
$join2e->getOutputLabel()->chain($outlab2e);

# this is purely to keep track of the input in the log
my $inlab2e = $vu2->makeLabel($rtInTrans, "in", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $inlab2e, "Triceps::Label");
$inlab2e->chain($join2e->getInputLabel());

undef $result2;
# feed the data
&feedInput($inlab2e, &Triceps::OP_INSERT, \@incomingData);
&feedInput($inlab2e, &Triceps::OP_DELETE, \@incomingData);
$vu2->drainFrame();
ok($vu2->empty());

#print STDERR $result2;
$expect2e = 
'in OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" 
join2e.out OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" acct="1" 
join2e.out OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" acct="11" 
in OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" 
join2e.out OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" acct="1" 
join2e.out OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" acct="11" 
in OP_INSERT acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
join2e.out OP_INSERT acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
in OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" 
join2e.out OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" acct="2" 
join2e.out OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" acct="12" 
in OP_INSERT acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
join2e.out OP_INSERT acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
in OP_DELETE acctSrc="source1" acctXtrId="999" amount="100" 
join2e.out OP_DELETE acctSrc="source1" acctXtrId="999" amount="100" acct="1" 
join2e.out OP_DELETE acctSrc="source1" acctXtrId="999" amount="100" acct="11" 
in OP_DELETE acctSrc="source2" acctXtrId="ABCD" amount="200" 
join2e.out OP_DELETE acctSrc="source2" acctXtrId="ABCD" amount="200" acct="1" 
join2e.out OP_DELETE acctSrc="source2" acctXtrId="ABCD" amount="200" acct="11" 
in OP_DELETE acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
join2e.out OP_DELETE acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
in OP_DELETE acctSrc="source1" acctXtrId="2011" amount="400" 
join2e.out OP_DELETE acctSrc="source1" acctXtrId="2011" amount="400" acct="2" 
join2e.out OP_DELETE acctSrc="source1" acctXtrId="2011" amount="400" acct="12" 
in OP_DELETE acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
join2e.out OP_DELETE acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
';
ok($result2, $expect2e);

#########
# (2f) left join with limitOne = 1, and multiple records available
# also test the leftFromLabel here

# this is purely to keep track of the input in the log
my $inlab2f = $vu2->makeLabel($rtInTrans, "in", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $inlab2f, "Triceps::Label");

$join2f = Triceps::LookupJoin->new(
	name => "join2f",
	leftFromLabel => $inlab2f,
	rightTable => $tAccounts2de,
	rightIdxPath => ["lookupSrcExt"],
	rightFields => [ "internal/acct" ],
	by => [ "acctSrc" => "source", "acctXtrId" => "external" ],
	isLeft => 1,
	limitOne => 1,
	automatic => $auto,
);
ok(ref $join2f, "Triceps::LookupJoin");

my $outlab2f = $vu2->makeLabel($join2f->getResultRowType(), "out", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $outlab2f, "Triceps::Label");

# the output
$join2f->getOutputLabel()->chain($outlab2f);

undef $result2;
# feed the data
&feedInput($inlab2f, &Triceps::OP_INSERT, \@incomingData);
&feedInput($inlab2f, &Triceps::OP_DELETE, \@incomingData);
$vu2->drainFrame();
ok($vu2->empty());

#print STDERR $result2;
$expect2f = 
'in OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" 
join2f.out OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" acct="1" 
in OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" 
join2f.out OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" acct="1" 
in OP_INSERT acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
join2f.out OP_INSERT acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
in OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" 
join2f.out OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" acct="2" 
in OP_INSERT acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
join2f.out OP_INSERT acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
in OP_DELETE acctSrc="source1" acctXtrId="999" amount="100" 
join2f.out OP_DELETE acctSrc="source1" acctXtrId="999" amount="100" acct="1" 
in OP_DELETE acctSrc="source2" acctXtrId="ABCD" amount="200" 
join2f.out OP_DELETE acctSrc="source2" acctXtrId="ABCD" amount="200" acct="1" 
in OP_DELETE acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
join2f.out OP_DELETE acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
in OP_DELETE acctSrc="source1" acctXtrId="2011" amount="400" 
join2f.out OP_DELETE acctSrc="source1" acctXtrId="2011" amount="400" acct="2" 
in OP_DELETE acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
join2f.out OP_DELETE acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
';
ok($result2, $expect2f);

#########
# (2g) Use an automatically-found index that is not the first one.
# The "by" condition is really a weird abuse here, used simple because
# the types of these fields match.

# this is purely to keep track of the input in the log
my $inlab2g = $vu2->makeLabel($rtInTrans, "in", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $inlab2g, "Triceps::Label");

$join2g = Triceps::LookupJoin->new(
	name => "join2g",
	leftFromLabel => $inlab2g,
	rightTable => $tAccounts,
	byLeft => [ "amount/internal" ],
	isLeft => 1,
	automatic => $auto,
);
ok(ref $join2g, "Triceps::LookupJoin");

my $outlab2g = $vu2->makeLabel($join2g->getResultRowType(), "out", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $outlab2g, "Triceps::Label");

# the output
$join2g->getOutputLabel()->chain($outlab2g);

undef $result2;
# feed the data
@incomingData2g = (
	[ "source1", "999", 1 ], 
	[ "source2", "ABCD", 2 ], 
	[ "source3", "ZZZZ", 3 ], 
);
&feedInput($inlab2g, &Triceps::OP_INSERT, \@incomingData2g);
$vu2->drainFrame();
ok($vu2->empty());

#print STDERR $result2;
$expect2g = 
'in OP_INSERT acctSrc="source1" acctXtrId="999" amount="1" 
join2g.out OP_INSERT acctSrc="source1" acctXtrId="999" amount="1" source="source1" external="999" internal="1" 
join2g.out OP_INSERT acctSrc="source1" acctXtrId="999" amount="1" source="source2" external="ABCD" internal="1" 
in OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="2" 
join2g.out OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="2" source="source1" external="2011" internal="2" 
join2g.out OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="2" source="source2" external="QWERTY" internal="2" 
in OP_INSERT acctSrc="source3" acctXtrId="ZZZZ" amount="3" 
join2g.out OP_INSERT acctSrc="source3" acctXtrId="ZZZZ" amount="3" source="source1" external="42" internal="3" 
';
ok($result2, $expect2g);

###############################################################
# Now repeat all the same but with fieldsMirrorKey==1, and 
# to see its result with a copy of all the fields on the right.

#########
# (2xb) Exact same as 2xa, even reuse the same join, but work through its labels

undef $result2;
# feed the data
&feedInput($inlab2xb, &Triceps::OP_INSERT, \@incomingData);
&feedInput($inlab2xb, &Triceps::OP_DELETE, \@incomingData);
$vu2->drainFrame();
ok($vu2->empty());

#print STDERR $result2;
# expect same result as in test 1, except for different label names
# (since when a rowop is printed, it prints the name of the label for which it was created)
$expect2xb = $expect2xa;
$expect2xb =~ s/out OP/join2xab.out OP/g;
ok($result2, $expect2xb);


#########
# (2xc) inner join with an exactly-matching key that automatically triggers
# the limitOne flag to be true, using the labels

# reuses the same table, whih is already populated

$join2xc = Triceps::LookupJoin->new(
	unit => $vu2,
	name => "join2xc",
	leftRowType => $rtInTrans,
	rightTable => $tAccounts2,
	rightIdxPath => ["lookupSrcExt"],
	by => [ "acctSrc" => "source", "acctXtrId" => "external" ],
	isLeft => 0,
	automatic => $auto,
	fieldsMirrorKey => 1,
);
ok(ref $join2xc, "Triceps::LookupJoin");

my $outlab2xc = $vu2->makeLabel($join2xc->getResultRowType(), "out", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $outlab2xc, "Triceps::Label");

ok(ref $join2xc->getInputLabel(), "Triceps::Label");
ok(ref $join2xc->getOutputLabel(), "Triceps::Label");

# the output
$join2xc->getOutputLabel()->chain($outlab2xc);

# this is purely to keep track of the input in the log
my $inlab2xc = $vu2->makeLabel($rtInTrans, "in", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $inlab2xc, "Triceps::Label");
$inlab2xc->chain($join2xc->getInputLabel());

undef $result2;
# feed the data
&feedInput($inlab2xc, &Triceps::OP_INSERT, \@incomingData);
&feedInput($inlab2xc, &Triceps::OP_DELETE, \@incomingData);
$vu2->drainFrame();
ok($vu2->empty());

#print STDERR $result2;
# now the rows with empty right side must be missing
$expect2xc = 
'in OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" 
join2xc.out OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" source="source1" external="999" internal="1" 
in OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" 
join2xc.out OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" source="source2" external="ABCD" internal="1" 
in OP_INSERT acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
in OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" 
join2xc.out OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" source="source1" external="2011" internal="2" 
in OP_INSERT acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
in OP_DELETE acctSrc="source1" acctXtrId="999" amount="100" 
join2xc.out OP_DELETE acctSrc="source1" acctXtrId="999" amount="100" source="source1" external="999" internal="1" 
in OP_DELETE acctSrc="source2" acctXtrId="ABCD" amount="200" 
join2xc.out OP_DELETE acctSrc="source2" acctXtrId="ABCD" amount="200" source="source2" external="ABCD" internal="1" 
in OP_DELETE acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
in OP_DELETE acctSrc="source1" acctXtrId="2011" amount="400" 
join2xc.out OP_DELETE acctSrc="source1" acctXtrId="2011" amount="400" source="source1" external="2011" internal="2" 
in OP_DELETE acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
';
ok($result2, $expect2xc);

#########
# (2xd) inner join with limitOne = 0

# the accounts table will have 2 copies of each record, for tests (d) and (e)
$ttAccounts2xde = Triceps::TableType->new($rtAccounts)
	# muliple indexes can be defined for different purposes
	# (though of course each extra index adds overhead)
	->addSubIndex("lookupSrcExt", # quick look-up by source and external id
		Triceps::IndexType->newHashed(key => [ "source", "external" ])
		->addSubIndex("fifo", Triceps::IndexType->newFifo())
	)
; 
ok(ref $ttAccounts2xde, "Triceps::TableType");

$res = $ttAccounts2xde->initialize();
ok($res, 1);

$tAccounts2xde = $vu2->makeTable($ttAccounts2xde, "Accounts2xde");
ok(ref $tAccounts2xde, "Triceps::Table");

# fill the accounts table
&feedInput($tAccounts2xde->getInputLabel(), &Triceps::OP_INSERT, \@accountData);
@accountData2xde = ( # the second records, with different internal accounts
	[ "source1", "999", 11 ],
	[ "source1", "2011", 12 ],
	[ "source1", "42", 13 ],
	[ "source2", "ABCD", 11 ],
	[ "source2", "QWERTY", 12 ],
	[ "source2", "UIOP", 14 ],
);
&feedInput($tAccounts2xde->getInputLabel(), &Triceps::OP_INSERT, \@accountData2xde);
$vu2->drainFrame();
ok($vu2->empty());

# inner join with no limit to 1 record
$join2xd = Triceps::LookupJoin->new(
	unit => $vu2,
	name => "join2xd",
	leftRowType => $rtInTrans,
	rightTable => $tAccounts2xde,
	rightIdxPath => ["lookupSrcExt"],
	by => [ "acctSrc" => "source", "acctXtrId" => "external" ],
	isLeft => 0,
	automatic => $auto,
	fieldsMirrorKey => 1,
);
ok(ref $join2xd, "Triceps::LookupJoin");

my $outlab2xd = $vu2->makeLabel($join2xd->getResultRowType(), "out", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $outlab2xd, "Triceps::Label");

# the output
$join2xd->getOutputLabel()->chain($outlab2xd);

# this is purely to keep track of the input in the log
my $inlab2xd = $vu2->makeLabel($rtInTrans, "in", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $inlab2xd, "Triceps::Label");
$inlab2xd->chain($join2xd->getInputLabel());

undef $result2;
# feed the data
&feedInput($inlab2xd, &Triceps::OP_INSERT, \@incomingData);
&feedInput($inlab2xd, &Triceps::OP_DELETE, \@incomingData);
$vu2->drainFrame();
ok($vu2->empty());

#print STDERR $result2;
# now the rows with empty right side must be missing
$expect2xd = 
'in OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" 
join2xd.out OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" source="source1" external="999" internal="1" 
join2xd.out OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" source="source1" external="999" internal="11" 
in OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" 
join2xd.out OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" source="source2" external="ABCD" internal="1" 
join2xd.out OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" source="source2" external="ABCD" internal="11" 
in OP_INSERT acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
in OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" 
join2xd.out OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" source="source1" external="2011" internal="2" 
join2xd.out OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" source="source1" external="2011" internal="12" 
in OP_INSERT acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
in OP_DELETE acctSrc="source1" acctXtrId="999" amount="100" 
join2xd.out OP_DELETE acctSrc="source1" acctXtrId="999" amount="100" source="source1" external="999" internal="1" 
join2xd.out OP_DELETE acctSrc="source1" acctXtrId="999" amount="100" source="source1" external="999" internal="11" 
in OP_DELETE acctSrc="source2" acctXtrId="ABCD" amount="200" 
join2xd.out OP_DELETE acctSrc="source2" acctXtrId="ABCD" amount="200" source="source2" external="ABCD" internal="1" 
join2xd.out OP_DELETE acctSrc="source2" acctXtrId="ABCD" amount="200" source="source2" external="ABCD" internal="11" 
in OP_DELETE acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
in OP_DELETE acctSrc="source1" acctXtrId="2011" amount="400" 
join2xd.out OP_DELETE acctSrc="source1" acctXtrId="2011" amount="400" source="source1" external="2011" internal="2" 
join2xd.out OP_DELETE acctSrc="source1" acctXtrId="2011" amount="400" source="source1" external="2011" internal="12" 
in OP_DELETE acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
';
ok($result2, $expect2xd);

#########
# (2xe) left join with limitOne = 0

# left join with no limit to 1 record
$join2xe = Triceps::LookupJoin->new(
	unit => $vu2,
	name => "join2xe",
	leftRowType => $rtInTrans,
	rightTable => $tAccounts2xde,
	rightIdxPath => ["lookupSrcExt"],
	by => [ "acctSrc" => "source", "acctXtrId" => "external" ],
	isLeft => 1,
	automatic => $auto,
	fieldsMirrorKey => 1,
);
ok(ref $join2xe, "Triceps::LookupJoin");

my $outlab2xe = $vu2->makeLabel($join2xe->getResultRowType(), "out", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $outlab2xe, "Triceps::Label");

# the output
$join2xe->getOutputLabel()->chain($outlab2xe);

# this is purely to keep track of the input in the log
my $inlab2xe = $vu2->makeLabel($rtInTrans, "in", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $inlab2xe, "Triceps::Label");
$inlab2xe->chain($join2xe->getInputLabel());

undef $result2;
# feed the data
&feedInput($inlab2xe, &Triceps::OP_INSERT, \@incomingData);
&feedInput($inlab2xe, &Triceps::OP_DELETE, \@incomingData);
$vu2->drainFrame();
ok($vu2->empty());

#print STDERR $result2;
$expect2xe = 
'in OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" 
join2xe.out OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" source="source1" external="999" internal="1" 
join2xe.out OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" source="source1" external="999" internal="11" 
in OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" 
join2xe.out OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" source="source2" external="ABCD" internal="1" 
join2xe.out OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" source="source2" external="ABCD" internal="11" 
in OP_INSERT acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
join2xe.out OP_INSERT acctSrc="source3" acctXtrId="ZZZZ" amount="300" source="source3" external="ZZZZ" 
in OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" 
join2xe.out OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" source="source1" external="2011" internal="2" 
join2xe.out OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" source="source1" external="2011" internal="12" 
in OP_INSERT acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
join2xe.out OP_INSERT acctSrc="source2" acctXtrId="ZZZZ" amount="500" source="source2" external="ZZZZ" 
in OP_DELETE acctSrc="source1" acctXtrId="999" amount="100" 
join2xe.out OP_DELETE acctSrc="source1" acctXtrId="999" amount="100" source="source1" external="999" internal="1" 
join2xe.out OP_DELETE acctSrc="source1" acctXtrId="999" amount="100" source="source1" external="999" internal="11" 
in OP_DELETE acctSrc="source2" acctXtrId="ABCD" amount="200" 
join2xe.out OP_DELETE acctSrc="source2" acctXtrId="ABCD" amount="200" source="source2" external="ABCD" internal="1" 
join2xe.out OP_DELETE acctSrc="source2" acctXtrId="ABCD" amount="200" source="source2" external="ABCD" internal="11" 
in OP_DELETE acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
join2xe.out OP_DELETE acctSrc="source3" acctXtrId="ZZZZ" amount="300" source="source3" external="ZZZZ" 
in OP_DELETE acctSrc="source1" acctXtrId="2011" amount="400" 
join2xe.out OP_DELETE acctSrc="source1" acctXtrId="2011" amount="400" source="source1" external="2011" internal="2" 
join2xe.out OP_DELETE acctSrc="source1" acctXtrId="2011" amount="400" source="source1" external="2011" internal="12" 
in OP_DELETE acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
join2xe.out OP_DELETE acctSrc="source2" acctXtrId="ZZZZ" amount="500" source="source2" external="ZZZZ" 
';
ok($result2, $expect2xe);

#########
# (2xf) left join with limitOne = 1, and multiple records available
# also test the leftFromLabel here

# this is purely to keep track of the input in the log
my $inlab2xf = $vu2->makeLabel($rtInTrans, "in", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $inlab2xf, "Triceps::Label");

$join2xf = Triceps::LookupJoin->new(
	name => "join2xf",
	leftFromLabel => $inlab2xf,
	rightTable => $tAccounts2xde,
	rightIdxPath => ["lookupSrcExt"],
	by => [ "acctSrc" => "source", "acctXtrId" => "external" ],
	isLeft => 1,
	limitOne => 1,
	automatic => $auto,
	fieldsMirrorKey => 1,
);
ok(ref $join2xf, "Triceps::LookupJoin");

my $outlab2xf = $vu2->makeLabel($join2xf->getResultRowType(), "out", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $outlab2xf, "Triceps::Label");

# the output
$join2xf->getOutputLabel()->chain($outlab2xf);

undef $result2;
# feed the data
&feedInput($inlab2xf, &Triceps::OP_INSERT, \@incomingData);
&feedInput($inlab2xf, &Triceps::OP_DELETE, \@incomingData);
$vu2->drainFrame();
ok($vu2->empty());

#print STDERR $result2;
$expect2xf = 
'in OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" 
join2xf.out OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" source="source1" external="999" internal="1" 
in OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" 
join2xf.out OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" source="source2" external="ABCD" internal="1" 
in OP_INSERT acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
join2xf.out OP_INSERT acctSrc="source3" acctXtrId="ZZZZ" amount="300" source="source3" external="ZZZZ" 
in OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" 
join2xf.out OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" source="source1" external="2011" internal="2" 
in OP_INSERT acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
join2xf.out OP_INSERT acctSrc="source2" acctXtrId="ZZZZ" amount="500" source="source2" external="ZZZZ" 
in OP_DELETE acctSrc="source1" acctXtrId="999" amount="100" 
join2xf.out OP_DELETE acctSrc="source1" acctXtrId="999" amount="100" source="source1" external="999" internal="1" 
in OP_DELETE acctSrc="source2" acctXtrId="ABCD" amount="200" 
join2xf.out OP_DELETE acctSrc="source2" acctXtrId="ABCD" amount="200" source="source2" external="ABCD" internal="1" 
in OP_DELETE acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
join2xf.out OP_DELETE acctSrc="source3" acctXtrId="ZZZZ" amount="300" source="source3" external="ZZZZ" 
in OP_DELETE acctSrc="source1" acctXtrId="2011" amount="400" 
join2xf.out OP_DELETE acctSrc="source1" acctXtrId="2011" amount="400" source="source1" external="2011" internal="2" 
in OP_DELETE acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
join2xf.out OP_DELETE acctSrc="source2" acctXtrId="ZZZZ" amount="500" source="source2" external="ZZZZ" 
';
ok($result2, $expect2xf);

#########
# (2xg) same as 2xf, only drop the right-side key instead of mirroring it
# also test the leftFromLabel here

# this is purely to keep track of the input in the log
my $inlab2xg = $vu2->makeLabel($rtInTrans, "in", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $inlab2xg, "Triceps::Label");

$join2xg = Triceps::LookupJoin->new(
	name => "join2xg",
	leftFromLabel => $inlab2xg,
	rightTable => $tAccounts2xde,
	rightIdxPath => ["lookupSrcExt"],
	by => [ "acctSrc" => "source", "acctXtrId" => "external" ],
	isLeft => 1,
	limitOne => 1,
	automatic => $auto,
	fieldsDropRightKey => 1,
);
ok(ref $join2xg, "Triceps::LookupJoin");

my $outlab2xg = $vu2->makeLabel($join2xg->getResultRowType(), "out", undef, sub { $result2 .= $_[1]->printP() . "\n" } );
ok(ref $outlab2xg, "Triceps::Label");

# the output
$join2xg->getOutputLabel()->chain($outlab2xg);

undef $result2;
# feed the data
&feedInput($inlab2xg, &Triceps::OP_INSERT, \@incomingData);
# no need for a DELETE version
$vu2->drainFrame();
ok($vu2->empty());

#print STDERR $result2;
$expect2xg = 
'in OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" 
join2xg.out OP_INSERT acctSrc="source1" acctXtrId="999" amount="100" internal="1" 
in OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" 
join2xg.out OP_INSERT acctSrc="source2" acctXtrId="ABCD" amount="200" internal="1" 
in OP_INSERT acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
join2xg.out OP_INSERT acctSrc="source3" acctXtrId="ZZZZ" amount="300" 
in OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" 
join2xg.out OP_INSERT acctSrc="source1" acctXtrId="2011" amount="400" internal="2" 
in OP_INSERT acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
join2xg.out OP_INSERT acctSrc="source2" acctXtrId="ZZZZ" amount="500" 
';
ok($result2, $expect2xg);

}

&automaticAndNot(0);
#print STDERR "automaticAndNot 2nd go\n";
&automaticAndNot(1);


#########
# test the saveJoinerTo

{
	# not automatic
	my $code;
	my $join = Triceps::LookupJoin->new( 
		unit => $vu2,
		name => "join",
		leftRowType => $rtInTrans,
		rightTable => $tAccounts2,
		rightIdxPath => ["lookupSrcExt"],
		rightFields => [ "internal/acct" ],
		by => [ "acctSrc" => "source", "acctXtrId" => "external" ],
		isLeft => 1,
		automatic => 0,
		saveJoinerTo => \$code,
	);
	ok(ref $join, "Triceps::LookupJoin");
	#print STDERR "code = $code\n";
	ok($code =~ /^\s+sub  # \(\$self, \$row\)/);
}

{
	# automatic
	my $code;
	my $join = Triceps::LookupJoin->new( 
		unit => $vu2,
		name => "join",
		leftRowType => $rtInTrans,
		rightTable => $tAccounts2,
		rightIdxPath => ["lookupSrcExt"],
		rightFields => [ "internal/acct" ],
		by => [ "acctSrc" => "source", "acctXtrId" => "external" ],
		isLeft => 1,
		automatic => 1,
		saveJoinerTo => \$code,
	);
	ok(ref $join, "Triceps::LookupJoin");
	#print STDERR "code = $code\n";
	ok($code =~ /^\s+sub # \(\$inLabel, \$rowop, \$self\)/);
}

#########
# getters

{
	my $join = Triceps::LookupJoin->new( 
		unit => $vu2,
		name => "join",
		leftRowType => $rtInTrans,
		rightTable => $tAccounts2,
		rightIdxPath => ["lookupSrcExt"],
		rightFields => [ "internal/acct" ],
		byLeft => [ "acctSrc/source", "acctXtrId/external" ],
	);
	ok(ref $join, "Triceps::LookupJoin");

	my $res;
	$res = $join->getResultRowType();
	ok(ref $res, "Triceps::RowType");
	$res = $join->getInputLabel();
	ok(ref $res, "Triceps::Label");
	$res = $join->getOutputLabel();
	ok(ref $res, "Triceps::Label");

	ok($join->getUnit(), $vu2);
	ok($join->getName(), "join");
	ok($join->getLeftRowType(), $rtInTrans);
	ok($join->getRightTable(), $tAccounts2);
	ok(join(",", @{$join->getRightIdxPath()}), "lookupSrcExt");
	ok(! defined $join->getLeftFields());
	ok(join(",", @{$join->getRightFields()}), "internal/acct");
	ok($join->getFieldsLeftFirst(), 1);
	ok($join->getFieldsMirrorKey(), 0);
	ok(join(",", @{$join->getBy()}), "acctSrc,source,acctXtrId,external");
	ok(join(",", @{$join->getByLeft()}), "acctSrc/source,acctXtrId/external,!.*");
	ok($join->getIsLeft(), 1); # the default
	ok($join->getLimitOne(), 1); # got auto-detected as 1
	ok($join->getAutomatic(), 1); # the default
	ok($join->getOppositeOuter(), 0); # the default
	ok(! defined $join->getGroupSizeCode()); # the default
}
{
	my $join = Triceps::LookupJoin->new( 
		unit => $vu2,
		name => "join",
		leftRowType => $rtInTrans,
		rightTable => $tAccounts2,
		rightIdxPath => ["lookupSrcExt"],
		rightFields => [ "internal/acct" ],
		byLeft => [ "acctSrc/source", "acctXtrId/external" ],
		isLeft => 10,
		limitOne => 11,
		automatic => 12,
		oppositeOuter => 13,
		groupSizeCode => sub { 1; },
	);
	ok(ref $join, "Triceps::LookupJoin");

	ok($join->getIsLeft(), 10);
	ok($join->getLimitOne(), 11);
	ok($join->getAutomatic(), 12);
	ok($join->getOppositeOuter(), 13);
	ok(ref $join->getGroupSizeCode(), "CODE");
}

#########
# fnReturn
{
	my $join = Triceps::LookupJoin->new( 
		unit => $vu2,
		name => "join",
		leftRowType => $rtInTrans,
		rightTable => $tAccounts2,
		rightIdxPath => ["lookupSrcExt"],
		rightFields => [ "internal/acct" ],
		byLeft => [ "acctSrc/source", "acctXtrId/external" ],
	);
	ok(ref $join, "Triceps::LookupJoin");

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
		unit => $vu2,
		name => "join",
		leftRowType => $rtInTrans,
		rightTable => $tAccounts2,
		rightIdxPath => ["lookupSrcExt"],
		rightFields => [ "internal/acct" ],
		by => [ "acctSrc" => "source", "acctXtrId" => "external" ],
		isLeft => 1,
		automatic => 1,
	);
	delete $opt{$_[0]};
	eval {
		Triceps::LookupJoin->new(%opt);
	}
}

&tryMissingOptValue("unit");
ok($@ =~ /^Triceps::LookupJoin::new: option unit must be specified/);
&tryMissingOptValue("name");
ok($@ =~ /^Option 'name' must be specified for class 'Triceps::LookupJoin'/);
&tryMissingOptValue("leftRowType");
ok($@ =~ /^Triceps::LookupJoin::new: must have exactly one of options leftRowType or leftFromLabel/);
&tryMissingOptValue("rightTable");
ok($@ =~ /^Option 'rightTable' must be specified for class 'Triceps::LookupJoin'/);
&tryMissingOptValue("by");
ok($@ =~ /^Triceps::LookupJoin::new: must have exactly one of options by or byLeft, got none of them/);

sub tryBadOptValue # (optName, optValue)
{
	my %opt = (
		unit => $vu2,
		name => "join",
		leftRowType => $rtInTrans,
		rightTable => $tAccounts2,
		rightIdxPath => ["lookupSrcExt"],
		rightFields => [ "internal/acct" ],
		by => [ "acctSrc" => "source", "acctXtrId" => "external" ],
		isLeft => 1,
		automatic => 1,
	);
	while ($#_ >= 1) {
		$opt{$_[0]} = $_[1];
		shift; shift;
	}
	eval {
		Triceps::LookupJoin->new(%opt);
	}
}

&tryBadOptValue("unit", 9);
ok($@ =~ /^Option 'unit' of class 'Triceps::LookupJoin' must be a reference to 'Triceps::Unit', is ''/);
&tryBadOptValue("leftRowType", 9);
ok($@ =~ /^Option 'leftRowType' of class 'Triceps::LookupJoin' must be a reference to 'Triceps::RowType', is ''/);
&tryBadOptValue("rightTable", 9);
ok($@ =~ /^Option 'rightTable' of class 'Triceps::LookupJoin' must be a reference to 'Triceps::Table', is ''/);
&tryBadOptValue("rightIdxPath", [$vu2]);
ok($@ =~ /^Option 'rightIdxPath' of class 'Triceps::LookupJoin' must be a reference to 'ARRAY' '', is 'ARRAY' 'Triceps::Unit'/);
&tryBadOptValue("leftFields", 9);
ok($@ =~ /^Option 'leftFields' of class 'Triceps::LookupJoin' must be a reference to 'ARRAY', is ''/);
&tryBadOptValue("rightFields", 9);
ok($@ =~ /^Option 'rightFields' of class 'Triceps::LookupJoin' must be a reference to 'ARRAY', is ''/);
&tryBadOptValue("by", 9);
ok($@ =~ /^Option 'by' of class 'Triceps::LookupJoin' must be a reference to 'ARRAY', is ''/);
&tryBadOptValue("byLeft", 9);
ok($@ =~ /^Option 'byLeft' of class 'Triceps::LookupJoin' must be a reference to 'ARRAY', is ''/);
&tryBadOptValue("saveJoinerTo", 9);
ok($@ =~ /^Option 'saveJoinerTo' of class 'Triceps::LookupJoin' must be a reference to a scalar, is ''/);
&tryBadOptValue("oppositeOuter", 1, "automatic", 0);
ok($@ =~ /^The option 'oppositeOuter' may be enabled only in the automatic mode/);
&tryBadOptValue("groupSizeCode", 1, "oppositeOuter", 1);
ok($@ =~ /^Option 'groupSizeCode' of class 'Triceps::LookupJoin' must be a reference to 'CODE', is ''/);
&tryBadOptValue("groupSizeCode", sub { 1; }, "automatic", 1);
ok($@ =~ /^The option 'groupSizeCode' may be used only when the option 'oppositeOuter' is enabled/);

&tryBadOptValue("by", [ 'aaa' => 'bbb' ]);
ok($@ =~ /^Option 'by' contains an unknown left-side field 'aaa'/);
&tryBadOptValue("by", [ 'acctSrc' => 'bbb' ]);
ok($@ =~ /^Option 'by' contains a right-side field 'bbb' that is not in the index key,
  right key: \(external, source\)
  by: \(acctSrc, bbb\)/);
&tryBadOptValue("by", [ 'acctSrc' => 'internal' ]);
ok($@ =~ /^Option 'by' contains a right-side field 'internal' that is not in the index key,
  right key: \(external, source\)
  by: \(acctSrc, internal\)
/);

&tryBadOptValue("byLeft", [ "acctSrc/source", "acctXtrId/external" ]);
ok($@ =~ /^Triceps::LookupJoin::new: must have only one of options by or byLeft, got both by and byLeft/);

{
	eval {
		Triceps::LookupJoin->new(
			unit => $vu2,
			name => "join",
			leftRowType => $rtInTrans,
			rightTable => $tAccounts2,
			rightIdxPath => ["lookupSrcExt"],
			rightFields => [ "internal/acct" ],
			byLeft => [ "acctSrc/source", "acct/external" ],
			isLeft => 1,
			automatic => 1,
		);
	};
	ok($@ =~ /^Triceps::LookupJoin::new: option 'byLeft': result definition error:
  the field in definition 'acct\/external' is not found
The available fields are:
  acctSrc, acctXtrId, amount/);
}

&tryBadOptValue("rightIdxPath", [ 'lookupIntGroup', 'lookupInt' ]);
ok($@ =~ /^Triceps::TableType::findIndexKeyPath: the index type at path 'lookupIntGroup.lookupInt' does not have a key, table type is:/);

{
	my $tt = Triceps::TableType->new($rtAccounts)
		->addSubIndex("lookupSrcExt", # quick look-up by source and external id
			Triceps::IndexType->newHashed(key => [ "source", "external" ])
			->addSubIndex("fifo", Triceps::IndexType->newFifo())
		)
	;
	ok(ref $tt, "Triceps::TableType");
	$res = $tt->initialize();
	ok($res, 1);
	$t= $vu2->makeTable($tt, "TestTable");
	ok(ref $t, "Triceps::Table");

	eval {
		Triceps::LookupJoin->new(
			unit => $vu2,
			name => "join",
			leftRowType => $rtInTrans,
			rightTable => $t,
			rightFields => [ "internal/acct" ],
			by => [ "acctSrc" => "source", "acctXtrId" => "internal" ], # "internal" is not in the index on the right side
			isLeft => 1,
			automatic => 1,
		);
	};
	ok($@, qr/^The rightTable does not have an index that matches the key set\n  right key: \(source, internal\)\n  by: \(acctSrc, source, acctXtrId, internal\)\n  right table type:\n    table \(\n      row {\n        string source,\n        string external,\n        int32 internal,\n      }\n    \) {\n      index HashedIndex\(source, external, \) {\n        index FifoIndex\(\) fifo,\n      } lookupSrcExt,\n    }\n  at/);
}

&tryBadOptValue(rightFields => [ "internal/acct", "duck" ]),
ok($@ =~ /^Triceps::LookupJoin::new: option 'rightFields': result definition error:
  the field in definition 'duck' is not found
The available fields are:
  source, external, internal/);

&tryBadOptValue(leftFields => [ "acctSrc", "duck" ]),
ok($@ =~ /^Triceps::LookupJoin::new: option 'leftFields': result definition error:
  the field in definition 'duck' is not found
The available fields are:
  acctSrc, acctXtrId, amount/);

&tryBadOptValue(rightFields => [ "internal/acctSrc" ]),
ok($@ =~ /^A duplicate field 'acctSrc' is produced from  right-side field 'internal'; the preceding fields are: \(acctSrc, acctXtrId, amount\)/);

{
	my $lb = $vu2->makeDummyLabel($rtInTrans, "in");
	ok(ref $lb, "Triceps::Label");
	&tryBadOptValue(leftFromLabel => $lb),
	ok($@ =~ /^Triceps::LookupJoin::new: must have only one of options leftRowType or leftFromLabel/);
}

# test the match of array-ness in the join fields
{
	my $rtArr = Triceps::RowType->new(
		notArr1 => "uint8",
		notArr2 => "uint8[]",
		arr1 => "int32[]",
	);
	ok(ref $rtArr, "Triceps::RowType");

	my $tt = Triceps::TableType->new($rtArr)
		->addSubIndex("iterateSrc", # for iteration in order grouped by source
			Triceps::IndexType->newHashed(key => [ "notArr1" ]))
		->addSubIndex("byNotArr2", 
			Triceps::IndexType->newHashed(key => [ "notArr2" ]))
		->addSubIndex("byArr1", 
			Triceps::IndexType->newHashed(key => [ "arr1" ]));
	ok(ref $tt, "Triceps::TableType");
	$res = $tt->initialize();
	ok($res, 1);
	$t= $vu2->makeTable($tt, "TestTable");
	ok(ref $t, "Triceps::Table");

	my $j;
	$j = Triceps::LookupJoin->new(
		unit => $vu2,
		name => "join",
		leftRowType => $rtInTrans,
		rightTable => $t,
		rightFields => [ "notArr1" ],
		by => [ "acctSrc" => "notArr1" ],
		isLeft => 1,
		automatic => 1,
	);
	ok(ref $j, "Triceps::LookupJoin");

	$j = Triceps::LookupJoin->new(
		unit => $vu2,
		name => "join",
		leftRowType => $rtInTrans,
		rightTable => $t,
		rightIdxPath => ["byNotArr2"],
		rightFields => [ "notArr1" ],
		by => [ "acctSrc" => "notArr2" ],
		isLeft => 1,
		automatic => 1,
	);
	ok(ref $j, "Triceps::LookupJoin");

	$j = eval {
		Triceps::LookupJoin->new(
			unit => $vu2,
			name => "join",
			leftRowType => $rtInTrans,
			rightTable => $t,
			rightFields => [ "notArr1" ],
			rightIdxPath => [ "byArr1" ],
			by => [ "acctSrc" => "arr1" ],
			isLeft => 1,
			automatic => 1,
		);
	};
	ok($@ =~ /^Option 'by' fields 'acctSrc'='arr1' mismatch the array-ness, with types 'string' and 'int32\[\]'/);
}

# automatic joins don't do lookup()
{
	my $j = Triceps::LookupJoin->new(
		unit => $vu2,
		name => "join",
		leftRowType => $rtInTrans,
		rightTable => $t,
		rightIdxPath => ["byNotArr2"],
		rightFields => [ "notArr1" ],
		by => [ "acctSrc" => "notArr2" ],
		isLeft => 1,
		automatic => 1,
	);
	ok(ref $j, "Triceps::LookupJoin");
	eval {
		$j->lookup($rtInTrans->makeRowArray());
	};
	ok($@ =~ /^Joiner 'join' was created with automatic option and does not support the manual lookup\(\) call/);
}


#print STDERR "err=$@\n";

#########
# clearing
# MUST BE LAST because it will destroy everything in the unit

{
	my $j = Triceps::LookupJoin->new(
		unit => $vu2,
		name => "join",
		leftRowType => $rtInTrans,
		rightTable => $t,
		rightIdxPath => ["byNotArr2"],
		rightFields => [ "notArr1" ],
		by => [ "acctSrc" => "notArr2" ],
	);
	ok(ref $j, "Triceps::LookupJoin");
	ok(exists $j->{unit});

	$vu2->clearLabels();
	ok(!exists $j->{unit});
}
