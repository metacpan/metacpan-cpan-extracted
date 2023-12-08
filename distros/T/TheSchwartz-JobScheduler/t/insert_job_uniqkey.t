#!perl
# no critic (ControlStructures::ProhibitPostfixControls)
# no critic (ValuesAndExpressions::ProhibitMagicNumbers)

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
# TheSchwartz can have many actual databases hosting the queues
# simultaneously. For this test, however, we only have one database
# for each database type (SQLite, Pg, ...)
#
sub do_test {
    my ($db) = @_;
    my $dbh = DBI->connect( $db->connection_info );
    my ( $db_driver, $db_name ) = ( $db->driver, $db->name );

    subtest
      "Testing with $db_driver in db $db_name, Insert Jobs With Same uniqkey, policy \"no_check\", and Receive an Exception" =>
      sub {
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

        # Start
        my $client = TheSchwartz::JobScheduler->new(
            databases => \%databases,
            opts      => {
                handle_uniqkey => 'no_check',
            }
        );

        my $job = TheSchwartz::JobScheduler::Job->new(
            funcname => 'Test::uniqkey',
            arg      => { an_item => 'value A' },
            uniqkey  => 'UNIQUE_STR_A',
        );

        my $jobid_1 = $client->insert($job);
        ok( $jobid_1, 'Got a job id' );

        $job->arg( { an_item => 'value B' } );
        ## no critic (RegularExpressions::RequireExtendedFormatting)
        like( dies { $client->insert($job); }, qr/DBD::[[:word:]]{1,}::st execute failed:/ms, 'Failed as expected', );

        done_testing;
      };

    subtest 'Insert Jobs With Same uniqkey, policy "acknowledge", and get same jobid' => sub {
        my %test_dbs = ( $db_name => $db, );
        my $get_dbh  = sub {
            my ($id) = @_;
            my ( $dsn, $user, $pass, $attr ) = $test_dbs{$id}->connection_info;
            return DBI->connect( $dsn, $user, $pass, $attr );
        };
        my %databases;
        foreach my $id ( keys %test_dbs ) {
            $databases{$id} = {
                dbh_callback => $get_dbh,
                prefix       => q{}
            };
        }

        # Start
        my $client = TheSchwartz::JobScheduler->new(
            databases => \%databases,
            opts      => {
                handle_uniqkey => 'acknowledge',
            }
        );

        my $job = TheSchwartz::JobScheduler::Job->new(
            funcname => 'Test::uniqkey',
            arg      => { an_item => 'value A' },
            uniqkey  => 'UNIQUE_STR_A',
        );

        my $jobid_1 = $client->insert($job);
        ok( $jobid_1, 'Got a job id' );

        $job->arg( { an_item => 'value B' } );
        my $jobid_2 = $client->insert($job);
        ok( $jobid_2, 'Got a job id' );

        is( $jobid_1, $jobid_2, 'job ids are the same' );

        # Create one more
        $job->arg( { an_item => 'value C' } );
        $job->uniqkey(undef);
        my $jobid_3 = $client->insert($job);
        ok( $jobid_3,            'Got a job id' );
        ok( $jobid_3 > $jobid_2, 'New jobid is greater than previous' );

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
    init => \&init_db,
    do   => \&do_test,

    # demolish => sub { },
);

done_testing;
