#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 80;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT; # dummy namespace


my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
ok($dbh, "got a handle");
isa_ok($dbh, 'UR::DBI::db', 'Returned handle is the proper class');

&setup_schema($dbh);

&test_foreign_key_handling();

&test_column_details();



sub test_column_details {
    my $schema = URT::DataSource::SomeSQLite->default_owner;
    my $sth = URT::DataSource::SomeSQLite->get_column_details_from_data_dictionary('',$schema,'inline','%');

    my @results;
    while (my $row = $sth->fetchrow_hashref) {
        my $saved_row;
        foreach my $key ( qw( TABLE_NAME COLUMN_NAME DATA_TYPE COLUMN_SIZE NULLABLE COLUMN_DEF ) ) {
            $saved_row->{$key} = $row->{$key};
        }
        push @results, $saved_row;
    }
    @results = sort { $a->{'COLUMN_NAME'} cmp $b->{'COLUMN_NAME'} } @results;

    my @expected = ( { TABLE_NAME  => 'inline',
                       COLUMN_NAME => 'id',
                       DATA_TYPE   => 'integer',
                       COLUMN_SIZE => undef,
                       NULLABLE    => 1,
                       COLUMN_DEF  => undef,
                     },
                     { TABLE_NAME  => 'inline',
                       COLUMN_NAME => 'name',
                       DATA_TYPE   => 'varchar',
                       COLUMN_SIZE => 255,
                       NULLABLE    => 1,
                       COLUMN_DEF  => 'some name',
                     },
                  );
    is_deeply(\@results,
              \@expected,
               'column details for table inline are correct');
}

    


sub test_foreign_key_handling {
    my $expected_fk_data = &make_expected_fk_data();

    my @table_names = qw( foo inline inline_s named named_s unnamed unnamed_s named_2 named_2_s unnamed_2 unnamed_2_s);
    foreach my $table ( @table_names ) {
        my $found = &get_fk_info_from_dd('','',$table);
        my $found_count = scalar(@$found);

        my $expected = $expected_fk_data->{'from'}->{$table};
        my $expected_count = scalar(@$expected);

        $found = [ sort { $a->{FK_TABLE_NAME} cmp $b->{FK_TABLE_NAME} } @$found ];
        $expected = [ sort { $a->{FK_TABLE_NAME} cmp $b->{FK_TABLE_NAME} } @$expected ];

        is($found_count, $expected_count, "Number of FK rows from $table is correct");
        is_deeply($found, $expected, 'FK data is correct');
    }

    foreach my $table ( @table_names ) {
        my $found = &get_fk_info_from_dd('','','','','',$table);
        my $found_count = scalar(@$found);

        my $expected = $expected_fk_data->{'to'}->{$table};
        my $expected_count = scalar(@$expected);

        $found = [ sort { $a->{UK_TABLE_NAME} cmp $b->{UK_TABLE_NAME} } @$found ];
        $expected = [ sort { $a->{UK_TABLE_NAME} cmp $b->{UK_TABLE_NAME} } @$expected ];

        is($found_count, $expected_count, "Number of FK rows to $table is correct");
        is_deeply($found, $expected, 'FK data is correct');
    }
}


unlink URT::DataSource::SomeSQLite->server;



sub setup_schema {
    my $dbh = shift;

    ok( $dbh->do('CREATE TABLE foo (id1 integer, id2 integer, PRIMARY KEY (id1, id2))'),
        'create table (foo) with 2 primary keys');

    ok($dbh->do("CREATE TABLE inline (id integer PRIMARY KEY REFERENCES foo(id1) ON UPDATE RESTRICT ON DELETE SET NULL, name varchar(255) default 'some name')"),
       'create table with one inline foreign key to foo');

    ok($dbh->do('CREATE TABLE inline_s (id integer PRIMARY KEY REFERENCES foo (id1) ON UPDATE RESTRICT ON DELETE SET NULL , name varchar)'),
      'create table with one inline foreign key to foo, with different whitespace');

    ok($dbh->do('CREATE TABLE named (id integer PRIMARY KEY, name varchar, CONSTRAINT named_fk FOREIGN KEY (id) REFERENCES foo (id1) ON UPDATE RESTRICT ON DELETE SET NULL)'),
       'create table with one named table constraint foreign key to foo');

    ok($dbh->do('CREATE TABLE named_s (id integer PRIMARY KEY, name varchar, CONSTRAINT named_s_fk FOREIGN KEY(id) REFERENCES foo (id1) ON UPDATE RESTRICT ON DELETE SET NULL)'),
       'create table with one named table constraint foreign key to foo, with different whitespace');

    ok($dbh->do('CREATE TABLE unnamed (id integer PRIMARY KEY, name varchar, FOREIGN KEY (id) REFERENCES foo (id1) ON UPDATE RESTRICT ON DELETE SET NULL)'),
       'create table with one unnamed table constraint foreign key to foo');

    ok($dbh->do('CREATE TABLE unnamed_s (id integer PRIMARY KEY, name varchar, FOREIGN KEY(id) REFERENCES foo(id1) ON UPDATE RESTRICT ON DELETE SET NULL)'),
        'create table with one unnamed table constraint foreign key to foo, with different whitespace');

    ok($dbh->do('CREATE TABLE named_2 (id1 integer, id2 integer, name varchar, PRIMARY KEY (id1, id2), CONSTRAINT named_2_fk FOREIGN KEY (id1, id2) REFERENCES foo (id1,id2) ON UPDATE RESTRICT ON DELETE SET NULL)'),
       'create table with a dual column named foreign key to foo');

    ok($dbh->do('CREATE TABLE named_2_s (id1 integer, id2 integer, name varchar, PRIMARY KEY ( id1 , id2 ) , CONSTRAINT named_2_s_fk FOREIGN KEY( id1 , id2 ) REFERENCES foo( id1 , id2 ) ON UPDATE RESTRICT ON DELETE SET NULL )'),
      'create table with a dual column named foreign key to foo, with different whitespace');

    ok($dbh->do('CREATE TABLE unnamed_2 (id1 integer, id2 integer, name varchar, PRIMARY KEY (id1, id2), FOREIGN KEY (id1, id2) REFERENCES foo (id1,id2) ON UPDATE RESTRICT ON DELETE SET NULL)'),
       'create table with a dual column unnamed foreign key to foo');

    ok($dbh->do('CREATE TABLE unnamed_2_s (id1 integer, id2 integer, name varchar, PRIMARY KEY( id2 , id2 ) , FOREIGN KEY( id1 , id2 ) REFERENCES foo( id1 , id2 ) ON UPDATE RESTRICT ON DELETE SET NULL )'),
        'create table with a dual column unnamed foreign key to foo, with different whitespace');
}
    

sub make_expected_fk_data {
     my $to = {
             foo => [],
             inline => [
                      { FK_NAME => 'inline_id_foo_id1_fk',
                        FK_TABLE_NAME => 'inline',
                        FK_COLUMN_NAME => 'id',
                        UK_TABLE_NAME => 'foo',
                        UK_COLUMN_NAME => 'id1',
                        ORDINAL_POSITION => 1,
                        UPDATE_RULE => 1,
                        DELETE_RULE => 2,
                        UK_TABLE_CAT => undef,
                        UK_TABLE_SCHEM => 'main',
                        FK_TABLE_CAT => undef,
                        FK_TABLE_SCHEM => 'main',
                        UK_NAME => undef,
                        DEFERABILITY => undef,
                      },
                    ],
             inline_s => [
                     { FK_NAME => 'inline_s_id_foo_id1_fk',
                        FK_TABLE_NAME => 'inline_s',
                        FK_COLUMN_NAME => 'id',
                        UK_TABLE_NAME => 'foo',
                        UK_COLUMN_NAME => 'id1',
                        ORDINAL_POSITION => 1,
                        UPDATE_RULE => 1,
                        DELETE_RULE => 2,
                        UK_TABLE_CAT => undef,
                        UK_TABLE_SCHEM => 'main',
                        FK_TABLE_CAT => undef,
                        FK_TABLE_SCHEM => 'main',
                        UK_NAME => undef,
                        DEFERABILITY => undef,
                      },
                    ],
             named => [ 
                      { FK_NAME => 'named_fk',
                        FK_TABLE_NAME => 'named',
                        FK_COLUMN_NAME => 'id',
                        UK_TABLE_NAME => 'foo',
                        UK_COLUMN_NAME => 'id1',
                        ORDINAL_POSITION => 1,
                        UPDATE_RULE => 1,
                        DELETE_RULE => 2,
                        UK_TABLE_CAT => undef,
                        UK_TABLE_SCHEM => 'main',
                        FK_TABLE_CAT => undef,
                        FK_TABLE_SCHEM => 'main',
                        UK_NAME => undef,
                        DEFERABILITY => undef,
                       },
                    ],
             named_s => [
                      { FK_NAME => 'named_s_fk',
                        FK_TABLE_NAME => 'named_s',
                        FK_COLUMN_NAME => 'id',
                        UK_TABLE_NAME => 'foo',
                        UK_COLUMN_NAME => 'id1',
                        ORDINAL_POSITION => 1,
                        UPDATE_RULE => 1,
                        DELETE_RULE => 2,
                        UK_TABLE_CAT => undef,
                        UK_TABLE_SCHEM => 'main',
                        FK_TABLE_CAT => undef,
                        FK_TABLE_SCHEM => 'main',
                        UK_NAME => undef,
                        DEFERABILITY => undef,
                       },
                    ],
             unnamed => [
                      { FK_NAME => 'unnamed_id_foo_id1_fk',
                        FK_TABLE_NAME => 'unnamed',
                        FK_COLUMN_NAME => 'id',
                        UK_TABLE_NAME => 'foo',
                        UK_COLUMN_NAME => 'id1',
                        ORDINAL_POSITION => 1,
                        UPDATE_RULE => 1,
                        DELETE_RULE => 2,
                        UK_TABLE_CAT => undef,
                        UK_TABLE_SCHEM => 'main',
                        FK_TABLE_CAT => undef,
                        FK_TABLE_SCHEM => 'main',
                        UK_NAME => undef,
                        DEFERABILITY => undef,
                       },
                    ],
             unnamed_s => [
                      { FK_NAME => 'unnamed_s_id_foo_id1_fk',
                        FK_TABLE_NAME => 'unnamed_s',
                        FK_COLUMN_NAME => 'id',
                        UK_TABLE_NAME => 'foo',
                        UK_COLUMN_NAME => 'id1',
                        ORDINAL_POSITION => 1,
                        UPDATE_RULE => 1,
                        DELETE_RULE => 2,
                        UK_TABLE_CAT => undef,
                        UK_TABLE_SCHEM => 'main',
                        FK_TABLE_CAT => undef,
                        FK_TABLE_SCHEM => 'main',
                        UK_NAME => undef,
                        DEFERABILITY => undef,
                       },
                    ],
             named_2 => [
                      { FK_NAME => 'named_2_fk',
                        FK_TABLE_NAME => 'named_2',
                        FK_COLUMN_NAME => 'id1',
                        UK_TABLE_NAME => 'foo',
                        UK_COLUMN_NAME => 'id1',
                        ORDINAL_POSITION => 1,
                        UPDATE_RULE => 1,
                        DELETE_RULE => 2,
                        UK_TABLE_CAT => undef,
                        UK_TABLE_SCHEM => 'main',
                        FK_TABLE_CAT => undef,
                        FK_TABLE_SCHEM => 'main',
                        UK_NAME => undef,
                        DEFERABILITY => undef,
                       },
                      { FK_NAME => 'named_2_fk',
                        FK_TABLE_NAME => 'named_2',
                        FK_COLUMN_NAME => 'id2',
                        UK_TABLE_NAME => 'foo',
                        UK_COLUMN_NAME => 'id2',
                        ORDINAL_POSITION => 2,
                        UPDATE_RULE => 1,
                        DELETE_RULE => 2,
                        UK_TABLE_CAT => undef,
                        UK_TABLE_SCHEM => 'main',
                        FK_TABLE_CAT => undef,
                        FK_TABLE_SCHEM => 'main',
                        UK_NAME => undef,
                        DEFERABILITY => undef,
                       },
                     ],
             named_2_s => [
                      { FK_NAME => 'named_2_s_fk',
                        FK_TABLE_NAME => 'named_2_s',
                        FK_COLUMN_NAME => 'id1',
                        UK_TABLE_NAME => 'foo',
                        UK_COLUMN_NAME => 'id1',
                        ORDINAL_POSITION => 1,
                        UPDATE_RULE => 1,
                        DELETE_RULE => 2,
                        UK_TABLE_CAT => undef,
                        UK_TABLE_SCHEM => 'main',
                        FK_TABLE_CAT => undef,
                        FK_TABLE_SCHEM => 'main',
                        UK_NAME => undef,
                        DEFERABILITY => undef,
                       },
                      { FK_NAME => 'named_2_s_fk',
                        FK_TABLE_NAME => 'named_2_s',
                        FK_COLUMN_NAME => 'id2',
                        UK_TABLE_NAME => 'foo',
                        UK_COLUMN_NAME => 'id2',
                        ORDINAL_POSITION => 2,
                        UPDATE_RULE => 1,
                        DELETE_RULE => 2,
                        UK_TABLE_CAT => undef,
                        UK_TABLE_SCHEM => 'main',
                        FK_TABLE_CAT => undef,
                        FK_TABLE_SCHEM => 'main',
                        UK_NAME => undef,
                        DEFERABILITY => undef,
                       },
                     ],
             unnamed_2 => [
                       { FK_NAME => 'unnamed_2_id1_id2_foo_id1_id2_fk',
                         FK_TABLE_NAME => 'unnamed_2',
                         FK_COLUMN_NAME => 'id1',
                         UK_TABLE_NAME => 'foo',
                         UK_COLUMN_NAME => 'id1',
                         ORDINAL_POSITION => 1,
                         UPDATE_RULE => 1,
                         DELETE_RULE => 2,
                        UK_TABLE_CAT => undef,
                        UK_TABLE_SCHEM => 'main',
                        FK_TABLE_CAT => undef,
                        FK_TABLE_SCHEM => 'main',
                        UK_NAME => undef,
                        DEFERABILITY => undef,
                        },
                       { FK_NAME => 'unnamed_2_id1_id2_foo_id1_id2_fk',
                         FK_TABLE_NAME => 'unnamed_2',
                         FK_COLUMN_NAME => 'id2',
                         UK_TABLE_NAME => 'foo',
                         UK_COLUMN_NAME => 'id2',
                         ORDINAL_POSITION => 2,
                         UPDATE_RULE => 1,
                         DELETE_RULE => 2,
                        UK_TABLE_CAT => undef,
                        UK_TABLE_SCHEM => 'main',
                        FK_TABLE_CAT => undef,
                        FK_TABLE_SCHEM => 'main',
                        UK_NAME => undef,
                        DEFERABILITY => undef,
                        },
                      ],
             unnamed_2_s => [
                       { FK_NAME => 'unnamed_2_s_id1_id2_foo_id1_id2_fk',
                         FK_TABLE_NAME => 'unnamed_2_s',
                         FK_COLUMN_NAME => 'id1',
                         UK_TABLE_NAME => 'foo',
                         UK_COLUMN_NAME => 'id1',
                         ORDINAL_POSITION => 1,
                         UPDATE_RULE => 1,
                         DELETE_RULE => 2,
                        UK_TABLE_CAT => undef,
                        UK_TABLE_SCHEM => 'main',
                        FK_TABLE_CAT => undef,
                        FK_TABLE_SCHEM => 'main',
                        UK_NAME => undef,
                        DEFERABILITY => undef,
                        },
                       { FK_NAME => 'unnamed_2_s_id1_id2_foo_id1_id2_fk',
                         FK_TABLE_NAME => 'unnamed_2_s',
                         FK_COLUMN_NAME => 'id2',
                         UK_TABLE_NAME => 'foo',
                         UK_COLUMN_NAME => 'id2',
                         ORDINAL_POSITION => 2,
                         UPDATE_RULE => 1,
                         DELETE_RULE => 2,
                        UK_TABLE_CAT => undef,
                        UK_TABLE_SCHEM => 'main',
                        FK_TABLE_CAT => undef,
                        FK_TABLE_SCHEM => 'main',
                        UK_NAME => undef,
                        DEFERABILITY => undef,
                        },
                      ],
          };

    # The 'from' data is just the inverse of 'to'
    my $from;
    foreach my $fk_list ( values %$to ) {
        foreach my $fk ( @$fk_list ) {
            my $uk_table = $fk->{'UK_TABLE_NAME'};
            $from->{$uk_table} ||= [];
            push @{$from->{$uk_table}}, $fk;

            my $fk_table = $fk->{'FK_TABLE_NAME'};
            $from->{$fk_table} ||= [];
        }
    }

    return { from => $from, to => $to };
}


sub get_fk_info_from_dd {
    my $sth = URT::DataSource::SomeSQLite->get_foreign_key_details_from_data_dictionary(@_);
    { no warnings 'uninitialized';
      ok($sth, "Got a sth to get foreign keys from '$_[2]' to '$_[5]'");
    }
    my @rows;
    while ( my $row = $sth->fetchrow_hashref() ) {
        push @rows, $row;
    }

    return \@rows;
}

