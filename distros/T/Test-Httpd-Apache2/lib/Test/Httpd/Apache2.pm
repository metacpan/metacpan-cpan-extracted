package Test::Httpd::Apache2;

use strict;
use warnings;

use 5.008;
use Class::Accessor::Lite;
use Cwd qw(getcwd);
use File::Spec;
use File::Temp qw(tempdir);
use IO::Socket::INET;
use IPC::Open2 qw(open2);
use POSIX qw(WNOHANG);
use Test::TCP qw(empty_port);
use Time::HiRes qw(sleep);

use constant PATH_SEP => $^O eq 'MSWin32' ? ';' : ':';

our $VERSION = '0.09';

our %Defaults = (
    auto_start       => 1,
    pid              => undef,
    listen           => undef,
    required_modules => [],
    server_root      => undef,
    tmpdir           => undef,
    custom_conf      => '',
    search_paths     => [
        qw(/usr/sbin /usr/local/sbin /usr/local/apache/bin)
    ],
    httpd            => 'httpd',
    apxs             => 'apxs',
);

if ($^O eq 'MSWin32') {
    require Win32::Process;
    Win32::Process->import;
    my @cand_paths = map { $_ =~ s!/httpd\.exe$!!; $_ }
        glob('C:/progra~1/apach*/apach*/bin/httpd.exe');
    if (@cand_paths) {
        # use the latest version, if any
        my $path = $cand_paths[-1];
        unshift @{$Defaults{search_paths}}, $path;
        my $dso_path = $path;
        $dso_path =~ s!/bin$!/modules!;
        if (-d $dso_path) {
            # convert to shortname since SPs in path will let the glob fail
            $Defaults{_dso_path} = Win32::GetShortPathName($dso_path);
        }
    }
} else {
    # search for alternative names if necessary
    my @paths = (
        split(PATH_SEP, $ENV{PATH}),
        @{$Defaults{search_paths}},
    );
    if (grep { -x "$_/$Defaults{httpd}" } @paths) {
        # found
    } elsif (grep { -x "$_/apache2" } @paths) {
        # debian / ubuntu have these alternative names
        $Defaults{httpd} = "apache2";
        $Defaults{apxs} = "apxs2";
    }
}

Class::Accessor::Lite->mk_accessors(keys %Defaults);

sub new {
    my $klass = shift;
    my $self = bless {
        %Defaults,
        @_ == 1 ? %{$_[0]} : @_,
    }, $klass;
    if (! $self->server_root) {
        $self->server_root(getcwd);
    }
    $self->listen("127.0.0.1:@{[empty_port()]}")
        unless $self->listen();
    $self->tmpdir(tempdir(CLEANUP => 1));
    $self->start()
        if $self->auto_start();
    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->stop()
        if $self->pid();
}

sub start {
    my $self = shift;
    die "httpd is already running (pid:@{[$self->pid]})"
        if $self->pid;
    # write configuration
    $self->write_conf();
    # spawn httpd
    my $pid = fork;
    if (! defined $pid) {
        die "fork failed:$!";
    } elsif ($pid == 0) {
        # child process
        $ENV{PATH} = join(PATH_SEP, $ENV{PATH}, @{$self->search_paths});
        exec $self->httpd, '-X', '-D', 'FOREGROUND', '-f', $self->conf_file;
        die "failed to exec httpd:$!";
    }
    # wait until the port becomes available
    while (1) {
        my $sock = IO::Socket::INET->new(
            PeerAddr => do {
                $self->listen =~ /:/
                    ? $self->listen : "127.0.0.1:@{[$self->listen]}",
                },
            Proto    => 'tcp',
        ) and last;
        if (waitpid($pid, WNOHANG) == $pid) {
            if (open my $fh, '<', "@{[$self->tmpdir]}/error_log") {
                print STDERR do { local $/; join '', <$fh> };
            }
            die "httpd failed to start, exitted with rc=$?";
        }
        sleep 0.1;
    }
    # need to override pid on mswin32
    if ($^O eq 'MSWin32') {
        my $pidfile = "@{[$self->tmpdir]}/httpd.pid";
        open my $fh, '<', $pidfile
            or die "failed to open $pidfile:$!";
        $pid = <$fh>;
        chomp $pid;
    };
    $self->pid($pid);
}

sub stop {
    my $self = shift;
    die "httpd is not running"
        unless $self->pid;
    if ($^O eq 'MSWin32') {
        Win32::Process::KillProcess($self->pid, 0);
        sleep 1;
    } else {
        kill 'TERM', $self->pid;
        while (waitpid($self->pid, 0) != $self->pid) {
        }
    }
    $self->pid(undef);
}

sub build_conf {
    my $self = shift;
    my $load_modules = do {
        my %static_mods = map { $_ => 1 } @{$self->get_static_modules};
        my %dynamic_mods = %{$self->get_dynamic_modules};
        my @mods_to_load;
        my $httpd_ver = $self->get_httpd_version;
        for my $mod (@{$self->required_modules}) {
            # rewrite authz_host => access for apache/2.0.x
            if ($mod eq 'authz_host' && $self->get_httpd_version =~ m{2\.0\.}) {
                $mod = 'access';
            }
            if ($static_mods{$mod}) {
                # no need to do anything
            } elsif ($dynamic_mods{$mod}) {
                push @mods_to_load, $mod;
            } else {
                die "required module:$mod is not available";
            }
        }
        my $dso_path = $self->get_dso_path;
        $dso_path ? join('', map {
            "LoadModule ${_}_module $dso_path/$dynamic_mods{$_}\n"
        } @mods_to_load) : '';
    };
    my $conf = << "EOT";
ServerRoot @{[$self->server_root]}
PidFile @{[$self->tmpdir]}/httpd.pid
<IfModule !mpm_winnt_module>
  LockFile @{[$self->tmpdir]}/httpd.lock
</IfModule>
@{[ $^O ne 'MSWin32' && $< == 0 ? "User nobody" : ()]}
ErrorLog @{[$self->tmpdir]}/error_log
Listen @{[$self->listen]}
$load_modules

@{[$self->custom_conf]}
EOT
    return $conf;
}

sub write_conf {
    my $self = shift;
    open my $fh, '>', $self->conf_file
        or die "failed to open file:@{[$self->conf_file]}:$!";
    print $fh $self->build_conf;
    close $fh;
}

sub conf_file {
    my $self = shift;
    return "@{[$self->tmpdir]}/httpd.conf";
}

sub get_httpd_version {
    my $self = shift;
    return $self->{_httpd_version} ||= do {
        my $lines = $self->_read_cmd($self->httpd, '-v')
            or die 'dying due to previous error';
        $lines =~ m{Apache\/([0-9]+\.[0-9\.]+)}
            or die q{failed to parse out version number from the output of "httpd -v"};
        $1;
    };
}

sub get_static_modules {
    my $self = shift;
    return $self->{_static_modules} ||= do {
        my $lines = $self->_read_cmd($self->httpd, '-l')
            or die 'dying due to previous error';
        my @mods;
        for my $line (split /\n/, $lines) {
            if ($line =~ /^\s+mod_(.*)\.c/) {
                push @mods, $1;
            }
        }
        \@mods;
    };
}

sub get_dso_path {
    my $self = shift;
    if (! exists $self->{_dso_path}) {
        $self->{_dso_path} = sub {
            return undef
                unless grep { $_ eq 'so' } @{$self->get_static_modules};
            # first obtain the path
            my $path;
            if (my $lines = $self->_read_cmd($self->apxs, '-q', 'LIBEXECDIR')) {
                $path = (split /\n/, $lines)[0];
            } else {
                die "failed to determine the apache modules directory";
            }
            return $path;
        }->();
    }
    return $self->{_dso_path};
}

sub get_dynamic_modules {
    my $self = shift;
    return $self->{_dynamic_modules} ||= do {
        my %mods;
        if (my $dir = $self->get_dso_path()) {
            for my $n (glob "$dir/*.so") {
                $n =~ m{/((?:mod_|lib)([^/]+?)\.so)$}
                    and $mods{$2} = $1;
            }
        }
        \%mods;
    };
}

sub _read_cmd {
    my ($self, @cmd) = @_;
    my ($rfh, $wfh);
    local $ENV{PATH} = join PATH_SEP, $ENV{PATH}, @{$self->search_paths};
    my $pid = open2($rfh, $wfh, @cmd)
        or die "failed to run @{[join ' ', @cmd]}:$!";
    close $wfh;
    my $lines = do { local $/; join '', <$rfh> };
    close $rfh;
    while (waitpid($pid, 0) != $pid) {
    }
    if ($? != 0) {
        warn "$cmd[0] exitted with a non-zero value:$?";
        return;
    }
    return $lines;
}

1;

__END__

=head1 NAME

Test::Httpd::Apache2 - Apache2 runner for tests

=head1 SYNOPSIS

    use Test::Httpd::Apache2;

    my $httpd = Test::Httpd::Apache2->new(
        custom_conf => << 'EOT',
    DocumentRoot "htdocs"
    EOT
    );

    # do whatever you want
    my $url = "http://" . $httpd->listen . "/";
    ...

=head1 DESCRIPTION

The module automatically setups an instance of Apache2 httpd server and destroys it when the perl script exits.

=head1 FUNCTIONS

=head2 new

Creates and runs the httpd server.  Httpd is terminated when the returned object is DESTROYed.  The function accepts following arguments, which can also be read and/or be set through the accessors of the same name.

=head3 listen

The address to which the httpd binds to.  Corresponds to the "Listen" configuration directive of Apache.  The default value is "127.0.0.1:<whatever_port_that_was_unused>".

=head3 server_root

The "ServerRoot" runtime directive.  Set to current working directory if omitted.

=head3 custom_conf

Application-specific configuration passed that will be written to the configuration file of Apache.  Default is none.

=head3 required_modules

An arrayref to specify the required apache modules.  If any module are specified, C<Test::Httpd::Apache2> will check the list of statically-compiled-in and dynamically-aviable modules and load the necessary modules automatically.  Module names should be specified excluding the "mod_" prefix and ".so" suffix.  For example, C<auth_basic_module> should be specified as "auth_basic".  Default is an empty arrayref.

Note: "Authz_host" is automatically translated to "access" if the found httpd is Apache/2.0.x for compatibility.

=head3 search_paths

Paths to look for the httpd server in addition to the PATH environment variable.  The default is: /usr/sbin, /usr/local/sbin, /usr/local/apache/bin.

=head3 pid

the read-only accessor returns pid of the httpd server or undef if it is not running

=head2 start

the instance method starts the httpd server

=head2 stop

the instance method stops the httpd server

=head1 COPYRIGHT

Copyright (C) 2010 Cybozu Labs, Inc.  Written by Kazuho Oku.

=head1 THANKS TO

Tatsuhiko Miyagawa
mattn

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
