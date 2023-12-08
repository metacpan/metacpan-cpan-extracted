#!perl
# no critic (ControlStructures::ProhibitPostfixControls)
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

use strict;
use warnings;

use utf8;
use Test2::V0;
set_encoding('utf8');

use FindBin 1.51 qw( $RealBin );
use File::Spec;
my $lib_path;

BEGIN {
    $lib_path = File::Spec->catdir( ( $RealBin =~ /(.+)/msx )[0], q{.}, 'lib' );
}
use lib "$lib_path";

use Module::Load qw( load );

# Activate for testing
# use Log::Any::Adapter ('Stdout', log_level => 'debug' );

use DBI;
use Test::Database::Temp;

use TheSchwartz::JobScheduler;

# ##############################################################################
# Helpers
#
sub init_db {
    my ( $dbh, $name, $info, $driver ) = @_;
    my $module = "TheSchwartz::JobScheduler::Test::Database::Schemas::${driver}";
    load $module;
    my $schema = $module->new->schema;
    $dbh->begin_work();
    foreach my $row ( split qr/;\s*/msx, $schema ) {
        $dbh->do($row);
    }
    $dbh->commit;
    return;
}

# ##############################################################################
# Test
#
sub do_test {
    my ($db) = @_;
    my $dbh = DBI->connect( $db->connection_info );
    my ( $db_driver, $db_name ) = ( $db->driver, $db->name );

    subtest "Testing with $db_driver in db $db_name" => sub {

        # TheSchwartz can have many actual databases hosting the queues
        # simultaneously. For this test, however, we only have one database
        # for each database type (SQLite, Pg, ...)
        my %test_dbs = ( $db_name => $db, );
        my $get_dbh  = sub {
            my ($id) = @_;
            return DBI->connect( $test_dbs{$id}->connection_info );
        };
        my %databases;
        foreach my $id ( keys %test_dbs ) {
            $databases{$id} = {
                dbh_callback => $get_dbh,
                prefix       => q{}
            };
        }
        my $client = TheSchwartz::JobScheduler->new( databases => \%databases, );

        # No transactions. We have autocommit active.
        #     &{ $get_dbh }()->start_work;
        my $jobid_1 = $client->insert( 'fetch', 'https://example.com/' );

        #     &{ $get_dbh }()->end_work;
        is( $jobid_1, 1, 'Job id is 1' );

        my $jobid_2 = $client->insert(
            TheSchwartz::JobScheduler::Job->new(
                funcname => 'fetch',
                arg      => { type => 'site', url => 'https://example.com/' },
                priority => 3,
            )
        );
        is( $jobid_2, 2, 'Job id is 2' );

        my @jobs = $client->list_jobs( { funcname => 'fetch' } );
        is( scalar @jobs, 2, 'two jobs with funcname fetch' );
        my $row = $jobs[0];
        ok( $row, 'Jobs[0] exists' );
        is( $row->jobid, 1, 'jobs[0]->jobid is 1' );
        is(
            $row->funcid,
            $client->funcname_to_id( $dbh, $databases{$db_name}->{'prefix'}, 'fetch' ),
            'funcid matches with funcname_to_id()'
        );
        is( $row->arg,      'https://example.com/', 'arg(scalar) is correct' );
        is( $row->priority, undef,                  'priority is correct' );

        $row = $jobs[1];
        ok( $row, 'Jobs[1] exists' );
        is( $row->jobid, 2, 'jobs[0]->jobid is 2' );
        is(
            $row->funcid,
            $client->funcname_to_id( $dbh, $databases{$db_name}->{'prefix'}, 'fetch' ),
            'funcid matches with funcname_to_id()'
        );
        is( $row->arg,      { type => 'site', url => 'https://example.com/' }, 'arg(hash) is correct' );
        is( $row->priority, 3,                                                 'priority is correct' );

        my $jobid_3 = $client->insert( 'push', 'https://example.com/' );

        my @push_jobs = $client->list_jobs( { funcname => 'push' } );
        is( scalar @push_jobs, 1, 'two jobs with funcname fetch' );
        $row = $push_jobs[0];
        is( $row->jobid, 3, 'jobs[0]->jobid is 3' );

        # This will throw an exception but it is normal behaviour!
        # DBD::Pg::st execute failed: ERROR:  duplicate key value violates unique constraint "funcmap_funcname_key"
        # DETAIL:  Key (funcname)=(push) already exists. [..].
        is(
            $row->funcid,
            $client->funcname_to_id( $dbh, $databases{$db_name}->{'prefix'}, 'push' ),
            'funcid matches with funcname_to_id()'
        );
        is( $row->arg,      'https://example.com/', 'arg(scalar) is correct' );
        is( $row->priority, undef,                  'priority is correct' );

        done_testing;
    };
    return;
}

# ##############################################################################
# Create a subtest for each database we test.
#
# We only have schemas for SQLite and Pg
#
my @drivers = Test::Database::Temp->available_drivers( drivers => [qw( SQLite Pg )] );
Test::Database::Temp->use_all_available(
    drivers => \@drivers,
    build   => sub {
        my ($driver) = @_;
        my %params = ( args => {} );
        return \%params;
    },
    init   => \&init_db,
    deinit => sub {
        my ( $dbh, $name, $info, $driver ) = @_;
    },
    do => \&do_test,

    # demolish => sub { },
);

done_testing;
