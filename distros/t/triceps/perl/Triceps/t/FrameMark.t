#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The test for FrameMark and its handling in Unit.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 21 };
use Triceps;
use Triceps::X::TestFeed qw(:all);
use Carp;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

###################### new #################################

$u1 = Triceps::Unit->new("u1");
ok(ref $u1, "Triceps::Unit");

$u2 = Triceps::Unit->new("u2");
ok(ref $u2, "Triceps::Unit");

$m1 = Triceps::FrameMark->new("mark1");
ok(ref $m1, "Triceps::FrameMark");

$m2 = Triceps::FrameMark->new("mark2");
ok(ref $m2, "Triceps::FrameMark");

############################################################
# it's a version of the test in C++ code

@def1 = ( # a transaction received
	count => "int32", # loop count
	id => "int32", # record instance identity
);
$rt1 = Triceps::RowType->new(
	@def1
);
ok(ref $rt1, "Triceps::RowType");

sub startLoop # ($label, $rowop)
{
	my ($label, $rowop) = @_;

	my $depth = $u1->getStackDepth();
	($depth == 2) or confess "Stack depth growing to $depth";

	&send($rowop->printP(), "\n");
	$u1->setMark($m1);

	my %data = $rowop->getRow()->toHash();
	return if ($data{count} >= 3);

	if ($data{count} == 0) {
		$data{id} = 1;
		$u1->fork($labNext->makeRowop(&Triceps::OP_NOP, $rt1->makeRowHash(%data) ));
		$data{id} = 2;
		$u1->fork($labNext->makeRowop(&Triceps::OP_NOP, $rt1->makeRowHash(%data) ));
		$data{id} = 3;
		$u1->fork($labNext->makeRowop(&Triceps::OP_NOP, $rt1->makeRowHash(%data) ));
		# also test that the mark from unit 1 gets caught
		eval {
			$u2->loopAt($m1, $labu2->makeRowop(&Triceps::OP_INSERT, $rowop->getRow()));
		};
		$@ =~ s/ at \S*FrameMark[^\n]*//g; # remove the varying line number
		$@ =~ s/SCALAR\(\w+\)/SCALAR/g; # remove the varying scalar pointers
		&send("bad loopAt: $@\n");
	} else {
		$u1->call($labNext->makeRowop(&Triceps::OP_INSERT, $rowop->getRow()));
	}
}

sub nextLoop # ($label, $rowop)
{
	my ($label, $rowop) = @_;

	&send($rowop->printP(), "\n");

	my %data = $rowop->getRow()->toHash();
	$data{count}++;
	my $newrop = $labStart->makeRowop(&Triceps::OP_DELETE, $rt1->makeRowHash(%data) );
	if ($callType eq "tray") {
		my $tray = $u1->makeTray($newrop);
		$u1->loopAt($m1, $tray);
	} elsif ($callType eq "single") {
		$u1->loopAt($m1, $newrop);
	} elsif ($callType eq "fromHash") {
		$u1->makeHashLoopAt($m1, $labStart, &Triceps::OP_DELETE, %data);
	} elsif ($callType eq "fromArray") {
		# a convoluted but easiest way to get the updated data in an array
		my @adata = $rt1->makeRowHash(%data)->toArray();
		$u1->makeArrayLoopAt($m1, $labStart, &Triceps::OP_DELETE, @adata);
	}
}

$labu2 = $u2->makeDummyLabel($rt1, "labu2");
ok(ref $labu2, "Triceps::Label");

$labStart = $u1->makeLabel($rt1, "labStart", undef, \&startLoop );
ok(ref $labStart, "Triceps::Label");
$labNext = $u1->makeLabel($rt1, "labNext", undef, \&nextLoop );
ok(ref $labNext, "Triceps::Label");

$firstRow = $rt1->makeRowHash(
	count => 0,
	id => 99,
);
ok(ref $firstRow, "Triceps::Row");
$firstRowop = $labStart->makeRowop(&Triceps::OP_INSERT, $firstRow);
ok(ref $firstRowop, "Triceps::Rowop");

# run the test with single-records
setInputLines();
$callType = "single";
$u1->schedule($firstRowop);

$expect = "labStart OP_INSERT count=\"0\" id=\"99\" 
bad loopAt: Triceps::Unit::loopAt: mark belongs to a different unit 'u1'
\teval {...} called

labNext OP_NOP count=\"0\" id=\"1\" 
labNext OP_NOP count=\"0\" id=\"2\" 
labNext OP_NOP count=\"0\" id=\"3\" 
labStart OP_DELETE count=\"1\" id=\"1\" 
labNext OP_INSERT count=\"1\" id=\"1\" 
labStart OP_DELETE count=\"1\" id=\"2\" 
labNext OP_INSERT count=\"1\" id=\"2\" 
labStart OP_DELETE count=\"1\" id=\"3\" 
labNext OP_INSERT count=\"1\" id=\"3\" 
labStart OP_DELETE count=\"2\" id=\"1\" 
labNext OP_INSERT count=\"2\" id=\"1\" 
labStart OP_DELETE count=\"2\" id=\"2\" 
labNext OP_INSERT count=\"2\" id=\"2\" 
labStart OP_DELETE count=\"2\" id=\"3\" 
labNext OP_INSERT count=\"2\" id=\"3\" 
labStart OP_DELETE count=\"3\" id=\"1\" 
labStart OP_DELETE count=\"3\" id=\"2\" 
labStart OP_DELETE count=\"3\" id=\"3\" 
";

$u1->drainFrame();
ok($u1->empty());
#print &getResultLines();
ok(&getResultLines(), $expect);

# run the test with trays
setInputLines();
$callType = "tray";
$u1->schedule($firstRowop);

$u1->drainFrame();
ok($u1->empty());
#print &getResultLines();
ok(&getResultLines(), $expect);

# run the test with makeHashLoopAt
setInputLines();
$callType = "fromHash";
$u1->schedule($firstRowop);

$u1->drainFrame();
ok($u1->empty());
#print &getResultLines();
ok(&getResultLines(), $expect);

# run the test with makeArrayLoopAt
setInputLines();
$callType = "fromArray";
$u1->schedule($firstRowop);

$u1->drainFrame();
ok($u1->empty());
#print &getResultLines();
ok(&getResultLines(), $expect);

############################################################
# test of makeLoopHead()

sub doFibHead {
# compute some Fibonacci numbers in a perverse way

$uFib = Triceps::Unit->new("uFib");

my $rtFib = Triceps::RowType->new(
	iter => "int32", # iteration number
	cur => "int64", # current number
	prev => "int64", # previous number
);

my $lbPrint = $uFib->makeLabel($rtFib, "Print", undef, sub {
	&send($_[1]->getRow()->get("cur"));
});

my $lbCompute; # will fill in later

my ($lbNext, $markFib) = $uFib->makeLoopHead(
	$rtFib, "Fib", undef, sub {
		my $iter = $_[1]->getRow()->get("iter");
		if ($iter <= 1) {
			$uFib->call($lbPrint->adopt($_[1]));
		} else {
			$uFib->call($lbCompute->adopt($_[1]));
		}
	}
);

$lbCompute = $uFib->makeLabel($rtFib, "Compute", undef, sub {
	my $row = $_[1]->getRow();
	my $cur = $row->get("cur");
	$uFib->makeHashLoopAt($markFib, $lbNext, $_[1]->getOpcode(),
		iter => $row->get("iter") - 1,
		cur => $cur + $row->get("prev"),
		prev => $cur,
	);
});

my $lbMain = $uFib->makeLabel($rtFib, "Main", undef, sub {
	my $row = $_[1]->getRow();
	$uFib->makeHashCall($lbNext, $_[1]->getOpcode(),
		iter => $row->get("iter"),
		cur => 1,
		prev => 0,
	);
	&send(" is Fibonacci number ", $row->get("iter"), "\n");
});

while(&readLine) {
	chomp;
	my @data = split(/,/);
	$uFib->makeArrayCall($lbMain, @data);
	$uFib->drainFrame(); # just in case, for completeness
}

} # doFibHead

setInputLines(
	"OP_INSERT,1\n",
	"OP_DELETE,2\n",
	"OP_INSERT,5\n",
	"OP_INSERT,6\n",
);
&doFibHead();
#print &getResultLines();
ok(&getResultLines(), 
'> OP_INSERT,1
1 is Fibonacci number 1
> OP_DELETE,2
1 is Fibonacci number 2
> OP_INSERT,5
5 is Fibonacci number 5
> OP_INSERT,6
8 is Fibonacci number 6
');

############################################################
# test of makeLoopAround()

sub doFibAround {
# compute some Fibonacci numbers in a perverse way

$uFib = Triceps::Unit->new("uFib");

my $rtFib = Triceps::RowType->new(
	iter => "int32", # iteration number
	cur => "int64", # current number
	prev => "int64", # previous number
);

my $lbPrint = $uFib->makeLabel($rtFib, "Print", undef, sub {
	&send($_[1]->getRow()->get("cur"));
});

my ($lbNext, $markFib); # will fill in later

$lbCompute = $uFib->makeLabel($rtFib, "Compute", undef, sub {
	my $row = $_[1]->getRow();
	my $cur = $row->get("cur");
	my $iter = $row->get("iter");
	if ($iter <= 1) {
		$uFib->call($lbPrint->adopt($_[1]));
	} else {
		$uFib->makeHashLoopAt($markFib, $lbNext, $_[1]->getOpcode(),
			iter => $row->get("iter") - 1,
			cur => $cur + $row->get("prev"),
			prev => $cur,
		);
	}
});

($lbNext, $markFib) = $uFib->makeLoopAround(
	"Fib", $lbCompute
);

my $lbMain = $uFib->makeLabel($rtFib, "Main", undef, sub {
	my $row = $_[1]->getRow();
	$uFib->makeHashCall($lbNext, $_[1]->getOpcode(),
		iter => $row->get("iter"),
		cur => 1,
		prev => 0,
	);
	&send(" is a Fibonacci number ", $row->get("iter"), "\n");
});

while(&readLine) {
	chomp;
	my @data = split(/,/);
	$uFib->makeArrayCall($lbMain, @data);
	$uFib->drainFrame(); # just in case, for completeness
}

} # doFibAround

setInputLines(
	"OP_INSERT,1\n",
	"OP_DELETE,2\n",
	"OP_INSERT,5\n",
	"OP_INSERT,6\n",
);
&doFibAround();
#print &getResultLines();
ok(&getResultLines(), 
'> OP_INSERT,1
1 is a Fibonacci number 1
> OP_DELETE,2
1 is a Fibonacci number 2
> OP_INSERT,5
5 is a Fibonacci number 5
> OP_INSERT,6
8 is a Fibonacci number 6
');

