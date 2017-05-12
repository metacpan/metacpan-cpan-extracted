#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The test for Unit.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 142 };
use Triceps;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


###################### new #################################

$u1 = Triceps::Unit->new("u1");
ok(ref $u1, "Triceps::Unit");

$u2 = Triceps::Unit->new("u2");
ok(ref $u2, "Triceps::Unit");

$v = $u1->same($u1);
ok($v);
$v = $u1->same($u2);
ok(!$v);

ok($u1->getStackDepth(), 1);

###################### empty row type #################################

$rte = $u1->getEmptyRowType();
ok(ref $rte, "Triceps::RowType");
$v = $rte->getdef();
ok($#v, -1);

###################### makeTable prep #################################

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

$it1 = Triceps::IndexType->newHashed(key => [ "b", "c" ])
	->addSubIndex("fifo", Triceps::IndexType->newFifo()
	);
ok(ref $it1, "Triceps::IndexType");

$tt1 = Triceps::TableType->new($rt1)
	->addSubIndex("grouping", $it1);
ok(ref $tt1, "Triceps::TableType");

# check with uninitialized type
$t1 = eval { $u1->makeTable($tt1, "tab1"); };
ok(!defined $t1);
ok($@, qr/^Triceps::Unit::makeTable: table type was not successfully initialized at/);

$res = $tt1->initialize();
ok($res, 1);

###################### makeTable #################################

$t1 = $u1->makeTable($tt1, "tab1");
ok(ref $t1, "Triceps::Table");

$v = $t1->getUnit();
ok($u1->same($v));

###################### makeTray #################################
# see in Tray.t

###################### make*Label ###############################

my $clearlog; # where the clear function would write its history

sub exe_history # (label, rowop)
{
	my ($label, $rowop) = @_;
	our $history;
	$history .= "x " . $label->getName() . " op=" . Triceps::opcodeString($rowop->getOpcode()) 
		. " row=[" . join(", ", $rowop->getRow()->toArray()) . "]\n";
}

sub exe_history_xargs # (label, rowop, args...)
{
	my $label = shift @_;
	my $rowop = shift @_;
	our $history;
	$history .= "x " . $label->getName() . " op=" . Triceps::opcodeString($rowop->getOpcode()) 
		. " row=[" . join(", ", $rowop->getRow()->toArray()) . "] args=[" . join(',', @_) . "]\n";
}

sub exe_die # (label, rowop)
{
	my ($label, $rowop) = @_;
	die "xdie " . $label->getName() . " op=" . Triceps::opcodeString($rowop->getOpcode()) 
		. " row=[" . join(", ", $rowop->getRow()->toArray()) . "]";
}

sub log_clear # (label, args)
{
	my $label = shift @_;
	$clearlog .= "clear " . $label->getName() . " args=["  . join(",", @_) . "]\n";
}

$dumlab = $u1->makeDummyLabel($rt1, "dumlab");
ok(ref $dumlab, "Triceps::Label");

$xlab1 = $u1->makeLabel($rt1, "xlab1", \&log_clear, \&exe_history);
ok(ref $xlab1, "Triceps::Label");
$xlab2 = $u1->makeLabel($rt1, "xlab2", \&log_clear, \&exe_history_xargs, "a", "b");
ok(ref $xlab2, "Triceps::Label");

$dielab = $u1->makeLabel($rt1, "dielab", undef, \&exe_die);
ok(ref $dielab, "Triceps::Label");

$v = $dumlab->chain($xlab2);
ok($v);

our $history = "";
our @history; # for the other version of Perl tracing

# prepare rowops for enqueueing

@dataset1 = (
	a => 123,
	b => 456,
	c => 789,
	d => 3.14,
	e => "text",
);
@datavalues1 = (123, 456, 789, 3.14, "text");
$row1 = $rt1->makeRowHash(@dataset1);
ok(ref $row1, "Triceps::Row");

$rop11 = $xlab1->makeRowop("OP_INSERT", $row1);
ok(ref $rop11, "Triceps::Rowop");
$rop12 = $xlab1->makeRowop("OP_DELETE", $row1);
ok(ref $rop12, "Triceps::Rowop");

# will get to xlab2 through the chaining
$rop21 = $dumlab->makeRowop("OP_INSERT", $row1);
ok(ref $rop21, "Triceps::Rowop");
$rop22 = $dumlab->makeRowop("OP_DELETE", $row1);
ok(ref $rop22, "Triceps::Rowop");
# put them into a tray
$tray2 = $u1->makeTray($rop21, $rop22);
ok(ref $tray2, "Triceps::Tray");

$ropd1 = $dielab->makeRowop("OP_INSERT", $row1);
ok(ref $ropd1, "Triceps::Rowop");
$ropd2 = $dielab->makeRowop("OP_DELETE", $row1);
ok(ref $ropd2, "Triceps::Rowop");

# also add an empty tray
$trayem = $u1->makeTray();
ok(ref $trayem, "Triceps::Tray");

##################### schedule ##################################

# schedule 

$v = $u1->empty();
ok($v);

$u1->schedule($rop11, $tray2, $rop12, $trayem);

$v = $u1->empty();
ok(!$v);

$history = "";
$u1->callNext();
ok($history, "x xlab1 op=OP_INSERT row=[123, 456, 789, 3.14, text]\n");

$history = "";
$u1->callNext();
ok($history, "x xlab2 op=OP_INSERT row=[123, 456, 789, 3.14, text] args=[a,b]\n");

$history = "";
$u1->drainFrame();
ok($history, "x xlab2 op=OP_DELETE row=[123, 456, 789, 3.14, text] args=[a,b]\nx xlab1 op=OP_DELETE row=[123, 456, 789, 3.14, text]\n");
$v = $u1->empty();
ok($v);

# fork

$u1->fork($rop11, $tray2, $rop12, $trayem);
$v = $u1->empty();
ok(!$v);
$history = "";
$u1->drainFrame();
ok($history, 
	  "x xlab1 op=OP_INSERT row=[123, 456, 789, 3.14, text]\n"
	. "x xlab2 op=OP_INSERT row=[123, 456, 789, 3.14, text] args=[a,b]\n"
	. "x xlab2 op=OP_DELETE row=[123, 456, 789, 3.14, text] args=[a,b]\n" 
	. "x xlab1 op=OP_DELETE row=[123, 456, 789, 3.14, text]\n");
$v = $u1->empty();
ok($v);

# call

$history = "";
$u1->call($rop11, $tray2, $rop12, $trayem);
# no drain, CALL gets executed immediately
ok($history, 
	  "x xlab1 op=OP_INSERT row=[123, 456, 789, 3.14, text]\n"
	. "x xlab2 op=OP_INSERT row=[123, 456, 789, 3.14, text] args=[a,b]\n"
	. "x xlab2 op=OP_DELETE row=[123, 456, 789, 3.14, text] args=[a,b]\n" 
	. "x xlab1 op=OP_DELETE row=[123, 456, 789, 3.14, text]\n");
$v = $u1->empty();
ok($v);

# enqueue with constant

$u1->enqueue(&Triceps::EM_FORK, $rop11, $tray2, $rop12, $trayem);
$v = $u1->empty();
ok(!$v);
$history = "";
$u1->drainFrame();
ok($history, 
	  "x xlab1 op=OP_INSERT row=[123, 456, 789, 3.14, text]\n"
	. "x xlab2 op=OP_INSERT row=[123, 456, 789, 3.14, text] args=[a,b]\n"
	. "x xlab2 op=OP_DELETE row=[123, 456, 789, 3.14, text] args=[a,b]\n" 
	. "x xlab1 op=OP_DELETE row=[123, 456, 789, 3.14, text]\n");
$v = $u1->empty();
ok($v);

# enqueue with string

$u1->enqueue("EM_SCHEDULE", $rop11, $tray2, $rop12, $trayem);
$v = $u1->empty();
ok(!$v);
$history = "";
$u1->drainFrame();
ok($history, 
	  "x xlab1 op=OP_INSERT row=[123, 456, 789, 3.14, text]\n"
	. "x xlab2 op=OP_INSERT row=[123, 456, 789, 3.14, text] args=[a,b]\n"
	. "x xlab2 op=OP_DELETE row=[123, 456, 789, 3.14, text] args=[a,b]\n" 
	. "x xlab1 op=OP_DELETE row=[123, 456, 789, 3.14, text]\n");
$v = $u1->empty();
ok($v);

#############################################################
# scheduling combined with construction (except with frame marks,
# those are in FrameMark.t)

# schedule
$v = $u1->empty();
ok($v);

$history = "";
$v = $u1->makeHashSchedule($xlab1, "OP_INSERT", @dataset1);
ok($v);
$v = $u1->empty();
ok(!$v);
$u1->callNext();
ok($history, "x xlab1 op=OP_INSERT row=[123, 456, 789, 3.14, text]\n");
$v = $u1->empty();
ok($v);

$history = "";
$v = $u1->makeArraySchedule($xlab1, "OP_DELETE", @datavalues1);
ok($v);
$v = $u1->empty();
ok(!$v);
$u1->callNext();
ok($history, "x xlab1 op=OP_DELETE row=[123, 456, 789, 3.14, text]\n");
$v = $u1->empty();
ok($v);

# call
$history = "";
$v = $u1->makeHashCall($xlab1, "OP_INSERT", @dataset1);
ok($v);
ok($history, "x xlab1 op=OP_INSERT row=[123, 456, 789, 3.14, text]\n");

$history = "";
$v = $u1->makeArrayCall($xlab1, "OP_DELETE", @datavalues1);
ok($v);
ok($history, "x xlab1 op=OP_DELETE row=[123, 456, 789, 3.14, text]\n");

# schedule error handling, 
# selective touch-testing: different errors for different calls
eval {
	$v = $u1->makeHashSchedule($xlab1, "OP_INSET", @dataset1);
};
ok($@, qr/^Triceps::Label::makeRowop: unknown opcode string 'OP_INSET', if integer was meant, it has to be cast/);

eval {
	$v = $u1->makeHashCall($xlab1, "OP_INSERT", zzz => 1);
};
ok($@, qr/^Triceps::RowType::makeRowHash: attempting to set an unknown field 'zzz'/);

eval {
	$v = $u1->makeArraySchedule(666, "OP_DELETE", @datavalues1);
};
# Depending on the Perl version it's one of:
#   Can't call method "makeRowopArray" without a package or object reference
#   Can't locate object method "makeRowopArray" via package "666"
ok($@, qr/^Can't .* method "makeRowopArray" /);

#############################################################
# test scheduling for error catching

$elab1 = $u1->makeLabel($rt1, "elab1", undef, sub { die "an error in label handler" } );
ok(ref $elab1, "Triceps::Label");

$erop = $elab1->makeRowop("OP_INSERT", $row1);
ok(ref $erop, "Triceps::Rowop");

$u1->schedule($erop);
eval {
	$u1->drainFrame();
};
ok($@, qr/^an error in label handler at [^\n]*
Detected in the unit 'u1' label 'elab1' execution handler.
Called through the label 'elab1'. at/);

$u1->call($rop11);
$xlab1->clear(); # now the label could not call anything any more
eval {
	$u1->call($rop11);
};
ok($@, qr/Triceps::Unit::call: argument 1 is a Rowop for label xlab1 from a wrong unit \[label cleared\] at/);
ok($clearlog, "clear xlab1 args=[]\n");

# errors from exception catching

# recursive label
$reclab = $u1->makeLabel($rt1, "reclab", undef, sub { $u1->call($_[1]); } );
ok(ref $reclab, "Triceps::Label");
$recrop = $reclab->makeRowop("OP_INSERT", $row1);
ok(ref $recrop, "Triceps::Rowop");
eval {
	$u1->call($recrop);
};
ok($@, qr/^Exceeded the unit recursion depth limit 1 \(attempted 2\) on the label 'reclab'. at [^\n]*
\tmain::__ANON__[^\n]*
\teval[^\n]*
Detected in the unit 'u1' label 'reclab' execution handler.
Called through the label 'reclab'. at [^\n]*
\teval[^\n]*
/);
#print "$@";

# a crash in a deeply nested label
$nlab1 = $u1->makeLabel($rt1, "nlab1", undef, sub { die "Test of a crash"; } );
ok(ref $nlab1, "Triceps::Label");
$nlab2 = $u1->makeLabel($rt1, "nlab2", undef, sub { $u1->call($nlab1->adopt($_[1])); } );
ok(ref $nlab2, "Triceps::Label");
$nlab3 = $u1->makeLabel($rt1, "nlab3", undef, sub { $u1->call($nlab2->adopt($_[1])); } );
ok(ref $nlab3, "Triceps::Label");
$nlab4 = $u1->makeLabel($rt1, "nlab4", undef, sub { $u1->call($nlab3->adopt($_[1])); } );
ok(ref $nlab4, "Triceps::Label");
$nlab5 = $u1->makeLabel($rt1, "nlab5", undef, sub { $u1->call($nlab4->adopt($_[1])); } );
ok(ref $nlab5, "Triceps::Label");
$nrop5 = $nlab5->makeRowop("OP_INSERT", $row1);
ok(ref $nrop5, "Triceps::Rowop");
eval {
	$u1->call($nrop5);
};
#print "$@\n";
ok($@, qr/^Test of a crash at [^\n]*
Detected in the unit 'u1' label 'nlab1' execution handler.
Called through the label 'nlab1'. at [^\n]*
	main::__ANON__[^\n]*
	eval [^\n]*
Detected in the unit 'u1' label 'nlab2' execution handler.
Called through the label 'nlab2'. at [^\n]*
	main::__ANON__[^\n]*
	eval [^\n]*
Detected in the unit 'u1' label 'nlab3' execution handler.
Called through the label 'nlab3'. at [^\n]*
	main::__ANON__[^\n]*
	eval [^\n]*
Detected in the unit 'u1' label 'nlab4' execution handler.
Called through the label 'nlab4'. at [^\n]*
	main::__ANON__[^\n]*
	eval [^\n]*
Detected in the unit 'u1' label 'nlab5' execution handler.
Called through the label 'nlab5'. at [^\n]*
	eval [^\n]*
/);

#############################################################
# Test the call depth limits.

ok($u1->maxStackDepth(), 0);
ok($u1->maxRecursionDepth(), 1);

$u1->setMaxRecursionDepth(3);
ok($u1->maxRecursionDepth(), 3);

eval {
	$u1->call($recrop);
};
ok($@, qr/^Exceeded the unit recursion depth limit 3 \(attempted 4\) on the label 'reclab'. at [^\n]*
\tmain::__ANON__[^\n]*
\teval[^\n]*
Detected in the unit 'u1' label 'reclab' execution handler.
Called through the label 'reclab'. at [^\n]*
\tmain::__ANON__[^\n]*
\teval[^\n]*
Detected in the unit 'u1' label 'reclab' execution handler.
Called through the label 'reclab'. at [^\n]*
\tmain::__ANON__[^\n]*
\teval[^\n]*
Detected in the unit 'u1' label 'reclab' execution handler.
Called through the label 'reclab'. at [^\n]*
\teval[^\n]*
/);
#print "$@";

$u1->setMaxStackDepth(3);
$u1->setMaxRecursionDepth(0);
ok($u1->maxStackDepth(), 3);
ok($u1->maxRecursionDepth(), 0);

eval {
	$u1->call($recrop);
};
# There is always also the outermost frame, so the label recurses one less time.
ok($@, qr/^Unit 'u1' exceeded the stack depth limit 3, current depth 4, when calling the label 'reclab'. at [^\n]*
\tmain::__ANON__[^\n]*
\teval[^\n]*
Detected in the unit 'u1' label 'reclab' execution handler.
Called through the label 'reclab'. at [^\n]*
\tmain::__ANON__[^\n]*
\teval[^\n]*
Detected in the unit 'u1' label 'reclab' execution handler.
Called through the label 'reclab'. at [^\n]*
\teval[^\n]*
/);
#print "$@";

# restore back to defaults
$u1->setMaxStackDepth(0);
$u1->setMaxRecursionDepth(1);

#############################################################
# Test the current frame emptiness.

{
	$f_u = Triceps::Unit->new("f_u");
	ok($f_u->isInOuterFrame());
	ok($f_u->isFrameEmpty());

	my $f_protocol = "";

	$f_dummy_lab = $f_u->makeDummyLabel($rt1, "f_dummy_lab");
	$f_inner_lab = $f_u->makeLabel($rt1, "f_inner_lab", undef, sub {
		$f_protocol .= sprintf("InOuter = %d\n", $f_u->isInOuterFrame());
		$f_protocol .= sprintf("FrameEmpty = %d\n", $f_u->isFrameEmpty());

		$f_u->schedule($f_dummy_lab->makeRowop("OP_INSERT", $row1));
		$f_protocol .= sprintf("scheduled, FrameEmpty = %d\n", $f_u->isFrameEmpty());

		$f_u->fork($f_dummy_lab->makeRowop("OP_INSERT", $row1));
		$f_protocol .= sprintf("forked, FrameEmpty = %d\n", $f_u->isFrameEmpty());
	});
	$f_outer_lab = $f_u->makeLabel($rt1, "f_outer_lab", undef, sub {
		$f_protocol .= sprintf("outer InOuter = %d\n", $f_u->isInOuterFrame());
		$f_protocol .= sprintf("outer FrameEmpty = %d\n", $f_u->isFrameEmpty());
		$f_u->call($f_inner_lab->makeRowop("OP_INSERT", $row1));
	});
	$f_u->call($f_outer_lab->makeRowop("OP_INSERT", $row1));

	ok($f_protocol, 
'outer InOuter = 0
outer FrameEmpty = 1
InOuter = 0
FrameEmpty = 1
scheduled, FrameEmpty = 1
forked, FrameEmpty = 0
');
}

#############################################################
# tracer ops

$v = $u1->getTracer();
ok(! defined $v);

$trsn1 = Triceps::UnitTracerStringName->new();
ok(ref $trsn1, "Triceps::UnitTracerStringName");

$u1->setTracer($trsn1);
$v = $u1->getTracer();
ok(ref $v, "Triceps::UnitTracerStringName");
ok($trsn1->same($v));

$trp1 = Triceps::UnitTracerPerl->new(sub {});
ok(ref $trp1, "Triceps::UnitTracerPerl");

$u1->setTracer($trp1);
$v = $u1->getTracer();
ok(ref $v, "Triceps::UnitTracerPerl");
ok($trp1->same($v));

$u1->setTracer(undef);

$v = $u1->getTracer();
ok(! defined $v);

# try to set an invalid value
eval {
	$u1->setTracer(10);
};
ok($@ =~ "^Unit::setTracer: tracer is not a blessed SV reference to WrapUnitTracer");

eval {
	$u1->setTracer($u1);
};
ok($@ =~ "^Unit::setTracer: tracer has an incorrect magic for WrapUnitTracer");

#############################################################
# test all 3 kinds of scheduling for correct functioning - as in t_Unit.cpp scheduling()
# uses UnitTracerStringName and UnitTracerPerl, so tests them too

if (0) {
sub exe_call_two # (label, rowop, sub1, sub2)
{
	my ($label, $rowop, $sub1, $sub2) = @_;
	my $unit = $label->getUnit();
	$unit->call($sub1);
	$unit->enqueue(&Triceps::EM_CALL, $sub2);
}

sub exe_fork_two # (label, rowop, sub1, sub2)
{
	my ($label, $rowop, $sub1, $sub2) = @_;
	my $unit = $label->getUnit();
	$unit->fork($sub1);
	$unit->enqueue(&Triceps::EM_FORK, $sub2);
}

sub exe_sched_two # (label, rowop, sub1, sub2)
{
	my ($label, $rowop, $sub1, $sub2) = @_;
	my $unit = $label->getUnit();
	$unit->schedule($sub1);
	$unit->enqueue(&Triceps::EM_SCHEDULE, $sub2);
}
} # 0

sub exe_sched_fork_call # (label, rowop, lab1, lab2, lab3, row)
{
	my ($label, $rowop, $lab1, $lab2, $lab3, $row) = @_;
	my $unit = $label->getUnit();
	$unit->schedule($lab1->makeRowop(&Triceps::OP_INSERT, $row));
	$unit->schedule($lab1->makeRowop(&Triceps::OP_DELETE, $row));
	$unit->fork($lab2->makeRowop(&Triceps::OP_INSERT, $row));
	$unit->fork($lab2->makeRowop(&Triceps::OP_DELETE, $row));
	$unit->call($lab3->makeRowop(&Triceps::OP_INSERT, $row));
	$unit->call($lab3->makeRowop(&Triceps::OP_DELETE, $row));
}

$sntr = Triceps::UnitTracerStringName->new();
$u1->setTracer($sntr);

$s_lab1 = $u1->makeDummyLabel($rt1, "lab1");
ok(ref $s_lab1, "Triceps::Label");

# This is a test of how the nested forking goes.
$s_lab2a = $u1->makeDummyLabel($rt1, "lab2a");
ok(ref $s_lab2a, "Triceps::Label");
$s_lab2 = $u1->makeLabel($rt1, "lab2", undef, sub {
	$u1->fork($s_lab2a->adopt($_[1]));
});
ok(ref $s_lab2, "Triceps::Label");

$s_lab3 = $u1->makeDummyLabel($rt1, "lab3");
ok(ref $s_lab3, "Triceps::Label");

$s_lab4 = $u1->makeLabel($rt1, "lab4", undef, \&exe_sched_fork_call, $s_lab1, $s_lab2, $s_lab3, $row1);
ok(ref $s_lab4, "Triceps::Label");
$s_lab5 = $u1->makeLabel($rt1, "lab5", undef, \&exe_sched_fork_call, $s_lab1, $s_lab2, $s_lab3, $row1);
ok(ref $s_lab5, "Triceps::Label");

$s_op4 = $s_lab4->makeRowop(&Triceps::OP_NOP, $row1);
ok(ref $s_op4, "Triceps::Rowop");
$s_op5 = $s_lab5->makeRowop(&Triceps::OP_NOP, $row1);
ok(ref $s_op5, "Triceps::Rowop");

$s_expect =
	"unit 'u1' before label 'lab4' op OP_NOP\n"
	. "unit 'u1' before label 'lab3' op OP_INSERT\n"
	. "unit 'u1' before label 'lab3' op OP_DELETE\n"
	. "unit 'u1' before label 'lab2' op OP_INSERT\n"
	. "unit 'u1' before label 'lab2' op OP_DELETE\n"
	. "unit 'u1' before label 'lab2a' op OP_INSERT\n"
	. "unit 'u1' before label 'lab2a' op OP_DELETE\n"

	. "unit 'u1' before label 'lab5' op OP_NOP\n"
	. "unit 'u1' before label 'lab3' op OP_INSERT\n"
	. "unit 'u1' before label 'lab3' op OP_DELETE\n"
	. "unit 'u1' before label 'lab2' op OP_INSERT\n"
	. "unit 'u1' before label 'lab2' op OP_DELETE\n"
	. "unit 'u1' before label 'lab2a' op OP_INSERT\n"
	. "unit 'u1' before label 'lab2a' op OP_DELETE\n"

	. "unit 'u1' before label 'lab1' op OP_INSERT\n"
	. "unit 'u1' before label 'lab1' op OP_DELETE\n"
	. "unit 'u1' before label 'lab1' op OP_INSERT\n"
	. "unit 'u1' before label 'lab1' op OP_DELETE\n"
	;

$s_expect_verbose =
	"unit 'u1' before label 'lab4' op OP_NOP {\n"
	. "unit 'u1' before label 'lab3' op OP_INSERT {\n"
	. "unit 'u1' after label 'lab3' op OP_INSERT }\n"
	. "unit 'u1' before label 'lab3' op OP_DELETE {\n"
	. "unit 'u1' after label 'lab3' op OP_DELETE }\n"
	. "unit 'u1' after label 'lab4' op OP_NOP }\n"

	. "unit 'u1' before-drain label 'lab4' op OP_NOP {\n"
	. "unit 'u1' before label 'lab2' op OP_INSERT {\n"
	. "unit 'u1' after label 'lab2' op OP_INSERT }\n"
	. "unit 'u1' before label 'lab2' op OP_DELETE {\n"
	. "unit 'u1' after label 'lab2' op OP_DELETE }\n"
	. "unit 'u1' before label 'lab2a' op OP_INSERT {\n"
	. "unit 'u1' after label 'lab2a' op OP_INSERT }\n"
	. "unit 'u1' before label 'lab2a' op OP_DELETE {\n"
	. "unit 'u1' after label 'lab2a' op OP_DELETE }\n"
	. "unit 'u1' after-drain label 'lab4' op OP_NOP }\n"

	. "unit 'u1' before label 'lab5' op OP_NOP {\n"
	. "unit 'u1' before label 'lab3' op OP_INSERT {\n"
	. "unit 'u1' after label 'lab3' op OP_INSERT }\n"
	. "unit 'u1' before label 'lab3' op OP_DELETE {\n"
	. "unit 'u1' after label 'lab3' op OP_DELETE }\n"
	. "unit 'u1' after label 'lab5' op OP_NOP }\n"

	. "unit 'u1' before-drain label 'lab5' op OP_NOP {\n"
	. "unit 'u1' before label 'lab2' op OP_INSERT {\n"
	. "unit 'u1' after label 'lab2' op OP_INSERT }\n"
	. "unit 'u1' before label 'lab2' op OP_DELETE {\n"
	. "unit 'u1' after label 'lab2' op OP_DELETE }\n"
	. "unit 'u1' before label 'lab2a' op OP_INSERT {\n"
	. "unit 'u1' after label 'lab2a' op OP_INSERT }\n"
	. "unit 'u1' before label 'lab2a' op OP_DELETE {\n"
	. "unit 'u1' after label 'lab2a' op OP_DELETE }\n"
	. "unit 'u1' after-drain label 'lab5' op OP_NOP }\n"

	. "unit 'u1' before label 'lab1' op OP_INSERT {\n"
	. "unit 'u1' after label 'lab1' op OP_INSERT }\n"
	. "unit 'u1' before label 'lab1' op OP_DELETE {\n"
	. "unit 'u1' after label 'lab1' op OP_DELETE }\n"
	. "unit 'u1' before label 'lab1' op OP_INSERT {\n"
	. "unit 'u1' after label 'lab1' op OP_INSERT }\n"
	. "unit 'u1' before label 'lab1' op OP_DELETE {\n"
	. "unit 'u1' after label 'lab1' op OP_DELETE }\n"
	;

# execute with scheduling of op4, op5

$u1->schedule($s_op4);
$u1->enqueue("EM_SCHEDULE", $s_op5);
ok(!$u1->empty());

$u1->drainFrame();
ok($u1->empty());

$v = $sntr->print();
ok($v, $s_expect);

# check the buffer cleaning of string tracer
$sntr->clearBuffer();
$v = $sntr->print();
ok($v, "");

### repeat the same with the verbose tracer and fork() instead of schedule()

$sntr = Triceps::UnitTracerStringName->new(verbose => 1);
$u1->setTracer($sntr);

$u1->fork($s_op4);
$u1->enqueue("EM_FORK", $s_op5);
ok(!$u1->empty());

$u1->drainFrame();
ok($u1->empty());

$v = $sntr->print();
ok($v, $s_expect_verbose);

### same again but with Perl tracer

# x_Unit_A
sub tracerCb() # unit, label, fromLabel, rop, when, extra
{
	my ($unit, $label, $from, $rop, $when, @extra) = @_;
	our $history;

	my $msg = "unit '" . $unit->getName() . "' " 
		. Triceps::tracerWhenHumanString($when) . " label '" 
		. $label->getName() . "' ";
	if (defined $fromLabel) {
		$msg .= "(chain '" . $fromLabel->getName() . "') ";
	}
	$msg .= "op " . Triceps::opcodeString($rop->getOpcode());
	if (Triceps::tracerWhenIsBefore($when)) {
		$msg .= " {";
	} elsif (Triceps::tracerWhenIsAfter($when)) {
		$msg .= " }";
	}
	$msg .= "\n";
	$history .= $msg;
}

undef $history;
$ptr = Triceps::UnitTracerPerl->new(\&tracerCb);
$u1->setTracer($ptr);

$u1->fork($s_op4);
$u1->enqueue("EM_FORK", $s_op5);
ok(!$u1->empty());

$u1->drainFrame();
ok($u1->empty());

ok($history, $s_expect_verbose);

#############################################################
# test the chaining - as in t_Unit.cpp scheduling()

$sntr = Triceps::UnitTracerStringName->new(verbose => 1);
$u1->setTracer($sntr);

$c_lab1 = $u1->makeDummyLabel($rt1, "lab1");
ok(ref $c_lab1, "Triceps::Label");
$c_lab2 = $u1->makeDummyLabel($rt1, "lab2");
ok(ref $c_lab2, "Triceps::Label");
$c_lab3 = $u1->makeDummyLabel($rt1, "lab3");
ok(ref $c_lab3, "Triceps::Label");

$c_op1 = $c_lab1->makeRowop(&Triceps::OP_INSERT, $row1);
ok(ref $c_op1, "Triceps::Rowop");
$c_op2 = $c_lab1->makeRowop(&Triceps::OP_DELETE, $row1);
ok(ref $c_op2, "Triceps::Rowop");

$c_lab1->chain($c_lab2);
$c_lab1->chain($c_lab3);
$c_lab2->chain($c_lab3);

$u1->schedule($c_op1);
$u1->schedule($c_op2);
ok(!$u1->empty());

$u1->drainFrame();
ok($u1->empty());

$c_expect =
	"unit 'u1' before label 'lab1' op OP_INSERT {\n"
	. "unit 'u1' before-chained label 'lab1' op OP_INSERT {\n"
		. "unit 'u1' before label 'lab2' (chain 'lab1') op OP_INSERT {\n"
		. "unit 'u1' before-chained label 'lab2' (chain 'lab1') op OP_INSERT {\n"
			. "unit 'u1' before label 'lab3' (chain 'lab2') op OP_INSERT {\n"
			. "unit 'u1' after label 'lab3' (chain 'lab2') op OP_INSERT }\n"
		. "unit 'u1' after-chained label 'lab2' (chain 'lab1') op OP_INSERT }\n"
		. "unit 'u1' after label 'lab2' (chain 'lab1') op OP_INSERT }\n"

		. "unit 'u1' before label 'lab3' (chain 'lab1') op OP_INSERT {\n"
		. "unit 'u1' after label 'lab3' (chain 'lab1') op OP_INSERT }\n"
	. "unit 'u1' after-chained label 'lab1' op OP_INSERT }\n"
	. "unit 'u1' after label 'lab1' op OP_INSERT }\n"

	. "unit 'u1' before label 'lab1' op OP_DELETE {\n"
	. "unit 'u1' before-chained label 'lab1' op OP_DELETE {\n"
		. "unit 'u1' before label 'lab2' (chain 'lab1') op OP_DELETE {\n"
		. "unit 'u1' before-chained label 'lab2' (chain 'lab1') op OP_DELETE {\n"
			. "unit 'u1' before label 'lab3' (chain 'lab2') op OP_DELETE {\n"
			. "unit 'u1' after label 'lab3' (chain 'lab2') op OP_DELETE }\n"
		. "unit 'u1' after-chained label 'lab2' (chain 'lab1') op OP_DELETE }\n"
		. "unit 'u1' after label 'lab2' (chain 'lab1') op OP_DELETE }\n"

		. "unit 'u1' before label 'lab3' (chain 'lab1') op OP_DELETE {\n"
		. "unit 'u1' after label 'lab3' (chain 'lab1') op OP_DELETE }\n"
	. "unit 'u1' after-chained label 'lab1' op OP_DELETE }\n"
	. "unit 'u1' after label 'lab1' op OP_DELETE }\n"
	;

$v = $sntr->print();
ok($v, $c_expect);

### same chained input but with no-verbose

$sntr = Triceps::UnitTracerStringName->new();
$u1->setTracer($sntr);

$u1->schedule($c_op1);
$u1->schedule($c_op2);
ok(!$u1->empty());

$u1->drainFrame();
ok($u1->empty());

$c_expect =
"unit 'u1' before label 'lab1' op OP_INSERT
unit 'u1' before label 'lab2' (chain 'lab1') op OP_INSERT
unit 'u1' before label 'lab3' (chain 'lab2') op OP_INSERT
unit 'u1' before label 'lab3' (chain 'lab1') op OP_INSERT
unit 'u1' before label 'lab1' op OP_DELETE
unit 'u1' before label 'lab2' (chain 'lab1') op OP_DELETE
unit 'u1' before label 'lab3' (chain 'lab2') op OP_DELETE
unit 'u1' before label 'lab3' (chain 'lab1') op OP_DELETE
";

$v = $sntr->print();
ok($v, $c_expect);

### same chained input but with Perl printing of rows

# x_Unit_B
sub traceStringRowop
{
	my ($unit, $label, $fromLabel, $rowop, $when, 
		$verbose, $rlog, $rnest) = @_;

	if ($verbose) {
		${$rnest}-- if (Triceps::tracerWhenIsAfter($when));
	} else {
		return if ($when != &Triceps::TW_BEFORE);
	}

	my $msg =  "unit '" . $unit->getName() . "' " 
		. Triceps::tracerWhenHumanString($when) . " label '"
		. $label->getName() . "' ";
	if (defined $fromLabel) {
		$msg .= "(chain '" . $fromLabel->getName() . "') ";
	}
	my $tail = "";
	if (Triceps::tracerWhenIsBefore($when)) {
		$tail = " {";
	} elsif (Triceps::tracerWhenIsAfter($when)) {
		$tail = " }";
	}
	push (@{$rlog}, ("  " x ${$rnest}) . $msg . "op " 
		. $rowop->printP() . $tail);

	if ($verbose) {
		${$rnest}++ if (Triceps::tracerWhenIsBefore($when));
	}
}

undef @history;
my $tnest =  0; # keeps track of the tracing nesting level
$ptr = Triceps::UnitTracerPerl->new(\&traceStringRowop, 1, \@history, \$tnest);
$u1->setTracer($ptr);

$u1->schedule($c_op1);
$u1->schedule($c_op2);
ok(!$u1->empty());

$u1->drainFrame();
ok($u1->empty());

$c_expect_rows = ""
	. "unit 'u1' before label 'lab1' op lab1 OP_INSERT a=\"123\" b=\"456\" c=\"789\" d=\"3.14\" e=\"text\"  {\n"
	. "  unit 'u1' before-chained label 'lab1' op lab1 OP_INSERT a=\"123\" b=\"456\" c=\"789\" d=\"3.14\" e=\"text\"  {\n"
	. "    unit 'u1' before label 'lab2' (chain 'lab1') op lab1 OP_INSERT a=\"123\" b=\"456\" c=\"789\" d=\"3.14\" e=\"text\"  {\n"
	. "      unit 'u1' before-chained label 'lab2' (chain 'lab1') op lab1 OP_INSERT a=\"123\" b=\"456\" c=\"789\" d=\"3.14\" e=\"text\"  {\n"
	. "        unit 'u1' before label 'lab3' (chain 'lab2') op lab1 OP_INSERT a=\"123\" b=\"456\" c=\"789\" d=\"3.14\" e=\"text\"  {\n"
	. "        unit 'u1' after label 'lab3' (chain 'lab2') op lab1 OP_INSERT a=\"123\" b=\"456\" c=\"789\" d=\"3.14\" e=\"text\"  }\n"
	. "      unit 'u1' after-chained label 'lab2' (chain 'lab1') op lab1 OP_INSERT a=\"123\" b=\"456\" c=\"789\" d=\"3.14\" e=\"text\"  }\n"
	. "    unit 'u1' after label 'lab2' (chain 'lab1') op lab1 OP_INSERT a=\"123\" b=\"456\" c=\"789\" d=\"3.14\" e=\"text\"  }\n"
	. "    unit 'u1' before label 'lab3' (chain 'lab1') op lab1 OP_INSERT a=\"123\" b=\"456\" c=\"789\" d=\"3.14\" e=\"text\"  {\n"
	. "    unit 'u1' after label 'lab3' (chain 'lab1') op lab1 OP_INSERT a=\"123\" b=\"456\" c=\"789\" d=\"3.14\" e=\"text\"  }\n"
	. "  unit 'u1' after-chained label 'lab1' op lab1 OP_INSERT a=\"123\" b=\"456\" c=\"789\" d=\"3.14\" e=\"text\"  }\n"
	. "unit 'u1' after label 'lab1' op lab1 OP_INSERT a=\"123\" b=\"456\" c=\"789\" d=\"3.14\" e=\"text\"  }\n"
	. "unit 'u1' before label 'lab1' op lab1 OP_DELETE a=\"123\" b=\"456\" c=\"789\" d=\"3.14\" e=\"text\"  {\n"
	. "  unit 'u1' before-chained label 'lab1' op lab1 OP_DELETE a=\"123\" b=\"456\" c=\"789\" d=\"3.14\" e=\"text\"  {\n"
	. "    unit 'u1' before label 'lab2' (chain 'lab1') op lab1 OP_DELETE a=\"123\" b=\"456\" c=\"789\" d=\"3.14\" e=\"text\"  {\n"
	. "      unit 'u1' before-chained label 'lab2' (chain 'lab1') op lab1 OP_DELETE a=\"123\" b=\"456\" c=\"789\" d=\"3.14\" e=\"text\"  {\n"
	. "        unit 'u1' before label 'lab3' (chain 'lab2') op lab1 OP_DELETE a=\"123\" b=\"456\" c=\"789\" d=\"3.14\" e=\"text\"  {\n"
	. "        unit 'u1' after label 'lab3' (chain 'lab2') op lab1 OP_DELETE a=\"123\" b=\"456\" c=\"789\" d=\"3.14\" e=\"text\"  }\n"
	. "      unit 'u1' after-chained label 'lab2' (chain 'lab1') op lab1 OP_DELETE a=\"123\" b=\"456\" c=\"789\" d=\"3.14\" e=\"text\"  }\n"
	. "    unit 'u1' after label 'lab2' (chain 'lab1') op lab1 OP_DELETE a=\"123\" b=\"456\" c=\"789\" d=\"3.14\" e=\"text\"  }\n"
	. "    unit 'u1' before label 'lab3' (chain 'lab1') op lab1 OP_DELETE a=\"123\" b=\"456\" c=\"789\" d=\"3.14\" e=\"text\"  {\n"
	. "    unit 'u1' after label 'lab3' (chain 'lab1') op lab1 OP_DELETE a=\"123\" b=\"456\" c=\"789\" d=\"3.14\" e=\"text\"  }\n"
	. "  unit 'u1' after-chained label 'lab1' op lab1 OP_DELETE a=\"123\" b=\"456\" c=\"789\" d=\"3.14\" e=\"text\"  }\n"
	. "unit 'u1' after label 'lab1' op lab1 OP_DELETE a=\"123\" b=\"456\" c=\"789\" d=\"3.14\" e=\"text\"  }"
	;


ok(join("\n", @history), $c_expect_rows);
#print join("\n", @history), "\n";

{
	my @res;

	# the stack treatment with chaining
	my $x_lab1 = $u1->makeLabel($rt1, "lab1", undef, sub {
		push(@res, $u1->getStackDepth());
	});
	ok(ref $x_lab1, "Triceps::Label");
	my $x_lab2 = $u1->makeLabel($rt1, "lab2", undef, sub {
		push(@res, $u1->getStackDepth());
	});
	ok(ref $x_lab2, "Triceps::Label");

	$x_lab1->chain($x_lab2);

	$v = $u1->makeHashCall($x_lab1, "OP_INSERT", @dataset1);
	ok($v);
	ok(join("-", @res), "2-2");
}

#############################################################
# frame marks are tested in FrameMark.t, as well as makeLoopHead()
# and makeLoopAround()

#############################################################
# callBound() is tested in Fn.t

#############################################################
# MUST BE LAST
# test the unit clearing

# direct
undef $clearlog;
$v = $xlab2->getUnit();
ok($u1->same($v));
$u1->clearLabels();
ok($clearlog, "clear xlab2 args=[a,b]\n");
$v = eval { $xlab2->getUnit(); };
ok(!defined $v);
ok($@, qr/^Triceps::Label::getUnit: label has been already cleared/);

# with a trigger object
$u2lab1 = $u2->makeDummyLabel($rt1, "u2lab1");
ok(ref $u2lab1, "Triceps::Label");
{
	my $trig = $u2->makeClearingTrigger();
	# check that the label is still alive
	$v = $u2lab1->getUnit();
	ok($u2->same($v));
}
# now the label on u2 should be cleared
$v = eval { $u2lab1->getUnit(); };
ok(!defined $v);
ok($@, qr/^Triceps::Label::getUnit: label has been already cleared/);
