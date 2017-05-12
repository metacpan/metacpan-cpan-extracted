#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# Exzmples with the streaming functions.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 18 };
use Triceps;
use Triceps::X::TestFeed qw(:all);
use Carp;
ok(1); # If we made it this far, we're ok.

use strict;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

############################################################
# A looping Fibonacci computation with the streaming functions.

sub doFibFn1 {
# compute some Fibonacci numbers in a perverse way

my $uFib = Triceps::Unit->new("uFib");

###
# A streaming function that computes one step of a
# Fibonacci number, will be called repeatedly.

# Type of its input and output.
my $rtFib = Triceps::RowType->new(
	iter => "int32", # number of iterations left to do
	cur => "int64", # current number
	prev => "int64", # previous number
);

# Input: 
#   $lbFibCompute: request to do a step. iter will be decremented,
#     cur moved to prev, new value of cur computed.
# Output (by FnReturn labels):
#   "next": data to send to the next step, if the iteration
#     is not finished yet (iter in the produced row is >0).
#   "result": the result data if the iretaion is finished
#     (iter in the produced row is 0).
# The opcode is preserved through the computation.

my $frFib = Triceps::FnReturn->new(
	name => "Fib",
	unit => $uFib,
	labels => [
		next => $rtFib,
		result => $rtFib,
	],
);

my $lbFibCompute = $uFib->makeLabel($rtFib, "FibCompute", undef, sub {
	my $row = $_[1]->getRow();
	my $prev = $row->get("cur");
	my $cur = $prev + $row->get("prev");
	my $iter = $row->get("iter") - 1;
	$uFib->makeHashCall($frFib->getLabel($iter > 0? "next" : "result"), $_[1]->getOpcode(),
		iter => $iter,
		cur => $cur,
		prev => $prev,
	);
});

# End of streaming function
###

my $lbPrint = $uFib->makeLabel($rtFib, "Print", undef, sub {
	&send($_[1]->getRow()->get("cur"));
});

# binding to run the Triceps steps in a loop
my $fbFibLoop = Triceps::FnBinding->new(
	name => "FibLoop",
	on => $frFib,
	withTray => 1,
	labels => [
		next => $lbFibCompute,
		result => $lbPrint,
	],
);

my $lbMain = $uFib->makeLabel($rtFib, "Main", undef, sub {
	my $row = $_[1]->getRow();
	{
		my $ab = Triceps::AutoFnBind->new($frFib, $fbFibLoop);

		# send the request into the loop
		$uFib->makeHashCall($lbFibCompute, $_[1]->getOpcode(),
			iter => $row->get("iter"),
			cur => 0, # the "0-th" number
			prev => 1,
		);

		# now keep cycling the loop until it's all done
		while (!$fbFibLoop->trayEmpty()) {
			$fbFibLoop->callTray();
		}
	}
	&send(" is Fibonacci number ", $row->get("iter"), "\n");
});

while(&readLine) {
	chomp;
	my @data = split(/,/);
	$uFib->makeArrayCall($lbMain, @data);
	$uFib->drainFrame(); # just in case, for completeness
}

} # doFibFn1

setInputLines(
	"OP_INSERT,1\n",
	"OP_DELETE,2\n",
	"OP_INSERT,5\n",
	"OP_INSERT,6\n",
);
&doFibFn1();
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
# A looping Fibonacci computation with the streaming functions
# and the final output going directly to $lbPrint, without binding.

sub doFibFn2 {
# compute some Fibonacci numbers in a perverse way

my $uFib = Triceps::Unit->new("uFib");

# Type the data going through the loop.
my $rtFib = Triceps::RowType->new(
	iter => "int32", # number of iterations left to do
	cur => "int64", # current number
	prev => "int64", # previous number
);

my $lbPrint = $uFib->makeLabel($rtFib, "Print", undef, sub {
	&send($_[1]->getRow()->get("cur"));
});

###
# A streaming function that computes one step of a
# Fibonacci number, will be called repeatedly.

# Input: 
#   $lbFibCompute: request to do a step. iter will be decremented,
#     cur moved to prev, new value of cur computed.
# Looping Output (by FnReturn labels):
#   "next": data to send to the next step, if the iteration
#     is not finished yet (iter in the produced row is >0).
# Output connections:
#   Sent to $lbPrint: the result data if the iretaion is finished
#     (iter in the produced row is 0).
# The opcode is preserved through the computation.

my $frFib = Triceps::FnReturn->new(
	name => "Fib",
	unit => $uFib,
	labels => [
		next => $rtFib,
	],
);

my $lbFibCompute = $uFib->makeLabel($rtFib, "FibCompute", undef, sub {
	my $row = $_[1]->getRow();
	my $prev = $row->get("cur");
	my $cur = $prev + $row->get("prev");
	my $iter = $row->get("iter") - 1;
	$uFib->makeHashCall($iter > 0? $frFib->getLabel("next") : $lbPrint, $_[1]->getOpcode(),
		iter => $iter,
		cur => $cur,
		prev => $prev,
	);
});

# End of streaming function
###

# binding to run the Triceps steps in a loop
my $fbFibLoop = Triceps::FnBinding->new(
	name => "FibLoop",
	on => $frFib,
	withTray => 1,
	labels => [
		next => $lbFibCompute,
	],
);

my $lbMain = $uFib->makeLabel($rtFib, "Main", undef, sub {
	my $row = $_[1]->getRow();
	{
		my $ab = Triceps::AutoFnBind->new($frFib, $fbFibLoop);

		# send the request into the loop
		$uFib->makeHashCall($lbFibCompute, $_[1]->getOpcode(),
			iter => $row->get("iter"),
			cur => 0, # the "0-th" number
			prev => 1,
		);

		# now keep cycling the loop until it's all done
		while (!$fbFibLoop->trayEmpty()) {
			$fbFibLoop->callTray();
		}
	}
	&send(" is Fibonacci number ", $row->get("iter"), "\n");
});

while(&readLine) {
	chomp;
	my @data = split(/,/);
	$uFib->makeArrayCall($lbMain, @data);
	$uFib->drainFrame(); # just in case, for completeness
}

} # doFibFn2

setInputLines(
	"OP_INSERT,1\n",
	"OP_DELETE,2\n",
	"OP_INSERT,5\n",
	"OP_INSERT,6\n",
);
&doFibFn2();
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
# A simple recursive Fibonacci computation with the streaming functions.
# Uses the FnBinding::call() and closures for recursion.

sub doFibFn3 {
# compute some Fibonacci numbers in a perverse way

my $uFib = Triceps::Unit->new("uFib");
$uFib->setMaxRecursionDepth(100);

# Type the data going into the function
my $rtFibArg = Triceps::RowType->new(
	idx => "int32", # the index of Fibonacci number to generate
);

# Type of the function result
my $rtFibRes = Triceps::RowType->new(
	idx => "int32", # the index of Fibonacci number
	fib => "int64", # the generated Fibonacci number
);

###
# A streaming function that computes a Fibonacci number.

# Input: 
#   $lbFibCompute: request to compute the number.
# Output (by FnReturn labels):
#   "result": the computed value.
# The opcode is preserved through the computation.

my $frFib = Triceps::FnReturn->new(
	name => "Fib",
	unit => $uFib,
	labels => [
		result => $rtFibRes,
	],
);

my $lbFibResult = $frFib->getLabel("result");

my $lbFibCompute; # must be defined before assignment, for recursion
$lbFibCompute = $uFib->makeLabel($rtFibArg, "FibCompute", undef, sub {
	my $row = $_[1]->getRow();
	my $op = $_[1]->getOpcode();
	my $idx = $row->get("idx");
	my $res;

	if ($idx < 1) {
		$res = 0;
	} elsif($idx == 1) {
		$res = 1;
	} else {
		my ($prev1, $prev2);
		Triceps::FnBinding::call(
			name => "FibCompute.call1",
			on => $frFib,
			unit => $uFib,
			labels => [
				result => sub {
					$prev1 = $_[1]->getRow()->get("fib");
				}
			],
			rowop => $lbFibCompute->makeRowopHash($op, 
				idx => $idx - 1,
			),
		);
		Triceps::FnBinding::call(
			name => "FibCompute.call2",
			on => $frFib,
			unit => $uFib,
			labels => [
				result => sub {
					$prev2 = $_[1]->getRow()->get("fib");
				}
			],
			rowop => $lbFibCompute->makeRowopHash($op, 
				idx => $idx - 2,
			),
		);
		$res = $prev1 + $prev2;
	}
	$uFib->makeHashCall($frFib->getLabel("result"), $op,
		idx => $idx,
		fib => $res,
	);
});

# End of streaming function
###

# binding to call the Fibonacci function and print the result
my $fbFibCall = Triceps::FnBinding->new(
	name => "FibCall",
	on => $frFib,
	unit => $uFib,
	labels => [
		result => sub {
			my $row = $_[1]->getRow();
			&send($row->get("fib"), " is Fibonacci number ", $row->get("idx"), "\n");
		}
	],
);

while(&readLine) {
	chomp;
	my @data = split(/,/);
	$uFib->callBound(
		$lbFibCompute->makeRowopArray(@data),
		$frFib => $fbFibCall,
	);
	$uFib->drainFrame(); # just in case, for completeness
}

} # doFibFn3

setInputLines(
	"OP_INSERT,1\n",
	"OP_DELETE,2\n",
	"OP_INSERT,5\n",
	"OP_INSERT,6\n",
);
&doFibFn3();
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
# A simple recursive Fibonacci computation with the streaming functions.
# This version does not create the binding calls and closures on the fly
# but communicates through the global variables.

sub doFibFn4 {
# compute some Fibonacci numbers in a perverse way

my $uFib = Triceps::Unit->new("uFib");
$uFib->setMaxRecursionDepth(100);

# Type the data going into the function
my $rtFibArg = Triceps::RowType->new(
	idx => "int32", # the index of Fibonacci number to generate
);

# Type of the function result
my $rtFibRes = Triceps::RowType->new(
	idx => "int32", # the index of Fibonacci number
	fib => "int64", # the generated Fibonacci number
);

###
# A streaming function that computes a Fibonacci number.

# Input: 
#   $lbFibCompute: request to compute the number.
# Output (by FnReturn labels):
#   "result": the computed value.
# The opcode is preserved through the computation.

my $frFib = Triceps::FnReturn->new(
	name => "Fib",
	unit => $uFib,
	labels => [
		result => $rtFibRes,
	],
);

my $tmpFib; # used to pass the result from recursive calls
my $fbFibPrev = Triceps::FnBinding->new(
	unit => $uFib,
	name => "FibPrev",
	on => $frFib,
	labels => [
		result => sub {
			$tmpFib = $_[1]->getRow()->get("fib");
		},
	],
);

my $lbFibResult = $frFib->getLabel("result");

my $lbFibCompute; # must be defined before assignment, for recursion
$lbFibCompute = $uFib->makeLabel($rtFibArg, "FibCompute", undef, sub {
	my $row = $_[1]->getRow();
	my $op = $_[1]->getOpcode();
	my $idx = $row->get("idx");
	my $res;

	if ($idx < 1) {
		$res = 0;
	} elsif($idx == 1) {
		$res = 1;
	} else {
		{
			my $ab = Triceps::AutoFnBind->new(
				$frFib => $fbFibPrev,
			);
			$uFib->makeHashCall($lbFibCompute, $op, 
				idx => $idx - 1,
			),
		}
		my $prev1 = $tmpFib;
		{
			my $ab = Triceps::AutoFnBind->new(
				$frFib => $fbFibPrev,
			);
			$uFib->makeHashCall($lbFibCompute, $op, 
				idx => $idx - 2,
			),
		}
		my $prev2 = $tmpFib;
		$res = $prev1 + $prev2;
	}
	$uFib->makeHashCall($frFib->getLabel("result"), $op,
		idx => $idx,
		fib => $res,
	);
});

# End of streaming function
###

# binding to call the Fibonacci function and print the result
my $fbFibCall = Triceps::FnBinding->new(
	name => "FibCall",
	on => $frFib,
	unit => $uFib,
	labels => [
		result => sub {
			my $row = $_[1]->getRow();
			&send($row->get("fib"), " is Fibonacci number ", $row->get("idx"), "\n");
		}
	],
);

while(&readLine) {
	chomp;
	my @data = split(/,/);
	{
		my $ab = Triceps::AutoFnBind->new(
			$frFib => $fbFibCall,
		);
		$uFib->makeArrayCall($lbFibCompute, @data);
	}
	$uFib->drainFrame(); # just in case, for completeness
}

} # doFibFn4

setInputLines(
	"OP_INSERT,1\n",
	"OP_DELETE,2\n",
	"OP_INSERT,5\n",
	"OP_INSERT,6\n",
);
&doFibFn4();
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
# A simple recursive Fibonacci computation with the streaming functions.
# This version does not create the binding calls and closures on the fly
# but uses the call context stack.

sub doFibFn5 {
# compute some Fibonacci numbers in a perverse way

my $uFib = Triceps::Unit->new("uFib");
$uFib->setMaxRecursionDepth(100);

$uFib->setTracer(Triceps::UnitTracerStringName->new(verbose => 1));

# Type the data going into the function
my $rtFibArg = Triceps::RowType->new(
	idx => "int32", # the index of Fibonacci number to generate
);

# Type of the function result
my $rtFibRes = Triceps::RowType->new(
	idx => "int32", # the index of Fibonacci number
	fib => "int64", # the generated Fibonacci number
);

###
# A streaming function that computes a Fibonacci number.

# Input: 
#   $lbFibCompute: request to compute the number.
# Output (by FnReturn labels):
#   "result": the computed value.
# The opcode is preserved through the computation.

my @stackFib; # stack of the function states
my $stateFib; # The current state

my $frFib = Triceps::FnReturn->new(
	name => "Fib",
	unit => $uFib,
	labels => [
		result => $rtFibRes,
	],
	onPush => sub { push @stackFib, $stateFib; $stateFib = { }; },
	onPop => sub { $stateFib = pop @stackFib; },
);

my $lbFibResult = $frFib->getLabel("result");

# Declare the label & binding variables in advance, to define them sequentially.
my ($lbFibCompute, $fbFibPrev1, $fbFibPrev2);
$lbFibCompute = $uFib->makeLabel($rtFibArg, "FibCompute", undef, sub {
	my $row = $_[1]->getRow();
	my $op = $_[1]->getOpcode();
	my $idx = $row->get("idx");

	if ($idx <= 1) {
		$uFib->makeHashCall($frFib->getLabel("result"), $op,
			idx => $idx,
			fib => $idx < 1 ? 0 : 1,
		);
	} else {
		$stateFib->{op} = $op;
		$stateFib->{idx} = $idx;

		$frFib->push($fbFibPrev1);
		$uFib->makeHashCall($lbFibCompute, $op, 
			idx => $idx - 1,
		);
	}
});
$fbFibPrev1 = Triceps::FnBinding->new(
	unit => $uFib,
	name => "FibPrev1",
	on => $frFib,
	labels => [
		result => sub {
			$frFib->pop($fbFibPrev1);

			$stateFib->{prev1} = $_[1]->getRow()->get("fib");

			# must prepare before pushing new state and with it new $stateFib
			my $rop = $lbFibCompute->makeRowopHash($stateFib->{op}, 
				idx => $stateFib->{idx} - 2,
			);

			$frFib->push($fbFibPrev2);
			$uFib->call($rop);
		},
	],
);
$fbFibPrev2 = Triceps::FnBinding->new(
	unit => $uFib,
	on => $frFib,
	name => "FibPrev2",
	labels => [
		result => sub {
			$frFib->pop($fbFibPrev2);

			$stateFib->{prev2} = $_[1]->getRow()->get("fib");
			$uFib->makeHashCall($frFib->getLabel("result"), $stateFib->{op},
				idx => $stateFib->{idx},
				fib => $stateFib->{prev1} + $stateFib->{prev2},
			);
		},
	],
);

# End of streaming function
###

# binding to call the Fibonacci function and print the result
my $fbFibCall = Triceps::FnBinding->new(
	name => "FibCall",
	on => $frFib,
	unit => $uFib,
	labels => [
		result => sub {
			my $row = $_[1]->getRow();
			&send($row->get("fib"), " is Fibonacci number ", $row->get("idx"), "\n");
		}
	],
);

while(&readLine) {
	chomp;
	my @data = split(/,/);
	$uFib->callBound(
		$lbFibCompute->makeRowopArray(@data),
		$frFib => $fbFibCall,
	);
	$uFib->drainFrame(); # just in case, for completeness
	&send($uFib->getTracer()->print()); # print the trace, it's entertaining
	$uFib->getTracer()->clearBuffer();
}

} # doFibFn5

setInputLines(
	"OP_INSERT,1\n",
	"OP_DELETE,2\n",
	"OP_INSERT,5\n",
	"OP_INSERT,6\n",
);
&doFibFn5();
#print &getResultLines();
ok(&getResultLines(),
"> OP_INSERT,1
1 is Fibonacci number 1
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibCall.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' after label 'FibCall.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
> OP_DELETE,2
1 is Fibonacci number 2
unit 'uFib' before label 'FibCompute' op OP_DELETE {
unit 'uFib' before label 'FibCompute' op OP_DELETE {
unit 'uFib' before label 'Fib.result' op OP_DELETE {
unit 'uFib' before label 'FibPrev1.result' (chain 'Fib.result') op OP_DELETE {
unit 'uFib' before label 'FibCompute' op OP_DELETE {
unit 'uFib' before label 'Fib.result' op OP_DELETE {
unit 'uFib' before label 'FibPrev2.result' (chain 'Fib.result') op OP_DELETE {
unit 'uFib' before label 'Fib.result' op OP_DELETE {
unit 'uFib' before label 'FibCall.result' (chain 'Fib.result') op OP_DELETE {
unit 'uFib' after label 'FibCall.result' (chain 'Fib.result') op OP_DELETE }
unit 'uFib' after label 'Fib.result' op OP_DELETE }
unit 'uFib' after label 'FibPrev2.result' (chain 'Fib.result') op OP_DELETE }
unit 'uFib' after label 'Fib.result' op OP_DELETE }
unit 'uFib' after label 'FibCompute' op OP_DELETE }
unit 'uFib' after label 'FibPrev1.result' (chain 'Fib.result') op OP_DELETE }
unit 'uFib' after label 'Fib.result' op OP_DELETE }
unit 'uFib' after label 'FibCompute' op OP_DELETE }
unit 'uFib' after label 'FibCompute' op OP_DELETE }
> OP_INSERT,5
5 is Fibonacci number 5
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibCall.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' after label 'FibCall.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
> OP_INSERT,6
8 is Fibonacci number 6
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibCall.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' after label 'FibCall.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
");

############################################################
# A simple recursive Fibonacci computation with the streaming functions.
# The version with call context stack, scoping and trays in binding.

sub doFibFn6 {
# compute some Fibonacci numbers in a perverse way

my $uFib = Triceps::Unit->new("uFib");
$uFib->setMaxRecursionDepth(100);
$uFib->setMaxStackDepth(9); # just a way to find out, how much is uses

$uFib->setTracer(Triceps::UnitTracerStringName->new(verbose => 1));

# Type the data going into the function
my $rtFibArg = Triceps::RowType->new(
	idx => "int32", # the index of Fibonacci number to generate
);

# Type of the function result
my $rtFibRes = Triceps::RowType->new(
	idx => "int32", # the index of Fibonacci number
	fib => "int64", # the generated Fibonacci number
);

###
# A streaming function that computes a Fibonacci number.

# Input: 
#   $lbFibCompute: request to compute the number.
# Output (by FnReturn labels):
#   "result": the computed value.
# The opcode is preserved through the computation.

my @stackFib; # stack of the function states
my $stateFib; # The current state

my $frFib = Triceps::FnReturn->new(
	name => "Fib",
	unit => $uFib,
	labels => [
		result => $rtFibRes,
	],
	onPush => sub { push @stackFib, $stateFib; $stateFib = { }; },
	onPop => sub { $stateFib = pop @stackFib; },
);

my $lbFibResult = $frFib->getLabel("result");

# Declare the label & binding variables in advance, to define them sequentially.
my ($lbFibCompute, $fbFibPrev1, $fbFibPrev2);
$lbFibCompute = $uFib->makeLabel($rtFibArg, "FibCompute", undef, sub {
	my $row = $_[1]->getRow();
	my $op = $_[1]->getOpcode();
	my $idx = $row->get("idx");

	if ($idx <= 1) {
		$uFib->makeHashCall($frFib->getLabel("result"), $op,
			idx => $idx,
			fib => $idx < 1 ? 0 : 1,
		);
	} else {
		$stateFib->{op} = $op;
		$stateFib->{idx} = $idx;

		{
			my $ab = Triceps::AutoFnBind->new(
				$frFib => $fbFibPrev1
			);
			$uFib->makeHashCall($lbFibCompute, $op, 
				idx => $idx - 1,
			);
		}
		$fbFibPrev1->callTray();
	}
});
$fbFibPrev1 = Triceps::FnBinding->new(
	unit => $uFib,
	name => "FibPrev1",
	on => $frFib,
	withTray => 1,
	labels => [
		result => sub {
			$stateFib->{prev1} = $_[1]->getRow()->get("fib");

			# must prepare before pushing new state and with it new $stateFib
			my $rop = $lbFibCompute->makeRowopHash($stateFib->{op}, 
				idx => $stateFib->{idx} - 2,
			);

			{
				my $ab = Triceps::AutoFnBind->new(
					$frFib => $fbFibPrev2
				);
				$uFib->call($rop);
			}
			$fbFibPrev2->callTray();
		},
	],
);
$fbFibPrev2 = Triceps::FnBinding->new(
	unit => $uFib,
	on => $frFib,
	name => "FibPrev2",
	withTray => 1,
	labels => [
		result => sub {
			$stateFib->{prev2} = $_[1]->getRow()->get("fib");
			$uFib->makeHashCall($frFib->getLabel("result"), $stateFib->{op},
				idx => $stateFib->{idx},
				fib => $stateFib->{prev1} + $stateFib->{prev2},
			);
		},
	],
);

# End of streaming function
###

# binding to call the Fibonacci function and print the result
my $fbFibCall = Triceps::FnBinding->new(
	name => "FibCall",
	on => $frFib,
	unit => $uFib,
	labels => [
		result => sub {
			my $row = $_[1]->getRow();
			&send($row->get("fib"), " is Fibonacci number ", $row->get("idx"), "\n");
		}
	],
);

while(&readLine) {
	chomp;
	my @data = split(/,/);
	$uFib->callBound(
		$lbFibCompute->makeRowopArray(@data),
		$frFib => $fbFibCall,
	);
	$uFib->drainFrame(); # just in case, for completeness
	&send($uFib->getTracer()->print()); # print the trace, it's entertaining
	$uFib->getTracer()->clearBuffer();
}

} # doFibFn6

setInputLines(
	"OP_INSERT,1\n",
	"OP_DELETE,2\n",
	"OP_INSERT,5\n",
	"OP_INSERT,6\n",
);
&doFibFn6();
#print &getResultLines();
ok(&getResultLines(),
"> OP_INSERT,1
1 is Fibonacci number 1
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibCall.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' after label 'FibCall.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
> OP_DELETE,2
1 is Fibonacci number 2
unit 'uFib' before label 'FibCompute' op OP_DELETE {
unit 'uFib' before label 'FibCompute' op OP_DELETE {
unit 'uFib' before label 'Fib.result' op OP_DELETE {
unit 'uFib' after label 'Fib.result' op OP_DELETE }
unit 'uFib' after label 'FibCompute' op OP_DELETE }
unit 'uFib' before label 'FibPrev1.result' op OP_DELETE {
unit 'uFib' before label 'FibCompute' op OP_DELETE {
unit 'uFib' before label 'Fib.result' op OP_DELETE {
unit 'uFib' after label 'Fib.result' op OP_DELETE }
unit 'uFib' after label 'FibCompute' op OP_DELETE }
unit 'uFib' before label 'FibPrev2.result' op OP_DELETE {
unit 'uFib' before label 'Fib.result' op OP_DELETE {
unit 'uFib' before label 'FibCall.result' (chain 'Fib.result') op OP_DELETE {
unit 'uFib' after label 'FibCall.result' (chain 'Fib.result') op OP_DELETE }
unit 'uFib' after label 'Fib.result' op OP_DELETE }
unit 'uFib' after label 'FibPrev2.result' op OP_DELETE }
unit 'uFib' after label 'FibPrev1.result' op OP_DELETE }
unit 'uFib' after label 'FibCompute' op OP_DELETE }
> OP_INSERT,5
5 is Fibonacci number 5
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev1.result' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev2.result' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev1.result' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev2.result' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev1.result' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev1.result' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev2.result' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev2.result' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev1.result' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev1.result' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev2.result' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev1.result' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev2.result' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev2.result' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibCall.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' after label 'FibCall.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
> OP_INSERT,6
8 is Fibonacci number 6
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev1.result' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev2.result' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev1.result' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev2.result' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev1.result' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev1.result' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev2.result' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev2.result' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev1.result' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev1.result' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev2.result' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev1.result' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev2.result' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev2.result' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev1.result' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev1.result' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev2.result' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev1.result' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev2.result' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev1.result' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev1.result' op OP_INSERT {
unit 'uFib' before label 'FibCompute' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev2.result' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev2.result' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
unit 'uFib' before label 'FibPrev2.result' op OP_INSERT {
unit 'uFib' before label 'Fib.result' op OP_INSERT {
unit 'uFib' before label 'FibCall.result' (chain 'Fib.result') op OP_INSERT {
unit 'uFib' after label 'FibCall.result' (chain 'Fib.result') op OP_INSERT }
unit 'uFib' after label 'Fib.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev2.result' op OP_INSERT }
unit 'uFib' after label 'FibPrev1.result' op OP_INSERT }
unit 'uFib' after label 'FibCompute' op OP_INSERT }
");

############################################################
# A simple recursive Fibonacci computation with the streaming functions.
# This version uses the call context stack and forking.
# It needs no label recursion!

sub doFibFn7 {
# compute some Fibonacci numbers in a perverse way

my $uFib = Triceps::Unit->new("uFib");
$uFib->setMaxStackDepth(2); # for showing off

$uFib->setTracer(Triceps::UnitTracerStringName->new(verbose => 1));

# Type the data going into the function
my $rtFibArg = Triceps::RowType->new(
	idx => "int32", # the index of Fibonacci number to generate
);

# Type of the function result
my $rtFibRes = Triceps::RowType->new(
	idx => "int32", # the index of Fibonacci number
	fib => "int64", # the generated Fibonacci number
);

###
# A streaming function that computes a Fibonacci number.

# Input: 
#   $lbFibCompute: request to compute the number.
# Output (by FnReturn labels):
#   "result": the computed value.
# The opcode is preserved through the computation.

my @stackFib; # stack of the function states
my $stateFib; # The current state

my $frFib = Triceps::FnReturn->new(
	name => "Fib",
	unit => $uFib,
	labels => [
		result => $rtFibRes,
	],
	onPush => sub { push @stackFib, $stateFib; $stateFib = { }; },
	onPop => sub { $stateFib = pop @stackFib; },
);

my $lbFibResult = $frFib->getLabel("result");

# Declare the label & binding variables in advance, to define them sequentially.
my ($lbFibCompute, $fbFibPrev1, $fbFibPrev2);
$lbFibCompute = $uFib->makeLabel($rtFibArg, "FibCompute", undef, sub {
	my $row = $_[1]->getRow();
	my $op = $_[1]->getOpcode();
	my $idx = $row->get("idx");

	if ($idx <= 1) {
		$uFib->fork($frFib->getLabel("result")->makeRowopHash($op,
			idx => $idx,
			fib => $idx < 1 ? 0 : 1,
		));
	} else {
		$stateFib->{op} = $op;
		$stateFib->{idx} = $idx;

		$frFib->push($fbFibPrev1);
		$uFib->fork($lbFibCompute->makeRowopHash($op, 
			idx => $idx - 1,
		));
	}
});
$fbFibPrev1 = Triceps::FnBinding->new(
	unit => $uFib,
	name => "FibPrev1",
	on => $frFib,
	labels => [
		result => sub {
			$frFib->pop($fbFibPrev1);

			$stateFib->{prev1} = $_[1]->getRow()->get("fib");

			# must prepare before pushing new state and with it new $stateFib
			my $rop = $lbFibCompute->makeRowopHash($stateFib->{op}, 
				idx => $stateFib->{idx} - 2,
			);

			$frFib->push($fbFibPrev2);
			$uFib->fork($rop);
		},
	],
);
$fbFibPrev2 = Triceps::FnBinding->new(
	unit => $uFib,
	on => $frFib,
	name => "FibPrev2",
	labels => [
		result => sub {
			$frFib->pop($fbFibPrev2);

			$stateFib->{prev2} = $_[1]->getRow()->get("fib");
			$uFib->fork($frFib->getLabel("result")->makeRowopHash($stateFib->{op},
				idx => $stateFib->{idx},
				fib => $stateFib->{prev1} + $stateFib->{prev2},
			));
		},
	],
);

# End of streaming function
###

# binding to call the Fibonacci function and print the result
my $fbFibCall = Triceps::FnBinding->new(
	name => "FibCall",
	on => $frFib,
	unit => $uFib,
	labels => [
		result => sub {
			my $row = $_[1]->getRow();
			&send($row->get("fib"), " is Fibonacci number ", $row->get("idx"), "\n");
		}
	],
);

while(&readLine) {
	chomp;
	my @data = split(/,/);
	$uFib->callBound(
		$lbFibCompute->makeRowopArray(@data),
		$frFib => $fbFibCall,
	);
	$uFib->drainFrame(); # just in case, for completeness
	#&send($uFib->getTracer()->print()); # print the trace, it's entertaining
	$uFib->getTracer()->clearBuffer();
}

} # doFibFn7

setInputLines(
	"OP_INSERT,1\n",
	"OP_DELETE,2\n",
	"OP_INSERT,5\n",
	"OP_INSERT,6\n",
);
&doFibFn7();
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
# A simple recursive Fibonacci computation with the streaming functions.
# Forking and the trays, it has to use the call() for everything,
# except for the pop labels that get forked. But it gives no
# beneft compared to the simpler approach without any forks.

sub doFibFn8 {
# compute some Fibonacci numbers in a perverse way

my $uFib = Triceps::Unit->new("uFib");
$uFib->setMaxRecursionDepth(100);
$uFib->setMaxStackDepth(100); # for showing off

$uFib->setTracer(Triceps::UnitTracerStringName->new(verbose => 1));

# Type the data going into the function
my $rtFibArg = Triceps::RowType->new(
	idx => "int32", # the index of Fibonacci number to generate
);

# Type of the function result
my $rtFibRes = Triceps::RowType->new(
	idx => "int32", # the index of Fibonacci number
	fib => "int64", # the generated Fibonacci number
);

###
# A streaming function that computes a Fibonacci number.

# Input: 
#   $lbFibCompute: request to compute the number.
# Output (by FnReturn labels):
#   "result": the computed value.
# The opcode is preserved through the computation.

my @stackFib; # stack of the function states
my $stateFib; # The current state

my $frFib = Triceps::FnReturn->new(
	name => "Fib",
	unit => $uFib,
	labels => [
		result => $rtFibRes,
	],
	onPush => sub { push @stackFib, $stateFib; $stateFib = { }; },
	onPop => sub { $stateFib = pop @stackFib; },
);

my $lbFibResult = $frFib->getLabel("result");

# Declare the label & binding variables in advance, to define them sequentially.
my ($lbFibCompute, $lbFibPop1, $lbFibPop2, $fbFibPrev1, $fbFibPrev2);
$lbFibCompute = $uFib->makeLabel($rtFibArg, "FibCompute", undef, sub {
	my $row = $_[1]->getRow();
	my $op = $_[1]->getOpcode();
	my $idx = $row->get("idx");

	if ($idx <= 1) {
		$uFib->call($frFib->getLabel("result")->makeRowopHash($op,
			idx => $idx,
			fib => $idx < 1 ? 0 : 1,
		));
	} else {
		$stateFib->{op} = $op;
		$stateFib->{idx} = $idx;

		$frFib->push($fbFibPrev1);
		$uFib->call($lbFibCompute->makeRowopHash($op, 
			idx => $idx - 1,
		));
		$uFib->fork($lbFibPop1->makeRowopArray($op));
	}
});
$lbFibPop1 = $uFib->makeLabel($uFib->getEmptyRowType(), "FibPop1", undef, sub {
	$frFib->pop($fbFibPrev1);
	$fbFibPrev1->callTray();
});
$fbFibPrev1 = Triceps::FnBinding->new(
	unit => $uFib,
	name => "FibPrev1",
	on => $frFib,
	withTray => 1,
	labels => [
		result => sub {
			$stateFib->{prev1} = $_[1]->getRow()->get("fib");

			# must prepare before pushing new state and with it new $stateFib
			my $rop = $lbFibCompute->makeRowopHash($stateFib->{op}, 
				idx => $stateFib->{idx} - 2,
			);

			$frFib->push($fbFibPrev2);
			$uFib->call($rop);
			$uFib->fork($lbFibPop2->makeRowopArray("OP_INSERT"));
		},
	],
);
$lbFibPop2 = $uFib->makeLabel($uFib->getEmptyRowType(), "FibPop2", undef, sub {
	$frFib->pop($fbFibPrev2);
	$fbFibPrev2->callTray();
});
$fbFibPrev2 = Triceps::FnBinding->new(
	unit => $uFib,
	on => $frFib,
	name => "FibPrev2",
	withTray => 1,
	labels => [
		result => sub {
			$stateFib->{prev2} = $_[1]->getRow()->get("fib");
			$uFib->call($frFib->getLabel("result")->makeRowopHash($stateFib->{op},
				idx => $stateFib->{idx},
				fib => $stateFib->{prev1} + $stateFib->{prev2},
			));
		},
	],
);

# End of streaming function
###

# binding to call the Fibonacci function and print the result
my $fbFibCall = Triceps::FnBinding->new(
	name => "FibCall",
	on => $frFib,
	unit => $uFib,
	labels => [
		result => sub {
			my $row = $_[1]->getRow();
			&send($row->get("fib"), " is Fibonacci number ", $row->get("idx"), "\n");
		}
	],
);

while(&readLine) {
	chomp;
	my @data = split(/,/);
	$uFib->callBound(
		$lbFibCompute->makeRowopArray(@data),
		$frFib => $fbFibCall,
	);
	$uFib->drainFrame(); # just in case, for completeness
	#&send($uFib->getTracer()->print()); # print the trace, it's entertaining
	$uFib->getTracer()->clearBuffer();
}

} # doFibFn8

setInputLines(
	"OP_INSERT,1\n",
	"OP_DELETE,2\n",
	"OP_INSERT,5\n",
	"OP_INSERT,6\n",
);
&doFibFn8();
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
# A version of Collapse that uses the binding in flushing.

package FnCollapse;

sub CLONE_SKIP { 1; }

our @ISA=qw(Triceps::Collapse);

sub new # ($class, $optName => $optValue, ...)
{
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	# Now add an FnReturn to the output of the dataset's tables.
	# One return is enough for both.
	# Also create the bindings for sending the data.
	foreach my $dataset (values %{$self->{datasets}}) {
		my $fret = Triceps::FnReturn->new(
			name => $self->{name} . "." . $dataset->{name} . ".retTbl",
			labels => [
				del => $dataset->{tbDelete}->getOutputLabel(),
				ins => $dataset->{tbInsert}->getOutputLabel(),
			],
		);
		$dataset->{fret} = $fret;

		# these variables will be compiled into the binding snippets
		my $lbOut = $dataset->{lbOut};
		my $unit = $self->{unit};
		my $OP_INSERT = &Triceps::OP_INSERT;
		my $OP_DELETE = &Triceps::OP_DELETE;

		my $fbind = Triceps::FnBinding->new(
			name => $self->{name} . "." . $dataset->{name} . ".bndTbl",
			on => $fret,
			unit => $unit,
			labels => [
				del => sub {
					if ($_[1]->isDelete()) {
						$unit->call($lbOut->adopt($_[1]));
					}
				},
				ins => sub {
					if ($_[1]->isDelete()) {
						$unit->call($lbOut->makeRowop($OP_INSERT, $_[1]->getRow()));
					}
				},
			],
		);
		$dataset->{fbind} = $fbind;
	}
	bless $self, $class;
	return $self;
}

# Override the base-class flush with a different implementation.
sub flush # ($self)
{
	my $self = shift;
	foreach my $dataset (values %{$self->{datasets}}) {
		# The binding takes care of producing and directing
		# the output. AutoFnBind will unbind when the block ends.
		my $ab = Triceps::AutoFnBind->new(
			$dataset->{fret} => $dataset->{fbind}
		);
		$dataset->{tbDelete}->clear();
		$dataset->{tbInsert}->clear();
	}
}

package main;

############################################################
# A touch-test of FnCollapse, copied and adapted from xCollapse.t.

sub doCollapse1 {

my $unit = Triceps::Unit->new("unit");

our $rtData = Triceps::RowType->new(
	# mostly copied from the traffic aggregation example
	local_ip => "string",
	remote_ip => "string",
	bytes => "int64",
);

my $collapse = FnCollapse->new(
	unit => $unit,
	name => "collapse",
	data => [
		name => "idata",
		rowType => $rtData,
		key => [ "local_ip", "remote_ip" ],
	],
);

my $lbPrint = makePrintLabel("print", $collapse->getOutputLabel("idata"));

my $lbInput = $collapse->getInputLabel("idata");

while(&readLine) {
	chomp;
	my @data = split(/,/); # starts with a command, then string opcode
	my $type = shift @data;
	if ($type eq "data") {
		my $rowop = $lbInput->makeRowopArray(@data);
		$unit->call($rowop);
		$unit->drainFrame(); # just in case, for completeness
	} elsif ($type eq "flush") {
		$collapse->flush();
	}
}

} # doCollapse1

my @collapseInputData = (
	"data,OP_INSERT,1.2.3.4,5.6.7.8,100\n",
	"data,OP_INSERT,1.2.3.4,6.7.8.9,1000\n",
	"data,OP_DELETE,1.2.3.4,6.7.8.9,1000\n",
	"flush\n",
	"data,OP_DELETE,1.2.3.4,5.6.7.8,100\n",
	"data,OP_INSERT,1.2.3.4,5.6.7.8,200\n",
	"data,OP_INSERT,1.2.3.4,6.7.8.9,2000\n",
	"flush\n",
	"data,OP_DELETE,1.2.3.4,6.7.8.9,2000\n",
	"data,OP_INSERT,1.2.3.4,6.7.8.9,3000\n",
	"data,OP_DELETE,1.2.3.4,6.7.8.9,3000\n",
	"data,OP_INSERT,1.2.3.4,6.7.8.9,4000\n",
	"data,OP_DELETE,1.2.3.4,6.7.8.9,4000\n",
	"flush\n",
	# from this point, show the ordering of multiple delete-inserts
	"data,OP_INSERT,1.1.1.1,5.5.5.5,100\n",
	"data,OP_INSERT,2.2.2.2,6.6.6.6,100\n",
	"data,OP_INSERT,3.3.3.3,7.7.7.7,100\n",
	"data,OP_INSERT,4.4.4.4,8.8.8.8,100\n",
	"flush\n",
	"data,OP_DELETE,1.1.1.1,5.5.5.5,100\n",
	"data,OP_DELETE,2.2.2.2,6.6.6.6,100\n",
	"data,OP_DELETE,3.3.3.3,7.7.7.7,100\n",
	"data,OP_DELETE,4.4.4.4,8.8.8.8,100\n",
	"data,OP_INSERT,1.1.1.1,5.5.5.5,200\n",
	"data,OP_INSERT,2.2.2.2,6.6.6.6,200\n",
	"data,OP_INSERT,3.3.3.3,7.7.7.7,200\n",
	"data,OP_INSERT,4.4.4.4,8.8.8.8,200\n",
	"data,OP_DELETE,1.1.1.1,5.5.5.5,200\n",
	"data,OP_DELETE,2.2.2.2,6.6.6.6,200\n",
	"data,OP_DELETE,3.3.3.3,7.7.7.7,200\n",
	"data,OP_DELETE,4.4.4.4,8.8.8.8,200\n",
	"data,OP_INSERT,1.1.1.1,5.5.5.5,300\n",
	"data,OP_INSERT,2.2.2.2,6.6.6.6,300\n",
	"data,OP_INSERT,3.3.3.3,7.7.7.7,300\n",
	"data,OP_INSERT,4.4.4.4,8.8.8.8,300\n",
	"flush\n",
);

my $collapseResultBase = 
'> data,OP_INSERT,1.2.3.4,5.6.7.8,100
> data,OP_INSERT,1.2.3.4,6.7.8.9,1000
> data,OP_DELETE,1.2.3.4,6.7.8.9,1000
> flush
collapse.idata.out OP_INSERT local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="100" 
> data,OP_DELETE,1.2.3.4,5.6.7.8,100
> data,OP_INSERT,1.2.3.4,5.6.7.8,200
> data,OP_INSERT,1.2.3.4,6.7.8.9,2000
> flush
collapse.idata.out OP_DELETE local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="100" 
collapse.idata.out OP_INSERT local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="200" 
collapse.idata.out OP_INSERT local_ip="1.2.3.4" remote_ip="6.7.8.9" bytes="2000" 
> data,OP_DELETE,1.2.3.4,6.7.8.9,2000
> data,OP_INSERT,1.2.3.4,6.7.8.9,3000
> data,OP_DELETE,1.2.3.4,6.7.8.9,3000
> data,OP_INSERT,1.2.3.4,6.7.8.9,4000
> data,OP_DELETE,1.2.3.4,6.7.8.9,4000
> flush
collapse.idata.out OP_DELETE local_ip="1.2.3.4" remote_ip="6.7.8.9" bytes="2000" 
> data,OP_INSERT,1.1.1.1,5.5.5.5,100
> data,OP_INSERT,2.2.2.2,6.6.6.6,100
> data,OP_INSERT,3.3.3.3,7.7.7.7,100
> data,OP_INSERT,4.4.4.4,8.8.8.8,100
> flush
collapse.idata.out OP_INSERT local_ip="3.3.3.3" remote_ip="7.7.7.7" bytes="100" 
collapse.idata.out OP_INSERT local_ip="2.2.2.2" remote_ip="6.6.6.6" bytes="100" 
collapse.idata.out OP_INSERT local_ip="4.4.4.4" remote_ip="8.8.8.8" bytes="100" 
collapse.idata.out OP_INSERT local_ip="1.1.1.1" remote_ip="5.5.5.5" bytes="100" 
> data,OP_DELETE,1.1.1.1,5.5.5.5,100
> data,OP_DELETE,2.2.2.2,6.6.6.6,100
> data,OP_DELETE,3.3.3.3,7.7.7.7,100
> data,OP_DELETE,4.4.4.4,8.8.8.8,100
> data,OP_INSERT,1.1.1.1,5.5.5.5,200
> data,OP_INSERT,2.2.2.2,6.6.6.6,200
> data,OP_INSERT,3.3.3.3,7.7.7.7,200
> data,OP_INSERT,4.4.4.4,8.8.8.8,200
> data,OP_DELETE,1.1.1.1,5.5.5.5,200
> data,OP_DELETE,2.2.2.2,6.6.6.6,200
> data,OP_DELETE,3.3.3.3,7.7.7.7,200
> data,OP_DELETE,4.4.4.4,8.8.8.8,200
> data,OP_INSERT,1.1.1.1,5.5.5.5,300
> data,OP_INSERT,2.2.2.2,6.6.6.6,300
> data,OP_INSERT,3.3.3.3,7.7.7.7,300
> data,OP_INSERT,4.4.4.4,8.8.8.8,300
> flush
';

{
# data and result copied from xCollapse.t
my @inputData = @collapseInputData;

# XXX here the result order depends on the hash order
my $expectResult = $collapseResultBase .
'collapse.idata.out OP_DELETE local_ip="3.3.3.3" remote_ip="7.7.7.7" bytes="100" 
collapse.idata.out OP_DELETE local_ip="2.2.2.2" remote_ip="6.6.6.6" bytes="100" 
collapse.idata.out OP_DELETE local_ip="4.4.4.4" remote_ip="8.8.8.8" bytes="100" 
collapse.idata.out OP_DELETE local_ip="1.1.1.1" remote_ip="5.5.5.5" bytes="100" 
collapse.idata.out OP_INSERT local_ip="3.3.3.3" remote_ip="7.7.7.7" bytes="300" 
collapse.idata.out OP_INSERT local_ip="2.2.2.2" remote_ip="6.6.6.6" bytes="300" 
collapse.idata.out OP_INSERT local_ip="4.4.4.4" remote_ip="8.8.8.8" bytes="300" 
collapse.idata.out OP_INSERT local_ip="1.1.1.1" remote_ip="5.5.5.5" bytes="300" 
';

setInputLines(@inputData);
&doCollapse1();
#print &getResultLines();
ok(&getResultLines(), $expectResult);
}

############################################################
# A version of Collapse that uses the binding in flushing
# and keeps the deletes and inserts close in its output.

package FnCollapseClose;

sub CLONE_SKIP { 1; }

our @ISA=qw(FnCollapse);

sub new # ($class, $optName => $optValue, ...)
{
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	# Now add an FnReturn to the output of the dataset's tables.
	# One return is enough for both.
	# Also create the bindings for sending the data.
	foreach my $dataset (values %{$self->{datasets}}) {
		my $fret = Triceps::FnReturn->new(
			name => $self->{name} . "." . $dataset->{name} . ".retTbl",
			labels => [
				del => $dataset->{tbDelete}->getOutputLabel(),
				ins => $dataset->{tbInsert}->getOutputLabel(),
			],
		);
		$dataset->{fret} = $fret;

		# these variables will be compiled into the binding snippets
		my $lbInsInput = $dataset->{tbInsert}->getInputLabel();
		my $lbOut = $dataset->{lbOut};
		my $unit = $self->{unit};
		my $OP_INSERT = &Triceps::OP_INSERT;
		my $OP_DELETE = &Triceps::OP_DELETE;

		my $fbind = Triceps::FnBinding->new(
			name => $self->{name} . "." . $dataset->{name} . ".bndTbl",
			on => $fret,
			unit => $unit,
			labels => [
				del => sub {
					if ($_[1]->isDelete()) {
						$unit->call($lbOut->adopt($_[1]));
						# If the INSERT is available after this DELETE, this
						# will produce it.
						$unit->call($lbInsInput->adopt($_[1]));
					}
				},
				ins => sub {
					if ($_[1]->isDelete()) {
						$unit->call($lbOut->makeRowop($OP_INSERT, $_[1]->getRow()));
					}
				},
			],
		);
		$dataset->{fbind} = $fbind;
	}
	bless $self, $class;
	return $self;
}

package main;

############################################################
# A touch-test of FnCollapseClose, exactly the same as doCollapse1
# only using a different collapse class.

sub doCollapse2 {

my $unit = Triceps::Unit->new("unit");

our $rtData = Triceps::RowType->new(
	# mostly copied from the traffic aggregation example
	local_ip => "string",
	remote_ip => "string",
	bytes => "int64",
);

my $collapse = FnCollapseClose->new(
	unit => $unit,
	name => "collapse",
	data => [
		name => "idata",
		rowType => $rtData,
		key => [ "local_ip", "remote_ip" ],
	],
);

my $lbPrint = makePrintLabel("print", $collapse->getOutputLabel("idata"));

my $lbInput = $collapse->getInputLabel("idata");

while(&readLine) {
	chomp;
	my @data = split(/,/); # starts with a command, then string opcode
	my $type = shift @data;
	if ($type eq "data") {
		my $rowop = $lbInput->makeRowopArray(@data);
		$unit->call($rowop);
		$unit->drainFrame(); # just in case, for completeness
	} elsif ($type eq "flush") {
		$collapse->flush();
	}
}

} # doCollapse2

my $collapseResultInterleaved = $collapseResultBase .
'collapse.idata.out OP_DELETE local_ip="3.3.3.3" remote_ip="7.7.7.7" bytes="100" 
collapse.idata.out OP_INSERT local_ip="3.3.3.3" remote_ip="7.7.7.7" bytes="300" 
collapse.idata.out OP_DELETE local_ip="2.2.2.2" remote_ip="6.6.6.6" bytes="100" 
collapse.idata.out OP_INSERT local_ip="2.2.2.2" remote_ip="6.6.6.6" bytes="300" 
collapse.idata.out OP_DELETE local_ip="4.4.4.4" remote_ip="8.8.8.8" bytes="100" 
collapse.idata.out OP_INSERT local_ip="4.4.4.4" remote_ip="8.8.8.8" bytes="300" 
collapse.idata.out OP_DELETE local_ip="1.1.1.1" remote_ip="5.5.5.5" bytes="100" 
collapse.idata.out OP_INSERT local_ip="1.1.1.1" remote_ip="5.5.5.5" bytes="300" 
';

{
# data and result copied from xCollapse.t
my @inputData = @collapseInputData;

# XXX here the result order depends on the hash order
my $expectResult = $collapseResultInterleaved;

setInputLines(@inputData);
&doCollapse2();
#print &getResultLines();
ok(&getResultLines(), $expectResult);
}

############################################################
# A version of Collapse that uses the binding in flushing
# and keeps the deletes and inserts close in its output.
# In this version the propagation of Delete table flush
# is done by chaining.

package FnCollapseClose3;

sub CLONE_SKIP { 1; }

our @ISA=qw(FnCollapse);

sub new # ($class, $optName => $optValue, ...)
{
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	# Now add an FnReturn to the output of the dataset's tables.
	# One return is enough for both.
	# Also create the bindings for sending the data.
	foreach my $dataset (values %{$self->{datasets}}) {
		my $fret = Triceps::FnReturn->new(
			name => $self->{name} . "." . $dataset->{name} . ".retTbl",
			labels => [
				del => $dataset->{tbDelete}->getOutputLabel(),
				ins => $dataset->{tbInsert}->getOutputLabel(),
			],
		);
		$dataset->{fret} = $fret;

		# these variables will be compiled into the binding snippets
		my $lbInsInput = $dataset->{tbInsert}->getInputLabel();
		my $lbOut = $dataset->{lbOut};
		my $unit = $self->{unit};
		my $OP_INSERT = &Triceps::OP_INSERT;
		my $OP_DELETE = &Triceps::OP_DELETE;

		# The clearing of Delete table on flush propagates
		# to the output and to the Insert table.
		my $lbDel = $unit->makeDummyLabel(
			$dataset->{tbDelete}->getOutputLabel()->getRowType(), 
			$self->{name} . "." . $dataset->{name} . ".lbDel");
		$lbDel->chain($lbOut);
		$lbDel->chain($lbInsInput);

		my $fbind = Triceps::FnBinding->new(
			name => $self->{name} . "." . $dataset->{name} . ".bndTbl",
			on => $fret,
			unit => $unit,
			labels => [
				del => $lbDel,
				ins => sub {
					$unit->call($lbOut->makeRowop($OP_INSERT, $_[1]->getRow()));
				},
			],
		);
		$dataset->{fbind} = $fbind;
	}
	bless $self, $class;
	return $self;
}

package main;

############################################################
# A touch-test of FnCollapseClose3, exactly the same as doCollapse1
# only using a different collapse class.

sub doCollapse3 {

my $unit = Triceps::Unit->new("unit");

our $rtData = Triceps::RowType->new(
	# mostly copied from the traffic aggregation example
	local_ip => "string",
	remote_ip => "string",
	bytes => "int64",
);

my $collapse = FnCollapseClose3->new(
	unit => $unit,
	name => "collapse",
	data => [
		name => "idata",
		rowType => $rtData,
		key => [ "local_ip", "remote_ip" ],
	],
);

my $lbPrint = makePrintLabel("print", $collapse->getOutputLabel("idata"));

my $lbInput = $collapse->getInputLabel("idata");

while(&readLine) {
	chomp;
	my @data = split(/,/); # starts with a command, then string opcode
	my $type = shift @data;
	if ($type eq "data") {
		my $rowop = $lbInput->makeRowopArray(@data);
		$unit->call($rowop);
		$unit->drainFrame(); # just in case, for completeness
	} elsif ($type eq "flush") {
		$collapse->flush();
	}
}

} # doCollapse3

{
# data and result copied from xCollapse.t
my @inputData = @collapseInputData;

# XXX here the result order depends on the hash order
# The data is the same as before, except for the delete's label name
# on output.
my $expectResult = 
'> data,OP_INSERT,1.2.3.4,5.6.7.8,100
> data,OP_INSERT,1.2.3.4,6.7.8.9,1000
> data,OP_DELETE,1.2.3.4,6.7.8.9,1000
> flush
collapse.idata.out OP_INSERT local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="100" 
> data,OP_DELETE,1.2.3.4,5.6.7.8,100
> data,OP_INSERT,1.2.3.4,5.6.7.8,200
> data,OP_INSERT,1.2.3.4,6.7.8.9,2000
> flush
collapse.idata.lbDel OP_DELETE local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="100" 
collapse.idata.out OP_INSERT local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="200" 
collapse.idata.out OP_INSERT local_ip="1.2.3.4" remote_ip="6.7.8.9" bytes="2000" 
> data,OP_DELETE,1.2.3.4,6.7.8.9,2000
> data,OP_INSERT,1.2.3.4,6.7.8.9,3000
> data,OP_DELETE,1.2.3.4,6.7.8.9,3000
> data,OP_INSERT,1.2.3.4,6.7.8.9,4000
> data,OP_DELETE,1.2.3.4,6.7.8.9,4000
> flush
collapse.idata.lbDel OP_DELETE local_ip="1.2.3.4" remote_ip="6.7.8.9" bytes="2000" 
> data,OP_INSERT,1.1.1.1,5.5.5.5,100
> data,OP_INSERT,2.2.2.2,6.6.6.6,100
> data,OP_INSERT,3.3.3.3,7.7.7.7,100
> data,OP_INSERT,4.4.4.4,8.8.8.8,100
> flush
collapse.idata.out OP_INSERT local_ip="3.3.3.3" remote_ip="7.7.7.7" bytes="100" 
collapse.idata.out OP_INSERT local_ip="2.2.2.2" remote_ip="6.6.6.6" bytes="100" 
collapse.idata.out OP_INSERT local_ip="4.4.4.4" remote_ip="8.8.8.8" bytes="100" 
collapse.idata.out OP_INSERT local_ip="1.1.1.1" remote_ip="5.5.5.5" bytes="100" 
> data,OP_DELETE,1.1.1.1,5.5.5.5,100
> data,OP_DELETE,2.2.2.2,6.6.6.6,100
> data,OP_DELETE,3.3.3.3,7.7.7.7,100
> data,OP_DELETE,4.4.4.4,8.8.8.8,100
> data,OP_INSERT,1.1.1.1,5.5.5.5,200
> data,OP_INSERT,2.2.2.2,6.6.6.6,200
> data,OP_INSERT,3.3.3.3,7.7.7.7,200
> data,OP_INSERT,4.4.4.4,8.8.8.8,200
> data,OP_DELETE,1.1.1.1,5.5.5.5,200
> data,OP_DELETE,2.2.2.2,6.6.6.6,200
> data,OP_DELETE,3.3.3.3,7.7.7.7,200
> data,OP_DELETE,4.4.4.4,8.8.8.8,200
> data,OP_INSERT,1.1.1.1,5.5.5.5,300
> data,OP_INSERT,2.2.2.2,6.6.6.6,300
> data,OP_INSERT,3.3.3.3,7.7.7.7,300
> data,OP_INSERT,4.4.4.4,8.8.8.8,300
> flush
collapse.idata.lbDel OP_DELETE local_ip="3.3.3.3" remote_ip="7.7.7.7" bytes="100" 
collapse.idata.out OP_INSERT local_ip="3.3.3.3" remote_ip="7.7.7.7" bytes="300" 
collapse.idata.lbDel OP_DELETE local_ip="2.2.2.2" remote_ip="6.6.6.6" bytes="100" 
collapse.idata.out OP_INSERT local_ip="2.2.2.2" remote_ip="6.6.6.6" bytes="300" 
collapse.idata.lbDel OP_DELETE local_ip="4.4.4.4" remote_ip="8.8.8.8" bytes="100" 
collapse.idata.out OP_INSERT local_ip="4.4.4.4" remote_ip="8.8.8.8" bytes="300" 
collapse.idata.lbDel OP_DELETE local_ip="1.1.1.1" remote_ip="5.5.5.5" bytes="100" 
collapse.idata.out OP_INSERT local_ip="1.1.1.1" remote_ip="5.5.5.5" bytes="300" 
';

setInputLines(@inputData);
&doCollapse3();
#print &getResultLines();
ok(&getResultLines(), $expectResult);
}

############################################################
# Symbology look-up.
# Provides the ISIN codes for RIC in various records.
# It's not the easiest way to do things but for the sake
# of demonstration it works in the SQLy fashion.

sub doSymbology {

my $unit = Triceps::Unit->new("unit");

###########
# The streaming function that looks up the ISIN if needed and enriches
# its knowledge of ISINs if possible.
#
# The input data is a pair of (RIC, ISIN), either of which can be empty.
# If the input has both RIC and ISIN, and the table doesn't have this
# match, it's inserted into the table for the future.
# If the input has only RIC, the ISIN is looked up from the table
# (if the table has it), and both ar returned.
# If the input has no RIC, it's passed as-is to the output.

# Data for the ISIN enrichment. It will be both stored in the
# reference table, and passed around during the function calls.
my $rtIsin = Triceps::RowType->new(
	ric => "string",
	isin => "string",
);

my $ttIsin = Triceps::TableType->new($rtIsin)
	->addSubIndex("byRic", Triceps::IndexType->newHashed(key => [ "ric" ])
); 
$ttIsin->initialize();

my $tIsin = $unit->makeTable($ttIsin, "tIsin");

# the results will come from here
my $fretLookupIsin = Triceps::FnReturn->new(
	name => "fretLookupIsin",
	unit => $unit,
	labels => [
		result => $rtIsin,
	],
);

# The function argument: the input data will be sent here.
my $lbLookupIsin = $unit->makeLabel($rtIsin, "lbLookupIsin", undef, sub {
	my $row = $_[1]->getRow();
	if ($row->get("ric")) {
		my $argrh = $tIsin->makeRowHandle($row);
		my $rh = $tIsin->find($argrh);
		if ($rh->isNull()) {
			if ($row->get("isin")) {
				$tIsin->insert($argrh);
			}
		} else {
			$row = $rh->getRow();
		}
	}
	$unit->call($fretLookupIsin->getLabel("result")->makeRowop("OP_INSERT", $row));
});

###########

# The data will be coming in multiple varieties, each doing its own call.
# This example shows only one variety, the rest are similar.

my $rtTrade = Triceps::RowType->new(
	ric => "string",
	isin => "string",
	size => "float64",
	price => "float64",
);

my $lbTradeEnriched = $unit->makeDummyLabel($rtTrade, "lbTradeEnriched");
my $lbTrade = $unit->makeLabel($rtTrade, "lbTrade", undef, sub {
	my $rowop = $_[1];
	my $row = $rowop->getRow();
	Triceps::FnBinding::call(
		name => "callTradeLookupIsin",
		on => $fretLookupIsin,
		unit => $unit,
		rowop => $lbLookupIsin->makeRowopHash("OP_INSERT", 
			ric => $row->get("ric"),
			isin => $row->get("isin"),
		),
		labels => [
			result => sub { # a label will be created from this sub
				$unit->call($lbTradeEnriched->makeRowop($rowop->getOpcode(),
					$row->copymod(
						isin => $_[1]->getRow()->get("isin")
					)
				));
			},
		],
	);
});

###########

# print what is going on
my $lbPrintIsin = makePrintLabel("printIsin", $tIsin->getOutputLabel());
my $lbPrintTrade = makePrintLabel("printTrade", $lbTradeEnriched);

# the main loop
my %dispatch = (
	isin => $tIsin->getInputLabel(),
	trade => $lbTrade,
);

while(&readLine) {
	chomp;
	my @data = split(/,/); # starts with a command, then string opcode
	my $type = shift @data;
	my $lb = $dispatch{$type};
	my $rowop = $lb->makeRowopArray(@data);
	$unit->call($rowop);
	$unit->drainFrame(); # just in case, for completeness
}

}; # doSymbology

setInputLines(
	"isin,OP_INSERT,ABC.L,US0000012345\n",
	"isin,OP_INSERT,ABC.N,US0000012345\n",
	"isin,OP_INSERT,DEF.N,US0000054321\n",
	"trade,OP_INSERT,ABC.L,,100,10.5\n",
	"trade,OP_DELETE,ABC.N,,200,10.5\n",
	"trade,OP_INSERT,GHI.N,,300,10.5\n",
	"trade,OP_INSERT,,XX0000012345,400,10.5\n",
	"trade,OP_INSERT,GHI.N,XX0000012345,500,10.5\n",
	"trade,OP_INSERT,GHI.N,,600,10.5\n",
);
&doSymbology();
#print &getResultLines();
ok(&getResultLines(), 
'> isin,OP_INSERT,ABC.L,US0000012345
tIsin.out OP_INSERT ric="ABC.L" isin="US0000012345" 
> isin,OP_INSERT,ABC.N,US0000012345
tIsin.out OP_INSERT ric="ABC.N" isin="US0000012345" 
> isin,OP_INSERT,DEF.N,US0000054321
tIsin.out OP_INSERT ric="DEF.N" isin="US0000054321" 
> trade,OP_INSERT,ABC.L,,100,10.5
lbTradeEnriched OP_INSERT ric="ABC.L" isin="US0000012345" size="100" price="10.5" 
> trade,OP_DELETE,ABC.N,,200,10.5
lbTradeEnriched OP_DELETE ric="ABC.N" isin="US0000012345" size="200" price="10.5" 
> trade,OP_INSERT,GHI.N,,300,10.5
lbTradeEnriched OP_INSERT ric="GHI.N" isin="" size="300" price="10.5" 
> trade,OP_INSERT,,XX0000012345,400,10.5
lbTradeEnriched OP_INSERT ric="" isin="XX0000012345" size="400" price="10.5" 
> trade,OP_INSERT,GHI.N,XX0000012345,500,10.5
tIsin.out OP_INSERT ric="GHI.N" isin="XX0000012345" 
lbTradeEnriched OP_INSERT ric="GHI.N" isin="XX0000012345" size="500" price="10.5" 
> trade,OP_INSERT,GHI.N,,600,10.5
lbTradeEnriched OP_INSERT ric="GHI.N" isin="XX0000012345" size="600" price="10.5" 
');

############################################################
# A pipeline example, performing the encryption.

# A template to make a label that prints the data passing through the
# parent label into strings that are sent to the output label.
sub makePipePrintLabel($$$) # ($print_label_name, $parent_label, $out_label)
{
	my $name = shift;
	my $lbParent = shift;
	my $lbOutput = shift;
	my $unit = $lbOutput->getUnit();
	my $lb = $lbParent->getUnit()->makeLabel($lbParent->getType(), $name,
		undef, sub { # (label, rowop)
			$unit->makeArrayCall(
				$lbOutput, "OP_INSERT", $_[1]->printP());
		});
	$lbParent->chain($lb);
	return $lb;
}

sub doEncPipeline {

my $unit = Triceps::Unit->new("unit");

# All the input and output gets converted through an intermediate
# format of a row with one string field.
my $rtString = Triceps::RowType->new(
	s => "string"
);

# All the input gets sent here.
my $lbReceive = $unit->makeDummyLabel($rtString, "lbReceive");
my $retReceive = Triceps::FnReturn->new(
	name => "retReceive",
	labels => [
		data => $lbReceive,
	],
);

# The binding that actually prints the output.
my $bindSend = Triceps::FnBinding->new(
	name => "bindSend",
	on => $retReceive, # any matching return will do
	unit => $unit,
	labels => [
		data => sub {
			&send($_[1]->getRow()->get("s"), "\n");
		},
	],
);

my %dispatch; # the dispatch table will be set here

# The binding that dispatches the input data
my $bindDispatch = Triceps::FnBinding->new(
	name => "bindDispatch",
	on => $retReceive,
	unit => $unit,
	labels => [
		data => sub {
			my @data = split(/,/, $_[1]->getRow()->get("s")); # starts with a command, then string opcode
			my $type = shift @data;
			my $lb = $dispatch{$type};
			my $rowop = $lb->makeRowopArray(@data);
			$unit->call($rowop);
		},
	],
);

# All the output gets converted to rtString and sent here.
my $lbOutput = $unit->makeDummyLabel($rtString, "lbOutput");
my $retOutput = Triceps::FnReturn->new(
	name => "retOutput",
	labels => [
		data => $lbOutput,
	],
);

# The encryption pipeline element.
my $retEncrypt = Triceps::FnReturn->new(
	name => "retEncrypt",
	unit => $unit,
	labels => [
		data => $rtString,
	],
);
my $lbEncrypt = $retEncrypt->getLabel("data");
my $bindEncrypt = Triceps::FnBinding->new(
	name => "bindEncrypt",
	on => $retReceive,
	unit => $unit,
	labels => [
		data => sub {
			my $s = $_[1]->getRow()->get("s");
			$unit->makeArrayCall($lbEncrypt, "OP_INSERT", unpack("H*", $s));
		},
	],
);

# The decryption pipeline element.
my $retDecrypt = Triceps::FnReturn->new(
	name => "retDecrypt",
	unit => $unit,
	labels => [
		data => $rtString,
	],
);
my $lbDecrypt = $retDecrypt->getLabel("data");
my $bindDecrypt = Triceps::FnBinding->new(
	name => "bindDecrypt",
	on => $retReceive,
	unit => $unit,
	labels => [
		data => sub {
			my $s = $_[1]->getRow()->get("s");
			$unit->makeArrayCall($lbDecrypt, "OP_INSERT", pack("H*", $s));
		},
	],
);

# The body of the model: pass through the name, increase the count.
my $rtData = Triceps::RowType->new(
	name => "string",
	count => "int32",
);

my $lbIncResult = $unit->makeDummyLabel($rtData, "result");
my $lbInc = $unit->makeLabel($rtData, "inc", undef, sub {
	my $row = $_[1]->getRow();
	$unit->makeHashCall($lbIncResult, $_[1]->getOpcode(),
		name  => $row->get("name"),
		count => $row->get("count") + 1,
	);
});
makePipePrintLabel("printResult", $lbIncResult, $lbOutput);

%dispatch = (
	inc => $lbInc,
);

# The main loop.
while(&readLine) {
	my $ab;
	chomp;
	if (/^\+/) {
		$ab = Triceps::AutoFnBind->new(
			$retReceive => $bindDecrypt,
			$retDecrypt => $bindDispatch,
			$retOutput => $bindEncrypt,
			$retEncrypt => $bindSend,
		);
		$_ = substr($_, 1);
	} else {
		$ab = Triceps::AutoFnBind->new(
			$retReceive => $bindDispatch,
			$retOutput => $bindSend,
		);
	};
	$unit->makeArrayCall($lbReceive, "OP_INSERT", $_);
	$unit->drainFrame();
}

}; # doEncPipeline

setInputLines(
	"inc,OP_INSERT,abc,1\n",
	"inc,OP_DELETE,def,100\n",
	# perl -e 'print((unpack "H*", "inc,OP_INSERT,abc,2"), "\n");'
	"+696e632c4f505f494e534552542c6162632c32\n",
	# perl -e 'print((unpack "H*", "inc,OP_DELETE,def,101"), "\n");'
	"+696e632c4f505f44454c4554452c6465662c313031\n",
);
&doEncPipeline();
#print &getResultLines();
# perl -e 'print((pack "H*", "726573756c74204f505f494e53455254206e616d653d226162632220636f756e743d22332220"), "\n");'
# result OP_INSERT name="abc" count="3" 
# perl -e 'print((pack "H*", "726573756c74204f505f44454c455445206e616d653d226465662220636f756e743d223130322220"), "\n");'
# result OP_DELETE name="def" count="102" 
ok(&getResultLines(), '> inc,OP_INSERT,abc,1
result OP_INSERT name="abc" count="2" 
> inc,OP_DELETE,def,100
result OP_DELETE name="def" count="101" 
> +696e632c4f505f494e534552542c6162632c32
726573756c74204f505f494e53455254206e616d653d226162632220636f756e743d22332220
> +696e632c4f505f44454c4554452c6465662c313031
726573756c74204f505f44454c455445206e616d653d226465662220636f756e743d223130322220
');

############################################################
# A pipeline with sort-of-recursion.

sub doRecursivePipeline {
my $variant = shift;

my $unit = Triceps::Unit->new("unit");

# All the input and output gets converted through an intermediate
# format of a row with one string field.
my $rtString = Triceps::RowType->new(
	s => "string"
);

# All the input gets sent here.
my $lbReceive = $unit->makeDummyLabel($rtString, "lbReceive");
my $retReceive = Triceps::FnReturn->new(
	name => "retReceive",
	labels => [
		data => $lbReceive,
	],
);

# The binding that actually prints the output.
my $bindSend = Triceps::FnBinding->new(
	name => "bindSend",
	on => $retReceive, # any matching return will do
	unit => $unit,
	withTray => 1,
	labels => [
		data => sub {
			&send($_[1]->getRow()->get("s"), "\n");
		},
	],
);

my %dispatch; # the dispatch table will be set here

# The binding that dispatches the input data
my $bindDispatch = Triceps::FnBinding->new(
	name => "bindDispatch",
	on => $retReceive,
	unit => $unit,
	withTray => 1,
	labels => [
		data => sub {
			my @data = split(/,/, $_[1]->getRow()->get("s")); # starts with a command, then string opcode
			my $type = shift @data;
			my $lb = $dispatch{$type};
			my $rowop = $lb->makeRowopArray(@data);
			$unit->call($rowop);
		},
	],
);

# All the output gets converted to rtString and sent here.
my $lbOutput = $unit->makeDummyLabel($rtString, "lbOutput");
my $retOutput = Triceps::FnReturn->new(
	name => "retOutput",
	labels => [
		data => $lbOutput,
	],
);

# The encryption pipeline element.
my $retEncrypt = Triceps::FnReturn->new(
	name => "retEncrypt",
	unit => $unit,
	labels => [
		data => $rtString,
	],
);
my $lbEncrypt = $retEncrypt->getLabel("data");
my $bindEncrypt = Triceps::FnBinding->new(
	name => "bindEncrypt",
	on => $retReceive,
	unit => $unit,
	withTray => 1,
	labels => [
		data => sub {
			my $s = $_[1]->getRow()->get("s");
			$unit->makeArrayCall($lbEncrypt, "OP_INSERT", unpack("H*", $s));
		},
	],
);

# The decryption pipeline element.
my $retDecrypt = Triceps::FnReturn->new(
	name => "retDecrypt",
	unit => $unit,
	labels => [
		data => $rtString,
	],
);
my $lbDecrypt = $retDecrypt->getLabel("data");
my $bindDecrypt = Triceps::FnBinding->new(
	name => "bindDecrypt",
	on => $retReceive,
	unit => $unit,
	withTray => 1,
	labels => [
		data => sub {
			my $s = $_[1]->getRow()->get("s");
			$unit->makeArrayCall($lbDecrypt, "OP_INSERT", pack("H*", $s));
		},
	],
);

# The body of the model: pass through the name, increase the count.
my $rtData = Triceps::RowType->new(
	name => "string",
	count => "int32",
);

my $lbIncResult = $unit->makeDummyLabel($rtData, "result");
my $lbInc = $unit->makeLabel($rtData, "inc", undef, sub {
	my $row = $_[1]->getRow();
	$unit->makeHashCall($lbIncResult, $_[1]->getOpcode(),
		name  => $row->get("name"),
		count => $row->get("count") + 1,
	);
});
makePipePrintLabel("printResult", $lbIncResult, $lbOutput);

%dispatch = (
	inc => $lbInc,
);

# The main loop.
if ($variant == 1) {
# as one flat block
while(&readLine) {
	chomp;

	# receive
	my $abReceive = Triceps::AutoFnBind->new(
		$retReceive => $bindDecrypt,
	);
	$unit->makeArrayCall($lbReceive, "OP_INSERT", $_);

	# 1st decrypt
	my $abDecrypt1 = Triceps::AutoFnBind->new(
		$retDecrypt => $bindDecrypt,
	);
	$bindDecrypt->callTray();

	# 2nd decrypt
	my $abDecrypt2 = Triceps::AutoFnBind->new(
		$retDecrypt => $bindDispatch,
	);
	$bindDecrypt->callTray();

	# processing
	my $abProcess = Triceps::AutoFnBind->new(
		$retOutput => $bindEncrypt,
	);
	$bindDispatch->callTray();

	# 1st encrypt
	my $abEncrypt1 = Triceps::AutoFnBind->new(
		$retEncrypt => $bindEncrypt,
	);
	$bindEncrypt->callTray();

	# 2nd encrypt
	my $abEncrypt2 = Triceps::AutoFnBind->new(
		$retEncrypt => $bindSend,
	);
	$bindEncrypt->callTray();

	# send
	$bindSend->callTray();
}
} elsif ($variant == 2) {
# as nested blocks
while(&readLine) {
	chomp;

	# receive
	my $abReceive = Triceps::AutoFnBind->new(
		$retReceive => $bindDecrypt,
	);
	$unit->makeArrayCall($lbReceive, "OP_INSERT", $_);

	{
		# 1st decrypt
		my $abDecrypt1 = Triceps::AutoFnBind->new(
			$retDecrypt => $bindDecrypt,
		);
		$bindDecrypt->callTray();

		{
			# 2nd decrypt
			my $abDecrypt1 = Triceps::AutoFnBind->new(
				$retDecrypt => $bindDispatch,
			);
			$bindDecrypt->callTray();

			{
				# processing
				my $abProcess = Triceps::AutoFnBind->new(
					$retOutput => $bindEncrypt,
				);
				$bindDispatch->callTray();

				{
					# 1st encrypt
					my $abEncrypt1 = Triceps::AutoFnBind->new(
						$retEncrypt => $bindEncrypt,
					);
					$bindEncrypt->callTray();

					{
						# 2nd encrypt
						my $abEncrypt1 = Triceps::AutoFnBind->new(
							$retEncrypt => $bindSend,
						);
						$bindEncrypt->callTray();

						# send
						$bindSend->callTray();
					}
				}
			}
		}
	}
}
} elsif ($variant == 3) {
# as sequential blocks
while(&readLine) {
	chomp;

	# receive
	{
		my $abReceive = Triceps::AutoFnBind->new(
			$retReceive => $bindDecrypt,
		);
		$unit->makeArrayCall($lbReceive, "OP_INSERT", $_);
	}

	# 1st decrypt
	{
		my $abDecrypt1 = Triceps::AutoFnBind->new(
			$retDecrypt => $bindDecrypt,
		);
		$bindDecrypt->callTray();
	}

	# 2nd decrypt
	{
		my $abDecrypt1 = Triceps::AutoFnBind->new(
			$retDecrypt => $bindDispatch,
		);
		$bindDecrypt->callTray();
	}

	# processing
	{
		my $abProcess = Triceps::AutoFnBind->new(
			$retOutput => $bindEncrypt,
		);
		$bindDispatch->callTray();
	}

	# 1st encrypt
	{
		my $abEncrypt1 = Triceps::AutoFnBind->new(
			$retEncrypt => $bindEncrypt,
		);
		$bindEncrypt->callTray();
	}

	# 2nd encrypt
	{
		my $abEncrypt1 = Triceps::AutoFnBind->new(
			$retEncrypt => $bindSend,
		);
		$bindEncrypt->callTray();
	}

	# send
	$bindSend->callTray();
}
} elsif ($variant == 4) {
# as nested blocks, with repeated calls
while(&readLine) {
	chomp;

	# receive
	my $abReceive = Triceps::AutoFnBind->new(
		$retReceive => $bindDecrypt,
	);

	for (my $i = 0; $i < 3; $i++) {
		$unit->makeArrayCall($lbReceive, "OP_INSERT", $_);

		{
			# 1st decrypt
			my $abDecrypt1 = Triceps::AutoFnBind->new(
				$retDecrypt => $bindDecrypt,
			);
			$bindDecrypt->callTray();

			{
				# 2nd decrypt
				my $abDecrypt1 = Triceps::AutoFnBind->new(
					$retDecrypt => $bindDispatch,
				);
				$bindDecrypt->callTray();

				{
					# processing
					my $abProcess = Triceps::AutoFnBind->new(
						$retOutput => $bindEncrypt,
					);
					$bindDispatch->callTray();

					{
						# 1st encrypt
						my $abEncrypt1 = Triceps::AutoFnBind->new(
							$retEncrypt => $bindEncrypt,
						);
						$bindEncrypt->callTray();

						{
							# 2nd encrypt
							my $abEncrypt1 = Triceps::AutoFnBind->new(
								$retEncrypt => $bindSend,
							);
							$bindEncrypt->callTray();

							# send
							$bindSend->callTray();
						}
					}
				}
			}
		}
	}
}
} # end variant

}; # doRecursivePipeline

my @rpInput = (
	# perl -e 'print(unpack("H*", unpack("H*", "inc,OP_INSERT,abc,2")), "\n");'
	"3639366536333263346635303566343934653533343535323534326336313632363332633332\n",
);

# perl -e 'print(pack("H*", pack("H*", "37323635373337353663373432303466353035663439346535333435353235343230366536313664363533643232363136323633323232303633366637353665373433643232333332323230")), "\n");'
# result OP_INSERT name="abc" count="3"
my $rpExpect =
'> 3639366536333263346635303566343934653533343535323534326336313632363332633332
37323635373337353663373432303466353035663439346535333435353235343230366536313664363533643232363136323633323232303633366637353665373433643232333332323230
';

setInputLines(@rpInput);
&doRecursivePipeline(1);
#print &getResultLines();
ok(&getResultLines(), $rpExpect);

setInputLines(@rpInput);
&doRecursivePipeline(2);
#print &getResultLines();
ok(&getResultLines(), $rpExpect);

setInputLines(@rpInput);
&doRecursivePipeline(3);
#print &getResultLines();
ok(&getResultLines(), $rpExpect);

setInputLines(@rpInput);
&doRecursivePipeline(4);
#print &getResultLines();
ok(&getResultLines(),
'> 3639366536333263346635303566343934653533343535323534326336313632363332633332
37323635373337353663373432303466353035663439346535333435353235343230366536313664363533643232363136323633323232303633366637353665373433643232333332323230
37323635373337353663373432303466353035663439346535333435353235343230366536313664363533643232363136323633323232303633366637353665373433643232333332323230
37323635373337353663373432303466353035663439346535333435353235343230366536313664363533643232363136323633323232303633366637353665373433643232333332323230
');
