#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# An example of traffic accounting aggregated to multiple levels,
# with "freezing" and cleaning of old detailed data.

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

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#########################
# the traffic that gets consolidated by the hour

sub doHourly {

our $uTraffic = Triceps::Unit->new("uTraffic");

# one packet's header
our $rtPacket = Triceps::RowType->new(
	time => "int64", # packet's timestamp, microseconds
	local_ip => "string", # string to make easier to read
	remote_ip => "string", # string to make easier to read
	local_port => "int32", 
	remote_port => "int32",
	bytes => "int32", # size of the packet
);

# an hourly summary
our $rtHourly = Triceps::RowType->new(
	time => "int64", # hour's timestamp, microseconds
	local_ip => "string", # string to make easier to read
	remote_ip => "string", # string to make easier to read
	bytes => "int64", # bytes sent in an hour
);

# compute an hour-rounded timestamp
sub hourStamp # (time)
{
	return $_[0]  - ($_[0] % (1000*1000*3600));
}

# the current hour stamp that keeps being updated
our $currentHour;

# aggregation handler: recalculate the summary for the last hour
sub computeHourly # (table, context, aggop, opcode, rh, state, args...)
{
	my ($table, $context, $aggop, $opcode, $rh, $state, @args) = @_;
	our $currentHour;

	# don't send the NULL record after the group becomes empty
	return if ($context->groupSize()==0
		|| $opcode == &Triceps::OP_NOP);

	my $rhFirst = $context->begin();
	my $rFirst = $rhFirst->getRow();
	my $hourstamp = &hourStamp($rFirst->get("time"));

	return if ($hourstamp < $currentHour);

	if ($opcode == &Triceps::OP_DELETE) {
		$context->send($opcode, $$state);
		return;
	}
		
	my $bytes = 0;
	for (my $rhi = $rhFirst; !$rhi->isNull(); 
			$rhi = $context->next($rhi)) {
		$bytes += $rhi->getRow()->get("bytes");
	}

	my $res = $context->resultType()->makeRowHash(
		time => $hourstamp,
		local_ip => $rFirst->get("local_ip"), 
		remote_ip => $rFirst->get("remote_ip"), 
		bytes => $bytes,
	);
	${$state} = $res;
	$context->send($opcode, $res);
}

sub initHourly #  (@args)
{
	my $refvar;
	return \$refvar;
}

# the full stats for the recent time
our $ttPackets = Triceps::TableType->new($rtPacket)
	->addSubIndex("byHour", 
		Triceps::IndexType->newPerlSorted("byHour", undef, sub {
			return &hourStamp($_[0]->get("time")) <=> &hourStamp($_[1]->get("time"));
		})
		->addSubIndex("byIP", 
			Triceps::IndexType->newHashed(key => [ "local_ip", "remote_ip" ])
			->addSubIndex("group",
				Triceps::IndexType->newFifo()
				->setAggregator(Triceps::AggregatorType->new(
					$rtHourly, "aggrHourly", \&initHourly, \&computeHourly)
				)
			)
		)
	)
;

$ttPackets->initialize();
our $tPackets = $uTraffic->makeTable($ttPackets, "tPackets");

# the aggregated hourly stats, kept longer
our $ttHourly = Triceps::TableType->new($rtHourly)
	->addSubIndex("byAggr", 
		Triceps::SimpleOrderedIndex->new(
			time => "ASC", local_ip => "ASC", remote_ip => "ASC")
	)
;

$ttHourly->initialize();
our $tHourly = $uTraffic->makeTable($ttHourly, "tHourly");

# connect the tables
$tPackets->getAggregatorLabel("aggrHourly")->chain($tHourly->getInputLabel());

# label to print the changes to the detailed stats
makePrintLabel("lbPrintPackets", $tPackets->getOutputLabel());
# label to print the changes to the hourly stats
makePrintLabel("lbPrintHourly", $tHourly->getOutputLabel());

# dump a table's contents
sub dumpTable # ($table)
{
	my $table = shift;
	for (my $rhit = $table->begin(); !$rhit->isNull(); $rhit = $rhit->next()) {
		&send($rhit->getRow()->printP(), "\n");
	}
}

# how long to keep the detailed data, hours
our $keepHours = 2;

# flush the data older than $keepHours from $tPackets
sub flushOldPackets
{
	my $earliest = $currentHour - $keepHours * (1000*1000*3600);
	my $next;
	# the default iteration of $tPackets goes in the hour stamp order
	for (my $rhit = $tPackets->begin(); !$rhit->isNull(); $rhit = $next) {
		last if (&hourStamp($rhit->getRow()->get("time")) >= $earliest);
		$next = $rhit->next(); # advance before removal
		$tPackets->remove($rhit);
	}
}

while(&readLine) {
	chomp;
	my @data = split(/,/); # starts with a command, then string opcode
	my $type = shift @data;
	if ($type eq "new") {
		my $rowop = $tPackets->getInputLabel()->makeRowopArray(@data);
		# update the current notion of time (simplistic)
		$currentHour = &hourStamp($rowop->getRow()->get("time"));
		if (defined($rowop->getRow()->get("local_ip"))) {
			$uTraffic->call($rowop);
		}
		&flushOldPackets(); # flush the packets
		$uTraffic->drainFrame(); # just in case, for completeness
	} elsif ($type eq "dumpPackets") {
		&dumpTable($tPackets);
	} elsif ($type eq "dumpHourly") {
		&dumpTable($tHourly);
	}
}

}; # Hourly

#########################
#  run the hourly aggregation

setInputLines(
	"new,OP_INSERT,1330886011000000,1.2.3.4,5.6.7.8,2000,80,100\n",
	"new,OP_INSERT,1330886012000000,1.2.3.4,5.6.7.8,2000,80,50\n",
	"new,OP_INSERT,1330889811000000,1.2.3.4,5.6.7.8,2000,80,300\n",
	"new,OP_INSERT,1330894211000000,1.2.3.5,5.6.7.9,3000,80,200\n",
	"new,OP_INSERT,1330894211000000,1.2.3.4,5.6.7.8,2000,80,500\n",
	"dumpPackets\n",
	"dumpHourly\n",
	"new,OP_INSERT,1330896811000000,1.2.3.5,5.6.7.9,3000,80,10\n",
	"new,OP_INSERT,1330900411000000,1.2.3.4,5.6.7.8,2000,80,40\n",
	"new,OP_INSERT,1330904011000000\n",
	"dumpPackets\n",
	"dumpHourly\n",
);
&doHourly();
#print &getResultLines();
ok(&getResultLines(), 
'> new,OP_INSERT,1330886011000000,1.2.3.4,5.6.7.8,2000,80,100
tPackets.out OP_INSERT time="1330886011000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="100" 
tHourly.out OP_INSERT time="1330884000000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="100" 
> new,OP_INSERT,1330886012000000,1.2.3.4,5.6.7.8,2000,80,50
tHourly.out OP_DELETE time="1330884000000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="100" 
tPackets.out OP_INSERT time="1330886012000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="50" 
tHourly.out OP_INSERT time="1330884000000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="150" 
> new,OP_INSERT,1330889811000000,1.2.3.4,5.6.7.8,2000,80,300
tPackets.out OP_INSERT time="1330889811000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="300" 
tHourly.out OP_INSERT time="1330887600000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="300" 
> new,OP_INSERT,1330894211000000,1.2.3.5,5.6.7.9,3000,80,200
tPackets.out OP_INSERT time="1330894211000000" local_ip="1.2.3.5" remote_ip="5.6.7.9" local_port="3000" remote_port="80" bytes="200" 
tHourly.out OP_INSERT time="1330891200000000" local_ip="1.2.3.5" remote_ip="5.6.7.9" bytes="200" 
> new,OP_INSERT,1330894211000000,1.2.3.4,5.6.7.8,2000,80,500
tPackets.out OP_INSERT time="1330894211000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="500" 
tHourly.out OP_INSERT time="1330891200000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="500" 
> dumpPackets
time="1330886011000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="100" 
time="1330886012000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="50" 
time="1330889811000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="300" 
time="1330894211000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="500" 
time="1330894211000000" local_ip="1.2.3.5" remote_ip="5.6.7.9" local_port="3000" remote_port="80" bytes="200" 
> dumpHourly
time="1330884000000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="150" 
time="1330887600000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="300" 
time="1330891200000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="500" 
time="1330891200000000" local_ip="1.2.3.5" remote_ip="5.6.7.9" bytes="200" 
> new,OP_INSERT,1330896811000000,1.2.3.5,5.6.7.9,3000,80,10
tPackets.out OP_INSERT time="1330896811000000" local_ip="1.2.3.5" remote_ip="5.6.7.9" local_port="3000" remote_port="80" bytes="10" 
tHourly.out OP_INSERT time="1330894800000000" local_ip="1.2.3.5" remote_ip="5.6.7.9" bytes="10" 
tPackets.out OP_DELETE time="1330886011000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="100" 
tPackets.out OP_DELETE time="1330886012000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="50" 
> new,OP_INSERT,1330900411000000,1.2.3.4,5.6.7.8,2000,80,40
tPackets.out OP_INSERT time="1330900411000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="40" 
tHourly.out OP_INSERT time="1330898400000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="40" 
tPackets.out OP_DELETE time="1330889811000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="300" 
> new,OP_INSERT,1330904011000000
tPackets.out OP_DELETE time="1330894211000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="500" 
tPackets.out OP_DELETE time="1330894211000000" local_ip="1.2.3.5" remote_ip="5.6.7.9" local_port="3000" remote_port="80" bytes="200" 
> dumpPackets
time="1330896811000000" local_ip="1.2.3.5" remote_ip="5.6.7.9" local_port="3000" remote_port="80" bytes="10" 
time="1330900411000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="40" 
> dumpHourly
time="1330884000000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="150" 
time="1330887600000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="300" 
time="1330891200000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="500" 
time="1330891200000000" local_ip="1.2.3.5" remote_ip="5.6.7.9" bytes="200" 
time="1330894800000000" local_ip="1.2.3.5" remote_ip="5.6.7.9" bytes="10" 
time="1330898400000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="40" 
');

#########################
# the traffic that gets consolidated by the day:
# first by the hour as before, then, when the day rolls over, by the day,
# with the manual aggregation

sub doDaily {

our $uTraffic = Triceps::Unit->new("uTraffic");

# one packet's header
our $rtPacket = Triceps::RowType->new(
	time => "int64", # packet's timestamp, microseconds
	local_ip => "string", # string to make easier to read
	remote_ip => "string", # string to make easier to read
	local_port => "int32", 
	remote_port => "int32",
	bytes => "int32", # size of the packet
);

# an hourly summary, now with the day extracted
our $rtHourly = Triceps::RowType->new(
	time => "int64", # hour's timestamp, microseconds
	day => "string", # in YYYYMMDD
	local_ip => "string", # string to make easier to read
	remote_ip => "string", # string to make easier to read
	bytes => "int64", # bytes sent in an hour
);

# a daily summary: just all traffic for that day
our $rtDaily = Triceps::RowType->new(
	day => "string", # in YYYYMMDD
	bytes => "int64", # bytes sent in an hour
);

# reuse the same sub hourStamp

# compute the date of a timestamp, a string YYYYMMDD
sub dateStamp # (time)
{
	my @ts = gmtime($_[0]/1000000); # microseconds to seconds
	return sprintf("%04d%02d%02d", $ts[5]+1900, $ts[4]+1, $ts[3]);
}

# the current hour stamp that keeps being updated
our $currentHour = undef;
# the current day stamp that keeps being updated
our $currentDay = undef;

# aggregation handler: recalculate the summary for the last hour
sub computeHourlywDay # (table, context, aggop, opcode, rh, state, args...)
{
	my ($table, $context, $aggop, $opcode, $rh, $state, @args) = @_;
	our $currentHour;

	# don't send the NULL record after the group becomes empty
	return if ($context->groupSize()==0
		|| $opcode == &Triceps::OP_NOP);

	my $rhFirst = $context->begin();
	my $rFirst = $rhFirst->getRow();
	my $hourstamp = &hourStamp($rFirst->get("time"));

	return if ($hourstamp < $currentHour);

	if ($opcode == &Triceps::OP_DELETE) {
		$context->send($opcode, $$state);
		return;
	}
		
	my $bytes = 0;
	for (my $rhi = $rhFirst; !$rhi->isNull(); 
			$rhi = $context->next($rhi)) {
		$bytes += $rhi->getRow()->get("bytes");
	}

	my $res = $context->resultType()->makeRowHash(
		time => $hourstamp,
		day => &dateStamp($hourstamp),
		local_ip => $rFirst->get("local_ip"), 
		remote_ip => $rFirst->get("remote_ip"), 
		bytes => $bytes,
	);
	${$state} = $res;
	$context->send($opcode, $res);
}

# reuse the same sub initHourly 

# the full stats for the recent time
our $ttPackets = Triceps::TableType->new($rtPacket)
	->addSubIndex("byHour", 
		Triceps::IndexType->newPerlSorted("byHour", undef, sub {
			return &hourStamp($_[0]->get("time")) <=> &hourStamp($_[1]->get("time"));
		})
		->addSubIndex("byIP", 
			Triceps::IndexType->newHashed(key => [ "local_ip", "remote_ip" ])
			->addSubIndex("group",
				Triceps::IndexType->newFifo()
				->setAggregator(Triceps::AggregatorType->new(
					$rtHourly, "aggrHourly", \&initHourly, \&computeHourlywDay)
				)
			)
		)
	)
;

$ttPackets->initialize();
our $tPackets = $uTraffic->makeTable($ttPackets, "tPackets");

# the aggregated hourly stats, kept longer
our $ttHourly = Triceps::TableType->new($rtHourly)
	->addSubIndex("byAggr", 
		Triceps::SimpleOrderedIndex->new(
			time => "ASC", local_ip => "ASC", remote_ip => "ASC")
	)
	->addSubIndex("byDay", 
		Triceps::IndexType->newHashed(key => [ "day" ])
		->addSubIndex("group",
			Triceps::IndexType->newFifo()
		)
	)
;

$ttHourly->initialize();
our $tHourly = $uTraffic->makeTable($ttHourly, "tHourly");

# remember the daily secondary index type
our $idxHourlyByDay = $ttHourly->findSubIndex("byDay");
our $idxHourlyByDayGroup = $idxHourlyByDay->findSubIndex("group");

# the aggregated daily stats, kept even longer
our $ttDaily = Triceps::TableType->new($rtDaily)
	->addSubIndex("byDay", 
		Triceps::IndexType->newHashed(key => [ "day" ])
	)
;

$ttDaily->initialize();
our $tDaily = $uTraffic->makeTable($ttDaily, "tDaily");

# connect the tables (but not the daily one)
$tPackets->getAggregatorLabel("aggrHourly")->chain($tHourly->getInputLabel());

# reuse the same sub makePrintLabel

# label to print the changes to the detailed stats
makePrintLabel("lbPrintPackets", $tPackets->getOutputLabel());
# label to print the changes to the hourly stats
makePrintLabel("lbPrintHourly", $tHourly->getOutputLabel());
# label to print the changes to the daily stats
makePrintLabel("lbPrintDaily", $tDaily->getOutputLabel());

# reuse the same sub dumpTable

# how long to keep the detailed data, hours
our $keepHours = 2;

# reuse the same sub flushOldPackets

# the manual aggregation of a day's data
sub computeDay # ($dateStamp)
{
	our $uTraffic;
	my $bytes = 0;

	my $rhFirst = $tHourly->findIdxBy($idxHourlyByDay, day => $_[0]);
	my $rhEnd = $rhFirst->nextGroupIdx($idxHourlyByDayGroup);
	for (my $rhi = $rhFirst; 
			!$rhi->same($rhEnd); $rhi = $rhi->nextIdx($idxHourlyByDay)) {
		$bytes += $rhi->getRow()->get("bytes");
	}
	$uTraffic->makeHashCall($tDaily->getInputLabel(), "OP_INSERT",
		day => $_[0],
		bytes => $bytes,
	);
}

while(&readLine) {
	chomp;
	my @data = split(/,/); # starts with a command, then string opcode
	my $type = shift @data;
	if ($type eq "new") {
		my $rowop = $tPackets->getInputLabel()->makeRowopArray(@data);
		# update the current notion of time (simplistic)
		$currentHour = &hourStamp($rowop->getRow()->get("time"));
		my $lastDay = $currentDay;
		$currentDay = &dateStamp($currentHour);
		if (defined($rowop->getRow()->get("local_ip"))) {
			$uTraffic->call($rowop);
		}
		&flushOldPackets(); # flush the packets
		if (defined $lastDay && $lastDay ne $currentDay) {
			&computeDay($lastDay); # manual aggregation
		}
		$uTraffic->drainFrame(); # just in case, for completeness
	} elsif ($type eq "dumpPackets") {
		&dumpTable($tPackets);
	} elsif ($type eq "dumpHourly") {
		&dumpTable($tHourly);
	} elsif ($type eq "dumpDaily") {
		&dumpTable($tDaily);
	}
}

}; # Daily

#########################
#  run the daily aggregation

setInputLines(
	"new,OP_INSERT,1330886011000000,1.2.3.4,5.6.7.8,2000,80,100\n",
	"new,OP_INSERT,1330886012000000,1.2.3.4,5.6.7.8,2000,80,50\n",
	"new,OP_INSERT,1330889811000000,1.2.3.4,5.6.7.8,2000,80,300\n",
	"new,OP_INSERT,1330972411000000,1.2.3.5,5.6.7.9,3000,80,200\n",
	"new,OP_INSERT,1331058811000000\n",
	"new,OP_INSERT,1331145211000000\n",
	"dumpDaily\n",
);
&doDaily();
#print &getResultLines();
ok(&getResultLines(), 
'> new,OP_INSERT,1330886011000000,1.2.3.4,5.6.7.8,2000,80,100
tPackets.out OP_INSERT time="1330886011000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="100" 
tHourly.out OP_INSERT time="1330884000000000" day="20120304" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="100" 
> new,OP_INSERT,1330886012000000,1.2.3.4,5.6.7.8,2000,80,50
tHourly.out OP_DELETE time="1330884000000000" day="20120304" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="100" 
tPackets.out OP_INSERT time="1330886012000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="50" 
tHourly.out OP_INSERT time="1330884000000000" day="20120304" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="150" 
> new,OP_INSERT,1330889811000000,1.2.3.4,5.6.7.8,2000,80,300
tPackets.out OP_INSERT time="1330889811000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="300" 
tHourly.out OP_INSERT time="1330887600000000" day="20120304" local_ip="1.2.3.4" remote_ip="5.6.7.8" bytes="300" 
> new,OP_INSERT,1330972411000000,1.2.3.5,5.6.7.9,3000,80,200
tPackets.out OP_INSERT time="1330972411000000" local_ip="1.2.3.5" remote_ip="5.6.7.9" local_port="3000" remote_port="80" bytes="200" 
tHourly.out OP_INSERT time="1330970400000000" day="20120305" local_ip="1.2.3.5" remote_ip="5.6.7.9" bytes="200" 
tPackets.out OP_DELETE time="1330886011000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="100" 
tPackets.out OP_DELETE time="1330886012000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="50" 
tPackets.out OP_DELETE time="1330889811000000" local_ip="1.2.3.4" remote_ip="5.6.7.8" local_port="2000" remote_port="80" bytes="300" 
tDaily.out OP_INSERT day="20120304" bytes="450" 
> new,OP_INSERT,1331058811000000
tPackets.out OP_DELETE time="1330972411000000" local_ip="1.2.3.5" remote_ip="5.6.7.9" local_port="3000" remote_port="80" bytes="200" 
tDaily.out OP_INSERT day="20120305" bytes="200" 
> new,OP_INSERT,1331145211000000
tDaily.out OP_INSERT day="20120306" bytes="0" 
> dumpDaily
day="20120305" bytes="200" 
day="20120304" bytes="450" 
day="20120306" bytes="0" 
');
