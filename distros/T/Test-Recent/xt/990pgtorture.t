#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Recent qw(recent);

BEGIN {
	unless ($ENV{THIS_IS_MARKF_YOU_BETCHA}) {
		plan skip_all => "postgres torture test only runs on Mark's laptop";
	}
}

use DBI;

my $dbh = DBI->connect("dbi:Pg:dbname=postgres;host=127.0.0.1", 'mark', '', {RaiseError => 1});

my $sth = $dbh->prepare(<<'SQL');
	SELECT now() as n;
SQL

for (1..5000) {
	$sth->execute();
	my ($time) = $sth->fetchrow_array;
	recent $time;
}

$sth = $dbh->prepare(<<'SQL');
	SELECT EXTRACT(epoch FROM current_timestamp)::integer as n;
SQL


for (1..5000) {
	local $Test::Recent::future_duration = 1;
	$sth->execute();
	my ($time) = $sth->fetchrow_array;
	recent $time;
}


done_testing;