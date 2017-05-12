#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 25;

use Test::Differences;
use English '-no_match_vars';

my $original_execute;
BEGIN {
	use_ok 'Test::Environment', qw{
		PostgreSQL
	};
	$original_execute = \&Test::Environment::Plugin::PostgreSQL::execute;
}


# set all PGenv variables
foreach my $pgname (qw( PGUSER PGPASSWORD PGDATABASE PGHOST PGPORT )) {
	$ENV{$pgname} = 1;
}

my @execute_args;
my $username = 'user1';
my $password = 'pass1';
my $database = 'db';
my $hostname = 'host';
my $port     = 'port';

diag 'set password, hostname, port';
psql(
	'password' => $password,
	'hostname' => $hostname,
	'port'     => $port,
);

ok(! exists $ENV{'PGUSER'},       'check if psql UNset the postres PGUSER');
is($ENV{'PGPASSWORD'}, $password, 'check if psql set the postres PGPASSWORD');
ok(! $ENV{'PGDATABASE'},          'check if psql UNset the postres PGDATABASE');
is($ENV{'PGHOST'},     $hostname, 'check if psql set the postres PGHOST');
is($ENV{'PGPORT'},     $port,     'check if psql set the postres PGPORT');


diag 'set username, database';
psql(
	'username' => $username,
	'database' => $database,
);

is($ENV{'PGUSER'},     $username, 'check if psql set the postres PGUSER');
ok(! exists $ENV{'PGPASSWORD'},   'check if psql UNset the postres PGPASSWORD');
is($ENV{'PGDATABASE'}, $database, 'check if psql set the postres PGDATABASE');
ok(! exists $ENV{'PGHOST'},       'check if psql UNset the postres PGHOST');
ok(! exists $ENV{'PGPORT'},       'check if psql UNset the postres PGPORT');

diag 'execution tests';
my @output = psql(
	'execution_path'  => '/tmp',
	'command'         => 'SELECT',
	'output_filename' => '/tmp/test.out',
	'switches'        => '-x',
);

eq_or_diff(
	[ @execute_args ],
	[ 'psql', '-x', '-o', '"/tmp/test.out"', '-c', 'SELECT;' ],
	'check call to execute'
);

is_deeply(
	[ @output ],
	[ map { $_."\n" }
		'psql -x -o "/tmp/test.out" -c SELECT;',
	],
	'check output'
);

is($ENV{'PGUSER'},     $username, 'postres PGUSER should be still set');
ok(! exists $ENV{'PGPASSWORD'},   'postres PGPASSWORD still UNset');

diag 'parsing of dbi_dsn';
psql(
	'dbi_dsn' => 'dbi:Pg:dbname=dsn_test;host=localhost;port=123',
);

ok(! exists $ENV{'PGUSER'},         'check if psql UNset the postres PGUSER');
ok(! exists $ENV{'PGPASSWORD'},     'check if psql UNset the postres PGPASSWORD');
is($ENV{'PGDATABASE'}, 'dsn_test',  'check if psql set the postres PGDATABASE');
is($ENV{'PGHOST'},     'localhost', 'check if psql set the postres PGHOST');
is($ENV{'PGPORT'},     '123',       'check if psql set the postres PGPORT');

# check mixing style
psql(
	'dbi_dsn' => 'dbi:Pg:dbname=dsn_test;host=localhost',
	'port'    => $port,	
);

ok(! exists $ENV{'PGUSER'},         'check if psql UNset the postres PGUSER');
ok(! exists $ENV{'PGPASSWORD'},     'check if psql UNset the postres PGPASSWORD');
is($ENV{'PGDATABASE'}, 'dsn_test',  'check if psql set the postres PGDATABASE');
is($ENV{'PGHOST'},     'localhost', 'check if psql set the postres PGHOST');
is($ENV{'PGPORT'},     $port,       'check if psql set the postres PGPORT');

no warnings 'redefine';

sub Test::Environment::Plugin::PostgreSQL::execute {
	push @execute_args, @_;
	unshift @_, 'echo';
	return $original_execute->(@_);
}
