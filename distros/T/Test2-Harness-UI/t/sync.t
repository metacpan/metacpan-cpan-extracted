use Test2::V0;
use Test2::IPC;
use Test2::Tools::QuickDB;

BEGIN { $ENV{T2_HARNESS_UI_ENV} = 'dev' }
use Test2::Harness::UI::Sync;
use Test2::Harness::UI::UUID qw/uuid_inflate gen_uuid/;
use Test2::Harness::UI::Util qw/dbd_driver qdb_driver share_file/;

my %UUIDF = (MySQL => 'binary', PostgreSQL => 'string');

my @pids;
for my $schema_name (qw/MySQL PostgreSQL/) {
    my $pid = fork;
    if ($pid) {
        push @pids => $pid;
        next;
    }

    subtest "$schema_name sync" => sub {
        my $driver = qdb_driver($schema_name);
        skipall_unless_can_db(driver => $driver);
        require DBIx::QuickDB;

        my $uuidf = $UUIDF{$schema_name};

        my %dbs;
        for my $name (qw/a b/) {
            my $db  = DBIx::QuickDB->build_db("harness_ui_sync_$name" => {driver => $driver, dbd_driver => dbd_driver($schema_name)});
            my $dbh = $db->connect('quickdb', AutoCommit => 1, RaiseError => 1);
            $dbh->do('CREATE DATABASE harness_ui') or die "Could not create db " . $dbh->errstr;
            $db->load_sql(harness_ui => share_file("schema/${schema_name}.sql"));
            $dbs{$name} = $db;
        }

        my $connect = sub { $dbs{$_[0]}->connect('harness_ui', AutoCommit => 1, RaiseError => 1, PrintError => 0) };

        my $seed = sub {
            my ($dbh)      = @_;
            my $user_id    = gen_uuid();
            my $project_id = gen_uuid();
            $dbh->do("INSERT INTO users(user_id, username, role) VALUES(?, 'root', 'admin')", undef, $user_id->$uuidf);
            $dbh->do("INSERT INTO projects(project_id, name) VALUES(?, 'test')",              undef, $project_id->$uuidf);
            return ($user_id, $project_id);
        };

        my $add_run = sub {
            my ($dbh, $ids, $run_id, $status) = @_;
            $dbh->do(
                "INSERT INTO runs(run_id, user_id, project_id, status, mode) VALUES(?, ?, ?, ?, 'qvfd')",
                undef, uuid_inflate($run_id)->$uuidf, $ids->[0]->$uuidf, $ids->[1]->$uuidf, $status,
            );
        };

        my $dbh_a = $connect->('a');
        my $dbh_b = $connect->('b');
        my $ids_a = [$seed->($dbh_a)];
        my $ids_b = [$seed->($dbh_b)];

        my %runs = map { ($_ => gen_uuid()->string) } qw{
            absent_complete absent_canceled
            src_broken src_pending src_running
            dst_complete dst_canceled dst_broken dst_pending dst_running
        };

        $add_run->($dbh_a, $ids_a, $runs{absent_complete}, 'complete');
        $add_run->($dbh_a, $ids_a, $runs{absent_canceled}, 'canceled');
        $add_run->($dbh_a, $ids_a, $runs{src_broken},      'broken');
        $add_run->($dbh_a, $ids_a, $runs{src_pending},     'pending');
        $add_run->($dbh_a, $ids_a, $runs{src_running},     'running');

        for my $status (qw/complete canceled broken pending running/) {
            $add_run->($dbh_a, $ids_a, $runs{"dst_$status"}, 'complete');
            $add_run->($dbh_b, $ids_b, $runs{"dst_$status"}, $status);
        }

        my $sync = Test2::Harness::UI::Sync->new();

        is(
            [sort @{$sync->get_runs($dbh_b, all => 1)}],
            [sort map { $runs{"dst_$_"} } qw/complete canceled broken pending running/],
            "get_runs(all => 1) returns runs in every state",
        );

        my $delta;
        my $warnings = warnings { $delta = $sync->run_delta($dbh_a, $dbh_b) };

        is(
            [sort @{$delta->{missing_in_b}}],
            [sort @runs{qw/absent_complete absent_canceled/}],
            "Only finished source runs absent from the destination are selected, destination status does not matter",
        );
        is($delta->{missing_in_a}, [], "Nothing missing in a");

        is(
            $warnings,
            bag {
                item match(qr/Run '$runs{"dst_$_"}' is finished in database A, but is pending, running, or broken in database B/) for qw/broken pending running/;
                end;
            },
            "Warned about runs with mismatched states",
        );

        # The sync dump queries do not currently work against the PostgreSQL
        # schema (jobs.fields), so only test the import on MySQL.
        return unless $schema_name eq 'MySQL';

        # Simulate a stale delta: include a run that already exists in the destination.
        my $to_dbh = $connect->('b');
        $sync->sync(
            from_dbh         => $connect->('a'),
            to_dbh           => $to_dbh,
            run_ids          => [@{$delta->{missing_in_b}}, $runs{dst_broken}],
            from_uuid_format => $uuidf,
            to_uuid_format   => $uuidf,
        );
        $to_dbh->{InactiveDestroy} = 1;

        my $check = $connect->('b');
        my $rows  = $check->selectall_arrayref("SELECT run_id, status FROM runs");
        my %got   = map { (uuid_inflate($_->[0])->string => $_->[1]) } @$rows;

        is(
            \%got,
            {
                $runs{absent_complete} => 'complete',
                $runs{absent_canceled} => 'canceled',
                map { ($runs{"dst_$_"} => $_) } qw/complete canceled broken pending running/,
            },
            "Absent runs were imported, existing destination run was left untouched",
        );
    };

    exit 0;
}

waitpid($_, 0) for @pids;

done_testing;
