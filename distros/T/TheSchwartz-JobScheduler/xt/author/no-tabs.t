use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/TheSchwartz/JobScheduler.pm',
    'lib/TheSchwartz/JobScheduler/Job.pm',
    't/compile.t',
    't/insert_job.t',
    't/insert_job_uniqkey.t',
    't/job.t',
    't/lib/TestDatabaseHandleCallbackOne.pm',
    't/lib/TheSchwartz/JobScheduler/Test/Database/Schemas/Pg.pm',
    't/lib/TheSchwartz/JobScheduler/Test/Database/Schemas/SQLite.pm',
    't/private-_get_dbh.t',
    't/use_adhoc_dbhandle.t',
    't/use_database_managedhandle.t'
);

notabs_ok($_) foreach @files;
done_testing;
