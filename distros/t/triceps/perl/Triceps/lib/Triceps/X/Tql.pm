#
# (C) Copyright 2011-2015 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The implementation of TQL (Triceps/Trivial Query Language).
# It expects to work in the context of the calls by Triceps::X::SimpleServer.

#########################

use strict;

package main;

# The Safe module doesn't seem capable of importing the external
# symbols from inside a package. So put this import outside the
# package.
sub _Triceps_X_Tql_share_safe_rowget # ($safe)
{
	my $safe = shift;
	$safe->share('Triceps::Row::get');
}

package Triceps::X::Tql;

sub CLONE_SKIP { 1; }

our $VERSION = 'v2.0.1';

use Carp;
use Triceps::Braced qw(:all);
use Triceps::X::ThreadedServer qw(printOrShut);
use Safe;

# There are two ways to create a Tql object:
# (1) Use the option "tables" (possibly, with "tableNames"): the Tql object
# will be immediately initialized with thid list of tables.
# (2) Use no options, and initially create an uninitialized object. Then
# add the tables one by one with addTable(). After all tables are added,
# call initialize().
#
# Options:
# name => $name
# Name for the object, will be use to derive the sub-object names.
#
# trieadOwner => $owner
# (optional) The TrieadOwner object for the multithreaded operation.
# This option enables the threaded operation.
# Default: undef.
#
# socketName => $name
# (optional) Name of the socket in the App. Required when trieadOwner
# is used.
# Default: undef.
#
# nxprefix => $name
# (optional) In threaded mode, the prefix for the nexus names that
# are used for communication between the core of the application
# and the client threads.
# Default: "tql".
#
# tables => [ @tables ]
# (optional) Reference to an array of tables on which the TQL 
# object will allow queries. The presence of this option triggers the
# immediate initialization.
#
# tableNames => [ @tnames ]
# (optional) Reference to an array of names, under which the tables
# from the option "tables" will be known to TQL. If absent, the table names
# will be obtained with getName() for each table.
#
# inputs => [ @inputs ]
# (optional) Reference to an array of labels that the multithreaded
# TQL will recognize as inputs to which the clients may send data.
# The single-threaded TQL silently ignores them.
# The presence of this option triggers the immediate initialization.
#
# inputNames => [ @names ]
# (optional) Reference to an array of names, under which the labels
# from the option "inputs" will be known to TQL. If absent, the names
# will be obtained with getName() for each label.
sub new # ($class, $optName => $optValue, ...)
{
	my $myname = "Triceps::X::Tql";
	my $class = shift;
	my $self = {};

	&Triceps::Opt::parse($class, $self, {
		name => [ undef, \&Triceps::Opt::ck_mandatory ],
		tables => [ undef, sub { &Triceps::Opt::ck_ref(@_, "ARRAY", "Triceps::Table") } ],
		tableNames => [ undef, sub { &Triceps::Opt::ck_ref(@_, "ARRAY", "") } ],
		inputs => [ undef, sub { &Triceps::Opt::ck_ref(@_, "ARRAY", "Triceps::Label") } ],
		inputNames => [ undef, sub { &Triceps::Opt::ck_ref(@_, "ARRAY", "") } ],
		trieadOwner => [ undef, sub { &Triceps::Opt::ck_ref(@_, "Triceps::TrieadOwner") } ],
		socketName => [ undef, undef ],
		nxprefix => [ "tql", undef ],
	}, @_);

	if (defined $self->{tables}) {
		if (defined $self->{tableNames}) {
			confess "$myname: the arrays in options 'tables' and 'tableNames' must be of equal size, got "
					. ($#{$self->{tables}} + 1) . " and " . ($#{$self->{tableNames}} + 1)
				unless ($#{$self->{tableNames}} == $#{$self->{tables}});
		} else {
			my @names;
			foreach my $t (@{$self->{tables}}) {
				push @names, $t->getName();
			}
			$self->{tableNames} = \@names;
		}
	} else {
		confess "$myname: the option 'tableNames' may not be used without option 'tables'."
			if (defined $self->{tableNames});
	}

	if (defined $self->{inputs}) {
		if (defined $self->{inputNames}) {
			confess "$myname: the arrays in options 'inputs' and 'inputNames' must be of equal size, got "
					. ($#{$self->{inputs}} + 1) . " and " . ($#{$self->{inputNames}} + 1)
				unless ($#{$self->{inputNames}} == $#{$self->{inputs}});
		} else {
			my @names;
			foreach my $t (@{$self->{inputs}}) {
				push @names, $t->getName();
			}
			$self->{inputNames} = \@names;
		}
	} else {
		confess "$myname: the option 'inputNames' may not be used without option 'inputs'."
			if (defined $self->{inputNames});
	}

	if (defined $self->{tables} || defined $self->{inputs}) {
		initialize($self);
	}

	confess "$myname: option 'trieadOwner' requires 'socketName'"
		if (defined $self->{trieadOwner} && !defined $self->{socketName});

	bless $self, $class;
	return $self;
}

# Add one or more named tables, defined in pairs of arguments.
# May be used only while $self is not initialized.
sub addNamedTable # ($self, $name => $table, ...)
{
	my $myname = "Triceps::X::Tql::addNamedTable";
	my $self = shift;

	confess "$myname: may be used only on an uninitialized object"
		if ($self->{initialized});

	while($#_ >= 0) {
		my $name = shift; 
		my $table = shift;

		my $tref = ref $table;
		confess "$myname: the table named '$name' must be of Triceps::Table type, is '$tref'"
			unless ($tref eq "Triceps::Table");

		push @{$self->{tables}}, $table;
		push @{$self->{tableNames}}, $name;
	}
}

# Add one or more tables, using their own names.
# May be used only while $self is not initialized.
sub addTable # ($self, @tables)
{
	my $myname = "Triceps::X::Tql::addTable";
	my $self = shift;

	confess "$myname: may be used only on an uninitialized object"
		if ($self->{initialized});

	for my $table (@_) {
		my $tref = ref $table;
		confess "$myname: the table must be of Triceps::Table type, is '$tref'"
			unless ($tref eq "Triceps::Table");

		push @{$self->{tables}}, $table;
		push @{$self->{tableNames}}, $table->getName();
	}
}

# Add one or input labels, using their own names.
# Has no effect in the single-threaded version.
# May be used only while $self is not initialized.
sub addInput # ($self, @labels)
{
	my $myname = "Triceps::X::Tql::addInput";
	my $self = shift;

	confess "$myname: may be used only on an uninitialized object"
		if ($self->{initialized});

	for my $label (@_) {
		my $ref = ref $label;
		confess "$myname: input label must be of Triceps::Label type, is '$ref'"
			unless ($ref eq "Triceps::Label");

		push @{$self->{inputs}}, $label;
		push @{$self->{inputNames}}, $label->getName();
	}
}

# Add one or more named inputs, defined in pairs of arguments.
# Has no effect in the single-threaded version.
# May be used only while $self is not initialized.
sub addNamedInput # ($self, $name => $label, ...)
{
	my $myname = "Triceps::X::Tql::addNamedInput";
	my $self = shift;

	confess "$myname: may be used only on an uninitialized object"
		if ($self->{initialized});

	while($#_ >= 0) {
		my $name = shift; 
		my $label = shift;

		my $ref = ref $label;
		confess "$myname: input label name '$name' must be of Triceps::Label type, is '$ref'"
			unless ($ref eq "Triceps::Label");

		push @{$self->{inputs}}, $label;
		push @{$self->{inputNames}}, $name;
	}
}

# Processing of the request to dump a table in the main thread,
# will be chained to every request label in the facet, with the
# appropriate table argument.
sub _dumpTable # ($label, $rowop, $self, $table)
{
	my ($label, $rop, $self, $table) = @_;
	my $unit = $label->getUnit();
	# pass through the client id to the dump
	$unit->call($self->{beginDump}->adopt($rop));
	$table->dumpAll();
	$unit->call($self->{endDump}->adopt($rop));
	$self->{faOut}->flushWriter();
}

# Initialize the object. After that the tables may not be added any more.
sub initialize # ($self)
{
	my $myname = "Triceps::X::Tql::initialize";
	my $self = shift;

	return if ($self->{initialized});

	my $owner = $self->{trieadOwner};
	if (defined $owner) {
		my @labels;
		my @tabtypes;

		# row type for dump requests and responses
		my $rtRequest = Triceps::RowType->new(
			client => "string", #requesting client
			id => "string", # request id
			name => "string", # the table name, for convenience of requestor
			cmd => "string", # for convenience of requestor, the command that it is executing
		);

		# row type for the communication between the client reader
		# and writer threads, they will pass through the common
		# nexuses, to synchronized with the data
		my $rtControl = Triceps::RowType->new(
			client => "string", # client, for which is this command
			cmd => "string", # the command
			id => "string", # the command id
			arg1 => "string", # the arguments depend on the command
			arg2 => "string",
			arg3 => "string",
		);

		# build the output side
		for (my $i = 0; $i <= $#{$self->{tables}}; $i++) {
			my $name = $self->{tableNames}[$i]; 
			my $table = $self->{tables}[$i];

			push @tabtypes, $name, $table->getType()->copyFundamental();
			push @labels, "t.out." . $name, $table->getOutputLabel();
			push @labels, "t.dump." . $name, $table->getDumpLabel();
		}
		push @labels, "control", $rtControl; # pass-through from in to out
		push @labels, "beginDump", $rtRequest; # framing for the table dumps
		push @labels, "endDump", $rtRequest;

		$self->{faOut} = $owner->makeNexus(
			name => $self->{nxprefix} . "out",
			labels => [ @labels ],
			tableTypes => [ @tabtypes ],
			import => "writer",
		);
		$self->{beginDump} = $self->{faOut}->getLabel("beginDump");
		$self->{endDump} = $self->{faOut}->getLabel("endDump");

		# build the input side
		undef @labels;
		for (my $i = 0; $i <= $#{$self->{inputs}}; $i++) {
			my $name = $self->{inputNames}[$i]; 
			my $input = $self->{inputs}[$i];

			push @labels, "in." . $name, $input->getRowType();
		}
		push @labels, "control", $rtControl;

		$self->{faIn} = $owner->makeNexus(
			name => $self->{nxprefix} . "in",
			labels => [ @labels ],
			import => "reader",
		);
		# tie together the labels
		for (my $i = 0; $i <= $#{$self->{inputs}}; $i++) {
			my $name = $self->{inputNames}[$i]; 
			my $input = $self->{inputs}[$i];

			$self->{faIn}->getLabel("in." . $name)->chain($input);
		}
		# the control passes through
		$self->{faIn}->getLabel("control")->chain($self->{faOut}->getLabel("control"));

		# build the dump requests, will be coming from below
		undef @labels;
		for (my $i = 0; $i <= $#{$self->{tables}}; $i++) {
			my $name = $self->{tableNames}[$i]; 
			my $table = $self->{tables}[$i];

			push @labels, "t.rqdump." . $name, $rtRequest;
		}
		$self->{faRqDump} = $owner->makeNexus(
			name => $self->{nxprefix} . "rqdump",
			labels => [ @labels ],
			reverse => 1, # avoids making a loop, and gives priority
			import => "reader",
		);
		# tie together the labels
		for (my $i = 0; $i <= $#{$self->{tables}}; $i++) {
			my $name = $self->{tableNames}[$i]; 
			my $table = $self->{tables}[$i];

			$self->{faRqDump}->getLabel("t.rqdump." . $name)->makeChained(
				$self->{nxprefix} . "rqdump." . $name, undef, 
				\&_dumpTable, $self, $table
			);
		}

		# start the listener thread
		Triceps::Triead::start(
			app => $owner->app()->getName(),
			thread => $self->{nxprefix} . "Listener",
			main => \&listenerT,
			socketName => $self->{socketName},
			nxprefix => $self->{nxprefix},
			mainTriead => $owner->getName(),
		);
	} else {
		my %dispatch;
		my @labels;
		for (my $i = 0; $i <= $#{$self->{tables}}; $i++) {
			my $name = $self->{tableNames}[$i]; 
			my $table = $self->{tables}[$i];

			confess "$myname: found a duplicate table name '$name', all names are: "
					. join(", ", @{$self->{tableNames}})
				if (exists $dispatch{$name});

			$dispatch{$name} = $table;
			push @labels, $name, $table->getDumpLabel();
		}

		$self->{dispatch} = \%dispatch;
		$self->{fret} = Triceps::FnReturn->new(
			name => $self->{name} . ".fret",
			labels => \@labels,
		);
	}

	$self->{initialized} = 1;
}

# Build a "qdumpsub" request for dumping a table and subscribing to its
# updates in the multithreaded configuration.
#
# Confesses on errors.
#
# @param ctx - the context of the query
# @param tabname - name of the table to dump
# @param front - flag: put this request at the front of the requests
#        list; default: 0; the normal reading should use 0 but the
#        joining uses 1 to read the dimension tables before the
#        man fact feed starts
# @param lbNext - the label where the results of the dump and
#        subscription will be sent; if undef then a dummy label will
#        be created automatically
# @return - the lbNext, as passed in or automatically created
sub _makeQdumpsub # ($ctx, $tabname, [$front, $lbNext])
{
	my $ctx = shift;
	my $tabname = shift;
	my $front = shift;
	my $lbNext = shift;

	my $unit = $ctx->{u};

	my $lbrq = eval {
		$ctx->{faRqDump}->getLabel("t.rqdump.$tabname");
	};
	my $lbsrc = eval {
		$ctx->{faOut}->getLabel("t.out.$tabname");
	};
	die ("Found no such table '$tabname'\n") unless ($lbrq && $lbsrc);

	# compute the binding for the data dumps, that would be a cross-unit
	# binding to the original faOut but it's OK
	my $fretOut = $ctx->{faOut}->getFnReturn();
	my $dumpname = "t.dump.$tabname";
	# the dump and following subscription data will merge on this label
	if (!defined $lbNext) {
		$lbNext = $unit->makeDummyLabel(
			$lbsrc->getRowType(), "lb" . $ctx->{id} . "out_$tabname");
	}

	my $bindDump = Triceps::FnBinding->new(
		on => $fretOut,
		name => "bind" . $ctx->{id} . "dump",
		labels => [ $dumpname => $lbNext ],
	);

	# qdumpsub:
	#   * label where to send the dump request to
	#   * source output label, from which a subscription will be set up
	#     at the end of the dump
	#   * target label in the query that will be tied to the source label
	#   * binding to be used during the dump, which also directs the data
	#     to the same target label
	my $request = [ "qdumpsub", $lbrq, $lbsrc, $lbNext, $bindDump ];
	if ($front) {
		unshift @{$ctx->{requests}}, $request;
	} else {
		push @{$ctx->{requests}}, $request;
	}
	return $lbNext;
}

# "read" command. Defines a table to read from and starts the command pipeline.
# Options:
# table - name of the table to read from.
sub _tqlRead # ($ctx, @args)
{
	my $ctx = shift;
	die "The read command may not be used in the middle of a pipeline.\n" 
		if (defined($ctx->{prev}));
	my $opts = {};
	# XXX add ways to unquote when option parsing?
	&Triceps::Opt::parse("read", $opts, {
		table => [ undef, \&Triceps::Opt::ck_mandatory ],
	}, @_);

	my $tabname = bunescape($opts->{table});
	my $unit = $ctx->{u};

	if ($ctx->{faOut}) {
		# This request is not combined with any other table dump;
		# if the query does a self-join, the table will be independently
		# dumped twice.
		# XXX For now the result of "read" is not saved in any local table
		# copy, so it can not be used with a JoinTwo, only with a LookupJoin
		# (which is consistent with the single-threaded Tql).

		$ctx->{next} = &_makeQdumpsub($ctx, $tabname);
	} else {
		my $fret = $ctx->{fretDumps};

		die ("Read found no such table '$tabname'\n")
			unless (exists $ctx->{tables}{$tabname});
		my $table = $ctx->{tables}{$tabname};
		my $lab = $unit->makeDummyLabel($table->getRowType(), "lb" . $ctx->{id} . "read");
		$ctx->{next} = $lab;

		my $code = sub {
			Triceps::FnBinding::call(
				name => "bind" . $ctx->{id} . "read",
				unit => $unit,
				on => $fret,
				labels => [
					$tabname => $lab,
				],
				code => sub {
					$table->dumpAll();
				},
			);
		};
		push @{$ctx->{actions}}, $code;
	}
}

# "project" command. Projects (and possibly renames) a subset of fields
# in the current pipeline.
# Options:
# fields - an array of field definitions in the syntax of Triceps::Fields::filter()
#   (same as in the joins).
sub _tqlProject # ($ctx, @args)
{
	my $ctx = shift;
	die "The project command may not be used at the start of a pipeline.\n" 
		unless (defined($ctx->{prev}));
	my $opts = {};
	&Triceps::Opt::parse("project", $opts, {
		fields => [ undef, \&Triceps::Opt::ck_mandatory ],
	}, @_);
	
	my $patterns = split_braced_final($opts->{fields});

	my $rtIn = $ctx->{prev}->getRowType();
	my @inFields = $rtIn->getFieldNames();
	my @pairs =  &Triceps::Fields::filterToPairs("project", \@inFields, $patterns);
	my ($rtOut, $projectFunc) = &Triceps::Fields::makeTranslation(
		rowTypes => [ $rtIn ],
		filterPairs => [ \@pairs ],
	);

	my $unit = $ctx->{u};
	my $lab = $unit->makeDummyLabel($rtOut, "lb" . $ctx->{id} . "project");
	my $labin = $unit->makeLabel($rtIn, "lb" . $ctx->{id} . "project.in", undef, sub {
		$unit->call($lab->makeRowop($_[1]->getOpcode(), &$projectFunc($_[1]->getRow()) ));
	});
	$ctx->{prev}->chain($labin);
	$ctx->{next} = $lab;
}

# "print" command. The last command of the pipeline, which prints the results.
# If not used explicitly, the query adds this command implicitly at the end
# of the pipeline, with the default options.
# Options:
# tokenized (optional) - Flag: print in the name-value format, as in Row::printP().
#   Otherwise prints only the values in the CSV format. (default: 1)
sub _tqlPrint # ($ctx, @args)
{
	my $ctx = shift;
	die "The print command may not be used at the start of a pipeline.\n" 
		unless (defined($ctx->{prev}));
	my $opts = {};
	&Triceps::Opt::parse("print", $opts, {
		tokenized => [ 1, undef ],
	}, @_);
	my $tokenized = bunescape($opts->{tokenized}) + 0;
	my $prev = $ctx->{prev};

	if ($ctx->{faOut}) {
		if ($tokenized) {
			# print in the tokenized format
			$prev->makeChained("lb" . $ctx->{id} . "print", undef, sub {
				&{$_[3]}("t,", $_[2], ",", $_[1]->printP($_[2]), "\n");
			}, $ctx->{qname}, $ctx->{subPrint});
		} else {
			$prev->makeChained("lb" . $ctx->{id} . "print", undef, sub {
				&{$_[3]}(
					"d,", $_[2], ",", Triceps::opcodeString($_[1]->getOpcode()), ",",
					join(",", $_[1]->getRow()->toArray()), "\n");
			}, $ctx->{qname}, $ctx->{subPrint});
		}
		# no need for end-of-data notification, the framework code will
		# take care of it (and it's not end-of-data but end-of-dump)
	} else {
		if ($tokenized) {
			# print in the tokenized format
			$prev->makeChained("lb" . $ctx->{id} . "print", undef, sub {
				&Triceps::X::SimpleServer::outCurBuf($_[1]->printP($_[2]) . "\n");
			}, $ctx->{qname});
		} else {
			Triceps::X::SimpleServer::makeServerOutLabel($ctx->{prev}, $ctx->{qname});
		}

		# The end-of-data notification. It will run after the current pipeline
		# finishes.
		my $prevname = $ctx->{qname};
		push @{$ctx->{actions}}, sub {
			&Triceps::X::SimpleServer::outCurBuf("+EOD,OP_NOP,$prevname\n");
		};
	}

	$ctx->{next} = undef; # end of the pipeline
}

# "join" command. Joins the current pipeline with another table.
# This is functionally similar to LookupJoin, although the options
# are closer to JoinTwo.
# Options:
# table - name of the table to join with. The current pipeline is
#   considered the "left side", the table the "right side".
#   The duplicate key fields on the right side are always excluded
#   from the result, like JoinTwo option (fieldsUniqKey => "left").
# rightIdxPath (optional) - path name of the table's index on which to join.
#   (As usual, the path is an array of nested names). By default is
#   computed automatically from options by or byLeft. If it can not be
#   found automatically, or the explicitly specified index doesn't
#   exist or has incorrect key fields, it's an error.
# by (semi-optional) - the join equality condition specified as
#   pairs of fields. Similarly to JoinTwo, it's a single-level array
#   with the fields logically paired:
#   {leftFld1 rightFld1 leftFld2 rightFld2 ... }
#   Options "by" and "byLeft" are mutually exclusive, and one of them
#   must be present.
# byLeft (semi-optional) - the join equality condition specified as
#   a transformation on the left-side field set in the syntax of
#   Triceps::Fields::filter(), with an implicit element {!.*}
#   added at the end.
#   Options "by" and "byLeft" are mutually exclusive, and one of them
#   must be present.
# leftFields (optional) - the list of patterns for the left-side fields
#   to pass through and possibly rename, in the syntax of 
#   Triceps::Fields::filter(). (default: pass all, with the same name)
# rightFields (optional) - the list of patterns for the right-side fields
#   to pass through and possibly rename, in the syntax of 
#   Triceps::Fields::filter(). The key fields get implicitly removed
#   before. (default: pass all, with the same name)
# type (optional) - type of the join, "inner" or "left". (default: "inner")
sub _tqlJoin # ($ctx, @args)
{
	my $ctx = shift;
	die "The join command may not be used at the start of a pipeline.\n" 
		unless (defined($ctx->{prev}));
	my $opts = {};
	&Triceps::Opt::parse("join", $opts, {
		table => [ undef, \&Triceps::Opt::ck_mandatory ],
		rightIdxPath => [ undef, undef ],
		by => [ undef, undef ],
		byLeft => [ undef, undef ],
		leftFields => [ undef, undef ],
		rightFields => [ undef, undef ],
		type => [ "inner", undef ],
	}, @_);

	my $tabname = bunescape($opts->{table});
	my $unit = $ctx->{u};
	my $table;

	&Triceps::Opt::checkMutuallyExclusive("join", 1, "by", $opts->{by}, "byLeft", $opts->{byLeft});
	my $by = split_braced_final($opts->{by});
	my $byLeft = split_braced_final($opts->{byLeft});

	my $rightIdxPath;
	if (defined $opts->{rightIdxPath}) { # propagate the undef
		$rightIdxPath = split_braced_final($opts->{rightIdxPath});
	}

	# If we were to use a JoinTwo (which is more correct), the data
	# incoming through the query would have to be put into a table too.
	# And that requires finding the primary key for the data.
	# I suppose, after the sequence ids for the rows would get worked
	# out, that would provide the easy default primary key.
	if ($ctx->{faOut}) {
		# Potentially, the tables might be reused between multiple joins
		# in the query if the required keys match. But for now keep things
		# simpler by creating a new table from scratch each time.

		my $tt = eval {
			# copy to avoid adding an index to the original type
			$ctx->{faOut}->impTableType($tabname)->copy();
		};
		die ("Join found no such table '$tabname'\n") unless ($tt);

		if (!defined $rightIdxPath) {
			# determine or add the index automatically
			my @workby;
			if (defined $byLeft) { # need to translate
				my @leftfld = $ctx->{prev}->getRowType()->getFieldNames();
				@workby = &Triceps::Fields::filterToPairs("Join option 'byLeft'", 
					\@leftfld, [ @$byLeft, "!.*" ]);
			} else {
				@workby = @$by;
			}
			
			my @idxkeys; # extract the keys for the right side table
			for (my $i = 1; $i <= $#workby; $i+= 2) {
				push @idxkeys, $workby[$i];
			}
			$rightIdxPath = [ $tt->findOrAddIndex(@idxkeys) ];
		}

		# build the table from the type
		$tt->initialize();
		$table = $ctx->{u}->makeTable($tt, "tab" . $ctx->{id} . $tabname);
		push @{$ctx->{copyTables}}, $table;

		# build the request that fills the table with data and then
		# keeps it up to date; 
		# the table has to be filled before the query's main flow starts,
		# so put the request at the front
		&_makeQdumpsub($ctx, $tabname, 1, $table->getInputLabel());
	} else {
		die ("Join found no such table '$tabname'\n")
			unless (exists $ctx->{tables}{$tabname});
		$table = $ctx->{tables}{$tabname};
	}

	my $isLeft = 0; # default for inner join
	my $type = $opts->{type};
	if ($type eq "inner") {
		# already default
	} elsif ($type eq "left") {
		$isLeft = 1;
	} else {
		die "Unsupported value '$type' of option 'type'.\n"
	}

	my $leftFields = split_braced_final($opts->{leftFields});
	my $rightFields = split_braced_final($opts->{rightFields});

	my $join = Triceps::LookupJoin->new(
		name => "join" . $ctx->{id},
		unit => $unit,
		leftFromLabel => $ctx->{prev},
		rightTable => $table,
		rightIdxPath => $rightIdxPath,
		leftFields => $leftFields,
		rightFields => $rightFields,
		by => $by,
		byLeft => $byLeft,
		isLeft => $isLeft,
		fieldsDropRightKey => 1,
	);
	
	$ctx->{next} = $join->getOutputLabel();
}

# Replace a field name with the code that would get the field
# from a variable containing a row. The row definition in hash
# formatr is used to check up-front that the field exists.
sub replaceFieldRef # (\%def, $field)
{
	my $def = shift;
	my $field = shift;
	die "Unknown field '$field'; have fields: " . join(", ", keys %$def) . ".\n"
		unless (exists ${$def}{$field});
	#return '$_[0]->get("' . quotemeta($field) . '")';
	return '&Triceps::Row::get($_[0], "' . quotemeta($field) . '")';
}

# "where" command. Filters/selects the rows.
# Options:
# istrue - a Perl expression, the condition for the rows to pass through.
#   The particularly dangerous constructions are not allowed in the
#   expression, including the loops and the general function calls.
#   The fields of the row are referred to as $%field, these references
#   get translated before the expression is compiled.
sub _tqlWhere # ($ctx, @args)
{
	my $ctx = shift;
	die "The where command may not be used at the start of a pipeline.\n" 
		unless (defined($ctx->{prev}));
	my $opts = {};
	&Triceps::Opt::parse("where", $opts, {
		istrue => [ undef, \&Triceps::Opt::ck_mandatory ],
	}, @_);

	# Here only the keys (field names) will be important, the values
	# (field types) will be ignored.
	my $rt = $ctx->{prev}->getRowType();
	my %def = $rt->getdef();

	my $expr = bunescape($opts->{istrue});
	$expr =~ s/\$\%(\w+)/&replaceFieldRef(\%def, $1)/ge;

	my $safe = new Safe; 
	# This allows for the exploits that run the process out of memory,
	# but the danger is in the highly useful functions, so better take this risk.
	$safe->permit(qw(:base_core :base_mem :base_math sprintf));
	::_Triceps_X_Tql_share_safe_rowget($safe);

	my $compiled = $safe->reval("sub { $expr }", 1);
	die "$@" if($@);

	my $unit = $ctx->{u};
	my $lab = $unit->makeDummyLabel($rt, "lb" . $ctx->{id} . "where");
	my $labin = $unit->makeLabel($rt, "lb" . $ctx->{id} . "where.in", undef, sub {
		if (&$compiled($_[1]->getRow())) {
			$unit->call($lab->adopt($_[1]));
		}
	});
	$ctx->{prev}->chain($labin);
	$ctx->{next} = $lab;
}

our %tqlDispatch = (
	read => \&_tqlRead,
	project => \&_tqlProject,
	print => \&_tqlPrint,
	join => \&_tqlJoin,
	where => \&_tqlWhere,
);

# Print an error for the SimpleServer.
# Arguments as described in compileQuery option subError.
sub simpleServerError # ($id, $q, $msg, $error_code, $error_val)
{
	my ($id, $q, $msg, $error_code, $error_val) = @_;
	chomp $msg;
	$msg =~ s/\n/\\n/g; # no real newlines in the output
	$msg =~ s/,/;/g; # no confusing commas in the output
	&Triceps::X::SimpleServer::outCurBuf("+ERROR,OP_INSERT,$q: $msg\n");
}

# Perform a query in the context of a SimpleServer.
# The $argline is the full line received by the server and forwarded here;
# it still includes the query command on it.
# May be used only after $self is initialized.
sub query # ($self, $argline)
{
	my $myname = "Triceps::X::Tql::query";

	my $self = shift;
	my $argline = shift;

	confess "$myname: may be used only on an initialized object"
		unless ($self->{initialized});

	$argline =~ s/^([^,]*)(,|$)//; # skip the name of the label
	my $q = $1; # the name of the query itself

	#&Triceps::X::SimpleServer::outCurBuf("+DEBUGquery: $argline\n");

	my $ctx = compileQuery(
		qname => $q,
		text => $argline,
		subError => \&simpleServerError,
		tables => $self->{dispatch},
		fretDumps => $self->{fret},
	);
	if ($ctx) { # otherwise the error is already reported
		if (! eval {
			# Run the pipeline
			foreach my $code (@{$ctx->{actions}}) {
				&$code;
			}

			1; # means that everything went OK
		}) {
			&simpleServerError('', $q, "query run error: $@", '', '');
		}
	}
}

# The common query compilation for the single-threaded and multi-threaded versions.
#
# The options are:
#
# qid => $id
# (optional) The query id that will be used to report any service information
# such as errors, end of dump portion and such.
# Default: ''.
#
# qname => $name
# The query name that will be used as a label name for all the
# produced data, and for the service information too.
#
# nxprefix => $name
# (optional) Prefix for the created unit name.
# Default: ''.
#
# text => $query_text
# Text of the query, in the braced format.
#
# subError => \&error($id, $qname, $msg, $error_code, $error_val)
# The function that will handle the error reporting. The args are:
#   $id and $qname as received in the options
#   $msg - the full human-readable message
#   $error_code - the string identifying the error
#   $error_val - the particular value that caused the error
#
# tables => { $name => $table, ... }
# The tables list for the single-threaded version.
# Not used with the multithreaded version.
#
# fretDumps => $fnReturn
# The FnReturn object for dumps in the single-threaded version.
# Not used with the multithreaded version.
#
# faOut => $facet
# The facet used to send the data to the Tql thread.
# Not used with the single-threaded version.
#
# faRqDump => $facet
# The facet used to send the table dump requests back to the app core.
# Not used with the single-threaded version.
#
# subPrint => \&print($text)
# The function that prints the text back to the socket.
# Not used with the single-threaded version.
#
# @return - undef on error, the compiled context object on success
#           (see the definition of its contents inside the function)
sub compileQuery # (@opts)
{
	my $myname = "Triceps::X::Tql::compileQuery";
	my $opts = {};
	&Triceps::Opt::parse("chatSockWriteT", $opts, {
		qid => [ '', undef ],
		qname => [ undef, \&Triceps::Opt::ck_mandatory ],
		nxprefix => [ '', undef ],
		text => [ undef, \&Triceps::Opt::ck_mandatory ],
		subError => [ undef, sub { &Triceps::Opt::ck_mandatory; &Triceps::Opt::ck_ref(@_, "CODE"); } ],
		tables => [ undef, sub { &Triceps::Opt::ck_ref(@_, "HASH", "Triceps::Table"); } ],
		fretDumps => [ undef, sub { &Triceps::Opt::ck_ref(@_, "Triceps::FnReturn"); } ],
		faOut => [ undef, sub { &Triceps::Opt::ck_ref(@_, "Triceps::Facet"); } ],
		faRqDump => [ undef, sub { &Triceps::Opt::ck_ref(@_, "Triceps::Facet"); } ],
		subPrint => [ undef, sub { &Triceps::Opt::ck_ref(@_, "CODE"); } ],
	}, @_);

	# XXX check the mutually exclusive options

	my $q = $opts->{qname}; # the name of the query itself

	my @cmds = split_braced($opts->{text});
	if ($opts->{text} ne '') {
		&{$opts->{subError}}($opts->{qid}, $q, "mismatched braces in the trailing " . $opts->{text},
			'query_syntax', $opts->{text});
		return undef;
	}

	# The context for the commands to build up an execution of a query.
	# Unlike $self, the context is created afresh for every query.
	my $ctx = {};
	$ctx->{qid} = $opts->{qid};
	$ctx->{qname} = $opts->{qname};

	$ctx->{tables} = $opts->{tables};
	$ctx->{fretDumps} = $opts->{fretDumps};
	$ctx->{actions} = []; # code that will run the pipeline

	$ctx->{faOut} = $opts->{faOut};
	$ctx->{faRqDump} = $opts->{faRqDump};
	$ctx->{subPrint} = $opts->{subPrint};
	$ctx->{requests} = []; # dump and subscribe requests that will run the pipeline
	$ctx->{copyTables} = []; # the tables created in this query
		# (have to keep references to the tables or they will disappear)

	# The query will be built in a separate unit
	$ctx->{u} = Triceps::Unit->new($opts->{nxprefix} . "${q}.unit");
	$ctx->{prev} = undef; # will contain the output of the previous command in the pipeline
	$ctx->{id} = 0; # a unique id for auto-generated objects
	# deletion of the context will cause the unit in it to clean
	$ctx->{cleaner} = $ctx->{u}->makeClearingTrigger();

	if (! eval {
		foreach my $cmd (@cmds) {
			my @args = split_braced($cmd);
			my $argv0 = bunescape(shift @args);
			# The rest of @args do not get unquoted here!
			die "No such TQL command '$argv0'\n" unless exists $tqlDispatch{$argv0};
			# XXX do something better with the errors, show the failing command...
			$ctx->{id}++;
			&{$tqlDispatch{$argv0}}($ctx, @args);
			# Each command must set its result label (even if an undef) into
			# $ctx->{next}.
			die "Internal error in the command $argv0: missing result definition\n"
				unless (exists $ctx->{next});
			$ctx->{prev} = $ctx->{next};
			delete $ctx->{next};
		}
		if (defined $ctx->{prev}) {
			# implicitly print the result of the pipeline, no options
			&{$tqlDispatch{"print"}}($ctx);
		}

		1; # means that everything went OK
	}) {
		&{$opts->{subError}}($opts->{qid}, $q, "query error: $@", 'bad_query', '');
		return undef;
	}

	return $ctx;
}

# Listener for connections.
# Extra options:
#
# socketName => $name
# The listening socket name in the App.
#
# mainTriead => $name
# Name of the main thread that runs the model and exports the nexuses.
#
# nxprefix => $name
# The prefix for the nexus names that are used for communication between the
# core of the application and the client threads. Also determines the
# prefix for the Tql thread names.
#
sub listenerT
{
	my $opts = {};
	&Triceps::Opt::parse("listenerT", $opts, {@Triceps::Triead::opts,
		socketName => [ undef, \&Triceps::Opt::ck_mandatory ],
		mainTriead => [ undef, \&Triceps::Opt::ck_mandatory ],
		nxprefix => [ undef, \&Triceps::Opt::ck_mandatory ],
	}, @_);
	undef @_;
	my $owner = $opts->{owner};

	my ($tsock, $sock) = $owner->trackGetFile($opts->{socketName}, "+<");

	$owner->readyReady();

	Triceps::X::ThreadedServer::listen(
		owner => $owner,
		socket => $sock,
		prefix => $opts->{nxprefix},
		handler => \&readT,
		mainTriead => $opts->{mainTriead},
		nxprefix => $opts->{nxprefix},
	);
}

# The socket reading side of the client connection.
# Parses the data and commands from the client and forwards it through.
#
# Extra options:
#
# socketName => $name
# The newly connected client socket name in the App.
#
# mainTriead => $name
# Name of the main thread that runs the model and exports the nexuses.
#
# nxprefix => $name
# The prefix for the nexus names that are used for communication between the
# core of the application and the client threads. Also determines the
# prefix for the Tql thread names.
#
# The format of incoming user data is: generally CSV,
# either a data line or command line. The data lines are:
#
# d,label,opcode,fields...
#
# The "d" is a literal character telling that it's a data entry (essentially
# like a special command "d"). The field splitting is dumb at the moment and
# doesn't allow commas inside the data.
#
# The command lines are:
#   
#   command,id,args...
#
# id is the identifier of the command, that will be sent back in the response.
# The commands are:
#   d - a data line, see above, has no id
#   exit - drain and close this connection
#   shutdown - drain and shut down the whole server
#   confirm - will send back a confirmation when the data up to this point
#     has been processed in the core logic, no arguments
#   drain - will send back a confirmation when the data up to this point
#     has been fully processed and drained
#   subscribe - subscribe to a label or table, just gets the new updates,
#     without the initial contents; args: label or table name
#   dump - dump a table, will send the confirmation after the end of data;
#     args: table name
#   dumpsub - dump a table and then continue with subscription to updates, 
#     will send the confirmation after the end of dumped data;
#     args: table name
#   query - do an one-time query of the table contents, will send confirmation
#     after the end of data; query text is braced;
#     args: name of the query, text of the query
#     (NOT SUPPORTED YET)
#   querysub - do an one-time query of the table contents, followed by the
#     subscription to running updates, will send confirmation
#     after the end of data; query text is braced;
#     args: name of the query, text of the query
sub readT
{
	my $opts = {};
	&Triceps::Opt::parse("chatSockReadT", $opts, {@Triceps::Triead::opts,
		socketName => [ undef, \&Triceps::Opt::ck_mandatory ],
		mainTriead => [ undef, \&Triceps::Opt::ck_mandatory ],
		nxprefix => [ undef, \&Triceps::Opt::ck_mandatory ],
	}, @_);
	undef @_; # avoids a leak in threads module
	my $owner = $opts->{owner};
	my $app = $owner->app();
	my $unit = $owner->unit();
	my $tname = $opts->{thread};
	my $fragment = $opts->{fragment}; # this is the client name

	# only dup the socket, the writer thread will consume it
	my ($tsock, $sock) = $owner->trackDupFile($opts->{socketName}, "<");

	# messages will be sent here
	my $faIn = $owner->importNexus(
		from => $opts->{mainTriead} . "/" . $opts->{nxprefix} . "in",
		import => "writer",
	);

	Triceps::Triead::start(
		app => $opts->{app},
		thread => "$tname.rd",
		fragment => $opts->{fragment},
		main => \&writeT,
		socketName => $opts->{socketName},
		mainTriead => $opts->{mainTriead},
		nxprefix => $opts->{nxprefix},
	);

	$owner->readyReady();

	my $lbCtl = $faIn->getLabel("control");

	my %passcmd = ( # these commands are treated all the same, by passing to the writeT
		confirm => 1,
		subscribe => 1,
		dump => 1,
		dumpsub => 1,
		query => 1,
		querysub => 1,
	);

	while(<$sock>) {
		s/[\r\n]+$//;
		my @data = split(/,/, $_);
		if ($data[0] eq "exit") {
			last; # a special case, handle in this thread
		} elsif ($data[0] eq "shutdown") {
			my $drain = Triceps::AutoDrain::makeExclusive($owner);
			# the writers will accept the shutdown command from any client
			$unit->makeHashCall($lbCtl, "OP_INSERT", client => $fragment, cmd => "shutdown");
			$owner->flushWriters();
			$drain->wait();
			eval {$app->shutdown();};
			last;
		} elsif ($data[0] eq "d") {
			shift @data;
			my $dest = shift @data;
			my $lb = eval {
				$faIn->getLabel("in." . $dest);
			};
			if (!defined $lb) {
				$unit->makeHashCall($lbCtl, "OP_INSERT", client => $fragment, cmd => "error",
					arg1 => "Bad label in command 'd': '$dest'", arg2 => "bad_dest",
					arg3 => $dest);
			} else {
				if (!eval {
					$unit->makeArrayCall($lb, @data);
				}) {
					chomp $@;
					$@ =~ s/\n/\\n/g; # no real newlines in the output
					$@ =~ s/,/;/g; # no confusing commas in the output
					$unit->makeHashCall($lbCtl, "OP_INSERT", client => $fragment, cmd => "error",
						arg1 => "Bad data in command 'd' $dest: $@", arg2 => "bad_data",
						arg3 => join(',', @data));
				}
			}
		} elsif (exists $passcmd{$data[0]}) {
			my @data = split(/,/, $_, 4); # the 4th argument will be the query, left unsplit
			$unit->makeHashCall($lbCtl, "OP_INSERT", client => $fragment, cmd => $data[0],
				id => $data[1], arg1 => $data[2], arg2 => $data[3]);
		} elsif ($data[0] eq "drain") {
			Triceps::AutoDrain::makeShared($owner);
			$unit->makeHashCall($lbCtl, "OP_INSERT", client => $fragment, cmd => "drain", id => $data[1]);
		} else {
			$unit->makeHashCall($lbCtl, "OP_INSERT", client => $fragment, cmd => "error", id => $data[1],
				arg1 => "Bad command: '" . $data[0] . "'", arg2 => "bad_command",
				arg3 => $data[0]);
		}
		$owner->flushWriters();
	}

	{
		# let the data drain through
		my $drain = Triceps::AutoDrain::makeExclusive($owner);

		# send the notification - can do it because the drain is excluding itself
		$unit->makeHashCall($lbCtl, "OP_INSERT", client => $fragment, cmd => "exit");
		$owner->flushWriters();

		$drain->wait(); # wait for the notification to drain

		$app->shutdownFragment($opts->{fragment});
	}

	$tsock->close(); # not strictly necessary
}

# The actual execution of the commands and sending of the results.
#
# Extra options:
#
# socketName => $name
# The newly connected client socket name in the App.
#
# mainTriead => $name
# Name of the main thread that runs the model and exports the nexuses.
#
# nxprefix => $name
# The prefix for the nexus names that are used for communication between the
# core of the application and the client threads. Also determines the
# prefix for the Tql thread names.
#
# Besides the "real" user-initiated commands, the following commands are recognized:
# 
# exit - send a notification of the client exit
# shutdown - send a notification of the server shutdown
# error - send a notification of an error in the user data
#
# The output is either a data line or command confirmation line. The data lines are:
#
# d,label,opcode,fields...
# t,label,tokenized string...
#
# The tokenized format may be used to produce the result of the queries.
#
# The command confirmation lines are:
#
# command,id,[label]
# startdump,id,label
# error,id,user_text,type,value....
#
# The command confirmation name is generally the same as command name. Whether the
# label will be present in it, depends on whether the label is present in the 
# original command.
#
# The startdump confirmation is sent before the requested dump starts.
#
# The error report may have the real or empty id, depending on whether it was
# present in the original command. The error report contains the user-readable
# text, the error type, and the value that triggered the error. The value
# may be multi-field. The user-readable text is guaranteed to have any commas
# in it replaced with ';' and any line feeds with '\n'.
#
sub writeT
{
	my $opts = {};
	&Triceps::Opt::parse("chatSockWriteT", $opts, {@Triceps::Triead::opts,
		socketName => [ undef, \&Triceps::Opt::ck_mandatory ],
		mainTriead => [ undef, \&Triceps::Opt::ck_mandatory ],
		nxprefix => [ undef, \&Triceps::Opt::ck_mandatory ],
	}, @_);
	undef @_;
	my $owner = $opts->{owner};
	my $app = $owner->app();
	my $unit = $owner->unit();
	my $fragment = $opts->{fragment}; # this is the client name
	my @labels;

	my ($tsock, $sock) = $owner->trackGetFile($opts->{socketName}, ">");

	# incoming data and control commands
	my $faOut = $owner->importNexus(
		from => $opts->{mainTriead} . "/" . $opts->{nxprefix} . "out",
		import => "reader",
	);

	# the table dump requests to the core of the App
	my $faRqDump = $owner->importNexus(
		from => $opts->{mainTriead} . "/" . $opts->{nxprefix} . "rqdump",
		import => "writer",
	);

	# the commands that get handled by passing them through
	my %passcmds = (
		exit => 1,
		shutdown => 1,
		confirm => 1,
		drain => 1,
		error => 1,
	);

	my %subscr; # the currently active subscriptions, maps to constant 1
	my %dumps; # the currently active dumps, maps to command info
	my %queued_dumps; # the dump requests that arrive before the previous dump
		# is completed, they are queued. The entries are arrays of command info.
	my %queries; # query contexts, keyed by id
	my $fretOut = $faOut->getFnReturn();

	# to avoid filtering every dump row, its handling is done in an FnBinding
	# that's get pushed at the start of the dump and popped at the end of it
	my $subDump = sub { # ($label, $rowop, $dumpname)
		printOrShut($app, $fragment, $sock, 
			"d,", $_[2], ",", Triceps::opcodeString($_[1]->getOpcode()), ",",
			join(",", $_[1]->getRow()->toArray()), "\n");
	};

	# The subscription logic that is shared between "subscribe" and "dumpsub".
	my $subscribe = sub { # ($cmd, $id, $lbname)
		my ($cmd, $id, $lbname) = @_;

		if (!exists $subscr{$lbname}) {
			my $lbsrc = eval {
				$faOut->getLabel("t.out.$lbname");
			};
			if (!$lbsrc) {
				printOrShut($app, $fragment, $sock,
					"error,$id,Bad label for subscribe: '$lbname',bad_label,", $lbname, "\n");
				return;
			}
			$lbsrc->makeChained("lbOut.$lbname", undef, sub {
				printOrShut($app, $fragment, $sock, 
					"d,", $_[2], ",", Triceps::opcodeString($_[1]->getOpcode()), ",",
					join(",", $_[1]->getRow()->toArray()), "\n");
			}, $lbname);
			$subscr{$lbname} = 1;
		}
		printOrShut($app, $fragment, $sock, join(',', $cmd, $id, $lbname), "\n");
	};

	# The requests from a query context get sent one by one, and
	# after one is done, the next is sent until they all are done.
	my $runNextRequest = sub { # ($ctx)
		my $ctx = shift;
		my $requests = $ctx->{requests};
		undef $ctx->{curRequest}; # clear the info of the previous request
		my $r = shift @$requests;
		if (!defined $r) {
			# all done, now just need to pump the data through
			printOrShut($app, $fragment, $sock,
				"querysub,$ctx->{qid},$ctx->{qname}\n");
			return;
		}
		$ctx->{curRequest} = $r; # remember until completed
		my $cmd = $$r[0];
		if ($cmd eq "qdumpsub") {
			# qdumpsub:
			#   * label where to send the dump request to
			#   * source output label, from which a subscription will be set up
			#     at the end of the dump
			#   * target label in the query that will be tied to the source label
			#   * binding to be used during the dump, which also directs the data
			#     to the same target label
			my $lbrq = $$r[1];
			# this code very specifically ignores %dump, doing its requests
			# independently for each query, and showing off another way to
			# do things
			# print "DBG next request {" . $ctx->{qname} . "} qdumpsub " . $lbrq->getName() . "\n";
			$unit->makeHashCall($lbrq, "OP_INSERT", 
				client => $fragment, id => $ctx->{qid}, name => $ctx->{qname}, cmd => $cmd);
		} else {
			printOrShut($app, $fragment, $sock,
				"error,", $ctx->{qid}, ",Internal error: unknown request '$cmd',internal,", $cmd, "\n");
			$ctx->{requests} = [];
			undef $ctx->{curRequest};
			# and this will leave the query partially initialized,
			# but it should never happen
			return;
		}
	};

	undef @labels;
	foreach my $lbn ($fretOut->getLabelNames()) {
		next unless ($lbn =~ /^t\.dump\.(.*)$/);
		my $name = $1;
		my $lb = $unit->makeLabel(
			$fretOut->getLabel($lbn)->getRowType(), "dump.$name",
			undef, $subDump, $name);
		push @labels, $lbn, $lb;
	}
	my $bindDump = Triceps::FnBinding->new(
		on => $fretOut,
		name => "bindDump",
		labels => [ @labels ],
	);

	$faOut->getLabel("control")->makeChained("lbCtl", undef, sub {
		my $row = $_[1]->getRow();
		my ($client, $cmd, $id, @args) = $row->toArray();

		if ($client eq $fragment || $cmd eq "shutdown") {
			if (exists $passcmds{$cmd}) {
				no warnings; # shut up the warnings about undefs in join()
				printOrShut($app, $fragment, $sock, join(',', $cmd, $id, @args), "\n");
			} elsif ($cmd eq "subscribe") {
				&$subscribe($cmd, $id, $args[0]);
			} elsif ($cmd eq "dump" || $cmd eq "dumpsub") {
				my $info = [ $cmd, $id, $args[0] ];
				if (exists $dumps{$args[0]}) {
					# a dump on this table is already in progress, queue it up
					push @{$queued_dumps{$args[0]}}, $info;
					return;
				}
				my $lbrq = eval {
					$faRqDump->getLabel("t.rqdump." . $args[0]);
				};
				if (!$lbrq) {
					printOrShut($app, $fragment, $sock,
						"error,$id,Bad label for dump: '", $args[0], "',bad_label,", $args[0], "\n");
					return;
				}
				$dumps{$args[0]} = $info;
				$unit->makeHashCall($lbrq, "OP_INSERT", 
					client => $fragment, id => $id, name => $args[0], cmd => $cmd);
			} elsif ($cmd eq "querysub") {
				if ($id eq "" || exists $queries{$id}) {
					printOrShut($app, $fragment, $sock,
						"error,$id,Duplicate id '$id': query ids must be unique,bad_id,$id\n");
					next;
				}
				my $ctx = compileQuery(
					qid => $id,
					qname => $args[0],
					text => $args[1],
					subError => sub {
						chomp $_[2];
						$_[2] =~ s/\n/\\n/g; # no real newlines in the output
						$_[2] =~ s/,/;/g; # no confusing commas in the output
						printOrShut($app, $fragment, $sock, "error,", join(',', @_), "\n");
					},
					faOut => $faOut,
					faRqDump => $faRqDump,
					subPrint => sub {
						printOrShut($app, $fragment, $sock, @_);
					},
				);
				if ($ctx) { # otherwise the error is already reported
					$queries{$id} = $ctx;
					&$runNextRequest($ctx);
				}
			} else {
				printOrShut($app, $fragment, $sock,
					"error,$id,Bad command: '$cmd',bad_command,$cmd\n");
			}
		}
	});

	$faOut->getLabel("beginDump")->makeChained("lbBeginDump", undef, sub {
		my $row = $_[1]->getRow();
		my ($client, $id, $name, $cmd) = $row->toArray();
		return unless ($client eq $fragment);
		if ($cmd eq "qdumpsub") {
			return unless(exists $queries{$id});
			my $ctx = $queries{$id};
			$fretOut->push($ctx->{curRequest}[4]); # the binding for the dump
		} else {
			return unless (exists $dumps{$name});
			printOrShut($app, $fragment, $sock,
				"startdump,$id,$name\n");
			$fretOut->push($bindDump);
		}
	});
	$faOut->getLabel("endDump")->makeChained("lbEndDump", undef, sub {
		my $row = $_[1]->getRow();
		my ($client, $id, $name, $cmd) = $row->toArray();
		return unless ($client eq $fragment);

		if ($cmd eq "qdumpsub") {
			return unless(exists $queries{$id});
			my $ctx = $queries{$id};
			$fretOut->pop($ctx->{curRequest}[4]); # the binding for the dump
			# and chain together all the following updates
			$ctx->{curRequest}[2]->makeChained(
				"qsub$id." . $ctx->{curRequest}[3]->getName(), undef,
				sub {
					# a cross-unit call
					$_[2]->call($_[3]->adopt($_[1]));
				},
				$ctx->{u}, $ctx->{curRequest}[3]
			);

			&$runNextRequest($ctx);
		} else {
			return unless (exists $dumps{$name});
			$fretOut->pop($bindDump);
			my $info = $dumps{$name};
			if ($cmd eq "dumpsub") {
				&$subscribe(@$info);
			} else {
				printOrShut($app, $fragment, $sock, join(',', @$info), "\n");
			}
			delete $dumps{$name};

			# now, there might be more requests queued up, follow up on the next one
			$info = shift @{$queued_dumps{$name}};
			if (defined $info) {
				# presumably, this already worked before, so no need to eval
				my $lbrq = $faRqDump->getLabel("t.rqdump." . $name);
				$dumps{$name} = $info;
				$unit->makeHashCall($lbrq, "OP_INSERT", 
					client => $fragment, id => $$info[1], name => $$info[2], cmd => $$info[0]);
			}
		}
	});

	$owner->readyReady();

	# the first prompt
	printOrShut($app, $fragment, $sock, "ready\n");

	$owner->mainLoop();

	$tsock->close(); # not strictly necessary
}

1;
