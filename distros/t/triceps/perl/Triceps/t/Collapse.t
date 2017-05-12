#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# Tests for the Collapse.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;
use Carp;

use Test;
BEGIN { plan tests => 27 };
use Triceps;
use Triceps::X::TestFeed qw(:all);
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;

#########################
# Tests

# the common main loop based on TestFeed
sub mainloop($$$) # ($unit, $datalabel, $collapse)
{
	my $unit = shift;
	my $datalabel = shift;
	my $collapse = shift;
	while(&readLine) {
		chomp;
		my @data = split(/,/); # starts with a command, then string opcode
		my $type = shift @data;
		if ($type eq "data") {
			my $rowop = $datalabel->makeRowopArray(@data);
			$unit->call($rowop);
			$unit->drainFrame(); # just in case, for completeness
		} elsif ($type eq "flush") {
			$collapse->flush();
		}
	}
}

#########################

# the input row type etc that will be reused in multiple tests
our $rtData = Triceps::RowType->new(
	# mostly copied from the traffic aggregation example
	local_ip => "string",
	remote_ip => "string",
	bytes => "int64",
);

#########################

sub testExplicitRowType
{

my $unit = Triceps::Unit->new("unit");

my $collapse = Triceps::Collapse->new(
	unit => $unit,
	name => "collapse",
	data => [
		name => "idata",
		rowType => $rtData,
		key => [ "local_ip", "remote_ip" ],
	],
);

my $lbPrint = makePrintLabel("print", $collapse->getOutputLabel("idata"));

# since there is only one dataset, this works and tests it
&mainloop($unit, $collapse->getInputLabel($collapse->getDatasets()), $collapse);
}

sub testFromLabel
{

my $unit = Triceps::Unit->new("unit");

my $lbInput = $unit->makeDummyLabel($rtData, "lbInput");

my $collapse = Triceps::Collapse->new(
	name => "collapse",
	data => [
		name => "idata",
		fromLabel => $lbInput,
		key => [ "local_ip", "remote_ip" ],
	],
);

# test the errors in getting the labels
eval {
	$collapse->getInputLabel("nosuch");
};
ok($@, qr/^Unknown dataset 'nosuch'/);
eval {
	$collapse->getOutputLabel("nosuch");
};
ok($@, qr/^Unknown dataset 'nosuch'/);

# test the label names
ok($collapse->getInputLabel("idata")->getName(), "collapse.idata.in");
ok($collapse->getOutputLabel("idata")->getName(), "collapse.idata.out");

my $lbPrint = makePrintLabel("print", $collapse->getOutputLabel("idata"));

&mainloop($unit, $lbInput, $collapse);
}

#########################

my @inputData = (
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
);

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
';

setInputLines(@inputData);
&testExplicitRowType();
#print &getResultLines();
ok(&getResultLines(), $expectResult);

setInputLines(@inputData);
&testFromLabel();
#print &getResultLines();
ok(&getResultLines(), $expectResult);

#########
# fnReturn
{
	my $unit = Triceps::Unit->new("unit");
	my $collapse = Triceps::Collapse->new(
		unit => $unit,
		name => "collapse",
		data => [
			name => "idata",
			rowType => $rtData,
			key => [ "local_ip", "remote_ip" ],
		],
	);
	ok(ref $collapse, "Triceps::Collapse");

	my $out = $collapse->getOutputLabel("idata");
	ok(!$out->hasChained());

	my $ret = $collapse->fnReturn();
	ok(ref $ret, "Triceps::FnReturn");
	ok($ret->getName(), "collapse.fret");
	ok($out->hasChained());
	my @chain = $out->getChain();
	ok($chain[0]->same($ret->getLabel("idata")));
	# On repeated calls gets the exact same object.
	ok($ret, $collapse->fnReturn());
}

#########################
# errors: bad values in options

sub tryMissingOptValue # (optName)
{
	my $unit = Triceps::Unit->new("unit");
	my %opt = (
		unit => $unit,
		name => "collapse",
		data => [
			name => "idata",
			rowType => $rtData,
			key => [ "local_ip", "remote_ip" ],
		],
	);
	delete $opt{$_[0]};
	my $res = eval {
		Triceps::Collapse->new(%opt);
	};
}

&tryMissingOptValue("unit");
ok($@, qr/^Triceps::Collapse data set \(idata\): option unit at the main level must be specified at/);
&tryMissingOptValue("name");
ok($@, qr/^Option 'name' must be specified for class 'Triceps::Collapse'/);
&tryMissingOptValue("data");
ok($@, qr/^Option 'data' must be specified for class 'Triceps::Collapse'/);

sub tryMissingDataOptValue # (optName)
{
	my $unit = Triceps::Unit->new("unit");
	my %data = (
		name => "idata",
		rowType => $rtData,
		key => [ "local_ip", "remote_ip" ],
	);
	delete $data{$_[0]};
	my @data = %data;
	my %opt = (
		unit => $unit,
		name => "collapse",
		data => \@data,
	);
	my $res = eval {
		Triceps::Collapse->new(%opt);
	};
}

&tryMissingDataOptValue("key");
ok($@, qr/^Option 'key' must be specified for class 'Triceps::Collapse data set \(idata\)'/);
&tryMissingDataOptValue("name");
ok($@, qr/^Option 'name' must be specified for class 'Triceps::Collapse data set/);
&tryMissingDataOptValue("rowType");
ok($@, qr/^Triceps::Collapse data set \(idata\): must have exactly one of options rowType or fromLabel/);

sub tryBadOptValue # (optName, optValue, ...)
{
	my $unit = Triceps::Unit->new("unit");
	my %opt = (
		unit => $unit,
		name => "collapse",
		data => [
			name => "idata",
			rowType => $rtData,
			key => [ "local_ip", "remote_ip" ],
		],
	);
	$opt{$_[0]} = $_[1];
	my $res = eval {
		Triceps::Collapse->new(%opt);
	};
}

&tryBadOptValue("unit", 9);
ok($@, qr/^Option 'unit' of class 'Triceps::Collapse' must be a reference to 'Triceps::Unit', is ''/);
&tryBadOptValue("data", 9);
ok($@, qr/^Option 'data' of class 'Triceps::Collapse' must be a reference to 'ARRAY', is ''/);
{
	my $unit = Triceps::Unit->new("unit");
	&tryBadOptValue("data",[
		name => "idata",
		rowType => $rtData,
		# technically incorrect to have a label from other unit but ok here
		fromLabel => $unit->makeDummyLabel($rtData, "lbInput"),
		key => [ "local_ip", "remote_ip" ],
	]);
}
ok($@, qr/^Triceps::Collapse data set \(idata\): must have only one of options rowType or fromLabel/);
{
	my $unit = Triceps::Unit->new("unit2");
	&tryBadOptValue("data",[
		name => "idata",
		fromLabel => $unit->makeDummyLabel($rtData, "lbInput"),
		key => [ "local_ip", "remote_ip" ],
	]);
}
ok($@, qr/^Triceps::Collapse data set \(idata\): the label 'lbInput' in option fromLabel has a mismatched unit \('unit2' vs 'unit'\)/);

sub tryBadDataOptValue # (optName, optValue, ...)
{
	my $unit = Triceps::Unit->new("unit");
	my %data = (
		name => "idata",
		rowType => $rtData,
		key => [ "local_ip", "remote_ip" ],
	);
	$data{$_[0]} = $_[1];
	my @data = %data;
	my %opt = (
		unit => $unit,
		name => "collapse",
		data => \@data,
	);
	my $res = eval {
		Triceps::Collapse->new(%opt);
	};
}

&tryBadDataOptValue("key", [ "xxx" ]);
#print $@;
ok($@, qr/Triceps::Collapse::new: Collapse table type creation error for dataset 'idata':
  index error:
    nested index 1 'primary':
      can not find the key field 'xxx' at /);

#########
# clearing

{
	my $unit = Triceps::Unit->new("unit");

	my $collapse = Triceps::Collapse->new(
		unit => $unit,
		name => "collapse",
		data => [
			name => "idata",
			rowType => $rtData,
			key => [ "local_ip", "remote_ip" ],
		],
	);
	ok(exists $collapse->{datasets});
	$unit->clearLabels();
	ok(!exists $collapse->{datasets});
}
