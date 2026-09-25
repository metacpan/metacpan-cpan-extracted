package Test2::Harness::UI::RunProcessor;
use strict;
use warnings;

our $VERSION = '0.000149';

use DateTime;
use Data::GUID;
use Time::HiRes qw/time/;
use List::Util qw/first min max/;
use MIME::Base64 qw/decode_base64/;

use Clone qw/clone/;
use Carp qw/croak confess/;
use Scalar::Util qw/blessed/;
use bytes ();

use Test2::Util::Facets2Legacy qw/causes_fail/;

use Test2::Harness::UI::Util qw/format_duration is_invalid_subtest_name/;

use Test2::Harness::UI::UUID qw/gen_uuid gen_deflated_uuid uuid_inflate uuid_deflate uuid_mass_deflate/;
use Test2::Harness::Util::JSON qw/encode_json decode_json/;
use JSON::PP();

use Test2::Harness::UI::Util::ImportModes qw{
    %MODES
    record_all_events
    event_in_mode
    mode_check
    record_subtest_events
};

use Test2::Harness::UI::Util::HashBase qw{
    <config

    <running <jobs <binaries

    signal

    <coverage <uncover <new_jobs <id_cache <file_cache

    <mode
    <interval <last_flush
    <run <run_id +run_id_deflated +bulk_byte_cap
    +user +user_id
    +project +project_id

    <first_stamp <last_stamp

    <passed <failed <retried
    <job0_id <job_ord

    <disconnect_retry
};

sub trim_error {
    my ($msg, $err) = @_;

    my @lines;
    if ($ENV{TEST2_HARNESS_IMPORT_VERBOSE}) {
        @lines = ($err);
    }
    else {
        @lines = split /\n/, $err;
        @lines = (@lines[1 .. 5], "\n[... TRIMMED, set the TEST2_HARNESS_IMPORT_VERBOSE=1 env var to see the entire error ...]\n", @lines[-5 .. -1]) if @lines > 12;
    }

    return join("\n" => $msg, @lines) . "\n";
}

sub retry_on_disconnect {
    my $self = shift;
    my ($description, $callback) = @_;

    my ($attempt, $err);
    for my $i (0 .. ($self->{+DISCONNECT_RETRY} - 1)) {
        $attempt = $i;
        return 1 if eval { $callback->(); 1 };
        $err = $@;

        # Only the driver's message decides. DBI appends the statement and
        # bind values, and Carp a stack trace, and either can contain
        # "connect" (event facets, or this sub's own name).
        (my $msg = $err) =~ s/\[for Statement.*//s;
        ($msg) = split /\n/, $msg;
        last unless $msg =~ m/(gone away|connect|timeout)/i;

        # Try to fix the connection
        for (1 .. 10) {
            $self->schema->storage->disconnect;
            eval { $self->schema->storage->ensure_connected };
            last if $self->schema->storage->connected;
            sleep 1;
        }
    }

    die trim_error(qq{Failed "$description" (attempt $attempt)}, $err);
}

sub populate {
    my $self = shift;
    my ($type, $data) = @_;

    return unless $data && @$data;

    $self->retry_on_disconnect(
        "Populate '$type'",
        sub {
            my $rs = $self->schema->resultset($type);
            my $ok = eval { $rs->populate($data); 1 };
            my $err = $@;
            return 1 if $ok;

            die $err unless $err =~ m/duplicate/i;

            warn "Duplicate found:\n====\n$err\n====\n\nPopulating '$type' 1 at a time.\n";
            for my $item (@$data) {
                uuid_mass_deflate($item);
                next if eval { $rs->create($item); 1 };
                my $err = $@;

                # I need to track down why we still get duplicates (Coverage mainly) for now skip them.
                next if $err =~ m/duplicate/i;

                # Actual error
                warn $err;
            }

            return 1;
        }
    );
}

# DBIx::Class populate() hands rows to DBI's execute_for_fetch(), and neither
# DBD::Pg nor DBD::mysql batch that, so every row is its own round trip to
# the database. Events and coverage arrive in the hundreds of thousands of
# rows for one run, so those go out as multi-row INSERT statements instead,
# all inside one transaction.
#
# Nothing here goes through the Result class, so rows must already hold what
# the database stores: JSON encoded, ids either deflated or still
# Test2::Harness::UI::UUID objects (those and DateTime objects are converted
# here, see _bulk_value). Rows need not all name the same columns, the
# column list is the union and missing columns are NULL.
#
# Duplicate recovery needs AutoCommit: on a duplicate the transaction rolls
# back and the chunks are replayed outside one, so do not call this inside
# txn_do().
sub populate_bulk {
    my $self = shift;
    my ($type, $data, %params) = @_;

    return unless $data && @$data;

    # Past this many rows the statement gets slower per row on PostgreSQL,
    # and MySQL gains nothing from it. The byte cap keeps a statement under
    # MySQL's max_allowed_packet when events carry large facets.
    my $max_rows  = $params{chunk}       // 100;
    my $max_bytes = $params{chunk_bytes} // $self->bulk_byte_cap;
    croak "chunk must be a positive integer, got '$max_rows'" unless $max_rows =~ m/^\d+$/ && $max_rows > 0;

    my $schema  = $self->schema;
    my $storage = $schema->storage;
    my $source  = $schema->resultset($type)->result_source;

    my %seen;
    my @cols = sort grep { !$seen{$_}++ } map { keys %$_ } @$data;

    # Binary columns (bytea on PostgreSQL) need their type bound, or the
    # driver sends the bytes as text.
    my $colinfo = $source->columns_info(\@cols);
    my @attrs   = map { $storage->bind_attribute_by_data_type($colinfo->{$_}->{data_type}) } @cols;
    my $attrs   = (grep { $_ } @attrs) ? \@attrs : undef;

    # Convert everything before touching the database so a bad value dies
    # cleanly instead of inside a transaction. Every path below, including
    # duplicate recovery, writes these values so no row can be converted two
    # different ways.
    my @chunks = ([]);
    my $bytes  = 0;
    for my $item (@$data) {
        my $values = [map { $self->_bulk_value($type, $_, $colinfo->{$_}->{data_type}, $item->{$_}) } @cols];

        my $size = 0;
        $size += bytes::length($_) for grep { defined } @$values;

        if (@{$chunks[-1]} && (@{$chunks[-1]} >= $max_rows || $bytes + $size > $max_bytes)) {
            push @chunks => [];
            $bytes = 0;
        }

        push @{$chunks[-1]} => $values;
        $bytes += $size;
    }

    my $dbh    = $storage->dbh;
    my $insert = "INSERT INTO " . $dbh->quote_identifier($source->name) . " (" . join(', ', map { $dbh->quote_identifier($_) } @cols) . ") VALUES ";
    my $row    = "(" . join(', ', ('?') x @cols) . ")";

    my $insert_chunk = sub {
        my ($dbh, $chunk) = @_;

        my $sth = $dbh->prepare_cached($insert . join(', ', ($row) x @$chunk));

        if ($attrs) {
            for my $r (0 .. $#$chunk) {
                for my $c (0 .. $#cols) {
                    my $attr = $attrs->[$c] or next;
                    $sth->bind_param($r * @cols + $c + 1, undef, $attr);
                }
            }
        }

        $sth->execute(map { @$_ } @$chunk);
    };

    $self->retry_on_disconnect(
        "Populate '$type'",
        sub {
            my $ok = eval {
                $schema->txn_do(sub { $storage->dbh_do(sub { $insert_chunk->($_[1], $_) for @chunks }) });
                1;
            };
            my $err = $@;
            return 1 if $ok;

            die $err unless $err =~ m/duplicate/i;

            # The transaction rolled back, so nothing went in. Redo it with
            # autocommit, and only the chunk that holds the duplicate goes
            # in one row at a time. Chunks before a later failure stay
            # committed. DBI appends the whole statement and every bind value
            # to the error, drop those from the warning.
            (my $short = $err) =~ s/\s*\[for Statement.*//s;
            warn "Duplicate found:\n====\n$short\n====\n\nPopulating '$type' in chunks, falling back to 1 at a time on duplicates.\n";
            for my $chunk (@chunks) {
                next if eval { $storage->dbh_do(sub { $insert_chunk->($_[1], $chunk) }); 1 };
                my $err = $@;
                die $err unless $err =~ m/duplicate/i;

                for my $values (@$chunk) {
                    next if eval { $storage->dbh_do(sub { $insert_chunk->($_[1], [$values]) }); 1 };
                    my $err = $@;

                    # Only duplicates may be skipped, anything else is a lost
                    # row and must fail the import.
                    next if $err =~ m/duplicate/i;
                    die $err;
                }
            }

            return 1;
        }
    );

    return;
}

# MySQL rejects a statement larger than max_allowed_packet and drops the
# connection, and DBD::mysql interpolates the bind values into the statement
# text with escaping, so stay well under it. PostgreSQL has no such limit.
sub bulk_byte_cap {
    my $self = shift;

    return $self->{+BULK_BYTE_CAP} //= do {
        my $cap = 4 * 1024 * 1024;

        if ($Test2::Harness::UI::Schema::LOADED && $Test2::Harness::UI::Schema::LOADED =~ m/mysql/i) {
            my ($packet) = $self->schema->storage->dbh->selectrow_array('SELECT @@max_allowed_packet');
            $cap = min($cap, int($packet / 2)) if $packet;
        }

        $cap;
    };
}

sub _bulk_value {
    my $self = shift;
    my ($type, $col, $data_type, $val) = @_;

    return $val unless ref $val;

    if (blessed($val)) {
        # MySQL keeps most ids in BINARY(16) but some (trace_id) in CHAR(36),
        # so the column decides the form, not the database.
        return (($data_type // '') =~ m/binary/i ? $val->binary : $val->string) if $val->isa('Test2::Harness::UI::UUID');
        return $self->schema->storage->datetime_parser->format_datetime($val) if $val->isa('DateTime');
        return "$val" if overload::Method($val, '""');
    }

    die "Cannot write a " . ref($val) . " to column '$col' of '$type', populate_bulk() rows must hold what the database stores\n";
}

sub format_stamp {
    my $self = shift;
    my $stamp = shift;
    return undef unless $stamp;

    unless (ref($stamp)) {
        $self->{+FIRST_STAMP} = $self->{+FIRST_STAMP} ? min($self->{+FIRST_STAMP}, $stamp) : $stamp;
        $self->{+LAST_STAMP}  = $self->{+LAST_STAMP}  ? max($self->{+LAST_STAMP}, $stamp)  : $stamp;
    }

    return DateTime->from_epoch(epoch => $stamp, time_zone => 'local');
}

sub schema { $_[0]->{+CONFIG}->schema }

sub init {
    my $self = shift;

    croak "'config' is a required attribute"
        unless $self->{+CONFIG};

    $self->{+DISCONNECT_RETRY} //= 15;

    my $run;
    if ($run = $self->{+RUN}) {
        $self->{+RUN_ID} = $run->run_id;
        $self->{+MODE}   = $MODES{$run->mode};

        $self->retry_on_disconnect("update status for run '$self->{+RUN_ID}'" => sub { $run->update({status => 'pending'}) });
    }
    else {
        my $run_id = $self->{+RUN_ID} // croak "either 'run' or 'run_id' must be provided";
        my $mode   = $self->{+MODE}   // croak "'mode' is a required attribute unless 'run' is specified";
        $self->{+MODE} = $MODES{$mode} // croak "Invalid mode '$mode'";

        my $schema = $self->schema;
        my $run = $schema->resultset('Run')->create({
            run_id     => $run_id,
            user_id    => $self->user_id,
            project_id => $self->project_id,
            mode       => $mode,
            status     => 'pending',
        });

        $self->{+RUN} = $run;
    }

    $run->discard_changes;

    $self->{+PROJECT_ID} //= $run->project_id;

    $self->{+RUN_ID}     = uuid_inflate($self->{+RUN_ID});
    $self->{+USER_ID}    = uuid_inflate($self->{+USER_ID});
    $self->{+PROJECT_ID} = uuid_inflate($self->{+PROJECT_ID});

    $self->{+ID_CACHE} = {};
    $self->{+COVERAGE} = [];

    $self->{+PASSED} = 0;
    $self->{+FAILED} = 0;

    $self->{+JOB_ORD} = 1;
    $self->{+JOB0_ID} = gen_uuid();
}

sub flush_all {
    my $self = shift;

    my $all = $self->{+JOBS};
    for my $jobs (values %$all) {
        for my $job (values %$jobs) {
            $job->{done} = 'end';
            $self->flush(job => $job);
        }
    }

    $self->flush_events();
    $self->flush_reporting();
}

sub flush {
    my $self = shift;
    my %params = @_;

    my $job = $params{job} or croak "job is required";
    my $res = $job->{result};

    my $bmode = $self->run->buffer;
    my $int = $self->{+INTERVAL};

    # Always update if needed
    $self->retry_on_disconnect("update run" => sub { $self->run->insert_or_update() });

    my $flush = $params{force} ? 'force' : 0;
    $flush ||= 'always' if $bmode eq 'none';
    $flush ||= 'diag' if $bmode eq 'diag' && $res->fail && $params{is_diag};
    $flush ||= 'job' if $job->{done};
    $flush ||= 'status' if $res->is_column_changed('status');
    $flush ||= 'fail' if $res->is_column_changed('fail');

    if ($int && !$flush) {
        my $last = $self->{+LAST_FLUSH};
        $flush = 'interval' if !$last || $int < time - $last;
    }

    return "" unless $flush;
    $self->{+LAST_FLUSH} = time;

    $self->retry_on_disconnect("update job result" => sub { $res->update() });

    $self->flush_events();
    $self->flush_reporting();

    if (my $done = $job->{done}) {
        # Last time we need to write this, so clear it.
        delete $self->{+JOBS}->{$job->{job_id}}->{$job->{job_try}};

        unless ($res->status eq 'complete') {
            my $status = $self->{+SIGNAL} ? 'canceled' : 'broken';
            $status = 'canceled' if $done eq 'end';
            $res->status($status);
        }

        # Normalize the fail/pass
        my $fail = $res->fail ? 1 : 0;
        $res->fail($fail);

        $res->normalize_to_mode(mode => $self->{+MODE});
    }

    $self->retry_on_disconnect("update job result" => sub { $res->update() });

    return $flush;
}

sub flush_events {
    my $self = shift;

    return if mode_check($self->{+MODE}, 'summary');

    my @write;

    my $jobs = $self->{+JOBS};
    for my $tries (values %$jobs) {
        for my $job (values %$tries) {
            my $events = $job->{events};
            my $deferred = $job->{deffered_events} //= [];

            if (record_all_events(mode => $self->{+MODE}, job => $job->{result})) {
                push @write => (@$deferred, @$events);
                @$deferred = ();
            }
            else {
                for my $event (@$events) {
                    if (event_in_mode(event => $event, record_all_event => 0, mode => $self->{+MODE}, job => $job->{result})) {
                        push @write => $event;
                    }
                    else {
                        push @$deferred => $event;
                    }
                }
            }

            @$events = ();
        }
    }

    return unless @write;

    my @write_bin;
    for my $e (@write) {
        my $list = delete $e->{has_binary};

        $e->{has_binary} = $list && @$list ? 1 : 0;
        next unless $e->{has_binary};

        $e->{has_binary} = 1;
        for my $uuid (@$list) {
            push @write_bin => delete $self->{+BINARIES}->{$uuid};
        }
    }

    local $ENV{DBIC_DT_SEARCH_OK} = 1;
    $self->populate_bulk(Event => \@write);
    $self->populate(Binary => \@write_bin);
}

sub flush_reporting {
    my $self = shift;

    my @write;

    my %mixin_run = (
        user_id    => $self->user_id,
        run_id     => $self->{+RUN_ID},
        run_ord    => $self->run->run_ord(),
        project_id => $self->{+PROJECT_ID},
    );

    my $jobs = $self->{+JOBS};
    for my $tries (values %$jobs) {
        for my $job (values %$tries) {
            my $strip_event_id = 0;

            $strip_event_id = 1 unless record_subtest_events(
                job  => $job->{result},
                fail => $job->{result}->fail,
                mode => $self->{+MODE},

                is_harness_out => 0,
            );

            my %mixin = (
                %mixin_run,
                job_try      => $job->{job_try} // 0,
                job_key      => $job->{job_key},
                test_file_id => $job->{result}->test_file_id,
            );

            if (my $duration = $job->{duration}) {
                my $raw_fail  = $job->{result}->fail;
                my $raw_retry = $job->{result}->retry;
                my $abort = (defined($raw_fail) || defined($raw_retry)) ? 0 : 1;
                my $fail  = $raw_fail  // 0;
                my $pass  = $fail ? 0 : 1;
                my $retry = $raw_retry // 0;

                push @write => {
                    reporting_id => gen_uuid(),
                    duration     => $duration,
                    pass         => $pass,
                    fail         => $fail,
                    abort        => $abort,
                    retry        => $retry,
                    %mixin,
                };
            }

            my $reporting = delete $job->{reporting};

            for my $rep (@$reporting) {
                next unless defined $rep->{duration};
                next unless defined $rep->{subtest};

                delete $rep->{event_id} if $strip_event_id;

                %$rep = (
                    reporting_id => gen_uuid(),
                    %mixin,
                    %$rep,
                );

                push @write => $rep;
            }
        }
    }

    return unless @write;

    local $ENV{DBIC_DT_SEARCH_OK} = 1;

    $self->populate_bulk(Reporting => \@write);
}

sub user {
    my $self = shift;

    return $self->{+RUN}->user if $self->{+RUN};
    return $self->{+USER} if $self->{+USER};

    my $user_id = $self->{+USER_ID} // confess "No user or user_id specified";

    my $schema = $self->schema;
    my $user = $schema->resultset('User')->search({user_id => $user_id})->first;
    return $user if $user;
    confess "Invalid user_id: $user_id";
}

sub user_id {
    my $self = shift;

    return $self->{+RUN}->user_id if $self->{+RUN};
    return $self->{+USER}->user_id if $self->{+USER};
    return $self->{+USER_ID} if $self->{+USER_ID};
}

sub project {
    my $self = shift;

    return $self->{+RUN}->project if $self->{+RUN};
    return $self->{+PROJECT} if $self->{+PROJECT};

    my $project_id = $self->{+PROJECT_ID} // confess "No project or project_id specified";

    my $schema = $self->schema;
    my $project = $schema->resultset('Project')->search({project_id => $project_id})->first;
    return $project if $project;
    confess "Invalid project_id: $project_id";
}

sub project_id {
    my $self = shift;

    return $self->{+RUN}->project_id if $self->{+RUN};
    return $self->{+PROJECT}->project_id if $self->{+PROJECT};
    return $self->{+PROJECT_ID} if $self->{+PROJECT_ID};
}

sub start {
    my $self = shift;
    return if $self->{+RUNNING};

    $self->retry_on_disconnect("update status" => sub { $self->{+RUN}->update({status => 'running'}) });

    $self->{+RUNNING} = 1;
}

sub get_job {
    my $self = shift;
    my (%params) = @_;

    my $is_harness_out = 0;
    my $job_id = $params{job_id};

    if (!$job_id || $job_id eq '0') {
        $job_id = $self->{+JOB0_ID};
        $is_harness_out = 1;
    }

    $job_id = uuid_inflate($job_id);
    my $job_try = $params{job_try} // 0;

    my $job = $self->{+JOBS}->{$job_id}->{$job_try};
    return $job if $job;

    my $key = gen_uuid();

    my $test_file_id = undef;
    if (my $queue = $params{queue}) {
        my $file = $queue->{rel_file} // $queue->{file};
        $test_file_id = $self->get_test_file_id($file) if $file;
        $self->{+FILE_CACHE}->{$job_id} //= $test_file_id if $test_file_id;
    }

    $test_file_id //= $self->{+FILE_CACHE}->{$job_id};

    my $result;
    $self->retry_on_disconnect(
        "vivify job" => sub {
            $result = $self->schema->resultset('Job')->update_or_create({
                status         => 'pending',
                job_key        => $key,
                job_id         => $job_id,
                job_try        => $job_try,
                is_harness_out => $is_harness_out,
                job_ord        => $self->{+JOB_ORD}++,
                run_id         => $self->{+RUN}->run_id,
                fail_count     => 0,
                pass_count     => 0,
                test_file_id   => $test_file_id,

                $is_harness_out ? (name => "HARNESS INTERNAL LOG") : (),
            });
        }
    );

    # In case we are resuming.
    $self->retry_on_disconnect("delete old events" => sub { $result->events->delete_all() });

    # Prevent duplicate coverage when --retry is used
    if ($job_try) {
        if ($Test2::Harness::UI::Schema::LOADED =~ m/mysql/i) {
            my $schema = $self->schema;
            $schema->storage->connected; # Make sure we are connected
            my $dbh    = $schema->storage->dbh;

            my $query = <<"            EOT";
            DELETE coverage
              FROM coverage
              JOIN jobs USING(job_key)
             WHERE job_id = ?
            EOT

            my $sth = $dbh->prepare($query);
            $sth->execute($job_id) or die $sth->errstr;
        }
        else {
            $self->retry_on_disconnect(
                "delete old coverage" => sub {
                    $self->schema->resultset('Coverage')->search({'job_key.job_id' => $job_id}, {join => 'job_key'})->delete;
                }
            );
        }
    }

    if (my $old = $self->{+JOBS}->{$job_id}->{$job_try - 1}) {
        $self->{+UNCOVER}->{$old->{job_key}}++;
    }

    $job = {
        job_key => $key,
        job_id  => $job_id,
        job_try => $job_try,

        events    => [],
        orphans   => {},
        reporting => [],

        event_ord => 1,
        result    => $result,
    };

    return $self->{+JOBS}->{$job_id}->{$job_try} = $job;
}

sub process_event {
    my $self = shift;
    my ($event, $f, %params) = @_;

    $f //= $event->{facet_data};
    $f = $f ? clone($f) : {};

    $self->start unless $self->{+RUNNING};

    my $job = $params{job} // $self->get_job(%{$f->{harness} // {}}, queue => $f->{harness_job_queued});

    my $e = $self->_process_event($event, $f, %params, job => $job);
    clean($e);

    if (my $od = $e->{orphan}) {
        $job->{orphans}->{$e->{event_id}} = $e;
    }
    else {
        if (my $o = delete $job->{orphans}->{$e->{event_id}}) {
            $e->{orphan} = $o->{orphan};
            $e->{orphan_line} = $o->{orphan_line} if defined $o->{orphan_line};
            $e->{stamp} //= $o->{stamp};
        }
        push @{$job->{events}} => $e;
    }

    $self->flush(job => $job, is_diag => $e->{is_diag});

    return;
}

sub finish {
    my $self = shift;
    my (@errors) = @_;

    $self->flush_all();

    my $run = $self->run;

    my $status;
    my $dur_stat;
    my $aborted = 0;

    if (@errors) {
        my $error = join "\n" => @errors;
        $status = {status => 'broken', error => $error};
        $dur_stat = 'abort';
    }
    else {
        my $stat;
        if ($self->{+SIGNAL}) {
            $stat = 'canceled';
            $dur_stat = 'abort';
            $aborted = 1;
        }
        else {
            $stat = 'complete';
            $dur_stat = $self->{+FAILED} ? 'fail' : 'pass';
        }

        $status = {status => $stat, passed => $self->{+PASSED}, failed => $self->{+FAILED}, retried => $self->{+RETRIED}};
    }

    if ($self->{+FIRST_STAMP} && $self->{+LAST_STAMP}) {
        my $duration = $self->{+LAST_STAMP} - $self->{+FIRST_STAMP};
        $status->{duration} = format_duration($duration);

        $self->retry_on_disconnect("insert duration row" => sub {
            my $fail = $aborted ? 0 : $self->{+FAILED} ? 1 : 0;
            my $pass = ($fail || $aborted) ? 0 : 1;
            $self->schema->resultset('Reporting')->create({
                reporting_id => gen_uuid(),
                user_id      => $self->user_id,
                run_id       => $self->{+RUN_ID},
                project_id   => $self->{+PROJECT_ID},
                run_ord      => $self->run->run_ord(),
                duration     => $duration,
                retry        => 0,
                pass         => $pass,
                fail         => $fail,
                abort        => $aborted,
            });
        });
    }

    $self->retry_on_disconnect("update run status" => sub { $run->update($status) });

    return $status;
}

sub add_binary {
    my $self = shift;
    my $file = {@_};

    my $uuid = $file->{binary_id} //= gen_uuid();
    $file->{is_image} //= $file->{filename} =~ m/\.(a?png|gif|jpe?g|svg|bmp|ico)$/ ? 1 : 0;
    $file->{data} = decode_base64($file->{data});

    my $bins = $self->{+BINARIES} //= {};
    $bins->{$uuid} = $file;

    return $uuid;
}

sub _process_event {
    my $self = shift;
    my ($event, $f, %params) = @_;
    my $job = $params{job};

    my $harness = $f->{harness} // {};
    my $trace   = $f->{trace}   // {};

    my $e_id   = uuid_inflate($harness->{event_id} // $event->{event_id} // die "No event id!");
    my $nested = $f->{hubs}->[0]->{nested} || 0;

    my @has_binary;
    if ($f->{binary} && @{$f->{binary}}) {
        for my $file (@{$f->{binary}}) {
            my $data = delete $file->{data};
            $file->{data}    = 'removed';
            my $binary_id = $self->add_binary(event_id => $e_id, filename => $file->{filename}, description => $file->{details}, data => $data, is_image => $file->{is_image});
            push @has_binary => $binary_id;
        }
    }

    my $fail = causes_fail($f) ? 1 : 0;

    my $is_diag = $fail;
    $is_diag ||= 1 if $f->{errors} && @{$f->{errors}};
    $is_diag ||= 1 if $f->{assert} && !($f->{assert}->{pass} || $f->{amnesty});
    $is_diag ||= 1 if $f->{info} && first { $_->{debug} || $_->{important} } @{$f->{info}};
    $is_diag //= 0;

    my $is_harness = (first { substr($_, 0, 8) eq 'harness_' } keys %$f) ? 1 : 0;

    my $is_time = $f->{harness_job_end} ? ($f->{harness_job_end}->{times} ? 1 : 0) : 0;

    my $is_subtest = $f->{parent} ? 1 : 0;

    my $e = {
        event_id   => $e_id,
        nested     => $nested,
        is_subtest => $is_subtest,
        is_diag    => $is_diag,
        is_harness => $is_harness,
        is_time    => $is_time,
        trace_id   => $trace->{uuid},
        job_key    => $job->{job_key},
        event_ord  => $job->{event_ord}++,
        stamp      => $self->format_stamp($harness->{stamp} || $event->{stamp} || $params{stamp}),
        has_binary => \@has_binary,
    };

    my $orphan = $nested ? 1 : 0;
    if (my $p = $params{parent_id}) {
        $e->{parent_id} ||= $p;
        $orphan = 0;
    }

    if ($orphan) {
        clean($f);

        if ($f->{parent} && $f->{parent}->{children}) {
            $f->{parent}->{children} = "Removed";
        }

        $e->{orphan}      = encode_json($f);
        $e->{orphan_line} = $params{line} if $params{line};
    }
    else {
        if (my $fields = $f->{run_fields}) {
            $self->add_run_fields($fields);
        }

        if (my $job_coverage = $f->{job_coverage}) {
            $self->add_job_coverage($job, $job_coverage);
            $f->{job_coverage} = "Removed, used to populate the job_coverage table";
        }

        if (my $run_coverage = $f->{run_coverage}) {
            $f->{run_coverage} = "Removed, used to populate the run_coverage table";
            $self->add_run_coverage($run_coverage);
        }

        if ($f->{parent} && $f->{parent}->{children}) {
            $self->process_event({}, $_, job => $job, parent_id => $e_id, line => $params{line}) for @{$f->{parent}->{children}};
            $f->{parent}->{children} = "Removed, used to populate events table";

            $self->add_subtest_duration($job, $e, $f) unless $nested;
        }

        unless ($nested) {
            my $res = $job->{result};
            if ($fail) {
                $res->fail_count($res->fail_count + 1);
                $res->fail(1);
            }
            $res->pass_count($res->pass_count + 1) if $f->{assert} && !$fail;

            $self->update_other($job, $f) if $e->{is_harness};
        }

        clean($f);
        $e->{facets}      = encode_json($f);
        $e->{facets_line} = $params{line} if $params{line};
    }

    return $e;
}

sub add_subtest_duration {
    my $self = shift;
    my ($job, $e, $f) = @_;

    return if $f->{hubs}->[0]->{nested};

    my $parent = $f->{parent}       // return;
    my $assert = $f->{assert}       // return;
    my $st     = $assert->{details} // return;
    return if is_invalid_subtest_name($st);

    my $start    = $parent->{start_stamp} // return;
    my $stop     = $parent->{stop_stamp}  // return;
    my $duration = $stop - $start;

    push @{$job->{reporting}} => {
        duration => $duration,
        subtest  => $st,
        event_id => $e->{event_id},
        abort => 0,
        retry => 0,
        $assert->{pass} ? (pass => 1, fail => 0) : (fail => 1, pass => 0),
    };
}

sub add_job_coverage {
    my $self = shift;
    my ($job, $job_coverage) = @_;

    my $job_id  = $job->{job_id};
    my $job_try = $job->{job_try} // 0;

    # Do not add coverage if a retry has already started. Events could be out of order.
    return if $self->{+JOBS}->{$job_id}->{$job_try + 1};
    return if $self->{+UNCOVER} && $self->{+UNCOVER}->{$job->{job_key}};

    my $test = $job_coverage->{test} // $job->{result}->file;

    my $test_id    = uuid_deflate($self->get_test_file_id($test)) or confess("Could not get test id (for '$test')");
    my $manager_id = $self->get_coverage_manager_id($job_coverage->{manager});
    my $job_key    = uuid_deflate($job->{job_key});

    for my $source (keys %{$job_coverage->{files}}) {
        my $subs      = $job_coverage->{files}->{$source};
        my $source_id = $self->get_source_file_id($source);

        for my $sub (keys %$subs) {
            $self->_add_coverage(
                job_key             => $job_key,
                test_file_id        => $test_id,
                source_file_id      => $source_id,
                source_sub_id       => $self->get_source_sub_id($sub),
                coverage_manager_id => $manager_id,
                meta                => $subs->{$sub},
            );
        }
    }

    $self->flush_coverage;
}

sub add_run_coverage {
    my $self = shift;
    my ($run_coverage) = @_;

    my $files = $run_coverage->{files};
    my $meta  = $run_coverage->{testmeta};

    my (%test_ids, %manager_ids);

    for my $source (keys %$files) {
        my $subs      = $files->{$source};
        my $source_id = $self->get_source_file_id($source);

        for my $sub (keys %$subs) {
            my $tests  = $subs->{$sub};
            my $sub_id = $self->get_source_sub_id($sub);

            for my $test (keys %$tests) {
                my $test_id = $test_ids{$test} //= uuid_deflate($self->get_test_file_id($test)) or confess("Could not get test id (for '$test')");

                my $manager_id;
                if (defined(my $manager = $meta->{$test}->{manager})) {
                    $manager_id = $manager_ids{$manager} //= $self->get_coverage_manager_id($manager);
                }

                $self->_add_coverage(
                    test_file_id        => $test_id,
                    source_file_id      => $source_id,
                    source_sub_id       => $sub_id,
                    coverage_manager_id => $manager_id,
                    meta                => $tests->{$test},
                );
            }
        }
    }

    $self->flush_coverage;
}

# This runs once per coverage row, and there can be hundreds of thousands in
# one job, so the ids arrive resolved and deflated: the row goes to the
# database as it is, through populate_bulk().
sub _add_coverage {
    my $self = shift;
    my %params = @_;

    my $manager_id = $params{coverage_manager_id};
    my $meta = $manager_id ? encode_json($params{meta}) : undef;

    my $coverage = $self->{+COVERAGE} //= [];

    push @$coverage => {
        coverage_id         => gen_deflated_uuid(),
        run_id              => $self->{+RUN_ID_DEFLATED} //= uuid_deflate($self->{+RUN_ID}),
        test_file_id        => $params{test_file_id},
        source_file_id      => $params{source_file_id},
        source_sub_id       => $params{source_sub_id},
        coverage_manager_id => $manager_id,
        metadata            => $meta,
        job_key             => $params{job_key},
    };
}

sub flush_coverage {
    my $self = shift;

    my $coverage = $self->{+COVERAGE} or return;
    return unless @$coverage;

    $self->retry_on_disconnect("update has_coverage" => sub { $self->{+RUN}->update({has_coverage => 1}) })
        unless $self->{+RUN}->has_coverage;

    $self->populate_bulk(Coverage => $coverage);

    @$coverage = ();

    return;
}

sub _get__id {
    my $self = shift;
    my $id = $self->_get___id(@_);
    return $id unless defined $id;
    return uuid_inflate($id);
}

# The cache holds the deflated id, what the database stores, so a caller that
# writes rows directly can use it as it is.
sub _get___id {
    my $self = shift;
    my ($type, $id_field, $field, $id) = @_;

    return undef unless $id;

    return $self->{+ID_CACHE}->{$type}->{$id_field}->{$field}->{$id}
        if $self->{+ID_CACHE}->{$type}->{$id_field}->{$field}->{$id};

    my $spec = {$field => $id, $id_field => gen_uuid()};
    my $result = $self->schema->resultset($type)->find_or_create($spec);

    return $self->{+ID_CACHE}->{$type}->{$id_field}->{$field}->{$id} = uuid_deflate($result->$id_field);
}

sub get_test_file_id {
    my $self = shift;
    my ($file) = @_;

    return undef unless $file;

    return $self->_get__id('TestFile' => 'test_file_id', filename => $file);
}

# These return the deflated id, see _get___id().
sub get_source_file_id {
    my $self = shift;
    my ($file) = @_;

    return $self->_get___id(SourceFile => 'source_file_id', filename => $file) // die "Could not get source id";
}

sub get_source_sub_id {
    my $self = shift;
    my ($sub) = @_;

    return $self->_get___id(SourceSub => 'source_sub_id', subname => $sub) // die "Could not get sub id";
}

sub get_coverage_manager_id {
    my $self = shift;
    my ($package) = @_;

    return $self->_get___id(CoverageManager => 'coverage_manager_id', package => $package);
}

sub add_run_fields {
    my $self = shift;
    my ($fields) = @_;

    my $run    = $self->{+RUN};
    my $run_id = $run->run_id;

    return $self->_add_fields(
        fields    => $fields,
        type      => 'RunField',
        key_field => 'run_field_id',
        attrs     => {run_id => $run_id},
    );
}

sub add_job_fields {
    my $self = shift;
    my ($job, $fields) = @_;

    my $job_key = $job->job_key;

    return $self->_add_fields(
        fields    => $fields,
        type      => 'JobField',
        key_field => 'job_field_id',
        attrs     => {job_key => $job_key},
    );
}

sub _add_fields {
    my $self = shift;
    my %params = @_;

    my $fields    = $params{fields};
    my $type      = $params{type};
    my $key_field = $params{key_field};
    my $attrs     = $params{attrs} // {};

    my @add;
    for my $field (@$fields) {
        my $id  = gen_uuid;
        my $new = {%$attrs, $key_field => $id};

        $new->{name}    = $field->{name}    || 'unknown';
        $new->{details} = $field->{details} || $new->{name};
        $new->{raw}     = $field->{raw}               if $field->{raw};
        $new->{link}    = $field->{link}              if $field->{link};
        $new->{data}    = encode_json($field->{data}) if $field->{data};


        push @add => $new;

        # Replace the item in the $fields array with the id
        $field = $id;
    }

    $self->populate($type => \@add);
}

sub clean_output {
    my $text = shift;

    return undef unless defined $text;
    $text =~ s/^T2-HARNESS-ESYNC: \d+\n//gm;
    chomp($text);

    return undef unless length($text);
    return $text;
}

sub clean {
    my ($s) = @_;
    return 0 unless defined $s;
    my $r = ref($_[0]) or return 1;
    if    ($r eq 'HASH')  { return clean_hash(@_) }
    elsif ($r eq 'ARRAY') { return clean_array(@_) }
    return 1;
}

sub clean_hash {
    my ($s) = @_;
    my $vals = 0;

    for my $key (keys %$s) {
        my $v = clean($s->{$key});
        if   ($v) { $vals++ }
        else      { delete $s->{$key} }
    }

    $_[0] = undef unless $vals;

    return $vals;
}

sub clean_array {
    my ($s) = @_;

    @$s = grep { clean($_) } @$s;

    return @$s if @$s;

    $_[0] = undef;
    return 0;
}

sub update_other {
    my $self = shift;
    my ($job, $f) = @_;

    my $run = $self->{+RUN};

    if (my $run_data = $f->{harness_run}) {
        my $settings = $run_data->{settings} //= $f->{harness_settings};

        if (my $j = $settings->{runner}->{job_count}) {
            $run->concurrency($j);
        }

        clean($run_data);
        $run->parameters($run_data);

        if (my $fields = $run_data->{harness_run_fields} // $run_data->{fields}) {
            $self->add_run_fields($fields);
        }
    }

    my $job_result = $job->{result};
    my %cols = $job_result->get_columns;

    # Handle job events
    if (my $job_data = $f->{harness_job}) {
        #$cols{test_file_id} ||= $self->get_test_file_id($job_data->{file});
        $cols{name} ||= $job_data->{job_name};
        clean($job_data);
        $cols{parameters} = encode_json($job_data);
        $f->{harness_job}  = "Removed, see job with job_key $cols{job_key}";
    }
    if (my $job_exit = $f->{harness_job_exit}) {
        #$cols{test_file_id} ||= $self->get_test_file_id($job_exit->{file});
        $cols{exit_code} = $job_exit->{exit};

        if ($job_exit->{retry} && $job_exit->{retry} eq 'will-retry') {
            $cols{retry} = 1;
            $self->{+RETRIED}++;
            $self->{+FAILED}--;
        }
        else {
            $cols{retry} = 0;
        }

        $cols{stderr} = clean_output(delete $job_exit->{stderr});
        $cols{stdout} = clean_output(delete $job_exit->{stdout});
    }
    if (my $job_start = $f->{harness_job_start}) {
        $cols{test_file_id} ||= $self->get_test_file_id($job_start->{rel_file}) if $job_start->{rel_file};
        $cols{test_file_id} ||= $self->get_test_file_id($job_start->{file});
        $cols{start} = $self->format_stamp($job_start->{stamp});
    }
    if (my $job_launch = $f->{harness_job_launch}) {
        $cols{status} = 'running';

        $cols{test_file_id} ||= $self->get_test_file_id($job_launch->{file});
        $cols{launch} = $self->format_stamp($job_launch->{stamp});
    }
    if (my $job_end = $f->{harness_job_end}) {
        #$cols{test_file_id} ||= $self->get_test_file_id($job_end->{file});
        $cols{fail} ||= $job_end->{fail} ? 1 : 0;
        $cols{ended} = $self->format_stamp($job_end->{stamp});

        $cols{fail} ? $self->{+FAILED}++ : $self->{+PASSED}++;

        # All done
        $job->{done} = 1;
        $cols{status} = 'complete';

        if ($job_end->{rel_file} && $job_end->{times} && $job_end->{times}->{totals} && $job_end->{times}->{totals}->{total}) {
            my $tfile_id = $cols{test_file_id} ||= $self->get_test_file_id($job_end->{rel_file}) if $job_end->{rel_file};

            if (my $duration = $job_end->{times}->{totals}->{total}) {
                $job->{duration} = $duration;
                $cols{duration} = $duration;
            }
        }
    }
    if (my $job_fields = $f->{harness_job_fields}) {
        $self->add_job_fields($job_result, $job_fields);
    }

    $job_result->set_columns(\%cols);

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Harness::UI::RunProcessor

=head1 DESCRIPTION

=head1 SYNOPSIS

TODO

=head1 SOURCE

The source code repository for Test2-Harness-UI can be found at
F<http://github.com/Test-More/Test2-Harness-UI/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2019 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
