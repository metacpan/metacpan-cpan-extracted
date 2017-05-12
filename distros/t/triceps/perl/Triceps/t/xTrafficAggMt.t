#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# An example of traffic accounting aggregated to multiple levels,
# as a multithreaded pipeline.

#########################

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 3 };
use Triceps;
use Triceps::X::TestFeed qw(:all);
use Carp;
ok(1); # If we made it this far, we're ok.

use strict;

#########################
# This version of aggregation keeps updating the hourly and daily stats
# as the data comes in, on every packet (unlike xTrafficAgg.t that does that
# only at the end of the hour or day).
# It shows how each level can be split into a separate thread, to pipeline the
# computational load.

package Traffic1;

use Carp;
use Triceps::X::TestFeed qw(:all);

# Read the data and control commands from STDIN for the pipeline.
# The output is sent to the nexus "data".
# Also responsible for defining the control labels in the same nexus:
#   packet - the data
#   print - strings for printing at the end of pipeline
#   dumprq - dump requests to the elements of the pipeline
# Options inherited from Triead::start.
sub readerT # (@opts)
{
	my $opts = {};
	Triceps::Opt::parse("traffic main", $opts, {@Triceps::Triead::opts}, @_);
	my $owner = $opts->{owner};
	my $unit = $owner->unit();

	my $rtPacket = Triceps::RowType->new(
		time => "int64", # packet's timestamp, microseconds
		local_ip => "string", # string to make easier to read
		remote_ip => "string", # string to make easier to read
		local_port => "int32", 
		remote_port => "int32",
		bytes => "int32", # size of the packet
	);

	my $rtPrint = Triceps::RowType->new(
		text => "string", # the text to print (including \n)
	);

	my $rtDumprq = Triceps::RowType->new(
		what => "string", # identifies, what to dump
	);

	my $faOut = $owner->makeNexus(
		name => "data",
		labels => [
			packet => $rtPacket,
			print => $rtPrint,
			dumprq => $rtDumprq,
		],
		import => "writer",
	);

	my $lbPacket = $faOut->getLabel("packet");
	my $lbPrint = $faOut->getLabel("print");
	my $lbDumprq = $faOut->getLabel("dumprq");

	$owner->readyReady();

	while(&readLine) {
		chomp;
		# print the input line, as a debugging exercise
		$unit->makeArrayCall($lbPrint, "OP_INSERT", "> $_\n");

		my @data = split(/,/); # starts with a command, then string opcode
		my $type = shift @data;
		if ($type eq "new") {
			$unit->makeArrayCall($lbPacket, @data);
		} elsif ($type eq "dump") {
			$unit->makeArrayCall($lbDumprq, "OP_INSERT", $data[0]);
		} else {
			$unit->makeArrayCall($lbPrint, "OP_INSERT", "Unknown command '$type'\n");
		}
		$owner->flushWriters();
	}

	{
		# drain the pipeline before shutting down
		my $ad = Triceps::AutoDrain::makeShared($owner);
		$owner->app()->shutdown();
	}
}

# compute an hour-rounded timestamp (in microseconds)
sub hourStamp # (time)
{
	return $_[0]  - ($_[0] % (1000*1000*3600));
}

# Read and pass through all the inputs, also:
#   * keep the raw data
#   * aggregate the hourly stats from it,
#   * send the aggregated data
#   * send the dump of the kept raw data on request
# The output is sent to the nexus "data".
# The added labels in the nexus:
#   hourly - the aggregated hourly data
#
# Options are inherited from Triead::start, plus:
#   from => "thread/nexus"
#   The input nexus name.
sub rawToHourlyT # (@opts)
{
	my $opts = {};
	Triceps::Opt::parse("traffic main", $opts, {
		@Triceps::Triead::opts,
		from => [ undef, \&Triceps::Opt::ck_mandatory ],
	}, @_);
	my $owner = $opts->{owner};
	my $unit = $owner->unit();

	# The current hour stamp that keeps being updated;
	# any aggregated data will be propagated when it is in the
	# current hour (to avoid the propagation of the aggregator clearing).
	my $currentHour;

	my $faIn = $owner->importNexus(
		from => $opts->{from},
		as => "input",
		import => "reader",
	);

	# the full stats for the recent time
	my $ttPackets = Triceps::TableType->new($faIn->getLabel("packet")->getRowType())
		->addSubIndex("byHour", 
			Triceps::IndexType->newPerlSorted("byHour", undef, sub {
				return &hourStamp($_[0]->get("time")) <=> &hourStamp($_[1]->get("time"));
			})
			->addSubIndex("byIP", 
				Triceps::IndexType->newHashed(key => [ "local_ip", "remote_ip" ])
				->addSubIndex("group",
					Triceps::IndexType->newFifo()
				)
			)
		)
	;

	# type for a periodic summary, used for hourly, daily etc. updates
	my $rtSummary;

	Triceps::SimpleAggregator::make(
		tabType => $ttPackets,
		name => "hourly",
		idxPath => [ "byHour", "byIP", "group" ],
		result => [
			# time period's (here hour's) start timestamp, microseconds
			time => "int64", "last", sub {&hourStamp($_[0]->get("time"));},
			local_ip => "string", "last", sub {$_[0]->get("local_ip");},
			remote_ip => "string", "last", sub {$_[0]->get("remote_ip");},
			# bytes sent in a time period, here an hour
			bytes => "int64", "sum", sub {$_[0]->get("bytes");},
		],
		saveRowTypeTo => \$rtSummary,
	);

	$ttPackets->initialize();
	my $tPackets = $unit->makeTable($ttPackets, "tPackets");

	# Filter the aggregator output to match the current hour.
	my $lbHourlyFiltered = $unit->makeDummyLabel($rtSummary, "hourlyFiltered");
	$tPackets->getAggregatorLabel("hourly")->makeChained("hourlyFilter", undef, sub {
		if ($_[1]->getRow()->get("time") == $currentHour) {
			$unit->call($lbHourlyFiltered->adopt($_[1]));
		}
	});

	# update the notion of the current hour before the table
	$faIn->getLabel("packet")->makeChained("processPackets", undef, sub {
		my $row = $_[1]->getRow();
		$currentHour = &hourStamp($row->get("time"));
		# skip the timestamp updates without data
		if (defined $row->get("bytes")) {
			$unit->call($tPackets->getInputLabel()->adopt($_[1]));
		}
	});

	# The makeNexus default option chainFront => 1 will make
	# sure that the pass-through data propagates first, before the
	# processed data.
	my $faOut = $owner->makeNexus(
		name => "data",
		labels => [
			$faIn->getFnReturn()->getLabelHash(),
			hourly => $lbHourlyFiltered,
		],
		import => "writer",
	);

	my $lbPrint = $faOut->getLabel("print");

	# the dump request processing
	$tPackets->getDumpLabel()->makeChained("printDump", undef, sub {
		$unit->makeArrayCall($lbPrint, "OP_INSERT", $_[1]->getRow()->printP() . "\n");
	});
	$faIn->getLabel("dumprq")->makeChained("dump", undef, sub {
		if ($_[1]->getRow()->get("what") eq "packets") {
			$tPackets->dumpAll();
		}
	});

	$owner->readyReady();
	$owner->mainLoop(); # all driven by the reader
}

# compute a day-rounded timestamp (in microseconds)
sub dayStamp # (time)
{
	# for 32-bit machines, use floating-point to avoid overflow
	return $_[0]  - ($_[0] % (1000*1000*3600*24.));
}

# Read and pass through all the inputs, also:
#   * keep the hourly data
#   * aggregate the daily stats from it,
#   * send the aggregated data
#   * send the dump of the kept hourly data on request
# The output is sent to the nexus "data".
# The added labels in the nexus:
#   daily - the aggregated daily data
#
# Options are inherited from Triead::start, plus:
#   from => "thread/nexus"
#   The input nexus name.
sub hourlyToDailyT # (@opts)
{
	my $opts = {};
	Triceps::Opt::parse("traffic main", $opts, {
		@Triceps::Triead::opts,
		from => [ undef, \&Triceps::Opt::ck_mandatory ],
	}, @_);
	my $owner = $opts->{owner};
	my $unit = $owner->unit();

	# The current day stamp that keeps being updated;
	# any aggregated data will be propagated when it is in the
	# current day (to avoid the propagation of the aggregator clearing).
	my $currentDay;

	my $faIn = $owner->importNexus(
		from => $opts->{from},
		as => "input",
		import => "reader",
	);

	# the hourly stats for the recent time
	my $ttHourly = Triceps::TableType->new($faIn->getLabel("hourly")->getRowType())
		->addSubIndex("byDay", 
			Triceps::IndexType->newPerlSorted("byDay", undef, sub {
				return &dayStamp($_[0]->get("time")) <=> &dayStamp($_[1]->get("time"));
			})
			->addSubIndex("byIP", 
				Triceps::IndexType->newHashed(key => [ "local_ip", "remote_ip" ])
				->addSubIndex("group",
					Triceps::IndexType->newFifo()
				)
			)
		)
	;

	# type for a periodic summary, used for hourly, daily etc. updates
	my $rtSummary;

	Triceps::SimpleAggregator::make(
		tabType => $ttHourly,
		name => "daily",
		idxPath => [ "byDay", "byIP", "group" ],
		result => [
			# time period's (here day's) start timestamp, microseconds
			time => "int64", "last", sub {&dayStamp($_[0]->get("time"));},
			local_ip => "string", "last", sub {$_[0]->get("local_ip");},
			remote_ip => "string", "last", sub {$_[0]->get("remote_ip");},
			# bytes sent in a time period, here an hour
			bytes => "int64", "sum", sub {$_[0]->get("bytes");},
		],
		saveRowTypeTo => \$rtSummary,
	);

	$ttHourly->initialize();
	my $tHourly = $unit->makeTable($ttHourly, "tHourly");

	# Filter the aggregator output to match the current day.
	my $lbDailyFiltered = $unit->makeDummyLabel($rtSummary, "dailyFiltered");
	$tHourly->getAggregatorLabel("daily")->makeChained("dailyFilter", undef, sub {
		if ($_[1]->getRow()->get("time") == $currentDay) {
			$unit->call($lbDailyFiltered->adopt($_[1]));
		}
	});

	# update the notion of the current day from the Packets, because
	# only they would contain the time updates even when no data is coming in
	$faIn->getLabel("packet")->makeChained("processPackets", undef, sub {
		my $row = $_[1]->getRow();
		$currentDay = &dayStamp($row->get("time"));
	});
	# the hourly updates can be chained directly
	$faIn->getLabel("hourly")->chain($tHourly->getInputLabel());

	# The makeNexus default option chainFront => 1 will make
	# sure that the pass-through data propagates first, before the
	# processed data.
	my $faOut = $owner->makeNexus(
		name => "data",
		labels => [
			$faIn->getFnReturn()->getLabelHash(),
			daily => $lbDailyFiltered,
		],
		import => "writer",
	);

	my $lbPrint = $faOut->getLabel("print");

	# the dump request processing
	$tHourly->getDumpLabel()->makeChained("printDump", undef, sub {
		$unit->makeArrayCall($lbPrint, "OP_INSERT", $_[1]->getRow()->printP() . "\n");
	});
	$faIn->getLabel("dumprq")->makeChained("hourly", undef, sub {
		if ($_[1]->getRow()->get("what") eq "hourly") {
			$tHourly->dumpAll();
		}
	});

	$owner->readyReady();
	$owner->mainLoop(); # all driven by the reader
}

# Read and pass through all the inputs, also:
#   * keep the daily data
#   * send the dump of the kept daily data on request
# The output is sent to the nexus "data".
#
# Options are inherited from Triead::start, plus:
#   from => "thread/nexus"
#   The input nexus name.
sub storeDailyT # (@opts)
{
	my $opts = {};
	Triceps::Opt::parse("traffic main", $opts, {
		@Triceps::Triead::opts,
		from => [ undef, \&Triceps::Opt::ck_mandatory ],
	}, @_);
	my $owner = $opts->{owner};
	my $unit = $owner->unit();

	my $faIn = $owner->importNexus(
		from => $opts->{from},
		as => "input",
		import => "reader",
	);

	# the daily stats for the recent time, this time no further aggregation
	my $ttDaily = Triceps::TableType->new($faIn->getLabel("daily")->getRowType())
		->addSubIndex("byDay", 
			Triceps::SimpleOrderedIndex->new(time => "ASC",)
			->addSubIndex("byIP", 
				Triceps::IndexType->newHashed(key => [ "local_ip", "remote_ip" ])
			)
		)
	;

	$ttDaily->initialize();
	my $tDaily = $unit->makeTable($ttDaily, "tDaily");

	# the daily updates can be chained directly
	$faIn->getLabel("daily")->chain($tDaily->getInputLabel());

	# The makeNexus default option chainFront => 1 will make
	# sure that the pass-through data propagates first, before the
	# processed data.
	my $faOut = $owner->makeNexus(
		name => "data",
		labels => [
			$faIn->getFnReturn()->getLabelHash(),
		],
		import => "writer",
	);

	my $lbPrint = $faOut->getLabel("print");

	# the dump request processing
	$tDaily->getDumpLabel()->makeChained("printDump", undef, sub {
		$unit->makeArrayCall($lbPrint, "OP_INSERT", $_[1]->getRow()->printP() . "\n");
	});
	$faIn->getLabel("dumprq")->makeChained("daily", undef, sub {
		if ($_[1]->getRow()->get("what") eq "daily") {
			$tDaily->dumpAll();
		}
	});

	$owner->readyReady();
	$owner->mainLoop(); # all driven by the reader
}

# Create all the other threads and then read the tail of the
# pipeline and print the data from it.
# Options inherited from Triead::start.
sub printT # (@opts)
{
	my $opts = {};
	Triceps::Opt::parse("traffic main", $opts, {@Triceps::Triead::opts}, @_);
	my $owner = $opts->{owner};
	my $unit = $owner->unit();

	Triceps::Triead::start(
		app => $opts->{app},
		thread => "read",
		main => \&readerT,
	);
	Triceps::Triead::start(
		app => $opts->{app},
		thread => "raw_hour",
		main => \&rawToHourlyT,
		from => "read/data",
	);
	Triceps::Triead::start(
		app => $opts->{app},
		thread => "hour_day",
		main => \&hourlyToDailyT,
		from => "raw_hour/data",
	);
	Triceps::Triead::start(
		app => $opts->{app},
		thread => "day",
		main => \&storeDailyT,
		from => "hour_day/data",
	);

	my $faIn = $owner->importNexus(
		from => "day/data",
		as => "input",
		import => "reader",
	);

	$faIn->getLabel("print")->makeChained("print", undef, sub {
		&send($_[1]->getRow()->get("text"));
	});
	for my $tag ("packet", "hourly", "daily") {
		makePrintLabel($tag, $faIn->getLabel($tag));
	}

	$owner->readyReady();
	$owner->mainLoop(); # all driven by the reader
}

sub RUN {

Triceps::Triead::startHere(
	app => "traffic",
	thread => "print",
	main => \&printT,
);

};

package main;

setInputLines(
	"new,OP_INSERT,1330886011000000,1.2.3.4,5.6.7.8,2000,80,100\n",
	"new,OP_INSERT,1330886012000000,1.2.3.4,5.6.7.8,2000,80,50\n",
	"new,OP_INSERT,1330889612000000,1.2.3.4,5.6.7.8,2000,80,150\n",
	"new,OP_INSERT,1330889811000000,1.2.3.4,5.6.7.8,2000,80,300\n",
	"new,OP_INSERT,1330972411000000,1.2.3.5,5.6.7.9,3000,80,200\n",
	"new,OP_INSERT,1331058811000000\n",
	"new,OP_INSERT,1331145211000000\n",
	"dump,packets\n",
	"dump,hourly\n",
	"dump,daily\n",
);
&Traffic1::RUN();
#print &getResultLines();
ok(&getResultLines(), 
'> new,OP_INSERT,1330886011000000,1.2.3.4,5.6.7.8,2000,80,100
input.packet OP_INSERT time="1330886011000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="100" 
input.hourly OP_INSERT time="1330884000000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="100" 
input.daily OP_INSERT time="1330819200000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="100" 
> new,OP_INSERT,1330886012000000,1.2.3.4,5.6.7.8,2000,80,50
input.packet OP_INSERT time="1330886012000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="50" 
input.hourly OP_DELETE time="1330884000000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="100" 
input.daily OP_DELETE time="1330819200000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="100" 
input.hourly OP_INSERT time="1330884000000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="150" 
input.daily OP_INSERT time="1330819200000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="150" 
> new,OP_INSERT,1330889612000000,1.2.3.4,5.6.7.8,2000,80,150
input.packet OP_INSERT time="1330889612000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="150" 
input.hourly OP_INSERT time="1330887600000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="150" 
input.daily OP_DELETE time="1330819200000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="150" 
input.daily OP_INSERT time="1330819200000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="300" 
> new,OP_INSERT,1330889811000000,1.2.3.4,5.6.7.8,2000,80,300
input.packet OP_INSERT time="1330889811000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="300" 
input.hourly OP_DELETE time="1330887600000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="150" 
input.daily OP_DELETE time="1330819200000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="300" 
input.daily OP_INSERT time="1330819200000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="150" 
input.hourly OP_INSERT time="1330887600000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="450" 
input.daily OP_DELETE time="1330819200000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="150" 
input.daily OP_INSERT time="1330819200000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="600" 
> new,OP_INSERT,1330972411000000,1.2.3.5,5.6.7.9,3000,80,200
input.packet OP_INSERT time="1330972411000000" local_ip="1.2.3.5" remote_ip="5.6.7.9" local_port="3000" remote_port="80" bytes="200" 
input.hourly OP_INSERT time="1330970400000000" local_ip="1.2.3.5" remote_ip="5.6.7.9" bytes="200" 
input.daily OP_INSERT time="1330905600000000" local_ip="1.2.3.5" remote_ip="5.6.7.9" bytes="200" 
> new,OP_INSERT,1331058811000000
input.packet OP_INSERT time="1331058811000000" 
> new,OP_INSERT,1331145211000000
input.packet OP_INSERT time="1331145211000000" 
> dump,packets
time="1330886011000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="100" 
time="1330886012000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="50" 
time="1330889612000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="150" 
time="1330889811000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="300" 
time="1330972411000000" local_ip="1.2.3.5" remote_ip="5.6.7.9" local_port="3000" remote_port="80" bytes="200" 
> dump,hourly
time="1330884000000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="150" 
time="1330887600000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="450" 
time="1330970400000000" local_ip="1.2.3.5" remote_ip="5.6.7.9" bytes="200" 
> dump,daily
time="1330819200000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="600" 
time="1330905600000000" local_ip="1.2.3.5" remote_ip="5.6.7.9" bytes="200" 
');

#######################################################################
#
# The other verison that exports the table types through the nexuses.
#
# Here the timestamp is split into the human-readable parts.
#
#########################

package Traffic2;

use Carp;
use Triceps::X::TestFeed qw(:all);

# Read the data and control commands from STDIN for the pipeline.
# The output is sent to the nexus "data".
# Also responsible for defining the control labels in the same nexus:
#   packet - the data
#   user - mapping of the local ip to a local user
#   print - strings for printing at the end of pipeline
#   dumprq - dump requests to the elements of the pipeline
# The defined table types:
#   packets - the packets' key+grouping
# Options inherited from Triead::start.
sub readerT # (@opts)
{
	my $opts = {};
	Triceps::Opt::parse("traffic main", $opts, {@Triceps::Triead::opts}, @_);
	my $owner = $opts->{owner};
	my $unit = $owner->unit();

	my $rtPacket = Triceps::RowType->new(
		# packet's timestamp is here in human-readable parts
		year => "int32",
		month => "int32",
		day => "int32",
		hour => "int32",
		min => "int32",
		sec => "float64", # with fractions
		local_ip => "string", # string to make easier to read
		remote_ip => "string", # string to make easier to read
		local_port => "int32", 
		remote_port => "int32",
		bytes => "int32", # size of the packet
	);

	my $rtUser = Triceps::RowType->new(
		local_ip => "string",
		name => "string",
	);

	# table type that can be used to store the packets
	my $ttPackets = Triceps::TableType->new($rtPacket)
		->addSubIndex("key", 
			Triceps::SimpleOrderedIndex->new(
				year => "ASC",
				month => "ASC",
				day => "ASC",
				hour => "ASC",
				min => "ASC",
				sec => "ASC",
				local_ip => "ASC",
				remote_ip => "ASC",
				local_port => "ASC", 
				remote_port => "ASC",
			)->addSubIndex("group", 
				Triceps::IndexType->newFifo()
			)
		)
	;

	# the table type for users stored by primary key
	my $ttUsers = Triceps::TableType->new($rtUser)
		->addSubIndex("primary", 
			Triceps::IndexType->newHashed(key => [ "local_ip" ])
		)
	;

	# table type that can be used to store the user info

	my $rtPrint = Triceps::RowType->new(
		text => "string", # the text to print (including \n)
	);

	my $rtDumprq = Triceps::RowType->new(
		what => "string", # identifies, what to dump
	);

	my $faOut = $owner->makeNexus(
		name => "data",
		labels => [
			packet => $rtPacket,
			user => $rtUser,
			print => $rtPrint,
			dumprq => $rtDumprq,
		],
		tableTypes => [
			packets => $ttPackets, # could use copyFundamental() too
			users => $ttUsers->copyFundamental(),
		],
		import => "writer",
	);

	my $lbPacket = $faOut->getLabel("packet");
	my $lbUser = $faOut->getLabel("user");
	my $lbPrint = $faOut->getLabel("print");
	my $lbDumprq = $faOut->getLabel("dumprq");

	$owner->readyReady();

	while(&readLine) {
		chomp;
		# print the input line, as a debugging exercise
		$unit->makeArrayCall($lbPrint, "OP_INSERT", "> $_\n");

		my @data = split(/,/); # starts with a command, then string opcode
		my $type = shift @data;
		if ($type eq "packet") {
			$unit->makeArrayCall($lbPacket, @data);
		} elsif ($type eq "user") {
			$unit->makeArrayCall($lbUser, @data);
		} elsif ($type eq "dump") {
			$unit->makeArrayCall($lbDumprq, "OP_INSERT", $data[0]);
		} else {
			$unit->makeArrayCall($lbPrint, "OP_INSERT", "Unknown command '$type'\n");
		}
		$owner->flushWriters();
	}

	{
		# drain the pipeline before shutting down
		my $ad = Triceps::AutoDrain::makeShared($owner);
		$owner->app()->shutdown();
	}
}

# Do a simple-minded hourly aggregation.
# The added labels in the nexus:
#   hourly - the aggregated hourly data
# The packet label is fed through the table.
# The added table type:
#   hourly - the aggregated hourly data
#
# Options are inherited from Triead::start, plus:
#   from => "thread/nexus"
#   The input nexus name.
sub rawToHourlyT # (@opts)
{
	my $opts = {};
	Triceps::Opt::parse("traffic main", $opts, {
		@Triceps::Triead::opts,
		from => [ undef, \&Triceps::Opt::ck_mandatory ],
	}, @_);
	my $owner = $opts->{owner};
	my $unit = $owner->unit();

	my $faIn = $owner->importNexus(
		from => $opts->{from},
		as => "input",
		import => "reader",
	);

	# Table type for the simple aggregation by the hour, that
	# also drops the port numbers (can't just use the imported one
	# because the index "key" is all different).
	my $ttPackets = Triceps::TableType->new($faIn->getLabel("packet")->getRowType())
		->addSubIndex("key", 
			Triceps::SimpleOrderedIndex->new(
				year => "ASC",
				month => "ASC",
				day => "ASC",
				hour => "ASC",
				local_ip => "ASC",
				remote_ip => "ASC",
			)->addSubIndex("group", 
				Triceps::IndexType->newFifo()
			)
		)
	;

	# type for a periodic summary, used for hourly, daily etc. updates
	my $rtSummary;

	Triceps::SimpleAggregator::make(
		tabType => $ttPackets,
		name => "hourly",
		idxPath => [ "key", "group" ],
		result => [
			year => "string", "last", sub {$_[0]->get("year");},
			month => "string", "last", sub {$_[0]->get("month");},
			day => "string", "last", sub {$_[0]->get("day");},
			hour => "string", "last", sub {$_[0]->get("hour");},
			local_ip => "string", "last", sub {$_[0]->get("local_ip");},
			remote_ip => "string", "last", sub {$_[0]->get("remote_ip");},
			# bytes sent in a time period, here an hour
			bytes => "int64", "sum", sub {$_[0]->get("bytes");},
		],
		saveRowTypeTo => \$rtSummary,
	);

	$ttPackets->initialize();
	my $tPackets = $unit->makeTable($ttPackets, "tPackets");

	# Make the table type for keeping the data after aggregation.
	my $ttHourly = Triceps::TableType->new(
			$tPackets->getAggregatorLabel("hourly")->getRowType()
		)
		->addSubIndex("key", 
			Triceps::SimpleOrderedIndex->new(
				year => "ASC",
				month => "ASC",
				day => "ASC",
				hour => "ASC",
				local_ip => "ASC",
				remote_ip => "ASC",
			)
		)
	;

	# It's important to connect the pass-through data first,
	# before chaining anything to the labels of the faIn, to
	# make sure that any requests and raw inputs get through before
	# our reactions to them.
	my $faOut = $owner->makeNexus(
		name => "data",
		labels => [
			# the Opt::drop() call is used creatively to drop some of
			# the pass-though labels, since thir format is the same
			# as for the options
			&Triceps::Opt::drop({ "packet" => undef }, [
				$faIn->getFnReturn()->getLabelHash()
			]),
			# this orders the packet rowops correctly relative to the
			# aggregated rowops
			packet => $tPackets->getOutputLabel(),
			hourly => $tPackets->getAggregatorLabel("hourly"),
		],
		tableTypes => [
			$faIn->impTableTypesHash(), # pass through
			hourly => $ttHourly->copyFundamental(
				# For a demo, copy the index explicitly.
				"NO_FIRST_LEAF", # don't include the whole default indexing
				[ "key" ],
			),
		],
		import => "writer",
	);

	$faIn->getLabel("packet")->chain($tPackets->getInputLabel());

	my $lbPrint = $faOut->getLabel("print");

	# the dump request processing
	$tPackets->getDumpLabel()->makeChained("printDump", undef, sub {
		$unit->makeArrayCall($lbPrint, "OP_INSERT", $_[1]->getRow()->printP() . "\n");
	});
	$faIn->getLabel("dumprq")->makeChained("dump", undef, sub {
		# This is off-by-one stage: the table contains the complete set of
		# the packets that can be dumped, it produces the hourly aggregation
		# that in its turn is not stored in this table but is sent on.
		if ($_[1]->getRow()->get("what") eq "packets") {
			$tPackets->dumpAll();
		}
	});

	$owner->readyReady();
	$owner->mainLoop(); # all driven by the reader
}

# Join together the user with the hourly stats.
sub joinUsersT # (@opts)
{
	my $opts = {};
	Triceps::Opt::parse("traffic main", $opts, {
		@Triceps::Triead::opts,
		from => [ undef, \&Triceps::Opt::ck_mandatory ],
	}, @_);
	my $owner = $opts->{owner};
	my $unit = $owner->unit();

	my $faIn = $owner->importNexus(
		from => $opts->{from},
		as => "input",
		import => "reader",
	);

	my $ttHourly = $faIn->impTableType("hourly")
		->addSubIndex("local_ip", 
			Triceps::IndexType->newHashed(key => [ "local_ip" ])
			->addSubIndex("group",
				Triceps::IndexType->newFifo()
			)
		)
	;
	$ttHourly->initialize();

	my $tHourly = $unit->makeTable($ttHourly, "tHourly");

	my $ttUsers = $faIn->impTableType("users");
	$ttUsers->initialize();

	my $tUsers = $unit->makeTable($ttUsers, "tUsers");

	my $join = Triceps::JoinTwo->new( 
		name => "join",
		leftTable => $tHourly,
		leftIdxPath => ["local_ip"],
		rightTable => $tUsers,
		rightIdxPath => ["primary"],
	);

	# It's important to connect the pass-through data first,
	# before chaining anything to the labels of the faIn, to
	# make sure that any requests and raw inputs get through before
	# our reactions to them.
	my $faOut = $owner->makeNexus(
		name => "data",
		labels => [
			$faIn->getFnReturn()->getLabelHash(),
			hourlyUsers => $join->getOutputLabel(),
		],
		tableTypes => [
			$faIn->impTableTypesHash(), # pass through
		],
		import => "writer",
	);

	$faIn->getLabel("hourly")->chain($tHourly->getInputLabel());
	$faIn->getLabel("user")->chain($tUsers->getInputLabel());

	$owner->readyReady();
	$owner->mainLoop(); # all driven by the reader
}

# Create all the other threads and then read the tail of the
# pipeline and print the data from it.
# Options inherited from Triead::start.
sub printT # (@opts)
{
	my $opts = {};
	Triceps::Opt::parse("traffic main", $opts, {@Triceps::Triead::opts}, @_);
	my $owner = $opts->{owner};
	my $unit = $owner->unit();

	Triceps::Triead::start(
		app => $opts->{app},
		thread => "read",
		main => \&readerT,
	);
	Triceps::Triead::start(
		app => $opts->{app},
		thread => "raw_hour",
		main => \&rawToHourlyT,
		from => "read/data",
	);
	Triceps::Triead::start(
		app => $opts->{app},
		thread => "join_users",
		main => \&joinUsersT,
		from => "raw_hour/data",
	);

	my $faIn = $owner->importNexus(
		from => "join_users/data",
		as => "input",
		import => "reader",
	);

	$faIn->getLabel("print")->makeChained("print", undef, sub {
		&send($_[1]->getRow()->get("text"));
	});
	for my $tag ("packet", "user", "hourly", "hourlyUsers") {
		makePrintLabel($tag, $faIn->getLabel($tag));
	}

	$owner->readyReady();
	$owner->mainLoop(); # all driven by the reader
}

sub RUN {

Triceps::Triead::startHere(
	app => "traffic",
	thread => "print",
	main => \&printT,
);

};

package main;

setInputLines(
	"packet,OP_INSERT,2012,10,30,12,10,11.,1.2.3.4,5.6.7.8,2000,80,100\n",
	"packet,OP_INSERT,2012,10,30,12,10,12.,1.2.3.4,5.6.7.8,2000,80,100\n",
	"user,OP_INSERT,1.2.3.4,abcd\n",
	"packet,OP_INSERT,2012,10,30,12,10,12.,1.2.3.4,5.6.7.8,2000,80,100\n",
	"user,OP_DELETE,1.2.3.4,abcd\n",
	"user,OP_INSERT,1.2.3.4,defg\n",
);
&Traffic2::RUN();
#print &getResultLines();
ok(&getResultLines(), 
'> packet,OP_INSERT,2012,10,30,12,10,11.,1.2.3.4,5.6.7.8,2000,80,100
input.packet OP_INSERT year="2012" month="10" day="30" hour="12" min="10" sec="11" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="100" 
input.hourly OP_INSERT year="2012" month="10" day="30" hour="12" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="100" 
> packet,OP_INSERT,2012,10,30,12,10,12.,1.2.3.4,5.6.7.8,2000,80,100
input.hourly OP_DELETE year="2012" month="10" day="30" hour="12" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="100" 
input.packet OP_INSERT year="2012" month="10" day="30" hour="12" min="10" sec="12" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="100" 
input.hourly OP_INSERT year="2012" month="10" day="30" hour="12" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="200" 
> user,OP_INSERT,1.2.3.4,abcd
input.user OP_INSERT local_ip="1.2.3.4" name="abcd" 
input.hourlyUsers OP_INSERT year="2012" month="10" day="30" hour="12" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="200" name="abcd" 
> packet,OP_INSERT,2012,10,30,12,10,12.,1.2.3.4,5.6.7.8,2000,80,100
input.hourly OP_DELETE year="2012" month="10" day="30" hour="12" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="200" 
input.hourlyUsers OP_DELETE year="2012" month="10" day="30" hour="12" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="200" name="abcd" 
input.packet OP_INSERT year="2012" month="10" day="30" hour="12" min="10" sec="12" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="100" 
input.hourly OP_INSERT year="2012" month="10" day="30" hour="12" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="300" 
input.hourlyUsers OP_INSERT year="2012" month="10" day="30" hour="12" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="300" name="abcd" 
> user,OP_DELETE,1.2.3.4,abcd
input.user OP_DELETE local_ip="1.2.3.4" name="abcd" 
input.hourlyUsers OP_DELETE year="2012" month="10" day="30" hour="12" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="300" name="abcd" 
> user,OP_INSERT,1.2.3.4,defg
input.user OP_INSERT local_ip="1.2.3.4" name="defg" 
input.hourlyUsers OP_INSERT year="2012" month="10" day="30" hour="12" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="300" name="defg" 
');
