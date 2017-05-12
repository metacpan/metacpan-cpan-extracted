#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The examples of joins.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 12 };
use Triceps;
use Triceps::X::TestFeed qw(:all);
use Carp;
ok(1); # If we made it this far, we're ok.

use strict;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#########################
# common row types and such, for translation of the external account
# numbers from various external systems into the internal number

our $rtInTrans = Triceps::RowType->new( # a transaction received
	id => "int32", # the transaction id
	acctSrc => "string", # external system that sent us a transaction
	acctXtrId => "string", # its name of the account of the transaction
	amount => "int32", # the amount of transaction (int is easier to check)
);

our $rtAccounts = Triceps::RowType->new( # account translation map
	source => "string", # external system that sent us a transaction
	external => "string", # its name of the account in the transaction
	internal => "int32", # our internal account id
);

our $ttAccounts = Triceps::TableType->new($rtAccounts)
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
$ttAccounts->initialize();

my @commonInput = (
	"acct,OP_INSERT,source1,999,1\n",
	"acct,OP_INSERT,source1,2011,2\n",
	"acct,OP_INSERT,source2,ABCD,1\n",
	"trans,OP_INSERT,1,source1,999,100\n", 
	"trans,OP_INSERT,2,source2,ABCD,200\n", 
	"trans,OP_INSERT,3,source2,QWERTY,200\n", 
	"acct,OP_INSERT,source2,QWERTY,2\n",
	"trans,OP_DELETE,3,source2,QWERTY,200\n", 
	"acct,OP_DELETE,source1,999,1\n",
);

my $code;

#########################
# a manual filtering on lookup

sub doManualLookup {

our $uJoin = Triceps::Unit->new("uJoin");

our $tAccounts = $uJoin->makeTable($ttAccounts, "tAccounts");

my $lbFilterResult = $uJoin->makeDummyLabel($rtInTrans, "lbFilterResult");
my $lbFilter = $uJoin->makeLabel($rtInTrans, "lbFilter", undef, sub {
	my ($label, $rowop) = @_;
	my $row = $rowop->getRow();
	my $rh = $tAccounts->findBy(
		source => $row->get("acctSrc"),
		external => $row->get("acctXtrId"),
	);
	if (!$rh->isNull()) {
		$uJoin->call($lbFilterResult->adopt($rowop));
	}
});

# label to print the changes to the detailed stats
makePrintLabel("lbPrint", $lbFilterResult);

while(&readLine) {
	chomp;
	my @data = split(/,/); # starts with a command, then string opcode
	my $type = shift @data;
	if ($type eq "acct") {
		$uJoin->makeArrayCall($tAccounts->getInputLabel(), @data);
	} elsif ($type eq "trans") {
		$uJoin->makeArrayCall($lbFilter, @data);
	}
	$uJoin->drainFrame(); # just in case, for completeness
}

} # doManualLookup 

setInputLines(@commonInput);
&doManualLookup();
#print &getResultLines();
ok(&getResultLines(), 
'> acct,OP_INSERT,source1,999,1
> acct,OP_INSERT,source1,2011,2
> acct,OP_INSERT,source2,ABCD,1
> trans,OP_INSERT,1,source1,999,100
lbFilterResult OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" 
> trans,OP_INSERT,2,source2,ABCD,200
lbFilterResult OP_INSERT id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" 
> trans,OP_INSERT,3,source2,QWERTY,200
> acct,OP_INSERT,source2,QWERTY,2
> trans,OP_DELETE,3,source2,QWERTY,200
lbFilterResult OP_DELETE id="3" acctSrc="source2" acctXtrId="QWERTY" amount="200" 
> acct,OP_DELETE,source1,999,1
');

#########################
# perform a LookupJoin, with a left join

sub doLookupLeft {

our $uJoin = Triceps::Unit->new("uJoin");

our $tAccounts = $uJoin->makeTable($ttAccounts, "tAccounts");

our $join = Triceps::LookupJoin->new(
	unit => $uJoin,
	name => "join",
	leftRowType => $rtInTrans,
	rightTable => $tAccounts,
	rightIdxPath => ["lookupSrcExt"],
	rightFields => [ "internal/acct" ],
	by => [ "acctSrc" => "source", "acctXtrId" => "external" ],
	isLeft => 1,
	#saveJoinerTo => \$code,
); # would confess by itself on an error

# label to print the changes to the detailed stats
makePrintLabel("lbPrint", $join->getOutputLabel());

while(&readLine) {
	chomp;
	my @data = split(/,/); # starts with a command, then string opcode
	my $type = shift @data;
	if ($type eq "acct") {
		$uJoin->makeArrayCall($tAccounts->getInputLabel(), @data);
	} elsif ($type eq "trans") {
		$uJoin->makeArrayCall($join->getInputLabel(), @data);
	}
	$uJoin->drainFrame(); # just in case, for completeness
}

} # doLookupLeft

setInputLines(@commonInput);
&doLookupLeft();
#print &getResultLines();
ok(&getResultLines(), 
'> acct,OP_INSERT,source1,999,1
> acct,OP_INSERT,source1,2011,2
> acct,OP_INSERT,source2,ABCD,1
> trans,OP_INSERT,1,source1,999,100
join.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" acct="1" 
> trans,OP_INSERT,2,source2,ABCD,200
join.out OP_INSERT id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" acct="1" 
> trans,OP_INSERT,3,source2,QWERTY,200
join.out OP_INSERT id="3" acctSrc="source2" acctXtrId="QWERTY" amount="200" 
> acct,OP_INSERT,source2,QWERTY,2
> trans,OP_DELETE,3,source2,QWERTY,200
join.out OP_DELETE id="3" acctSrc="source2" acctXtrId="QWERTY" amount="200" acct="2" 
> acct,OP_DELETE,source1,999,1
');
#$code =~ s/\n\t\t/\n/g;
#$code =~ s/\t/  /g;
#print "$code\n";

#########################
# Just like doLookupLeft but with the left table having the same key 
# field names as the right.

sub doLookupLeftSameFields {

our $uJoin = Triceps::Unit->new("uJoin");

our $rtTrans = Triceps::RowType->new( # a transaction received
	id => "int32", # the transaction id
	source => "string", # external system that sent us a transaction
	external => "string", # its name of the account of the transaction
	amount => "int32", # the amount of transaction (int is easier to check)
);

our $tAccounts = $uJoin->makeTable($ttAccounts, "tAccounts");

our $join = Triceps::LookupJoin->new(
	unit => $uJoin,
	name => "join",
	leftRowType => $rtTrans,
	rightTable => $tAccounts,
	byLeft => [ "source", "external" ],
	fieldsDropRightKey => 1,
	isLeft => 1,
); # would confess by itself on an error

# label to print the changes to the detailed stats
makePrintLabel("lbPrint", $join->getOutputLabel());

while(&readLine) {
	chomp;
	my @data = split(/,/); # starts with a command, then string opcode
	my $type = shift @data;
	if ($type eq "acct") {
		$uJoin->makeArrayCall($tAccounts->getInputLabel(), @data);
	} elsif ($type eq "trans") {
		$uJoin->makeArrayCall($join->getInputLabel(), @data);
	}
	$uJoin->drainFrame(); # just in case, for completeness
}

} # doLookupLeftSameFields

setInputLines(@commonInput);
&doLookupLeftSameFields();
#print &getResultLines();
ok(&getResultLines(), 
'> acct,OP_INSERT,source1,999,1
> acct,OP_INSERT,source1,2011,2
> acct,OP_INSERT,source2,ABCD,1
> trans,OP_INSERT,1,source1,999,100
join.out OP_INSERT id="1" source="source1" external="999" amount="100" internal="1" 
> trans,OP_INSERT,2,source2,ABCD,200
join.out OP_INSERT id="2" source="source2" external="ABCD" amount="200" internal="1" 
> trans,OP_INSERT,3,source2,QWERTY,200
join.out OP_INSERT id="3" source="source2" external="QWERTY" amount="200" 
> acct,OP_INSERT,source2,QWERTY,2
> trans,OP_DELETE,3,source2,QWERTY,200
join.out OP_DELETE id="3" source="source2" external="QWERTY" amount="200" internal="2" 
> acct,OP_DELETE,source1,999,1
');
#$code =~ s/\n\t\t/\n/g;
#$code =~ s/\t/  /g;
#print "$code\n";

#########################
# perform a LookupJoin, with an inner join and leftFromLabel

sub doLookupFull {

our $uJoin = Triceps::Unit->new("uJoin");

our $tAccounts = $uJoin->makeTable($ttAccounts, "tAccounts");

our $lbTrans = $uJoin->makeDummyLabel($rtInTrans, "lbTrans");

our $join = Triceps::LookupJoin->new(
	name => "join",
	leftFromLabel => $lbTrans,
	rightTable => $tAccounts,
	#rightIdxPath => ["lookupSrcExt"],
	leftFields => [ "id", "amount" ],
	#leftFields => [ "!acct.*", ".*" ],
	fieldsLeftFirst => 0,
	rightFields => [ "internal/acct" ],
	by => [ "acctSrc" => "source", "acctXtrId" => "external" ],
	isLeft => 0,
); # would confess by itself on an error

# label to print the changes to the detailed stats
makePrintLabel("lbPrint", $join->getOutputLabel());

while(&readLine) {
	chomp;
	my @data = split(/,/); # starts with a command, then string opcode
	my $type = shift @data;
	if ($type eq "acct") {
		$uJoin->makeArrayCall($tAccounts->getInputLabel(), @data);
	} elsif ($type eq "trans") {
		$uJoin->makeArrayCall($lbTrans, @data);
	}
	$uJoin->drainFrame(); # just in case, for completeness
}

} # doLookupFull

setInputLines(@commonInput);
&doLookupFull();
#print &getResultLines();
ok(&getResultLines(), 
'> acct,OP_INSERT,source1,999,1
> acct,OP_INSERT,source1,2011,2
> acct,OP_INSERT,source2,ABCD,1
> trans,OP_INSERT,1,source1,999,100
join.out OP_INSERT acct="1" id="1" amount="100" 
> trans,OP_INSERT,2,source2,ABCD,200
join.out OP_INSERT acct="1" id="2" amount="200" 
> trans,OP_INSERT,3,source2,QWERTY,200
> acct,OP_INSERT,source2,QWERTY,2
> trans,OP_DELETE,3,source2,QWERTY,200
join.out OP_DELETE acct="2" id="3" amount="200" 
> acct,OP_DELETE,source1,999,1
');

#########################
# perform a LookupJoin, with multiple rows in the result

our $ttAccounts2 = Triceps::TableType->new($rtAccounts)
	->addSubIndex("iterateSrc", # for iteration in order grouped by source
		Triceps::IndexType->newHashed(key => [ "source" ])
		->addSubIndex("lookupSrcExt",
			Triceps::IndexType->newHashed(key => [ "external" ])
			->addSubIndex("grouping", Triceps::IndexType->newFifo())
		)
	)
;
$ttAccounts2->initialize();

sub doLookupLeftMulti {

our $uJoin = Triceps::Unit->new("uJoin");

our $tAccounts = $uJoin->makeTable($ttAccounts2, "tAccounts");

our $join = Triceps::LookupJoin->new(
	unit => $uJoin,
	name => "join",
	leftRowType => $rtInTrans,
	rightTable => $tAccounts,
	rightIdxPath => [ "iterateSrc", "lookupSrcExt" ],
	rightFields => [ "internal/acct" ],
	by => [ "acctSrc" => "source", "acctXtrId" => "external" ],
	#saveJoinerTo => \$code,
); # would confess by itself on an error

# label to print the changes to the detailed stats
makePrintLabel("lbPrint", $join->getOutputLabel());

while(&readLine) {
	chomp;
	my @data = split(/,/); # starts with a command, then string opcode
	my $type = shift @data;
	if ($type eq "acct") {
		$uJoin->makeArrayCall($tAccounts->getInputLabel(), @data);
	} elsif ($type eq "trans") {
		$uJoin->makeArrayCall($join->getInputLabel(), @data);
	}
	$uJoin->drainFrame(); # just in case, for completeness
}

} # doLookupLeftMulti

setInputLines(
	"acct,OP_INSERT,source1,999,1\n",
	"acct,OP_INSERT,source1,2011,2\n",
	"acct,OP_INSERT,source2,ABCD,1\n",
	"acct,OP_INSERT,source2,ABCD,10\n",
	"acct,OP_INSERT,source2,ABCD,100\n",
	"trans,OP_INSERT,1,source1,999,100\n", 
	"trans,OP_INSERT,2,source2,ABCD,200\n", 
	"trans,OP_INSERT,3,source2,QWERTY,200\n", 
	"acct,OP_INSERT,source2,QWERTY,2\n",
	"trans,OP_DELETE,3,source2,QWERTY,200\n", 
	"acct,OP_DELETE,source1,999,1\n",
);
&doLookupLeftMulti();
#print &getResultLines();
ok(&getResultLines(), 
'> acct,OP_INSERT,source1,999,1
> acct,OP_INSERT,source1,2011,2
> acct,OP_INSERT,source2,ABCD,1
> acct,OP_INSERT,source2,ABCD,10
> acct,OP_INSERT,source2,ABCD,100
> trans,OP_INSERT,1,source1,999,100
join.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" acct="1" 
> trans,OP_INSERT,2,source2,ABCD,200
join.out OP_INSERT id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" acct="1" 
join.out OP_INSERT id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" acct="10" 
join.out OP_INSERT id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" acct="100" 
> trans,OP_INSERT,3,source2,QWERTY,200
join.out OP_INSERT id="3" acctSrc="source2" acctXtrId="QWERTY" amount="200" 
> acct,OP_INSERT,source2,QWERTY,2
> trans,OP_DELETE,3,source2,QWERTY,200
join.out OP_DELETE id="3" acctSrc="source2" acctXtrId="QWERTY" amount="200" acct="2" 
> acct,OP_DELETE,source1,999,1
');
#$code =~ s/\n\t\t/\n/g;
#$code =~ s/\t/  /g;
#print "$code\n";

#########################
# perform a LookupJoin, with multiple rows in the result but only one chosen

sub doLookupLeftMultiOne {

our $uJoin = Triceps::Unit->new("uJoin");

our $tAccounts = $uJoin->makeTable($ttAccounts2, "tAccounts");

our $join = Triceps::LookupJoin->new(
	unit => $uJoin,
	name => "join",
	leftRowType => $rtInTrans,
	rightTable => $tAccounts,
	rightIdxPath => [ "iterateSrc", "lookupSrcExt" ],
	rightFields => [ "internal/acct" ],
	by => [ "acctSrc" => "source", "acctXtrId" => "external" ],
	limitOne => 1,
); # would confess by itself on an error

# label to print the changes to the detailed stats
makePrintLabel("lbPrint", $join->getOutputLabel());

while(&readLine) {
	chomp;
	my @data = split(/,/); # starts with a command, then string opcode
	my $type = shift @data;
	if ($type eq "acct") {
		$uJoin->makeArrayCall($tAccounts->getInputLabel(), @data);
	} elsif ($type eq "trans") {
		$uJoin->makeArrayCall($join->getInputLabel(), @data);
	}
	$uJoin->drainFrame(); # just in case, for completeness
}

} # doLookupLeftMultiOne

setInputLines(
	"acct,OP_INSERT,source1,999,1\n",
	"acct,OP_INSERT,source1,2011,2\n",
	"acct,OP_INSERT,source2,ABCD,1\n",
	"acct,OP_INSERT,source2,ABCD,10\n",
	"acct,OP_INSERT,source2,ABCD,100\n",
	"trans,OP_INSERT,1,source1,999,100\n", 
	"trans,OP_INSERT,2,source2,ABCD,200\n", 
	"trans,OP_INSERT,3,source2,QWERTY,200\n", 
	"acct,OP_INSERT,source2,QWERTY,2\n",
	"trans,OP_DELETE,3,source2,QWERTY,200\n", 
	"acct,OP_DELETE,source1,999,1\n",
);
&doLookupLeftMultiOne();
#print &getResultLines();
ok(&getResultLines(), 
'> acct,OP_INSERT,source1,999,1
> acct,OP_INSERT,source1,2011,2
> acct,OP_INSERT,source2,ABCD,1
> acct,OP_INSERT,source2,ABCD,10
> acct,OP_INSERT,source2,ABCD,100
> trans,OP_INSERT,1,source1,999,100
join.out OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" acct="1" 
> trans,OP_INSERT,2,source2,ABCD,200
join.out OP_INSERT id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" acct="1" 
> trans,OP_INSERT,3,source2,QWERTY,200
join.out OP_INSERT id="3" acctSrc="source2" acctXtrId="QWERTY" amount="200" 
> acct,OP_INSERT,source2,QWERTY,2
> trans,OP_DELETE,3,source2,QWERTY,200
join.out OP_DELETE id="3" acctSrc="source2" acctXtrId="QWERTY" amount="200" acct="2" 
> acct,OP_DELETE,source1,999,1
');

#########################
# LookupJoin, with a left join, and manual iteration

sub doLookupLeftManual {

our $uJoin = Triceps::Unit->new("uJoin");

our $tAccounts = $uJoin->makeTable($ttAccounts, "tAccounts");

our $join = Triceps::LookupJoin->new(
	unit => $uJoin,
	name => "join",
	leftRowType => $rtInTrans,
	rightTable => $tAccounts,
	rightFields => [ "internal/acct" ],
	by => [ "acctSrc" => "source", "acctXtrId" => "external" ],
	automatic => 0,
	#saveJoinerTo => \$code,
); # would confess by itself on an error

# label to print the changes to the detailed stats
my $lbPrint = makePrintLabel("lbPrint", $join->getOutputLabel());

while(&readLine) {
	chomp;
	my @data = split(/,/); # starts with a command, then string opcode
	my $type = shift @data;
	if ($type eq "acct") {
		$uJoin->makeArrayCall($tAccounts->getInputLabel(), @data);
	} elsif ($type eq "trans") {
		my $op = shift @data; # drop the opcode field
		my $trans = $rtInTrans->makeRowArray(@data);
		my @rows = $join->lookup($trans);
		foreach my $r (@rows) {
			$uJoin->call($lbPrint->makeRowop($op, $r));
		}
	}
	$uJoin->drainFrame(); # just in case, for completeness
}

} # doLookupLeftManual

setInputLines(@commonInput);
&doLookupLeftManual();
#print &getResultLines();
ok(&getResultLines(), 
'> acct,OP_INSERT,source1,999,1
> acct,OP_INSERT,source1,2011,2
> acct,OP_INSERT,source2,ABCD,1
> trans,OP_INSERT,1,source1,999,100
lbPrint OP_INSERT id="1" acctSrc="source1" acctXtrId="999" amount="100" acct="1" 
> trans,OP_INSERT,2,source2,ABCD,200
lbPrint OP_INSERT id="2" acctSrc="source2" acctXtrId="ABCD" amount="200" acct="1" 
> trans,OP_INSERT,3,source2,QWERTY,200
lbPrint OP_INSERT id="3" acctSrc="source2" acctXtrId="QWERTY" amount="200" 
> acct,OP_INSERT,source2,QWERTY,2
> trans,OP_DELETE,3,source2,QWERTY,200
lbPrint OP_DELETE id="3" acctSrc="source2" acctXtrId="QWERTY" amount="200" acct="2" 
> acct,OP_DELETE,source1,999,1
');
#$code =~ s/\n\t\t/\n/g;
#$code =~ s/\t/  /g;
#print "$code\n";

#####################################################################################
# The JoinTwo examples

#########################
# common row types and such, for the currency conversion

our $rtToUsd = Triceps::RowType->new( # a currency conversion to USD
	date => "int32", # as of which date, in format YYYYMMDD
	currency => "string", # currency code
	toUsd => "float64", # multiplier to convert this currency to USD
);

our $rtPosition = Triceps::RowType->new( # a customer account position
	date => "int32", # as of which date, in format YYYYMMDD
	customer => "string", # customer account id
	symbol => "string", # stock symbol
	quantity => "float64", # number of shares
	price => "float64", # share price in local currency
	currency => "string", # currency code of the price
);

# exchange rates, to convert all currencies to USD
our $ttToUsd = Triceps::TableType->new($rtToUsd)
	->addSubIndex("primary",
		Triceps::IndexType->newHashed(key => [ "date", "currency" ])
	)
	->addSubIndex("byDate", # for cleaning by date
		Triceps::SimpleOrderedIndex->new(date => "ASC")
		->addSubIndex("grouping", Triceps::IndexType->newFifo())
	)
;
$ttToUsd->initialize();

# the positions in the original currency
our $ttPosition = Triceps::TableType->new($rtPosition)
	->addSubIndex("primary",
		Triceps::IndexType->newHashed(key => [ "date", "customer", "symbol" ])
	)
	->addSubIndex("currencyLookup", # for joining with currency conversion
		Triceps::IndexType->newHashed(key => [ "date", "currency" ])
		->addSubIndex("grouping", Triceps::IndexType->newFifo())
	)
	->addSubIndex("byDate", # for cleaning by date
		Triceps::SimpleOrderedIndex->new(date => "ASC")
		->addSubIndex("grouping", Triceps::IndexType->newFifo())
	)
;
$ttPosition->initialize();

# remember the indexes for the future use
our $ixtToUsdByDate = $ttToUsd->findSubIndex("byDate");
our $ixtPositionByDate = $ttPosition->findSubIndex("byDate");

our @inputBasicJoin = (
	"cur,OP_INSERT,20120310,USD,1\n",
	"cur,OP_INSERT,20120310,GBP,2\n",
	"cur,OP_INSERT,20120310,EUR,1.5\n",
	"pos,OP_INSERT,20120310,one,AAA,100,15,USD\n",
	"pos,OP_INSERT,20120310,two,AAA,100,8,GBP\n",
	"pos,OP_INSERT,20120310,three,AAA,100,300,RUR\n",
	"pos,OP_INSERT,20120310,three,BBB,200,80,GBP\n",
	"cur,OP_INSERT,20120310,RUR,0.04\n",
	"cur,OP_DELETE,20120310,GBP,2\n",
	"cur,OP_INSERT,20120310,GBP,2.2\n",
	"pos,OP_DELETE,20120310,one,AAA,100,15,USD\n",
	"pos,OP_INSERT,20120310,one,AAA,200,16,USD\n",
);

#########################

sub doJoinInner {

our $uJoin = Triceps::Unit->new("uJoin");

our $tToUsd = $uJoin->makeTable($ttToUsd, "tToUsd");
our $tPosition = $uJoin->makeTable($ttPosition, "tPosition");

our $join = Triceps::JoinTwo->new(
	name => "join",
	leftTable => $tPosition,
	rightTable => $tToUsd,
	byLeft => [ "date", "currency" ],
	type => "inner",
); # would confess by itself on an error

# label to print the changes to the detailed stats
makePrintLabel("lbPrint", $join->getOutputLabel());

while(&readLine) {
	chomp;
	my @data = split(/,/); # starts with a command, then string opcode
	my $type = shift @data;
	if ($type eq "cur") {
		$uJoin->makeArrayCall($tToUsd->getInputLabel(), @data);
	} elsif ($type eq "pos") {
		$uJoin->makeArrayCall($tPosition->getInputLabel(), @data);
	}
	$uJoin->drainFrame(); # just in case, for completeness
}

} # doJoinInner

setInputLines(@inputBasicJoin);
&doJoinInner();
#print &getResultLines();
ok(&getResultLines(), 
'> cur,OP_INSERT,20120310,USD,1
> cur,OP_INSERT,20120310,GBP,2
> cur,OP_INSERT,20120310,EUR,1.5
> pos,OP_INSERT,20120310,one,AAA,100,15,USD
join.leftLookup.out OP_INSERT date="20120310" customer="one" symbol="AAA" quantity="100" price="15" currency="USD" toUsd="1" 
> pos,OP_INSERT,20120310,two,AAA,100,8,GBP
join.leftLookup.out OP_INSERT date="20120310" customer="two" symbol="AAA" quantity="100" price="8" currency="GBP" toUsd="2" 
> pos,OP_INSERT,20120310,three,AAA,100,300,RUR
> pos,OP_INSERT,20120310,three,BBB,200,80,GBP
join.leftLookup.out OP_INSERT date="20120310" customer="three" symbol="BBB" quantity="200" price="80" currency="GBP" toUsd="2" 
> cur,OP_INSERT,20120310,RUR,0.04
join.rightLookup.out OP_INSERT date="20120310" customer="three" symbol="AAA" quantity="100" price="300" currency="RUR" toUsd="0.04" 
> cur,OP_DELETE,20120310,GBP,2
join.rightLookup.out OP_DELETE date="20120310" customer="two" symbol="AAA" quantity="100" price="8" currency="GBP" toUsd="2" 
join.rightLookup.out OP_DELETE date="20120310" customer="three" symbol="BBB" quantity="200" price="80" currency="GBP" toUsd="2" 
> cur,OP_INSERT,20120310,GBP,2.2
join.rightLookup.out OP_INSERT date="20120310" customer="two" symbol="AAA" quantity="100" price="8" currency="GBP" toUsd="2.2" 
join.rightLookup.out OP_INSERT date="20120310" customer="three" symbol="BBB" quantity="200" price="80" currency="GBP" toUsd="2.2" 
> pos,OP_DELETE,20120310,one,AAA,100,15,USD
join.leftLookup.out OP_DELETE date="20120310" customer="one" symbol="AAA" quantity="100" price="15" currency="USD" toUsd="1" 
> pos,OP_INSERT,20120310,one,AAA,200,16,USD
join.leftLookup.out OP_INSERT date="20120310" customer="one" symbol="AAA" quantity="200" price="16" currency="USD" toUsd="1" 
');

#########################

# Go through the table and clear all the rows where the field "date"
# is less than the date argument. The index type orders the table by date.
sub clearByDate($$$) # ($table, $ixt, $date)
{
	my ($table, $ixt, $date) = @_;

	my $next;
	for (my $rhit = $table->beginIdx($ixt); !$rhit->isNull(); $rhit = $next) {
		last if (($rhit->getRow()->get("date")) >= $date);
		$next = $rhit->nextIdx($ixt); # advance before removal
		$table->remove($rhit);
	}
}

sub doJoinLeft {

our $uJoin = Triceps::Unit->new("uJoin");

our $tToUsd = $uJoin->makeTable($ttToUsd, "tToUsd");
our $tPosition = $uJoin->makeTable($ttPosition, "tPosition");

our $businessDay = undef;

our $join = Triceps::JoinTwo->new(
	name => "join",
	leftTable => $tPosition,
	rightTable => $tToUsd,
	byLeft => [ "date", "currency" ],
	type => "left",
); # would confess by itself on an error

# label to print the changes to the detailed stats
makePrintLabel("lbPrint", $join->getOutputLabel());

while(&readLine) {
	chomp;
	my @data = split(/,/); # starts with a command, then string opcode
	my $type = shift @data;
	if ($type eq "cur") {
		$uJoin->makeArrayCall($tToUsd->getInputLabel(), @data);
	} elsif ($type eq "pos") {
		$uJoin->makeArrayCall($tPosition->getInputLabel(), @data);
	} elsif ($type eq "day") { # set the business day
		$businessDay = $data[0] + 0; # convert to an int
	} elsif ($type eq "clear") { # clear the previous day
		# flush the left side first, because it's an outer join
		&clearByDate($tPosition, $ixtPositionByDate, $businessDay);
		&clearByDate($tToUsd, $ixtToUsdByDate, $businessDay);
	}
	$uJoin->drainFrame(); # just in case, for completeness
}

} # doJoinLeft

setInputLines(
	# add the clearing for the contrast with the later filtered demo
	"day,20120310\n",
	@inputBasicJoin,
	"day,20120311\n",
	"clear\n",
);
&doJoinLeft();
#print &getResultLines();
ok(&getResultLines(), 
'> day,20120310
> cur,OP_INSERT,20120310,USD,1
> cur,OP_INSERT,20120310,GBP,2
> cur,OP_INSERT,20120310,EUR,1.5
> pos,OP_INSERT,20120310,one,AAA,100,15,USD
join.leftLookup.out OP_INSERT date="20120310" customer="one" symbol="AAA" quantity="100" price="15" currency="USD" toUsd="1" 
> pos,OP_INSERT,20120310,two,AAA,100,8,GBP
join.leftLookup.out OP_INSERT date="20120310" customer="two" symbol="AAA" quantity="100" price="8" currency="GBP" toUsd="2" 
> pos,OP_INSERT,20120310,three,AAA,100,300,RUR
join.leftLookup.out OP_INSERT date="20120310" customer="three" symbol="AAA" quantity="100" price="300" currency="RUR" 
> pos,OP_INSERT,20120310,three,BBB,200,80,GBP
join.leftLookup.out OP_INSERT date="20120310" customer="three" symbol="BBB" quantity="200" price="80" currency="GBP" toUsd="2" 
> cur,OP_INSERT,20120310,RUR,0.04
join.rightLookup.out OP_DELETE date="20120310" customer="three" symbol="AAA" quantity="100" price="300" currency="RUR" 
join.rightLookup.out OP_INSERT date="20120310" customer="three" symbol="AAA" quantity="100" price="300" currency="RUR" toUsd="0.04" 
> cur,OP_DELETE,20120310,GBP,2
join.rightLookup.out OP_DELETE date="20120310" customer="two" symbol="AAA" quantity="100" price="8" currency="GBP" toUsd="2" 
join.rightLookup.out OP_INSERT date="20120310" customer="two" symbol="AAA" quantity="100" price="8" currency="GBP" 
join.rightLookup.out OP_DELETE date="20120310" customer="three" symbol="BBB" quantity="200" price="80" currency="GBP" toUsd="2" 
join.rightLookup.out OP_INSERT date="20120310" customer="three" symbol="BBB" quantity="200" price="80" currency="GBP" 
> cur,OP_INSERT,20120310,GBP,2.2
join.rightLookup.out OP_DELETE date="20120310" customer="two" symbol="AAA" quantity="100" price="8" currency="GBP" 
join.rightLookup.out OP_INSERT date="20120310" customer="two" symbol="AAA" quantity="100" price="8" currency="GBP" toUsd="2.2" 
join.rightLookup.out OP_DELETE date="20120310" customer="three" symbol="BBB" quantity="200" price="80" currency="GBP" 
join.rightLookup.out OP_INSERT date="20120310" customer="three" symbol="BBB" quantity="200" price="80" currency="GBP" toUsd="2.2" 
> pos,OP_DELETE,20120310,one,AAA,100,15,USD
join.leftLookup.out OP_DELETE date="20120310" customer="one" symbol="AAA" quantity="100" price="15" currency="USD" toUsd="1" 
> pos,OP_INSERT,20120310,one,AAA,200,16,USD
join.leftLookup.out OP_INSERT date="20120310" customer="one" symbol="AAA" quantity="200" price="16" currency="USD" toUsd="1" 
> day,20120311
> clear
join.leftLookup.out OP_DELETE date="20120310" customer="two" symbol="AAA" quantity="100" price="8" currency="GBP" toUsd="2.2" 
join.leftLookup.out OP_DELETE date="20120310" customer="three" symbol="AAA" quantity="100" price="300" currency="RUR" toUsd="0.04" 
join.leftLookup.out OP_DELETE date="20120310" customer="three" symbol="BBB" quantity="200" price="80" currency="GBP" toUsd="2.2" 
join.leftLookup.out OP_DELETE date="20120310" customer="one" symbol="AAA" quantity="200" price="16" currency="USD" toUsd="1" 
');

#########################

sub doJoinOuter {

our $uJoin = Triceps::Unit->new("uJoin");

our $tToUsd = $uJoin->makeTable($ttToUsd, "tToUsd");
our $tPosition = $uJoin->makeTable($ttPosition, "tPosition");

our $join = Triceps::JoinTwo->new(
	name => "join",
	leftTable => $tPosition,
	rightTable => $tToUsd,
	byLeft => [ "date", "currency" ],
	type => "outer",
); # would confess by itself on an error

# label to print the changes to the detailed stats
makePrintLabel("lbPrint", $join->getOutputLabel());

while(&readLine) {
	chomp;
	my @data = split(/,/); # starts with a command, then string opcode
	my $type = shift @data;
	if ($type eq "cur") {
		$uJoin->makeArrayCall($tToUsd->getInputLabel(), @data);
	} elsif ($type eq "pos") {
		$uJoin->makeArrayCall($tPosition->getInputLabel(), @data);
	}
	$uJoin->drainFrame(); # just in case, for completeness
}

} # doJoinOuter

setInputLines(
	"cur,OP_INSERT,20120310,GBP,2\n",
	"pos,OP_INSERT,20120310,two,AAA,100,8,GBP\n",
	"pos,OP_INSERT,20120310,three,BBB,200,80,GBP\n",
	"pos,OP_INSERT,20120310,three,AAA,100,300,RUR\n",
	"cur,OP_INSERT,20120310,RUR,0.04\n",
	"cur,OP_DELETE,20120310,GBP,2\n",
	"cur,OP_INSERT,20120310,GBP,2.2\n",
	"pos,OP_DELETE,20120310,three,BBB,200,80,GBP\n",
	"pos,OP_DELETE,20120310,three,AAA,100,300,RUR\n",
);
&doJoinOuter();
#print &getResultLines();
ok(&getResultLines(), 
'> cur,OP_INSERT,20120310,GBP,2
join.rightLookup.out OP_INSERT date="20120310" currency="GBP" toUsd="2" 
> pos,OP_INSERT,20120310,two,AAA,100,8,GBP
join.leftLookup.out OP_DELETE date="20120310" currency="GBP" toUsd="2" 
join.leftLookup.out OP_INSERT date="20120310" customer="two" symbol="AAA" quantity="100" price="8" currency="GBP" toUsd="2" 
> pos,OP_INSERT,20120310,three,BBB,200,80,GBP
join.leftLookup.out OP_INSERT date="20120310" customer="three" symbol="BBB" quantity="200" price="80" currency="GBP" toUsd="2" 
> pos,OP_INSERT,20120310,three,AAA,100,300,RUR
join.leftLookup.out OP_INSERT date="20120310" customer="three" symbol="AAA" quantity="100" price="300" currency="RUR" 
> cur,OP_INSERT,20120310,RUR,0.04
join.rightLookup.out OP_DELETE date="20120310" customer="three" symbol="AAA" quantity="100" price="300" currency="RUR" 
join.rightLookup.out OP_INSERT date="20120310" customer="three" symbol="AAA" quantity="100" price="300" currency="RUR" toUsd="0.04" 
> cur,OP_DELETE,20120310,GBP,2
join.rightLookup.out OP_DELETE date="20120310" customer="two" symbol="AAA" quantity="100" price="8" currency="GBP" toUsd="2" 
join.rightLookup.out OP_INSERT date="20120310" customer="two" symbol="AAA" quantity="100" price="8" currency="GBP" 
join.rightLookup.out OP_DELETE date="20120310" customer="three" symbol="BBB" quantity="200" price="80" currency="GBP" toUsd="2" 
join.rightLookup.out OP_INSERT date="20120310" customer="three" symbol="BBB" quantity="200" price="80" currency="GBP" 
> cur,OP_INSERT,20120310,GBP,2.2
join.rightLookup.out OP_DELETE date="20120310" customer="two" symbol="AAA" quantity="100" price="8" currency="GBP" 
join.rightLookup.out OP_INSERT date="20120310" customer="two" symbol="AAA" quantity="100" price="8" currency="GBP" toUsd="2.2" 
join.rightLookup.out OP_DELETE date="20120310" customer="three" symbol="BBB" quantity="200" price="80" currency="GBP" 
join.rightLookup.out OP_INSERT date="20120310" customer="three" symbol="BBB" quantity="200" price="80" currency="GBP" toUsd="2.2" 
> pos,OP_DELETE,20120310,three,BBB,200,80,GBP
join.leftLookup.out OP_DELETE date="20120310" customer="three" symbol="BBB" quantity="200" price="80" currency="GBP" toUsd="2.2" 
> pos,OP_DELETE,20120310,three,AAA,100,300,RUR
join.leftLookup.out OP_DELETE date="20120310" customer="three" symbol="AAA" quantity="100" price="300" currency="RUR" toUsd="0.04" 
join.leftLookup.out OP_INSERT date="20120310" currency="RUR" toUsd="0.04" 
');

#########################

sub doJoinFiltered {

our $uJoin = Triceps::Unit->new("uJoin");

our $tToUsd = $uJoin->makeTable($ttToUsd, "tToUsd");
our $tPosition = $uJoin->makeTable($ttPosition, "tPosition");

our $businessDay = undef;

our $lbPositionCurrent = $uJoin->makeDummyLabel(
	$tPosition->getRowType, "lbPositionCurrent");
our $lbPositionFilter = $uJoin->makeLabel($tPosition->getRowType,
	"lbPositionFilter", undef, sub {
		if ($_[1]->getRow()->get("date") >= $businessDay) {
			$uJoin->call($lbPositionCurrent->adopt($_[1]));
		}
	});
$tPosition->getOutputLabel()->chain($lbPositionFilter);

our $lbToUsdCurrent = $uJoin->makeDummyLabel(
	$tToUsd->getRowType, "lbToUsdCurrent");
our $lbToUsdFilter = $uJoin->makeLabel($tToUsd->getRowType,
	"lbToUsdFilter", undef, sub {
		if ($_[1]->getRow()->get("date") >= $businessDay) {
			$uJoin->call($lbToUsdCurrent->adopt($_[1]));
		}
	});
$tToUsd->getOutputLabel()->chain($lbToUsdFilter);

our $join = Triceps::JoinTwo->new(
	name => "join",
	leftTable => $tPosition,
	leftFromLabel => $lbPositionCurrent,
	rightTable => $tToUsd,
	rightFromLabel => $lbToUsdCurrent,
	byLeft => [ "date", "currency" ],
	type => "left",
); # would confess by itself on an error

# label to print the changes to the detailed stats
makePrintLabel("lbPrint", $join->getOutputLabel());

while(&readLine) {
	chomp;
	my @data = split(/,/); # starts with a command, then string opcode
	my $type = shift @data;
	if ($type eq "cur") {
		$uJoin->makeArrayCall($tToUsd->getInputLabel(), @data);
	} elsif ($type eq "pos") {
		$uJoin->makeArrayCall($tPosition->getInputLabel(), @data);
	} elsif ($type eq "day") { # set the business day
		$businessDay = $data[0] + 0; # convert to an int
	} elsif ($type eq "clear") { # clear the previous day
		# flush the left side first, because it's an outer join
		&clearByDate($tPosition, $ixtPositionByDate, $businessDay);
		&clearByDate($tToUsd, $ixtToUsdByDate, $businessDay);
	}
	$uJoin->drainFrame(); # just in case, for completeness
}

} # doJoinFiltered

setInputLines(
	# add the clearing for the contrast with the later filtered demo
	"day,20120310\n",
	@inputBasicJoin,
	"day,20120311\n",
	"clear\n",
);
&doJoinFiltered();
#print &getResultLines();
ok(&getResultLines(), 
'> day,20120310
> cur,OP_INSERT,20120310,USD,1
> cur,OP_INSERT,20120310,GBP,2
> cur,OP_INSERT,20120310,EUR,1.5
> pos,OP_INSERT,20120310,one,AAA,100,15,USD
join.leftLookup.out OP_INSERT date="20120310" customer="one" symbol="AAA" quantity="100" price="15" currency="USD" toUsd="1" 
> pos,OP_INSERT,20120310,two,AAA,100,8,GBP
join.leftLookup.out OP_INSERT date="20120310" customer="two" symbol="AAA" quantity="100" price="8" currency="GBP" toUsd="2" 
> pos,OP_INSERT,20120310,three,AAA,100,300,RUR
join.leftLookup.out OP_INSERT date="20120310" customer="three" symbol="AAA" quantity="100" price="300" currency="RUR" 
> pos,OP_INSERT,20120310,three,BBB,200,80,GBP
join.leftLookup.out OP_INSERT date="20120310" customer="three" symbol="BBB" quantity="200" price="80" currency="GBP" toUsd="2" 
> cur,OP_INSERT,20120310,RUR,0.04
join.rightLookup.out OP_DELETE date="20120310" customer="three" symbol="AAA" quantity="100" price="300" currency="RUR" 
join.rightLookup.out OP_INSERT date="20120310" customer="three" symbol="AAA" quantity="100" price="300" currency="RUR" toUsd="0.04" 
> cur,OP_DELETE,20120310,GBP,2
join.rightLookup.out OP_DELETE date="20120310" customer="two" symbol="AAA" quantity="100" price="8" currency="GBP" toUsd="2" 
join.rightLookup.out OP_INSERT date="20120310" customer="two" symbol="AAA" quantity="100" price="8" currency="GBP" 
join.rightLookup.out OP_DELETE date="20120310" customer="three" symbol="BBB" quantity="200" price="80" currency="GBP" toUsd="2" 
join.rightLookup.out OP_INSERT date="20120310" customer="three" symbol="BBB" quantity="200" price="80" currency="GBP" 
> cur,OP_INSERT,20120310,GBP,2.2
join.rightLookup.out OP_DELETE date="20120310" customer="two" symbol="AAA" quantity="100" price="8" currency="GBP" 
join.rightLookup.out OP_INSERT date="20120310" customer="two" symbol="AAA" quantity="100" price="8" currency="GBP" toUsd="2.2" 
join.rightLookup.out OP_DELETE date="20120310" customer="three" symbol="BBB" quantity="200" price="80" currency="GBP" 
join.rightLookup.out OP_INSERT date="20120310" customer="three" symbol="BBB" quantity="200" price="80" currency="GBP" toUsd="2.2" 
> pos,OP_DELETE,20120310,one,AAA,100,15,USD
join.leftLookup.out OP_DELETE date="20120310" customer="one" symbol="AAA" quantity="100" price="15" currency="USD" toUsd="1" 
> pos,OP_INSERT,20120310,one,AAA,200,16,USD
join.leftLookup.out OP_INSERT date="20120310" customer="one" symbol="AAA" quantity="200" price="16" currency="USD" toUsd="1" 
> day,20120311
> clear
');

