package TheSchwartz::Moosified::Job;

use Moose;
use Storable ();
use TheSchwartz::Moosified::Utils qw/sql_for_unixtime run_in_txn/;
use TheSchwartz::Moosified::JobHandle;

has 'jobid'         => ( is => 'rw', isa => 'Int' );
has 'funcid'        => ( is => 'rw', isa => 'Int' );
has 'arg'           => ( is => 'rw', isa => 'Any' );
has 'uniqkey'       => ( is => 'rw', isa => 'Maybe[Str]' );
has 'insert_time'   => ( is => 'rw', isa => 'Maybe[Int]' );
has 'run_after'     => ( is => 'rw', isa => 'Int', default => sub { time } );
has 'grabbed_until' => ( is => 'rw', isa => 'Int', default => 0 );
has 'priority'      => ( is => 'rw', isa => 'Maybe[Int]' );
has 'coalesce'      => ( is => 'rw', isa => 'Maybe[Str]' );

has 'funcname' => (
    is => 'rw',
    isa => 'Str',
    lazy_build => 1,
);

has 'handle' => (
    is => 'rw',
    isa => 'TheSchwartz::Moosified::JobHandle',
    handles => [qw(
        exit_status
        failure_log
        failures
        client
        dbh
    )],
);

has 'did_something' => ( is => 'rw', isa => 'Bool', default => 0 );

sub BUILD {
    my ($self, $params) = @_;
        
    if (my $arg = $params->{arg}) {
        if (ref($arg) eq 'SCALAR') {
            $params->{arg} = Storable::thaw($$arg);
        } elsif (!ref($arg)) {
            # if a regular scalar, test to see if it's a storable or not.
            $params->{arg} = _cond_thaw($arg);
        }
        $self->arg( $params->{arg} );
    }
}

sub _build_funcname {
    my $self = shift;
    my $funcname = $self->client->funcid_to_name($self->dbh, $self->funcid)
        or die "Failed to lookup funcname of job $self";
    return $funcname;
}

sub debug {
    my ($self, $msg) = @_;
    
    $self->client->debug($msg, $self);
}

sub as_hashref {
    my $self = shift;

    my %data;
    for my $col (qw( jobid funcid arg uniqkey insert_time run_after grabbed_until priority coalesce )) {
        $data{$col} = $self->$col if $self->can($col);
    }

    return \%data;
}

sub add_failure {
    my $job = shift;
    my $msg = shift;
    $msg = '' unless defined $msg;
    
    my $table_error = $job->handle->client->prefix . 'error';
    if (my $len = $job->handle->client->error_length) {
        $msg = substr($msg,0,$len);
    }
    my $sql = qq~INSERT INTO $table_error (error_time, jobid, message, funcid) VALUES (?, ?, ?, ?)~;
    my $dbh = $job->dbh;
    my $sth = $dbh->prepare($sql);
    $sth->execute(time(), $job->jobid, $msg, $job->funcid);

    # and let's lazily clean some errors while we're here.
    my $maxage = $TheSchwartz::Moosified::T_ERRORS_MAX_AGE || (86400*7);
    my $dtime  = time() - $maxage;
    $dbh->do(qq~DELETE FROM $table_error WHERE error_time < $dtime~);

    return 1;
}

sub completed {
    my $job = shift;
    
    $job->debug("job completed");
    if ($job->did_something) {
        $job->debug("can't call 'completed' on already finished job");
        return 0;
    }
    $job->did_something(1);
    return run_in_txn {
        $job->set_exit_status(0);
        $job->remove();
    } $job->dbh;
}

sub remove {
    my $job = shift;
    
    my $jobid = $job->jobid;
    my $table_job = $job->handle->client->prefix . 'job';
    $job->dbh->do(qq~DELETE FROM $table_job WHERE jobid = $jobid~);
}

sub set_exit_status {
    my $job = shift;
    my($exit) = @_;
    my $class = $job->funcname;
    my $secs = $class->keep_exit_status_for or return;

    my $t = time();
    my $jobid = $job->jobid;
    my $funcid = $job->funcid;
    my @status = ($exit, $t, $t + $secs);
    my $dbh = $job->dbh;
    my $table_exitstatus = $job->handle->client->prefix . 'exitstatus';
    my $needs_update = 0;
    {
        my $sth = $dbh->prepare(qq{
            INSERT INTO $table_exitstatus
            (funcid, status, completion_time, delete_after, jobid)
            SELECT ?, ?, ?, ?, ?
            WHERE NOT EXISTS (
                SELECT 1 FROM $table_exitstatus WHERE jobid = ?
            )
        });
        $sth->execute($funcid, @status, $jobid, $jobid);
        $needs_update = ($sth->rows == 0);
    }
    if ($needs_update) {
        # only update if this status is newest
        my $sth = $dbh->prepare(qq{
            UPDATE $table_exitstatus
            SET status=?, completion_time=?, delete_after=?
            WHERE jobid = ? AND completion_time < ?
        });
        $sth->execute(@status, $jobid, $t);
    }

    # and let's lazily clean some exitstatus while we're here.  but
    # rather than doing this query all the time, we do it 1/nth of the
    # time, and deleting up to n*10 queries while we're at it.
    # default n is 10% of the time, doing 100 deletes.
    my $clean_thres = $TheSchwartz::Moosified::T_EXITSTATUS_CLEAN_THRES || 0.10;
    if (rand() < $clean_thres) {
        my $unixtime = sql_for_unixtime($dbh);
        $dbh->do(qq~DELETE FROM $table_exitstatus WHERE delete_after < $unixtime~);
    }

    return 1;
}

sub permanent_failure {
    my ($job, $msg, $ex_status) = @_;
    if ($job->did_something) {
        $job->debug("can't call 'permanent_failure' on already finished job");
        return 0;
    }
    $job->_failed($msg, $ex_status, 0);
}

sub failed {
    my ($job, $msg, $ex_status) = @_;
    if ($job->did_something) {
        $job->debug("can't call 'failed' on already finished job");
        return 0;
    }

    ## If this job class specifies that jobs should be retried,
    ## update the run_after if necessary, but keep the job around.

    my $class       = $job->funcname;
    my $failures    = $job->failures + 1;    # include this one, since we haven't ->add_failure yet
    my $max_retries = $class->max_retries($job);

    $job->debug("job failed.  considering retry.  is max_retries of $max_retries >= failures of $failures?");
    $job->_failed($msg, $ex_status, $max_retries >= $failures, $failures);
}

sub _failed {
    my ($job, $msg, $exit_status, $_retry, $failures) = @_;
    $job->did_something(1);
    $job->debug("job failed: " . ($msg || "<no message>"));

    run_in_txn {
        ## Mark the failure in the error table.
        $job->add_failure($msg);

        if ($_retry) {
            my $table_job = $job->handle->client->prefix . 'job';
            my $class = $job->funcname;
            my @bind;
            my $sql = qq{UPDATE $table_job SET };
            if (my $delay = $class->retry_delay($failures)) {
                my $run_after = time() + $delay;
                $job->run_after($run_after);
                push @bind, $run_after;
                $sql .= qq{run_after = ?, };
            }
            $sql .= q{grabbed_until = 0 WHERE jobid = ?};
            push @bind, $job->jobid;
            $job->dbh->do($sql, {}, @bind);
        } else {
            $job->set_exit_status($exit_status || 1);
            $job->remove();
        }
    } $job->dbh;
}

sub replace_with {
    my $job = shift;
    my(@jobs) = @_;

    if ($job->did_something) {
        $job->debug("can't call 'replace_with' on already finished job");
        return 0;
    }
    # Note: we don't set 'did_something' here because completed does it down below.

    $job->debug("replacing job with " . (scalar @jobs) . " other jobs");

    ## The new jobs @jobs should be inserted into the same database as $job,
    ## which they're replacing.
    for my $new_job (@jobs) {
        next unless ref $new_job->arg;
        $new_job->arg( Storable::nfreeze( $new_job->arg ) );
    }

    run_in_txn {
        ## Mark the original job as completed successfully.
        $job->completed;

        ## Insert the new jobs.
        $job->client->_try_insert($_, $job->dbh) for @jobs;
    } $job->dbh;
}

sub set_as_current {
    my $job = shift;
    $job->client->current_job($job);
}

sub _cond_thaw {
    my $data = shift;

    my $magic = eval { Storable::read_magic($data); };
    if ($magic && $magic->{major} && $magic->{major} >= 2 && $magic->{major} <= 5) {
        my $thawed = eval { Storable::thaw($data) };
        if ($@) {
            # false alarm... looked like a Storable, but wasn't.
            return $data;
        }
        return $thawed;
    } else {
        return $data;
    }
}

no Moose;
1;
__END__
