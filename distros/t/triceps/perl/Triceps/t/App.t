#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The test for App handling.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl App.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;
use strict;
use threads;

use Test;
BEGIN { plan tests => 151 };
use Triceps;
ok(1); # If we made it this far, we're ok.

#########################
# stuff that will be used repeatedly

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

#########################

# basic creation, look-up
{
	ok(&Triceps::App::DEFAULT_TIMEOUT(), 30);

	my $a1 = Triceps::App::make("a1");
	ok(ref $a1, "Triceps::App");

	# no threads means dead
	ok($a1->isDead());
	$a1->waitDead();
	ok(!$a1->isShutdown());

	my $a1x = Triceps::App::find("a1");
	ok(ref $a1x, "Triceps::App");
	ok($a1->same($a1x));
	$a1x = Triceps::App::resolve("a1");
	ok($a1->same($a1x));
	$a1x = Triceps::App::resolve($a1);
	ok($a1->same($a1x));

	ok($a1->getName(), "a1");

	my @apps;
	@apps = Triceps::App::listApps();
	ok($#apps, 1);
	ok($apps[0], "a1");
	ok($a1->same($apps[1]));
	undef @apps;

	my $t1 = threads->create(
		sub {
			my $tname = shift;
			my $a1z = Triceps::App::find($tname);
			ok(ref $a1z, "Triceps::App");
		}, "a1");
	$t1->join();

	$Test::ntest += 1; # include the tests in the thread

	# check that the references still work
	ok(ref $a1, "Triceps::App");
	ok($a1->same($a1x));

	# check the basic harvesting (more will be used in the TrieadOwner and other tests)
	$a1->waitNeedHarvest();
	ok($a1->harvestOnce(), 1); # no threads, means the app is dead
	$a1->harvester();
	$a1->harvester(die_on_abort => 0);
	ok(!defined(eval { $a1->harvester("die_on_abort"); }));
	ok($@, qr/^Usage: Triceps::App::harvester\(app, optionName, optionValue, ...\), option names and values must go in pairs/);
	ok(!defined(eval { $a1->harvester(xxx => 1); }));
	ok($@, qr/^Triceps::App::harvester: unknown option 'xxx'/);

	# drop the app from the directory of all apps
	$a1->drop();
	@apps = Triceps::App::listApps();
	ok($#apps, -1);
}

# test the drop by name
{
	my $a1 = Triceps::App::make("a1");
	ok(ref $a1, "Triceps::App");

	my @apps;
	@apps = Triceps::App::listApps();
	ok($#apps, 1);
	ok($apps[0], "a1");

	Triceps::App::drop("a1");
	@apps = Triceps::App::listApps();
	ok($#apps, -1);
}

# declareTriead() failure (the success is tested with TrieadOwner)
{
	ok(!defined(eval {Triceps::App::declareTriead("zz", "t1");}));
	ok($@, qr/^Triceps application 'zz' is not found./);
}

# the getTrieads() is tested with TrieadOwner

# abort
{
	my ($t, $m);
	my $a1 = Triceps::App::make("a1");
	ok(ref $a1, "Triceps::App");

	ok(!$a1->isAborted);
	($t, $m) = $a1->getAborted();
	ok(!defined $t);
	ok(!defined $m);

	$a1->abortBy("some thread", "test msg");
	ok(Triceps::App::isAborted("a1"));
	($t, $m) = Triceps::App::getAborted("a1");
	ok($t, "some thread");
	ok($m, "test msg");

	# the second abort has no effect but doesn't fail either
	Triceps::App::abortBy("a1", "other thread", "other msg");

	eval { $a1->harvester(); };
	ok($@, qr/App 'a1' has been aborted by thread 'some thread': test msg/);

	$a1->drop();
}

# timeouts
{
	my $a1 = Triceps::App::make("a1");
	ok(ref $a1, "Triceps::App");

	$a1->setTimeout(100, 0); # set the frag timeout to 0, to not screw up the deadline
	$a1->setDeadline(time() -1);
	Triceps::App::setDeadline("a1", time() -1);

	$a1->declareTriead("tx");

	Triceps::Triead::startHere(
		makeApp => 0,
		app => "a1",
		thread => "t1",
		main => sub {
			my $opts = {};
			&Triceps::Opt::parse("t1 main", $opts, {@Triceps::Triead::opts}, @_);
			eval { $opts->{owner}->readyReady(); };
			ok($@, qr/Application 'a1' did not initialize within the deadline.\nThe lagging threads are:\n  tx: not defined/);
		},
		harvest => 0,
	);

	eval { $a1->setDeadline(time() -1); };
	ok($@, qr/Triceps application 'a1' deadline can not be changed after the thread creation/);

	$a1->drop();
}
{
	my $a1 = Triceps::App::make("a1");
	ok(ref $a1, "Triceps::App");

	$a1->setTimeout(0);
	Triceps::App::setTimeout("a1", 0);

	$a1->declareTriead("tx");

	Triceps::Triead::startHere(
		makeApp => 0,
		app => "a1",
		thread => "t1",
		main => sub {
			my $opts = {};
			&Triceps::Opt::parse("t1 main", $opts, {@Triceps::Triead::opts}, @_);
			eval { $opts->{owner}->readyReady(); };
			ok($@, qr/Application 'a1' did not initialize within the deadline.\nThe lagging threads are:\n  tx: not defined/);
		},
		harvest => 0,
	);

	eval { $a1->setTimeout(0); };
	ok($@, qr/Triceps application 'a1' deadline can not be changed after the thread creation/);

	$a1->drop();
}
{
	my $a1 = Triceps::App::make("a1");
	ok(ref $a1, "Triceps::App");

	$a1->setTimeout(30, 0);
	Triceps::App::setTimeout("a1", 30, 0);
	$a1->setDeadline(time() -1); # frag timeout can only move the deadline forward, so set it back

	eval { $a1->setTimeout(30, 0, 1); };
	ok($@, qr/Usage: Triceps::App::setTimeout\(app, main_to, \[frag_to\]\), too many argument/);

	$a1->refreshDeadline();
	Triceps::App::refreshDeadline("a1");

	$a1->declareTriead("tx");

	Triceps::Triead::startHere(
		makeApp => 0,
		app => "a1",
		thread => "t1",
		main => sub {
			my $opts = {};
			&Triceps::Opt::parse("t1 main", $opts, {@Triceps::Triead::opts}, @_);
			eval { $opts->{owner}->readyReady(); };
			ok($@, qr/Application 'a1' did not initialize within the deadline.\nThe lagging threads are:\n  tx: not defined/);
		},
		harvest => 0,
	);

	eval { $a1->setTimeout(0); };
	ok($@, qr/Triceps application 'a1' deadline can not be changed after the thread creation/);

	$a1->drop();
}

# shutdown and drain touch-test
{
	my $a1 = Triceps::App::make("a1");
	ok(ref $a1, "Triceps::App");

	# this thread is for waiting for readiness only
	Triceps::Triead::startHere(
		makeApp => 0,
		app => "a1",
		thread => "t2",
		main => sub {
			my $opts = {};
			&Triceps::Opt::parse("t2 main", $opts, {@Triceps::Triead::opts}, @_);
			my $to = $opts->{owner};
			my $app = $to->app();

			my $fa = $to->makeNexus(
				name => "nx1",
				labels => [
					one => $rt1,
				],
				import => "none",
			);

			Triceps::Triead::start(
				app => "a1",
				thread => "t1",
				main => sub {
					my $opts = {};
					&Triceps::Opt::parse("t1 main", $opts, {@Triceps::Triead::opts}, @_);
					my $to = $opts->{owner};
					$to->importNexus(
						from => "t2/nx1",
						import => "reader",
					);
					$to->readyReady();
					$to->mainLoop(); # will exit when the app is shut down
				},
			);

			Triceps::Triead::start(
				app => "a1",
				thread => "t3",
				main => sub {
					my $opts = {};
					&Triceps::Opt::parse("t3 main", $opts, {@Triceps::Triead::opts}, @_);
					my $to = $opts->{owner};
					$to->importNexus(
						from => "t2/nx1",
						import => "reader",
					);
					$to->readyReady();
					$to->mainLoop(); # will exit when the app is shut down
				},
			);

			$to->readyReady();

			ok(!$to->isRqDrain());
			$app->requestDrain();
			ok($to->isRqDrain());
			$app->waitDrain();
			ok($app->isDrained());
			$app->undrain();

			ok(!$to->isRqDrain());
			Triceps::App::requestDrain("a1");
			ok($to->isRqDrain());
			Triceps::App::waitDrain("a1");
			ok(Triceps::App::isDrained("a1"));
			Triceps::App::undrain("a1");

			ok(!$to->isRqDrain());
			$app->drain();
			ok($to->isRqDrain());
			$app->undrain();

			ok(!$to->isRqDrain());
			Triceps::App::drain("a1");
			ok($to->isRqDrain());
			Triceps::App::undrain("a1");

			ok(!$to->isRqDrain());
			$to->requestDrainShared();
			ok($to->isRqDrain());
			$to->waitDrain();
			ok($to->isDrained());
			$to->undrain();

			ok(!$to->isRqDrain());
			$to->requestDrainExclusive();
			ok(!$to->isRqDrain());
			$to->waitDrain();
			ok($to->isDrained());
			$to->undrain();

			ok(!$to->isRqDrain());
			$to->drainShared();
			ok($to->isRqDrain());
			ok($to->isDrained());
			$to->undrain();

			ok(!$to->isRqDrain());
			$to->drainExclusive();
			ok(!$to->isRqDrain());
			ok($to->isDrained());
			$to->undrain();

		},
		harvest => 0,
	);

	ok(!$a1->isShutdown());
	ok(!Triceps::App::isShutdown("a1"));
	ok(!Triceps::App::isDead("a1"));

	$a1->shutdown();
	ok($a1->isShutdown());
	Triceps::App::shutdown("a1");
	$a1->waitDead();
	ok($a1->isDead());

	$a1->harvester();
}

# pass around some data
{
	# this thread will read the final result
	my $res;
	Triceps::Triead::startHere(
		app => "a1",
		thread => "main",
		main => sub {
			my $opts = {};
			&Triceps::Opt::parse("main main", $opts, {@Triceps::Triead::opts}, @_);
			my $to = $opts->{owner};
			my $app = $to->app();

			my $faDummy = $to->makeNexus(
				name => "dummy",
				labels => [
					one => $rt1,
				],
				rowTypes => [
					rt1 => $rt1,
				],
				import => "none",
			);

			my $faIn = $to->makeNexus(
				name => "sink",
				labels => [
					one => $rt1,
				],
				import => "reader",
			);

			$to->markConstructed();

			Triceps::Triead::start(
				app => "a1",
				thread => "t1",
				main => sub {
					my $opts = {};
					&Triceps::Opt::parse("t1 main", $opts, {@Triceps::Triead::opts}, @_);
					my $to = $opts->{owner};
					my $faDummy = $to->importNexus(
						from => "main/dummy",
						import => "reader",
					);
					my $faOut = $to->makeNexus(
						name => "out",
						labels => [
							one => $faDummy->impRowType("rt1"),
						],
						import => "writer",
					);
					$to->readyReady();

					my $x = $to->nextXtrayNoWait();
					$to->unit()->makeHashCall($faOut->getLabel("one"), "OP_INSERT",
						b => $x,
					);
				},
			);

			Triceps::Triead::start(
				app => "a1",
				thread => "t2",
				main => sub {
					my $opts = {};
					&Triceps::Opt::parse("t2 main", $opts, {@Triceps::Triead::opts}, @_);
					my $to = $opts->{owner};
					my $faIn = $to->importNexus(
						from => "t1/out",
						import => "reader",
					);
					my $faOut = $to->makeNexus(
						name => "out",
						labels => [
							one => $faIn->getLabel("one"),
						],
						import => "writer",
					);
					$to->readyReady();

					while ($to->nextXtray()) { }
				},
			);

			Triceps::Triead::start(
				app => "a1",
				thread => "t3",
				main => sub {
					my $opts = {};
					&Triceps::Opt::parse("t3 main", $opts, {@Triceps::Triead::opts}, @_);
					my $to = $opts->{owner};
					my $faIn = $to->importNexus(
						from => "t2/out",
						import => "reader",
					);
					my $faOut = $to->importNexus(
						from => "main/sink",
						import => "writer",
					);
					$faIn->getLabel("one")->chain($faOut->getLabel("one"));
					$to->readyReady();

					$to->mainLoop();
				},
			);

			$faIn->getLabel("one")->chain($to->unit()->makeLabel($rt1, "lbtest", undef, sub {
				my $rop = $_[1]; 
				$res .= $rop->printP();
				$res .= "\n";
			}));
			$to->readyReady();

			$to->nextXtray();
			$to->app()->shutdown();
		},
	);
	ok($res, "sink.one OP_INSERT b=\"0\" \n");
	# app gets harvested in startHere()
}

# the situation when the same thread serves as both the 
# source and sink; and also tests shutdownFragment()
{
	my $tharvest;

	my $res;
	Triceps::Triead::startHere(
		app => "a1",
		thread => "t1",
		main => sub {
			my $opts = {};
			&Triceps::Opt::parse("t1 main", $opts, {@Triceps::Triead::opts}, @_);
			my $to = $opts->{owner};
			my $app = $to->app();

			# this is a little perverse but more convenient to run the
			# harvest in the new thread while the original thread
			# can call ok() without any races
			$tharvest = async {
				my $app = Triceps::App::find("a1");
				$app->harvester();
			};

			my $faOut = $to->makeNexus(
				name => "source",
				labels => [
					one => $rt1,
				],
				import => "writer",
			);

			my $faIn = $to->makeNexus(
				name => "sink",
				labels => [
					one => $rt1,
				],
				reverse => 1,
				import => "reader",
			);

			# XXX make a convenience method for making this kind of labels Label::make(from => ...)
			$faIn->getLabel("one")->chain($to->unit()->makeLabel($rt1, "lbtest", undef, sub {
				my $rop = $_[1]; 
				$res .= $rop->printP();
				$res .= "\n";
			}));

			$to->markConstructed();

			Triceps::Triead::start(
				app => "a1",
				thread => "t2",
				fragment => "f1",
				main => sub {
					my $opts = {};
					&Triceps::Opt::parse("t2 main", $opts, {@Triceps::Triead::opts}, @_);
					my $to = $opts->{owner};

					my $faIn = $to->importNexus(
						from => "t1/source",
						import => "reader",
					);
					my $faOut = $to->importNexus(
						from => "t1/sink",
						import => "writer",
					);
					$faIn->getLabel("one")->chain($faOut->getLabel("one"));
					$to->readyReady();

					$to->mainLoop();
				},
			);

			$to->readyReady();

			$to->drainExclusive();
			$to->unit()->makeHashCall($faOut->getLabel("one"), "OP_INSERT",
				b => 99,
			);
			$to->flushWriters(); # must not get stuck on an exclusive drain
			$to->waitDrain();
			# now our buffer must be populated
			
			$app->shutdownFragment("f1");

			# check that t2 exits and disappears from the App because
			# it's in a fragment, have to busy-wait
			while (1) {
				my %ts = $app->getTrieads();
				last if (!defined $ts{"t2"});
			}

			$to->undrain();
			# read the collected buffer
			while ($to->nextXtrayNoWait()) { }
		},
		harvest => 0,
	);
	$tharvest->join();
	ok($res, "sink.one OP_INSERT b=\"99\" \n");
}

# the topology check error, and also the error catch in the startHere during harvesting
{
	eval { Triceps::Triead::startHere(
		app => "a1",
		thread => "t1",
		main => sub {
			my $opts = {};
			&Triceps::Opt::parse("t1 main", $opts, {@Triceps::Triead::opts}, @_);
			my $to = $opts->{owner};

			my $faOut = $to->makeNexus(
				name => "source",
				labels => [
					one => $rt1,
				],
				import => "writer",
			);

			my $faIn = $to->makeNexus(
				name => "sink",
				labels => [
					one => $rt1,
				],
				import => "reader",
			);

			$to->markConstructed();

			Triceps::Triead::start(
				app => "a1",
				thread => "t2",
				fragment => "f1",
				main => sub {
					my $opts = {};
					&Triceps::Opt::parse("t2 main", $opts, {@Triceps::Triead::opts}, @_);
					my $to = $opts->{owner};

					my $faIn = $to->importNexus(
						from => "t1/source",
						import => "reader",
					);
					my $faOut = $to->importNexus(
						from => "t1/sink",
						import => "writer",
					);
					$to->readyReady();

				},
			);

			$to->readyReady();

		},
	); };
	ok($@, qr/^App 'a1' has been aborted by thread 't.': In application 'a1' detected an illegal direct loop:\n  thread 't1'\n  nexus 't1\/source'\n  thread 't2'\n  nexus 't1\/sink'\n  thread 't1'/);
}

# the scoped auto-drain, exclusive or with no wait
{
	my $res;
	Triceps::Triead::startHere(
		app => "a1",
		thread => "t1",
		main => sub {
			my $opts = {};
			&Triceps::Opt::parse("t1 main", $opts, {@Triceps::Triead::opts}, @_);
			my $to = $opts->{owner};
			my $app = $to->app();

			my $faOut = $to->makeNexus(
				name => "source",
				labels => [
					one => $rt1,
				],
				import => "writer",
			);

			my $faIn = $to->makeNexus(
				name => "sink",
				labels => [
					one => $rt1,
				],
				reverse => 1,
				import => "reader",
			);

			$to->readyReady();

			{
				# by TrieadOwner
				my $drain = Triceps::AutoDrain::makeSharedNoWait($to);
				ok(ref $drain, "Triceps::AutoDrain");
				# can't wait for draining itself because has a reader facet
				ok(!$app->isDrained());
			}
			{
				my $drain = Triceps::AutoDrain::makeExclusive($to);
				ok(ref $drain, "Triceps::AutoDrain");
				ok($app->isDrained());
			}
			{
				# intersperse to clear the drained condition
				# by App
				my $drain = Triceps::AutoDrain::makeSharedNoWait($app);
				ok(ref $drain, "Triceps::AutoDrain");
				ok(!$app->isDrained());
			}
			{
				my $drain = Triceps::AutoDrain::makeExclusiveNoWait($to);
				ok(ref $drain, "Triceps::AutoDrain");
				$drain->wait();
				ok($app->isDrained());
			}
			{
				# intersperse to clear the drained condition
				# by App name
				my $drain = Triceps::AutoDrain::makeSharedNoWait("a1");
				ok(ref $drain, "Triceps::AutoDrain");
				ok(!$app->isDrained());
			}

			# test the errors
			ok(! defined eval { Triceps::AutoDrain::makeShared("a2"); });
			ok($@, qr/^Triceps application 'a2' is not found/);
			ok(! defined eval { Triceps::AutoDrain::makeShared($to->get()); });
			ok($@, qr/^Triceps::AutoDrain::makeShared: argument has an incorrect magic for App or TrieadOwner/);
			ok(! defined eval { Triceps::AutoDrain::makeSharedNoWait("a2"); });
			ok($@, qr/^Triceps application 'a2' is not found/);
			ok(! defined eval { Triceps::AutoDrain::makeSharedNoWait($to->get()); });
			ok($@, qr/^Triceps::AutoDrain::makeSharedNoWait: argument has an incorrect magic for App or TrieadOwner/);
			ok(! defined eval { Triceps::AutoDrain::makeExclusive($app); });
			ok($@, qr/^Triceps::AutoDrain::makeExclusive\(\): wto has an incorrect magic for WrapTrieadOwnerPtr/);
			ok(! defined eval { Triceps::AutoDrain::makeExclusiveNoWait($app); });
			ok($@, qr/^Triceps::AutoDrain::makeExclusiveNoWait\(\): wto has an incorrect magic for WrapTrieadOwnerPtr/);
		},
	);
}

# the scoped auto-drain, shared with wait
{
	my $res;
	Triceps::Triead::startHere(
		app => "a1",
		thread => "t1",
		main => sub {
			my $opts = {};
			&Triceps::Opt::parse("t1 main", $opts, {@Triceps::Triead::opts}, @_);
			my $to = $opts->{owner};
			my $app = $to->app();

			# with no readers, this will be input-only
			my $faOut = $to->makeNexus(
				name => "source",
				labels => [
					one => $rt1,
				],
				import => "writer",
			);

			$to->readyReady();

			{
				my $drain = Triceps::AutoDrain::makeShared($to);
				ok(ref $drain, "Triceps::AutoDrain");
				ok($app->isDrained());
			}
			{
				my $drain = Triceps::AutoDrain::makeShared($app);
				ok(ref $drain, "Triceps::AutoDrain");
				ok($app->isDrained());
			}
			{
				my $drain = Triceps::AutoDrain::makeShared("a1");
				ok(ref $drain, "Triceps::AutoDrain");
				ok($app->isDrained());
			}
		},
	);
}

# the error propagation from the file interruption and joiner
{
	my $a1 = Triceps::App::make("a1");
	ok(ref $a1, "Triceps::App");

	my $to1 = Triceps::TrieadOwner->new("__test_fail__", undef, $a1, "t1", "frag1");
	ok(ref $to1, "Triceps::TrieadOwner");
	
	$to1->markReady(); # to allow the fragment shutdown to work

	eval { $a1->shutdownFragment("frag1"); };
	ok($@, qr/^Failed to interrupt the thread 't1' of application 'a1':\n  PerlTrieadJoin::interrupt test of error catching app 'a1' thread 't1'/);

	$to1->markDead();

	eval { $a1->harvester(); };
	ok($@, qr/^Failed to join the thread 't1' of application 'a1':\n  PerlTrieadJoin::join test of error catching app 'a1' thread 't1'/);
	$a1->drop();
}

# an error throwing from joiner (should never happen but still...)
{
	my $a1 = Triceps::App::make("a1");
	ok(ref $a1, "Triceps::App");

	my $realJoiner = $Triceps::_JOIN_TID;
	$Triceps::_JOIN_TID = sub { die "test error"; }; # will fail on an attempts to call

	my $to1 = Triceps::TrieadOwner->new(9999, undef, $a1, "t1", "");
	ok(ref $to1, "Triceps::TrieadOwner");
	$to1->markDead();

	eval { $a1->harvester(); };
	ok($@, qr/^Failed to join the thread 't1' of application 'a1':\n  test error/);

	$Triceps::_JOIN_TID = $realJoiner;
}
# check that the harvester completed its work before rethrowing
eval { Triceps::App::find("a1"); };
ok($@, qr/^Triceps application 'a1' is not found/);

# error catching in harvestOnce()
{
	my $a1 = Triceps::App::make("a1");
	ok(ref $a1, "Triceps::App");

	my $realJoiner = $Triceps::_JOIN_TID;
	$Triceps::_JOIN_TID = sub { die "test error"; }; # will fail on an attempts to call

	my $to1 = Triceps::TrieadOwner->new(9999, undef, $a1, "t1", "");
	ok(ref $to1, "Triceps::TrieadOwner");
	$to1->markDead();

	eval { $a1->harvestOnce(); };
	ok($@, qr/^Failed to join the thread 't1' of application 'a1':\n  test error/);

	$Triceps::_JOIN_TID = $realJoiner;

	$a1->harvester(); # dispose of the App
}

# an error throwing from joiner with also an abort report
{
	my $a1 = Triceps::App::make("a1");
	ok(ref $a1, "Triceps::App");

	my $realJoiner = $Triceps::_JOIN_TID;
	$Triceps::_JOIN_TID = sub { die "test error"; }; # will fail on an attempts to call

	my $to1 = Triceps::TrieadOwner->new(9999, undef, $a1, "t1", "");
	ok(ref $to1, "Triceps::TrieadOwner");
	$to1->abort("abort msg");

	eval { $a1->harvester(); };
	ok($@, qr/^Failed to join the thread 't1' of application 'a1':\n  test error at [^\n]*\n  Detected in the application 'a1' thread 't1' join.\nApp 'a1' has been aborted by thread 't1': abort msg/);

	$Triceps::_JOIN_TID = $realJoiner;
}
# check that the harvester completed its work before rethrowing
eval { Triceps::App::find("a1"); };
ok($@, qr/^Triceps application 'a1' is not found/);

# the app build
Triceps::App::build "a1", sub {
	Triceps::App::globalNexus(
		name => "types",
		rowTypes => [
			rt1 => $rt1,
		],
	);
	Triceps::Triead::start(
		app => $Triceps::App::name,
		thread => "t1",
		main => sub {
			my $opts = {};
			&Triceps::Opt::parse("t1 main", $opts, {@Triceps::Triead::opts}, @_);
			my $to = $opts->{owner};
			$to->importNexus(
				from => "global/types",
				import => "writer", # if importing just for the types, use "writer"!
			);
			$to->readyReady();
		},
	);
};
ok(!defined $Triceps::App::name);
ok(!defined $Triceps::App::app);
ok(!defined $Triceps::App::global);
eval { Triceps::App::find("a1"); };
ok($@, qr/^Triceps application 'a1' is not found/);

# the error catch in app build
eval {
	Triceps::App::build "a1", sub {
		Triceps::App::globalNexus(
			name => "types",
			rowTypes => [
				rt1 => $rt1,
			],
		);
		die "test error";
	};
};
ok($@, qr/App 'a1' has been aborted by thread 'global': test error/);
ok(!defined $Triceps::App::name);
ok(!defined $Triceps::App::app);
ok(!defined $Triceps::App::global);
eval { Triceps::App::find("a1"); };
ok($@, qr/^Triceps application 'a1' is not found/);

# test failures of all the references to a non-existing App
eval { Triceps::App::resolve(9); };
ok($@, qr/^Triceps::App::resolve: app is not an App reference nor a string/);
eval { Triceps::App::resolve($rt1); };
ok($@, qr/^Triceps::App::resolve: app has an incorrect magic for App/);
eval { Triceps::App::resolve("zzz"); };
ok($@, qr/^Triceps application 'zzz' is not found/);
eval { Triceps::App::drop("zzz"); };
ok($@, qr/^Triceps application 'zzz' is not found/);
eval { Triceps::App::isAborted("zzz"); };
ok($@, qr/^Triceps application 'zzz' is not found/);
eval { Triceps::App::getAborted("zzz"); };
ok($@, qr/^Triceps application 'zzz' is not found/);
eval { Triceps::App::abortBy("zzz", "t1", "msg"); };
ok($@, qr/^Triceps application 'zzz' is not found/);
eval { Triceps::App::setDeadline("zzz", 10); };
ok($@, qr/^Triceps application 'zzz' is not found/);
eval { Triceps::App::setTimeout("zzz", 10); };
ok($@, qr/^Triceps application 'zzz' is not found/);
eval { Triceps::App::refreshDeadline("zzz"); };
ok($@, qr/^Triceps application 'zzz' is not found/);
eval { Triceps::App::declareTriead("zzz", "t1"); };
ok($@, qr/^Triceps application 'zzz' is not found/);
eval { Triceps::App::getTrieads("zzz"); };
ok($@, qr/^Triceps application 'zzz' is not found/);
eval { Triceps::App::isDead("zzz"); };
ok($@, qr/^Triceps application 'zzz' is not found/);
eval { Triceps::App::isShutdown("zzz"); };
ok($@, qr/^Triceps application 'zzz' is not found/);
eval { Triceps::App::shutdown("zzz"); };
ok($@, qr/^Triceps application 'zzz' is not found/);
eval { Triceps::App::shutdownFragment("zzz", "xxx"); };
ok($@, qr/^Triceps application 'zzz' is not found/);
eval { Triceps::App::requestDrain("zzz"); };
ok($@, qr/^Triceps application 'zzz' is not found/);
eval { Triceps::App::waitDrain("zzz"); };
ok($@, qr/^Triceps application 'zzz' is not found/);
eval { Triceps::App::drain("zzz"); };
ok($@, qr/^Triceps application 'zzz' is not found/);
eval { Triceps::App::undrain("zzz"); };
ok($@, qr/^Triceps application 'zzz' is not found/);
eval { Triceps::App::isDrained("zzz"); };
ok($@, qr/^Triceps application 'zzz' is not found/);

