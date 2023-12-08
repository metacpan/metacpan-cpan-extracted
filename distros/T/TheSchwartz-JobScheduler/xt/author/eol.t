use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

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
    't/use_database_managedhandle.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
