#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The test for Aggregator in a table.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 94 };
use Triceps;
ok(2); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


######################### preparations (originating from Unit.t and Table.t)  #############################

$u1 = Triceps::Unit->new("u1");
ok(ref $u1, "Triceps::Unit");

# for debugging
$trsn1 = Triceps::UnitTracerStringName->new();
ok(ref $trsn1, "Triceps::UnitTracerStringName");
$u1->setTracer($trsn1);

$u2 = Triceps::Unit->new("u2");
ok(ref $u2, "Triceps::Unit");

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

@def2 = (
	b => "int32",
	c => "int64",
	v => "float64",
);
$rt2 = Triceps::RowType->new( # used later
	@def2
);
ok(ref $rt2, "Triceps::RowType");

######################### basic aggregation, recalculating every time  #############################

# collect the aggregator handler call history
my $aggistory;

sub aggHandler1 # (table, context, aggop, opcode, rh, state, args...)
{
	my ($table, $context, $aggop, $opcode, $rh, @args) = @_; # state is taken as part of args
	$agghistory .= "bad context type " . ref($context) unless (ref($context) eq "Triceps::AggregatorContext");
	$_[1] = 99; # try to spoil the original reference to context

	$args[0] = "*undef*" 
		unless (defined $args[0]);

	$agghistory .= "call (" . join(", ", @args) . ") " . &Triceps::aggOpString($aggop) . " " . &Triceps::opcodeString($opcode);
	if (!$rh->isNull()) {
		my $row = $rh->getRow();
		$agghistory .= " [" . join(", ", $rh->getRow()->toArray()) . "]\n";
	} else {
		$agghistory .= " NULL\n";
	}

	# calculate b as count(*), c as sum(c), v as last(d)
	my $sum = 0;
	for (my $iterh = $context->begin(); !$iterh->isNull(); $iterh = $context->next($iterh)) {
		$sum += $iterh->getRow()->get("c");
	}

	# this aggregator sends a NULL record after the last delete, the other option
	# would be to send nothing at all when $context->groupSize()==0

	# otherwise d is left as undef
	my $lastrh = $context->last();
	my $lastd;
	if (!$lastrh->isNull()) { 
		$lastd = $lastrh->getRow()->get("d");
	}

	my @vals = ( b => $context->groupSize(), c => $sum, v => $lastd );
	$context->makeHashSend($opcode, @vals);
	#my $res = $context->resultType()->makeRowHash(@vals);
	#print STDERR "DEBUG sent agg result [" . join(", ", $res->toArray()) . "]\n";

	undef $context; # if the references are wrong, this would delete the context object and cause a valgrind error later
}

# collect the aggregator result history
my $reshistory;

sub append_reshistory
{
	#print STDERR "DEBUG append_reshistory\n";
	my $lab = shift;
	my $rop = shift;
	my @arow = $rop->getRow()->toArray();
	# make the warnings about undefined values shut up
	foreach my $i (@arow) {
		$i = "*undef*" unless (defined $i);
	}
	$reshistory .= &Triceps::opcodeString($rop->getOpcode()) . " " 
		. " [" . join(", ", @arow) . "]\n";
}

my $aggreslab1 = $u1->makeLabel($rt2, "aggres1", undef, \&append_reshistory);
ok(ref $aggreslab1, "Triceps::Label");

$agt1 = Triceps::AggregatorType->new($rt2, "aggr", undef, \&aggHandler1, "qqqq", 12);
ok(ref $agt1, "Triceps::AggregatorType");
ok($rt2->same($agt1->getRowType()));

$it1 = Triceps::IndexType->newHashed(key => [ "b", "c" ])
	->addSubIndex("fifo", Triceps::IndexType->newFifo()
		->setAggregator($agt1)
	);
ok(ref $it1, "Triceps::IndexType");

# XXX the API is not very good: the index can be reused multiple times
# in the same table with different ids, but the aggregator in it can't
$tt1 = Triceps::TableType->new($rt1)
	->addSubIndex("grouping", $it1)
	;
ok(ref $tt1, "Triceps::TableType");

$res = $tt1->initialize();
ok($res, 1);

$t1 = $u1->makeTable($tt1, "tab1");
ok(ref $t1, "Triceps::Table");

# connect the history recording label
$res = $t1->getAggregatorLabel("aggr");
ok(ref $res, "Triceps::Label");
$res = $res->chain($aggreslab1);
ok($res, 1);

# send some records into the table

@dataset1 = (
	a => "uint8",
	b => 123,
	c => 3e15+0,
	d => 3.14,
	e => "string",
);
$r1 = $rt1->makeRowHash( @dataset1);
ok(ref $r1, "Triceps::Row");

@dataset2 = (
	a => "aaa",
	b => 123,
	c => 3e15+0,
	d => 2.71,
	e => "string2",
);
$r2 = $rt1->makeRowHash( @dataset2);
ok(ref $r2, "Triceps::Row");

$res = $t1->insert($r1);
ok($res == 1);
$res = $t1->insert($r2);
ok($res == 1);
$res = $t1->deleteRow($r2);
ok($res == 1);
$res = $t1->deleteRow($r1);
ok($res == 1);

ok($agghistory, 
	"call (*undef*, qqqq, 12) AO_AFTER_INSERT OP_INSERT [uint8, 123, 3000000000000000, 3.14, string]\n"
	. "call (*undef*, qqqq, 12) AO_BEFORE_MOD OP_DELETE NULL\n"
	. "call (*undef*, qqqq, 12) AO_AFTER_INSERT OP_INSERT [aaa, 123, 3000000000000000, 2.71, string2]\n"
	. "call (*undef*, qqqq, 12) AO_BEFORE_MOD OP_DELETE NULL\n"
	. "call (*undef*, qqqq, 12) AO_AFTER_DELETE OP_INSERT [aaa, 123, 3000000000000000, 2.71, string2]\n"
	. "call (*undef*, qqqq, 12) AO_BEFORE_MOD OP_DELETE NULL\n"
	. "call (*undef*, qqqq, 12) AO_AFTER_DELETE OP_INSERT [uint8, 123, 3000000000000000, 3.14, string]\n"
	. "call (*undef*, qqqq, 12) AO_COLLAPSE OP_NOP NULL\n"
);

# for the results to propagate through the history label, the unit must run...
$u1->drainFrame();
ok($u1->empty());
#print STDERR "DEBUG trace:\n" . $trsn1->print();

ok($reshistory, 
	"OP_INSERT  [1, 3000000000000000, 3.14]\n"
	. "OP_DELETE  [1, 3000000000000000, 3.14]\n"
	. "OP_INSERT  [2, 6000000000000000, 2.71]\n"
	. "OP_DELETE  [2, 6000000000000000, 2.71]\n"
	. "OP_INSERT  [1, 3000000000000000, 3.14]\n"
	. "OP_DELETE  [1, 3000000000000000, 3.14]\n"
	. "OP_INSERT  [0, 0, *undef*]\n"
	. "OP_NOP  [0, 0, *undef*]\n"
);

######################### basic aggregation, keeping the context  #############################

our $outside_context;

sub aggHandler2 # (table, context, aggop, opcode, rh, state, args...)
{
	my ($table, $context, $aggop, $opcode, $rh, $state, @args) = @_;

	#print STDERR "Got state $state " . ref($state) . "\n";

	if (!$rh->isNull()) {
		# apply the row

		# for field b instead of if() could use $context->groupSize()
		if ($aggop == &Triceps::AO_AFTER_INSERT) {
			$state->{"b"}++;
			$state->{"c"} += $rh->getRow()->get("c");
		} elsif ($aggop == &Triceps::AO_AFTER_DELETE) {
			$state->{"b"}--;
			$state->{"c"} -= $rh->getRow()->get("c");
		}
		# here it uses the last seen record, not last in the group!
		$state->{"v"} = $rh->getRow()->get("d");
	}

	# this aggregator sends a NULL record after the last delete, the other option
	# would be to send nothing at all when $context->groupSize()==0

	my $res = $context->resultType()->makeRowHash(%$state);
	# this is weird, but provides a way to test makeArraySend()
	$context->makeArraySend($opcode, $res->toArray());
	#print STDERR "DEBUG sent agg result [" . join(", ", $res->toArray()) . "]\n";

	$outside_context = $context; # try to access context later
}

sub aggConstructor2
{
	# the state is reference to the last record sent
	my $state = { b => 0, c => 0, v => 0 };
	#print STDERR "Constructed state $state " . ref($state) . "\n";
	return $state;
}

undef $reshistory;

$agt2 = Triceps::AggregatorType->new($rt2, "aggr", \&aggConstructor2, \&aggHandler2);
ok(ref $agt2, "Triceps::AggregatorType");

$it2 = Triceps::IndexType->newHashed(key => [ "b", "c" ])
	->addSubIndex("fifo", Triceps::IndexType->newFifo()
		->setAggregator($agt2)
	);
ok(ref $it2, "Triceps::IndexType");

$tt2 = Triceps::TableType->new($rt1)
	->addSubIndex("grouping", $it2)
	;
ok(ref $tt2, "Triceps::TableType");

$res = $tt2->initialize();
ok($res, 1);

$t2 = $u1->makeTable($tt2, "tab2");
ok(ref $t2, "Triceps::Table");

# connect the history recording label, same one as in test 1
$res = $t2->getAggregatorLabel("aggr");
ok(ref $res, "Triceps::Label");
$res = $res->chain($aggreslab1);
ok($res, 1);

# send the same records 

$res = $t2->insert($r1);
ok($res == 1);
$res = $t2->insert($r2);
ok($res == 1);
$res = $t2->deleteRow($r2);
ok($res == 1);
$res = $t2->deleteRow($r1);
ok($res == 1);

# for the results to propagate through the history label, the unit must run...
$trsn1->clearBuffer();
$u1->drainFrame();
ok($u1->empty());
#print STDERR "DEBUG trace:\n" . $trsn1->print();

ok($reshistory, 
	"OP_INSERT  [1, 3000000000000000, 3.14]\n"
	. "OP_DELETE  [1, 3000000000000000, 3.14]\n"
	. "OP_INSERT  [2, 6000000000000000, 2.71]\n"
	. "OP_DELETE  [2, 6000000000000000, 2.71]\n"
	. "OP_INSERT  [1, 3000000000000000, 2.71]\n" # here the definition of last() is different!
	. "OP_DELETE  [1, 3000000000000000, 2.71]\n"
	. "OP_INSERT  [0, 0, 3.14]\n" # 3.14 comes from the record being deleted
	. "OP_NOP  [0, 0, 3.14]\n"
);

# test that the remembered context is invalid
eval {
	$res = $outside_context->resultType();
};
ok("$@", qr/Triceps::AggregatorContext::resultType\(\): self has been already invalidated.*/);

######################### aggregation with both context and iteration  #############################

# reset the aggregator handler call history
undef $agghistory;

sub aggHandler3 # (table, context, aggop, opcode, rh, state, args...)
{
	my ($table, $context, $aggop, $opcode, $rh, $state, @args) = @_;
	$agghistory .= "bad context type " . ref($context) unless (ref($context) eq "Triceps::AggregatorContext");

	$agghistory .= "call (" . join(", ", @args) . ") " . &Triceps::aggOpString($aggop) . " " . &Triceps::opcodeString($opcode);
	if (!$rh->isNull()) {
		my $row = $rh->getRow();
		$agghistory .= " [" . join(", ", $rh->getRow()->toArray()) . "]\n";
	} else {
		$agghistory .= " NULL\n";
	}

	# don't send the NULL record after the group becomes empty
	return if ($context->groupSize()==0); # AO_COLLAPSE really gets taken care of here

	if ($aggop == &Triceps::AO_BEFORE_MOD || $aggop == &Triceps::AO_COLLAPSE) {
		# just resend the last record
		$context->send($opcode, $state);
		#print STDERR "DEBUG resent agg result [" . join(", ", $state->toArray()) . "]\n";
	} else {
		# recalculate the new state

		# calculate b as count(*), c as sum(c), v as last(d)
		my $sum = 0;
		for (my $iterh = $context->begin(); !$iterh->isNull(); $iterh = $context->next($iterh)) {
			$sum += $iterh->getRow()->get("c");
		}

		my $lastrh = $context->last();
		my @vals = ( b => $context->groupSize(), c => $sum, v => $lastrh->getRow()->get("d") );
		my $res = $context->resultType()->makeRowHash(@vals);

		# rememeber the last record in the state
		$_[5] = $res;

		$context->send($opcode, $res);
		#print STDERR "DEBUG sent agg result [" . join(", ", $res->toArray()) . "]\n";
	}
}

sub aggConstructor3 # (@args)
{
	$agghistory .= "construct (" . join(", ", @_) . ")\n"; # test argument passing to constructor
	return undef; # a placeholder for a future row reference
}

# reset the aggregator result history
undef $reshistory;

$agt3 = Triceps::AggregatorType->new($rt2, "aggr", \&aggConstructor3, \&aggHandler3, "qqqq", 12);
ok(ref $agt3, "Triceps::AggregatorType");

$it3 = Triceps::IndexType->newHashed(key => [ "b", "c" ])
	->addSubIndex("fifo", Triceps::IndexType->newFifo()
		->setAggregator($agt3)
	);
ok(ref $it3, "Triceps::IndexType");

$tt3 = Triceps::TableType->new($rt1)
	->addSubIndex("grouping", $it3)
	;
ok(ref $tt3, "Triceps::TableType");

$res = $tt3->initialize();
ok($res, 1);

$t3 = $u1->makeTable($tt3, "tab3");
ok(ref $t3, "Triceps::Table");

# connect the history recording label, same one as in test 1
$res = $t3->getAggregatorLabel("aggr");
ok(ref $res, "Triceps::Label");
$res = $res->chain($aggreslab1);
ok($res, 1);

# send the same records 

$res = $t3->insert($r1);
ok($res == 1);
$res = $t3->insert($r2);
ok($res == 1);
$res = $t3->deleteRow($r2);
ok($res == 1);
$res = $t3->deleteRow($r1);
ok($res == 1);

ok($agghistory, 
	"construct (qqqq, 12)\n"
	. "call (qqqq, 12) AO_AFTER_INSERT OP_INSERT [uint8, 123, 3000000000000000, 3.14, string]\n"
	. "call (qqqq, 12) AO_BEFORE_MOD OP_DELETE NULL\n"
	. "call (qqqq, 12) AO_AFTER_INSERT OP_INSERT [aaa, 123, 3000000000000000, 2.71, string2]\n"
	. "call (qqqq, 12) AO_BEFORE_MOD OP_DELETE NULL\n"
	. "call (qqqq, 12) AO_AFTER_DELETE OP_INSERT [aaa, 123, 3000000000000000, 2.71, string2]\n"
	. "call (qqqq, 12) AO_BEFORE_MOD OP_DELETE NULL\n"
	. "call (qqqq, 12) AO_AFTER_DELETE OP_INSERT [uint8, 123, 3000000000000000, 3.14, string]\n"
	. "call (qqqq, 12) AO_COLLAPSE OP_NOP NULL\n"
);

# for the results to propagate through the history label, the unit must run...
$trsn1->clearBuffer();
$u1->drainFrame();
ok($u1->empty());
#print STDERR "DEBUG trace:\n" . $trsn1->print();

ok($reshistory, 
	"OP_INSERT  [1, 3000000000000000, 3.14]\n"
	. "OP_DELETE  [1, 3000000000000000, 3.14]\n"
	. "OP_INSERT  [2, 6000000000000000, 2.71]\n"
	. "OP_DELETE  [2, 6000000000000000, 2.71]\n"
	. "OP_INSERT  [1, 3000000000000000, 3.14]\n"
	. "OP_DELETE  [1, 3000000000000000, 3.14]\n"
);

######################### aggregation with iteration by another index  #############################

# this is not exactly convenient: the other index type can be obtained from table type
# only after the iterator type is already hardcoded into it, so must go with an external
# variable
my $otherIndexType;

sub aggHandler4 # (table, context, aggop, opcode, rh, state, args...)
{
	my ($table, $context, $aggop, $opcode, $rh, $state, @args) = @_; # state is taken as part of args

	# calculate b as count(*), c as sum(c), v as last(d)
	# but iterate on a FIFO index in reverse order, so v actually becomes first(d)
	my $sum = 0;
	my $end = $context->endIdx($otherIndexType);
	my $itlastrh;
	for (my $iterh = $context->beginIdx($otherIndexType); !$iterh->same($end); $iterh = $table->nextIdx($otherIndexType, $iterh)) {
		$itlastrh = $iterh;
		$sum += $iterh->getRow()->get("c");
	}

	# this aggregator sends a NULL record after the last delete, the other option
	# would be to send nothing at all when $context->groupSize()==0

	# otherwise d is left as undef
	my $lastrh = $context->lastIdx($otherIndexType);
	my $lastd;
	if (!$lastrh->isNull()) { 
		if ($lastrh->same($itlastrh)) {
			$lastd = $lastrh->getRow()->get("d");
		} else {
			$lastd = 999999; # if iteration picks a different last record
		}
	}

	my @vals = ( b => $context->groupSize(), c => $sum, v => $lastd );
	my $res = $context->resultType()->makeRowHash(@vals);
	$context->send($opcode, $res);
	# print STDERR "DEBUG sent agg result [" . join(", ", $res->toArray()) . "]\n";

	undef $context; # if the references are wrong, this would delete the context object and cause a valgrind error later
}

# reset the aggregator result history
undef $reshistory;

$agt4 = Triceps::AggregatorType->new($rt2, "aggr", undef, \&aggHandler4, "qqqq", 12);
ok(ref $agt4, "Triceps::AggregatorType");

$it4 = Triceps::IndexType->newHashed(key => [ "b", "c" ])
	->addSubIndex("fifo", Triceps::IndexType->newFifo()
		->setAggregator($agt4)
	)->addSubIndex("reverse", Triceps::IndexType->newFifo(reverse => 1)
	);
ok(ref $it4, "Triceps::IndexType");

# XXX the API is not very good: the index can be reused multiple times
# in the same table with different ids, but the aggregator in it can't
$tt4 = Triceps::TableType->new($rt1)
	->addSubIndex("grouping", $it4)
	;
ok(ref $tt4, "Triceps::TableType");

$res = $tt4->initialize();
ok($res, 1);

$t4 = $u1->makeTable($tt4, "tab4");
ok(ref $t4, "Triceps::Table");

# remember the reverse index for the aggregator
$otherIndexType = $tt4->findSubIndex("grouping")->findSubIndex("reverse");
ok(ref $otherIndexType, "Triceps::IndexType");

# connect the history recording label, same one as in test 1
$res = $t4->getAggregatorLabel("aggr");
ok(ref $res, "Triceps::Label");
$res = $res->chain($aggreslab1);
ok($res, 1);

# send the same records (slightly different order)

$res = $t4->insert($r1);
ok($res == 1);
$res = $t4->insert($r2);
ok($res == 1);
$res = $t4->deleteRow($r1);
ok($res == 1);
$res = $t4->deleteRow($r2);
ok($res == 1);

# for the results to propagate through the history label, the unit must run...
$trsn1->clearBuffer();
$u1->drainFrame();
ok($u1->empty());
#print STDERR "DEBUG trace:\n" . $trsn1->print();

ok($reshistory, 
	"OP_INSERT  [1, 3000000000000000, 3.14]\n"
	. "OP_DELETE  [1, 3000000000000000, 3.14]\n"
	. "OP_INSERT  [2, 6000000000000000, 3.14]\n"
	. "OP_DELETE  [2, 6000000000000000, 3.14]\n"
	. "OP_INSERT  [1, 3000000000000000, 2.71]\n"
	. "OP_DELETE  [1, 3000000000000000, 2.71]\n"
	. "OP_INSERT  [0, 0, *undef*]\n"
	. "OP_NOP  [0, 0, *undef*]\n"
);

######################### source code, basic aggregation, keeping the context  #############################
# a variation of aggHandler2 with the code in a different format

undef $outside_context;

my $aggHandler2Src = '
	# (table, context, aggop, opcode, rh, state, args...)
	my ($table, $context, $aggop, $opcode, $rh, $state, @args) = @_;
	our $outside_context;

	#print STDERR "Got state $state " . ref($state) . "\n";

	if (!$rh->isNull()) {
		# apply the row

		# for field b instead of if() could use $context->groupSize()
		if ($aggop == &Triceps::AO_AFTER_INSERT) {
			$state->{"b"}++;
			$state->{"c"} += $rh->getRow()->get("c");
		} elsif ($aggop == &Triceps::AO_AFTER_DELETE) {
			$state->{"b"}--;
			$state->{"c"} -= $rh->getRow()->get("c");
		}
		# here it uses the last seen record, not last in the group!
		$state->{"v"} = $rh->getRow()->get("d");
	}

	# this aggregator sends a NULL record after the last delete, the other option
	# would be to send nothing at all when $context->groupSize()==0

	my $res = $context->resultType()->makeRowHash(%$state);
	# this is weird, but provides a way to test makeArraySend()
	$context->makeArraySend($opcode, $res->toArray());
	#print STDERR "DEBUG sent agg result [" . join(", ", $res->toArray()) . "]\n";

	$outside_context = $context; # try to access context later
';

my $aggConstructor2Src = '
	# the state is reference to the last record sent
	my $state = { b => 0, c => 0, v => 0 };
	#print STDERR "Constructed state $state " . ref($state) . "\n";
	return $state;
';

undef $reshistory;

$agt2 = Triceps::AggregatorType->new($rt2, "aggr", $aggConstructor2Src, $aggHandler2Src);
ok(ref $agt2, "Triceps::AggregatorType");

$it2 = Triceps::IndexType->newHashed(key => [ "b", "c" ])
	->addSubIndex("fifo", Triceps::IndexType->newFifo()
		->setAggregator($agt2)
	);
ok(ref $it2, "Triceps::IndexType");

$tt2 = Triceps::TableType->new($rt1)
	->addSubIndex("grouping", $it2)
	;
ok(ref $tt2, "Triceps::TableType");

$res = $tt2->initialize();
ok($res, 1);

$t2 = $u1->makeTable($tt2, "tab2");
ok(ref $t2, "Triceps::Table");

# connect the history recording label, same one as in test 1
$res = $t2->getAggregatorLabel("aggr");
ok(ref $res, "Triceps::Label");
$res = $res->chain($aggreslab1);
ok($res, 1);

# send the same records 

$res = $t2->insert($r1);
ok($res == 1);
$res = $t2->insert($r2);
ok($res == 1);
$res = $t2->deleteRow($r2);
ok($res == 1);
$res = $t2->deleteRow($r1);
ok($res == 1);

# for the results to propagate through the history label, the unit must run...
$trsn1->clearBuffer();
$u1->drainFrame();
ok($u1->empty());
#print STDERR "DEBUG trace:\n" . $trsn1->print();

ok($reshistory, 
	"OP_INSERT  [1, 3000000000000000, 3.14]\n"
	. "OP_DELETE  [1, 3000000000000000, 3.14]\n"
	. "OP_INSERT  [2, 6000000000000000, 2.71]\n"
	. "OP_DELETE  [2, 6000000000000000, 2.71]\n"
	. "OP_INSERT  [1, 3000000000000000, 2.71]\n" # here the definition of last() is different!
	. "OP_DELETE  [1, 3000000000000000, 2.71]\n"
	. "OP_INSERT  [0, 0, 3.14]\n" # 3.14 comes from the record being deleted
	. "OP_NOP  [0, 0, 3.14]\n"
);

# test that the remembered context is invalid
eval {
	$res = $outside_context->resultType();
};
ok("$@", qr/Triceps::AggregatorContext::resultType\(\): self has been already invalidated.*/);

######################### error handling in the constructor #############################

$agt2 = Triceps::AggregatorType->new($rt2, "aggr", '
	die "constructor test error";
', ' ');
ok(ref $agt2, "Triceps::AggregatorType");

$it2 = Triceps::IndexType->newHashed(key => [ "b", "c" ])
	->addSubIndex("fifo", Triceps::IndexType->newFifo()
		->setAggregator($agt2)
	);
ok(ref $it2, "Triceps::IndexType");

$tt2 = Triceps::TableType->new($rt1)
	->addSubIndex("grouping", $it2)
	;
ok(ref $tt2, "Triceps::TableType");

$res = $tt2->initialize();
ok($res, 1);

$t2 = $u1->makeTable($tt2, "tab2");
ok(ref $t2, "Triceps::Table");

eval { $t2->insert($r1); };
ok($@, qr/^Error in unit u1 table tab2 aggregator tab2.aggr constructor: constructor test error/);
eval { $t2->insert($r1); };
ok($@, qr/^Table is disabled due to the previous error:\n  Error in unit u1 table tab2 aggregator tab2.aggr constructor: constructor test error/);

######################### error handling in the handler #############################

$agt2 = Triceps::AggregatorType->new($rt2, "aggr", undef, '
	die "handler test error";
');
ok(ref $agt2, "Triceps::AggregatorType");

$it2 = Triceps::IndexType->newHashed(key => [ "b", "c" ])
	->addSubIndex("fifo", Triceps::IndexType->newFifo()
		->setAggregator($agt2)
	);
ok(ref $it2, "Triceps::IndexType");

$tt2 = Triceps::TableType->new($rt1)
	->addSubIndex("grouping", $it2)
	;
ok(ref $tt2, "Triceps::TableType");

$res = $tt2->initialize();
ok($res, 1);

$t2 = $u1->makeTable($tt2, "tab2");
ok(ref $t2, "Triceps::Table");

eval { $t2->insert($r1); };
ok($@, qr/^Error in unit u1 table tab2 aggregator tab2.aggr handler: handler test error/);
eval { $t2->insert($r1); };
ok($@, qr/^Table is disabled due to the previous error:\n  Error in unit u1 table tab2 aggregator tab2.aggr handler: handler test error/);
