#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The test for SimpleOrderedIndexType's interaction with threads.

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 5 };
use Triceps;
use Carp;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#########################
# common definitions

$u1 = Triceps::Unit->new("u1");
ok(ref $u1, "Triceps::Unit");

@def1 = (
	a => "uint8",
	b => "int32",
	c => "int64",
	d => "float64",
	e => "string",
);
$rt1 = Triceps::RowType->new( # used later
	@def1
);
ok(ref $rt1, "Triceps::RowType");

#########################
# very similar to SortedIndexTypeMt.t

# exporting a table type to another thread
{
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
				->addSubIndex("primary", 
					Triceps::SimpleOrderedIndex->new(
						b => "ASC",
						c => "ASC",
					)
				)
			;
			ok(ref $tt1, "Triceps::TableType");
			$tt1->initialize();

			my $faOut = $owner->makeNexus(
				name => "source",
				labels => [
					data => $rt1, # data to forward to the table
					dump => $rt1, # the row type doesn't matter
				],
				tableTypes => [
					tt1 => $tt1,
				],
				import => "writer",
			);

			my $faIn = $owner->makeNexus(
				name => "sink",
				labels => [
					out => $rt1, # normal table output
					dump => $rt1, # table's dump
				],
				reverse => 1,
				import => "reader",
			);

			$owner->markConstructed();

			Triceps::Triead::start(
				app => "a1",
				thread => "th1",
				main => sub {
					my $opts = {};
					&Triceps::Opt::parse("th1 main", $opts, {@Triceps::Triead::opts}, @_);
					my $owner = $opts->{owner};
					my $unit = $owner->unit();

					my $faSource = $owner->importNexus(
						from => "main/source",
						import => "reader",
					);
					my $faSink = $owner->importNexus(
						from => "main/sink",
						import => "writer",
					);

					my $tt1 = $faSource->impTableType("tt1");
					$tt1->initialize();
					my $t1 = $unit->makeTable($tt1, "t1");

					$faSource->getLabel("data")->chain($t1->getInputLabel());
					$t1->getOutputLabel()->chain($faSink->getLabel("out"));
					$t1->getDumpLabel()->chain($faSink->getLabel("dump"));

					$faSource->getLabel("dump")->makeChained("dump", undef, sub {
						$t1->dumpAll();
						#$t1->dump(); # this triggers an interesting error
					});

					$owner->readyReady();
					$owner->mainLoop();
					$owner->markDead();
				},
			);

			$faIn->getLabel("out")->makeChained("indata", undef, sub {
				$res .= $_[1]->printP() . "\n";
			});
			$faIn->getLabel("dump")->makeChained("indump", undef, sub {
				$res .= $_[1]->printP() . "\n";
			});

			my $odata = $faOut->getLabel("data");
			my $odump = $faOut->getLabel("dump");

			$owner->readyReady();

			# insert the rows in reverse order
			$unit->makeHashCall($odata, "OP_INSERT", b => 2, c => 2);
			$unit->makeHashCall($odata, "OP_INSERT", b => 2, c => 1);
			$unit->makeHashCall($odata, "OP_INSERT", b => 1, c => 2);
			$unit->makeHashCall($odata, "OP_INSERT", b => 1, c => 1);

			$unit->makeHashCall($odump, "OP_INSERT");
			$owner->flushWriters();

			Triceps::AutoDrain::makeExclusive($owner);
			while ($owner->nextXtrayNoWait()) { }
			$app->shutdown();
		},
	);
	#print $res;
	ok($res,
'sink.out OP_INSERT b="2" c="2" 
sink.out OP_INSERT b="2" c="1" 
sink.out OP_INSERT b="1" c="2" 
sink.out OP_INSERT b="1" c="1" 
sink.dump OP_INSERT b="1" c="1" 
sink.dump OP_INSERT b="1" c="2" 
sink.dump OP_INSERT b="2" c="1" 
sink.dump OP_INSERT b="2" c="2" 
');
}

