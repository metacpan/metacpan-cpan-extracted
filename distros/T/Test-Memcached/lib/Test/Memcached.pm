package Test::Memcached;
use strict;
use warnings;

use Class::Accessor::Lite;
use Cwd;
use File::Temp qw(tempdir);
use IO::Socket::INET;
use Time::HiRes ();

# process does not die when received SIGTERM, on win32.
my $TERMSIG = $^O eq 'MSWin32' ? 'KILL' : 'TERM';

our $VERSION = '0.00004';
our $errstr;
our %OPTIONS_MAP = (
    # perl name               => [ $option_name, $boolean, $default ]
    tcp_port                  => [ 'p',          0,        11211 ],
    udp_port                  => [ 'U',          0,        11211 ],
    unix_socket               => [ 's',          0,        undef ],
    unix_socket_mask          => [ 'a',          0,        undef ],
    bind                      => [ 'l',          0,        undef ],
    # no -d, cause we don't run as daemon
    max_core_limit            => [ 'r',          0,        undef ],
    user                      => [ 'u',          0,        undef ],
    max_memory                => [ 'm',          0,        undef ],
    error_on_exhausted_memory => [ 'M',          1,        undef ],
    max_connections           => [ 'c',          0,        undef ],
    lock_down                 => [ 'k',          1,        undef ],
    verbose                   => [ 'v',          1,        undef ],
    pidfile                   => [ 'P',          0,        undef ],
    chunk_size_factor         => [ 'f',          0,        undef ],
    minimum_space             => [ 'n',          0,        undef ],
    use_large_memory_pages    => [ 'L',          1,        undef ],
    delimiter                 => [ 'D',          0,        undef ],
    threads                   => [ 't',          0,        undef ],
    requests_per_event        => [ 'R',          0,        undef ],
    disable_cas               => [ 'C',          1,        undef ],
    backlog_limit             => [ 'b',          0,        undef ],
    bind_protocol             => [ 'B',          0,        undef ],
    item_size                 => [ 'I',          0,        undef ],
);

our @SEARCH_PATHS = qw(/usr/local /opt/local /usr);

my %DEFAULTS = (
    options    => undef,
    base_dir   => undef,
    memcached  => undef,
    pid        => undef,
    _owner_pid => undef,
    memcached_version => undef,
    memcached_major_version => undef,
    memcached_minor_version => undef,
    memcached_micro_version => undef,
);

Class::Accessor::Lite->mk_accessors(keys %DEFAULTS);

sub new {
    my $class = shift;
    my $self  = bless {
        %DEFAULTS,
        @_ == 1 ? %{ $_[0] } : @_,
        _owner_pid => $$,
    }, $class;

    $self->{options} ||= {};

    if (defined $self->base_dir) {
        $self->base_dir(cwd . '/' . $self->base_dir)
            if $self->base_dir !~ m|^/|;
    } else {
        $self->base_dir(
            tempdir(
                CLEANUP => $ENV{TEST_MEMCACHED_PRESERVE} ? undef : 1,
            ),
        );
    }

    if (! $self->memcached) {
        my $prog = _find_program( 'memcached' )
            or return;
        $self->memcached( $prog );
    }
    # run memcached -h, and find out the version string
    my $cmd = join(' ', $self->memcached, '-h');
    my $output = qx/$cmd/;
    if ($output =~ /^memcached\s+((\d+)\.(\d+)\.(\d+))/) {
        $self->memcached_version($1);
        $self->memcached_major_version($2);
        $self->memcached_minor_version($3);
        $self->memcached_micro_version($4);
    } else {
        warn "Could not parse memcached version";
    }

    return $self;
}

sub start {
    my ($self, %args) = @_;

    return if defined $self->pid;

    if ($> == 0 && ! $self->options->{user}) {
        # if you're root, then you need to do something about it
        die "You may not run memcached as root: Please specify the user via `user` option";
    }

    if (! $self->options->{unix_socket} && 
        ! $self->options->{udp_port} &&
        ! $self->options->{tcp_port}
    ) {
        my $port = $args{tcp_port} || 10000;
        $port = 19000 unless $port =~ /^[0-9]+$/ && $port < 19000;

        my $sock;
        while ( $port++ < 20000 ) {
            $sock = IO::Socket::INET->new(
                Listen    => 5,
                LocalAddr => '127.0.0.1',
                LocalPort => $port,
                Proto     => 'tcp',
                (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
            );
            last if $sock;
        }
        if (! $sock) {
            die "empty port not found";
        }
        $sock->close;
        
        $self->options->{tcp_port} = $port;
    }

    if ($self->options->{tcp_port} && ! $self->options->{bind}) {
        $self->options->{bind} = '127.0.0.1';
    }

    open my $logfh, '>>', $self->base_dir . '/memcached.log'
        or die 'failed to create log file:' . $self->base_dir
            . "/memcached.log:$!";
    my $pid = fork;
    die "fork(2) failed:$!"
        unless defined $pid;
    if ($pid == 0) {
        open STDOUT, '>&', $logfh
            or die "dup(2) failed:$!";
        open STDERR, '>&', $logfh
            or die "dup(2) failed:$!";

        my @cmd = ($self->memcached, $self->_format_options());
        print STDERR "Executing @cmd\n";
        exec( @cmd );
        exit;
    }

    # wait until the port opens
    if (my $port = $self->option('tcp_port')) {
        _wait_port( $port );
    }

    $self->pid($pid);
}

sub _check_port {
    my ($port) = @_;

    my $remote = IO::Socket::INET->new(
        Proto    => 'tcp',
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
    );
    if ($remote) {
        close $remote;
        return 1;
    }
    else {
        return 0;
    }
}

sub _wait_port {
    my $port = shift;

    my $retry = 100;
    while ( $retry-- ) {
        return if _check_port($port);
        Time::HiRes::sleep(0.1);
    }
    die "cannot open port: $port";
}

sub option {
    my ($self, $name) = @_;
    return $self->options->{$name};
}

sub _format_options {
    my $self = shift;
    my $options = $self->options;
    my @options;
    while (my ($name, $value) = each %$options) {
        if ($name eq 'verbose') {
            push @options, '-' . ('v' x $value);
        } else {
            my $data = $OPTIONS_MAP{ $name };
            push @options, 
                ("-$data->[0]", $data->[1] ? !(!$value) : $value)
        }
    }
    return @options;
}

sub stop {
    my ($self, $sig) = @_;
    return
        unless defined $self->pid;
    $sig ||= $TERMSIG;
    kill $sig, $self->pid;

    local $?;
    while (waitpid($self->pid, 0) <= 0) {
    }

    $self->pid(undef);
}

sub DESTROY {
    my $self = shift;
    $self->stop
        if defined $self->pid && $$ == $self->_owner_pid;
}

sub _find_program {
    my ($prog, @subdirs) = @_;
    undef $errstr;
    my $path = _get_path_of($prog);
    return $path
        if $path;
    for my $memcached (_get_path_of('memcached'),
                   map { "$_/bin/memcached" } @SEARCH_PATHS) {
        if (-x $memcached) {
            for my $subdir (@subdirs) {
                $path = $memcached;
                if ($path =~ s|/bin/memcached$|/$subdir/$prog|
                        and -x $path) {
                    return $path;
                }
            }
        }
    }
    $errstr = "could not find $prog, please set appropriate PATH";
    return;
}

sub _get_path_of {
    my $prog = shift;
    my $path = `which $prog 2> /dev/null`;
    chomp $path
        if $path;
    $path = ''
        unless -x $path;
    $path;
}

1;

=head1 NAME

Test::Memcached - Memcached Runner For Tests

=head1 SYNOPSIS

    use Test::Memcached;

    my $memd = Test::Memcached->new(
        options => {
            user => 'memcached-user',
        }
    );

    $memd->start;

    my $port = $memd->option( 'tcp_port' );

    my $client = Cache::Memcached->new({
        servers => [ "127.0.0.1:$port" ]
    });
    $client->get(...);

    $memd->stop; 

=head1 DESCRIPTION

Test::Memcached automatically sets up a memcached instance, and destroys it
when the perl script exists. 

=head1 HACKING Makefile

This is not for the faint of heart, but you can actually hack your CPAN style
Makefile to start your memcached server once per "make test". Do something like this in your Makefile.PL:

    # After you generated your Makefile (that's after your "WriteMakeffile()"
    # or "WriteAll()" statements):

    if (-f 'Makefile') {
        open (my $fh, '<', 'Makefile') or die "Could not open Makefile: $!";
        my $makefile = do { local $/; <$fh> };
        close $fh or die $!;

        $makefile =~ s/"-e" "(test_harness\(\$\(TEST_VERBOSE\), )/"-I\$(INST_LIB)" "-I\$(INST_ARCHLIB)" "-It\/lib" "-MTest::Memcached" "-e" "\\\$\$SIG{INT} = sub { CORE::exit }; my \\\$\$memd; if ( ! \\\$\$ENV{TEST_MEMCACHED_SERVERS}) { \\\$\$memd = Test::Memcached->new(); if (\\\$\$memd) { \\\$\$memd->start(); \\\$\$ENV{TEST_MEMCACHED_SERVERS} = '127.0.0.1:' . \\\$\$memd->option('tcp_port'); } } $1/;

        open (my $fh, '>', 'Makefile') or die "Could not open Makefile: $!";
        print $fh $makefile;
        close $fh or die $!;
    }

Then you can just rely on TEST_MEMCACHED_SERVERS in your .t files. 
When make test ends, then the memcached instance will automatically stop.

It's ugly, but it works

=head1 METHODS

=head2 new

Creates a new instance. you can set the location of memcached by explicitly setting it, or it will attempt to find it.

You can speficy a set of options to pass to memcached. Below table shows the values that you can use, and the option name that will be mapped to:

    tcp_port                  : 'p'
    udp_port                  : 'U'
    unix_socket               : 's'
    unix_socket_mask          : 'a'
    bind                      : 'l'
    max_core_limit            : 'r'
    user                      : 'u'
    max_memory                : 'm'
    error_on_exhausted_memory : 'M'
    max_connections           : 'c'
    lock_down                 : 'k'
    verbose                   : 'v'
    pidfile                   : 'P'
    chunk_size_factor         : 'f'
    minimum_space             : 'n'
    use_large_memory_pages    : 'L'
    delimiter                 : 'D'
    threads                   : 't'
    requests_per_event        : 'R'
    disable_cas               : 'C'
    backlog_limit             : 'b'
    bind_protocol             : 'B'
    item_size                 : 'I'

=head2 option

Gets the current value of the named option

    my $port = $memd->option('tcp_port');

=head2 start

If no unix_socket, udp_port is set, automatically looks for an empty port to listen on, and starts memcached.

=head2 stop

stops memcached. by sending TERM signal

=head2 DESTROY

When the object goes out of scope, stop gets called.

=head1 AUTHORS

Kazuho Oku wrote Test::mysqld, which I shamelessly stole from.

Tokuhiro Matsuno wrote Test::TCP, which I also shamelessly stole from

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
