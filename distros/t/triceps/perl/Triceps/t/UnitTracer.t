#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The test for UnitTracer (in C++ Unit::Tracer).

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 14 };
use Triceps;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

################### canned tracer #############################

$ts1 = Triceps::UnitTracerStringName->new();
ok(ref $ts1, "Triceps::UnitTracerStringName");

$ts2 = Triceps::UnitTracerStringName->new(verbose => 1);
ok(ref $ts2, "Triceps::UnitTracerStringName");

$ts3 = Triceps::UnitTracerStringName->new(verbose => 0);
ok(ref $ts3, "Triceps::UnitTracerStringName");

$ts4 = eval { Triceps::UnitTracerStringName->new(0); };
ok (!defined $ts4);
ok($@, qr/^Usage: Triceps::UnitTracerStringName::new\(CLASS, optionName, optionValue, ...\), option names and values must go in pairs at/);

$ts4 = eval { Triceps::UnitTracerStringName->new(unknown => 1); };
ok (!defined $ts4);
ok($@, qr/^Triceps::UnitTracerStringName::new: unknown option 'unknown'/);

# execution tested in Unit.t

################### perl tracer #############################

my $tlog; # perl tracer will be adding messages here

sub tracerCb() # unit, label, fromLabel, rop, when, extra
{
	my ($unit, $label, $from, $rop, $when, @extra) = @_;
	my $msg;

	$msg = "unit '" . $unit->getName() . "' " . Triceps::tracerWhenHumanString($when) . " label '" . $label->getName() . "' ";
	if (defined $fromLabel) {
		$msg .= "(chain '" . $fromLabel->getName() . "') ";
	}
	$msg .= "op " . Triceps::opcodeString($rop->getOpcode()) . "' [" . join(',', @extra) . "]\n";
	$tlog .= $msg;
}

$tp1 = Triceps::UnitTracerPerl->new(\&tracerCb);
ok(ref $tp1, "Triceps::UnitTracerPerl");

$tp2 = Triceps::UnitTracerPerl->new(\&tracerCb, "a", "b");
ok(ref $tp2, "Triceps::UnitTracerPerl");

# execution tested in Unit.t

#######################
# this has nothing to do with tracers as such, just a test that the Parl class
# inheritance passes through correctly from the C++ classes

$v = $ts1->__testSubclassCall();
ok($v, "UnitTracerStringName");

$v = $tp1->__testSubclassCall();
ok($v, "UnitTracerPerl");

$v = $ts1->__testSuperclassCall();
ok($v, 1);

$v = $tp1->__testSuperclassCall();
ok($v, 1);

