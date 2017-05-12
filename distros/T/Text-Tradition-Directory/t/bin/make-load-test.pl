#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use File::Temp;

use Text::Tradition;
use Text::Tradition::Directory;

## We're loading the besoin data, and dumping the backend db rows into
## a .sql file for load testing (testing of data loading, not the
## other sort)
my $sql = 't/data/speed_test_load.sql';
my $uuid = 'load-test';

print "Loading t/data/besoin.xml and storing it in $sql ...\n";

## Load tradition data:
my $tradition = Text::Tradition->new(
   'input' => 'Self',
   'file'  => "t/data/besoin.xml"
);
$tradition->add_stemma(dotfile => "t/data/besoin.dot");

## save to db:
my $fh = File::Temp->new();
my $file = $fh->filename;
$fh->close;

my $dsn = "dbi:SQLite:$file";
my $dir = Text::Tradition::Directory->new(
    dsn => $dsn,
    extra_args => { create => 1 },
);
my $scope = $dir->new_scope;
$dir->store($uuid, $tradition);

## out to SQL file:
`sqlite3 $file ".dump" > $sql`;

print "$sql updated,\n";
