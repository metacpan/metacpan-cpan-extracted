#!/usr/bin/perl
use strict;
use warnings;

use Fennec class => 'Test::FixtureBuilder';

BEGIN {
    require_ok $CLASS;
    package MyFixtureBuilder;
    use File::Temp qw/tempfile/;

    use DBI;
    use DBD::SQLite;

    use base $main::CLASS;

    my %DBs;

    sub name_to_handle {
        my $class = shift;
        my ($name) = @_;

        unless ($DBs{$name}) {
            my ($fh, $filename) = tempfile(EXLOCK => 0);
            close($fh);
            my $dbh = DBI->connect("dbi:SQLite:dbname=$filename","","");

            $dbh->do('CREATE TABLE A(a INTEGER, b INTEGER)')
                || die "Could not create table";

            $dbh->do('CREATE TABLE B(a INTEGER, b INTEGER)')
                || die "Could not create table";

            $DBs{$name} = $dbh;
        }

        return $DBs{$name};
    }

    END { delete $DBs{$_} for keys %DBs }
}

BEGIN { MyFixtureBuilder->import }

sub fetch {
    my ($table) = @_;
    my $dbh = MyFixtureBuilder->name_to_handle('test') || die "No db";

    my $sth = $dbh->prepare( "SELECT * FROM $table" );
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

tests can_we_fix_it => sub {
    my $self = shift;
    can_ok( $self, qw/fixture_db fixture_table fixture_row/ );
};

tests full_stack => sub {
    my $self = shift;

    # Assert no rows
    is( scalar @{fetch('A')}, 0, "No results A" );
    is( scalar @{fetch('B')}, 0, "No results B" );

    fixture_db test => sub {
        fixture_table A => sub {
            fixture_row { a => 1, b => 1 };
            fixture_row { a => 2, b => 2 };
            fixture_row { a => 3, b => 3 };
        };

        # Assert rows above, but not below
        is( scalar @{fetch('A')}, 3, "results A" );
        is( scalar @{fetch('B')}, 0, "Still no results B" );

        fixture_table B => sub {
            fixture_row { a => 1, b => 1 };
            fixture_row { a => 2, b => 2 };
            fixture_row { a => 3, b => 3 };
        };

        is( scalar @{fetch('B')}, 3, "results B" );
    };

    # Assert all rows
    is_deeply(
        fetch('A'),
        [
            { a => 1, b => 1 },
            { a => 2, b => 2 },
            { a => 3, b => 3 },
        ],
        "Verify results from A"
    );

    is_deeply(
        fetch('B'),
        [
            { a => 1, b => 1 },
            { a => 2, b => 2 },
            { a => 3, b => 3 },
        ],
        "Verify results from B"
    );
};

done_testing;
