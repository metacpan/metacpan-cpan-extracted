use Test2::V0;
use Test2::IPC;
use Test2::Tools::QuickDB;
use File::Temp;
use Time::HiRes;

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

        # Capture everything printed to STDOUT (or STDERR) by sync() and its
        # loader child. This has to go through a file since the child cannot
        # write into the parent's memory.
        my $capture = sub {
            my ($code, $fh) = @_;
            $fh //= \*STDOUT;
            my $tmp = File::Temp->new();
            open(my $orig, '>&', $fh)  or die "Could not dup handle: $!";
            open($fh,      '>&', $tmp) or die "Could not redirect handle: $!";
            my $ok  = eval { $code->(); 1 };
            my $err = $@;
            $fh->flush();
            open($fh, '>&', $orig) or die "Could not restore handle: $!";
            die $err unless $ok;
            seek($tmp, 0, 0);
            return join '' => <$tmp>;
        };

        my $usable = sub {
            my ($dbh, $name) = @_;
            ok(eval { $dbh->selectrow_array('SELECT 1') }, "$name handle is still usable") or diag($@);
        };

        my $add_children = sub {
            my ($dbh, $run_id, %params) = @_;
            my $job_key = gen_uuid();
            my $job_id  = $params{job_id} // gen_uuid();
            my $file_id = gen_uuid();
            $dbh->do("INSERT INTO test_files(test_file_id, filename) VALUES(?, ?)", undef, $file_id->$uuidf, "t/$job_key.t");
            $dbh->do(
                "INSERT INTO jobs(job_key, job_id, job_ord, run_id, status, test_file_id) VALUES(?, ?, 1, ?, 'complete', ?)",
                undef, $job_key->$uuidf, $job_id->$uuidf, uuid_inflate($run_id)->$uuidf, $file_id->$uuidf,
            );
            $dbh->do(
                "INSERT INTO run_fields(run_field_id, run_id, name, details) VALUES(?, ?, 'rf', 'run field')",
                undef, gen_uuid()->$uuidf, uuid_inflate($run_id)->$uuidf,
            );
            $dbh->do(
                "INSERT INTO job_fields(job_field_id, job_key, name, details) VALUES(?, ?, 'jf', 'job field')",
                undef, gen_uuid()->$uuidf, $job_key->$uuidf,
            );
            return $job_id;
        };

        my %count_from = (
            runs       => 'runs',
            run_fields => 'run_fields',
            jobs       => 'jobs',
            job_fields => 'job_fields JOIN jobs USING(job_key)',
        );

        my $count_children = sub {
            my ($dbh, $run_id) = @_;
            my $id = uuid_inflate($run_id)->$uuidf;
            return {map { ($_ => $dbh->selectrow_array("SELECT COUNT(*) FROM $count_from{$_} WHERE run_id = ?", undef, $id)) } keys %count_from};
        };

        my %all_rows = (runs => 1, run_fields => 1, jobs => 1, job_fields => 1);
        my %no_rows  = (runs => 0, run_fields => 0, jobs => 0, job_fields => 0);

        subtest stale_delta => sub {
            # Simulate a stale delta: include a run that already exists in the destination.
            my $from_dbh = $connect->('a');
            my $to_dbh   = $connect->('b');
            $sync->sync(
                from_dbh         => $from_dbh,
                to_dbh           => $to_dbh,
                run_ids          => [@{$delta->{missing_in_b}}, $runs{dst_broken}],
                from_uuid_format => $uuidf,
                to_uuid_format   => $uuidf,
            );

            $usable->($from_dbh, "Source");
            $usable->($to_dbh,   "Destination");

            my $rows = $to_dbh->selectall_arrayref("SELECT run_id, status FROM runs");
            my %got  = map { (uuid_inflate($_->[0])->string => $_->[1]) } @$rows;

            is(
                \%got,
                {
                    $runs{absent_complete} => 'complete',
                    $runs{absent_canceled} => 'canceled',
                    map { ($runs{"dst_$_"} => $_) } qw/complete canceled broken pending running/,
                },
                "Absent runs were imported, existing destination run was left untouched",
            );

            ok($from_dbh->disconnect, "Source handle disconnects cleanly");
            ok($to_dbh->disconnect,   "Destination handle disconnects cleanly");
        };

        subtest one_run => sub {
            my $run_id = gen_uuid()->string;
            $add_run->($dbh_a, $ids_a, $run_id, 'complete');
            $add_children->($dbh_a, $run_id);

            my $from_dbh = $connect->('a');
            my $to_dbh   = $connect->('b');

            my $out = $capture->(
                sub {
                    $sync->sync(
                        from_dbh         => $from_dbh,
                        to_dbh           => $to_dbh,
                        run_ids          => [$run_id],
                        from_uuid_format => $uuidf,
                        to_uuid_format   => $uuidf,
                        debug            => 1,
                    );
                }
            );

            like($out, qr{^\s*Dumped run 1/1: \Q$run_id\E$}m, "Reported the dump");
            like($out, qr{^Imported run 1/1: \Q$run_id\E$}m,  "Reported the import of the final run");
            unlike($out, qr/BROKEN/, "Nothing broken");

            # The parent's handles must survive the loader child exiting.
            $usable->($from_dbh, "Source");
            $usable->($to_dbh,   "Destination");

            is(
                $count_children->($to_dbh, $run_id),
                \%all_rows,
                "Run and its child rows are in the destination after the first sync",
            );

            is($sync->run_delta($from_dbh, $to_dbh)->{missing_in_b}, [], "Nothing left to sync");

            ok($from_dbh->disconnect, "Source handle disconnects cleanly");
            ok($to_dbh->disconnect,   "Destination handle disconnects cleanly");
        };

        subtest multi_run_broken_last => sub {
            my @good = map { gen_uuid()->string } 1 .. 3;
            for my $run_id (@good) {
                $add_run->($dbh_a, $ids_a, $run_id, 'complete');
                $add_children->($dbh_a, $run_id);
            }

            # The final run has a job whose (job_id, job_try) already exists in
            # the destination under another run, so its import fails.
            my $blocker = gen_uuid()->string;
            $add_run->($dbh_b, $ids_b, $blocker, 'complete');
            my $job_id = $add_children->($dbh_b, $blocker);

            my $bad = gen_uuid()->string;
            $add_run->($dbh_a, $ids_a, $bad, 'complete');
            $add_children->($dbh_a, $bad, job_id => $job_id);

            my $from_dbh = $connect->('a');
            my $to_dbh   = $connect->('b');

            my $out = $capture->(
                sub {
                    $sync->sync(
                        from_dbh         => $from_dbh,
                        to_dbh           => $to_dbh,
                        run_ids          => [@good, $bad],
                        from_uuid_format => $uuidf,
                        to_uuid_format   => $uuidf,
                        debug            => 1,
                    );
                }
            );

            my $i = 0;
            for my $run_id (@good) {
                $i++;
                my @imported = ($out =~ m/^Imported run \Q$i\E\/4: \Q$run_id\E$/mg);
                is(scalar(@imported),                   1,          "Run $i reported as imported exactly once");
                is($count_children->($to_dbh, $run_id), \%all_rows, "Run $i imported with child rows");
            }

            my @broken = ($out =~ m/^\s*BROKEN run 4\/4: \Q$bad\E$/mg);
            is(scalar(@broken), 1, "Final broken run reported exactly once");
            unlike($out, qr/Imported run 4\/4/, "Final broken run not reported as imported");
            is($count_children->($to_dbh, $bad), \%no_rows, "Final broken run was rolled back");

            $usable->($from_dbh, "Source");
            $usable->($to_dbh,   "Destination");
        };

        # The loader fails once all data was sent, or before the parent writes
        # anything, so the parent's writes hit a closed pipe.
        my $marker = File::Temp::tempdir(CLEANUP => 1) . "/loader-closed";
        my %stubs  = (
            after_data => sub {
                my ($self, %params) = @_;
                1 while readline($params{rh});
                die "loader boom\n";
            },
            early => sub {
                my ($self, %params) = @_;
                close($params{rh});
                open(my $fh, '>', $marker) or die "Could not create '$marker': $!";
                close($fh)                 or die "Could not close '$marker': $!";
                die "loader boom\n";
            },
        );

        for my $case (sort keys %stubs) {
            subtest "loader_failure_$case" => sub {
                my $run_id = gen_uuid()->string;
                $add_run->($dbh_a, $ids_a, $run_id, 'complete');

                my $from_dbh = $connect->('a');
                my $to_dbh   = $connect->('b');

                no warnings 'redefine';
                local *Test2::Harness::UI::Sync::read_sync = $stubs{$case};

                my $render_runs = \&Test2::Harness::UI::Sync::render_runs;
                local *Test2::Harness::UI::Sync::render_runs = sub {
                    my $deadline = Time::HiRes::time() + 10;
                    until ($case ne 'early' || -e $marker) {
                        die "Loader did not close the pipe within 10 seconds\n" if Time::HiRes::time() > $deadline;
                        Time::HiRes::sleep(0.01);
                    }
                    return $render_runs->(@_);
                };

                # Do not use dies {} or warnings {} here: dies {} localizes $?,
                # which clobbers the loader child's exit code when it exits from
                # inside that scope, and the child's warnings would only be
                # captured in the child's copy of the array.
                my $err;
                my $stderr = $capture->(
                    sub {
                        local $SIG{__WARN__};
                        local $SIG{PIPE} = 'DEFAULT';    # It may be inherited as ignored
                        eval {
                            $sync->sync(
                                from_dbh         => $from_dbh,
                                to_dbh           => $to_dbh,
                                run_ids          => [$run_id],
                                from_uuid_format => $uuidf,
                                to_uuid_format   => $uuidf,
                                name             => 'failing loader',
                            );
                            1;
                        } or $err = $@;
                    },
                    \*STDERR
                );

                like($err,    qr/Loader exited badly/,                           "sync() dies when the loader fails");
                like($stderr, qr/\[Loader\] failing loader failed: loader boom/, "Loader reported why it failed");
                like($stderr, qr/\[Loader\] failing loader exited badly: 255/,   "Parent reported the loader exit code");

                $usable->($from_dbh, "Source");
                $usable->($to_dbh,   "Destination");
            };
        }

        subtest read_sync_leaves_handle => sub {
            my $run_id = gen_uuid()->string;
            $add_run->($dbh_a, $ids_a, $run_id, 'complete');
            $add_children->($dbh_a, $run_id);

            my $jsonl = '';
            open(my $wh, '>', \$jsonl) or die "Could not open in-memory handle: $!";
            $sync->write_sync(dbh => $dbh_a, run_ids => [$run_id], wh => $wh, uuidf => $uuidf);
            close($wh);

            open(my $rh, '<', \$jsonl) or die "Could not open in-memory handle: $!";
            my $to_dbh = $connect->('b');
            $sync->read_sync(dbh => $to_dbh, run_ids => [$run_id], rh => $rh, uuidf => $uuidf);

            $usable->($to_dbh, "Caller supplied");
            ok($to_dbh->{AutoCommit}, "AutoCommit setting was restored");
            is(
                $count_children->($to_dbh, $run_id),
                \%all_rows,
                "Run and its child rows were imported and committed",
            );
        };
    };

    exit 0;
}

for my $pid (@pids) {
    waitpid($pid, 0);
    is($?, 0, "Forked test process $pid exited cleanly");
}

done_testing;
