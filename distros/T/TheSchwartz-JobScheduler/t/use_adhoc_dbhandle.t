#!perl
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

use Database::Temp;

use TheSchwartz::JobScheduler;

# ##############################################################################
# Helpers
#
sub init_db {
    my ( $dbh, $name, $info, $driver ) = @_;
    my $module = "TheSchwartz::JobScheduler::Test::Database::Schemas::${driver}";
    load $module;
    my $schema = $module->new->schema;
    foreach my $row ( split qr/;\s*/msx, $schema ) {
        $dbh->do($row);
    }
    return;
}

# ##############################################################################
# Test
#
# In this test we create first two databases.
# Pointers to the databases are in @test_dbs.
# ManagedConfig only has connection info.
# When @test_dbs goes undef, the databases drop.
#

my @test_dbs;

BEGIN {
    diag 'Create temp databases';

    # my @drivers = Test::Database::Temp->available_drivers();
    my @drivers = qw( SQLite SQLite );
    foreach my $driver (@drivers) {
        my $test_db = Database::Temp->new(
            driver => $driver,
            init   => sub {
                my ( $dbh, $name, $info, $driver ) = @_;
                init_db( $dbh, $name, $info, $driver );
            },
        );
        diag 'Test database (' . $test_db->driver . ') ' . $test_db->name . " created.\n";
        push @test_dbs, $test_db;
    }
}

# use Database::ManagedHandle;
use DBI;

sub get_dbh {
    my ($db_id) = @_;
    my ($db)    = grep { $_->name eq $db_id; } @test_dbs;
    return DBI->connect( $db->connection_info );
}

subtest 'Testing' => sub {
    my %databases;
    foreach my $db (@test_dbs) {
        $databases{ $db->name } = { prefix => q{} };
    }
    my $scheduler = TheSchwartz::JobScheduler->new( databases => \%databases, );

    my $job1 = TheSchwartz::JobScheduler::Job->new(
        funcname => 'fetch',
        arg      => { type => 'site', url => 'https://example.com/1' },
    );
    my $jobid_1 = $scheduler->insert( job => $job1, dbh_callback => \&get_dbh, );
    is( $jobid_1, 1, 'Job id is 1' );

    my $jobid_2 = $scheduler->insert(
        job => TheSchwartz::JobScheduler::Job->new(
            funcname => 'fetch',
            arg      => { type => 'site', url => 'https://example.com/2' },
            priority => 3,
        ),
        dbh_callback => \&get_dbh,
    );
    is( $jobid_2, 2, 'Job id is 2' );

    my @jobs = $scheduler->list_jobs(
        search_params => { funcname => 'fetch' },
        dbh_callback  => \&get_dbh,
    );
    is( scalar @jobs, 2, 'two jobs with funcname fetch' );
    my $row = $jobs[0];
    ok( $row, 'Jobs[0] exists' );
    is( $row->jobid,    1,                                                  'jobs[0]->jobid is 1' );
    is( $row->arg,      { type => 'site', url => 'https://example.com/1' }, 'arg(hash) is correct' );
    is( $row->priority, undef,                                              'priority (default: undef) is correct' );

    $row = $jobs[1];
    ok( $row, 'Jobs[1] exists' );
    is( $row->jobid,    2,                                                  'jobs[0]->jobid is 2' );
    is( $row->arg,      { type => 'site', url => 'https://example.com/2' }, 'arg(hash) is correct' );
    is( $row->priority, 3,                                                  'priority (defined) is correct' );

    my $jobid_3 = $scheduler->insert(
        job => TheSchwartz::JobScheduler::Job->new(
            funcname => 'push',
            arg      => { type => 'site', url => 'https://example.com/3' },
            priority => 2,
        ),
        dbh_callback => \&get_dbh,
    );

    my @push_jobs = $scheduler->list_jobs(
        search_params => { funcname => 'push' },
        dbh_callback  => \&get_dbh,
    );
    is( scalar @push_jobs, 1, 'two jobs with funcname fetch' );
    $row = $push_jobs[0];
    is( $row->jobid, 3, 'jobs[0]->jobid is 3' );

    is( $row->arg,      { type => 'site', url => 'https://example.com/3' }, 'arg(hash) is correct' );
    is( $row->priority, 2,                                                  'priority is correct' );

    done_testing;
};

# Undefine all Database::Temp objects explicitly to demolish
# the databases in good order, instead of doing it unmanaged
# during global destruct, when program dies.
@test_dbs = undef;

done_testing;
