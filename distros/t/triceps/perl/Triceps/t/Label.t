#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The test for Label.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 64 };
use Triceps;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


######################### preparations (originating from Table.t)  #############################

$u1 = Triceps::Unit->new("u1");
ok(ref $u1, "Triceps::Unit");

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

$res = $tt1->initialize();
ok($res, 1);

$t1 = $u1->makeTable($tt1, "tab1");
ok(ref $t1, "Triceps::Table");

$lb = $t1->getOutputLabel();
ok(ref $lb, "Triceps::Label");

########################## label g/setters #################################################

$rt2 = $lb->getType();
ok(ref $rt2, "Triceps::RowType");
ok($rt1->same($rt2));

$rt2 = $lb->getRowType();
ok(ref $rt2, "Triceps::RowType");
ok($rt1->same($rt2));

$v = $lb->getName();
ok($v, "tab1.out");

$v = $lb->same($lb);
ok($v);

$v = $lb->same($t1->getInputLabel());
ok(!$v);

$v = $lb->getUnit();
ok($u1->same($v));

ok(!$lb->isNonReentrant());
$lb->setNonReentrant();
ok($lb->isNonReentrant());

########################## chaining #################################################

$res = $lb->hasChained();
ok($res, 0);
@chain = $lb->getChain();
ok($#chain, -1);

# technically, chaining the input label of a table to its output label is a tight loop
# but here it doesn't matter
$res = $lb->chain($t1->getInputLabel());
ok($res);

$res = $lb->hasChained();
ok($res, 1);
@chain = $lb->getChain();
ok(join(", ", map {$_->getName()} @chain), "tab1.in");
$v = $t1->getInputLabel()->same($chain[0]);
ok($v);

# yes, the same chaining can be repeated!
$res = $lb->chain($t1->getInputLabel());
ok($res);

@chain = $lb->getChain();
ok(join(", ", map {$_->getName()} @chain), "tab1.in, tab1.in");

# incorrect chaining
eval { $lb->chain($lb); };
ok($@, qr/^Triceps::Label::chain: failed\n  labels must not be chained in a loop\n    tab1.out->tab1.out/);

# see that it's unchanged
@chain = $lb->getChain();
ok(join(", ", map {$_->getName()} @chain), "tab1.in, tab1.in");

# clear the chaining
$lb->clearChained();
@chain = $lb->getChain();
ok($#chain, -1);

######################### chainFront ##################################

$res = $lb->chainFront($t1->getInputLabel());
ok($res);

$res = $lb->chainFront($t1->getPreLabel());
ok($res);

@chain = $lb->getChain();
ok(join(", ", map {$_->getName()} @chain), "tab1.pre, tab1.in");

# incorrect chaining
eval { $lb->chainFront($lb); };
ok($@, qr/^Triceps::Label::chainFront: failed\n  labels must not be chained in a loop\n    tab1.out->tab1.out/);

# see that it's unchanged
@chain = $lb->getChain();
ok(join(", ", map {$_->getName()} @chain), "tab1.pre, tab1.in");

# clear the chaining
$lb->clearChained();
@chain = $lb->getChain();
ok($#chain, -1);

######################### makeRowop ###################################
# tested in Rowop.t, together with adopt()

######################## PerlLabel ####################################

# the more interesting execution is tested in Unit.t

sub plab_exec # (label, rowop)
{
	1;
}

$plab = $u1->makeLabel($rt1, "plab", undef, \&plab_exec);
ok(ref $plab, "Triceps::Label");

$res = $plab->getName();
ok($res, "plab");

$res = $plab->getCode();
ok($res, \&plab_exec);

ok(!$plab->isCleared());
$plab->clear();
ok($plab->isCleared());

eval { $res = $lb->getCode(); };
ok($@, qr/^Triceps::Label::getCode: label is not a Perl Label, has no Perl code/);

$lb->clear(); # even a non-Perl label can be cleared

# clearing of the objects by the default Triceps::clearArgs
package ttt;

sub CLONE_SKIP { 1; }

sub new
{
	my $class = shift;
	my $self = {a => 1, b => 2};
	bless $self, $class;
	return $self;
}

package main;

{
	my $tobj = ttt->new();
	ok(ref $tobj, "ttt");
	my $tcopy = $tobj;
	ok(exists $tcopy->{a});

	$plab = $u1->makeLabel($rt1, "plab", undef, \&plab_exec, $tobj);
	ok(ref $plab, "Triceps::Label");

	$plab->clear();

	# the undefuned clearSub equals to clearArgs() which will wipe out the object
	ok(!exists $tcopy->{a});
}

######################## ClearingLabel ####################################
# it's really a special simplified PerlLabel that does nothing but
# calls clearArgs() at clearing time, and should never be sent any data

{
	my $tobj = ttt->new();
	ok(ref $tobj, "ttt");
	my $tcopy = $tobj;
	ok(exists $tcopy->{a});

	my $clab = $u1->makeClearingLabel("clab", $tobj);
	ok(ref $clab, "Triceps::Label");
	ok($clab->getName(), "clab");

	$clab->clear();

	# clearing calls clearArgs() which will wipe out the object
	ok(!exists $tcopy->{a});
}

######################### makeChained ###################################

{
	my $res;
	my $olb = $u1->makeDummyLabel($rt1, "lbOrig");
	ok(ref $olb, "Triceps::Label");
	my $clb = $olb->makeChained("lbChained", sub {
		$res = "cleared";
	} , sub {
		my $label = shift;
		my $rowop = shift;
		$res .= $rowop->printP();
		$res .= sprintf("\nArgs: %s\n", join(' ', @_));
	}, 1, 2, 3);
	ok(ref $clb, "Triceps::Label");

	@chain = $olb->getChain();
	ok($#chain, 0);
	ok($clb->same($chain[0]));

	$u1->makeHashCall($olb, "OP_INSERT", b => 1);
	ok($res, "lbOrig OP_INSERT b=\"1\" \nArgs: 1 2 3\n");

	$clb->clear();
	ok($res, "cleared");

	# test errors
	ok(!defined eval {
		$olb->makeChained("lbChained", 1, 2);
	});
	ok($@, qr/^Triceps::Unit::makeLabel\(clear\): code must be a source code string or a reference to Perl function/);
	ok(!defined eval {
		$olb->makeChained("lbChained", undef);
	});
	ok($@, qr/^Use: Label::makeChained\(self, name, clear, exec, ...\)/);
	ok(!defined eval {
		$olb->clear();
		$olb->makeChained("lbChained", undef, undef);
	});
	ok($@, qr/^Triceps::Label::getUnit: label has been already cleared at \S+ line \S+\n\tTriceps::Label::makeChained/);
}

######################### code snippets #################################

# this gets transparently supported in the callback logic, so just
# test that the label can be constructed with the code snippets,
# as a touch-test
{
	my $olb = $u1->makeDummyLabel($rt1, "lbOrig");
	ok(ref $olb, "Triceps::Label");
	my $clb = $olb->makeChained("lbChained", '
		return 1
	' , '
		return 1
	', 1, 2, 3);
	ok(ref $clb, "Triceps::Label");
}

