package Test::SVN::Repo;
# ABSTRACT: Subversion repository fixtures for testing
$Test::SVN::Repo::VERSION = '0.022';
use strict;
use warnings;

use Carp            qw( croak );
use IPC::Run        qw( run start );
use File::Temp      qw( tempdir );
use Path::Class     ();
use POSIX           qw( :errno_h strerror );
use Scalar::Util    qw( weaken );
use URI::file       ();

use base qw( Class::Accessor );

__PACKAGE__->mk_ro_accessors(qw(
        root_path users keep_files verbose start_port end_port retry_count
        server_port server_pid
    ));

#------------------------------------------------------------------------------

my @instances; # these are all weak references, held for cleanup only

sub CLEANUP {
    for my $instance (@instances) {
        next unless $instance;
        $instance->_cleanup_resources() if $instance;
    }
    exit(0);
}

for my $sig (qw( ABRT BUS EMT FPE HUP ILL INT PIPE QUIT SEGV SYS TERM TRAP )) {
    next unless exists $SIG{$sig};
    $SIG{$sig} = \&CLEANUP
}
END { CLEANUP() }

#------------------------------------------------------------------------------

sub repo_path        { shift->root_path->subdir('repo') }
sub is_authenticated { exists $_[0]->{users} }

sub url {
    my ($self) = @_;
    return $self->is_authenticated
            ? 'svn://localhost:' . $self->server_port
            : URI::file->new($self->repo_path)->as_string;
}

#------------------------------------------------------------------------------

sub new {
    my ($class, %args) = @_;
    my $self = {};

    $self->{root_path}   = Path::Class::Dir->new($args{root_path} || tempdir);
    $self->{users}       = $args{users} if exists $args{users};
    $self->{keep_files}  = _defined_or($args{keep_files},
                                defined($args{root_path}));
    $self->{verbose}     = _defined_or($args{verbose}, 0);
    $self->{start_port}  = _defined_or($args{start_port}, 1024);
    $self->{end_port}    = _defined_or($args{end_port}, 65535);
    $self->{retry_count} = _defined_or($args{retry_count}, 100);
    $self->{pid}         = $$;

    bless $self, $class;
    push(@instances, $self);
    weaken($instances[-1]);

    return $self->_init;
}

sub _defined_or {
    my ($arg, $default) = @_;
    return defined $arg ? $arg : $default;
}

sub _init {
    my ($self) = @_;

    $self->_create_repo;
    if ($self->is_authenticated) {
        croak 'users hash must contain at least one username/password pair'
            if scalar(keys %{ $self->users }) == 0;
        $self->_setup_auth;
        $self->_spawn_server;   # this will die if it fails
    }
    return $self;
}

sub DESTROY {
    my ($self) = @_;
    $self->_cleanup_resources();
}

#------------------------------------------------------------------------------

sub _diag { __PACKAGE__->builder->diag(@_) }

sub _setup_auth {
    my ($self) = @_;
    my $conf_path = $self->_server_conf_path;

    _create_file($conf_path->file('svnserve.conf'), <<'END');
[general]
anon-access = read
auth-access = write
realm = Test Repo
password-db = passwd
END

    my %auth = %{ $self->users };
    _create_file($conf_path->file('passwd'),
            "[users]\n",
            map { $_ . ' = ' . $auth{$_} . "\n" } keys %auth);

    my $repo_path = $self->repo_path->stringify;
    _create_file($conf_path->file('authz'),
            "[groups]\n",
            'users = ', join(',', keys %auth), "\n",
            "[$repo_path]\n",
            "users = rw\n");

#    _diag(`find $conf_path -type f -print -exec cat {} \\;`);
}

sub _create_repo {
    my ($self) = @_;

    my @cmd = ('svnadmin', 'create', $self->repo_path);
    my ($in, $out, $err);
    run(\@cmd, \$in, \$out, \$err)
        or croak $err;
    _diag(join(' ', @cmd), $out) if $out && $self->verbose;
    _diag(join(' ', @cmd), $err) if $err && $self->verbose;
}

sub _create_file {
    my $fullpath = shift;
    print {$fullpath->openw} @_;
}

sub _spawn_server {
    my ($self) = @_;

    my $retry_count = $self->retry_count;
    my $base_port = $self->start_port;
    my $port_range = $self->end_port - $self->start_port + 1;
    for (1 .. $retry_count) {
        my $port = _choose_random_port($base_port, $port_range);

        if ($self->_try_spawn_server($port)) {
            $self->{server_port} = $port;
            $self->{server_pid} = $self->_get_server_pid;
            _diag('Server pid ', $self->server_pid,
                  ' started on port ', $self->server_port) if $self->verbose;
            return 1;
        }
        _diag("Port $port busy") if $self->verbose;
    }
    die "Giving up after $retry_count attempts";
}

sub _choose_random_port {
    my ($base_port, $num_ports) = @_;
    return int(rand($num_ports)) + $base_port;
}

sub _try_spawn_server {
    my ($self, $port) = @_;
    # We're checking message text - need to ensure known locale
    local $ENV{LC_ALL} = 'C';
    my @cmd = ( 'svnserve',
                '-d',           # daemon mode
                '--foreground', # don't actually daemonize
                '-r'            => $self->repo_path->stringify,
                '--pid-file'    => $self->_server_pid_file->stringify,
                '--listen-host' => 'localhost',
                '--listen-port' => $port,
              );

    my ($in, $out, $err);
    my $h = start(\@cmd, \$in, \$out, \$err);
    while ($h->pumpable) {
        if (-e $self->_server_pid_file) {
            $self->{server} = $h;
            return 1;
        }
        $h->pump_nb;
    }
    $h->finish;
    my $eaddrinuse = EADDRINUSE();
    return 0 if ($err =~ /E0+$eaddrinuse\D/i);       # newer svn uses code
    return 0 if ($err =~ /Address already in use/i); # older svn uses msg only

    # Final fallback for stubborn locales
    my $eaddrinuse_msg = strerror($eaddrinuse);
    return 0 if ($err =~ /\Q$eaddrinuse_msg\E/i);
    die "$err (EADDRINUSE=\"$eaddrinuse_msg\")\n";
}

sub _get_server_pid {
    my ($self) = @_;

    # We've already established that the server file exists, but not that it
    # has been written. Retry until we get some valid data in there.
    while (1) {
        my $data = _read_file($self->_server_pid_file);
        if ($data =~ /^(\d+)\n$/ms) {
            return $1;
        }
        _sleep(0.1);
    }
}

sub _cleanup_resources {
    my ($self) = @_;

    # Only cleanup if we are the creating process
    return unless $self->{pid} == $$;

    if (my $server = delete $self->{server}) {
        # kill_kill takes forever on Win32
        $server->signal('KILL') if $^O eq 'MSWin32';
        $server->kill_kill(grace => 5);

        # wait until we can manually unlink the pid file - on Win32 it can
        # still be locked and the subsequent rmtree fails
        while (not unlink $self->_server_pid_file) {
            _sleep(0.1);
        }
    }
    $self->root_path->rmtree if !$self->keep_files && $self->root_path;
}

sub _read_file {
    my $fh = $_[0]->openr;
    local $/ = <$fh>;
}

sub _server_conf_path { shift->repo_path->subdir('conf') }

sub _server_pid_file  { shift->_server_conf_path->file('server.pid') }

sub _sleep {
    my ($duration) = @_;                    # opted to avoid another dependency
    select(undef, undef, undef, $duration)  ## no critic ProhibitSleepViaSelect
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::SVN::Repo - Subversion repository fixtures for testing

=head1 VERSION

version 0.022

=head1 SYNOPSIS

    # Create a plain on-disk repo
    my $repo = Test::SVN::Repo->new;

    # Create a repo with password authenticated server
    $repo = Test::SVN::Repo->new(
            users => { joe => 'secret', fred => 'foobar' },
        );

    my $repo_url = $repo->url;

    # do stuff with your new repo
    system("svn co --username joe --password secret $repo_url");

=head1 DESCRIPTION

Create temporary subversion repositories for testing.

If no authentication is required, a simple on-disk repo is created.
An svnserve instance is created when authentication is required.

Repositories and servers are cleaned up when the object is destroyed.

Requires the C<svnadmin> and C<svnserve> external binaries. These are both
included in standard Subversion releases.

=head1 METHODS

=head2 CONSTRUCTOR

Creates a new svn repository, spawning an svnserve server if authentication
is required.

Arguments. All are optional.

=over

=item users

Hashref containing username/password pairs for repository authentication.

If this attribute is specified, there must be at least one user.
Specifying users causes an svnserve instance to be created.

=item root_path

Base path to create the repo. By default, a temporary directory is created,
and deleted on exit.

=item keep_files

Prevent root_path from being deleted in the destructor.

If root_path is provided in the constructor, it will be preserved by default.
If no root_path is provided, and a temporary directory is created, it will
be destroyed by default.

=item verbose

Verbose output. Default off.

=item start_port end_port retry_count

Server mode only.

In order to find a free port for the server, ports are randomly selected from
the range [start_port, end_port] until one succeeds. Gives up after retry_count
failures.

Default values: 1024, 65536, 1000

=back

=head2 READ-ONLY ACCESSORS

=head3 url

Repository URL.

=head3 repo_path

Local path to the SVN repository.

=head3 is_authenticated

True if the the svn repo requires authorisation.
This is enabled by supplying a users hashref to the constructor.

=head3 server_pid

Process id of the svnserve process.

=head3 server_port

Listen port of the svnserve process.

=head1 ACKNOWLEDGEMENTS

Thanks to Strategic Data for sponsoring the development of this module.

=for Pod::Coverage CLEANUP
=for test_synopsis
my ($repo);

=head1 AUTHOR

Stephen Thirlwall <sdt@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Stephen Thirlwall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
