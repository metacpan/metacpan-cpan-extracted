#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT; # dummy namespace

# Test the internal dumping code for systems that do not have sqlite3 in the PATH

my @db_creation_text = (
    q(BEGIN TRANSACTION;),
    q(CREATE TABLE bar (bar_id integer PRIMARY KEY, some_data varchar);),
    q(INSERT INTO bar VALUES(1,'Hi there');),
    q(INSERT INTO bar VALUES(2,'blahblah');),
    q(INSERT INTO bar VALUES(3,null);),
    q(CREATE TABLE foo (foo_id_1 integer, foo_id_2 integer, PRIMARY KEY (foo_id_1, foo_id_2));),
    q(INSERT INTO foo VALUES(1,2);),
    q(INSERT INTO foo VALUES(2,3);),
    q(INSERT INTO foo VALUES(4,5);),
    q(COMMIT;),
);
if (defined URT::DataSource::SomeSQLite->_singleton_object->_get_foreign_key_setting) {
    # If DBD::SQLite supports foreign keys, then the dump file will have this line
    unshift @db_creation_text, q(PRAGMA foreign_keys = OFF;);
    plan tests => 21;
} else {
    plan tests => 20;
}

my $dump_file = URT::DataSource::SomeSQLite->_data_dump_path();
my $fh = IO::File->new($dump_file, 'w');
ok($fh, "Opened dump file for writing");
unless ($fh) {
    diag "Can't open $dump_file for writing: $!";
}
$fh->print(join("\n", @db_creation_text), "\n");
$fh->close();

{
    local $ENV{'PATH'} = '/nonexistent';

    # These _should_ ensure that we'll re-initialize the DB from the dump
    my $db_file = URT::DataSource::SomeSQLite->server;
    unlink($db_file);
    URT::DataSource::SomeSQLite->disconnect;
    note("initializing DB");
    URT::DataSource::SomeSQLite->_init_database();

    note("db file is $db_file");
    my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
    ok($dbh, "got a handle");
    isa_ok($dbh, 'UR::DBI::db', 'Returned handle is the proper class');
    
    # Try getting some data
    my @row = $dbh->selectrow_array('select * from foo where foo_id_1 = 1');
    ok(($row[0] == 1 and $row[1] == 2), 'Got row from table foo');

    @row = $dbh->selectrow_array('select * from foo where foo_id_1 = 2');
    ok(($row[0] == 2 and $row[1] == 3), 'Got row from table foo');

    @row = $dbh->selectrow_array('select * from bar where bar_id = 1');
    ok(($row[0] == 1 and $row[1] eq 'Hi there'), 'Got row from table bar');

    @row = $dbh->selectrow_array('select * from bar where bar_id = 3');
    ok(($row[0] == 3 and !defined($row[1])) , 'Got row from table bar');

    # truncate the dump file to 0 bytes
    {   my $fh = IO::File->new($dump_file, '>');
        $fh->close();
    }

    ok(URT::DataSource::SomeSQLite->_singleton_object->_dump_db_to_file_internal(), 'Call force re-creation of the dump file');

    ok((-r $dump_file and -s $dump_file), 'Re-created dump file');
    $fh = IO::File->new($dump_file);
    ok($fh, "Opened dump file for reading");

    for(my $i = 0; $i < @db_creation_text; $i++) {
        my $line = $fh->getline();
        chomp $line;
        is($line, $db_creation_text[$i], 'DB dump test line ' . ($i+1) . ' is correct');
    }
}


