#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The basic example of a window (nested FIFO index).

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 6 };
use Triceps;
use Triceps::X::TestFeed qw(:all);
use Carp;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#########################
# the simple window

sub doWindow {

our $uTrades = Triceps::Unit->new("uTrades");
our $rtTrade = Triceps::RowType->new(
	id => "int32", # trade unique id
	symbol => "string", # symbol traded
	price => "float64",
	size => "float64", # number of shares traded
);

our $ttWindow = Triceps::TableType->new($rtTrade)
	->addSubIndex("bySymbol", 
		Triceps::IndexType->newHashed(key => [ "symbol" ])
			->addSubIndex("last2",
				Triceps::IndexType->newFifo(limit => 2)
			)
	)
;
$ttWindow->initialize();
our $tWindow = $uTrades->makeTable($ttWindow, "tWindow");

# remember the index type by symbol, for searching on it
our $itSymbol = $ttWindow->findSubIndex("bySymbol");
# remember the FIFO index, for finding the start of the group
our $itLast2 = $itSymbol->findSubIndex("last2");

# print out the changes to the table as they happen
our $lbWindowPrint = $uTrades->makeLabel($rtTrade, "lbWindowPrint",
	undef, sub { # (label, rowop)
		&send($_[1]->printP(), "\n"); # print the change
	});
$tWindow->getOutputLabel()->chain($lbWindowPrint);

while(&readLine) {
	chomp;
	my $rTrade = $rtTrade->makeRowArray(split(/,/));
	my $rhTrade = $tWindow->makeRowHandle($rTrade);
	$tWindow->insert($rhTrade);
	# There are two ways to find the first record for this
	# symbol. Use one way for the symbol AAA and the other for the rest.
	my $rhFirst;
	if ($rTrade->get("symbol") eq "AAA") {
		$rhFirst = $tWindow->findIdx($itSymbol, $rTrade);
	} else  {
		# $rhTrade is now in the table but it's the last record
		$rhFirst = $rhTrade->firstOfGroupIdx($itLast2);
	}
	my $rhEnd = $rhFirst->nextGroupIdx($itLast2);
	&send("New contents:\n");
	for (my $rhi = $rhFirst; 
			!$rhi->same($rhEnd); $rhi = $rhi->nextIdx($itLast2)) {
		&send("  ", $rhi->getRow()->printP(), "\n");
	}
}

}; # Window

#########################
#  run the example

setInputLines(
	"1,AAA,10,10\n",
	"2,BBB,100,100\n",
	"3,AAA,20,20\n",
	"4,BBB,200,200\n",
	"5,AAA,30,30\n",
	"6,BBB,300,300\n",
);
&doWindow();
#print &getResultLines();
ok(&getResultLines(), 
'> 1,AAA,10,10
tWindow.out OP_INSERT id="1" symbol="AAA" price="10" size="10" 
New contents:
  id="1" symbol="AAA" price="10" size="10" 
> 2,BBB,100,100
tWindow.out OP_INSERT id="2" symbol="BBB" price="100" size="100" 
New contents:
  id="2" symbol="BBB" price="100" size="100" 
> 3,AAA,20,20
tWindow.out OP_INSERT id="3" symbol="AAA" price="20" size="20" 
New contents:
  id="1" symbol="AAA" price="10" size="10" 
  id="3" symbol="AAA" price="20" size="20" 
> 4,BBB,200,200
tWindow.out OP_INSERT id="4" symbol="BBB" price="200" size="200" 
New contents:
  id="2" symbol="BBB" price="100" size="100" 
  id="4" symbol="BBB" price="200" size="200" 
> 5,AAA,30,30
tWindow.out OP_DELETE id="1" symbol="AAA" price="10" size="10" 
tWindow.out OP_INSERT id="5" symbol="AAA" price="30" size="30" 
New contents:
  id="3" symbol="AAA" price="20" size="20" 
  id="5" symbol="AAA" price="30" size="30" 
> 6,BBB,300,300
tWindow.out OP_DELETE id="2" symbol="BBB" price="100" size="100" 
tWindow.out OP_INSERT id="6" symbol="BBB" price="300" size="300" 
New contents:
  id="4" symbol="BBB" price="200" size="200" 
  id="6" symbol="BBB" price="300" size="300" 
'
);

#########################
# the window with primary and secondary index

sub doSecondary {

our $uTrades = Triceps::Unit->new("uTrades");
our $rtTrade = Triceps::RowType->new(
	id => "int32", # trade unique id
	symbol => "string", # symbol traded
	price => "float64",
	size => "float64", # number of shares traded
);

our $ttWindow = Triceps::TableType->new($rtTrade)
	->addSubIndex("byId", 
		Triceps::IndexType->newHashed(key => [ "id" ])
	)
	->addSubIndex("bySymbol", 
		Triceps::IndexType->newHashed(key => [ "symbol" ])
			->addSubIndex("last2",
				Triceps::IndexType->newFifo(limit => 2)
			)
	)
;
$ttWindow->initialize();
our $tWindow = $uTrades->makeTable($ttWindow, "tWindow");

# remember the index type by symbol, for searching on it
our $itSymbol = $ttWindow->findSubIndex("bySymbol");
# remember the FIFO index, for finding the start of the group
our $itLast2 = $itSymbol->findSubIndex("last2");

# remember, which was the last row modified
our $rLastMod;
our $lbRememberLastMod = $uTrades->makeLabel($rtTrade, "lbRememberLastMod",
	undef, sub { # (label, rowop)
		$rLastMod = $_[1]->getRow();
	});
$tWindow->getOutputLabel()->chain($lbRememberLastMod);

# Print the average price of the symbol in the last modified row
sub printAverage # (row)
{
	return unless defined $rLastMod;
	my $rhFirst = $tWindow->findIdx($itSymbol, $rLastMod);
	my $rhEnd = $rhFirst->nextGroupIdx($itLast2);
	&send("Contents:\n");
	my $avg;
	my ($sum, $count);
	for (my $rhi = $rhFirst; 
			!$rhi->same($rhEnd); $rhi = $rhi->nextIdx($itLast2)) {
		&send("  ", $rhi->getRow()->printP(), "\n");
		$count++;
		$sum += $rhi->getRow()->get("price");
	}
	if ($count) {
		$avg = $sum/$count;
	}
	&send("Average price: ", (defined $avg? $avg: "Undefined"), "\n");
}

while(&readLine) {
	chomp;
	my @data = split(/,/);
	$uTrades->makeArrayCall($tWindow->getInputLabel(), @data);
	&printAverage();
	undef $rLastMod; # clear for the next iteration
	$uTrades->drainFrame(); # just in case, for completeness
}

}; # Secondary

#########################
#  run the example

setInputLines(
	"OP_INSERT,1,AAA,10,10\n",
	"OP_INSERT,2,BBB,100,100\n",
	"OP_INSERT,3,AAA,20,20\n",
	"OP_INSERT,4,BBB,200,200\n",
	"OP_INSERT,5,AAA,30,30\n",
	"OP_INSERT,6,BBB,300,300\n",
	"OP_DELETE,3\n",
	"OP_DELETE,5\n",
);
&doSecondary();
#print &getResultLines();
ok(&getResultLines(), 
'> OP_INSERT,1,AAA,10,10
Contents:
  id="1" symbol="AAA" price="10" size="10" 
Average price: 10
> OP_INSERT,2,BBB,100,100
Contents:
  id="2" symbol="BBB" price="100" size="100" 
Average price: 100
> OP_INSERT,3,AAA,20,20
Contents:
  id="1" symbol="AAA" price="10" size="10" 
  id="3" symbol="AAA" price="20" size="20" 
Average price: 15
> OP_INSERT,4,BBB,200,200
Contents:
  id="2" symbol="BBB" price="100" size="100" 
  id="4" symbol="BBB" price="200" size="200" 
Average price: 150
> OP_INSERT,5,AAA,30,30
Contents:
  id="3" symbol="AAA" price="20" size="20" 
  id="5" symbol="AAA" price="30" size="30" 
Average price: 25
> OP_INSERT,6,BBB,300,300
Contents:
  id="4" symbol="BBB" price="200" size="200" 
  id="6" symbol="BBB" price="300" size="300" 
Average price: 250
> OP_DELETE,3
Contents:
  id="5" symbol="AAA" price="30" size="30" 
Average price: 30
> OP_DELETE,5
Contents:
Average price: Undefined
');

#########################
# the window with a manual aggregator

sub doManualAgg1 {

our $uTrades = Triceps::Unit->new("uTrades");
our $rtTrade = Triceps::RowType->new(
	id => "int32", # trade unique id
	symbol => "string", # symbol traded
	price => "float64",
	size => "float64", # number of shares traded
);

our $ttWindow = Triceps::TableType->new($rtTrade)
	->addSubIndex("byId", 
		Triceps::IndexType->newHashed(key => [ "id" ])
	)
	->addSubIndex("bySymbol", 
		Triceps::IndexType->newHashed(key => [ "symbol" ])
			->addSubIndex("last2",
				Triceps::IndexType->newFifo(limit => 2)
			)
	)
;
$ttWindow->initialize();
our $tWindow = $uTrades->makeTable($ttWindow, "tWindow");

# remember the index type by symbol, for searching on it
our $itSymbol = $ttWindow->findSubIndex("bySymbol");
# remember the FIFO index, for finding the start of the group
our $itLast2 = $itSymbol->findSubIndex("last2");

# remember, which was the last row modified
our $rLastMod;
our $lbRememberLastMod = $uTrades->makeLabel($rtTrade, "lbRememberLastMod",
	undef, sub { # (label, rowop)
		$rLastMod = $_[1]->getRow();
	});
$tWindow->getOutputLabel()->chain($lbRememberLastMod);

#####
# a manual aggregation: average price

our $rtAvgPrice = Triceps::RowType->new(
	symbol => "string", # symbol traded
	id => "int32", # last trade's id
	price => "float64", # avg price of the last 2 trades
);

# place to send the average: could be a dummy label, but to keep the
# code smaller also print the rows here, instead of in a separate label
our $lbAverage = $uTrades->makeLabel($rtAvgPrice, "lbAverage",
	undef, sub { # (label, rowop)
		&send($_[1]->printP(), "\n");
	});

# Send the average price of the symbol in the last modified row
sub computeAverage # (row)
{
	return unless defined $rLastMod;
	my $rhFirst = $tWindow->findIdx($itSymbol, $rLastMod);
	my $rhEnd = $rhFirst->nextGroupIdx($itLast2);
	&send("Contents:\n");
	my $avg = 0;
	my ($sum, $count);
	my $rhLast;
	for (my $rhi = $rhFirst; 
			!$rhi->same($rhEnd); $rhi = $rhi->nextIdx($itLast2)) {
		&send("  ", $rhi->getRow()->printP(), "\n");
		$rhLast = $rhi;
		$count++;
		$sum += $rhi->getRow()->get("price");
	}
	if ($count) {
		$avg = $sum/$count;
		$uTrades->call($lbAverage->makeRowop(&Triceps::OP_INSERT,
			$rtAvgPrice->makeRowHash(
				symbol => $rhLast->getRow()->get("symbol"),
				id => $rhLast->getRow()->get("id"),
				price => $avg
			)
		));
	}
}

while(&readLine) {
	chomp;
	my @data = split(/,/);
	$uTrades->makeArrayCall($tWindow->getInputLabel(), @data);
	&computeAverage();
	undef $rLastMod; # clear for the next iteration
	$uTrades->drainFrame(); # just in case, for completeness
}

}; # ManualAgg1

#########################
#  run the example

setInputLines(
	"OP_INSERT,1,AAA,10,10\n",
	"OP_INSERT,3,AAA,20,20\n",
	"OP_INSERT,5,AAA,30,30\n",
	"OP_DELETE,3\n",
	"OP_DELETE,5\n",
);
&doManualAgg1();
#print &getResultLines();
ok(&getResultLines(), 
'> OP_INSERT,1,AAA,10,10
Contents:
  id="1" symbol="AAA" price="10" size="10" 
lbAverage OP_INSERT symbol="AAA" id="1" price="10" 
> OP_INSERT,3,AAA,20,20
Contents:
  id="1" symbol="AAA" price="10" size="10" 
  id="3" symbol="AAA" price="20" size="20" 
lbAverage OP_INSERT symbol="AAA" id="3" price="15" 
> OP_INSERT,5,AAA,30,30
Contents:
  id="3" symbol="AAA" price="20" size="20" 
  id="5" symbol="AAA" price="30" size="30" 
lbAverage OP_INSERT symbol="AAA" id="5" price="25" 
> OP_DELETE,3
Contents:
  id="5" symbol="AAA" price="30" size="30" 
lbAverage OP_INSERT symbol="AAA" id="5" price="30" 
> OP_DELETE,5
Contents:
');

#########################
# the window with a manual aggregator and a helper table

sub doManualAgg2 {

our $uTrades = Triceps::Unit->new("uTrades");
our $rtTrade = Triceps::RowType->new(
	id => "int32", # trade unique id
	symbol => "string", # symbol traded
	price => "float64",
	size => "float64", # number of shares traded
);

our $ttWindow = Triceps::TableType->new($rtTrade)
	->addSubIndex("byId", 
		Triceps::IndexType->newHashed(key => [ "id" ])
	)
	->addSubIndex("bySymbol", 
		Triceps::IndexType->newHashed(key => [ "symbol" ])
			->addSubIndex("last2",
				Triceps::IndexType->newFifo(limit => 2)
			)
	)
;
$ttWindow->initialize();
our $tWindow = $uTrades->makeTable($ttWindow, "tWindow");

# remember the index type by symbol, for searching on it
our $itSymbol = $ttWindow->findSubIndex("bySymbol");
# remember the FIFO index, for finding the start of the group
our $itLast2 = $itSymbol->findSubIndex("last2");

# remember, which was the last row modified
our $rLastMod;
our $lbRememberLastMod = $uTrades->makeLabel($rtTrade, "lbRememberLastMod",
	undef, sub { # (label, rowop)
		$rLastMod = $_[1]->getRow();
	});
$tWindow->getOutputLabel()->chain($lbRememberLastMod);

#####
# a manual aggregation: average price

our $rtAvgPrice = Triceps::RowType->new(
	symbol => "string", # symbol traded
	id => "int32", # last trade's id
	price => "float64", # avg price of the last 2 trades
);

our $ttAvgPrice = Triceps::TableType->new($rtAvgPrice)
	->addSubIndex("bySymbol", 
		Triceps::IndexType->newHashed(key => [ "symbol" ])
	)
;
$ttAvgPrice->initialize();
our $tAvgPrice = $uTrades->makeTable($ttAvgPrice, "tAvgPrice");
our $lbAvgPriceHelper = $tAvgPrice->getInputLabel();

# place to send the average: could be a dummy label, but to keep the
# code smaller also print the rows here, instead of in a separate label
our $lbAverage = makePrintLabel("lbAverage", $tAvgPrice->getOutputLabel());

# Send the average price of the symbol in the last modified row
sub computeAverage2 # (row)
{
	return unless defined $rLastMod;
	my $rhFirst = $tWindow->findIdx($itSymbol, $rLastMod);
	my $rhEnd = $rhFirst->nextGroupIdx($itLast2);
	&send("Contents:\n");
	my $avg = 0;
	my ($sum, $count);
	my $rhLast;
	for (my $rhi = $rhFirst; 
			!$rhi->same($rhEnd); $rhi = $rhi->nextIdx($itLast2)) {
		&send("  ", $rhi->getRow()->printP(), "\n");
		$rhLast = $rhi;
		$count++;
		$sum += $rhi->getRow()->get("price");
	}
	if ($count) {
		$avg = $sum/$count;
		$uTrades->makeHashCall($lbAvgPriceHelper, &Triceps::OP_INSERT,
			symbol => $rhLast->getRow()->get("symbol"),
			id => $rhLast->getRow()->get("id"),
			price => $avg
		);
	} else {
		$uTrades->makeHashCall($lbAvgPriceHelper, &Triceps::OP_DELETE,
			symbol => $rLastMod->get("symbol"),
		);
	}
}

while(&readLine) {
	chomp;
	my @data = split(/,/);
	$uTrades->makeArrayCall($tWindow->getInputLabel(), @data);
	&computeAverage2();
	undef $rLastMod; # clear for the next iteration
	$uTrades->drainFrame(); # just in case, for completeness
}

}; # ManualAgg2

#########################
#  run the example

setInputLines(
	"OP_INSERT,1,AAA,10,10\n",
	"OP_INSERT,3,AAA,20,20\n",
	"OP_INSERT,5,AAA,30,30\n",
	"OP_DELETE,3\n",
	"OP_DELETE,5\n",
);
&doManualAgg2();
#print &getResultLines();
ok(&getResultLines(), 
'> OP_INSERT,1,AAA,10,10
Contents:
  id="1" symbol="AAA" price="10" size="10" 
tAvgPrice.out OP_INSERT symbol="AAA" id="1" price="10" 
> OP_INSERT,3,AAA,20,20
Contents:
  id="1" symbol="AAA" price="10" size="10" 
  id="3" symbol="AAA" price="20" size="20" 
tAvgPrice.out OP_DELETE symbol="AAA" id="1" price="10" 
tAvgPrice.out OP_INSERT symbol="AAA" id="3" price="15" 
> OP_INSERT,5,AAA,30,30
Contents:
  id="3" symbol="AAA" price="20" size="20" 
  id="5" symbol="AAA" price="30" size="30" 
tAvgPrice.out OP_DELETE symbol="AAA" id="3" price="15" 
tAvgPrice.out OP_INSERT symbol="AAA" id="5" price="25" 
> OP_DELETE,3
Contents:
  id="5" symbol="AAA" price="30" size="30" 
tAvgPrice.out OP_DELETE symbol="AAA" id="5" price="25" 
tAvgPrice.out OP_INSERT symbol="AAA" id="5" price="30" 
> OP_DELETE,5
Contents:
tAvgPrice.out OP_DELETE symbol="AAA" id="5" price="30" 
');

#########################
#  run the same example, demonstrating an issue with a missing DELETE

setInputLines(
	"OP_INSERT,1,AAA,10,10\n",
	"OP_INSERT,3,AAA,20,20\n",
	"OP_INSERT,5,AAA,30,30\n",
	"OP_INSERT,5,BBB,30,30\n",
	"OP_INSERT,7,AAA,40,40\n",
);
&doManualAgg2();
#print &getResultLines();
ok(&getResultLines(), 
'> OP_INSERT,1,AAA,10,10
Contents:
  id="1" symbol="AAA" price="10" size="10" 
tAvgPrice.out OP_INSERT symbol="AAA" id="1" price="10" 
> OP_INSERT,3,AAA,20,20
Contents:
  id="1" symbol="AAA" price="10" size="10" 
  id="3" symbol="AAA" price="20" size="20" 
tAvgPrice.out OP_DELETE symbol="AAA" id="1" price="10" 
tAvgPrice.out OP_INSERT symbol="AAA" id="3" price="15" 
> OP_INSERT,5,AAA,30,30
Contents:
  id="3" symbol="AAA" price="20" size="20" 
  id="5" symbol="AAA" price="30" size="30" 
tAvgPrice.out OP_DELETE symbol="AAA" id="3" price="15" 
tAvgPrice.out OP_INSERT symbol="AAA" id="5" price="25" 
> OP_INSERT,5,BBB,30,30
Contents:
  id="5" symbol="BBB" price="30" size="30" 
tAvgPrice.out OP_INSERT symbol="BBB" id="5" price="30" 
> OP_INSERT,7,AAA,40,40
Contents:
  id="3" symbol="AAA" price="20" size="20" 
  id="7" symbol="AAA" price="40" size="40" 
tAvgPrice.out OP_DELETE symbol="AAA" id="5" price="25" 
tAvgPrice.out OP_INSERT symbol="AAA" id="7" price="30" 
');
