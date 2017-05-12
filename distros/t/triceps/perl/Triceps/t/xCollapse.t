#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The original simple version of Triceps::Collapse.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;
use Carp;

use Test;
BEGIN { plan tests => 16 };
use Triceps;
use Triceps::X::TestFeed qw(:all);
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;

#########################

package MyCollapse;

use Carp;
use strict;

sub CLONE_SKIP { 1; }

# A constructor to create a Collapse template.
# It collapses multiple changes on each key into at most one delete and one insert,
# matching the final result after all the modifications.
# This allows to skip the intermediate updates, if only the end result is of interest.
#
# The arguments are specified as option name-value pairs:
# unit - the unit where this barrier belongs
# name - the barrier name, used as a prefix for the label names
# data - the dataset description, itself a reference to an array of option name-value pairs
#   (currently only one "data" option may be used, but this will be extended in the future)
#   name - name of the data set, used for its input and output labels, always make it
#      the first option (to get the correct name used in the error messages)
#   rowType - the row type (mutually exclusive with fromLabel)
#   fromLabel - the label that would send the data here, allows to find
#      out the row type and gets the dataset's input automatically chained to that label
#      (mutually exclusive with rowType)
#   key - the key of the data, a reference to array of strings, same as for Hashed index
#
# Confesses on any error.
sub new # ($class, $optName => $optValue, ...)
{
	my $class = shift;
	my $self = {};

	&Triceps::Opt::parse($class, $self, {
		unit => [ undef, sub { &Triceps::Opt::ck_mandatory(@_); &Triceps::Opt::ck_ref(@_, "Triceps::Unit") } ],
		name => [ undef, \&Triceps::Opt::ck_mandatory ],
		data => [ undef, sub { &Triceps::Opt::ck_mandatory(@_); &Triceps::Opt::ck_ref(@_, "ARRAY") } ],
	}, @_);
	
	# parse the data element
	my %data_unparsed = @{$self->{data}};
	my $dataset = {};
	&Triceps::Opt::parse("$class data set (" . ($data_unparsed{name} or 'UNKNOWN') . ")", $dataset, {
		name => [ undef, \&Triceps::Opt::ck_mandatory ],
		key => [ undef, sub { &Triceps::Opt::ck_mandatory(@_); &Triceps::Opt::ck_ref(@_, "ARRAY", "") } ],
		rowType => [ undef, sub { &Triceps::Opt::ck_ref(@_, "Triceps::RowType"); } ],
		fromLabel => [ undef, sub { &Triceps::Opt::ck_ref(@_, "Triceps::Label"); } ],
	}, @{$self->{data}});

	# save the dataset for the future
	$self->{datasets}{$dataset->{name}} = $dataset;
	# check the options
	confess "The data set (" . $dataset->{name} . ") must have only one of options rowType or fromLabel"
		if (defined $dataset->{rowType} && defined $dataset->{fromLabel});
	confess "The data set (" . $dataset->{name} . ") must have exactly one of options rowType or fromLabel"
		if (!defined $dataset->{rowType} && !defined $dataset->{fromLabel});
	my $lbFrom = $dataset->{fromLabel};
	if (defined $lbFrom) {
		confess "The unit of the Collapse and the unit of its data set (" . $dataset->{name} . ") fromLabel must be the same"
			unless ($self->{unit}->same($lbFrom->getUnit()));
		$dataset->{rowType} = $lbFrom->getType();
	}

	# create the tables
	$dataset->{tt} = Triceps::TableType->new($dataset->{rowType})
		->addSubIndex("primary", 
			Triceps::IndexType->newHashed(key => $dataset->{key})
		);

	Triceps::wrapfess
		"Collapse table type creation error for dataset '" . $dataset->{name} . "':",
		sub { $dataset->{tt}->initialize(); };

	$dataset->{tbInsert} = $self->{unit}->makeTable($dataset->{tt}, $self->{name} . "." . $dataset->{name} . ".tbInsert");
	$dataset->{tbDelete} = $self->{unit}->makeTable($dataset->{tt}, $self->{name} . "." . $dataset->{name} . ".tbInsert");

	# create the labels
	Triceps::wrapfess
		"Collapse internal error: input label creation for dataset '" . $dataset->{name} . "':",
		sub { $dataset->{lbIn} = $self->{unit}->makeLabel($dataset->{rowType}, $self->{name} . "." . $dataset->{name} . ".in", 
			undef, \&_handleInput, $self, $dataset); };

	Triceps::wrapfess
		"Collapse internal error: output label creation for dataset '" . $dataset->{name} . "':",
		sub { $dataset->{lbOut} = $self->{unit}->makeDummyLabel($dataset->{rowType}, $self->{name} . "." . $dataset->{name} . ".out"); };
			
	# chain the input label, if any
	if (defined $lbFrom) {
		$lbFrom->chain($dataset->{lbIn});
		delete $dataset->{fromLabel}; # no need to keep the reference any more
	}

	bless $self, $class;
	return $self;
}

# (protected)
# handle one incoming row on a dataset's input label
sub _handleInput # ($label, $rop, $self, $dataset)
{
	my $label = shift;
	my $rop = shift;
	my $self = shift;
	my $dataset = shift;

	if ($rop->isInsert()) {
		# Simply add to the insert table: the effect is the same, independently of
		# whether the row was previously deleted or not. This also handles correctly
		# multiple inserts without a delete between them, even though this kind of
		# input is not really expected.
		$dataset->{tbInsert}->insert($rop->getRow());
	} elsif($rop->isDelete()) {
		# If there was a row in the insert table, delete that row (undoing the previous insert).
		# Otherwise it means that there was no previous insert seen in this round, so this must be a
		# deletion of a row inserted in the previous round, so insert it into the delete table.
		if (! $dataset->{tbInsert}->deleteRow($rop->getRow())) {
			$dataset->{tbDelete}->insert($rop->getRow());
		}
	}
}

# Unlatch and flush the collected data, then latch again.
sub flush # ($self)
{
	my $self = shift;
	my $unit = $self->{unit};
	my $OP_INSERT = &Triceps::OP_INSERT;
	my $OP_DELETE = &Triceps::OP_DELETE;
	foreach my $dataset (values %{$self->{datasets}}) {
		my $tbIns = $dataset->{tbInsert};
		my $tbDel = $dataset->{tbDelete};
		my $lbOut = $dataset->{lbOut};
		my $next;
		# send the deletes always before the inserts
		for (my $rh = $tbDel->begin(); !$rh->isNull(); $rh = $next) {
			$next = $rh->next(); # advance the irerator before removing
			$tbDel->remove($rh);
			$unit->call($lbOut->makeRowop($OP_DELETE, $rh->getRow()));
		}
		for (my $rh = $tbIns->begin(); !$rh->isNull(); $rh = $next) {
			$next = $rh->next(); # advance the irerator before removing
			$tbIns->remove($rh);
			$unit->call($lbOut->makeRowop($OP_INSERT, $rh->getRow()));
		}
	}
}

# Get the input label of a dataset.
# Confesses on error.
sub getInputLabel($$) # ($self, $dsetname)
{
	my ($self, $dsetname) = @_;
	confess "Unknown dataset '$dsetname'"
		unless exists $self->{datasets}{$dsetname};
	return $self->{datasets}{$dsetname}{lbIn};
}

# Get the output label of a dataset.
# Confesses on error.
sub getOutputLabel($$) # ($self, $dsetname)
{
	my ($self, $dsetname) = @_;
	confess "Unknown dataset '$dsetname'"
		unless exists $self->{datasets}{$dsetname};
	return $self->{datasets}{$dsetname}{lbOut};
}

# Get the lists of datasets (currently only one).
sub getDatasets($) # ($self)
{
	my $self = shift;
	return keys %{$self->{datasets}};
}

# TODO In the future may also have separate calls for latching and unlatching.

package main;
use strict;

#########################
# Tests

# helper functions

# the common main loop based on FeedTest
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

my $collapse = MyCollapse->new(
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

my $collapse = MyCollapse->new(
	unit => $unit,
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
		MyCollapse->new(%opt);
	};
}

&tryMissingOptValue("unit");
ok($@, qr/^Option 'unit' must be specified for class 'MyCollapse'/);
&tryMissingOptValue("name");
ok($@, qr/^Option 'name' must be specified for class 'MyCollapse'/);
&tryMissingOptValue("data");
ok($@, qr/^Option 'data' must be specified for class 'MyCollapse'/);

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
		MyCollapse->new(%opt);
	};
}

&tryMissingDataOptValue("key");
ok($@, qr/^Option 'key' must be specified for class 'MyCollapse data set \(idata\)'/);
&tryMissingDataOptValue("name");
ok($@, qr/^Option 'name' must be specified for class 'MyCollapse data set/);
&tryMissingDataOptValue("rowType");
ok($@, qr/^The data set \(idata\) must have exactly one of options rowType or fromLabel/);

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
		MyCollapse->new(%opt);
	};
}

&tryBadOptValue("unit", 9);
ok($@, qr/^Option 'unit' of class 'MyCollapse' must be a reference to 'Triceps::Unit', is ''/);
&tryBadOptValue("data", 9);
ok($@, qr/^Option 'data' of class 'MyCollapse' must be a reference to 'ARRAY', is ''/);
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
ok($@, qr/^The data set \(idata\) must have only one of options rowType or fromLabel /);
{
	my $unit = Triceps::Unit->new("unit");
	&tryBadOptValue("data",[
		name => "idata",
		fromLabel => $unit->makeDummyLabel($rtData, "lbInput"),
		key => [ "local_ip", "remote_ip" ],
	]);
}
ok($@, qr/^The unit of the Collapse and the unit of its data set \(idata\) fromLabel must be the same/);

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
		MyCollapse->new(%opt);
	};
}

&tryBadDataOptValue("key", [ "xxx" ]);
ok($@, 
qr/^Collapse table type creation error for dataset 'idata':
  index error:
    nested index 1 'primary':
      can not find the key field 'xxx' at/);
