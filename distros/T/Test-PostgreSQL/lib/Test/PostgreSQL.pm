package Test::PostgreSQL;
use 5.14.0;
use strict;
use warnings;
use Moo;
use Types::Standard -all;
use Function::Parameters qw(:strict);
use Try::Tiny;
use DBI;
use File::Spec;
use File::Temp;
use File::Which;
use POSIX qw(SIGQUIT SIGKILL WNOHANG getuid setuid);
use User::pwent;

our $VERSION = '1.25';
our $errstr;

# Deprecate use of %Defaults as we want to remove this package global
use Tie::Hash::Method;
tie our %Defaults, 'Tie::Hash::Method', FETCH => sub {
    my $msg = "\nWARNING: using \$Test::PostgreSQL::Defaults is DEPRECATED.";
    if ( $_[1] =~ /^(initdb|postmaster)_args$/ ) {
        $msg .= " Use Test::PostgreSQL->new( extra_$_[1] => ... ) instead.";
    }
    warn $msg;
    return $_[0]->base_hash->{ $_[1] };
  };

%Defaults = (
    auto_start      => 2,
    initdb_args     => '-U postgres -A trust',
    postmaster_args => '-h 127.0.0.1 -F',
);

has dbname => (
    is => 'ro',
    isa => Str,
    default => 'test',
);

has dbowner => (
    is => 'ro',
    isa => Str,
    default => 'postgres',
);

has host => (
    is => 'ro',
    isa => Str,
    default => '127.0.0.1',
);

# Various paths that Postgres gets installed under, sometimes with a version on the end,
# in which case take the highest version. We append /bin/ and so forth to the path later.
# *Note that these are used only if the program isn't already in the path!*
has search_paths => (
  is => "ro",
  isa => ArrayRef,
  builder => "_search_paths",
);

method _search_paths() {
    my @base_paths = (
        # popular installation dir?
        qw(/usr/local/pgsql),
        # ubuntu (maybe debian as well, find the newest version)
        (sort { $b cmp $a } grep { -d $_ } glob "/usr/lib/postgresql/*"),
        # macport
        (sort { $b cmp $a } grep { -d $_ } glob "/opt/local/lib/postgresql*"),
        # Postgresapp.com
        (sort { $b cmp $a } grep { -d $_ } glob "/Applications/Postgres.app/Contents/Versions/*"),
        # BSDs end up with it in /usr/local/bin which doesn't appear to be in the path sometimes:
        "/usr/local",
    );

    # This environment variable is used to override the default, so it gets
    # prefixed to the start of the search paths.
    if (defined $ENV{POSTGRES_HOME}) {
      return [$ENV{POSTGRES_HOME}, @base_paths];
    }
    return \@base_paths;
}

# We attempt to use this port first, and will increment from there.
# The final port ends up in the ->port attribute.
has base_port => (
  is => "ro",
  isa => Int,
  default => 15432,
);

has auto_start => (
  is => "ro",
  default => 2,
);

has base_dir => (
  is => "rw",
  default => sub {
    File::Temp->newdir(
        'pgtest.XXXXX',
        CLEANUP => $ENV{TEST_POSTGRESQL_PRESERVE} ? undef : 1,
        EXLOCK  => 0,
        TMPDIR  => 1
    );
  },
  coerce => fun ($newval) {
    # Ensure base_dir is absolute; usually only the case if the user set it.
    # Avoid munging objects such as File::Temp
    ref $newval ? $newval : File::Spec->rel2abs($newval);
  },
);

has socket_dir => (
  is => "ro",
  isa => Str,
  lazy => 1,
  default => method () { File::Spec->catdir( $self->base_dir, 'tmp' ) },
);

has initdb => (
  is => "ro",
  isa => Str,
  lazy => 1,
  default => method () { $self->_find_program('initdb') || die $errstr },
);

has initdb_args => (
  is => "lazy",
  isa => Str,
);

method _build_initdb_args() {
    return '-U '. $self->dbowner . ' -A trust ' . $self->extra_initdb_args;
}

has extra_initdb_args => (
  is      => "ro",
  isa     => Str,
  default => "",
);

has unix_socket => (
  is  => "ro",
  isa     => Bool,
  default => 0,
);

has pg_ctl => (
  is => "ro",
  isa => Maybe[Str],
  lazy => 1,
  builder => "_pg_ctl_builder",
);

method _pg_ctl_builder() {
  my $prog = $self->_find_program('pg_ctl');
  if ( $prog ) {
      # we only use pg_ctl if Pg version is >= 9
      my $ret = qx/"$prog" --version/;
      if ( $ret =~ /(\d+)(?:\.|devel)/ && $1 >= 9 ) {
          return $prog;
      }
      warn "pg_ctl version earlier than 9";
      return;
  }
  return;
}

has pg_config => (
    is => 'ro',
    isa => Str,
);

has psql => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    default => method () { $self->_find_program('psql') || die $errstr },
);

has psql_args => (
    is => 'lazy',
    isa => Str,
);

method _build_psql_args() {
    return '-U ' . $self->dbowner . ' -d ' . $self->dbname . ' -h '.
        ($self->unix_socket ? $self->socket_dir : '127.0.0.1') .
        ' -p ' . $self->port
        . $self->extra_psql_args;
}

has extra_psql_args => (
    is => 'ro',
    isa => Str,
    default => '',
);

has run_psql_args => (
    is => 'ro',
    isa => Str,
    # Single transaction, skip .psqlrc, be quiet, echo errors, stop on first error
    default => '-1Xqb -v ON_ERROR_STOP=1',
);

has seed_scripts => (
    is => 'ro',
    isa => ArrayRef[Str],
    default => sub { [] },
);

has pid => (
  is => "rw",
  isa => Maybe[Int],
);

has port => (
  is => "rw",
  isa => Maybe[Int],
);

has uid => (
  is => "rw",
  isa => Maybe[Int],
);

# Are we running as root? (Typical when run inside Docker containers)
has is_root => (
  is => "ro",
  isa => Bool,
  default => sub { getuid == 0 }
);

has postmaster => (
  is => "rw",
  isa => Str,
  lazy => 1,
  default => method () {
    $self->_find_program("postgres")
    || $self->_find_program("postmaster")
    || die $errstr
  },
);

has postmaster_args => (
  is => "lazy",
  isa => Str,
);

method _build_postmaster_args() {
    return "-h ".
        ($self->unix_socket ? "''" : "127.0.0.1") .
        " -F " . $self->extra_postmaster_args;
}

has extra_postmaster_args => (
    is      => "ro",
    isa     => Str,
    default => "",
);

has _owner_pid => (
  is => "ro",
  isa => Int,
  default => sub { $$ },
);

method BUILD($) {
    # Ensure we have one or the other ways of starting Postgres:
    try { $self->pg_ctl or $self->postmaster } catch { die $_ };

    if (defined $self->uid and $self->uid == 0) {
        die "uid() must be set to a non-root user id.";
    }

    if (not defined($self->uid) and $self->is_root) {
        my $ent = getpwnam("nobody");
        unless (defined $ent) {
            die "user nobody does not exist, use uid() to specify a non-root user.";
        }
        unless ($ent->uid > 0) {
            die "user nobody has uid 0; confused and exiting. use uid() to specify a non-root user.";
        }
        $self->uid($ent->uid);
    }

    # Ensure base dir is writable by our target uid, if we were running as root
    chown $self->uid, -1, $self->base_dir
        if defined $self->uid;

    if ($self->auto_start) {
        $self->setup
            if $self->auto_start >= 2;
        $self->start;
    }
}

method DEMOLISH($in_global_destruction) {
    local $?;
    if (defined $self->pid && $self->_owner_pid == $$) {
      $self->stop
    }
    return;
}

sub dsn {
    my %args = shift->_default_args(@_);

    return 'DBI:Pg:' . join(';', map { "$_=$args{$_}" } sort keys %args);
}

sub _default_args {
    my ($self, %args) = @_;
    # If we're doing socket-only (i.e., not listening on localhost),
    # then provide the path to the socket
    if ($self->{unix_socket}) {
        $args{host} //= $self->socket_dir;
    } else {
        $args{host} ||= $self->host;
    }

    $args{port} ||= $self->port;
    $args{user} ||= $self->dbowner;
    $args{dbname} ||= $self->dbname;
    return %args;
}

sub uri {
    my $self = shift;
    my %args = $self->_default_args(@_);

    return sprintf('postgresql://%s@%s:%d/%s', @args{qw/user host port dbname/});
}

method start() {
    if (defined $self->pid) {
      warn "Apparently already started on " . $self->pid . "; not restarting.";
      return;
    }

    # If the user specified a port, try only that port:
    if ($self->port) {
        $self->_try_start($self->port);
    }
    else {
        $self->_find_port_and_launch;
    }

    # create "test" database
    $self->_create_test_database($self->dbname);
}

# This whole method was mostly cargo-culted from the earlier test-postgresql;
# It could probably be made more sane.
method _find_port_and_launch() {
  my $tries = 10;
  my $port = $self->base_port;
  # try by incrementing port number
  while (1) {
    my $good = try {
      $self->_try_start($port);
      1;
    }
    catch {
      # warn "Postgres failed to start on port $port\n";
      unless ($tries--) {
        die "Failed to start postgres on port $port: $_";
      }
      undef;
    };
    return if $good;
    $port++;
  }
}

method _try_start($port) {
    my $logfile = File::Spec->catfile($self->base_dir, 'postgres.log');

    if ( $self->pg_ctl ) {
        my @cmd = (
            $self->pg_ctl,
            'start', '-w', '-s', '-D',
            File::Spec->catdir( $self->base_dir, 'data' ),
            '-l', $logfile, '-o',
            join( ' ',
                $self->postmaster_args, '-p',
                $port,                  '-k',
                $self->socket_dir)
        );
        $self->setuid_cmd(\@cmd, 1);

        my $pid_path = File::Spec->catfile( $self->base_dir, 'data', 'postmaster.pid' );

        open( my $pidfh, '<', $pid_path )
          or die "Failed to open $pid_path: $!";

        # Note that the file contains several lines; we only want the PID from the first.
        my $pid = <$pidfh>;
        chomp $pid;
        $self->pid($pid);
        close $pidfh;

        $self->port($port);
    }
    else {
        # old style - open log and fork
        open my $logfh, '>>', $logfile
            or die "failed to create log file: $logfile: $!";
        my $pid = fork;
        die "fork(2) failed:$!"
            unless defined $pid;
        if ($pid == 0) {
            open STDOUT, '>>&', $logfh
                or die "dup(2) failed:$!";
            open STDERR, '>>&', $logfh
                or die "dup(2) failed:$!";
            chdir $self->base_dir
                or die "failed to chdir to:" . $self->base_dir . ":$!";
            if (defined $self->uid) {
                setuid($self->uid) or die "setuid failed: $!";
            }
            my $cmd = join(
                ' ',
                $self->postmaster,
                $self->postmaster_args,
                '-p', $port,
                '-D', File::Spec->catdir($self->base_dir, 'data'),
                '-k', $self->socket_dir,
            );
            exec($cmd);
            die "failed to launch postmaster:$?";
        }
        close $logfh;
        # wait until server becomes ready (or dies)
        for (my $i = 0; $i < 100; $i++) {
            open $logfh, '<', $logfile
            or die "failed to create log file: $logfile: $!";
            my $lines = do { join '', <$logfh> };
            close $logfh;
            last
                if $lines =~ /is ready to accept connections/;
            if (waitpid($pid, WNOHANG) > 0) {
                # failed
                die "Failed to start Postgres: $lines\n";
            }
            sleep 1;
        }
        # PostgreSQL is ready
        $self->pid($pid);
        $self->port($port);
    }
    return;
}

method stop($sig = SIGQUIT) {
    if ( $self->pg_ctl && defined $self->base_dir ) {
        my @cmd = (
            $self->pg_ctl, 'stop', '-s', '-D',
            File::Spec->catdir( $self->base_dir, 'data' ),
            '-m', 'fast'
        );
        $self->setuid_cmd(\@cmd);
    }
    else {
        # old style or $self->base_dir File::Temp obj already DESTROYed
        return unless defined $self->pid;

        kill $sig, $self->pid;
        my $timeout = 10;
        while ($timeout > 0 and waitpid($self->pid, WNOHANG) == 0) {
            $timeout -= sleep(1);
        }

        if ($timeout <= 0) {
            warn "Pg refused to die gracefully; killing it violently.\n";
            kill SIGKILL, $self->pid;
            $timeout = 5;
            while ($timeout > 0 and waitpid($self->pid, WNOHANG) == 0) {
                $timeout -= sleep(1);
            }
            if ($timeout <= 0) {
                warn "Pg really didn't die.. WTF?\n";
            }
        }
    }
    $self->pid(undef);
    return;
}

method _create_test_database($dbname) {
  my $tries = 5;
  my $dbh;
  while ($tries) {
      $tries -= 1;
      $dbh = DBI->connect($self->dsn(dbname => 'template1'), '', '', {
          PrintError => 0,
          RaiseError => 0
      });
      last if $dbh;

      # waiting for database to start up
      if ($DBI::errstr =~ /the database system is starting up/
          || $DBI::errstr =~ /Connection refused/) {
          sleep(1);
          next;
      }
      die $DBI::errstr;
  }

  die "Connection to the database failed even after 5 tries"
      unless ($dbh);

  if ($dbh->selectrow_arrayref(qq{SELECT COUNT(*) FROM pg_database WHERE datname='$dbname'})->[0] == 0) {
      $dbh->do("CREATE DATABASE $dbname")
          or die $dbh->errstr;
  }

    my $seed_scripts = $self->seed_scripts || [];
    
    $self->run_psql_scripts(@$seed_scripts)
        if @$seed_scripts;
    
    return;
}

method setup() {
    # (re)create directory structure
    mkdir $self->base_dir;
    chmod 0755, $self->base_dir
        or die "failed to chmod 0755 dir:" . $self->base_dir . ":$!";
    if ($ENV{USER} && $ENV{USER} eq 'root') {
        chown $self->uid, -1, $self->base_dir
            or die "failed to chown dir:" . $self->base_dir . ":$!";
    }
    my $tmpdir = $self->socket_dir;
    if (mkdir $tmpdir) {
        if ($self->uid) {
            chown $self->uid, -1, $tmpdir
                or die "failed to chown dir:$tmpdir:$!";
        }
    }
    # initdb
    if (! -d File::Spec->catdir($self->base_dir, 'data')) {
        if ( $self->pg_ctl ) {
            my @cmd = (
                $self->pg_ctl,
                'init',
                '-s',
                '-D', File::Spec->catdir($self->base_dir, 'data'),
                '-o',
                $self->initdb_args,
            );
            $self->setuid_cmd(\@cmd);
        }
        else {
            # old style
            pipe my $rfh, my $wfh
                or die "failed to create pipe:$!";
            my $pid = fork;
            die "fork failed:$!"
                unless defined $pid;
            if ($pid == 0) {
                close $rfh;
                open STDOUT, '>&', $wfh
                    or die "dup(2) failed:$!";
                open STDERR, '>&', $wfh
                    or die "dup(2) failed:$!";
                chdir $self->base_dir
                    or die "failed to chdir to:" . $self->base_dir . ":$!";
                if (defined $self->uid) {
                    setuid($self->uid)
                        or die "setuid failed:$!";
                }
                my $cmd = join(
                    ' ',
                    $self->initdb,
                    $self->initdb_args,
                    '-D', File::Spec->catdir($self->base_dir, 'data'),
                );
                exec($cmd);
                die "failed to exec:$cmd:$!";
            }
            close $wfh;
            my $output = '';
            while (my $l = <$rfh>) {
                $output .= $l;
            }
            close $rfh;
            while (waitpid($pid, 0) <= 0) {
            }
            die "*** initdb failed ***\n$output\n"
                if $? != 0;

        }
        
        my $conf_file
            = File::Spec->catfile($self->base_dir, 'data', 'postgresql.conf');
        
        if (my $pg_config = $self->pg_config) {
            open my $fh, '>', $conf_file or die "Can't open $conf_file: $!";
            print $fh $pg_config;
            close $fh;
        }
        else {
            # use postgres hard-coded configuration as some packagers mess
            # around with postgresql.conf.sample too much:
            truncate $conf_file, 0;
        }
    }
}

method _find_program($prog) {
    undef $errstr;
    my $path = which $prog;
    return $path if $path;
    for my $sp (@{$self->search_paths}) {
        return "$sp/bin/$prog" if -x "$sp/bin/$prog";
        return "$sp/$prog" if -x "$sp/$prog";
    }
    $errstr = "could not find $prog, please set appropriate PATH or POSTGRES_HOME";
    return;
}

method setuid_cmd($cmd, $suppress_errors = !1) {
  my $pid = fork;
  if ($pid == 0) {
    chdir $self->base_dir;
    if (defined $self->uid) {
      setuid($self->uid) or die "setuid failed: $!";
    }
    close STDERR if $suppress_errors;
    exec(@$cmd) or die "Failed to exec pg_ctl: $!";
  }
  else {
    waitpid($pid, 0);
  }
}

method run_psql(@psql_args) {
    my $cmd = join ' ', (
        $self->psql,
        
        # Default connection settings
        $self->psql_args,
        
        # Extra connection settings or something else
        $self->extra_psql_args,
        
        # run_psql specific arguments
        $self->run_psql_args,
        
        @psql_args,
    );
    
    # Usually anything less than WARNING is not really helpful
    # in batch mode. Does it make sense to make this configurable?
    local $ENV{PGOPTIONS} = '--client-min-messages=warning';
    
    my $psql_out = qx{$cmd 2>&1};
    
    die "Error executing psql: $psql_out" unless $? == 0;
}

method run_psql_scripts(@script_paths) {
    my $psql_args = join ' ', map {; "-f $_" } @script_paths;
    
    $self->run_psql($psql_args);
}

1;
__END__

=pod

=encoding utf8

=head1 NAME

Test::PostgreSQL - PostgreSQL runner for tests

=head1 SYNOPSIS

  use DBI;
  use Test::PostgreSQL;
  use Test::More;

  # optionally
  # (if not already set at shell):
  #
  # $ENV{POSTGRES_HOME} = '/path/to/my/pgsql/installation';

  my $pgsql = eval { Test::PostgreSQL->new() }
      or plan skip_all => $@;

  plan tests => XXX;

  my $dbh = DBI->connect($pgsql->dsn);

=head1 DESCRIPTION

C<Test::PostgreSQL> automatically setups a PostgreSQL instance in a temporary
directory, and destroys it when the perl script exits.

This module is a fork of Test::postgresql, which was abandoned by its author
several years ago.

=head1 ATTRIBUTES

C<Test::PostgreSQL> object has the following attributes, overridable by passing
corresponding argument to constructor:

=head2 dbname

Database name to use in this C<Test::PostgreSQL> instance. Default is C<test>.

=head2 dbowner

Database owner user name. Default is C<postgres>.

=head2 host

Host name or IP address to use for PostgreSQL instance connections. Default is
C<127.0.0.1>.

=head2 base_dir

Base directory under which the PostgreSQL instance is being created. The
property can be passed as a parameter to the constructor, in which case the
directory will not be removed at exit.

=head2 base_port

Connection port number to start with. If the port is already used we will increment
the value and try again.

Default: C<15432>.

=head2 unix_socket

Whether to only connect via UNIX sockets; if false (the default),
connections can occur via localhost. [This changes the L</dsn>
returned to only give the UNIX socket directory, and avoids any issues with
conflicting TCP ports on localhost.]

=head2 socket_dir

Unix socket directory to use if L</unix_socket> is true. Default is C<$basedir/tmp>.

=head2 pg_ctl

Path to C<pg_ctl> program which is part of the PostgreSQL distribution.

Starting with PostgreSQL version 9.0 C<pg_ctl> can be used to start/stop
postgres without having to use fork/pipe and will be chosen automatically
if L</pg_ctl> is not set but the program is found and the version is recent
enough.

B<NOTE:> do NOT use this with PostgreSQL versions prior to version 9.0.

By default we will try to find C<pg_ctl> in PostgresSQL directory.

=head2 initdb

Path to C<initdb> program which is part of the PostreSQL distribution. Default is
to try and find it in PostgreSQL directory.

=head2 initdb_args

Arguments to pass to C<initdb> program when creating a new PostgreSQL database
cluster for Test::PostgreSQL session.

Defaults to C<-U postgres -A trust>. See L</db_owner>.

=head2 extra_initdb_args

Extra args to be appended to L</initdb_args>. Default is empty.

=head2 pg_config

Configuration to place in C<$basedir/data/postgresql.conf>. Use this to override
PostgreSQL configuration defaults, e.g. to speed up PostgreSQL database init
and seeding one might use something like this:

    my $pgsql = Test::PostgreSQL->new(
        pg_config => q|
        # foo baroo mymse throbbozongo
        fsync = off
        synchronous_commit = off
        full_page_writes = off
        bgwriter_lru_maxpages = 0
        shared_buffers = 512MB
        effective_cache_size = 512MB
        work_mem = 100MB
    |);

=head2 postmaster

Path to C<postmaster> which is part of the PostgreSQL distribution. If not set,
the programs are automatically searched by looking up $PATH and other prefixed
directories. Since C<postmaster> is deprecated in newer PostgreSQL versions
C<postgres> is used in preference to C<postmaster>.

=head2 postmaster_args

Defaults to C<-h 127.0.0.1 -F>.

=head2 extra_postmaster_args

Extra args to be appended to L</postmaster_args>. Default is empty.

=head2 psql

Path to C<psql> client which is part of the PostgreSQL distribution.

C<psql> can be used to run SQL scripts against the temporary database created
by L</new>:

    my $pgsql = Test::PostgreSQL->new();
    my $psql = $pgsql->psql;
    
    my $out = `$psql -f /path/to/script.sql 2>&1`;
    
    die "Error executing script.sql: $out" unless $? == 0;

=head2 psql_args

Command line arguments necessary for C<psql> to connect to the correct PostgreSQL
instance.

Defaults to C<-U postgres -d test -h 127.0.0.1 -p $self-E<gt>port>.

See also L</db_owner>, L</dbname>, L</host>, L</base_port>.

=head2 extra_psql_args

Extra args to be appended to L</psql_args>.

=head2 run_psql_args

Arguments specific for L</run_psql> invocation, used mostly to set up and seed
database schema after PostgreSQL instance is launched and configured.

Default is C<-1Xqb -v ON_ERROR_STOP=1>. This means:

=over 4

=item *

1: Run all SQL statements in passed scripts as single transaction

=item *

X: Skip C<.psqlrc> files

=item *

q: Run quietly, print only notices and errors on stderr (if any)

=item *

b: Echo SQL statements that cause PostgreSQL exceptions

=item *

-v ON_ERROR_STOP=1: Stop processing SQL statements after the first error

=back

=head2 seed_scripts

Arrayref with the list of SQL scripts to run after the database was instanced
and set up. Default is C<[]>.

=head2 auto_start

Integer value that controls whether PostgreSQL server is started and setup
after creating C<Test::PostgreSQL> instance. Possible values:

=over 4

=item C<0>

Do not start PostgreSQL.

=item C<1>

Start PostgreSQL but do not run L</setup>.

=item C<2>

Start PostgreSQL and run L</setup>.

Default is C<2>.

=back

=head1 METHODS

=head2 new

Create and run a PostgreSQL instance. The instance is terminated when the
returned object is being DESTROYed.  If required programs (initdb and
postmaster) were not found, the function returns undef and sets appropriate
message to $Test::PostgreSQL::errstr.

=head2 dsn

Builds and returns dsn by using given parameters (if any).  Default username is
C<postgres>, and dbname is C<test> (an empty database).

=head2 uri

Builds and returns a connection URI using the given parameters (if any). See
L<URI::db> for details about the format.

Default username is C<postgres>, and dbname is C<test> (an empty database).

=head2 pid

Returns process id of PostgreSQL (or undef if not running).

=head2 port

Returns TCP port number on which postmaster is accepting connections (or undef
if not running).

=head2 start

Starts postmaster.

=head2 stop

Stops postmaster.

=head2 setup

Setups the PostgreSQL instance. Note that this method should be invoked I<before>
L</start>.

=head2 run_psql

Execute C<psql> program with the given list of arguments. Usually this would be
something like:

    $pgsql->run_psql('-c', q|'INSERT INTO foo (bar) VALUES (42)'|);

Or:

    $pgsql->run_psql('-f', '/path/to/script.sql');

Note that when using literal SQL statements with C<-c> parameter you will need
to escape them manually like shown above. C<run_psql> will not quote them for you.

The actual command line to execute C<psql> will be concatenated from L</psql_args>,
L</extra_psql_args>, and L</run_psql_args>.

=head2 run_psql_scripts

Given a list of script file paths, invoke L</run_psql> once with C<-f 'script'>
for every path.

=head1 ENVIRONMENT

=head2 POSTGRES_HOME

If your postgres installation is not located in a well known path, or you have
many versions installed and want to run your tests against particular one, set
this environment variable to the desired path. For example:

    export POSTGRES_HOME='/usr/local/pgsql94beta'

This is the same idea and variable name which is used by the installer of
L<DBD::Pg>.

=head1 AUTHOR

Toby Corkindale, Kazuho Oku, Peter Mottram, Alex Tokarev, plus various contributors.

=head1 COPYRIGHT

Current version copyright © 2012-2015 Toby Corkindale.

Previous versions copyright (C) 2009 Cybozu Labs, Inc.

=head1 LICENSE

This module is free software, released under the Perl Artistic License 2.0.
See L<http://www.perlfoundation.org/artistic_license_2_0> for more information.

=cut
