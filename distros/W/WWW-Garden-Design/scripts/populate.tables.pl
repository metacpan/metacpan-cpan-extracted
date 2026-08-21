#!/usr/bin/env perl

use strict;
use warnings;

use WWW::Garden::Design::Import::Pg;
use WWW::Garden::Design::Import::SQLite;

# ----------------------------------

my($db_type) = $ENV{FLOWER_DB};

if ( (! $db_type) || ($db_type !~ /^(Pg|SQLite)$/) )
{
	print "Env var FLOWER_DB must match /^(Pg|SQLite)\$/\n";
}

print "Importing the $db_type flowers database. \n";

my($db);

if ($db_type eq 'Pg')
{
	$db = WWW::Garden::Design::Import::Pg -> new;
}
else
{
	$db = WWW::Garden::Design::Import::SQLite -> new;
}

$db -> populate_all_tables;
