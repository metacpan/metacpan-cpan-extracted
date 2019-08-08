# NAME

TheSchwartz - reliable job queue

# SYNOPSIS

    # MyApp.pm
    package MyApp;

    sub work_asynchronously {
        my %args = @_;

        my $client = TheSchwartz->new( databases => $DATABASE_INFO );
        $client->insert('MyWorker', \%args);
    }


    # myworker.pl
    package MyWorker;
    use base qw( TheSchwartz::Worker );

    sub work {
        my $class = shift;
        my TheSchwartz::Job $job = shift;

        print "Workin' hard or hardly workin'? Hyuk!!\n";

        $job->completed();
    }

    package main;

    my $client = TheSchwartz->new( databases => $DATABASE_INFO );
    $client->can_do('MyWorker');
    $client->work();

# DESCRIPTION

TheSchwartz is a reliable job queue system. Your application can put jobs into
the system, and your worker processes can pull jobs from the queue atomically
to perform. Failed jobs can be left in the queue to retry later.

_Abilities_ specify what jobs a worker process can perform. Abilities are the
names of `TheSchwartz::Worker` sub-classes, as in the synopsis: the `MyWorker`
class name is used to specify that the worker script can perform the job. When
using the `TheSchwartz` client's `work` functions, the class-ability duality
is used to automatically dispatch to the proper class to do the actual work.

TheSchwartz clients will also prefer to do jobs for unused abilities before
reusing a particular ability, to avoid exhausting the supply of one kind of job
while jobs of other types stack up.

Some jobs with high setup times can be performed more efficiently if a group of
related jobs are performed together. TheSchwartz offers a facility to
_coalesce_ jobs into groups, which a properly constructed worker can find and
perform at once. For example, if your worker were delivering email, you might
store the domain name from the recipient's address as the coalescing value. The
worker that grabs that job could then batch deliver all the mail for that
domain once it connects to that domain's mail server.

# USAGE

## `TheSchwartz->new( %args )`

Optional members of `%args` are:

- `databases`

    An arrayref of database information. TheSchwartz workers can use multiple
    databases, such that if any of them are unavailable, the worker will search for
    appropriate jobs in the other databases automatically.

    Each member of the `databases` value should be a hashref containing either:

    - `dsn`

        The database DSN for this database.

    - `user`

        The user name to use when connecting to this database.

    - `pass`

        The password to use when connecting to this database.

    or

    - `driver`

        A `Data::ObjectDriver::Driver::DBI` object.

        See note below.

- `verbose`

    A value indicating whether to log debug messages. If `verbose` is a coderef,
    it is called to log debug messages. If `verbose` is not a coderef but is some
    other true value, debug messages will be sent to `STDERR`. Otherwise, debug
    messages will not be logged.

- `prioritize`

    A value indicating whether to utilize the job 'priority' field when selecting
    jobs to be processed. If unspecified, jobs will always be executed in a
    randomized order.

- `floor`

    A value indicating the minimum priority a job needs to be for this worker to 
    perform. If unspecified all jobs are considered.

- `batch_size`

    A value indicating how many jobs should be fetched from the DB for consideration.

- `driver_cache_expiration`

    Optional value to control how long database connections are cached for in seconds.
    By default, connections are not cached. To re-use the same database connection for
    five minutes, pass driver\_cache\_expiration => 300 to the constructor. Improves job
    throughput in cases where the work to process a job is small compared to the database
    connection set-up and tear-down time.

- `retry_seconds`

    The number of seconds after which to try reconnecting to apparently dead
    databases. If not given, TheSchwartz will retry connecting to databases after
    30 seconds.

- `strict_remove_ability`

    By default when work\_once does not find a job it will reset current\_abilities to
    all\_abilities and look for a job. Setting this option will prevent work\_once from
    resetting abilities if it can't find a job for the current capabilities.

## `$client->list_jobs( %args )`

Returns a list of `TheSchwartz::Job` objects matching the given arguments. The
required members of `%args` are:

- `funcname`

    the name of the function or a reference to an array of functions

- `run_after`

    the value you want to check <= against on the run\_after column

- `grabbed_until`

    the value you want to check <= against on the grabbed\_until column

- `coalesce_op`

    defaults to '=', set it to whatever you want to compare the coalesce field too
    if you want to search, you can use 'LIKE'

- `coalesce`

    coalesce value to search for, if you set op to 'LIKE' you can use '%' here,
    do remember that '%' searches anchored at the beginning of the string are
    much faster since it is can do a btree index lookup

- `want_handle`

    if you want all your jobs to be set up using a handle.  defaults to true.
    this option might be removed, as you should always have this on a Job object.

- `jobid`

    if you want a specific job you can pass in it's ID and if it's available it
    will be listed.

It is important to remember that this function does not lock anything, it just
returns as many jobs as there is up to amount of databases \* $client->{batch\_size}

## `$client->lookup_job( $handle_id )`

Returns a `TheSchwartz::Job` corresponding to the given handle ID.

## `$client->set_verbose( $verbose )`

Sets the current logging function to `$verbose` if it's a coderef. If not a
coderef, enables debug logging to `STDERR` if `$verbose` is true; otherwise,
disables logging.

# POSTING JOBS

The methods of TheSchwartz clients used by applications posting jobs to the
queue are:

## `$client->insert( $job )`

Adds the given `TheSchwartz::Job` to one of the client's job databases.

## `$client->insert( $funcname, $arg )`

Adds a new job with function name `$funcname` and arguments `$arg` to the queue.

## `$client->insert_jobs( @jobs )`

Adds the given `TheSchwartz::Job` objects to one of the client's job
databases. All the given jobs are recorded in _one_ job database.

## `$client->set_prioritize( $prioritize )`

Set the `prioritize` value as described in the constructor.

## `$client->set_floor( $floor )`

Set the `floor<gt` value as described in the constructor.

## `$client->set_batch_size( $batch_size )`

Set the `batch_size<gt` value as described in the constructor.

## `$client->set_strict_remove_ability( $strict_remove_ability )`

Set the `strict_remove_ability<gt` value as described in the constructor.

# WORKING

The methods of TheSchwartz clients for use in worker processes are:

## `$client->can_do( $ability )`

Adds `$ability` to the list of abilities `$client` is capable of performing.
Subsequent calls to that client's `work` methods will find jobs requiring the
given ability.

## `$client->work_once()`

Find and perform one job `$client` can do.

## `$client->work_until_done()`

Find and perform jobs `$client` can do until no more such jobs are found in
any of the client's job databases.

## `$client->work( [$delay] )`

Find and perform any jobs `$client` can do, forever. When no job is available,
the working process will sleep for `$delay` seconds (or 5, if not specified)
before looking again.

## `$client->work_on($handle)`

Given a job handle (a scalar string) _$handle_, runs the job, then returns.

## `$client->grab_and_work_on($handle)`

Similar to [$client->work\_on($handle)](https://metacpan.org/pod/$client->work_on\($handle\)), except that the job will be grabbed
before being run. It guarantees that only one worker will work on it (at least
in the `grab_for` interval).

Returns false if the worker could not grab the job, and true if the worker worked
on it.

## `$client->find_job_for_workers( [$abilities] )`

Returns a `TheSchwartz::Job` for a random job that the client can do. If
specified, the job returned matches one of the abilities in the arrayref
`$abilities`, rather than `$client`'s abilities.

## `$client->find_job_with_coalescing_value( $ability, $coval )`

Returns a `TheSchwartz::Job` for a random job for a worker capable of
`$ability` and with a coalescing value of `$coval`.

## `$client->find_job_with_coalescing_prefix( $ability, $coval )`

Returns a `TheSchwartz::Job` for a random job for a worker capable of
`$ability` and with a coalescing value beginning with `$coval`.

Note the `TheSchwartz` implementation of this function uses a `LIKE` query to
find matching jobs, with all the attendant performance implications for your
job databases.

## `$client->get_server_time( $driver )`

Given an open driver _$driver_ to a database, gets the current server time from the database.

# THE SCOREBOARD

The scoreboards can be used to monitor what the TheSchwartz::Worker sub-classes are
currently working on.  Once the scoreboard has been enabled in the workers with
`set_scoreboard` method the `thetop` utility (shipped with TheSchwartz distribution
in the `extras` directory) can be used to list all current jobs being worked on.

## `$client->set_scoreboard( $dir )`

Enables the scoreboard.  Setting this to `1` or `on` will cause TheSchwartz to create
a scoreboard file in a location it determines is optimal.

Passing in any other option sets the directory the TheSchwartz scoreboard directory should
be created in.  For example, if you set this to `/tmp` then this would create a directory
called `/tmp/theschwartz` and a scoreboard file `/tmp/theschwartz/scoreboard.pid` in it
(where pid is the current process pid.) 

## `$client->scoreboard()`

Returns the path to the current scoreboard file.

## `$client->start_scoreboard()`

Writes the current job information to the scoreboard file (called by the worker
in work\_safely before it actually starts working)

## `$client->end_scoreboard()`

Appends the current job duration to the end of the scoreboard file (called by
the worker in work\_safely once work has been completed)

## `$client->clean_scoreboard()`

Removes the scoreboard file (but not the scoreboard directory.)  Automatically
called by TheSchwartz during object destruction (i.e. when the instance goes
out of scope)

# PASSING IN AN EXISTING DRIVER

You can pass in a existing `Data::Object::Driver::DBI` object which also allows you
to reuse exist Database handles like so:

        my $dbh = DBI->connect( $dsn, "root", "", {
                RaiseError => 1,
                PrintError => 0,
                AutoCommit => 1,
            } ) or die $DBI::errstr;
        my $driver = Data::ObjectDriver::Driver::DBI->new( dbh => $dbh);
        return TheSchwartz->new(databases => [{ driver => $driver }]);

**Note**: it's important that the `RaiseError` and `AutoCommit` flags are 
set on the handle for various bits of functionality to work.

# COPYRIGHT, LICENSE & WARRANTY

This software is Copyright 2007, Six Apart Ltd, cpan@sixapart.com. All
rights reserved.

TheSchwartz is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

TheSchwartz comes with no warranty of any kind.
