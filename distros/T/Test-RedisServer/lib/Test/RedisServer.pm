package Test::RedisServer;
use strict;
use warnings;
use Mouse;

our $VERSION = '0.21';

use Carp;
use File::Temp;
use POSIX qw(SIGTERM WNOHANG);
use Time::HiRes qw(sleep);
use Errno ();

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

no Mouse;

sub BUILD {
    my ($self) = @_;

    $self->_owner_pid($$);

    my $tmpdir = $self->tmpdir;
    unless (defined $self->conf->{port} or defined $self->conf->{unixsocket}) {
        $self->conf->{unixsocket} = "$tmpdir/redis.sock";
        $self->conf->{port} = '0';
    }

    unless (defined $self->conf->{dir}) {
        $self->conf->{dir} = "$tmpdir/";
    }

    if ($self->conf->{loglevel} and $self->conf->{loglevel} eq 'warning') {
        warn "Test::RedisServer does not support \"loglevel warning\", using \"notice\" instead.\n";
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
    open my $logfh, '>>', "$tmpdir/redis-server.log"
        or croak "failed to create log file: $tmpdir/redis-server.log";

    my $pid = fork;
    croak "fork(2) failed:$!" unless defined $pid;

    if ($pid == 0) {
        open STDOUT, '>&', $logfh or croak "dup(2) failed:$!";
        open STDERR, '>&', $logfh or croak "dup(2) failed:$!";
        $self->exec;
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
            if (open $logfh, '<', "$tmpdir/redis-server.log") {
                $log = do { local $/; <$logfh> };
                close $logfh;
            }

            # confirmed this message is included from v1.3.6 (older version in git repo)
            #   to current HEAD (2012-07-30)
            # The message has changed a bit with Redis 4.x, make regexp a bit more flexible
            if ( $log =~ /[Rr]eady to accept connections/ ) {
                $ready = 1;
                last;
            }
        }

        sleep $elapsed += 0.1;
    }

    unless ($ready) {
        if ($self->pid) {
            $self->pid(undef);
            kill SIGTERM, $pid;
            while (waitpid($pid, WNOHANG) >= 0) {
            }
        }

        croak "*** failed to launch redis-server ***\n" . do {
            my $log = q[];
            if (open $logfh, '<', "$tmpdir/redis-server.log") {
                $log = do { local $/; <$logfh> };
                close $logfh;
            }
            $log;
        };
    }

    $self->pid($pid);
}

sub exec {
    my ($self) = @_;

    my $tmpdir = $self->tmpdir;

    open my $conffh, '>', "$tmpdir/redis.conf" or croak "cannot write conf: $!";
    print $conffh $self->_conf_string;
    close $conffh;

    exec 'redis-server', "$tmpdir/redis.conf"
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
        sleep 0.1;
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

__PACKAGE__->meta->make_immutable;

__END__

=for stopwords redis redis-server mysqld tmpdir destructor

=head1 NAME

Test::RedisServer - redis-server runner for tests.

=head1 SYNOPSIS

    use Redis;
    use Test::RedisServer;
    use Test::More;
    
    my $redis_server;
    eval {
        $redis_server = Test::RedisServer->new;
    } or plan skip_all => 'redis-server is required for this test';
    
    my $redis = Redis->new( $redis_server->connect_info );
    
    is $redis->ping, 'PONG', 'ping pong ok';
    
    done_testing;

=head1 DESCRIPTION

=head1 METHODS

=head2 new(%options)

    my $redis_server = Test::RedisServer->new(%options);

Create a new redis-server instance, and start it by default (use auto_start option to avoid this)

Available options are:

=over

=item * auto_start => 0 | 1 (Default: 1)

Automatically start redis-server instance (by default).
You can disable this feature by C<< auto_start => 0 >>, and start instance manually by C<start> or C<exec> method below.

=item * conf => 'HashRef'

This is a redis.conf key value pair. You can use any key-value pair(s) that redis-server supports.

If you want to use this redis.conf:

    port 9999
    databases 16
    save 900 1

Your conf parameter will be:

    Test::RedisServer->new( conf => {
        port      => 9999,
        databases => 16,
        save      => '900 1',
    });

=item * timeout => 'Int'

Timeout seconds for detecting if redis-server is awake or not. (Default: 3)

=item * tmpdir => 'String'

Temporal directory, where redis config will be stored. By default it is created for you, but if you start Test::RedisServer via exec (e.g. with Test::TCP), you should provide it to be automatically deleted:

=back

=head2 start

Start redis-server instance manually.

=head2 exec

Just exec to redis-server instance. This method is useful to use this module with L<Test::TCP>, L<Proclet> or etc.

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
            my $redis = Test::RedisServer->new(
                auto_start => 0,
                conf       => { port => $port },
                tmpdir     => $tmp_dir,
            );
            $redis->exec;
        },
    );

=head2 stop

Stop redis-server instance.

This method is automatically called from object destructor, DESTROY.

=head2 connect_info

Return connection info for client library to connect this redis-server instance.

This parameter is designed to pass directly to L<Redis> module.

    my $redis_server = Test::RedisServer->new;
    my $redis = Redis->new( $redis_server->connect_info );

=head2 pid

Return redis-server instance's process id, or undef when redis-server is not running.

=head2 wait_exit

Block until redis instance exited. 

=head1 SEE ALSO

L<Test::mysqld> for mysqld.

L<Test::Memcached> for Memcached.

This module steals lots of stuff from above modules.

L<Test::Mock::Redis>, another approach for testing redis application.

=head1 INTERNAL METHODS

=head2 BUILD

=head2 DEMOLISH

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012 KAYAC Inc. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
