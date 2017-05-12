#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT; # dummy namespace

use File::Temp;
use File::Spec;

my $sqlite_dir = File::Temp::tempdir( CLEANUP => 1 );

create_dir_with_schema_files($sqlite_dir);
define_datasource($sqlite_dir);

my $ds = URT::DataSource::SQLiteDir->get();
my $person_index = $ds->get_unique_index_details_from_data_dictionary('main','person');
my $other_index = $ds->get_unique_index_details_from_data_dictionary('other','person');

is(scalar(keys(%$person_index)), 1, 'found only the index for main schema');
is(scalar(keys(%$other_index)), 1, 'found only the index for other schema');

is((keys(%$person_index))[0], 'main_person_name_idx', 'found proper index for person table');
is((keys(%$other_index))[0], 'other_person_name_idx', 'found proper index for other table');

sub create_dir_with_schema_files {
    my $sqlite_dir = shift;
    my $main_schema_file = File::Spec->catfile($sqlite_dir, 'main.sqlite3');
    my $main_dbh = DBI->connect("dbi:SQLite:dbname=$main_schema_file",'','')
            || die "Can't create main schema file in dir $sqlite_dir: ".$DBI::errstr;
    $main_dbh->do('create table person (person_id integer primary key, name varchar)');
    $main_dbh->do("create unique index main_person_name_idx ON person (name)");

    my $other_schema_file = File::Spec->catfile($sqlite_dir, 'other.sqlite3');
    my $other_dbh = DBI->connect("dbi:SQLite:dbname=$other_schema_file",'','')
            || die "Can't create other schema file in dir $sqlite_dir: ".$DBI::errstr;
    $other_dbh->do('create table person (person_id integer primary_key, name varchar)');
    $other_dbh->do("create unique index other_person_name_idx ON person (name)");
}

sub define_datasource {
    my $sqlite_dir = shift;

    UR::Object::Type->define(
        class_name => 'URT::DataSource::SQLiteDir',
        is => 'UR::DataSource::SQLite',
        has_constant => [
            server => { value => $sqlite_dir },
        ],
    );
}

