#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The example of queries in TQL (Triceps/Trivial Query Language)
# with multithreading.

#########################

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 7 };
use Triceps;
use Triceps::X::TestFeed qw(:all);
use Triceps::X::Tql;
use Triceps::X::ThreadedServer;
use Triceps::X::ThreadedClient;
use Carp;
ok(2); # If we made it this far, we're ok.

use strict;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#########################
# The simple App example.

package App1;
use Test;
use Carp;

sub appCoreT # (@opts)
{
	my $opts = {};
	&Triceps::Opt::parse("appCoreT", $opts, {@Triceps::Triead::opts,
		socketName => [ undef, \&Triceps::Opt::ck_mandatory ],
	}, @_);
	undef @_; # avoids a leak in threads module
	my $owner = $opts->{owner};
	my $app = $owner->app();
	my $unit = $owner->unit();

	# build the core logic

	my $rtTrade = Triceps::RowType->new(
		id => "int32", # trade unique id
		symbol => "string", # symbol traded
		price => "float64",
		size => "float64", # number of shares traded
	);

	my $ttWindow = Triceps::TableType->new($rtTrade)
		->addSubIndex("byId", 
			Triceps::SimpleOrderedIndex->new(id => "ASC")
		)
	;
	$ttWindow->initialize();

	# Represents the static information about a company.
	my $rtSymbol = Triceps::RowType->new(
		symbol => "string", # symbol name
		name => "string", # the official company name
		eps => "float64", # last quarter earnings per share
	);

	my $ttSymbol = Triceps::TableType->new($rtSymbol)
		->addSubIndex("bySymbol", 
			Triceps::SimpleOrderedIndex->new(symbol => "ASC")
		)
	;
	$ttSymbol->initialize();

	my $tWindow = $unit->makeTable($ttWindow, "tWindow");
	my $tSymbol = $unit->makeTable($ttSymbol, "tSymbol");

	# $tSymbol->getOutputLabel()->makeChained("dbgSymbol", undef, sub {
		# print "XXX ", $_[1]->printP(), "\n";
	# });

	# export the endpoints for TQL (it starts the listener)
	my $tql = Triceps::X::Tql->new(
		name => "tql",
		trieadOwner => $owner,
		socketName => $opts->{socketName},
		tables => [
			$tWindow,
			$tSymbol,
		],
		tableNames => [
			"window",
			"symbol",
		],
		inputs => [
			$tWindow->getInputLabel(),
			$tSymbol->getInputLabel(),
		],
		inputNames => [
			"window",
			"symbol",
		],
	);

	$owner->readyReady();

	$owner->mainLoop();
}

# the basic table dumps-subscribes
{
	my ($port, $thread) = Triceps::X::ThreadedServer::startServer(
			app => "appTql",
			main => \&appCoreT,
			port => 0,
			fork => -1, # create a thread, not a process
	);

	eval {
		Triceps::App::build "client", sub {
			my $appname = $Triceps::App::name;
			my $owner = $Triceps::App::global;

			# give the port in startClient
			my $client = Triceps::X::ThreadedClient->new(
				owner => $owner,
				totalTimeout => 10.,
				debug => 0,
			);

			$owner->readyReady();

			$client->startClient(c1 => $port);
			$client->expect(c1 => 'ready');

			$client->send(c1 => "subscribe,s1,symbol\n");
			$client->expect(c1 => 'subscribe,s1');

			$client->send(c1 => "d,symbol,OP_INSERT,ABC,ABC Corp,1.0\n");
			$client->expect(c1 => 'd,symbol,OP_INSERT,ABC,ABC Corp,1$');

			$client->send(c1 => "confirm,cf1\n");
			$client->expect(c1 => '^confirm,cf1,');

			# on this simple model the drain command is really impossible
			# to tell apart from confirm since evrything is synchronous anyway
			$client->send(c1 => "drain,dr1\n");
			$client->expect(c1 => '^drain,dr1,');

			$client->send(c1 => "dump,d2,symbol\n");
			$client->expect(c1 => '^dump,d2,symbol$');

			# this is dump with a duplicate subscription, so the
			# subscription part is really redundant
			$client->send(c1 => "dumpsub,ds3,symbol\n");
			$client->expect(c1 => '^dumpsub,ds3,symbol$');

			$client->send(c1 => "d,symbol,OP_INSERT,DEF,Defense Corp,2.0\n");
			$client->expect(c1 => 'd,symbol,OP_INSERT,DEF,Defense Corp,2$');

			# this one is not echoed, becuase not subscribed yet
			$client->send(c1 => "d,window,OP_INSERT,1,ABC,101,10\n");

			# this is dump with a new subscription
			$client->send(c1 => "dumpsub,ds4,window\n");
			$client->expect(c1 => '^dumpsub,ds4,window$');

			$client->send(c1 => "d,window,OP_INSERT,2,ABC,102,12\n");
			$client->expect(c1 => 'd,window,OP_INSERT,2,ABC,102,12$');

			$client->send(c1 => "shutdown\n");
			$client->expect(c1 => '__EOF__');

			#print $client->getTrace();
			ok($client->getTrace(), 
'> connect c1
c1|ready
> c1|subscribe,s1,symbol
c1|subscribe,s1,symbol
> c1|d,symbol,OP_INSERT,ABC,ABC Corp,1.0
c1|d,symbol,OP_INSERT,ABC,ABC Corp,1
> c1|confirm,cf1
c1|confirm,cf1,,,
> c1|drain,dr1
c1|drain,dr1,,,
> c1|dump,d2,symbol
c1|startdump,d2,symbol
c1|d,symbol,OP_INSERT,ABC,ABC Corp,1
c1|dump,d2,symbol
> c1|dumpsub,ds3,symbol
c1|startdump,ds3,symbol
c1|d,symbol,OP_INSERT,ABC,ABC Corp,1
c1|dumpsub,ds3,symbol
> c1|d,symbol,OP_INSERT,DEF,Defense Corp,2.0
c1|d,symbol,OP_INSERT,DEF,Defense Corp,2
> c1|d,window,OP_INSERT,1,ABC,101,10
> c1|dumpsub,ds4,window
c1|startdump,ds4,window
c1|d,window,OP_INSERT,1,ABC,101,10
c1|dumpsub,ds4,window
> c1|d,window,OP_INSERT,2,ABC,102,12
c1|d,window,OP_INSERT,2,ABC,102,12
> c1|shutdown
c1|shutdown,,,,
c1|__EOF__
');
		};
	};

	# let the errors from the server to be printed first
	$thread->join();
	die $@ if $@;
}

# the simple query subscription
{
	my ($port, $thread) = Triceps::X::ThreadedServer::startServer(
			app => "appTql",
			main => \&appCoreT,
			port => 0,
			fork => -1, # create a thread, not a process
	);

	eval {
		Triceps::App::build "client", sub {
			my $appname = $Triceps::App::name;
			my $owner = $Triceps::App::global;

			# give the port in startClient
			my $client = Triceps::X::ThreadedClient->new(
				owner => $owner,
				totalTimeout => 10.,
				debug => 0,
			);

			$owner->readyReady();

			$client->startClient(c1 => $port);
			$client->expect(c1 => 'ready');

			$client->send(c1 => "d,symbol,OP_INSERT,ABC,ABC Corp,1.0\n");
			# no expect, because not subscribed yet

			$client->send(c1 => "querysub,q1,query1,{read table symbol}{print tokenized 0}\n");
			$client->expect(c1 => '^d,query1,OP_INSERT,ABC,ABC Corp,1$');
			$client->expect(c1 => '^querysub,q1,query1');

			$client->send(c1 => "d,symbol,OP_INSERT,DEF,Defense Corp,2.0\n");
			$client->expect(c1 => '^d,query1,OP_INSERT,DEF,Defense Corp,2$');

			# do another one, with a projection, filter, and tokenized format in implicit print
			$client->send(c1 => "querysub,q2,query2,"
				. '{read table symbol}'
				. '{where istrue {$%symbol =~ /^A/}}'
				. '{project fields {symbol eps}}'
				. "\n");
			$client->expect(c1 => '^t,query2,query2 OP_INSERT symbol="ABC" eps="1" $');
			$client->expect(c1 => '^querysub,q2,query2');

			$client->send(c1 => "d,symbol,OP_INSERT,AAA,Absolute Auto Analytics Inc,3.0\n");
			# the parallel results will go in the order they were subscribed, due to the
			# chaining order in the model
			$client->expect(c1 => '^d,query1,OP_INSERT,AAA,Absolute Auto Analytics Inc,3$');
			$client->expect(c1 => '^t,query2,query2 OP_INSERT symbol="AAA" eps="3" $');

			$client->send(c1 => "d,symbol,OP_DELETE,DEF,Defense Corp,2.0\n");
			$client->expect(c1 => '^d,query1,OP_DELETE,DEF,Defense Corp,2$');

			$client->send(c1 => "shutdown\n");
			$client->expect(c1 => '__EOF__');

			#print $client->getTrace();
			ok($client->getTrace(), 
'> connect c1
c1|ready
> c1|d,symbol,OP_INSERT,ABC,ABC Corp,1.0
> c1|querysub,q1,query1,{read table symbol}{print tokenized 0}
c1|d,query1,OP_INSERT,ABC,ABC Corp,1
c1|querysub,q1,query1
> c1|d,symbol,OP_INSERT,DEF,Defense Corp,2.0
c1|d,query1,OP_INSERT,DEF,Defense Corp,2
> c1|querysub,q2,query2,{read table symbol}{where istrue {$%symbol =~ /^A/}}{project fields {symbol eps}}
c1|t,query2,query2 OP_INSERT symbol="ABC" eps="1" 
c1|querysub,q2,query2
> c1|d,symbol,OP_INSERT,AAA,Absolute Auto Analytics Inc,3.0
c1|d,query1,OP_INSERT,AAA,Absolute Auto Analytics Inc,3
c1|t,query2,query2 OP_INSERT symbol="AAA" eps="3" 
> c1|d,symbol,OP_DELETE,DEF,Defense Corp,2.0
c1|d,query1,OP_DELETE,DEF,Defense Corp,2
> c1|shutdown
c1|shutdown,,,,
c1|__EOF__
');
		};
	};

	# let the errors from the server to be printed first
	$thread->join();
	die $@ if $@;
}

# the query with join
{
	my ($port, $thread) = Triceps::X::ThreadedServer::startServer(
			app => "appTql",
			main => \&appCoreT,
			port => 0,
			fork => -1, # create a thread, not a process
	);

	eval {
		Triceps::App::build "client", sub {
			my $appname = $Triceps::App::name;
			my $owner = $Triceps::App::global;

			# give the port in startClient
			my $client = Triceps::X::ThreadedClient->new(
				owner => $owner,
				totalTimeout => 10.,
				debug => 0,
			);

			$owner->readyReady();

			$client->startClient(c1 => $port);
			$client->expect(c1 => 'ready');

			# fill the symbols
			$client->send(c1 => "d,symbol,OP_INSERT,ABC,ABC Corp,2.0\n");
			$client->send(c1 => "d,symbol,OP_INSERT,DEF,Defense Corp,2.0\n");
			$client->send(c1 => "d,symbol,OP_INSERT,AAA,Absolute Auto Analytics Inc,3.0\n");
			# no expect, because not subscribed yet

			# send some trades too
			$client->send(c1 => "d,window,OP_INSERT,1,AAA,12,100\n");
			# no expect, because not subscribed yet

			# the query with join
			$client->send(c1 => "querysub,q1,query1,"
				. '{read table window}'
				. '{join table symbol byLeft {symbol} type left}'
				. "\n");
			$client->expect(c1 => '^querysub,q1,query1');

			# more trades
			$client->send(c1 => "d,window,OP_INSERT,2,ABC,13,100\n");
			$client->expect(c1 => '^t,query1');
			$client->send(c1 => "d,window,OP_INSERT,3,AAA,11,200\n");
			$client->expect(c1 => '^t,query1');

			# change a symbol
			$client->send(c1 => "d,symbol,OP_DELETE,AAA,Absolute Auto Analytics Inc,3.0\n");
			$client->send(c1 => "d,symbol,OP_INSERT,AAA,Alcoholic Abstract Aliens,3.0\n");
			# since the join is LookupJoin, produces no output

			# but on the next trade will use the new symbol info
			# (and magically fill the rest of the fields from primary key on DELETE)
			$client->send(c1 => "d,window,OP_DELETE,1\n");
			$client->expect(c1 => '^t,query1');

			# a weird query that doesn't make a whole lot of sense
			# but tests the join of the same table twice in the
			# same query
			$client->send(c1 => "querysub,q2,query2,"
				. '{read table window}'
				. '{join table symbol byLeft {symbol} type left}'
				. '{join table symbol byLeft {eps} type left rightFields {symbol/symbol2}}'
				. "\n");
			$client->expect(c1 => '^querysub,q2,query2');

			$client->send(c1 => "shutdown\n");
			$client->expect(c1 => '__EOF__');

			#print $client->getTrace();
			ok($client->getTrace(), 
'> connect c1
c1|ready
> c1|d,symbol,OP_INSERT,ABC,ABC Corp,2.0
> c1|d,symbol,OP_INSERT,DEF,Defense Corp,2.0
> c1|d,symbol,OP_INSERT,AAA,Absolute Auto Analytics Inc,3.0
> c1|d,window,OP_INSERT,1,AAA,12,100
> c1|querysub,q1,query1,{read table window}{join table symbol byLeft {symbol} type left}
c1|t,query1,query1 OP_INSERT id="1" symbol="AAA" price="12" size="100" name="Absolute Auto Analytics Inc" eps="3" 
c1|querysub,q1,query1
> c1|d,window,OP_INSERT,2,ABC,13,100
c1|t,query1,query1 OP_INSERT id="2" symbol="ABC" price="13" size="100" name="ABC Corp" eps="2" 
> c1|d,window,OP_INSERT,3,AAA,11,200
c1|t,query1,query1 OP_INSERT id="3" symbol="AAA" price="11" size="200" name="Absolute Auto Analytics Inc" eps="3" 
> c1|d,symbol,OP_DELETE,AAA,Absolute Auto Analytics Inc,3.0
> c1|d,symbol,OP_INSERT,AAA,Alcoholic Abstract Aliens,3.0
> c1|d,window,OP_DELETE,1
c1|t,query1,query1 OP_DELETE id="1" symbol="AAA" price="12" size="100" name="Alcoholic Abstract Aliens" eps="3" 
> c1|querysub,q2,query2,{read table window}{join table symbol byLeft {symbol} type left}{join table symbol byLeft {eps} type left rightFields {symbol/symbol2}}
c1|t,query2,query2 OP_INSERT id="2" symbol="ABC" price="13" size="100" name="ABC Corp" eps="2" symbol2="ABC" 
c1|t,query2,query2 OP_INSERT id="2" symbol="ABC" price="13" size="100" name="ABC Corp" eps="2" symbol2="DEF" 
c1|t,query2,query2 OP_INSERT id="3" symbol="AAA" price="11" size="200" name="Alcoholic Abstract Aliens" eps="3" symbol2="AAA" 
c1|querysub,q2,query2
> c1|shutdown
c1|shutdown,,,,
c1|__EOF__
');
		};
	};

	# let the errors from the server to be printed first
	$thread->join();
	die $@ if $@;
}

# test that the addInput() and addNamedInput() work, without actually instantating
# the server
{
	my $uTrades = Triceps::Unit->new("uTrades");

	my $rtTrade = Triceps::RowType->new(
		id => "int32", # trade unique id
		symbol => "string", # symbol traded
		price => "float64",
		size => "float64", # number of shares traded
	);

	my $lb1 = $uTrades->makeDummyLabel($rtTrade, "lb1");
	my $lb2 = $uTrades->makeDummyLabel($rtTrade, "lb2");
	my $lb3 = $uTrades->makeDummyLabel($rtTrade, "lb3");
	my $lb4 = $uTrades->makeDummyLabel($rtTrade, "lb4");

	# The information about tables, for querying.
	my $tql = Triceps::X::Tql->new(name => "tql");
	$tql->addNamedInput(
		first => $lb1,
		second => $lb2,
	);
	$tql->addInput(
		$lb3,
		$lb4,
	);
	my @inputs = @{$tql->{inputs}};
	my @inputNames = @{$tql->{inputNames}};

	ok(join(',', map {$_->getName()} @inputs), "lb1,lb2,lb3,lb4");
	ok(join(',', @inputNames), "first,second,lb3,lb4");
}

# check that everything completed and not died
ok(1);

# XXX test the error handling
