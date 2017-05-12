package Unix::PID;

# this works with these uncommented, but we leave them commented out to avoid a little time and memory
# use strict;
# use warnings;
$Unix::PID::VERSION = '0.23';

sub import {
    shift;
    my $file = defined $_[0] && $_[0] !~ m{ \A \d+ \. \d+ \. \d+ \z }xms ? shift : '';

    #### handle use Mod '1.2.3'; here? make it play nice with version.pm ?? ##
    #    my $want = shift;
    #
    #    if(defined $want && $want !~ m{^\d+\.\d+\.\d+$}) {
    #        require Carp;
    #        Carp::croak "Unix::PID is version $VERSION, you requested $want"
    #            if Unix::PID->VERSION < version->new($want)->numify();
    #    }
    #### ???? ##

    if ( defined $file && $file ne '' ) {
        require Carp;
        Unix::PID->new()->pid_file($file)
          || Carp::croak("The PID in $file is still running.");
    }
}

sub new {
    my ( $class, $args_ref ) = @_;
    $args_ref = {} if ref($args_ref) ne 'HASH';
    my $self = bless(
        {
            'ps_path'     => '',
            'errstr'      => '',
            'minimum_pid' => !exists $args_ref->{'minimum_pid'} || $args_ref->{'minimum_pid'} !~ m{\A\d+\z}ms ? 11 : $args_ref->{'minimum_pid'},
            'open3'       => exists $args_ref->{'use_open3'} && !$args_ref->{'use_open3'} ? 0 : 1,
        },
        $class
    );
    require IPC::Open3 if $self->{'open3'};

    $self->set_ps_path( $args_ref->{'ps_path'} ) if exists $args_ref->{'ps_path'};

    return $self;
}

sub get_ps_path {
    return $_[0]->{'ps_path'};
}

sub get_errstr {
    return $_[0]->{'errstr'};
}

sub non_blocking_wait {
    my ($self) = @_;
    while ( ( my $zombie = waitpid( -1, 1 ) ) > 0 ) { }
}

sub set_ps_path {
    my ( $self, $path ) = @_;
    $path = substr( $path, 0, ( length($path) - 1 ) )
      if substr( $path, -1, 1 ) eq '/';
    if ( ( -d $path && -x "$path/ps" ) || $path eq '' ) {
        $self->{'ps_path'} = $path;
        return 1;
    }
    else {
        return;
    }
}

sub get_pidof {
    my ( $self, $name, $exact ) = @_;
    my %map;
    for ( $self->_raw_ps( 'axo', 'pid,command' ) ) {
        $_ =~ s{ \A \s* | \s* \z }{}xmsg;
        my ( $pid, $cmd ) = $_ =~ m{ \A (\d+) \s+ (.*) \z }xmsg;
        $map{$pid} = $cmd if $pid && $pid ne $$ && $cmd;
    }
    my @pids =
      $exact
      ? grep { $map{$_} =~ m/^\Q$name\E$/ } keys %map
      : grep { $map{$_} =~ m/\Q$name\E/ } keys %map;

    return wantarray ? @pids : $pids[0];
}

sub kill {
    my ( $self, $pid, $give_kill_a_chance ) = @_;
    $give_kill_a_chance = int $give_kill_a_chance;
    $pid = int $pid;
    my $min = int $self->{'minimum_pid'};
    if ( $pid < $min ) {

        # prevent bad args from killing the process group (IE '0')
        # or general low level ones
        warn "kill() called with integer value less than $min";
        return;
    }

    # CORE::kill 0, $pid : may be false but still running, see `perldoc -f kill`
    if ( $self->is_pid_running($pid) ) {

        # RC from CORE::kill is not a boolean of if the PID was killed or not, only that it was signaled
        # so it is not an indicator of "success" in killing $pid
        CORE::kill( 15, $pid );    # TERM
        CORE::kill( 2,  $pid );    # INT
        CORE::kill( 1,  $pid );    # HUP
        CORE::kill( 9,  $pid );    # KILL
        
        # give kill() some time to take effect?
        if ($give_kill_a_chance) {
            sleep($give_kill_a_chance);
        }
        return if $self->is_pid_running($pid);
    }
    return 1;
}

sub get_pid_from_pidfile {
    my ( $self, $pid_file ) = @_;

    # if this function is ever changed to use $self as a hash object, update pid_file() to not do a class method call
    return 0 if !-e $pid_file;

    open my $pid_fh, '<', $pid_file or return;
    chomp( my $pid = <$pid_fh> );
    close $pid_fh;

    return int( abs($pid) );
}

sub is_pidfile_running {
    my ( $self, $pid_file ) = @_;
    my $pid = $self->get_pid_from_pidfile($pid_file) || return;
    return $pid if $self->is_pid_running($pid);
    return;
}

sub pid_file {
    my ( $self, $pid_file, $newpid, $retry_conf ) = @_;
    $newpid = $$ if !$newpid;

    my $rc = $self->pid_file_no_unlink( $pid_file, $newpid, $retry_conf );
    if ( $rc && $newpid == $$ ) {

        # prevent forked childrens' END from killing parent's pid files
        #   'unlink_end_use_current_pid_only' is undocumented as this may change, feedback welcome!
        #   'carp_unlink_end' undocumented as it is only meant for testing (rt57462, use Test::Carp to test END behavior)
        if ( $self->{'unlink_end_use_current_pid_only'} ) {
            eval 'END { unlink $pid_file if $$ eq ' . $$ . '}';
            if ( $self->{'carp_unlink_end'} ) {

                # eval 'END { require Carp;Carp::carp("[info] $$ !unlink $pid_file (current pid check)") if $$ ne ' . $$ . '}';
                eval 'END { require Carp;Carp::carp("[info] $$ unlink $pid_file (current pid check)") if $$ eq ' . $$ . '}';
            }
        }
        else {
            eval 'END { unlink $pid_file if Unix::PID->get_pid_from_pidfile($pid_file) eq $$ }';
            if ( $self->{'carp_unlink_end'} ) {

                # eval 'END { require Carp;Carp::carp("[info] $$ !unlink $pid_file (pid file check)") if Unix::PID->get_pid_from_pidfile($pid_file) ne $$ }';
                eval 'END { require Carp;Carp::carp("[info] $$ unlink $pid_file (pid file check)") if Unix::PID->get_pid_from_pidfile($pid_file) eq $$ }';
            }
        }
    }

    return 1 if $rc == 1;
    return 0 if defined $rc && $rc == 0;
    return;
}

sub pid_file_no_unlink {
    my ( $self, $pid_file, $newpid, $retry_conf ) = @_;
    $newpid = $$ if !$newpid;

    if ( ref($retry_conf) eq 'ARRAY' ) {
        $retry_conf->[0] = int( abs( $retry_conf->[0] ) );
        for my $idx ( 1 .. scalar( @{$retry_conf} ) - 1 ) {
            next if ref $retry_conf->[$idx] eq 'CODE';
            $retry_conf->[$idx] = int( abs( $retry_conf->[$idx] ) );
        }
    }
    else {
        $retry_conf = [ 3, 1, 2 ];
    }

    my $passes = 0;
    require Fcntl;

  EXISTS:
    $passes++;
    if ( -e $pid_file ) {

        my $curpid = $self->get_pid_from_pidfile($pid_file);

        # TODO: narrow even more the race condition where $curpid stops running and a new PID is put in
        # the file between when we pull in $curpid above and check to see if it is running/unlink below

        return 1 if int $curpid == $$ && $newpid == $$;    # already setup
        return if int $curpid == $$;                       # can't change it while $$ is alive
        return if $self->is_pid_running( int $curpid );

        unlink $pid_file;                                  # must be a stale PID file, so try to remove it for sysopen()
    }

    # write only if it does not exist:
    sysopen( my $pid_fh, $pid_file, Fcntl::O_WRONLY() | Fcntl::O_EXCL() | Fcntl::O_CREAT() ) || do {
        return 0 if $passes >= $retry_conf->[0];
        if ( ref( $retry_conf->[$passes] ) eq 'CODE' ) {
            $retry_conf->[$passes]->( $self, $pid_file, $passes );
        }
        else {
            sleep( $retry_conf->[$passes] ) if $retry_conf->[$passes];
        }
        goto EXISTS;
    };

    print {$pid_fh} int( abs($newpid) );
    close $pid_fh;

    return 1;
}

sub kill_pid_file {
    my ( $self, $pidfile ) = @_;
    my $rc = $self->kill_pid_file_no_unlink($pidfile);
    if ( $rc && -e $pidfile ) {
        unlink $pidfile or return -1;
    }
    return $rc;
}

sub kill_pid_file_no_unlink {
    my ( $self, $pidfile ) = @_;
    if ( -e $pidfile ) {
        my $pid = $self->get_pid_from_pidfile($pidfile);
        $self->kill($pid) or return;
        return $pid;
    }
    return 1;
}

sub is_running {
    my ( $self, $check_this, $exact ) = @_;
    return $self->is_pid_running($check_this) if $check_this =~ m{ \A \d+ \z }xms;
    return $self->is_command_running( $check_this, $exact );
}

sub pid_info {
    my ( $self, $pid ) = @_;
    my @outp = $self->_pid_info_raw($pid);
    return wantarray ? split( /\s+/, $outp[1], 11 ) : [ split( /\s+/, $outp[1], 11 ) ];
}

sub pid_info_hash {
    my ( $self, $pid ) = @_;
    my @outp = $self->_pid_info_raw($pid);
    my %info;
    @info{ split( /\s+/, $outp[0], 11 ) } = split( /\s+/, $outp[1], 11 );
    return wantarray ? %info : \%info;
}

sub _pid_info_raw {
    my ( $self, $pid ) = @_;
    my @info = $self->_raw_ps( 'u', '-p', $pid );
    chomp @info;
    return wantarray ? @info : \@info;
}

sub is_pid_running {
    my ( $self, $check_pid ) = @_;
    $check_pid = int($check_pid);
    return if !$check_pid;
    
    return 1 if $> == 0 && CORE::kill( 0, $check_pid );    # if we are superuser we can avoid the the system call. For details see `perldoc -f kill`

    # If the proc filesystem is available, it's a good test. If not, continue on to system call
    return 1 if -e "/proc/$$" && -r "/proc/$$" && -r "/proc/$check_pid";
    
    # even if we are superuser, go ahead and call ps just in case CORE::kill 0's false RC was erroneous
    my $info = ( $self->_pid_info_raw($check_pid) )[1];
    return 1 if defined $info;
    return;
}

sub is_command_running {
    my ( $self, $check_command, $exact ) = @_;
    return scalar $self->get_pidof( $check_command, $exact ) ? 1 : 0;
}

sub wait_for_pidsof {
    my ( $self, $wait_ref ) = @_;

    $wait_ref->{'get_pidof'} = $self->get_command($$) if !$wait_ref->{'get_pidof'};
    $wait_ref->{'max_loops'} = 5
      if !defined $wait_ref->{'max_loops'}
          || $wait_ref->{'max_loops'} !~ m{ \A \d+ \z }xms;

    $wait_ref->{'hit_max_loops'} = sub {
        die 'Hit max loops in wait_for_pidsof()';
      }
      if ref $wait_ref->{'hit_max_loops'} ne 'CODE';

    my @got_pids;
    if ( ref $wait_ref->{'pid_list'} eq 'ARRAY' ) {
        @got_pids = grep { defined } map { $self->is_pid_running($_) ? $_ : undef } @{ $wait_ref->{'pid_list'} };
    }
    else {
        @got_pids = $self->get_pidof( $wait_ref->{'get_pidof'} );
    }

    if ( $wait_ref->{'use_hires_usleep'} || $wait_ref->{'use_hires_nanosleep'} ) {
        require Time::HiRes;
    }

    my $lcy = '';
    my $fib = '';
    if ( ref $wait_ref->{'sleep_for'} ) {
        if ( ref $wait_ref->{'sleep_for'} eq 'ARRAY' ) {
            require List::Cycle;
            $lcy = List::Cycle->new( { 'values' => $wait_ref->{'sleep_for'} } );
        }
        if ( $wait_ref->{'sleep_for'} eq 'HASH' ) {
            if ( exists $wait_ref->{'sleep_for'}->{'fibonacci'} ) {
                require Math::Fibonacci::Phi;
                $fib = 1;
            }
        }
    }
    $wait_ref->{'sleep_for'} = 60 if !defined $wait_ref->{'sleep_for'};

    my $loop_cnt = 0;

    while ( scalar @got_pids ) {
        $loop_cnt++;

        $wait_ref->{'pre_sleep'}->( $loop_cnt, \@got_pids )
          if ref $wait_ref->{'pre_sleep'} eq 'CODE';

        my $period =
            $lcy ? $lcy->next()
          : $fib ? Math::Fibonacci::term($loop_cnt)
          :        $wait_ref->{'sleep_for'};

        if ( $wait_ref->{'use_hires_nanosleep'} ) {
            Time::HiRes::nanosleep($period);
        }
        elsif ( $wait_ref->{'use_hires_usleep'} ) {
            Time::HiRes::usleep($period);
        }
        else {
            sleep $period;
        }

        if ( ref $wait_ref->{'pid_list'} eq 'ARRAY' ) {
            @got_pids = grep { defined } map { $self->is_pid_running($_) ? $_ : undef } @{ $wait_ref->{'pid_list'} };
        }
        else {
            @got_pids = $self->get_pidof( $wait_ref->{'get_pidof'} );
        }

        if ( $loop_cnt >= $wait_ref->{'max_loops'} ) {
            $wait_ref->{'hit_max_loops'}->( $loop_cnt, \@got_pids );
            last;
        }
    }
}

sub _raw_ps {
    my ( $self, @ps_args ) = @_;
    my $path = $self->get_ps_path();
    $self->{'errstr'} = '';

    if ( !$path ) {
        for (
            qw( /usr/local/bin /usr/local/sbin
            /usr/bin /usr/sbin
            /bin      /sbin
            )
          ) {
            if ( -x "$_/ps" ) {
                $self->set_ps_path($_);
                $path = $self->get_ps_path();
                last;
            }
        }
    }

    my $ps = $path ? "$path/ps" : 'ps';
    my @out;

    if ( $self->{'open3'} ) {
        local $SIG{'CHLD'} = 'IGNORE';

        # IPC::Open3 says: If CHLD_ERR is false, or the same file descriptor as CHLD_OUT, then STDOUT and STDERR of the child are on the same filehandle (this means that an autovivified lexical cannot be used for the STDERR filehandle, see SYNOPSIS).
        my $err_fh = \*Unix::PID::PS_ERR;
        my $pid = IPC::Open3::open3( my $in_fh, my $out_fh, $err_fh, $ps, @ps_args );

        @out = <$out_fh>;
        $self->{'errstr'} = join '', <$err_fh>;

        close $in_fh;
        close $out_fh;
        close $err_fh;
        waitpid( $pid, 0 );
    }
    else {

        # command's STDERR is not captured by backticks so we silence it, if you want finer grained control do not disable open3
        @out = `$ps @ps_args 2>/dev/null`;    # @ps_args will interpolate in these backticks like it does in double quotes
    }

    return wantarray ? @out : join '', @out;
}

sub AUTOLOAD {
    my ( $self, $pid ) = @_;

    # return if $Unix::PID::AUTOLOAD eq 'Unix::PID::DESTROY';  # don't try to autoload this one ...

    my $subname = $Unix::PID::AUTOLOAD . '=';
    $subname =~ s/.*:://;
    $subname =~ s{\A get\_ }{}xms;

    my $data = $self->_raw_ps( '-p', $pid, '-o', $subname );
    $data =~ s{ \A \s* | \s* \z }{}xmsg;
    return $data;
}

sub DESTROY { }    # just to avoid trying to autoload this one ...

1;
