#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# Simple "Hello world" examples for a table.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 4 };
use Triceps;
use Triceps::X::TestFeed qw(:all);
use Carp;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#########################
# Example with the direct table ops

sub helloWorldDirect()
{
	my $hwunit = Triceps::Unit->new("hwunit");
	my $rtCount = Triceps::RowType->new(
		address => "string",
		count => "int32",
	);

	my $ttCount = Triceps::TableType->new($rtCount)
		->addSubIndex("byAddress", 
			Triceps::IndexType->newHashed(key => [ "address" ])
		)
	;
	$ttCount->initialize();

	my $tCount = $hwunit->makeTable($ttCount, "tCount");

	while(&readLine) {
		chomp;
		my @data = split(/\W+/);

		# the common part: find if there already is a count for this address
		my $rhFound = $tCount->findBy(
			address => $data[1]
		);
		my $cnt = 0;
		if (!$rhFound->isNull()) {
			$cnt = $rhFound->getRow()->get("count");
		}

		if ($data[0] =~ /^hello$/i) {
			my $new = $rtCount->makeRowHash(
				address => $data[1],
				count => $cnt+1,
			);
			$tCount->insert($new);
		} elsif ($data[0] =~ /^count$/i) {
			&send("Received '", $data[1], "' ", $cnt + 0, " times\n");
		} elsif ($data[0] =~ /^dump$/i) {
			for (my $rhi = $tCount->begin(); !$rhi->isNull(); $rhi = $rhi->next()) {
				&send($rhi->getRow->printP(), "\n");
			}
		} elsif ($data[0] =~ /^delete$/i) {
			my $res = $tCount->deleteRow($rtCount->makeRowHash(
				address => $data[1],
			));
			&send("Address '", $data[1], "' is not found\n") unless $res;
		} elsif ($data[0] =~ /^remove$/i) {
			if (!$rhFound->isNull()) {
				$tCount->remove($rhFound);
			} else {
				&send("Address '", $data[1], "' is not found\n");
			}
		} elsif ($data[0] =~ /^clear$/i) {
			my $rhi = $tCount->begin(); 
			while (!$rhi->isNull()) {
				my $rhnext = $rhi->next();
				$tCount->remove($rhi);
				$rhi = $rhnext;
			}
		} else {
			&send("Unknown command '$data[0]'\n");
		}
	}
}

#########################
# test the last example

setInputLines(
	"Hello, table!\n",
	"Hello, world!\n",
	"Hello, table!\n",
	"count world\n",
	"Count table\n",
	"dump\n",
	"delete x\n",
	"delete world\n",
	"count world\n",
	"remove y\n",
	"remove table\n",
	"count table\n",
	"Hello, table!\n",
	"Hello, table!\n",
	"Hello, table!\n",
	"Hello, world!\n",
	"count table\n",
	"clear\n",
	"dump\n",
	"goodbye, world\n",
);
&helloWorldDirect();
# XXX the result depends on the hashing order
#print &getResultLines();
ok(&getResultLines(), 
"> Hello, table!
> Hello, world!
> Hello, table!
> count world
Received 'world' 1 times
> Count table
Received 'table' 2 times
> dump
address=\"world\" count=\"1\" 
address=\"table\" count=\"2\" 
> delete x
Address 'x' is not found
> delete world
> count world
Received 'world' 0 times
> remove y
Address 'y' is not found
> remove table
> count table
Received 'table' 0 times
> Hello, table!
> Hello, table!
> Hello, table!
> Hello, world!
> count table
Received 'table' 3 times
> clear
> dump
> goodbye, world
Unknown command 'goodbye'
"
);

#########################
# An example of a wrapper over the table class

package MyTable;

sub CLONE_SKIP { 1; }

our @ISA = qw(Triceps::Table);

sub new # (class, unit, args of makeTable...)
{
	my $class = shift;
	my $unit = shift;
	my $self = $unit->makeTable(@_);
	bless $self, $class;
	return $self;
}

package main;

{
	my $hwunit = Triceps::Unit->new("hwunit");
	my $rtCount = Triceps::RowType->new(
		address => "string",
		count => "int32",
	);

	my $ttCount = Triceps::TableType->new($rtCount)
		->addSubIndex("byAddress", 
			Triceps::IndexType->newHashed(key => [ "address" ])
		)
	;
	$ttCount->initialize();

	my $tCount = MyTable->new($hwunit, $ttCount, "tCount");
	ok(ref $tCount, "MyTable");
}

#########################
# Example with the rowops used with the table.

sub helloWorldLabels()
{
	my $hwunit = Triceps::Unit->new("hwunit");
	my $rtCount = Triceps::RowType->new(
		address => "string",
		count => "int32",
	);

	my $ttCount = Triceps::TableType->new($rtCount)
		->addSubIndex("byAddress", 
			Triceps::IndexType->newHashed(key => [ "address" ])
		)
	;
	$ttCount->initialize();

	my $tCount = $hwunit->makeTable($ttCount, "tCount");

	my $lbPrintCount = $hwunit->makeLabel($tCount->getRowType(),
		"lbPrintCount", undef, sub { # (label, rowop)
			my ($label, $rowop) = @_;
			my $row = $rowop->getRow();
			&send(&Triceps::opcodeString($rowop->getOpcode), " '", 
				$row->get("address"), "', count ", $row->get("count"), "\n");
		} );
	$tCount->getOutputLabel()->chain($lbPrintCount);

	# the updates will be sent here, for the tables to process
	my $lbTableInput = $tCount->getInputLabel();

	while(&readLine) {
		chomp;
		my @data = split(/\W+/);

		# the common part: find if there already is a count for this address
		my $rhFound = $tCount->findBy(
			address => $data[1]
		);
		my $cnt = 0;
		if (!$rhFound->isNull()) {
			$cnt = $rhFound->getRow()->get("count");
		}

		if ($data[0] =~ /^hello$/i) {
			$hwunit->makeHashSchedule($lbTableInput, "OP_INSERT",
				address => $data[1],
				count => $cnt+1,
			);
		} elsif ($data[0] =~ /^clear$/i) {
			$hwunit->makeHashSchedule($lbTableInput, "OP_DELETE",
				address => $data[1]
			);
		} else {
			&send("Unknown command '$data[0]'\n");
		}
		$hwunit->drainFrame();
	}
}

#########################
# test the last example

setInputLines(
	"Hello, table!\n",
	"Hello, world!\n",
	"Hello, table!\n",
	"clear, table\n",
	"Hello, table!\n",
	"goodbye, world\n",
);
&helloWorldLabels();
#print &getResultLines();
ok(&getResultLines(), 
"> Hello, table!
OP_INSERT 'table', count 1
> Hello, world!
OP_INSERT 'world', count 1
> Hello, table!
OP_DELETE 'table', count 1
OP_INSERT 'table', count 2
> clear, table
OP_DELETE 'table', count 2
> Hello, table!
OP_INSERT 'table', count 1
> goodbye, world
Unknown command 'goodbye'
"
);

