package MMM::MirrorTask;

=head1 NAME

MMM::MirrorTask Class to store mirror task function and data

=cut

use strict;
use warnings;
use MMM::Sync;
use MMM::Utils;
use MMM::Config;
use MMM::Mirror;
use Fcntl qw(:flock);
use Digest::MD5;

=head1 METHODS

=head2 new

=cut

sub new {
    my ($class, $mmm, $name, %options) = @_;
    bless(
        {
            mmm => $mmm,
            name => $name,
            options => { %options },
            lockcount => 0,
        },
        $class
    );
}

sub DESTROY {
    my ($self) = @_;
    $self->{lockcount} = 1; # Force unlock, can't happen
    $self->unlock();
}

=head2 name

Return the name of the current task

=cut

sub name {
    $_[0]->{name}
}

=head2 is_disable

Return true if the current task is disable

=cut

sub is_disable { yes_no($_[0]->val('disable')) }

=head2 val( $var, $default)

Return the configuration value for $var. Return $default if parameter
is not set in the config

=cut

sub val {
    my ( $self, $var, $default ) = @_;
    $self->{mmm}->{config}->val( $self->name, $var, $default );
}

=head2 frequency

Return the frequency value from config

=cut

sub frequency {
    my ($self) = @_;
    duration2m($self->val( 'period', PERIOD ));
}

sub _set_status_time {
    my ($config, $section, $var, $val) = @_;
    $config->newval($section, $var, $val);
    $config->SetParameterComment(
        $section, $var, scalar(gmtime($val))
    );
}

=head2 state_info

Return a hashref about job status

=cut

sub state_info {
    my ($self, $status) = @_;
    $status ||= $self->_get_status();
    my %info = ();
    foreach my $section (qw(job success failure)) {
        foreach my $var ($status->Parameters($section)) {
            $info{$section}{$var} = $status->val($section, $var);
        }
    }
    if  (yes_no($self->val('compute_size', 0))) {
        $info{job}{size} = $status->val('job', 'size');
    } else {
        delete($info{job}{size});
    }

    $info{job}{error_log} = [ grep { $_ } ($status->val('job', 'error_log')) ];
    $info{job}{next_run_time} = $self->next_run_time($status);
    $info{job}{is_running} = $self->is_running;
    return %info;
}

sub _compute_config_sum {
    my ($self) = @_;
    my $md5 = Digest::MD5->new();
    foreach (qw(url source path)) {
        $md5->add("$_=");
        $md5->add(join("\n", $self->val('job', $_, '')));
    }
    return $md5->hexdigest
}

sub _set_compute_config_sum {
    my ($self, $status) = @_;
    $status ||= $self->_get_status();
    my $newsum = $self->_compute_config_sum();
    if ($status->val('job', 'config_sum', '') ne $newsum) {
        $status->newval('job', 'config_sum', $newsum);
        return 1;
    } else {
        return 0;
    }
}

=head2 next_run_time

Return the time (in second) when the next run should be performed

=cut

sub next_run_time {
    my ($self, $status) = @_;
    my @alltime = ( scalar( time() ) );
    $status ||= $self->_get_status();
    my $last_start = 0;
    if ($self->_compute_config_sum() ne $status->val('job', 'config_sum', '')) {
        $self->_log('INFO',
	    'Config for has changed, need to be run immediately')
        if($status->val('job', 'start', 0));
    } else {
        $last_start = $status->val( 'job' , 'start', 0 );
    }

    if ( $last_start ) {
        push( @alltime, $last_start + ( $self->frequency * 60 ) );
    }

    if (   $self->val('waitafter', WAITAFTER_MINIMA)
        && $status->val( 'job' , 'end' ) )
    {
        push( @alltime,
            $status->val( 'job', 'end' ) +
              $self->val('waitafter', WAITAFTER_MINIMA) * 60 );
    }

    if (   $self->val('waitaftersuccess')
        && $status->val( 'success', 'end' ) )
    {
        push( @alltime,
            $status->val( 'job', 'success' ) +
              $self->val('waitaftersuccess') * 60 );
    }

    my ($t) = sort { $b <=> $a } @alltime;
    # $self->_log('DEBUG', 'Next run time for %s is %d (in %d), frequency is %d',
    #    $self->{name}, $t, $t - scalar(time()),
    #    $self->frequency,
    #);

    $t;
}

=head2 source

Return the source associate to the list, if any

=cut

sub source {
    $_[0]->val('source') || '';
}

sub _log {
    my ($self, $level, $message, @args) = @_;
    $self->{mmm}->log(
        $level,
        sprintf('[%s] %s', $self->name, $message),
        @args
    );
}

sub _lockpath {
    my ($self) = @_;
    my $lockfile = $self->name;
    $lockfile =~ s:/:_:g;
    join('/', ($self->{mmm}->statedir, "/$lockfile.lck"));
}

sub _statusfile {
    my ($self) = @_;
    my $lockfile = $self->name;
    $lockfile =~ s:/:_:g;
    join('/', ($self->{mmm}->statedir, $lockfile));
}

=head2 getlock($share)

Try to lock the lockfile for this task, in shared mode if
$share is set.

=cut

sub getlock {
    my ($self, $share) = @_;
    if ($self->{lockcount}) {
        $self->{lockcount}++;
        $self->_log(
            'DEBUG',
            'Lock is already done, counter is now %d', $self->{lockcount}
        );
        return $self->{lockcount};
    }
    $self->_log( 'DEBUG', 'Trying to acquire lock' );
    $self->{lockfile} = $self->_lockpath;
    if ( open( $self->{lockfh}, $share ? '<' : '>', $self->_lockpath) ) {
        if ( !flock(
                $self->{lockfh}, LOCK_NB | ( $share ? LOCK_SH : LOCK_EX ) ) ) {
            if ( ( $! + 0 ) != 11 ) { # E_AGAIN, does this is really need
                $self->_log(
                    'FATAL',
                    "Cannot lock file %s",
                    $self->_lockpath
                );
                unlink( $self->_lockpath );
                close( $self->{lockfh} );
                return;
            }
            $self->_log( 'DEBUG', 'is already lock' );
            return;
        }
        my $fh = $self->{lockfh};
        print $fh "$$\n" unless($share);
    }
    else {
        $self->_log( 'FATAL',
            'Cannot open lock file %s :%s', $self->{lockfile}, $!);
        return;
    }
    ++$self->{lockcount};
}

=head2 unlock

Release the lock for the task

=cut

sub unlock {
    my ($self) = @_;
    $self->{lockfh} or return;
    --$self->{lockcount} and return;
    unlink( $self->{lockfile} );
    close( $self->{lockfh} );
}

=head2 is_running

Return true is the task is running (lock check)

=cut

sub is_running {
    my ($self) = @_;
    my @stat = stat($self->_lockpath);
    if ($self->{mmm}->_task_is_registred($self->name)) {
        return $stat[9] || scalar(time);
    }

    if (!defined($stat[9])) { return }
    else {
        my $res = $self->getlock(1);
        if ($res) {
            $self->unlock;
	        if ($res > 1) { return $stat[9]; }
            else { return; }
        } else { return $stat[9]; }
    }
}

sub _get_status {
    my ($self) = @_;
    Config::IniFiles->new(
        -f $self->_statusfile ? ( -file => $self->_statusfile ) : ()
    ) || Config::IniFiles->new();
}

sub _write_status {
    my ($self, $status) = @_;
    $self->_log( 'DEBUG', 'Write status file: %s', $self->_statusfile );
    $status->WriteConfig( $self->_statusfile );
}

=head2 failure_count

Return three values:
- the count of failure since last success
- the previous failure count
- and if this count has change between the two previous run
(eg if failure count is different of previous failure count)

=cut

sub failure_count {
    my ($self, $status) = @_;
    my $before = defined($self->{successive_failure_before})
        ? $self->{successive_failure_before}
        : ($status ||= $self->_get_status())->val('job', 'old_failure_count', 0);
    my $after = defined($self->{successive_failure_after})
        ? $self->{successive_failure_after}
        : ($status ||= $self->_get_status())->val('job', 'successive_failure_count', 0);
    return(
        $before, $after, defined($after) ? $after != $before : undef
    );
}

=head2 sync

Perform the synchronization

=cut

sub sync {
    my ($self) = @_;
    $self->_log('INFO', 'Start to process' );
    $self->_log('DEBUG', 'goes into %s%s',
        $self->dest,
        $self->{options}{dryrun} ? ' (dryrun mode)' : '',
    );

    my $oldname = $0;
    $0 = 'mmm [' . $self->name . ']';
    
    $self->getlock() or return;

    my $status = $self->_get_status();
    $self->_set_compute_config_sum($status);
    my ($ouid, $ogid) = MMM::Utils::setid( $self->val('user'), $self->val('group') );

    $self->{successive_failure_before} =
        $status->val('job', 'successive_failure_count', 0);
    $status->newval('job', 'old_failure_count', $self->{successive_failure_before});
    $status->delval( 'job', 'command');
    $status->newval('job', 'processed_count',
        $status->val('job', 'processed_count', 0) + 1
    );

    if (!defined($status->val('job', 'first_sync'))) {
        _set_status_time($status, 'job', 'first_sync', scalar( time() ));
    }

    my $res = 0;

    if (! -d $self->dest) {
        push(@{ $self->{output} }, sprintf('Directory %s does not exists (%s)',
            $self->dest,
            $self->name,
        ));
        foreach (qw(start end)) {
            _set_status_time($status, 'job', $_, scalar( time() ));
        }
        return $res;
    }

    if ($self->val('pre_exec')) {
        my @cmd = ($self->val('pre_exec'), $self->name, $self->dest);
        $self->_log('INFO', 'Executing PRE: %s',
            join(' ', map { qq{"$_"} } (@cmd)));
        if (system(@cmd) != 0) {
            if ($? == -1) {
                $self->_log('ERROR', 'failed to execute pre_exec: %s', $!);
            } else {
                $self->_log('ERROR',
                    'Pre_exec exited with value %d, abborting sync', $? >> 8);
            }
            return $res;
        }
    }

    if (my $url = $self->val('url')) {
        $res = $self->_sync_url(
            $status, $url,
            password => $self->val('password') || undef,
            use_ssh => yes_no($self->val('rsync_use_ssh')),
        );
    } else {
        $self->_log('ERROR', 'No source or url' );
        return $res
    }

    $status->newval('job', 'success', $res ? 1 : 0);
    if ($res) {
        $self->_log('NOTICE', 'Sync done%s from %s',
            $self->{options}{dryrun} ? ' (dryrun mode)' : '',
            $status->val('success', 'sync_from'),
        );
        $status->newval('job', 'successive_failure_count', 0);
    } else {
        $self->_log('WARNING', 'Unable to sync');
        $status->newval('job', 'successive_failure_count',
            $status->val('job', 'successive_failure_count', 0) + 1
        );
        foreach (@{ $self->{output} ? $self->{output} : [ "No output from process" ]}) {
            $self->_log('ERROR', $_);
        }
    }
    $self->{successive_failure_after} =
        $status->val('job', 'successive_failure_count', 0);

    if ($self->val('post_exec')) {
        $ENV{MMM_RESULT} = $res;
        if ($res) {
            $ENV{MMM_FROM} = $status->val('success', 'sync_from');
            $ENV{MMM_MIRROR} = $status->val('job', 'try_from');
        }
        my @cmd = ($self->val('post_exec'), $self->name, $self->dest);
        $self->_log('INFO', 'Executing POST: %s',
            join(' ', map { qq{"$_"} } (@cmd)));
        if (system(@cmd) != 0) {
            if ($? == -1) {
                $self->_log('WARNING', 'failed to execute post_exec: %s', $!);
            } else {
                $self->_log('WARNING',
                    'Post_exec exited with value %d, abborting sync', $? >> 8);
            }
        }
    }

    if (yes_no($self->val('compute_size', 0)) && 
        scalar(time) > $status->val('job', 'size_time', 0) +
        duration2m($self->val('size_delay', SIZE_DELAY) * 60)) {
        $self->du_dest($status);
    }

    MMM::Utils::setid($ouid, $ogid);

    $self->_write_status($status) unless($self->{options}{dryrun});

    if ($self->{mmm}->can('send_mail')) {
        if ($status->val('job', 'old_failure_count', 0) !=
            $status->val('job', 'successive_failure_count', 0) &&
            grep { $status->val('job', 'successive_failure_count', 0) == $_ }
            (0, $self->val('errors_mail', 3))
        ) {

            $self->{mmm}->body_queue($self, $self, $self->state_info($status));
            $self->{mmm}->send_mail();
        }
    }

    $self->unlock();
    $0 = $oldname;
    $res
}

sub _sync_url {
    my ($self, $status, $based_url, %options) = @_;

    my $url = $based_url;
    $url =~ m:/$: or $url .= '/';
    $url .= '/' . $self->val('subdir') if ($self->val('subdir'));
    $url =~ m:/$: or $url .= '/';

    $self->_log('DEBUG', 'Try from mirror %s', $url);
    _set_status_time($status, 'job', 'start', scalar( time() ));

    foreach my $val (
        'bwlimit',              # bandwidth limit in k
        'timeout',              # timeout
        'rsync_opts',           # specifics rsync options
        'rsync_defaults',       # defaults rsync options
        'exclude',              # excluded files/dir
        'tempdir',
        'partialdir',
        ) {
        if (my $v = $self->val($val)) {
            $options{$val} = $v;
        }
    }
    foreach my $val (
        'delete-after',         # deleting after ?
        'delete',               # delete removed files ?
        'delete-excluded',      # deleting excluded files ?
        ) {
        $options{$val} = yes_no($self->val($val));
    }
    my $sync = MMM::Sync->new(
        $url,
        $self->dest,
        %options,
    );

    if (my $m = MMM::Mirror->new(url => $url)) {
        $status->newval('job', 'try_from', $m->host);
    }

    my $sync_res;
    my $max_try = $self->val( 'max_try', MAX_TRY );
    $self->_log('DEBUG', 'running %s', join(' ', $sync->buildcmd()));
    foreach my $trycount (1 .. $max_try) {
        $sync->reset_output;
        if ( $self->{options}{dryrun} ) {
            $sync_res = 0;
            sleep(10);
        } else {
            $sync_res = $sync->sync();
        }
        $self->_log($sync_res ? 'WARNING' : 'DEBUG', 
            'Try %d/%d, res: %d from mirror %s',
            $trycount, $max_try, $sync_res,
            $sync->{source}, # TODO: kill intrusive var access
        );
        $self->{output} = $sync->get_output;
        if ($sync_res != 1) {
            last
        }
    }

    $status->newval( 'job', 'command', join(' ', $sync->buildcmd) );

    _set_status_time($status, 'job', 'end', scalar( time() ) );

    my $concerned_section = $sync_res ? 'failure' : 'success';

    foreach (qw(start end)) {
        _set_status_time($status, $concerned_section, $_,
            $status->val('job', $_) 
        );
    }
    $status->newval($concerned_section, 'url', $url);
    $status->newval($concerned_section, 'try_from', $status->val('job', 'try_from'));

    if ($sync_res == 0) {
        $status->delval( 'job', 'error_log' );
        $status->newval('success', 'sync_from', $status->val('job', 'try_from'));
    } else {
        if (@{ $self->{output} || []}) {
            $status->newval('job', 'error_log',
                (@{ $self->{output}} > 10)
                ? (@{$self->{output}}[-9 .. -1], '...')
                : (@{$self->{output}})
            );
        }
        return 0;
    }
}

=head2 dest

The destination directory for this mirror

=cut

sub dest {
    my ($self) = @_;
    return $self->val('path', $self->name);
}

=head2 du_dest

Perform du over the destination directory and store the result into status file

=cut

sub du_dest {
    my ($self, $status) = @_;
    $status ||= $self->_get_status();
    $self->_log('DEBUG', 'Calculating size of %s', $self->dest);
    $self->getlock() or return;
    if (! -d $self->dest) { return }
    open(my $handle, sprintf('\\du -s %s |', $self->dest)) or return;
    my $line = <$handle>;
    if ($line && $line =~ /^(\d+)/) {
        $status->newval('job', 'size', $1);
        $status->newval('job', 'size_time', scalar(time));
    }
    close($handle);
    $self->_write_status($status);
    $self->unlock;
    return 1;
}

=head1 STATUS FILE STRUCTURE

=head2 job SECTION

=over 4

=item successed 1 if last run was ok

=item size The size of the tree

=item size_time Last time the size were checked

=item first_sync

The first time job is take into account

=back

=head2 success SECTION

=item start

=item end

=head2 failure SECTION

=cut

1;
