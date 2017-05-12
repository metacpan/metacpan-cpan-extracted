#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The test for aggregators' and SimpleAggregator's interaction with threads.
# XXX For now it tests that SimpleAggregator doesn't work for passing its
# results between threads.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 3 };
use Triceps;
use Carp;
use Triceps::X::TestFeed qw(:all);
use strict;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#########################

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

# exporting a table type with aggregator to another thread
{
	my $res;

	eval {
	Triceps::Triead::startHere(
		app => "a1",
		thread => "main",
		main => sub {
			my $opts = {};
			&Triceps::Opt::parse("main main", $opts, {@Triceps::Triead::opts}, @_);
			my $owner = $opts->{owner};
			my $app = $owner->app();
			my $unit = $owner->unit();

			my $ttWindow = &makeTtWindow();
			Triceps::SimpleAggregator::make(
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
			);
			ok(ref $ttWindow, "Triceps::TableType");
			$ttWindow->initialize();

			my $faOut = $owner->makeNexus(
				name => "source",
				labels => [
					data => $rtTrade, # data to forward to the table
				],
				tableTypes => [
					ttWindow => $ttWindow,
				],
				import => "writer",
			);

			Triceps::Triead::start(
				app => "a1",
				thread => "th1",
				immediate => 1,
				main => sub {
					my $opts = {};
					&Triceps::Opt::parse("th1 main", $opts, {@Triceps::Triead::opts}, @_);
					my $owner = $opts->{owner};
					my $unit = $owner->unit();

					my $faSource = $owner->importNexus(
						from => "main/source",
						import => "reader",
						immediate => $opts->{immediate},
					);

					my $ttWindow = $faSource->impTableType("ttWindow");
					$ttWindow->initialize();
					my $t1 = $unit->makeTable($ttWindow, "t1");

					$faSource->getLabel("data")->chain($t1->getInputLabel());

					my $faResult = $owner->makeNexus(
						name => "result",
						labels => [
							data => $t1->getOutputLabel(),
							aggr => $t1->getAggregatorLabel("myAggr"),
						],
						import => "writer",
						reverse => 1,
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
			$unit->makeHashCall($odata, "OP_INSERT", id => 1, symbol => "AAA", price => 10, size => 10,);
			$unit->makeHashCall($odata, "OP_INSERT", id => 2, symbol => "BBB", price => 20, size => 20,);
			$unit->makeHashCall($odata, "OP_INSERT", id => 3, symbol => "AAA", price => 20, size => 20,);
			$unit->makeHashCall($odata, "OP_INSERT", id => 5, symbol => "AAA", price => 30, size => 30,);
			$unit->makeHashCall($odata, "OP_INSERT", id => 3, symbol => "BBB", price => 20, size => 20,);
			$unit->makeHashCall($odata, "OP_DELETE", id => 5,);

			$owner->flushWriters();

			Triceps::AutoDrain::makeExclusive($owner);
			while ($owner->nextXtrayNoWait()) { }
			$app->shutdown();
		},
	);
	};
	ok($@,
qr/App 'a1' has been aborted by thread 'main': Triceps::TrieadOwner::makeNexus: invalid arguments:
  In app 'a1' thread 'main' can not export the facet 'source' with an error:
    Can not export the table type 'ttWindow' containing errors:
      index error:
        nested index 2 'bySymbol':
          nested index 1 'last2':
            aggregator 'myAggr':
              PerlAggregatorType: the handler function is not compatible with multithreading:
                argument 1 is not threadable:
                  to allow passing between the threads, the value must be one of undef, int, float, string, RowType, or an array or hash thereof/);
	#print $res;
	#ok($res,' ');
}
