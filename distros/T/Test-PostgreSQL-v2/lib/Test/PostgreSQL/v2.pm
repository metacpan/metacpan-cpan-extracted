package Test::PostgreSQL::v2;

$Test::PostgreSQL::v2::VERSION   = '2.04';
$Test::PostgreSQL::v2::AUTHORITY = 'cpan:MANWAR';

use strict;
use warnings;

use File::Spec;
use Carp qw(croak);
use IO::Socket::INET;
use File::Which qw(which);
use Time::HiRes qw(sleep);
use POSIX qw(:sys_wait_h);
use File::Temp qw(tempdir);

our $errstr = '';

=head1 NAME

Test::PostgreSQL::v2 - A modern, isolated PostgreSQL executable runner for tests

=head1 VERSION

Version 2.04

=head1 SYNOPSIS

    use DBI;
    use Test::PostgreSQL::v2;

    # Start a temporary PostgreSQL instance
    my $pg = Test::PostgreSQL::v2->new()
        or die $Test::PostgreSQL::v2::errstr;

    # Connect directly with DBI
    my $dbh = DBI->connect($pg->dsn, $pg->user, '')
        or die $DBI::errstr;

    $dbh->do("CREATE TABLE foo (id SERIAL PRIMARY KEY, name TEXT)");
    $dbh->disconnect;

    # The instance is automatically stopped and cleaned up when $pg goes out of scope

B<Usage with Test::DBIx::Class>

The recommended way to use this module with L<Test::DBIx::Class> is via the
bundled C<Testpostgresqlv2> trait, which handles all lifecycle and
compile-time scoping automatically:

    use Test::More;
    use Test::DBIx::Class {
        schema_class => 'MyApp::Schema',
        traits       => ['Testpostgresqlv2'],
        deploy_db    => 1,
    }, qw/:resultsets/;

    ok ResultSet('User')->create({ name => 'John' }), 'Created user';

    done_testing;

If you need manual control over the connection instead, you must start the
instance at compile time to satisfy C<use Test::DBIx::Class>'s import phase:

    use Test::More;

    our $pg;
    BEGIN {
        require Test::PostgreSQL::v2;
        $pg = Test::PostgreSQL::v2->new()
            or die $Test::PostgreSQL::v2::errstr;
    }

    use Test::DBIx::Class {
        schema_class => 'MyApp::Schema',
        connect_info => [ $pg->dsn, $pg->user, '' ],
        deploy_db    => 1,
    }, qw/:resultsets/;

    done_testing;

=head1 DESCRIPTION

B<Test::PostgreSQL::v2> is a "clean sheet" rewrite designed to replace the
aging L<Test::PostgreSQL>. It addresses modern Linux environment constraints
(like Ubuntu 24.04+) by isolating sockets in temporary directories and
correctly discovering modern Postgres binaries.

=head1 CONSTRUCTOR

B<new(%args)>

The C<new> method initialises and starts a temporary PostgreSQL instance. It
performs the following steps:

=over 4

=item * Binary Discovery: Searches for C<initdb> and C<postgres>
(or C<postmaster>). It respects the C<POSTGRES_HOME> environment variable
if set, falling back to the system C<PATH>.

=item * Workspace Isolation: Creates a unique C<tempdir> for the data
cluster and unix sockets (via the C<-k> flag). This avoids permission
conflicts with system-wide PostgreSQL socket directories like
C</var/run/postgresql>.

=item * Automatic Port Selection: If no port is provided, it dynamically
searches for an available port on the specified host.

=item * Cluster Initialisation: Runs C<initdb> with C<trust>
authentication and C<--nosync> for maximum test performance.

=item * Daemonisation & Readiness: Forks the server process and polls
the host/port until the instance is ready to accept connections. If the
server fails to start, it slurps the C<pg.log> into a C<croak> message for
immediate debugging.

=back

B<Arguments:>

=over 4

=item * C<host> (Default: 127.0.0.1)

The bind address for the server.

=item * C<port> (Default: Auto-selected)

The TCP port to listen on.

=item * C<user> (Default: 'postgres')

The superuser name to be created during C<initdb>.

=back

B<Returns:> A C<Test::PostgreSQL::v2> object.

=cut

sub new {
    my ($class, %args) = @_;

    $errstr = '';
    my $self = eval { $class->_new(%args) };
    if ($@) {
        $errstr = $@;
        $errstr =~ s/ at \S+ line \d+\.?\s*$//;
        return undef;
    }

    return $self;
}

sub _new {
    my ($class, %args) = @_;

    # 1. Root Check
    if ($> == 0 && !defined $args{user}) {
        croak "PostgreSQL cannot run as root. Please run tests as a non-privileged user.";
    }

    # 2. Binary Discovery with better error reporting
    my $base_path = $ENV{POSTGRES_HOME}
                    ? File::Spec->catdir($ENV{POSTGRES_HOME}, 'bin')
                    : undef;

    my $initdb = which('initdb', $base_path) || which('initdb');
    unless ($initdb) {
        my @searched;
        push @searched, $base_path                    if $base_path;
        push @searched, split(/:/, $ENV{PATH} // '');
        croak sprintf(
            "Cannot find 'initdb' binary. PostgreSQL does not appear to be "
          . "installed or is not in your PATH.\n"
          . "Searched in:\n%s\n"
          . "Hint: Install PostgreSQL (e.g. 'sudo apt install postgresql') "
          . "or set POSTGRES_HOME to your PostgreSQL installation directory "
          . "(e.g. POSTGRES_HOME=/usr/lib/postgresql/16).",
            join('', map { "  - $_\n" } @searched)
        );
    }

    my $postgres =    which('postgres', $base_path)
                   || which('postgres')
                   || which('postmaster', $base_path);
    unless ($postgres) {
        croak "postgres binary not found. Ensure PostgreSQL is installed.";
    }

    # 3. Workspace Setup
    my $base_tmp = tempdir(CLEANUP => 1);
    my $socket_dir = $base_tmp;
    my $extra_cleanup;

    # Socket path length protection (Unix limit is ~100 chars)
    if (length($socket_dir) > 85) {
        $socket_dir = "/tmp/pg_v2_$$";
        mkdir $socket_dir, 0700 or croak "Failed to create socket dir $socket_dir: $!";
        $extra_cleanup = $socket_dir;
    }

    my $self = bless {
        tmpdir             => $base_tmp,
        socket_dir         => $socket_dir,
        extra_cleanup_dir  => $extra_cleanup, # For DESTROY
        datadir            => File::Spec->catdir($base_tmp, 'data'),
        host               => $args{host} || '127.0.0.1',
        user               => $args{user} || 'postgres',
        owner              => $$,
        log                => File::Spec->catfile($base_tmp, 'pg.log'),
    }, $class;

    $self->{port} = $args{port} || _find_free_port($self->{host});

    # 4. Initialise Cluster
    system($initdb, '-D', $self->{datadir}, '--auth=trust', '--nosync', '-U', $self->{user}) == 0
        or croak "initdb failed with exit code " . ($? >> 8);

    # 5. Launch Process
    my $pid = fork();
    defined $pid or croak "fork failed: $!";

    if ($pid == 0) {
        open STDOUT, '>', $self->{log} or exit 1;
        open STDERR, '>&STDOUT';
        exec($postgres,
            '-D', $self->{datadir},
            '-p', $self->{port},
            '-h', $self->{host},
            '-k', $self->{socket_dir},
            '-F',
        );
        exit 1;
    }

    $self->{pid} = $pid;

    # 6. Readiness Check
    my $connected = 0;
    for (1..50) {
        if (waitpid($pid, WNOHANG) != 0) {
            my $log_content = _slurp($self->{log});
            croak "Postgres died on startup. Logs:\n$log_content";
        }

        if (IO::Socket::INET->new(
                PeerAddr => $self->{host},
                PeerPort => $self->{port},
                Timeout  => 0.5)) {
            $connected = 1; last;
        }

        sleep 0.1;
    }

    croak "Timed out waiting for Postgres to start on port $self->{port}"
        unless $connected;

    return $self;
}

=head1 METHODS

=head2 errstr()

Returns last saved error.

=cut

sub errstr  { return $errstr }

=head2 dsn()

Returns a string formatted for L<DBI> connection.
Example: C<dbi:Pg:dbname=postgres;host=127.0.0.1;port=54321>

=cut

sub dsn {
    my $self = shift;

    croak "dsn() must be called as an object method"
        unless ref $self;

    return sprintf('dbi:Pg:dbname=postgres;host=%s;port=%d',
        $self->{host}, $self->{port});
}

=head2 user()

Returns the username configured for the database (defaults to 'postgres').

=head2 host()

Returns the host/IP the database is listening on.

=head2 port()

Returns the port the database is listening on.

=head2 pid()

Returns the process ID of the backgrounded PostgreSQL server.

=cut

sub user { my $self = shift; ref $self ? $self->{user} : croak "user() is an object method" }
sub host { my $self = shift; ref $self ? $self->{host} : croak "host() is an object method" }
sub port { my $self = shift; ref $self ? $self->{port} : croak "port() is an object method" }
sub pid  { my $self = shift; ref $self ? $self->{pid}  : croak "pid() is an object method"  }

sub _find_free_port {
    my $host = shift;

    # Note: there is an inherent TOCTOU race between releasing the port
    # here and PostgreSQL binding it. This is acceptable for test use.
    my $s    = IO::Socket::INET->new(Listen => 1, LocalAddr => $host)
        or return 54321;
    my $port = $s->sockport;
    close $s;
    return $port;
}

sub _slurp {
    my $file = shift;
    return "No log found" unless -f $file;
    open my $fh, '<', $file or return "Cannot open log";
    local $/; return <$fh>;
}

sub DESTROY {
    my $self = shift;

    local $@; # protect caller's $@

    # 1. Guard: Only the process that created the object should kill the DB
    return unless $self->{pid} && $self->{pid} > 0 && $self->{owner} == $$;

    # 2. Shutdown Sequence
    # We use SIGTERM first (graceful).
    # Note: Legacy used SIGQUIT,
    # but SIGTERM is the modern standard for 'pg_ctl stop'.
    kill 'TERM', $self->{pid};

    my $wait = 50; # 5 seconds (50 * 0.1)
    while ($wait > 0 && waitpid($self->{pid}, WNOHANG) <= 0) {
        sleep 0.1;
        $wait--;
    }

    # 3. Force Kill if necessary
    if (kill(0, $self->{pid})) {
        kill 'KILL', $self->{pid};
        waitpid($self->{pid}, 0); # Reap the zombie
    }

    # 4. Manual Cleanup for Long Socket Paths
    # If we created a fallback socket dir in /tmp (outside the tempdir)
    if ($self->{extra_cleanup_dir} && -d $self->{extra_cleanup_dir}) {
        # Only remove if it's empty or contains only the socket file
        # safer to use File::Path::remove_tree if you have it
        require File::Path;
        File::Path::remove_tree($self->{extra_cleanup_dir});
    }
}

=head1 CAVEATS

=head2 Process Management

The PostgreSQL server process is tied to the lifecycle of the Perl object.
When the object goes out of scope, the C<DESTROY> method attempts a
C<SIGTERM>, waits up to 5 seconds for a clean shutdown, and falls back to
C<SIGKILL> if the process remains stubborn.

If the Perl interpreter crashes via C<SIGKILL> or an abrupt C<BAIL_OUT>,
the background PostgreSQL process may remain running (orphaned). Always
ensure your test runner handles cleanup or use a process supervisor in CI
environments.

=head2 Data Persistence

This module uses L<File::Temp> with C<CLEANUP =E<gt> 1>. All database data,
configuration files, and logs are B<permanently deleted> when the object is
destroyed. This is intentional for unit testing but makes the module
unsuitable for persistent local development databases.

=head1 ENVIRONMENT VARIABLES

=head2 POSTGRES_HOME

If set, the module will look for C<initdb> and C<postgres> binaries in
C<$POSTGRES_HOME/bin>. This is useful for testing against specific versions
of PostgreSQL installed in non-standard locations (e.g., C</usr/lib/postgresql/16/>).

=head1 SEE ALSO

=over 4

=item * L<Test::PostgreSQL>

The original inspiration for this module. While it served the community for years,
it may struggle with modern Linux socket permissions and binary naming conventions
addressed here in C<Test::PostgreSQL::v2>.

=item * L<Test::DBIx::Class>

The gold standard for ORM-based testing. C<Test::PostgreSQL::v2> is designed to
be a reliable backend engine for C<Test::DBIx::Class> configurations.

=item * L<DateTime::Format::Pg>

Essential for handling PostgreSQL-specific date and time formats. Verified
compatible with this module's data handling in integration tests.

=item * L<DBI> and L<DBD::Pg>

The underlying database interface and driver required to communicate with
the instances spawned by this module.

=back

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Test-PostgreSQL-v2>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/Test-PostgreSQL-v2/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::PostgreSQL::v2

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/Test-PostgreSQL-v2/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-PostgreSQL-v2>

=item * Search MetaCPAN

L<https://metacpan.org/dist/Test-PostgreSQL-v2/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:
L<http://www.perlfoundation.org/artistic_license_2_0>
Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.
If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.
This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.
This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.
Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Test::PostgreSQL::v2
