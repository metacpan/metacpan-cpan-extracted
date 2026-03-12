package Test::ValkeyServer;
use strict;
use warnings;
use Mouse;

our $VERSION = '0.01';

use Carp;
use File::Temp;
use POSIX qw(SIGTERM WNOHANG);
use Time::HiRes qw(sleep);
use Errno ();
use Redis;

has auto_start => (
    is      => 'rw',
    default => 1,
);

has [qw/pid _owner_pid/] => (
    is => 'rw',
);

has conf => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has timeout => (
    is      => 'rw',
    default => 3,
);

has tmpdir  => (
    is         => 'rw',
    lazy_build => 1,
);

has _redis => (
    is  => 'rw',
    isa => 'Redis',
);

has cluster => (
    is      => 'ro',
    default => 0,
);

no Mouse;

sub BUILD {
    my ($self) = @_;

    $self->_owner_pid($$);

    my $tmpdir = $self->tmpdir;
    if ($self->cluster) {
        croak "cluster mode requires a port to be specified in conf"
            unless defined $self->conf->{port} && $self->conf->{port} > 0;
        croak "cluster mode does not support unixsocket"
            if defined $self->conf->{unixsocket};
        $self->conf->{bind} = '127.0.0.1'
            unless defined $self->conf->{bind};
        $self->conf->{'cluster-announce-ip'} = $self->conf->{bind}
            unless defined $self->conf->{'cluster-announce-ip'};
        $self->conf->{'cluster-config-file'} = "$tmpdir/nodes.conf";
        $self->conf->{'cluster-enabled'} = 'yes';
    }
    elsif (!defined $self->conf->{port} && !defined $self->conf->{unixsocket}) {
        $self->conf->{unixsocket} = "$tmpdir/valkey.sock";
        $self->conf->{port} = '0';
    }

    unless (defined $self->conf->{dir}) {
        $self->conf->{dir} = "$tmpdir/";
    }

    if ($self->conf->{loglevel} and $self->conf->{loglevel} eq 'warning') {
        warn "Test::ValkeyServer does not support \"loglevel warning\", using \"notice\" instead.\n";
        $self->conf->{loglevel} = 'notice';
    }

    if ($self->auto_start) {
        $self->start;
    }
}

sub DEMOLISH {
    my ($self) = @_;
    $self->stop if defined $self->pid && $$ == $self->_owner_pid;
}

sub start {
    my ($self) = @_;

    return if defined $self->pid;

    my $tmpdir = $self->tmpdir;
    open my $logfh, '>>', "$tmpdir/valkey-server.log"
        or croak "failed to create log file: $tmpdir/valkey-server.log";

    my $pid = fork;
    croak "fork(2) failed:$!" unless defined $pid;

    if ($pid == 0) {
        open STDOUT, '>&', $logfh or croak "dup(2) failed:$!";
        open STDERR, '>&', $logfh or croak "dup(2) failed:$!";
        $self->_exec;
    }
    close $logfh;

    my $ready;
    my $elapsed = 0;
    $self->pid($pid);

    while ($elapsed <= $self->timeout) {
        if (waitpid($pid, WNOHANG) > 0) {
            $self->pid(undef);
            last;
        }
        else {
            my $log = q[];
            if (open $logfh, '<', "$tmpdir/valkey-server.log") {
                $log = do { local $/; <$logfh> };
                close $logfh;
            }

            if ( $log =~ /Ready to accept connections/ ) {
                $ready = 1;
                last;
            }
        }

        sleep($elapsed += 0.1);
    }

    unless ($ready) {
        if ($self->pid) {
            $self->pid(undef);
            kill SIGTERM, $pid;
            while (waitpid($pid, WNOHANG) >= 0) {
            }
        }

        croak "*** failed to launch valkey-server ***\n" . do {
            my $log = q[];
            if (open $logfh, '<', "$tmpdir/valkey-server.log") {
                $log = do { local $/; <$logfh> };
                close $logfh;
            }
            $log;
        };
    }

    if ($self->cluster) {
        $self->_create_cluster($pid);
    }

    # This is sometimes needed to send commands to ValkeyServer during the stop process.
    # Generally, we would like to generate it lazily and not have it as a property
    # of the object. However, if you try to create the object at the stop,
    # the object generation may fail, such as missing the socket file. Therefore,
    # we will make the object and store it as property here.
    $self->_redis( Redis->new($self->connect_info) );

    $self->pid($pid);
}

sub exec {
    my ($self) = @_;

    croak "cluster mode is not supported with exec(); use start() instead"
        if $self->cluster;

    $self->_exec;
}

sub _exec {
    my ($self) = @_;

    my $tmpdir = $self->tmpdir;

    open my $conffh, '>', "$tmpdir/valkey.conf" or croak "cannot write conf: $!";
    print $conffh $self->_conf_string;
    close $conffh;

    CORE::exec 'valkey-server', "$tmpdir/valkey.conf"
        or do {
            if ($! == Errno::ENOENT) {
                print STDERR "exec failed: no such file or directory\n";
            }
            else {
                print STDERR "exec failed: unexpected error: $!\n";
            }
            exit($?);
        };
}

sub stop {
    my ($self, $sig) = @_;

    local $?; # waitpid may change this value :/
    return unless defined $self->pid;

    # If the tmpdir has disappeared, clear the save config to prevent saving
    # in the server terminating process. The newer Valkey will save on stop
    # for robustness, but will keep blocking if the directory is missing.
    #
    # It is unlikely that tmpdir will disappear first, but if both the ValkeyServer
    # object and the tmpdir are defined globally, it may happen because the order
    # in which they are DEMOLISHed is uncertain.
    if (! -f $self->tmpdir) {
        $self->_redis->config_set('appendonly', 'no');
        $self->_redis->config_set('save', '');
    }

    $sig ||= SIGTERM;

    kill $sig, $self->pid;
    while (waitpid($self->pid, WNOHANG) >= 0) {
    }

    $self->pid(undef);
}

sub wait_exit {
    my ($self) = @_;

    local $?;

    my $kid;
    my $pid = $self->pid;
    do {
        $kid = waitpid($pid, WNOHANG);
        sleep(0.1);
    } while $kid >= 0;

    $self->pid(undef);
}

sub connect_info {
    my ($self) = @_;

    my $host = $self->conf->{bind} || '0.0.0.0';
    my $port = $self->conf->{port};
    my $sock = $self->conf->{unixsocket};

    if ($port && $port > 0) {
        return (server => $host . ':' . $port);
    }
    else {
        return (sock => $sock);
    }
}

sub _build_tmpdir {
    File::Temp->newdir( CLEANUP => 1 );
}

sub _conf_string {
    my ($self) = @_;

    my $conf = q[];
    my %conf = %{ $self->conf };
    while (my ($k, $v) = each %conf) {
        next unless defined $v;
        $conf .= "$k $v\n";
    }

    $conf;
}

sub _create_cluster {
    my ($self, $pid) = @_;

    my $host = $self->conf->{bind};
    my $port = $self->conf->{port};

    my $create = $self->_run_valkey_cli(
        '--cluster', 'create', "$host:$port",
        '--cluster-replicas', '0', '--cluster-yes',
    );

    my $elapsed = 0;
    my $cluster_ok;
    my $info = { output => q[], timed_out => 0 };
    while ($elapsed <= $self->timeout) {
        $info = $self->_run_valkey_cli('-h', $host, '-p', $port, 'cluster', 'info');
        last if $info->{timed_out};

        if ($info->{output} =~ /cluster_state:ok/) {
            $cluster_ok = 1;
            last;
        }
        sleep(0.1);
        $elapsed += 0.1;
    }

    unless ($cluster_ok) {
        kill SIGTERM, $pid;
        while (waitpid($pid, WNOHANG) >= 0) {
            sleep(0.1);
        }
        $self->pid(undef);
        my @message = ('*** failed to create valkey cluster ***');
        push @message, 'valkey-cli --cluster create timed out'
            if $create->{timed_out};
        push @message, 'valkey-cli cluster info timed out'
            if $info->{timed_out};
        push @message, "valkey-cli output: $create->{output}"
            if length $create->{output};
        push @message, "last valkey-cli cluster info output: $info->{output}"
            if length $info->{output};
        croak join("\n", @message) . "\n";
    }
}

sub _run_valkey_cli {
    my ($self, @args) = @_;

    my $tmpdir = $self->tmpdir;
    my $logfile = "$tmpdir/valkey-cli.log";

    open my $logfh, '>>', $logfile
        or croak "failed to create log file: $logfile";
    seek $logfh, 0, 2 or croak "seek(2) failed: $!";
    my $offset = tell $logfh;
    croak "tell(2) failed: $!" unless defined $offset;

    my $child_pid = fork;
    croak "fork(2) failed: $!" unless defined $child_pid;

    if ($child_pid == 0) {
        open STDOUT, '>&', $logfh or croak "dup(2) failed: $!";
        open STDERR, '>&', $logfh or croak "dup(2) failed: $!";
        CORE::exec 'valkey-cli', @args
            or do { print STDERR "exec valkey-cli failed: $!\n"; exit 1; };
    }

    close $logfh;

    my $elapsed = 0;
    while ($elapsed <= $self->timeout) {
        if (waitpid($child_pid, WNOHANG) > 0) {
            return {
                output    => $self->_read_log_since($logfile, $offset),
                timed_out => 0,
            };
        }

        sleep(0.1);
        $elapsed += 0.1;
    }

    kill SIGTERM, $child_pid;
    while (waitpid($child_pid, WNOHANG) == 0) {
        sleep(0.1);
    }

    return {
        output    => $self->_read_log_since($logfile, $offset),
        timed_out => 1,
    };
}

sub _read_log_since {
    my ($self, $logfile, $offset) = @_;

    my $output = q[];
    if (open my $logfh, '<', $logfile) {
        seek $logfh, $offset, 0 or croak "seek(2) failed: $!";
        $output = do { local $/; <$logfh> };
        close $logfh;
    }

    return $output;
}

__PACKAGE__->meta->make_immutable;

__END__

=for stopwords valkey valkey-server mysqld tmpdir destructor Valkey plainbanana

=head1 NAME

Test::ValkeyServer - valkey-server runner for tests.

=head1 SYNOPSIS

    use Redis;
    use Test::ValkeyServer;
    use Test::More;

    my $valkey_server;
    eval {
        $valkey_server = Test::ValkeyServer->new;
    } or plan skip_all => 'valkey-server is required for this test';

    my $redis = Redis->new( $valkey_server->connect_info );

    is $redis->ping, 'PONG', 'ping pong ok';

    done_testing;

=head1 DESCRIPTION

Test::ValkeyServer is a fork of L<Test::RedisServer> adapted for
L<Valkey|https://valkey.io/>, the open source high-performance key/value store.
It automatically spawns a temporary valkey-server instance for use in your test
suite and cleans it up when done.

This module was forked from L<Test::RedisServer> version 0.24 by Daisuke Murase
and adapted for Valkey compatibility.

=head1 METHODS

=head2 new(%options)

    my $valkey_server = Test::ValkeyServer->new(%options);

Create a new valkey-server instance, and start it by default (use auto_start option to avoid this)

Available options are:

=over

=item * auto_start => 0 | 1 (Default: 1)

Automatically start valkey-server instance (by default).
You can disable this feature by C<< auto_start => 0 >>, and start instance manually by C<start> or C<exec> method below.

=item * conf => 'HashRef'

This is a valkey.conf key value pair. You can use any key-value pair(s) that valkey-server supports.

If you want to use this valkey.conf:

    port 9999
    databases 16
    save 900 1

Your conf parameter will be:

    Test::ValkeyServer->new( conf => {
        port      => 9999,
        databases => 16,
        save      => '900 1',
    });

=item * cluster => 0 | 1 (Default: 0)

Enable single-node cluster mode. Unix sockets are not supported in this mode
(specifying C<unixsocket> in C<conf> throws an error), and
C<valkey-cli --cluster create> is called after the server starts. A TCP port
must be specified via C<conf>. Requires C<valkey-cli> in PATH and Valkey 8.1+.

    use Test::TCP qw(empty_port);
    my $server = Test::ValkeyServer->new(
        cluster => 1,
        conf    => { port => empty_port(), bind => '127.0.0.1' },
    );
    my $redis = Redis->new($server->connect_info);
    # Now you can use cluster commands

Note: cluster mode is not compatible with C<exec()>; use C<start()> instead.

=item * timeout => 'Int'

Timeout seconds for detecting if valkey-server is awake or not. (Default: 3)
In cluster mode, this timeout applies to both server startup and cluster creation separately.

=item * tmpdir => 'String'

Temporal directory, where valkey config will be stored. By default it is created for you, but if you start Test::ValkeyServer via exec (e.g. with Test::TCP), you should provide it to be automatically deleted:

=back

=head2 start

Start valkey-server instance manually.

=head2 exec

Just exec to valkey-server instance. This method is useful to use this module with L<Test::TCP>, L<Proclet> or etc.

    use File::Temp;
    use Test::TCP;
    my $tmp_dir = File::Temp->newdir( CLEANUP => 1 );

    test_tcp(
        client => sub {
            my ($port, $server_pid) = @_;
            ...
        },
        server => sub {
            my ($port) = @_;
            my $valkey = Test::ValkeyServer->new(
                auto_start => 0,
                conf       => { port => $port },
                tmpdir     => $tmp_dir,
            );
            $valkey->exec;
        },
    );

=head2 stop

Stop valkey-server instance.

This method is automatically called from object destructor, DEMOLISH.

=head2 connect_info

Return connection info for client library to connect this valkey-server instance.

This parameter is designed to pass directly to L<Redis> module.

    my $valkey_server = Test::ValkeyServer->new;
    my $redis = Redis->new( $valkey_server->connect_info );

=head2 pid

Return valkey-server instance's process id, or undef when valkey-server is not running.

=head2 wait_exit

Block until valkey instance exited.

=head1 SEE ALSO

L<Test::mysqld> for mysqld.

L<Test::Memcached> for Memcached.

This module steals lots of stuff from above modules.

L<Test::RedisServer>, the original module this was forked from.

=head1 INTERNAL METHODS

=head2 BUILD

=head2 DEMOLISH

=head1 AUTHOR

Daisuke Murase <typester@cpan.org> (original L<Test::RedisServer> author)

Current maintainer: plainbanana

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012 KAYAC Inc. All rights reserved.

Forked as Test::ValkeyServer in 2025 by plainbanana.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
