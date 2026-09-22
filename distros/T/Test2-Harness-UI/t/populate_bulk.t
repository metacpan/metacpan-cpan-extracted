use Test2::V0;

BEGIN { $ENV{T2_HARNESS_UI_ENV} = 'dev' }

use Test2::Tools::QuickDB;
use DBIx::QuickDB;

use Test2::Harness::UI::Util qw/dbd_driver qdb_driver share_file/;
use Test2::Harness::UI::UUID qw/gen_uuid gen_deflated_uuid uuid_deflate uuid_inflate/;
use DateTime;

# Coverage, event, and reporting rows go to the database through multi-row
# INSERT statements in one transaction. This checks what arrives, that rows
# with differing columns and with UUID/DateTime objects are written as the
# database stores them, that a failure rolls the whole batch back, and that a
# statement rejected for a duplicate falls back to inserting its rows one at a
# time so the rest still land.

my $schema_name = skipall_unless_can_db($ENV{T2_HARNESS_UI_TEST_DB} ? [$ENV{T2_HARNESS_UI_TEST_DB}] : ['PostgreSQL', 'MySQL']);
$schema_name =~ s{^.*::}{}g;
note("Using driver '$schema_name'");

require Test2::Harness::UI::Config;
require Test2::Harness::UI::RunProcessor;

my $db = DBIx::QuickDB->build_db("populate_bulk_$$" => {driver => qdb_driver($schema_name), dbd_driver => dbd_driver($schema_name)});
my $dbh = $db->connect('quickdb', AutoCommit => 1, RaiseError => 1);
$dbh->do('CREATE DATABASE harness_ui') or die "Could not create db " . $dbh->errstr;
$db->load_sql(harness_ui => share_file('schema/' . $schema_name . '.sql'));

my $config = Test2::Harness::UI::Config->new(
    dbi_dsn     => $db->connect_string('harness_ui'),
    dbi_user    => '',
    dbi_pass    => '',
    single_user => 1,
    show_user   => 1,
    email       => 'exodist7@gmail.com',
);

my $schema  = $config->schema;
my $project = $schema->resultset('Project')->find_or_create({name => 'test', project_id => gen_uuid()});
my $user    = $schema->resultset('User')->find_or_create({username => 'root', user_id => gen_uuid(), role => 'user'});
my $run     = $schema->resultset('Run')->create({
    run_id     => gen_uuid(),
    mode       => 'complete',
    buffer     => 'none',
    status     => 'pending',
    user_id    => $user->user_id,
    project_id => $project->project_id,
});

my $processor = Test2::Harness::UI::RunProcessor->new(run => $run, config => $config, buffer => 1);

my $coverage = $schema->resultset('Coverage');

subtest run_coverage => sub {
    $processor->add_run_coverage({
        files => {
            'lib/A.pm' => {
                'a' => {'t/a.t' => ['*'], 't/b.t' => [{subtest => 'x'}]},
                '*' => {'t/a.t' => ['*']},
            },
            'lib/B.pm' => {
                'b' => {'t/b.t' => ['*']},
            },
        },
        testmeta => {
            't/a.t' => {manager => 'Manager'},
            't/b.t' => {},
        },
    });

    is($coverage->count, 4, "Four rows");
    ok($run->discard_changes->has_coverage, "Run knows it has coverage");

    my @rows = sort { $a->{test_file} cmp $b->{test_file} || $a->{source_file} cmp $b->{source_file} || $a->{source_sub} cmp $b->{source_sub} }
        map { $_->human_fields } $coverage->all;

    is(
        \@rows,
        [
            {test_file => 't/a.t', source_file => 'lib/A.pm', source_sub => '*', manager => 'Manager', metadata => ['*']},
            {test_file => 't/a.t', source_file => 'lib/A.pm', source_sub => 'a', manager => 'Manager', metadata => ['*']},
            {test_file => 't/b.t', source_file => 'lib/A.pm', source_sub => 'a', manager => undef,     metadata => ['*']},
            {test_file => 't/b.t', source_file => 'lib/B.pm', source_sub => 'b', manager => undef,     metadata => ['*']},
        ],
        "Rows carry the names, the manager, and the metadata; metadata is only kept when there is a manager"
    );
};

subtest duplicate => sub {
    my ($existing) = $coverage->all;
    my %dup = $existing->get_columns;

    my %new1 = (%dup, coverage_id => gen_deflated_uuid(), source_sub_id => $processor->get_source_sub_id('brand_new_1'));
    my %new2 = (%dup, coverage_id => gen_deflated_uuid(), source_sub_id => $processor->get_source_sub_id('brand_new_2'));

    # Two chunks: the first holds the duplicate and goes in a row at a time,
    # the second is replayed as one statement.
    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings => $_[0] };
        $processor->populate_bulk(Coverage => [\%dup, \%new1, \%new2], chunk => 2);
    }

    is($coverage->count, 6, "Both rows that were not duplicates were inserted");
    is(scalar(@warnings), 1, "One warning, the duplicate itself was skipped silently");
    like($warnings[0], qr/Duplicate found.*Populating 'Coverage' in chunks/s, "The fallback announced itself");
    unlike($warnings[0], qr/for Statement/, "The warning does not carry the statement and every bind value");
};

subtest duplicate_event => sub {
    my $job = $schema->resultset('Job')->create({job_key => gen_uuid(), job_id => gen_uuid(), job_ord => 1, run_id => $run->run_id});

    my $trace = gen_uuid();
    my $new   = gen_uuid();
    my $dup   = {event_id => gen_uuid(), job_key => $job->job_key, event_ord => 1};
    $processor->populate_bulk(Event => [$dup]);

    # The row after the duplicate carries a UUID object for trace_id, which
    # is CHAR(36) on MySQL. Recovery must write it the same way the normal
    # path does.
    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings => $_[0] };
        $processor->populate_bulk(Event => [$dup, {event_id => $new, job_key => $job->job_key, event_ord => 2, trace_id => $trace}]);
    }

    my $events = $schema->resultset('Event');
    is($events->count, 2, "The new row landed");
    is(scalar(@warnings), 1, "One duplicate warning");
    is(uuid_inflate($events->find({event_id => $new})->trace_id)->string, $trace->string, "trace_id written in the column's form during recovery");

    my $before = $events->count;
    my $err = dies {
        local $SIG{__WARN__} = sub { 1 };
        $processor->populate_bulk(Event => [$dup, {event_id => gen_uuid(), job_key => gen_uuid(), event_ord => 3}]);
    };
    ok($err, "A non-duplicate error during recovery is fatal");
    unlike($err, qr/duplicate/i, "It is the real error, not the duplicate");
    is($events->count, $before, "The bad row was not written");
};

subtest chunking => sub {
    like(dies { $processor->populate_bulk(Coverage => [{}], chunk => 0) }, qr/chunk must be a positive integer/, "Zero chunk size rejected");

    my ($existing) = $coverage->all;
    my %tmpl = $existing->get_columns;
    my @rows = map { {%tmpl, coverage_id => gen_deflated_uuid(), source_sub_id => $processor->get_source_sub_id("bytes_$_")} } 1 .. 5;

    my $executes = 0;
    {
        no warnings 'redefine';
        my $orig = \&DBI::st::execute;
        local *DBI::st::execute = sub { $executes++; goto &$orig };
        $processor->populate_bulk(Coverage => \@rows, chunk_bytes => 1);
    }

    is($executes, 5, "Byte cap split every row into its own statement");
    is($coverage->count, 11, "All rows landed");
};

subtest events => sub {
    my $job = $schema->resultset('Job')->create({
        job_key => gen_uuid(),
        job_id  => gen_uuid(),
        job_ord => 2,
        run_id  => $run->run_id,
    });

    my $stamp = DateTime->from_epoch(epoch => 1758475500.25, time_zone => 'UTC');

    my ($a, $b, $c) = map { gen_uuid() } 1 .. 3;
    my @rows = (
        {event_id => $a, job_key => $job->job_key, event_ord => 1, stamp => $stamp, facets => '{"x":1}', facets_line => 5},
        {event_id => $b, job_key => $job->job_key, event_ord => 2, stamp => $stamp, orphan => '{"y":2}', parent_id => $a, nested => 1},
        {event_id => $c, job_key => $job->job_key, event_ord => 3, stamp => undef, trace_id => uuid_inflate($a->string)},
    );

    # Chunk of 2 so the batch spans two statements.
    $processor->populate_bulk(Event => \@rows, chunk => 2);

    my $events = $schema->resultset('Event')->search({event_ord => {'>=' => 1}, job_key => $job->job_key});
    is($events->count, 3, "Three rows");

    my $ea = $events->find({event_id => $a});
    my $eb = $events->find({event_id => $b});
    my $ec = $events->find({event_id => $c});

    is($ea->facets, {x => 1}, "JSON column stored as given");
    is($ea->facets_line, 5, "Column only some rows have");
    is($ea->orphan, undef, "Column this row did not name is NULL");
    is($ea->stamp->epoch, 1758475500, "DateTime object formatted for the database");
    is($ea->parent_id, undef, "No parent");

    is($eb->orphan, {y => 2}, "Other JSON column");
    is(uuid_inflate($eb->parent_id)->string, $a->string, "UUID object deflated and readable");
    is($eb->nested, 1, "Plain value");

    is($ec->stamp, undef, "NULL stamp");
    is(uuid_inflate($ec->trace_id)->string, $a->string, "UUID from string");
};

subtest reporting => sub {
    my ($job)   = $schema->resultset('Job')->search({job_ord => 2})->all;
    my ($event) = $schema->resultset('Event')->search({job_key => $job->job_key})->all;

    my %mixin = (
        user_id    => $user->user_id,
        run_id     => $run->run_id,
        run_ord    => $run->run_ord,
        project_id => $project->project_id,
        job_try    => 0,
        job_key    => $job->job_key,
    );

    $processor->populate_bulk(Reporting => [
        {reporting_id => gen_uuid(), duration => 1.5, pass => 1, fail => 0, abort => 0, retry => 0, %mixin},
        {reporting_id => gen_uuid(), duration => 0.5, pass => 0, fail => 1, abort => 0, retry => 0, subtest => 'foo', event_id => $event->event_id, %mixin},
    ]);

    my $reporting = $schema->resultset('Reporting');
    is($reporting->count, 2, "Two rows");

    my ($sub) = $reporting->search({subtest => 'foo'})->all;
    ok($sub, "Row with the extra columns");
    is(uuid_inflate($sub->event_id)->string, uuid_inflate($event->event_id)->string, "event_id carried over");
    is($sub->duration, 0.5, "duration");

    my ($top) = $reporting->search({subtest => undef})->all;
    ok($top, "Row without the extra columns");
    is($top->event_id, undef, "event_id NULL where the row did not name it");
};

subtest rollback => sub {
    my $events = $schema->resultset('Event');
    my $before = $events->count;
    my ($job)  = $schema->resultset('Job')->search({job_ord => 2})->all;

    my @rows = (
        {event_id => gen_uuid(), job_key => $job->job_key, event_ord => 10},
        {event_id => gen_uuid(), job_key => gen_uuid(), event_ord => 11},    # job does not exist
    );

    like(
        dies { $processor->populate_bulk(Event => \@rows, chunk => 1) },
        qr/Populate 'Event'/,
        "Non-duplicate error is fatal"
    );

    is($events->count, $before, "First chunk rolled back with the second");
};

subtest bad_value => sub {
    like(
        dies { $processor->populate_bulk(Event => [{event_id => gen_uuid(), facets => {x => 1}}]) },
        qr/Cannot write a HASH to column 'facets' of 'Event'/,
        "Refuses a reference the database cannot store"
    );
};

subtest empty => sub {
    ok(lives { $processor->populate_bulk(Coverage => []) }, "Nothing to do with no rows");
    ok(lives { $processor->populate_bulk(Coverage => undef) }, "Nothing to do with no list");
};

done_testing;
