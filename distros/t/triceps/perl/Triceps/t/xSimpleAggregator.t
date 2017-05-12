#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The initial version of Triceps::SimpleAggregator, preserved as a reference
# of the basic code generation for the aggregators.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;
use Carp;

use Test;
BEGIN { plan tests => 66 };
use Triceps;
use Triceps::X::TestFeed qw(:all);
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#########################
# The aggregator generation class
#

package MySimpleAggregator;
use Carp;

sub CLONE_SKIP { 1; }

use strict;

# the definition of aggregation functions
# in format:
#    funcName => {
#        featureName => featureValue, ...
#    }
# The features are:
#  argcount (optional) - count of arguments to the function, defaults to 1,
#      currently only supports 0 and 1
#  vars (optional) - define the variables used to store the intermediate result
#      as a ref to hash { varName => initializationConstantValue, ... }
#  step (optional) - define the code snippet for one step of the iteration.
#      It should be a complete statement or multiple statements. They will
#      be wrapped in an individual block. They can refer to the special variables:
#        $%argiter - function argument from the current iterated row
#        $%niter - sequential number of the current iterated row (starting from 0)
#        $%groupsize - size of the group being aggregated
#        other $%... - a variable defined in vars
#  result - define the code snippet to compute the result of the function.
#      It must be an expression, not a statement. It can refer to the special variables:
#        $%argfirst - function argument from the first row of the group
#        $%arglast - function argument from the last row of the group
#        $%groupsize - size of the group being aggregated
#        other $%... - a variable defined in vars
#  
our $FUNCTIONS = {
	first => {
		result => '$%argfirst',
	},
	last => {
		result => '$%arglast',
	},
	count_star => {
		argcount => 0,
		result => '$%groupsize',
	},
	count => {
		vars => { count => 0 },
		step => '$%count++ if (defined $%argiter);',
		result => '$%count',
	},
	sum => {
		vars => { sum => 0 },
		step => '$%sum += $%argiter;',
		result => '$%sum',
	},
	max => {
		vars => { max => 'undef' },
		step => '$%max = $%argiter if (!defined $%max || $%argiter > $%max);',
		result => '$%max',
	},
	min => {
		vars => { min => 'undef' },
		step => '$%min = $%argiter if (!defined $%min || $%argiter < $%min);',
		result => '$%min',
	},
	avg => {
		vars => { sum => 0, count => 0 },
		step => 'if (defined $%argiter) { $%sum += $%argiter; $%count++; }',
		result => '($%count == 0? undef : $%sum / $%count)',
	},
	avg_perl => { # Perl-like treat the NULLs as 0s
		vars => { sum => 0 },
		step => '$%sum += $%argiter;',
		result => '$%sum / $%groupsize',
	},
	nth_simple => { # inefficient, need proper multi-args for better efficiency
		vars => { n => 'undef', tmp => 'undef', val => 'undef' },
		step => '($%n, $%tmp) = @$%argiter; if ($%n == $%niter) { $%val = $%tmp; }',
		result => '$%val',
	},
	_defective => { # purely for test purposes, a defective definition
	},
	_defective_syntax => { # purely for test purposes, a defective definition
		result => 'XXXXXXX',
	},
	_defective_argiter => { # purely for test purposes, a defective definition
		argcount => 0,
		step => '$%argiter',
		result => '0',
	},
	_defective_stepvar => { # purely for test purposes, a defective definition
		argcount => 0,
		step => '$%x',
		result => '0',
	},
	_defective_argfirst => { # purely for test purposes, a defective definition
		argcount => 0,
		result => '$%argfirst',
	},
	_defective_arglast => { # purely for test purposes, a defective definition
		argcount => 0,
		result => '$%arglast',
	},
	_defective_resultvar => { # purely for test purposes, a defective definition
		argcount => 0,
		result => '$%x',
	},
};

# Make an aggregator and add it to a table type.
# The arguments are passed in option form, name-value pairs.
# Note: no $class argument!!!
# Options:
#   tabType (TableType) - table type on which to add the aggrgeator
#   name (string) - aggregator name
#   idxPath (reference to array of strings) - path of index type names to
#       the one where the aggregator is to be added
#   result (reference to an array of result field definitions) - repeating groups
#       fieldName => type, function, function_argument
#   saveRowTypeTo (optional, ref to a scalar) - where to save a copy of the result row type
#   saveInitTo (optional, ref to a scalar) - where to save a copy of the init function
#       source code, the saved value may be undef if the init is not used
#   saveComputeTo (optional, ref to a scalar) - where to save a copy of the compute
#       function source code
# @return - the same TableType, with added aggregator, or confess
sub make # (optName => optValue, ...)
{
	my $opts = {}; # the parsed options
	my $myname = "MySimpleAggregator::make";
	
	&Triceps::Opt::parse("MySimpleAggregator", $opts, {
			tabType => [ undef, sub { &Triceps::Opt::ck_mandatory(@_); &Triceps::Opt::ck_ref(@_, "Triceps::TableType") } ],
			name => [ undef, \&Triceps::Opt::ck_mandatory ],
			idxPath => [ undef, sub { &Triceps::Opt::ck_mandatory(@_); &Triceps::Opt::ck_ref(@_, "ARRAY", "") } ],
			result => [ undef, sub { &Triceps::Opt::ck_mandatory(@_); &Triceps::Opt::ck_ref(@_, "ARRAY") } ],
			saveRowTypeTo => [ undef, sub { &Triceps::Opt::ck_refscalar(@_) } ],
			saveInitTo => [ undef, sub { &Triceps::Opt::ck_refscalar(@_) } ],
			saveComputeTo => [ undef, sub { &Triceps::Opt::ck_refscalar(@_) } ],
		}, @_);

	# reset the saved source code
	${$opts->{saveInitTo}} = undef if (defined($opts->{saveInitTo}));
	${$opts->{saveComputeTo}} = undef if (defined($opts->{saveComputeTo}));
	${$opts->{saveRowTypeTo}} = undef if (defined($opts->{saveRowTypeTo}));

	# find the index type, on which to build the aggregator
	my $idx = $opts->{tabType}->findIndexPath(@{$opts->{idxPath}});
	confess "$myname: the index type is already initialized, can not add an aggregator on it"
		if ($idx->isInitialized());
	
	# check the result definition and build the result row type and code snippets for the computation
	my $rtRes;
	my $needIter = 0; # flag: some of the functions require iteration
	my $needfirst = 0; # the result needs the first row of the group
	my $needlast = 0; # the result needs the last row of the group
	my $codeInit = ''; # code for function initialization
	my $codeStep = ''; # code for iteration
	my $codeResult = ''; # code to compute the intermediate values for the result
	my $codeBuild = ''; # code to build the result row
	my @compArgs; # the field functions are passed as args to the computation
	{
		my $grpstep = 4; # definition grouped by 4 items per result field
		my @resopt = @{$opts->{result}};
		my @rtdefRes; # field definition for the result
		my $id = 0; # numeric id of the field

		while ($#resopt >= 0) {
			confess "$myname: the values in the result definition must go in groups of 4"
				unless ($#resopt >= 3);
			my $fld = shift @resopt;
			my $type = shift @resopt;
			my $func = shift @resopt;
			my $funcarg = shift @resopt;

			confess("$myname: the result field name must be a string, got a " . ref($fld) . " ")
				unless (ref($fld) eq '');
			confess("$myname: the result field type must be a string, got a " . ref($type) . " for field '$fld'")
				unless (ref($type) eq '');
			confess("$myname: the result field function must be a string, got a " . ref($func) . " for field '$fld'")
				unless (ref($func) eq '');

			my $funcDef = $FUNCTIONS->{$func}
				or confess("$myname: function '" . $func . "' is unknown");

			my $argCount = $funcDef->{argcount}; 
			$argCount = 1 # 1 is the default value
				unless defined($argCount);
			confess("$myname: in field '$fld' function '$func' requires an argument computation that must be a Perl sub reference")
				unless ($argCount == 0 || ref $funcarg eq 'CODE');
			confess("$myname: in field '$fld' function '$func' requires no argument, use undef as a placeholder")
				unless ($argCount != 0 || !defined $funcarg);

			push(@rtdefRes, $fld, $type);

			push(@compArgs, $funcarg)
				if (defined $funcarg);

			# add to the code snippets

			### initialization
			my $vars = $funcDef->{vars};
			if (defined $vars) {
				foreach my $v (keys %$vars) {
					# the variable names are given a unique prefix;
					# the initialization values are constants, no substitutions
					$codeInit .= "  my \$v${id}_${v} = " . $vars->{$v} . ";\n";
				}
			} else {
				$vars = { }; # a dummy
			}

			### iteration
			my $step = $funcDef->{step};
			if (defined $step) {
				$needIter = 1;
				$codeStep .= "    # field $fld=$func\n";
				if (defined $funcarg) {
					# compute the function argument from the current row
					$codeStep .= "    my \$a${id} = \$args[" . $#compArgs ."](\$row);\n";
				}
				# substitute the variables in $step
				$step =~ s/\$\%(\w+)/&replaceStep($1, $func, $vars, $id, $argCount)/ge;
				$codeStep .= "    { $step; }\n";
			}

			### result building
			my $result = $funcDef->{result};
			confess "MySimpleAggregator: internal error in definition of aggregation function '$func', missing result computation"
				unless (defined $result);
			# substitute the variables in $result
			if ($result =~ /\$\%argfirst/) {
				$needfirst = 1;
				$codeResult .= "  my \$f${id} = \$args[" . $#compArgs ."](\$rowFirst);\n";
			}
			if ($result =~ /\$\%arglast/) {
				$needlast = 1;
				$codeResult .= "  my \$l${id} = \$args[" . $#compArgs ."](\$rowLast);\n";
			}
			$result =~ s/\$\%(\w+)/&replaceResult($1, $func, $vars, $id, $argCount)/ge;
			$codeBuild .= "    ($result), # $fld\n";

			$id++;
		}
		$rtRes = Triceps::wrapfess
			"$myname: invalid result row type definition:",
			sub { Triceps::RowType->new(@rtdefRes); };
	}
	${$opts->{saveRowTypeTo}} = $rtRes if (defined($opts->{saveRowTypeTo}));

	# build the computation function
	my $compText = "sub {\n";
	$compText .= "  use strict;\n";
	$compText .= "  my (\$table, \$context, \$aggop, \$opcode, \$rh, \$state, \@args) = \@_;\n";
	$compText .= "  return if (\$context->groupSize()==0 || \$opcode == &Triceps::OP_NOP);\n";
	$compText .= $codeInit;
	if ($needIter) {
		$compText .= "  my \$npos = 0;\n";
		$compText .= "  for (my \$rhi = \$context->begin(); !\$rhi->isNull(); \$rhi = \$context->next(\$rhi)) {\n";
		$compText .= "    my \$row = \$rhi->getRow();\n";
		$compText .= $codeStep;
		$compText .= "    \$npos++;\n";
		$compText .= "  }\n";
	}
	if ($needfirst) {
		$compText .= "  my \$rowFirst = \$context->begin()->getRow();\n";
	}
	if ($needlast) {
		$compText .= "  my \$rowLast = \$context->last()->getRow();\n";
	}
	$compText .= $codeResult;
	$compText .= "  \$context->makeArraySend(\$opcode,\n";
	$compText .= $codeBuild;
	$compText .= "  );\n";
	$compText .= "}\n";

	${$opts->{saveComputeTo}} = $compText if (defined($opts->{saveComputeTo}));

	# compile the computation function
	my $compFun = eval $compText
		or confess "$myname: error in compilation of the aggregation computation:\n  $@function text:\n"
			. Triceps::Code::numalign($compText, "  ") . "\n";

	# build and add the aggregator
	my $agg = Triceps::wrapfess
		"$myname: internal error: failed to build an aggregator type:",
		sub { Triceps::AggregatorType->new($rtRes, $opts->{name}, undef, $compFun, @compArgs); };

	Triceps::wrapfess
		"$myname: failed to set the aggregator in the index type:",
		sub { $idx->setAggregator($agg); };

	return $opts->{tabType};
}

# For an aggregation function's step macro, replace a macro variable reference
# with the actual variable.
# @param varname - variable to replace
# @param func - function name, for error messages
# @param vars - definitions of the function's vars
# @param id - the unique id of this field
# @param argCount - the argument count declared by the function
sub replaceStep # ($varname, $func, $vars, $id, $argCount)
{
	my ($varname, $func, $vars, $id, $argCount) = @_;

	if ($varname eq 'argiter') {
		confess "MySimpleAggregator: internal error in definition of aggregation function '$func', step computation refers to 'argiter' but the function declares no arguments"
			unless ($argCount > 0);
		return "\$a${id}";
	} elsif ($varname eq 'niter') {
		return "\$npos";
	} elsif ($varname eq 'groupsize') {
		return "\$context->groupSize()";
	} elsif (exists $vars->{$varname}) {
		return "\$v${id}_${varname}";
	} else {
		confess "MySimpleAggregator: internal error in definition of aggregation function '$func', step computation refers to an unknown variable '$varname'"
	}
}

# For an aggregation function's result macro, replace a macro variable reference
# with the actual variable.
# @param varname - variable to replace
# @param func - function name, for error messages
# @param vars - definitions of the function's vars
# @param id - the unique id of this field
# @param argCount - the argument count declared by the function
sub replaceResult # ($varname, $func, $vars, $id, $argCount)
{
	my ($varname, $func, $vars, $id, $argCount) = @_;

	if ($varname eq 'argfirst') {
		confess "MySimpleAggregator: internal error in definition of aggregation function '$func', result computation refers to '$varname' but the function declares no arguments"
			unless ($argCount > 0);
		return "\$f${id}";
	} elsif ($varname eq 'arglast') {
		confess "MySimpleAggregator: internal error in definition of aggregation function '$func', result computation refers to '$varname' but the function declares no arguments"
			unless ($argCount > 0);
		return "\$l${id}";
	} elsif ($varname eq 'groupsize') {
		return "\$context->groupSize()";
	} elsif (exists $vars->{$varname}) {
		return "\$v${id}_${varname}";
	} else {
		confess "MySimpleAggregator: internal error in definition of aggregation function '$func', result computation refers to an unknown variable '$varname'"
	}
}

package main;

#######################################################################

use strict;

#########################
# helper functions

# instantiate the table and run it with the given input in TestFeed
sub runExample($$$) # ($unit, $tabType, $aggName)
{
	my ($unit, $tt, $aggName) = @_;
	$tt->initialize();
	my $t = $unit->makeTable($tt, "t");
	my $lbAgg = $t->getAggregatorLabel($aggName);
	
	# label to print the result of aggregation
	my $lbPrint = $unit->makeLabel($lbAgg->getType(), "lbPrint",
		undef, sub { # (label, rowop)
			&send($_[1]->printP(), "\n");
		});

	$lbAgg->chain($lbPrint);

	while(&readLine) {
		chomp;
		my @data = split(/,/); # starts with a string opcode
		$unit->makeArrayCall($t->getInputLabel(), @data);
		$unit->drainFrame(); # just in case, for completeness
	}
	# XXX this leaks labels $lbPrint until the unit gets cleared
	# (since forgetLabel() is not in Perl API at the moment)
}

# the input data
my $rtTrade = Triceps::RowType->new(
	id => "int32", # trade unique id
	symbol => "string", # symbol traded
	price => "float64",
	size => "float64", # number of shares traded
);

# create a new table type for trades, to put an aggregator on

sub makeTtWindow
{
	return Triceps::TableType->new($rtTrade)
		->addSubIndex("byId", 
			Triceps::IndexType->newHashed(key => [ "id" ])
		)
		->addSubIndex("bySymbol", 
			Triceps::IndexType->newHashed(key => [ "symbol" ])
			->addSubIndex("last2",
				Triceps::IndexType->newFifo(limit => 2)
			)
		);
}

#########################
# touch-test of all the main code-building paths

my $uTrades = Triceps::Unit->new("uTrades");

my $ttWindow = &makeTtWindow();

my $compText = 1;
my $initText = 1;
my $rtAggr = 1;
my $res = MySimpleAggregator::make(
	tabType => $ttWindow,
	name => "myAggr",
	idxPath => [ "bySymbol", "last2" ],
	result => [
		symbol => "string", "first", sub {$_[0]->get("symbol");},
		id => "int32", "last", sub {$_[0]->get("id");},
		volume => "float64", "sum", sub {$_[0]->get("size");},
		count => "int32", "count_star", undef,
		second => "int32", "nth_simple", sub { [1, $_[0]->get("id")];},
	],
	saveRowTypeTo => \$rtAggr,
	saveComputeTo => \$compText,
	saveInitTo => \$initText,
);
ok(ref $res, "Triceps::TableType");
ok($ttWindow->same($res));
ok(ref $rtAggr, "Triceps::RowType");
ok($rtAggr->print(undef), "row { string symbol, int32 id, float64 volume, int32 count, int32 second, }");
#print $compText;
ok(!defined($initText));
# check that the code elements are present
ok($compText =~ /rhi = /);
ok($compText =~ /rowFirst = /);
ok($compText =~ /rowLast = /);

setInputLines(
	"OP_INSERT,1,AAA,10,10\n",
	"OP_INSERT,2,BBB,100,100\n",
	"OP_INSERT,3,AAA,20,20\n",
	"OP_INSERT,5,AAA,30,30\n",
	"OP_INSERT,3,BBB,20,20\n",
	"OP_DELETE,5\n",
);
&runExample($uTrades, $ttWindow, "myAggr");
#print &getResultLines();
ok(&getResultLines(), 
'> OP_INSERT,1,AAA,10,10
t.myAggr OP_INSERT symbol="AAA" id="1" volume="10" count="1" 
> OP_INSERT,2,BBB,100,100
t.myAggr OP_INSERT symbol="BBB" id="2" volume="100" count="1" 
> OP_INSERT,3,AAA,20,20
t.myAggr OP_DELETE symbol="AAA" id="1" volume="10" count="1" 
t.myAggr OP_INSERT symbol="AAA" id="3" volume="30" count="2" second="3" 
> OP_INSERT,5,AAA,30,30
t.myAggr OP_DELETE symbol="AAA" id="3" volume="30" count="2" second="3" 
t.myAggr OP_INSERT symbol="AAA" id="5" volume="50" count="2" second="5" 
> OP_INSERT,3,BBB,20,20
t.myAggr OP_DELETE symbol="AAA" id="5" volume="50" count="2" second="5" 
t.myAggr OP_DELETE symbol="BBB" id="2" volume="100" count="1" 
t.myAggr OP_INSERT symbol="AAA" id="5" volume="30" count="1" 
t.myAggr OP_INSERT symbol="BBB" id="3" volume="120" count="2" second="3" 
> OP_DELETE,5
t.myAggr OP_DELETE symbol="AAA" id="5" volume="30" count="1" 
');

#########################
# test of path for the count only

$ttWindow = &makeTtWindow();

undef $compText;
undef $rtAggr;
$res = MySimpleAggregator::make(
	tabType => $ttWindow,
	name => "myAggr",
	idxPath => [ "bySymbol", "last2" ],
	result => [
		count => "int32", "count_star", undef,
	],
	saveRowTypeTo => \$rtAggr,
	saveComputeTo => \$compText,
);
ok(ref $res, "Triceps::TableType");
ok($ttWindow->same($res));
ok(ref $rtAggr, "Triceps::RowType");
ok($rtAggr->print(undef), "row { int32 count, }");
#print $compText;
# check that the code elements are present or absent
ok($compText !~ /rhi = /);
ok($compText !~ /rowFirst = /);
ok($compText !~ /rowLast = /);

setInputLines(
	"OP_INSERT,1,AAA,10,10\n",
	"OP_INSERT,2,BBB,100,100\n",
	"OP_INSERT,3,AAA,20,20\n",
	"OP_INSERT,5,AAA,30,30\n",
	"OP_INSERT,3,BBB,20,20\n",
	"OP_DELETE,5\n",
);
&runExample($uTrades, $ttWindow, "myAggr");
#print &getResultLines();
ok(&getResultLines(), 
'> OP_INSERT,1,AAA,10,10
t.myAggr OP_INSERT count="1" 
> OP_INSERT,2,BBB,100,100
t.myAggr OP_INSERT count="1" 
> OP_INSERT,3,AAA,20,20
t.myAggr OP_DELETE count="1" 
t.myAggr OP_INSERT count="2" 
> OP_INSERT,5,AAA,30,30
t.myAggr OP_DELETE count="2" 
t.myAggr OP_INSERT count="2" 
> OP_INSERT,3,BBB,20,20
t.myAggr OP_DELETE count="2" 
t.myAggr OP_DELETE count="1" 
t.myAggr OP_INSERT count="1" 
t.myAggr OP_INSERT count="2" 
> OP_DELETE,5
t.myAggr OP_DELETE count="1" 
');

#########################
# test of path for the first only

$ttWindow = &makeTtWindow();

undef $compText;
undef $rtAggr;
$res = MySimpleAggregator::make(
	tabType => $ttWindow,
	name => "myAggr",
	idxPath => [ "bySymbol", "last2" ],
	result => [
		symbol => "string", "first", sub {$_[0]->get("symbol");},
	],
	saveRowTypeTo => \$rtAggr,
	saveComputeTo => \$compText,
);
ok(ref $res, "Triceps::TableType");
ok($ttWindow->same($res));
ok(ref $rtAggr, "Triceps::RowType");
ok($rtAggr->print(undef), "row { string symbol, }");
#print $compText;
# check that the code elements are present or absent
ok($compText !~ /rhi = /);
ok($compText =~ /rowFirst = /);
ok($compText !~ /rowLast = /);

setInputLines(
	"OP_INSERT,1,AAA,10,10\n",
	"OP_INSERT,2,BBB,100,100\n",
	"OP_INSERT,3,AAA,20,20\n",
	"OP_INSERT,5,AAA,30,30\n",
	"OP_INSERT,3,BBB,20,20\n",
	"OP_DELETE,5\n",
);
&runExample($uTrades, $ttWindow, "myAggr");
#print &getResultLines();
ok(&getResultLines(), 
'> OP_INSERT,1,AAA,10,10
t.myAggr OP_INSERT symbol="AAA" 
> OP_INSERT,2,BBB,100,100
t.myAggr OP_INSERT symbol="BBB" 
> OP_INSERT,3,AAA,20,20
t.myAggr OP_DELETE symbol="AAA" 
t.myAggr OP_INSERT symbol="AAA" 
> OP_INSERT,5,AAA,30,30
t.myAggr OP_DELETE symbol="AAA" 
t.myAggr OP_INSERT symbol="AAA" 
> OP_INSERT,3,BBB,20,20
t.myAggr OP_DELETE symbol="AAA" 
t.myAggr OP_DELETE symbol="BBB" 
t.myAggr OP_INSERT symbol="AAA" 
t.myAggr OP_INSERT symbol="BBB" 
> OP_DELETE,5
t.myAggr OP_DELETE symbol="AAA" 
');

#########################
# test of path for the last only

$ttWindow = &makeTtWindow();

undef $compText;
undef $rtAggr;
$res = MySimpleAggregator::make(
	tabType => $ttWindow,
	name => "myAggr",
	idxPath => [ "bySymbol", "last2" ],
	result => [
		symbol => "string", "last", sub {$_[0]->get("symbol");},
	],
	saveRowTypeTo => \$rtAggr,
	saveComputeTo => \$compText,
);
ok(ref $res, "Triceps::TableType");
ok($ttWindow->same($res));
ok(ref $rtAggr, "Triceps::RowType");
ok($rtAggr->print(undef), "row { string symbol, }");
#print $compText;
# check that the code elements are present or absent
ok($compText !~ /rhi = /);
ok($compText !~ /rowFirst = /);
ok($compText =~ /rowLast = /);

setInputLines(
	"OP_INSERT,1,AAA,10,10\n",
	"OP_INSERT,2,BBB,100,100\n",
	"OP_INSERT,3,AAA,20,20\n",
	"OP_INSERT,5,AAA,30,30\n",
	"OP_INSERT,3,BBB,20,20\n",
	"OP_DELETE,5\n",
);
&runExample($uTrades, $ttWindow, "myAggr");
#print &getResultLines();
ok(&getResultLines(), 
'> OP_INSERT,1,AAA,10,10
t.myAggr OP_INSERT symbol="AAA" 
> OP_INSERT,2,BBB,100,100
t.myAggr OP_INSERT symbol="BBB" 
> OP_INSERT,3,AAA,20,20
t.myAggr OP_DELETE symbol="AAA" 
t.myAggr OP_INSERT symbol="AAA" 
> OP_INSERT,5,AAA,30,30
t.myAggr OP_DELETE symbol="AAA" 
t.myAggr OP_INSERT symbol="AAA" 
> OP_INSERT,3,BBB,20,20
t.myAggr OP_DELETE symbol="AAA" 
t.myAggr OP_DELETE symbol="BBB" 
t.myAggr OP_INSERT symbol="AAA" 
t.myAggr OP_INSERT symbol="BBB" 
> OP_DELETE,5
t.myAggr OP_DELETE symbol="AAA" 
');

#########################
# test without optional options

$ttWindow = &makeTtWindow();

$res = MySimpleAggregator::make(
	tabType => $ttWindow,
	name => "myAggr",
	idxPath => [ "bySymbol", "last2" ],
	result => [
		symbol => "string", "last", sub {$_[0]->get("symbol");},
	],
);
ok(ref $res, "Triceps::TableType");

#########################
# errors: missing mandatory options

$ttWindow = &makeTtWindow();
$res = eval {
	MySimpleAggregator::make(
		name => "myAggr",
		idxPath => [ "bySymbol", "last2" ],
		result => [
			symbol => "string", "last", sub {$_[0]->get("symbol");},
		],
	);
}; 
ok($@, qr/^Option 'tabType' must be specified for class 'MySimpleAggregator'/);

$ttWindow = &makeTtWindow();
$res = eval {
	MySimpleAggregator::make(
		tabType => $ttWindow,
		idxPath => [ "bySymbol", "last2" ],
		result => [
			symbol => "string", "last", sub {$_[0]->get("symbol");},
		],
	);
};
ok($@, qr/^Option 'name' must be specified for class 'MySimpleAggregator'/);

$ttWindow = &makeTtWindow();
$res = eval {
	MySimpleAggregator::make(
		tabType => $ttWindow,
		name => "myAggr",
		result => [
			symbol => "string", "last", sub {$_[0]->get("symbol");},
		],
	);
};
ok($@, qr/^Option 'idxPath' must be specified for class 'MySimpleAggregator'/);

$ttWindow = &makeTtWindow();
$res = eval {
	MySimpleAggregator::make(
		tabType => $ttWindow,
		name => "myAggr",
		idxPath => [ "bySymbol", "last2" ],
	);
};
ok($@, qr/^Option 'result' must be specified for class 'MySimpleAggregator'/);

#########################
# errors: bad values in options

sub tryBadOptValue($$) # (optName, optValue)
{
	$ttWindow = &makeTtWindow();
	my %opts = (
		tabType => $ttWindow,
		name => "myAggr",
		idxPath => [ "bySymbol", "last2" ],
		result => [
			symbol => "string", "last", sub {$_[0]->get("symbol");},
		],
		saveRowTypeTo => \$rtAggr,
		saveComputeTo => \$compText,
		saveInitTo => \$initText,
	);
	$opts{$_[0]} = $_[1];
	$res = eval {
		MySimpleAggregator::make(%opts);
	};
}

tryBadOptValue(
		tabType => "zzz",
);
ok($@, qr/^Option 'tabType' of class 'MySimpleAggregator' must be a reference to 'Triceps::TableType', is/);

tryBadOptValue(
		idxPath => { "bySymbol", "last2" },
);
ok($@, qr/^Option 'idxPath' of class 'MySimpleAggregator' must be a reference to 'ARRAY', is/);

tryBadOptValue(
		idxPath => [ $ttWindow ],
);
ok($@, qr/^Option 'idxPath' of class 'MySimpleAggregator' must be a reference to 'ARRAY' '', is/);

tryBadOptValue(
		result => { }
);
ok($@, qr/^Option 'result' of class 'MySimpleAggregator' must be a reference to 'ARRAY', is/);

tryBadOptValue(
		idxPath => [ ],
);
ok($@, qr/^Triceps::TableType::findIndexPath: idxPath must be an array of non-zero length, table type is:/);
#print "$@\n";

tryBadOptValue(
		idxPath => [ "bySymbol", "zzz" ],
);
ok($@, qr/^Triceps::TableType::findIndexPath: unable to find the index type at path 'bySymbol.zzz', table type is:/);
#print "$@\n";

$ttWindow = &makeTtWindow();
$ttWindow->initialize();
$res = eval {
	MySimpleAggregator::make(
		tabType => $ttWindow,
		name => "myAggr",
		idxPath => [ "bySymbol", "last2" ],
		result => [
			symbol => "string", "last", sub {$_[0]->get("symbol");},
		],
	);
};
ok($@, qr/^MySimpleAggregator::make: the index type is already initialized, can not add an aggregator on it/);

tryBadOptValue(
		result => [
			symbol => "string", "last", sub {$_[0]->get("symbol");},
			id => "int32", "last",
		],
);
ok($@, qr/^MySimpleAggregator::make: the values in the result definition must go in groups of 4/);

tryBadOptValue(
		result => [
			symbol => "string", "last", sub {$_[0]->get("symbol");}, sub {$_[0]->get("symbol");},
			id => "int32", "last", sub {$_[0]->get("id");},
		],
);
ok($@, qr/^MySimpleAggregator::make: the result field name must be a string, got a CODE/);

tryBadOptValue(
		result => [
			symbol => sub {$_[0]->get("symbol");},
			id => "int32", "last", sub {$_[0]->get("id");},
		],
);
ok($@, qr/^MySimpleAggregator::make: the result field type must be a string, got a CODE for field 'symbol'/);

tryBadOptValue(
		result => [
			symbol => "string", sub {$_[0]->get("symbol");},
			id => "int32", "last", sub {$_[0]->get("id");},
		],
);
ok($@, qr/^MySimpleAggregator::make: the result field function must be a string, got a CODE for field 'symbol'/);

tryBadOptValue(
		result => [
			symbol => "string", "nosuch", sub {$_[0]->get("symbol");},
			id => "int32", "last", sub {$_[0]->get("id");},
		],
);
ok($@, qr/^MySimpleAggregator::make: function 'nosuch' is unknown/);

tryBadOptValue(
		result => [
			symbol => "string", "first", 
			id => "int32", "last", sub {$_[0]->get("id");},
		],
);
ok($@, qr/^MySimpleAggregator::make: in field 'symbol' function 'first' requires an argument computation that must be a Perl sub reference/);

tryBadOptValue(
		result => [
			symbol => "string", "count_star", sub {$_[0]->get("symbol");},
		],
);
ok($@, qr/^MySimpleAggregator::make: in field 'symbol' function 'count_star' requires no argument, use undef as a placeholder/);

tryBadOptValue(
		result => [
			symbol => "string", "_defective", sub {$_[0]->get("symbol");},
		],
);
ok($@, qr/^MySimpleAggregator: internal error in definition of aggregation function '_defective', missing result computation/);

tryBadOptValue(
		result => [
			symbol => "string[]", "last", sub {$_[0]->get("symbol");},
		],
);
ok($@, qr/^MySimpleAggregator::make: invalid result row type definition:\n  Triceps::RowType::new: field 'symbol' string array type is not supported/);

tryBadOptValue(
		result => [
			symbol => "string", "_defective_syntax", sub {$_[0]->get("symbol");},
		],
);
#print $@;
ok($@, qr/^MySimpleAggregator::make: error in compilation of the aggregation computation:/);

tryBadOptValue(
		result => [
			symbol => "string", "_defective_argiter", undef
		],
);
ok($@, qr/^MySimpleAggregator: internal error in definition of aggregation function '_defective_argiter', step computation refers to 'argiter' but the function declares no arguments/);

tryBadOptValue(
		result => [
			symbol => "string", "_defective_argfirst", undef
		],
);
ok($@, qr/^MySimpleAggregator: internal error in definition of aggregation function '_defective_argfirst', result computation refers to 'argfirst' but the function declares no arguments/);

tryBadOptValue(
		result => [
			symbol => "string", "_defective_arglast", undef
		],
);
ok($@, qr/^MySimpleAggregator: internal error in definition of aggregation function '_defective_arglast', result computation refers to 'arglast' but the function declares no arguments/);

tryBadOptValue(
		result => [
			symbol => "string", "_defective_stepvar", undef
		],
);
ok($@, qr/^MySimpleAggregator: internal error in definition of aggregation function '_defective_stepvar', step computation refers to an unknown variable 'x'/);

tryBadOptValue(
		result => [
			symbol => "string", "_defective_resultvar", undef
		],
);
ok($@, qr/^MySimpleAggregator: internal error in definition of aggregation function '_defective_resultvar', result computation refers to an unknown variable 'x'/);
#print "$@\n";

#########################
# test the aggregation functions that weren't exercised in the first example
$ttWindow = &makeTtWindow();

undef $compText;
undef $rtAggr;
$res = MySimpleAggregator::make(
	tabType => $ttWindow,
	name => "myAggr",
	idxPath => [ "bySymbol", "last2" ],
	result => [
		symbol => "string", "first", sub {$_[0]->get("symbol");},
		id => "int32", "first", sub {$_[0]->get("id");},
		maxsize => "float64", "max", sub {$_[0]->get("size");},
		minsize => "float64", "min", sub {$_[0]->get("size");},
		count => "int32", "count", sub {$_[0]->get("size");},
		avg => "float64", "avg", sub {$_[0]->get("size");},
		# the following makes the Perl test warnings shut up on NULL fields
		avgperl => "float64", "avg_perl", sub { my $x = $_[0]->get("size"); if (!defined $x) {$x = 0;}; return $x},
	],
	saveRowTypeTo => \$rtAggr,
	saveComputeTo => \$compText,
);
ok(ref $res, "Triceps::TableType");
ok($ttWindow->same($res));
ok(ref $rtAggr, "Triceps::RowType");
ok($rtAggr->print(undef), "row { string symbol, int32 id, float64 maxsize, float64 minsize, int32 count, float64 avg, float64 avgperl, }");
#print $compText;

setInputLines(
	"OP_INSERT,1,AAA,10,\n",
	"OP_INSERT,2,AAA,10,100\n",
	"OP_INSERT,3,AAA,10,200\n",
	"OP_INSERT,4,AAA,10,50\n",
);
&runExample($uTrades, $ttWindow, "myAggr");
#print &getResultLines();
# the old records get pushed out of the window by the limit
ok(&getResultLines(), 
'> OP_INSERT,1,AAA,10,
t.myAggr OP_INSERT symbol="AAA" id="1" count="0" avgperl="0" 
> OP_INSERT,2,AAA,10,100
t.myAggr OP_DELETE symbol="AAA" id="1" count="0" avgperl="0" 
t.myAggr OP_INSERT symbol="AAA" id="1" maxsize="100" minsize="100" count="1" avg="100" avgperl="50" 
> OP_INSERT,3,AAA,10,200
t.myAggr OP_DELETE symbol="AAA" id="1" maxsize="100" minsize="100" count="1" avg="100" avgperl="50" 
t.myAggr OP_INSERT symbol="AAA" id="2" maxsize="200" minsize="100" count="2" avg="150" avgperl="150" 
> OP_INSERT,4,AAA,10,50
t.myAggr OP_DELETE symbol="AAA" id="2" maxsize="200" minsize="100" count="2" avg="150" avgperl="150" 
t.myAggr OP_INSERT symbol="AAA" id="3" maxsize="200" minsize="50" count="2" avg="125" avgperl="125" 
');
