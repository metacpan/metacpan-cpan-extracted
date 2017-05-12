#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The fork-join (AKA diamond) topology with the correct reordering afterwards.
# (The fork-join has nothing to do with the table joins, it's a connection
# topology).

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 2 };
use Triceps;
use Triceps::X::TestFeed qw(:all);
use Carp;
ok(1); # If we made it this far, we're ok.

use strict;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#########################
# The logic is organized in a pipeline, with simple feed and printing.
# The logic of the workers is copied from the xSelfJoin.t example of the 
# foreign exchange arbitration.

package App1;
use Test;
use Carp;
use Triceps::X::TestFeed qw(:all);

sub mainT # (@opts)
{
	my $opts = {};
	&Triceps::Opt::parse("mainT", $opts, {@Triceps::Triead::opts,
		workers => [ 1, undef ], # number of worker threads
		delay => [ 0, undef ], # artificial delay for the 0th thread
	}, @_);
	undef @_; # avoids a leak in threads module
	my $owner = $opts->{owner};
	my $app = $owner->app();
	my $unit = $owner->unit();

	my $rtRate = Triceps::RowType->new( # an exchange rate between two currencies
		ccy1 => "string", # currency code
		ccy2 => "string", # currency code
		rate => "float64", # multiplier when exchanging ccy1 to ccy2
	);

	# the resulting trade recommendations
	my $rtResult = Triceps::RowType->new(
		triead => "int32", # id of the thread that produced it
		ccy1 => "string", # currency code
		ccy2 => "string", # currency code
		ccy3 => "string", # currency code
		rate1 => "float64",
		rate2 => "float64",
		rate3 => "float64",
		looprate => "float64",
	);

	# each tray gets sequentially numbered and framed
	my $rtFrame = Triceps::RowType->new(
		seq => "int64", # sequence number
		triead => "int32", # id of the thread that produced it (optional)
	);
	
	# the plain-text output of the result
	my $rtPrint = Triceps::RowType->new(
		text => "string",
	);
	
	# the input data
	my $faIn = $owner->makeNexus(
		name => "input",
		labels => [
			rate => $rtRate,
			_BEGIN_ => $rtFrame,
		],
		import => "none",
	);

	# the raw result collected from the workers
	my $faRes = $owner->makeNexus(
		name => "result",
		labels => [
			result => $rtResult,
			_BEGIN_ => $rtFrame,
		],
		import => "none",
	);

	my $faPrint = $owner->makeNexus(
		name => "print",
		labels => [
			raw => $rtPrint, # in raw order as received by collator
			cooked => $rtPrint, # after collation
		],
		import => "reader",
	);

	Triceps::Triead::start(
		app => $app->getName(),
		thread => "reader",
		main => \&readerT,
		to => $owner->getName() . "/input",
	);

	for (my $i = 0; $i < $opts->{workers}; $i++) {
		Triceps::Triead::start(
			app => $app->getName(),
			thread => "worker$i",
			main => \&workerT,
			from => $owner->getName() . "/input",
			to => $owner->getName() . "/result",
			delay => ($i == 0? $opts->{delay} : 0),
			workers => $opts->{workers},
			identity => $i,
		);
	}

	Triceps::Triead::start(
		app => $app->getName(),
		thread => "collator",
		main => \&collatorT,
		from => $owner->getName() . "/result",
		to => $owner->getName() . "/print",
	);

	my @rawp; # the print in original order
	my @cookedp; # the print in collated order

	$faPrint->getLabel("raw")->makeChained("lbRawP", undef, sub {
		push @rawp, $_[1]->getRow()->get("text");
	});
	$faPrint->getLabel("cooked")->makeChained("lbCookedP", undef, sub {
		push @cookedp, $_[1]->getRow()->get("text");
	});

	$owner->readyReady();

	$owner->mainLoop();

	&send("--- raw ---\n", join("\n", @rawp), "\n");
	&send("--- cooked ---\n", join("\n", @cookedp), "\n");
}

sub readerT # (@opts)
{
	my $opts = {};
	&Triceps::Opt::parse("readerT", $opts, {@Triceps::Triead::opts,
		to => [ undef, \&Triceps::Opt::ck_mandatory ], # dest nexus
	}, @_);
	undef @_; # avoids a leak in threads module
	my $owner = $opts->{owner};
	my $unit = $owner->unit();

	my $faIn = $owner->importNexus(
		from => $opts->{to},
		import => "writer",
	);

	my $lbRate = $faIn->getLabel("rate");
	my $lbBegin = $faIn->getLabel("_BEGIN_");
	# _END_ is always defined, even if not defined explicitly
	my $lbEnd = $faIn->getLabel("_END_");
	my $seq = 0; # the sequence

	$owner->readyReady();

	while(&readLine) {
		chomp;

		++$seq; # starts with 1
		$unit->makeHashCall($lbBegin, "OP_INSERT", seq => $seq);
		my @data = split(/,/); # starts with a string opcode
		$unit->makeArrayCall($lbRate, @data);
		# calling _END_ is an equivalent of flushWriter()
		$unit->makeHashCall($lbEnd, "OP_INSERT");
	}

	{
		# drain the pipeline before shutting down
		my $ad = Triceps::AutoDrain::makeShared($owner);
		$owner->app()->shutdown();
	}
}

sub workerT # (@opts)
{
	my $opts = {};
	&Triceps::Opt::parse("workerT", $opts, {@Triceps::Triead::opts,
		from => [ undef, \&Triceps::Opt::ck_mandatory ], # src nexus
		to => [ undef, \&Triceps::Opt::ck_mandatory ], # dest nexus
		delay => [ 0, undef ], # processing delay
		workers => [ undef, \&Triceps::Opt::ck_mandatory ], # how many workers
		identity => [ undef, \&Triceps::Opt::ck_mandatory ], # which one is us
	}, @_);
	undef @_; # avoids a leak in threads module
	my $owner = $opts->{owner};
	my $unit = $owner->unit();
	my $delay = $opts->{delay};
	my $workers = $opts->{workers};
	my $identity = $opts->{identity};

	my $faIn = $owner->importNexus(
		from => $opts->{from},
		import => "reader",
	);

	my $faRes = $owner->importNexus(
		from => $opts->{to},
		import => "writer",
	);

	my $lbInRate = $faIn->getLabel("rate");
	my $lbResult = $faRes->getLabel("result");
	my $lbResBegin = $faRes->getLabel("_BEGIN_");
	my $lbResEnd = $faRes->getLabel("_END_");

	my $seq; # sequence from the frame labels
	my $compute; # the computation is to be done by this label
	$faIn->getLabel("_BEGIN_")->makeChained("lbInBegin", undef, sub {
		$seq = $_[1]->getRow()->get("seq");
	});

	# all exchange rates
	my $ttRate = Triceps::TableType->new($lbInRate->getRowType())
		->addSubIndex("byCcy1",
			Triceps::IndexType->newHashed(key => [ "ccy1" ])
			->addSubIndex("byCcy12",
				Triceps::IndexType->newHashed(key => [ "ccy2" ])
			)
		)
		->addSubIndex("byCcy2",
			Triceps::IndexType->newHashed(key => [ "ccy2" ])
			->addSubIndex("grouping", Triceps::IndexType->newFifo())
		)
	;
	$ttRate->initialize();
	my $tRate = $unit->makeTable($ttRate, "tRate");
	my $lbRateInput = $tRate->getInputLabel();

	my $ixtCcy1 = $ttRate->findSubIndex("byCcy1");
	my $ixtCcy12 = $ixtCcy1->findSubIndex("byCcy12");

	# the table gets updated for every incoming rate
	$lbInRate->makeChained("lbIn", undef, sub {
		my $ccy1 = $_[1]->getRow()->get("ccy1");
		# decide, whether this thread is to perform the join
		$compute = ((ord(substr($ccy1, 0, 1)) - ord('A')) % $workers == $identity);

		# this relies on every Xtray containing only one rowop,
		# otherwise one Xtray will be split into multiple
		if ($compute) {
			$unit->makeHashCall($lbResBegin, "OP_INSERT", seq => $seq, triead => $identity);
			select(undef, undef, undef, $delay) if ($delay);
		}

		# even with $compute is set, this might produce some output or not,
		# but the frame still goes out every time $compute is set, because
		# _BEGIN_ forces it
		$unit->call($lbRateInput->adopt($_[1]));
	});


	##################################################
	# The logic is copied from xSelfJoin.t
	# Arbitrate with the manual traversal

	$tRate->getOutputLabel()->makeChained("lbCompute", undef, sub {
		return if (!$compute); # not this thread's problem

		my ($label, $rowop) = @_;
		my $row = $rowop->getRow();
		my $ccy1 = $row->get("ccy1");
		my $ccy2 = $row->get("ccy2");
		my $rate1 = $row->get("rate");

		my $rhi = $tRate->findIdxBy($ixtCcy1, ccy1 => $ccy2);
		my $rhiEnd = $rhi->nextGroupIdx($ixtCcy12);
		for (; !$rhi->same($rhiEnd); $rhi = $rhi->nextIdx($ixtCcy12)) {
			my $row2 = $rhi->getRow();
			my $ccy3 = $row2->get("ccy2");
			my $rate2 = $row2->get("rate");

			my $rhj = $tRate->findIdxBy($ixtCcy12, ccy1 => $ccy3, ccy2 => $ccy1);
			# it's a leaf primary index, so there may be no more than one match
			next
				if ($rhj->isNull());
			my $row3 = $rhj->getRow();
			my $rate3 = $row3->get("rate");
			my $looprate = $rate1 * $rate2 * $rate3;

			# now build the row in normalized order of currencies
			my $result;
			if ($ccy2 lt $ccy3) {
				if ($ccy2 lt $ccy1) { # rotate left
					$result = $lbResult->makeRowopHash($rowop->getOpcode(),
						ccy1 => $ccy2,
						ccy2 => $ccy3,
						ccy3 => $ccy1,
						rate1 => $rate2,
						rate2 => $rate3,
						rate3 => $rate1,
						looprate => $looprate,
					);
				}
			} else {
				if ($ccy3 lt $ccy1) { # rotate right
					$result = $lbResult->makeRowopHash($rowop->getOpcode(),
						ccy1 => $ccy3,
						ccy2 => $ccy1,
						ccy3 => $ccy2,
						rate1 => $rate3,
						rate2 => $rate1,
						rate3 => $rate2,
						looprate => $looprate,
					);
				}
			}
			if (!defined $result) { # use the straight order
				$result = $lbResult->makeRowopHash($rowop->getOpcode(),
					ccy1 => $ccy1,
					ccy2 => $ccy2,
					ccy3 => $ccy3,
					rate1 => $rate1,
					rate2 => $rate2,
					rate3 => $rate3,
					looprate => $looprate,
				);
			}
			if ($looprate > 1) {
				$unit->call($result);
			}
		}
	});
	##################################################

	$owner->readyReady();

	$owner->mainLoop();
}

sub collatorT # (@opts)
{
	my $opts = {};
	&Triceps::Opt::parse("collatorT", $opts, {@Triceps::Triead::opts,
		from => [ undef, \&Triceps::Opt::ck_mandatory ], # src nexus
		to => [ undef, \&Triceps::Opt::ck_mandatory ], # dest nexus
	}, @_);
	undef @_; # avoids a leak in threads module
	my $owner = $opts->{owner};
	my $unit = $owner->unit();

	my $faRes = $owner->importNexus(
		from => $opts->{from},
		import => "reader",
	);

	my $faPrint = $owner->importNexus(
		from => $opts->{to},
		import => "writer",
	);

	my $lbResult = $faRes->getLabel("result");
	my $lbResBegin = $faRes->getLabel("_BEGIN_");
	my $lbResEnd = $faRes->getLabel("_END_");

	my $lbPrintRaw = $faPrint->getLabel("raw");
	my $lbPrintCooked = $faPrint->getLabel("cooked");

	my $seq = 1; # next expected sequence
	my @trays; # trays held for reordering: $trays[0] is the slot for sequence $seq
		# (only of course that slot will be always empty but the following ones may
		# contain the trays that arrived out of order)
	my $curseq; # the sequence of the current arriving tray

	# The processing of data after it has been "cooked", i.e. reordered.
	my $bindRes = Triceps::FnBinding->new(
		name => "bindRes",
		on => $faRes->getFnReturn(),
		unit => $unit,
		withTray => 1,
		labels => [
			"_BEGIN_" => sub {
				$unit->makeHashCall($lbPrintCooked, "OP_INSERT", text => $_[1]->printP("BEGIN"));
			},
			"result" => sub {
				$unit->makeHashCall($lbPrintCooked, "OP_INSERT", text => $_[1]->printP("result"));
			}
		],
	);
	$faRes->getFnReturn()->push($bindRes); # will stay permanently
	
	# manipulation of the reordering, 
	# and along the way reporting of the raw sequence
	$lbResBegin->makeChained("lbBegin", undef, sub {
		$unit->makeHashCall($lbPrintRaw, "OP_INSERT", text => $_[1]->printP("BEGIN"));
		$curseq = $_[1]->getRow()->get("seq");
	});
	$lbResult->makeChained("lbResult", undef, sub {
		$unit->makeHashCall($lbPrintRaw, "OP_INSERT", text => $_[1]->printP("result"));
	});
	$lbResEnd->makeChained("lbEnd", undef, sub {
		my $tray = $bindRes->swapTray();
		if ($curseq == $seq) {
			$unit->call($tray);
			shift @trays;
			$seq++;
			while ($#trays >= 0 && defined($trays[0])) {
				# flush the trays that arrived misordered
				$unit->call(shift @trays);
				$seq++;
			}
		} elsif ($curseq > $seq) {
			$trays[$curseq-$seq] = $tray; # remember for the future
		} else {
			# should never happen but just in case
			$unit->call($tray);
		}
	});

	$owner->readyReady();

	$owner->mainLoop();
};

sub RUN {
Triceps::Triead::startHere(
	app => "ForkJoin",
	thread => "main",
	main => \&mainT,
	workers => 2,
	delay => 0.02,
);
}

package main;

# input for the arbitration
my @inputArb = (
	"OP_INSERT,AAA,BBB,1.30\n",
	"OP_INSERT,BBB,AAA,0.74\n",
	"OP_INSERT,AAA,CCC,1.98\n",
	"OP_INSERT,CCC,AAA,0.49\n",
	"OP_INSERT,BBB,CCC,1.28\n",
	"OP_INSERT,CCC,BBB,0.78\n",

	"OP_DELETE,BBB,AAA,0.74\n",
	"OP_INSERT,BBB,AAA,0.64\n",
);
setInputLines(@inputArb);
&App1::RUN();
#print(&getResultLines(), "\n");
ok(&getResultLines(),
'--- raw ---
BEGIN OP_INSERT seq="2" triead="1" 
BEGIN OP_INSERT seq="5" triead="1" 
BEGIN OP_INSERT seq="7" triead="1" 
result OP_DELETE ccy1="AAA" ccy2="CCC" ccy3="BBB" rate1="1.98" rate2="0.78" rate3="0.74" looprate="1.142856" 
BEGIN OP_INSERT seq="8" triead="1" 
BEGIN OP_INSERT seq="1" triead="0" 
BEGIN OP_INSERT seq="3" triead="0" 
BEGIN OP_INSERT seq="4" triead="0" 
BEGIN OP_INSERT seq="6" triead="0" 
result OP_INSERT ccy1="AAA" ccy2="CCC" ccy3="BBB" rate1="1.98" rate2="0.78" rate3="0.74" looprate="1.142856" 
--- cooked ---
BEGIN OP_INSERT seq="1" triead="0" 
BEGIN OP_INSERT seq="2" triead="1" 
BEGIN OP_INSERT seq="3" triead="0" 
BEGIN OP_INSERT seq="4" triead="0" 
BEGIN OP_INSERT seq="5" triead="1" 
BEGIN OP_INSERT seq="6" triead="0" 
result OP_INSERT ccy1="AAA" ccy2="CCC" ccy3="BBB" rate1="1.98" rate2="0.78" rate3="0.74" looprate="1.142856" 
BEGIN OP_INSERT seq="7" triead="1" 
result OP_DELETE ccy1="AAA" ccy2="CCC" ccy3="BBB" rate1="1.98" rate2="0.78" rate3="0.74" looprate="1.142856" 
BEGIN OP_INSERT seq="8" triead="1" 
');

