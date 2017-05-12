#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The example of queries in TQL (Triceps/Trivial Query Language).

#########################

use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 4 };
use Triceps;
use Triceps::X::TestFeed qw(:all);
use Carp;
ok(1); # If we made it this far, we're ok.

use strict;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#########################
# Common Triceps types.

# The basic table type to be used for querying.
# Represents the trades reports.
our $rtTrade = Triceps::RowType->new(
	id => "int32", # trade unique id
	symbol => "string", # symbol traded
	price => "float64",
	size => "float64", # number of shares traded
);

our $ttWindow = Triceps::TableType->new($rtTrade)
	->addSubIndex("bySymbol", 
		Triceps::SimpleOrderedIndex->new(symbol => "ASC")
			->addSubIndex("last2",
				Triceps::IndexType->newFifo(limit => 2)
			)
	)
;
$ttWindow->initialize();

# Represents the static information about a company.
our $rtSymbol = Triceps::RowType->new(
	symbol => "string", # symbol name
	name => "string", # the official company name
	eps => "float64", # last quarter earnings per share
);

our $ttSymbol = Triceps::TableType->new($rtSymbol)
	->addSubIndex("bySymbol", 
		Triceps::IndexType->newHashed(key => [ "symbol" ])
	)
;
$ttSymbol->initialize();

################################################################
# The Tql object built in one call.

sub runTqlQuery1
{

my $uTrades = Triceps::Unit->new("uTrades");
my $tWindow = $uTrades->makeTable($ttWindow, "tWindow");
my $tSymbol = $uTrades->makeTable($ttSymbol, "tSymbol");

# The information about tables, for querying.
my $tql = Triceps::X::Tql->new(
	name => "tql",
	tables => [
		$tWindow,
		$tSymbol,
	],
);

my %dispatch;
$dispatch{$tWindow->getName()} = $tWindow->getInputLabel();
$dispatch{$tSymbol->getName()} = $tSymbol->getInputLabel();
$dispatch{"query"} = sub { $tql->query(@_); };
$dispatch{"exit"} = \&Triceps::X::SimpleServer::exitFunc;

# calls Triceps::X::SimpleServer::startServer(0, \%dispatch);
Triceps::X::DumbClient::run(\%dispatch);
};

# the same input and result gets reused mutiple times
my @inputQuery1 = (
	"tSymbol,OP_INSERT,AAA,Absolute Auto Analytics Inc,0.5\n",
	"tWindow,OP_INSERT,1,AAA,10,10\n",
	"tWindow,OP_INSERT,3,AAA,20,20\n",
	"tWindow,OP_INSERT,5,AAA,30,30\n",
	"query,{read table tSymbol}\n",
	"query,{read table tWindow} {project fields {symbol price}} {print tokenized 0}\n",
	"query,{read table tWindow} {project fields {symbol price}}\n",
	"query,{read table tWindow} {join table tSymbol rightIdxPath bySymbol byLeft {symbol}}\n",
	"query,{read table tWindow} {join table tSymbol byLeft {symbol}}\n",
	"query,{read table tWindow} {where istrue {\$%price == 20}}\n",
);
my $expectQuery1 = 
'> tSymbol,OP_INSERT,AAA,Absolute Auto Analytics Inc,0.5
> tWindow,OP_INSERT,1,AAA,10,10
> tWindow,OP_INSERT,3,AAA,20,20
> tWindow,OP_INSERT,5,AAA,30,30
> query,{read table tSymbol}
> query,{read table tWindow} {project fields {symbol price}} {print tokenized 0}
> query,{read table tWindow} {project fields {symbol price}}
> query,{read table tWindow} {join table tSymbol rightIdxPath bySymbol byLeft {symbol}}
> query,{read table tWindow} {join table tSymbol byLeft {symbol}}
> query,{read table tWindow} {where istrue {$%price == 20}}
query OP_INSERT symbol="AAA" name="Absolute Auto Analytics Inc" eps="0.5" 
+EOD,OP_NOP,query
query,OP_INSERT,AAA,20
query,OP_INSERT,AAA,30
+EOD,OP_NOP,query
query OP_INSERT symbol="AAA" price="20" 
query OP_INSERT symbol="AAA" price="30" 
+EOD,OP_NOP,query
query OP_INSERT id="3" symbol="AAA" price="20" size="20" name="Absolute Auto Analytics Inc" eps="0.5" 
query OP_INSERT id="5" symbol="AAA" price="30" size="30" name="Absolute Auto Analytics Inc" eps="0.5" 
+EOD,OP_NOP,query
query OP_INSERT id="3" symbol="AAA" price="20" size="20" name="Absolute Auto Analytics Inc" eps="0.5" 
query OP_INSERT id="5" symbol="AAA" price="30" size="30" name="Absolute Auto Analytics Inc" eps="0.5" 
+EOD,OP_NOP,query
query OP_INSERT id="3" symbol="AAA" price="20" size="20" 
+EOD,OP_NOP,query
';

setInputLines(@inputQuery1);
&runTqlQuery1();
#print &getResultLines();
ok(&getResultLines(), $expectQuery1);

################################################################
# Same as Query1 but initializes the Tql object piecemeal.
# (the list of queries used is somewhat reduced).

sub runTqlQuery2
{

my $uTrades = Triceps::Unit->new("uTrades");
my $tWindow = $uTrades->makeTable($ttWindow, "tWindow");
my $tSymbol = $uTrades->makeTable($ttSymbol, "tSymbol");

# The information about tables, for querying.
my $tql = Triceps::X::Tql->new(name => "tql");
$tql->addNamedTable(
	window => $tWindow,
	symbol => $tSymbol,
);
# add 2nd time, with different names
$tql->addTable(
	$tWindow,
	$tSymbol,
);
$tql->initialize();

my %dispatch;
$dispatch{$tWindow->getName()} = $tWindow->getInputLabel();
$dispatch{$tSymbol->getName()} = $tSymbol->getInputLabel();
$dispatch{"query"} = sub { $tql->query(@_); };
$dispatch{"exit"} = \&Triceps::X::SimpleServer::exitFunc;

Triceps::X::DumbClient::run(\%dispatch);
};

# the same input and result gets reused mutiple times
my @inputQuery2 = (
	"tSymbol,OP_INSERT,AAA,Absolute Auto Analytics Inc,0.5\n",
	"tWindow,OP_INSERT,1,AAA,10,10\n",
	"tWindow,OP_INSERT,3,AAA,20,20\n",
	"tWindow,OP_INSERT,5,AAA,30,30\n",
	"query,{read table tSymbol}\n",
	"query,{read table tWindow}\n",
	"query,{read table symbol}\n",
	"query,{read table window}\n",
);
my $expectQuery2 = 
'> tSymbol,OP_INSERT,AAA,Absolute Auto Analytics Inc,0.5
> tWindow,OP_INSERT,1,AAA,10,10
> tWindow,OP_INSERT,3,AAA,20,20
> tWindow,OP_INSERT,5,AAA,30,30
> query,{read table tSymbol}
> query,{read table tWindow}
> query,{read table symbol}
> query,{read table window}
query OP_INSERT symbol="AAA" name="Absolute Auto Analytics Inc" eps="0.5" 
+EOD,OP_NOP,query
query OP_INSERT id="3" symbol="AAA" price="20" size="20" 
query OP_INSERT id="5" symbol="AAA" price="30" size="30" 
+EOD,OP_NOP,query
query OP_INSERT symbol="AAA" name="Absolute Auto Analytics Inc" eps="0.5" 
+EOD,OP_NOP,query
query OP_INSERT id="3" symbol="AAA" price="20" size="20" 
query OP_INSERT id="5" symbol="AAA" price="30" size="30" 
+EOD,OP_NOP,query
';

setInputLines(@inputQuery2);
&runTqlQuery2();
#print &getResultLines();
ok(&getResultLines(), $expectQuery2);

################################################################
# Same as Query1 but initializes the Tql object with explicit names.
# (the list of queries used is shared with Query2).

sub runTqlQuery3
{

my $uTrades = Triceps::Unit->new("uTrades");
my $tWindow = $uTrades->makeTable($ttWindow, "tWindow");
my $tSymbol = $uTrades->makeTable($ttSymbol, "tSymbol");

# The information about tables, for querying.
my $tql = Triceps::X::Tql->new(
	name => "tql",
	tables => [
		$tWindow,
		$tSymbol,
		$tWindow,
		$tSymbol,
	],
	tableNames => [
		"window",
		"symbol",
		$tWindow->getName(),
		$tSymbol->getName(),
	],
);

my %dispatch;
$dispatch{$tWindow->getName()} = $tWindow->getInputLabel();
$dispatch{$tSymbol->getName()} = $tSymbol->getInputLabel();
$dispatch{"query"} = sub { $tql->query(@_); };
$dispatch{"exit"} = \&Triceps::X::SimpleServer::exitFunc;

Triceps::X::DumbClient::run(\%dispatch);
};

setInputLines(@inputQuery2);
&runTqlQuery3();
#print &getResultLines();
ok(&getResultLines(), $expectQuery2);

