#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The examples of self-joins.

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 4 };
use Triceps;
use Triceps::X::TestFeed qw(:all);
use Carp;
ok(1); # If we made it this far, we're ok.

use strict;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#########################
# common row types and such, for the forex arbitration

our $rtRate = Triceps::RowType->new( # an exchange rate between two currencies
	ccy1 => "string", # currency code
	ccy2 => "string", # currency code
	rate => "float64", # multiplier when exchanging ccy1 to ccy2
);

# all exchange rates
our $ttRate = Triceps::TableType->new($rtRate)
	->addSubIndex("byCcy1",
		Triceps::IndexType->newHashed(key => [ "ccy1" ])
		->addSubIndex("byCcy12",
			Triceps::IndexType->newHashed(key => [ "ccy2" ])
		)
	)
	->addSubIndex("byCcy2",
		Triceps::IndexType->newHashed(key => [ "ccy2" ])
		->addSubIndex("grouping", Triceps::IndexType->newFifo())
	)
;
$ttRate->initialize();

# input for the arbitration
my @inputArb = (
	"rate,OP_INSERT,EUR,USD,1.48\n",
	"rate,OP_INSERT,USD,EUR,0.65\n",
	"rate,OP_INSERT,GBP,USD,1.98\n",
	"rate,OP_INSERT,USD,GBP,0.49\n",
	"rate,OP_INSERT,EUR,GBP,0.74\n",
	"rate,OP_INSERT,GBP,EUR,1.30\n",

	"rate,OP_DELETE,EUR,USD,1.48\n",
	"rate,OP_INSERT,EUR,USD,1.28\n",
	"rate,OP_DELETE,USD,EUR,0.65\n",
	"rate,OP_INSERT,USD,EUR,0.78\n",

	"rate,OP_DELETE,EUR,GBP,0.74\n",
	"rate,OP_INSERT,EUR,GBP,0.64\n",
);

#########################
# Arbitrate with the joins

sub doArbJoins {

our $uArb = Triceps::Unit->new("uArb");

our $tRate = $uArb->makeTable($ttRate, "tRate");

our $join1 = Triceps::JoinTwo->new(
	name => "join1",
	leftTable => $tRate,
	leftIdxPath => [ "byCcy2" ],
	leftFields => [ "ccy1", "ccy2", "rate/rate1" ],
	rightTable => $tRate,
	rightIdxPath => [ "byCcy1" ],
	rightFields => [ "ccy2/ccy3", "rate/rate2" ],
); # would die by itself on an error
our $ttJoin1 = Triceps::TableType->new($join1->getResultRowType())
	->addSubIndex("byCcy123",
		Triceps::IndexType->newHashed(key => [ "ccy1", "ccy2", "ccy3" ])
	)
	->addSubIndex("byCcy31",
		Triceps::IndexType->newHashed(key => [ "ccy3", "ccy1" ])
		->addSubIndex("grouping", Triceps::IndexType->newFifo())
	)
;
$ttJoin1->initialize();
our $tJoin1 = $uArb->makeTable($ttJoin1, "tJoin1");
$join1->getOutputLabel()->chain($tJoin1->getInputLabel());

our $join2 = Triceps::JoinTwo->new(
	name => "join2",
	leftTable => $tJoin1,
	leftIdxPath => [ "byCcy31" ],
	rightTable => $tRate,
	rightIdxPath => [ "byCcy1", "byCcy12" ],
	rightFields => [ "rate/rate3" ],
	# the field ordering in the indexes is already right, but
	# for clarity add an explicit join condition too
	byLeft => [ "ccy3/ccy1", "ccy1/ccy2" ], 
); # would die by itself on an error

# now compute the resulting circular rate and filter the profitable loops
our $rtResult = Triceps::RowType->new(
	$join2->getResultRowType()->getdef(),
	looprate => "float64",
);
my $lbResult = $uArb->makeDummyLabel($rtResult, "lbResult");
my $lbCompute = $uArb->makeLabel($join2->getResultRowType(), "lbCompute", undef, sub {
	my ($label, $rowop) = @_;
	my $row = $rowop->getRow();
	my $looprate = $row->get("rate1") * $row->get("rate2") * $row->get("rate3");

	if ($looprate > 1) {
		$uArb->makeHashCall($lbResult, $rowop->getOpcode(),
			$row->toHash(),
			looprate => $looprate,
		);
	} else {
			&send("__", $rowop->printP(), "looprate=$looprate \n"); # for debugging
	}
});
$join2->getOutputLabel()->chain($lbCompute);

# label to print the changes to the detailed stats
makePrintLabel("lbPrint", $lbResult);
#makePrintLabel("lbPrintJoin1", $join1->getOutputLabel());
#makePrintLabel("lbPrintJoin2", $join2->getOutputLabel());

while(&readLine) {
	chomp;
	my @data = split(/,/); # starts with a command, then string opcode
	my $type = shift @data;
	if ($type eq "rate") {
		$uArb->makeArrayCall($tRate->getInputLabel(), @data);
	}
	$uArb->drainFrame(); # just in case, for completeness
}

} # doArbJoins

setInputLines(@inputArb);
&doArbJoins();
#print &getResultLines();
ok(&getResultLines(), 
'> rate,OP_INSERT,EUR,USD,1.48
> rate,OP_INSERT,USD,EUR,0.65
> rate,OP_INSERT,GBP,USD,1.98
> rate,OP_INSERT,USD,GBP,0.49
> rate,OP_INSERT,EUR,GBP,0.74
__join2.leftLookup.out OP_INSERT ccy1="EUR" ccy2="GBP" rate1="0.74" ccy3="USD" rate2="1.98" rate3="0.65" looprate=0.95238 
__join2.leftLookup.out OP_INSERT ccy1="USD" ccy2="EUR" rate1="0.65" ccy3="GBP" rate2="0.74" rate3="1.98" looprate=0.95238 
__join2.rightLookup.out OP_INSERT ccy1="GBP" ccy2="USD" rate1="1.98" ccy3="EUR" rate2="0.65" rate3="0.74" looprate=0.95238 
> rate,OP_INSERT,GBP,EUR,1.30
__join2.leftLookup.out OP_INSERT ccy1="GBP" ccy2="EUR" rate1="1.3" ccy3="USD" rate2="1.48" rate3="0.49" looprate=0.94276 
__join2.leftLookup.out OP_INSERT ccy1="USD" ccy2="GBP" rate1="0.49" ccy3="EUR" rate2="1.3" rate3="1.48" looprate=0.94276 
__join2.rightLookup.out OP_INSERT ccy1="EUR" ccy2="USD" rate1="1.48" ccy3="GBP" rate2="0.49" rate3="1.3" looprate=0.94276 
> rate,OP_DELETE,EUR,USD,1.48
__join2.leftLookup.out OP_DELETE ccy1="EUR" ccy2="USD" rate1="1.48" ccy3="GBP" rate2="0.49" rate3="1.3" looprate=0.94276 
__join2.leftLookup.out OP_DELETE ccy1="GBP" ccy2="EUR" rate1="1.3" ccy3="USD" rate2="1.48" rate3="0.49" looprate=0.94276 
__join2.rightLookup.out OP_DELETE ccy1="USD" ccy2="GBP" rate1="0.49" ccy3="EUR" rate2="1.3" rate3="1.48" looprate=0.94276 
> rate,OP_INSERT,EUR,USD,1.28
__join2.leftLookup.out OP_INSERT ccy1="EUR" ccy2="USD" rate1="1.28" ccy3="GBP" rate2="0.49" rate3="1.3" looprate=0.81536 
__join2.leftLookup.out OP_INSERT ccy1="GBP" ccy2="EUR" rate1="1.3" ccy3="USD" rate2="1.28" rate3="0.49" looprate=0.81536 
__join2.rightLookup.out OP_INSERT ccy1="USD" ccy2="GBP" rate1="0.49" ccy3="EUR" rate2="1.3" rate3="1.28" looprate=0.81536 
> rate,OP_DELETE,USD,EUR,0.65
__join2.leftLookup.out OP_DELETE ccy1="USD" ccy2="EUR" rate1="0.65" ccy3="GBP" rate2="0.74" rate3="1.98" looprate=0.95238 
__join2.leftLookup.out OP_DELETE ccy1="GBP" ccy2="USD" rate1="1.98" ccy3="EUR" rate2="0.65" rate3="0.74" looprate=0.95238 
__join2.rightLookup.out OP_DELETE ccy1="EUR" ccy2="GBP" rate1="0.74" ccy3="USD" rate2="1.98" rate3="0.65" looprate=0.95238 
> rate,OP_INSERT,USD,EUR,0.78
lbResult OP_INSERT ccy1="USD" ccy2="EUR" rate1="0.78" ccy3="GBP" rate2="0.74" rate3="1.98" looprate="1.142856" 
lbResult OP_INSERT ccy1="GBP" ccy2="USD" rate1="1.98" ccy3="EUR" rate2="0.78" rate3="0.74" looprate="1.142856" 
lbResult OP_INSERT ccy1="EUR" ccy2="GBP" rate1="0.74" ccy3="USD" rate2="1.98" rate3="0.78" looprate="1.142856" 
> rate,OP_DELETE,EUR,GBP,0.74
lbResult OP_DELETE ccy1="EUR" ccy2="GBP" rate1="0.74" ccy3="USD" rate2="1.98" rate3="0.78" looprate="1.142856" 
lbResult OP_DELETE ccy1="USD" ccy2="EUR" rate1="0.78" ccy3="GBP" rate2="0.74" rate3="1.98" looprate="1.142856" 
lbResult OP_DELETE ccy1="GBP" ccy2="USD" rate1="1.98" ccy3="EUR" rate2="0.78" rate3="0.74" looprate="1.142856" 
> rate,OP_INSERT,EUR,GBP,0.64
__join2.leftLookup.out OP_INSERT ccy1="EUR" ccy2="GBP" rate1="0.64" ccy3="USD" rate2="1.98" rate3="0.78" looprate=0.988416 
__join2.leftLookup.out OP_INSERT ccy1="USD" ccy2="EUR" rate1="0.78" ccy3="GBP" rate2="0.64" rate3="1.98" looprate=0.988416 
__join2.rightLookup.out OP_INSERT ccy1="GBP" ccy2="USD" rate1="1.98" ccy3="EUR" rate2="0.78" rate3="0.64" looprate=0.988416 
');

#########################
# Arbitrate with the manual traversal

sub doArbManual {

our $uArb = Triceps::Unit->new("uArb");

our $tRate = $uArb->makeTable($ttRate, "tRate");

# now compute the resulting circular rate and filter the profitable loops
our $rtResult = Triceps::RowType->new(
	ccy1 => "string", # currency code
	ccy2 => "string", # currency code
	ccy3 => "string", # currency code
	rate1 => "float64",
	rate2 => "float64",
	rate3 => "float64",
	looprate => "float64",
);
my $ixtCcy1 = $ttRate->findSubIndex("byCcy1");
my $ixtCcy12 = $ixtCcy1->findSubIndex("byCcy12");

my $lbResult = $uArb->makeDummyLabel($rtResult, "lbResult");
my $lbCompute = $uArb->makeLabel($rtRate, "lbCompute", undef, sub {
	my ($label, $rowop) = @_;
	my $row = $rowop->getRow();
	my $ccy1 = $row->get("ccy1");
	my $ccy2 = $row->get("ccy2");
	my $rate1 = $row->get("rate");

	my $rhi = $tRate->findIdxBy($ixtCcy1, ccy1 => $ccy2);
	my $rhiEnd = $rhi->nextGroupIdx($ixtCcy12);
	for (; !$rhi->same($rhiEnd); $rhi = $rhi->nextIdx($ixtCcy12)) {
		my $row2 = $rhi->getRow();
		my $ccy3 = $row2->get("ccy2");
		my $rate2 = $row2->get("rate");

		my $rhj = $tRate->findIdxBy($ixtCcy12, ccy1 => $ccy3, ccy2 => $ccy1);
		# it's a leaf primary index, so there may be no more than one match
		next
			if ($rhj->isNull());
		my $row3 = $rhj->getRow();
		my $rate3 = $row3->get("rate");
		my $looprate = $rate1 * $rate2 * $rate3;

		# now build the row in normalized order of currencies
		&send("____Order before: $ccy1, $ccy2, $ccy3\n");
		my $result;
		if ($ccy2 lt $ccy3) {
			if ($ccy2 lt $ccy1) { # rotate left
				$result = $lbResult->makeRowopHash($rowop->getOpcode(),
					ccy1 => $ccy2,
					ccy2 => $ccy3,
					ccy3 => $ccy1,
					rate1 => $rate2,
					rate2 => $rate3,
					rate3 => $rate1,
					looprate => $looprate,
				);
			}
		} else {
			if ($ccy3 lt $ccy1) { # rotate right
				$result = $lbResult->makeRowopHash($rowop->getOpcode(),
					ccy1 => $ccy3,
					ccy2 => $ccy1,
					ccy3 => $ccy2,
					rate1 => $rate3,
					rate2 => $rate1,
					rate3 => $rate2,
					looprate => $looprate,
				);
			}
		}
		if (!defined $result) { # use the straight order
			$result = $lbResult->makeRowopHash($rowop->getOpcode(),
				ccy1 => $ccy1,
				ccy2 => $ccy2,
				ccy3 => $ccy3,
				rate1 => $rate1,
				rate2 => $rate2,
				rate3 => $rate3,
				looprate => $looprate,
			);
		}
		if ($looprate > 1) {
			$uArb->call($result);
		} else {
			&send("__", $result->printP(), "\n"); # for debugging
		}
	}
});
$tRate->getOutputLabel()->chain($lbCompute);
makePrintLabel("lbPrint", $lbResult);

while(&readLine) {
	chomp;
	my @data = split(/,/); # starts with a command, then string opcode
	my $type = shift @data;
	if ($type eq "rate") {
		$uArb->makeArrayCall($tRate->getInputLabel(), @data);
	}
	$uArb->drainFrame(); # just in case, for completeness
}

} # doArbManual

setInputLines(@inputArb);
&doArbManual();
#print &getResultLines();
ok(&getResultLines(), 
'> rate,OP_INSERT,EUR,USD,1.48
> rate,OP_INSERT,USD,EUR,0.65
> rate,OP_INSERT,GBP,USD,1.98
> rate,OP_INSERT,USD,GBP,0.49
> rate,OP_INSERT,EUR,GBP,0.74
____Order before: EUR, GBP, USD
__lbResult OP_INSERT ccy1="EUR" ccy2="GBP" ccy3="USD" rate1="0.74" rate2="1.98" rate3="0.65" looprate="0.95238" 
> rate,OP_INSERT,GBP,EUR,1.30
____Order before: GBP, EUR, USD
__lbResult OP_INSERT ccy1="EUR" ccy2="USD" ccy3="GBP" rate1="1.48" rate2="0.49" rate3="1.3" looprate="0.94276" 
> rate,OP_DELETE,EUR,USD,1.48
____Order before: EUR, USD, GBP
__lbResult OP_DELETE ccy1="EUR" ccy2="USD" ccy3="GBP" rate1="1.48" rate2="0.49" rate3="1.3" looprate="0.94276" 
> rate,OP_INSERT,EUR,USD,1.28
____Order before: EUR, USD, GBP
__lbResult OP_INSERT ccy1="EUR" ccy2="USD" ccy3="GBP" rate1="1.28" rate2="0.49" rate3="1.3" looprate="0.81536" 
> rate,OP_DELETE,USD,EUR,0.65
____Order before: USD, EUR, GBP
__lbResult OP_DELETE ccy1="EUR" ccy2="GBP" ccy3="USD" rate1="0.74" rate2="1.98" rate3="0.65" looprate="0.95238" 
> rate,OP_INSERT,USD,EUR,0.78
____Order before: USD, EUR, GBP
lbResult OP_INSERT ccy1="EUR" ccy2="GBP" ccy3="USD" rate1="0.74" rate2="1.98" rate3="0.78" looprate="1.142856" 
> rate,OP_DELETE,EUR,GBP,0.74
____Order before: EUR, GBP, USD
lbResult OP_DELETE ccy1="EUR" ccy2="GBP" ccy3="USD" rate1="0.74" rate2="1.98" rate3="0.78" looprate="1.142856" 
> rate,OP_INSERT,EUR,GBP,0.64
____Order before: EUR, GBP, USD
__lbResult OP_INSERT ccy1="EUR" ccy2="GBP" ccy3="USD" rate1="0.64" rate2="1.98" rate3="0.78" looprate="0.988416" 
');

#########################
# Arbitrate with the LookupJoins

sub doArbLookupJoins {

our $uArb = Triceps::Unit->new("uArb");

our $tRate = $uArb->makeTable($ttRate, "tRate");

our $join1 = Triceps::LookupJoin->new(
	name => "join1",
	leftFromLabel => $tRate->getOutputLabel(),
	leftFields => [ "ccy1", "ccy2", "rate/rate1" ],
	rightTable => $tRate,
	rightIdxPath => [ "byCcy1" ],
	rightFields => [ "ccy2/ccy3", "rate/rate2" ],
	byLeft => [ "ccy2/ccy1" ], 
	isLeft => 0,
); # would die by itself on an error

our $join2 = Triceps::LookupJoin->new(
	name => "join2",
	leftFromLabel => $join1->getOutputLabel(),
	rightTable => $tRate,
	rightIdxPath => [ "byCcy1", "byCcy12" ],
	rightFields => [ "rate/rate3" ],
	byLeft => [ "ccy3/ccy1", "ccy1/ccy2" ], 
	isLeft => 0,
); # would die by itself on an error

# now compute the resulting circular rate and filter the profitable loops
our $rtResult = Triceps::RowType->new(
	$join2->getResultRowType()->getdef(),
	looprate => "float64",
);
my $lbResult = $uArb->makeDummyLabel($rtResult, "lbResult");
my $lbCompute = $uArb->makeLabel($join2->getResultRowType(), "lbCompute", undef, sub {
	my ($label, $rowop) = @_;
	my $row = $rowop->getRow();

	my $ccy1 = $row->get("ccy1");
	my $ccy2 = $row->get("ccy2");
	my $ccy3 = $row->get("ccy3");
	my $rate1 = $row->get("rate1");
	my $rate2 = $row->get("rate2");
	my $rate3 = $row->get("rate3");
	my $looprate = $rate1 * $rate2 * $rate3;

	# now build the row in normalized order of currencies
	&send("____Order before: $ccy1, $ccy2, $ccy3\n");
	my $result;
	if ($ccy2 lt $ccy3) {
		if ($ccy2 lt $ccy1) { # rotate left
			$result = $lbResult->makeRowopHash($rowop->getOpcode(),
				ccy1 => $ccy2,
				ccy2 => $ccy3,
				ccy3 => $ccy1,
				rate1 => $rate2,
				rate2 => $rate3,
				rate3 => $rate1,
				looprate => $looprate,
			);
		}
	} else {
		if ($ccy3 lt $ccy1) { # rotate right
			$result = $lbResult->makeRowopHash($rowop->getOpcode(),
				ccy1 => $ccy3,
				ccy2 => $ccy1,
				ccy3 => $ccy2,
				rate1 => $rate3,
				rate2 => $rate1,
				rate3 => $rate2,
				looprate => $looprate,
			);
		}
	}
	if (!defined $result) { # use the straight order
		$result = $lbResult->makeRowopHash($rowop->getOpcode(),
			ccy1 => $ccy1,
			ccy2 => $ccy2,
			ccy3 => $ccy3,
			rate1 => $rate1,
			rate2 => $rate2,
			rate3 => $rate3,
			looprate => $looprate,
		);
	}
	if ($looprate > 1) {
		$uArb->call($result);
	} else {
		&send("__", $result->printP(), "\n"); # for debugging
	}
});
$join2->getOutputLabel()->chain($lbCompute);

# label to print the changes to the detailed stats
makePrintLabel("lbPrint", $lbResult);
#makePrintLabel("lbPrintJoin1", $join1->getOutputLabel());
#makePrintLabel("lbPrintJoin2", $join2->getOutputLabel());

while(&readLine) {
	chomp;
	my @data = split(/,/); # starts with a command, then string opcode
	my $type = shift @data;
	if ($type eq "rate") {
		$uArb->makeArrayCall($tRate->getInputLabel(), @data);
	}
	$uArb->drainFrame(); # just in case, for completeness
}

} # doArbLookupJoins

setInputLines(@inputArb);
&doArbLookupJoins();
#print &getResultLines();
ok(&getResultLines(), 
'> rate,OP_INSERT,EUR,USD,1.48
> rate,OP_INSERT,USD,EUR,0.65
> rate,OP_INSERT,GBP,USD,1.98
> rate,OP_INSERT,USD,GBP,0.49
> rate,OP_INSERT,EUR,GBP,0.74
____Order before: EUR, GBP, USD
__lbResult OP_INSERT ccy1="EUR" ccy2="GBP" rate1="0.74" ccy3="USD" rate2="1.98" rate3="0.65" looprate="0.95238" 
> rate,OP_INSERT,GBP,EUR,1.30
____Order before: GBP, EUR, USD
__lbResult OP_INSERT ccy1="EUR" ccy2="USD" rate1="1.48" ccy3="GBP" rate2="0.49" rate3="1.3" looprate="0.94276" 
> rate,OP_DELETE,EUR,USD,1.48
____Order before: EUR, USD, GBP
__lbResult OP_DELETE ccy1="EUR" ccy2="USD" rate1="1.48" ccy3="GBP" rate2="0.49" rate3="1.3" looprate="0.94276" 
> rate,OP_INSERT,EUR,USD,1.28
____Order before: EUR, USD, GBP
__lbResult OP_INSERT ccy1="EUR" ccy2="USD" rate1="1.28" ccy3="GBP" rate2="0.49" rate3="1.3" looprate="0.81536" 
> rate,OP_DELETE,USD,EUR,0.65
____Order before: USD, EUR, GBP
__lbResult OP_DELETE ccy1="EUR" ccy2="GBP" rate1="0.74" ccy3="USD" rate2="1.98" rate3="0.65" looprate="0.95238" 
> rate,OP_INSERT,USD,EUR,0.78
____Order before: USD, EUR, GBP
lbResult OP_INSERT ccy1="EUR" ccy2="GBP" rate1="0.74" ccy3="USD" rate2="1.98" rate3="0.78" looprate="1.142856" 
> rate,OP_DELETE,EUR,GBP,0.74
____Order before: EUR, GBP, USD
lbResult OP_DELETE ccy1="EUR" ccy2="GBP" rate1="0.74" ccy3="USD" rate2="1.98" rate3="0.78" looprate="1.142856" 
> rate,OP_INSERT,EUR,GBP,0.64
____Order before: EUR, GBP, USD
__lbResult OP_INSERT ccy1="EUR" ccy2="GBP" rate1="0.64" ccy3="USD" rate2="1.98" rate3="0.78" looprate="0.988416" 
');

