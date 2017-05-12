package TheSchwartz::Moosified;

use Moose;
use Moose::Util::TypeConstraints;
use Carp;
use Scalar::Util qw( refaddr );
use List::Util qw( shuffle );
use File::Spec ();
use Storable ();
use TheSchwartz::Moosified::Utils qw/insert_id sql_for_unixtime bind_param_attr run_in_txn order_by_priority/;
use TheSchwartz::Moosified::Job;
use TheSchwartz::Moosified::JobHandle;

our $VERSION = '0.07'; # when bumping, also update t/00-load.t
our $AUTHORITY = 'cpan:FAYLAND';

## Number of jobs to fetch at a time in find_job_for_workers.
our $FIND_JOB_BATCH_SIZE = 50;

# subtype-s
my $sub_verbose = sub {
    my $msg = shift;
    $msg =~ s/\s+$//;
    print STDERR "$msg\n";
};
subtype 'TheSchwartz.Moosified.Verbose'
    => as 'CodeRef'
    => where { 1; };
coerce 'TheSchwartz.Moosified.Verbose'
    => from 'Int'
    => via {
        if ($_) {
            return $sub_verbose;
        } else {
            return sub { 0 };
        }
    };

has 'verbose' => ( is => 'rw', isa => 'TheSchwartz.Moosified.Verbose', coerce => 1, default => 0 );
has 'prioritize' => ( is => 'rw', isa => 'Bool', default => 0 );

has 'retry_seconds' => (is => 'rw', isa => 'Int', default => 30);
has 'retry_at' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

has 'databases' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] },
);

has 'all_abilities'     => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'current_abilities' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'current_job' => ( is => 'rw', isa => 'Object' );

has 'funcmap_cache' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

has 'scoreboard'  => (
    is => 'rw',
    isa => 'Str',
    trigger => \&_trigger_scoreboard,
);

has 'prefix' => ( is => 'rw', isa => 'Str', default => '' );
has 'error_length' => ( is => 'rw', isa => 'Int', default => 255 );

sub debug {
    my $self = shift;
    
    return unless $self->verbose;
    $self->verbose->(@_);
}

sub shuffled_databases {
    my $self = shift;
    return shuffle( @{ $self->databases } );
}

sub _try_insert {
    my $self = shift;
    my $job = shift;
    my $dbh = shift;

    $job->funcid( $self->funcname_to_id( $dbh, $job->funcname ) );

    run_in_txn {
        $job->insert_time(time());

        my $row = $job->as_hashref;
        if ($dbh->{Driver}{Name} && $dbh->{Driver}{Name} eq 'Pg') {
            delete $row->{jobid};
        }
        my @col = keys %$row;

        my $table_job = $self->prefix . 'job';
        my $sql = sprintf 'INSERT INTO %s (%s) VALUES (%s)',
            $table_job, join( ", ", @col ), join( ", ", ("?") x @col );

        my $sth = $dbh->prepare_cached($sql);
        my $i = 1;
        for my $col (@col) {
            $sth->bind_param(
                $i++,
                $row->{$col},
                bind_param_attr( $dbh, $col ),
            );
        }
        $sth->execute();

        my $jobid = insert_id( $dbh, $sth, $table_job, "jobid" );
        $job->jobid($jobid);
    } $dbh;
}

sub insert {
    my $self = shift;

    my $job;
    if ( ref $_[0] eq 'TheSchwartz::Moosified::Job' ) {
        $job = $_[0];
    }
    else {
        $job = TheSchwartz::Moosified::Job->new(funcname => $_[0], arg => $_[1]);
    }
    $job->arg( Storable::nfreeze( $job->arg ) ) if ref $job->arg;

    for my $dbh ( $self->shuffled_databases ) {
        eval {
            $self->_try_insert($job,$dbh);
        };
        $self->debug("insert failed: $@") if $@;

        next unless $job->jobid;

        ## We inserted the job successfully!
        ## Attach a handle to the job, and return the handle.
        my $handle = TheSchwartz::Moosified::JobHandle->new({
                dbh    => $dbh,
                client => $self,
                jobid  => $job->jobid
            });
        $job->handle($handle);
        return $handle;
    }

    return;
}

sub find_job_for_workers {
    my $client = shift;

    my ($worker_classes) = @_;
    $worker_classes ||= $client->{current_abilities};
    
    return unless (scalar @$worker_classes);

    my $limit    = $FIND_JOB_BATCH_SIZE;

    for my $dbh ( $client->shuffled_databases ) {

        my $unixtime = sql_for_unixtime($dbh);
        my $order_by = $client->prioritize ? order_by_priority($dbh) : '';

        my @jobs;
        eval {
            ## Search for jobs in this database where:
            ## 1. funcname is in the list of abilities this $client supports;
            ## 2. the job is scheduled to be run (run_after is in the past);
            ## 3. no one else is working on the job (grabbed_until is in
            ##    in the past).
            my @ids = map { $client->funcname_to_id( $dbh, $_ ) }
                      @$worker_classes;

            my $ids = join(',', @ids);
            my $table_job = $client->prefix . 'job';
            my $sql = qq~SELECT * FROM $table_job WHERE funcid IN ($ids) AND run_after <= $unixtime AND grabbed_until <= $unixtime $order_by LIMIT $limit~;

            my $sth = $dbh->prepare_cached($sql);
            $sth->execute();
            while ( my $ref = $sth->fetchrow_hashref ) {
                push @jobs, $ref;
            }
            $sth->finish;
        };
#        if ($@) {
#
#        }

        my $job = $client->_grab_a_job($dbh, @jobs);
        return $job if $job;
    }
}

sub get_server_time {
    my ( $client, $dbh ) = @_;
    my $unixtime_sql = sql_for_unixtime($dbh);
    return $dbh->selectrow_array("SELECT $unixtime_sql");
}

sub _grab_a_job {
    my ( $client, $dbh, @jobs ) = @_;

    ## Got some jobs! Randomize them to avoid contention between workers.
    @jobs = shuffle(@jobs);

  JOB:
    while (my $ref = shift @jobs) {
        my $job = TheSchwartz::Moosified::Job->new( $ref );

        ## Convert the funcid to a funcname, based on this database's map.
        $job->funcname( $client->funcid_to_name($dbh, $job->funcid) );

        ## Update the job's grabbed_until column so that
        ## no one else takes it.
        my $worker_class = $job->funcname;
        my $old_grabbed_until = $job->grabbed_until;
        
        my $server_time = $client->get_server_time($dbh)
            or die "expected a server time";
        
        my $new_grabbed_until = $server_time + ($worker_class->grab_for || 1);

        # Prevent a condition that could result in more than one client
        # grabbing the same job b/c it doesn't look grabbed
        next JOB if ($new_grabbed_until == $old_grabbed_until);

        ## Update the job in the database, and end the transaction.

        my $table_job = $client->prefix . 'job';
        my $sql  = qq~UPDATE $table_job SET grabbed_until = ? WHERE jobid = ? AND grabbed_until = ?~;
        my $sth  = $dbh->prepare($sql);
        $sth->execute($new_grabbed_until, $job->jobid, $old_grabbed_until);
        my $rows = $sth->rows;

        next JOB unless $rows == 1;
        
        $job->grabbed_until( $new_grabbed_until );

        ## Now prepare the job, and return it.
        my $handle = TheSchwartz::Moosified::JobHandle->new({
            dbh    => $dbh,
            client => $client,
            jobid  => $job->jobid,
        });
        $job->handle($handle);
        return $job;
    }

    return undef;
}

sub list_jobs {
    my ( $self, $arg ) = @_;

    die "No funcname" unless exists $arg->{funcname};

    my @options;
    push @options, {
        key   => 'run_after',
        op    => '<=',
        value => $arg->{run_after}
    } if exists $arg->{run_after};
    push @options, {
        key   => 'grabbed_until',
        op    => '<=',
        value => $arg->{grabbed_until}
    } if exists $arg->{grabbed_until};

    if ( $arg->{coalesce} ) {
        $arg->{coalesce_op} ||= '=';
        push @options, {
            key   => 'coalesce',
            op    => $arg->{coalesce_op},
            value => $arg->{coalesce}
        };
    }
    
    my $limit = $arg->{limit} || $FIND_JOB_BATCH_SIZE;

    my @jobs;
    for my $dbh ( $self->shuffled_databases ) {
        my $order_by = $self->prioritize ? order_by_priority($dbh) : '';

        eval {
            
            my ($funcid, $funcop);
            if ( ref($arg->{funcname}) ) { # ARRAYREF
                $funcid = '(' . join(',', map { $self->funcname_to_id($dbh, $_) } @{$arg->{funcname}}) . ')';
                $funcop = 'IN';
            } else {
                $funcid = $self->funcname_to_id($dbh, $arg->{funcname});
                $funcop = '=';
            }

            my $table_job = $self->prefix . 'job';
            my $sql = qq~SELECT * FROM $table_job WHERE funcid $funcop $funcid~;
            my @value = ();
            for (@options) {
                $sql .= " AND $_->{key} $_->{op} ?";
                push @value, $_->{value};
            }
            $sql .= qq~ $order_by LIMIT $limit~;

            my $sth = $dbh->prepare_cached($sql);
            $sth->execute(@value);
            while ( my $ref = $sth->fetchrow_hashref ) {
                $ref->{funcname} = $self->funcid_to_name($dbh, $ref->{funcid});
                my $job = TheSchwartz::Moosified::Job->new( $ref );
                if ($arg->{want_handle}) {
                    my $handle = TheSchwartz::Moosified::JobHandle->new({
                        dbh    => $dbh,
                        client => $self,
                        jobid  => $job->jobid
                    });
                    $job->handle($handle);
                }
                push @jobs, $job;
            }
            $sth->finish;
        };
    }

    return @jobs;
}

sub find_job_with_coalescing_prefix {
    my $client = shift;
    my ($funcname, $coval) = @_;
    $coval .= "%";
    return $client->_find_job_with_coalescing('LIKE', $funcname, $coval);
}

sub find_job_with_coalescing_value {
    my $client = shift;
    return $client->_find_job_with_coalescing('=', @_);
}

sub _find_job_with_coalescing {
    my $client = shift;
    my ($op, $funcname, $coval) = @_;

    my $limit    = $FIND_JOB_BATCH_SIZE;
    my $order_by = $client->prioritize ? 'ORDER BY priority DESC' : '';

    for my $dbh ( $client->shuffled_databases ) {
        my $unixtime = sql_for_unixtime($dbh);

        my @jobs;
        eval {
            ## Search for jobs in this database where:
            ## 1. funcname is in the list of abilities this $client supports;
            ## 2. the job is scheduled to be run (run_after is in the past);
            ## 3. no one else is working on the job (grabbed_until is in
            ##    in the past).
            my $funcid = $client->funcname_to_id($dbh, $funcname);

            my $table_job = $client->prefix . 'job';
            my $sql = qq~SELECT * FROM $table_job WHERE funcid = ? AND run_after <= $unixtime AND grabbed_until <= $unixtime AND coalesce $op ? $order_by LIMIT $limit~;
            my $sth = $dbh->prepare_cached($sql);
            $sth->execute( $funcid, $coval );
            while ( my $ref = $sth->fetchrow_hashref ) {
                $ref->{funcname} = $funcname;
                push @jobs, $ref;
            }
            $sth->finish;
        };
#        if ($@) {
#
#        }

        my $job = $client->_grab_a_job($dbh, @jobs);
        return $job if $job;
    }
}

sub can_do {
    my $client = shift;
    my ($class) = @_;
    push @{ $client->{all_abilities} }, $class;
    push @{ $client->{current_abilities} }, $class;
}

sub reset_abilities {
    my $client = shift;
    $client->{all_abilities} = [];
    $client->{current_abilities} = [];
}

sub restore_full_abilities {
    my $client = shift;
    $client->{current_abilities} = [ @{ $client->{all_abilities} } ];
}

sub temporarily_remove_ability {
    my $client = shift;
    my ($class) = @_;
    $client->{current_abilities} = [
            grep { $_ ne $class } @{ $client->{current_abilities} }
        ];
    if (!@{ $client->{current_abilities} }) {
        $client->restore_full_abilities;
    }
}

sub work {
    my $client = shift;
    my ($delay) = @_;
    $delay ||= 5;
    while (1) {
        sleep $delay unless $client->work_once;
    }
}

sub work_until_done {
    my $client = shift;
    while (1) {
        $client->work_once or last;
    }
}

## Returns true if it did something, false if no jobs were found
sub work_once {
    my $client = shift;
    my $job = shift;  # optional specific job to work on

    ## Look for a job with our current set of abilities. Note that the
    ## list of current abilities may not be equal to the full set of
    ## abilities, to allow for even distribution between jobs.
    $job ||= $client->find_job_for_workers;

    ## If we didn't find anything, restore our full abilities, and try
    ## again.
    if (!$job &&
        @{ $client->{current_abilities} } < @{ $client->{all_abilities} }) {
        $client->restore_full_abilities;
        $job = $client->find_job_for_workers;
    }

    my $class = $job ? $job->funcname : undef;
    if ($job) {
        my $priority = $job->priority ? ", priority " . $job->priority : "";
        $job->debug("TheSchwartz::work_once got job of class '$class'$priority");
    } else {
        $client->debug("TheSchwartz::work_once found no jobs");
    }

    ## If we still don't have anything, return.
    return unless $job;

    ## Now that we found a job for this particular funcname, remove it
    ## from our list of current abilities. So the next time we look for a
    ## we'll find a job for a different funcname. This prevents starvation of
    ## high funcid values because of the way MySQL's indexes work.
    $client->temporarily_remove_ability($class);

    $class->work_safely($job);

    ## We got a job, so return 1 so work_until_done (which calls this method)
    ## knows to keep looking for jobs.
    return 1;
}

sub funcid_to_name {
    my ( $client, $dbh, $funcid ) = @_;
    my $cache = $client->_funcmap_cache($dbh);
    return $cache->{funcid2name}{$funcid};
}

sub funcname_to_id {
    my ( $self, $dbh, $funcname ) = @_;

    my $dbid  = refaddr $dbh;
    my $cache = $self->_funcmap_cache($dbh);
    my $table_funcmap = $self->prefix . 'funcmap';

    unless ( exists $cache->{funcname2id}{$funcname} ) {
        my $id;
        eval {
            run_in_txn {
                ## This might fail in a race condition since funcname is UNIQUE
                my $sth = $dbh->prepare_cached(
                    "INSERT INTO $table_funcmap (funcname) VALUES (?)");
                $sth->execute($funcname);

                $id = insert_id( $dbh, $sth, $table_funcmap, "funcid" );
            } $dbh;
        };

        ## If we got an exception, try to load the record again
        if ($@) {
            my $sth = $dbh->prepare_cached(
                "SELECT funcid FROM $table_funcmap WHERE funcname = ?");
            $sth->execute($funcname);
            ($id) = $sth->fetchrow_array;
            $sth->finish;
            croak "Can't find or create funcname $funcname: $@" unless $id;
        }

        $cache->{funcname2id}{ $funcname } = $id;
        $cache->{funcid2name}{ $id } = $funcname;
        $self->funcmap_cache->{$dbid} = $cache;
    }

    $cache->{funcname2id}{$funcname};
}

sub _funcmap_cache {
    my ( $client, $dbh ) = @_;
    my $dbid = refaddr $dbh;
    my $table_funcmap = $client->prefix . 'funcmap';
    unless ( exists $client->funcmap_cache->{$dbid} ) {
        my $cache = { funcname2id => {}, funcid2name => {} };
        my $sth = $dbh->prepare_cached("SELECT funcid, funcname FROM $table_funcmap");
        $sth->execute;
        while ( my $row = $sth->fetchrow_arrayref ) {
            $cache->{funcname2id}{ $row->[1] } = $row->[0];
            $cache->{funcid2name}{ $row->[0] } = $row->[1];
        }
        $sth->finish;
        $client->funcmap_cache->{$dbid} = $cache;
    }
    return $client->funcmap_cache->{$dbid};
}

sub _trigger_scoreboard {
    my ($self, $dir) = @_;
    
    return unless $dir;
    return if (-f $dir); # no endless loop

    # They want the scoreboard but don't care where it goes
    if (($dir eq '1') or ($dir eq 'on')) {
        $dir = File::Spec->tmpdir();
    }

    $self->{scoreboard} = $dir."/theschwartz.scoreboard.$$";
}

sub start_scoreboard {
    my $client = shift;

    # Don't do anything if we're not configured to write to the scoreboard
    my $scoreboard = $client->scoreboard;
    return unless $scoreboard;

    # Don't do anything of (for some reason) we don't have a current job
    my $job = $client->current_job;
    return unless $job;

    my $class = $job->funcname;

    open(my $sb, '>', $scoreboard)
      or $job->debug("Could not write scoreboard '$scoreboard': $!");
    print $sb join("\n", ("pid=$$",
                         'funcname='.($class||''),
                         'started='.($job->grabbed_until-($class->grab_for||1)),
                         'arg='._serialize_args($job->arg),
                        )
                 ), "\n";
    close($sb);

    return;
}

# Quick and dirty serializer.  Don't use Data::Dumper because we don't need to
# recurse indefinitely and we want to truncate the output produced
sub _serialize_args {
    my ($args) = @_;

    if (ref $args) {
        if (ref $args eq 'HASH') {
            return join ',',
                   map { ($_||'').'='.substr($args->{$_}||'', 0, 200) }
                   keys %$args;
        } elsif (ref $args eq 'ARRAY') {
            return join ',',
                   map { substr($_||'', 0, 200) }
                   @$args;
        }
    } else {
        return $args;
    }
}

sub end_scoreboard {
    my $client = shift;

    # Don't do anything if we're not configured to write to the scoreboard
    my $scoreboard = $client->scoreboard;
    return unless $scoreboard;

    my $job = $client->current_job;

    open(my $sb, '>>', $scoreboard)
      or $client->debug("Could not append scoreboard '$scoreboard': $!");
    print $sb "done=".time."\n";
    close($sb);

    return;
}

sub clean_scoreboard {
    my $client = shift;

    # Don't do anything if we're not configured to write to the scoreboard
    my $scoreboard = $client->scoreboard;
    return unless $scoreboard;

    unlink($scoreboard);
}

sub DEMOLISH {
    foreach my $arg (@_) {
        # Call 'clean_scoreboard' on TheSchwartz objects
        if (ref($arg) and $arg->isa('TheSchwartz::Moosified')) {
            $arg->clean_scoreboard;
        }
    }
}

no Moose;
no Moose::Util::TypeConstraints;
1; # End of TheSchwartz::Moosified
__END__

=head1 NAME

TheSchwartz::Moosified - TheSchwartz based on Moose!

=head1 SYNOPSIS

    use TheSchwartz::Moosified;

    my $client = TheSchwartz::Moosified->new();
    $client->databases([$dbh]);
    
    # rest are the same as TheSchwartz
    
    # in some place we insert job into TheSchwartz::Moosified
    # in another place we run this job
    
    # 1, insert job in cgi/Catalyst
    use TheSchwartz::Moosified;
    my $client = TheSchwartz::Moosified->new();
    $client->databases([$dbh]);
    $client->insert('My::Worker::A', { args1 => 1, args2 => 2 } );
    
    # 2, defined the heavy things in My::Worker::A
    package My::Worker::A;
    use base 'TheSchwartz::Moosified::Worker';
    sub work {
        my ($class, $job) = @_;
    
        # $job is an instance of TheSchwartz::Moosified::Job
        my $args = $job->args;
        # do heavy things like resize photos, add 1 to 2 etc.
        $job->completed;
    }
    
    # 3, run the worker in a non-stop script
    use TheSchwartz::Moosified;
    my $client = TheSchwartz::Moosified->new();
    $client->databases([$dbh]);
    $client->can_do('My::Worker::A');
    $client->work();

=head1 DESCRIPTION

L<TheSchwartz> is a powerful job queue. This module is a Moose implemention.

read more on L<TheSchwartz>

=head1 SETTING

=over 4

=item * C<databases>

Databases containing TheSchwartz jobs, shuffled before each use.

    my $dbh1 = DBI->conncet(@dbi_info);
    my $dbh2 = $schema->storage->dbh;
    my $client = TheSchwartz::Moosified->new( databases => [ $dbh1, $dbh2 ] );
    
    # or
    my $client = TheSchwartz::Moosified->new();
    $client->databases( [ $dbh1, $dbh2 ] );

=item * C<verbose>

controls debug logging.

    my $client = TheSchwartz::Moosified->new( verbose => 1 );
    
    # or
    my $client = TheSchwartz::Moosified->new();
    $client->verbose( 1 );
    $client->verbose( sub {
        my $msg = shift;
        print STDERR "[INFO] $msg\n";
    } );

=item * C<prefix>

optional prefix for tables. compatible with L<TheSchwartz::Simple>

    my $client = TheSchwartz::Moosified->new( prefix => 'theschwartz_' );

=item * C<scoreboard>

save job info to file. by default, the file will be saved at $tmpdir/theschwartz/scoreboard.$$

    my $client = TheSchwartz::Moosified->new( scoreboard => 1 );
    
    # or
    my $client = TheSchwartz::Moosified->new();
    # be sure the file is there
    $client->scoreboard( "/home/fayland/theschwartz/scoreboard.log" );

=item * C<error_length>

optional, defaults to 255.  Messages logged to the C<failure_log> (the
C<error> table) are truncated to this length.  Setting this to zero means no
truncation (although the database you are using may truncate this for you).

=back

=head1 POSTING JOBS

The methods of TheSchwartz clients used by applications posting jobs to the
queue are:

=head2 C<$client-E<gt>insert( $job )>

Adds the given C<TheSchwartz::Job> to one of the client's job databases.

=head2 C<$client-E<gt>insert( $funcname, $arg )>

Adds a new job with funcname C<$funcname> and arguments C<$arg> to the queue.

=head1 WORKING

The methods of TheSchwartz clients for use in worker processes are:

=head2 C<$client-E<gt>can_do( $ability )>

Adds C<$ability> to the list of abilities C<$client> is capable of performing.
Subsequent calls to that client's C<work> methods will find jobs requiring the
given ability.

=head2 C<$client-E<gt>work_once()>

Find and perform one job C<$client> can do.

=head2 C<$client-E<gt>work_until_done()>

Find and perform jobs C<$client> can do until no more such jobs are found in
any of the client's job databases.

=head2 C<$client-E<gt>work( [$delay] )>

Find and perform any jobs C<$client> can do, forever. When no job is available,
the working process will sleep for C<$delay> seconds (or 5, if not specified)
before looking again.

=head2 C<$client-E<gt>find_job_for_workers( [$abilities] )>

Returns a C<TheSchwartz::Job> for a random job that the client can do. If
specified, the job returned matches one of the abilities in the arrayref
C<$abilities>, rather than C<$client>'s abilities.

=head2 C<$client-E<gt>find_job_with_coalescing_value( $ability, $coval )>

Returns a C<TheSchwartz::Job> for a random job for a worker capable of
C<$ability> and with a coalescing value of C<$coval>.

=head2 C<$client-E<gt>find_job_with_coalescing_prefix( $ability, $coval )>

Returns a C<TheSchwartz::Job> for a random job for a worker capable of
C<$ability> and with a coalescing value beginning with C<$coval>.

Note the C<TheSchwartz> implementation of this function uses a C<LIKE> query to
find matching jobs, with all the attendant performance implications for your
job databases.

=head1 SEE ALSO

L<TheSchwartz>, L<TheSchwartz::Simple>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

Jeremy Stashewsky, C<< <jstash+cpan at gmail.com> >>

Luke Closs C<< <cpan at 5thplane.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008,2016 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
