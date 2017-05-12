#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The test for aggregators interaction with threads.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 5 };
use Triceps;
use Carp;
use Triceps::X::TestFeed qw(:all);
use strict;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#########################

my @def1 = (
	a => "uint8",
	b => "int32",
	c => "int64",
	d => "float64",
	e => "string",
);
my $rt1 = Triceps::RowType->new( # used later
	@def1
);
ok(ref $rt1, "Triceps::RowType");

my @def2 = (
	b => "int32",
	c => "int64",
	v => "float64",
);
my $rt2 = Triceps::RowType->new( # used later
	@def2
);
ok(ref $rt2, "Triceps::RowType");

my @dataset1 = (
	a => "uint8",
	b => 123,
	c => 3e15+0,
	d => 3.14,
	e => "string",
);

my @dataset2 = (
	a => "aaa",
	b => 123,
	c => 3e15+0,
	d => 2.71,
	e => "string2",
);

#########################

# exporting a table type with aggregator to another thread
{

	# The aggregator definition is copied from Aggregator.t
	my $aggHandler3 = ' # (table, context, aggop, opcode, rh, state, args...)
		my ($table, $context, $aggop, $opcode, $rh, $state, @args) = @_;

		# do not send the NULL record after the group becomes empty
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
	';

	my $aggConstructor3 = '
		return undef; # a placeholder for a future row reference
	';

	my $res;

	Triceps::Triead::startHere(
		app => "a1",
		thread => "main",
		main => sub {
			my $opts = {};
			&Triceps::Opt::parse("main main", $opts, {@Triceps::Triead::opts}, @_);
			my $owner = $opts->{owner};
			my $app = $owner->app();
			my $unit = $owner->unit();

			my $tt1 = Triceps::TableType->new($rt1)
				->addSubIndex("grouping",
					Triceps::IndexType->newHashed(key => [ "b", "c" ])
						->addSubIndex("fifo", Triceps::IndexType->newFifo()
							->setAggregator(
								Triceps::AggregatorType->new($rt2, "aggr", $aggConstructor3, $aggHandler3)
							)
						)
				);
			ok(ref $tt1, "Triceps::TableType");

			my $faOut = $owner->makeNexus(
				name => "source",
				labels => [
					data => $rt1, # data to forward to the table
				],
				tableTypes => [
					tt1 => $tt1,
				],
				import => "writer",
			);

			Triceps::Triead::start(
				app => "a1",
				thread => "th1",
				immed => 1,
				reverse => 1,
				main => sub {
					my $opts = {};
					&Triceps::Opt::parse("th1 main", $opts, {@Triceps::Triead::opts,
						reverse => [ 0, undef ],
					}, @_);
					my $owner = $opts->{owner};
					my $unit = $owner->unit();

					my $faSource = $owner->importNexus(
						from => "main/source",
						import => "reader",
						immed => $opts->{immed},
					);

					my $tt1 = $faSource->impTableType("tt1");
					$tt1->initialize();
					my $t1 = $unit->makeTable($tt1, "t1");

					$faSource->getLabel("data")->chain($t1->getInputLabel());

					my $faResult = $owner->makeNexus(
						name => "result",
						labels => [
							data => $t1->getOutputLabel(),
							aggr => $t1->getAggregatorLabel("aggr"),
						],
						import => "writer",
						reverse => $opts->{reverse},
					);

					$owner->readyReady();
					$owner->mainLoop();
					$owner->markDead();
				},
			);

			my $faIn = $owner->importNexus(
				from => "th1/result",
				as => "sink",
				import => "reader",
			);

			$owner->markConstructed();

			$faIn->getLabel("data")->makeChained("indata", undef, sub {
				$res .= $_[1]->printP() . "\n";
			});
			$faIn->getLabel("aggr")->makeChained("inaggr", undef, sub {
				$res .= $_[1]->printP() . "\n";
			});

			my $odata = $faOut->getLabel("data");

			$owner->readyReady();

			# insert the rows in reverse order
			$unit->makeHashCall($odata, "OP_INSERT", @dataset1);
			$unit->makeHashCall($odata, "OP_INSERT", @dataset2);
			$unit->makeHashCall($odata, "OP_DELETE", @dataset2);
			$unit->makeHashCall($odata, "OP_DELETE", @dataset1);

			$owner->flushWriters();

			Triceps::AutoDrain::makeExclusive($owner);
			while ($owner->nextXtrayNoWait()) { }
			$app->shutdown();
		},
	);

	#print $res;
	ok($res,
'sink.data OP_INSERT a="uint8" b="123" c="3000000000000000" d="3.14" e="string" 
sink.aggr OP_INSERT b="1" c="3000000000000000" v="3.14" 
sink.aggr OP_DELETE b="1" c="3000000000000000" v="3.14" 
sink.data OP_INSERT a="aaa" b="123" c="3000000000000000" d="2.71" e="string2" 
sink.aggr OP_INSERT b="2" c="6000000000000000" v="2.71" 
sink.aggr OP_DELETE b="2" c="6000000000000000" v="2.71" 
sink.data OP_DELETE a="aaa" b="123" c="3000000000000000" d="2.71" e="string2" 
sink.aggr OP_INSERT b="1" c="3000000000000000" v="3.14" 
sink.aggr OP_DELETE b="1" c="3000000000000000" v="3.14" 
sink.data OP_DELETE a="uint8" b="123" c="3000000000000000" d="3.14" e="string" 
');
}
