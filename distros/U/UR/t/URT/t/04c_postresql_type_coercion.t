#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";

use URT; # dummy namespace

# This tests the PostgreSQL data source's ability to filter a date-type column
# with "like" and a string.

UR::Object::Type->define(
    class_name => 'URT::A',
    id_by => [
        a_id => { is => 'String' },
    ],
    has => [
        creation_date => { is => 'DateTime' },
        some_event_time => { is => 'Timestamp' },
    ],
    table_name => 'A',
    data_source => 'URT::DataSource::SomePostgreSQL',
);

{
    my $sql = '';
    URT::DataSource::SomePostgreSQL->add_observer(
        aspect => 'query',
        callback => sub {
            my $ds = shift;
            my $aspect = shift;
            $sql = shift;
            $sql =~ s/\n/ /g;       # Convert newlines to spaces
            $sql =~ s/^\s+|\s+$//g; # Remove leading and trailing whitespace

            # We need to die here so it dosen't try to connect to this
            # fake oracle database, which happens right after the SQL is
            # constructed
            die "escape\n";
        }
    );

    sub get_sql {
        my $code = shift;
        $sql = '';
        eval { $code->() };
        unless ($@ =~ m/escape/) {
            ok(0, "Did not capture the SQL, got $@");
            exit;
        }
        return $sql;
    }
}

is(get_sql(sub { URT::A->get('creation_date like' => '1999-12-31%') }),
    q{select A.a_id, A.creation_date, A.some_event_time from A where to_char(A.creation_date, 'YYYY-MM-DD HH24:MI:SS') like ? escape E'\\\\' order by A.a_id COLLATE "C"},
    "to_char coercion on DateTime column");

is(get_sql(sub { URT::A->get('some_event_time like' => '1970-01-01%') }),
    q{select A.a_id, A.creation_date, A.some_event_time from A where to_char(A.some_event_time, 'YYYY-MM-DD HH24:MI:SS.US') like ? escape E'\\\\' order by A.a_id COLLATE "C"},
    "to_char coercion on Timestamp column");

is(get_sql(sub { URT::A->get('some_event_time like' => '1970-01-01%', -order => ['-id']) }),
    q{select A.a_id, A.creation_date, A.some_event_time from A where to_char(A.some_event_time, 'YYYY-MM-DD HH24:MI:SS.US') like ? escape E'\\\\' order by A.a_id COLLATE "C" DESC},
    "to_char coercion on Timestamp column");
