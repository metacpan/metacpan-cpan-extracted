package Test::SSH::Backend::Base;

use strict;
use warnings;
use File::Spec;
use File::Glob qw(:glob);
use Carp;
use POSIX;
use FileHandle;

use Test::SSH::Patch::URI::ssh;

my @private = qw(timeout logger test_commands path user_keys private_dir requested_uri run_server c_params);
my @public  = qw(host port auth_method password user key_path);
for my $accessor (@public) {
    no strict 'refs';
    *$accessor = sub { shift->{$accessor} }
}

sub new {
    my ($class, %opts) = @_;

    my $sshd = {};
    bless $sshd, $class;
    $sshd->{$_} = delete($opts{$_}) for (@public, @private);

    if (defined (my $uri_txt =  $sshd->{requested_uri})) {
        my $uri = URI->new($uri_txt);
        $uri->scheme('ssh') unless defined $uri->scheme;
        if ($uri->scheme ne 'ssh') {
            $sshd->_error("not a ssh URI '$uri'");
            return;
        }

        for my $k (qw(password host port user c_params)) {
            my $v = $uri->$k;
            $sshd->{$k} = $v if defined $v;
        }

        for (@{$opts{c_params} || []}) {
            if (/^key_path=(.*)$/) {
                $sshd->{user_keys} = [$1];
            }
        }
    }

    $sshd->_write_fh('log'); # opens log file
    $sshd->_log("starting backend of class '$class'");

    return $sshd;
}

sub _log {
    local ($@, $!, $?, $^E);
    my $sshd = shift;
    my $line = join(': ', @_);
    if (defined (my $fhs = $sshd->{log_fhs})) {
        print {$fhs->[1]} "# Test::SSH > $line\n"
    }
    eval { $sshd->{logger}->($line) }
}

sub _error { shift->_log(error => @_) }

my $dev_null = File::Spec->devnull;
sub _dev_null { $dev_null }

my $up_dir = File::Spec->updir;
my $cur_dir = File::Spec->curdir;

sub _is_server_running { defined(shift->server_version) }

sub _run_remote_cmd {
    my ($sshd, @cmd) = @_;

    if ($sshd->_is_server_running) {
        my $auth_method = $sshd->{auth_method};
        my (@auth_args, @auth_opts);
        if ($auth_method eq 'publickey') {
            @auth_args = ( -i => $sshd->{key_path},
                           -o => 'PreferredAuthentications=publickey',
                           -o => 'BatchMode=yes' );
        }
        elsif ($auth_method eq 'password') {
            @auth_args = ( -o => 'PreferredAuthentications=password,keyboard-interactive',
                           -o => 'BatchMode=no' );
            @auth_opts = ( password => $sshd->{password} );
        }
        else {
            $sshd->_error("unsupported authentication method $auth_method");
            return;
        }

        return $sshd->_run_cmd( { search_binary => 1, @auth_opts },
                                'ssh',
                                '-T',
                                -F => $dev_null,
                                -p => $sshd->{port},
                                -l => $sshd->{user},
                                -o => 'StrictHostKeyChecking=no',
                                -o => "UserKnownHostsFile=$dev_null",
                                @auth_args,
                                '--',
                                $sshd->{host},
                                @cmd );
    }
}

sub _find_binaries {
    my ($sshd, @cmds) = @_;
    $sshd->_log("resolving command(s) @cmds");
    my @path = @{$sshd->{path}};

    if (defined $sshd->{_ssh_executable}) {
        my $dir = File::Spec->join((File::Spec->splitpath($sshd->{_ssh_executable}))[0,1]);
        unshift @path, $dir, File::Spec->join($dir, $up_dir, 'sbin');
    }

    my @bins;
    $sshd->_log("search path is " . join(":", @path));
    for my $path (@path) {
        for my $cmd (@cmds) {
            my $fn = File::Spec->join($path, $cmd);
            if (-f $fn) {
                $sshd->_log("candidate found at $fn");
                unless (-x $fn) {
                    $sshd->_log("file $fn is not executable");
                    next;
                }
                unless (-B $fn) {
                    $sshd->_log("file $fn looks like a wrapper, ignoring it");
                    next;
                }
                return $fn unless wantarray;
                push @bins, $fn;
            }
        }
    }
    return @bins;
}

sub _find_executable {
    my ($sshd, $cmd, $version_flags, $min_version) = @_;
    my $slot = "${cmd}_executable";
    defined $sshd->{$slot} and return $sshd->{$slot};
    if (defined $version_flags) {
        for my $bin ($sshd->_find_binaries($cmd)) {
            $sshd->_log("checking version of '$bin'");
            my $out = $sshd->_capture_cmd( $bin, $version_flags );
            if (defined $out) {
                if (my ($ver, $mayor) = $out =~ /^(OpenSSH[_\-](\d+)\.\d+(?:\.\d+)?(?:p\d+))/m) {
                    if (!defined($min_version) or $mayor >= $min_version) {
                        $sshd->_log("executable version is $ver, selecting it!");
                        $sshd->{$slot} = $bin;
                        last;
                    }
                    else {
                        $sshd->_log("executable is too old ($ver), $min_version.x required");
                        next;
                    }
                }
            }
            $sshd->_log("command failed");
        }
    }
    else {
        $sshd->{$slot} = $sshd->_find_binaries($cmd)
    }
    if (defined (my $bin = $sshd->{$slot})) {
        $sshd->_log("command '$cmd' resolved as '$sshd->{$slot}'");
        return $bin;
    }
    else {
        $sshd->_error("no executable found for command '$cmd'");
        return;
    }
}

sub _ssh_executable { shift->_find_executable('ssh', '-V', 5) }

sub _mkdir {
    my ($sshd, $dir) = @_;
    if (defined $dir) {
        -d $dir and return 1;
        if (mkdir($dir, 0700) and -d $dir) {
            $sshd->_log("directory '$dir' created");
            return 1;
        }
        $sshd->_error("unable to create directory '$dir'", $!);
    }
    return;
}

sub _private_dir {
    my ($sshd, $subdir) = @_;
    my $slot = "private_dir";
    my $pdir = $sshd->{$slot};
    $sshd->_mkdir($pdir) or return;

    if (defined $subdir) {
        for my $sd (split /\//, $subdir) {
            $slot .= "/$sd";
            if (defined $sshd->{$slot}) {
                $pdir = $sshd->{$slot};
            }
            else {
                $pdir = File::Spec->join($pdir, $sd);
                $sshd->_mkdir($pdir) or return;
                $sshd->{$slot} = $pdir;
            }
        }
    }
    return $pdir;
}

sub _backend_dir {
    my ($sshd, $subdir) = @_;
    my $class = (ref $sshd ? ref $sshd : $sshd);
    if (my ($be) = $class =~ /\b(\w+)$/) {
        return $sshd->_private_dir(lc($be) . '/' . $subdir);
    }
    $sshd->_error("unable to infer backend name!");
    return
}

sub _run_dir {
    my $sshd = shift;
    unless (defined $sshd->{run_dir}) {
        $sshd->{run_dir} = $sshd->_backend_dir("run/$$");
        # $sshd->_log(run_dir => $sshd->{run_dir});
    }
    $sshd->{run_dir}
}

sub _run_dir_last { shift->_backend_dir('openssh/run/last') }

sub _fh {
    my ($sshd, $name, $write) = @_;
    my $slot = "${name}_fhs";
    unless (defined $sshd->{$slot}) {
        my $fn = File::Spec->join($sshd->_run_dir, "$name.out");
        my ($rfh, $wfh);
        unless (open $wfh, '>>', $fn) {
            $sshd->_log("unable to open file '$fn' for writting");
            return;
        }
        unless (open $rfh, '<', $fn) {
            $sshd->_log("unable to open file '$fn' for writting");
            return;
        };
        $rfh->autoflush(1);
        $sshd->{$slot} = [$rfh, $wfh];
    }
    $sshd->{$slot}[$write ? 1 : 0];
}


sub _read_fh {
    my ($sshd, $name) = @_;
    $sshd->_fh($name, 0);
}

sub _write_fh {
    my ($sshd, $name) = @_;
    $sshd->_fh($name, 1);
}

sub _run_cmd {
    my $sshd = shift;
    my %opts = (ref $_[0] ? %{shift()} : ());
    my @cmd = @_;

    $sshd->_log("running command '@cmd'");

    delete @{$sshd}{qw(cmd_output_offset cmd_output_name)};

    if (delete $opts{search_binary}) {
        if (my $method = ($sshd->can("$cmd[0]_executable") or $sshd->can("_$cmd[0]_executable"))) {
            $cmd[0] = $sshd->$method;
            defined $cmd[0] or return;
        }
    }

    my $password = delete $opts{password};

    my $out_fn = delete $opts{out_name} || 'client';
    my $out_fh = $sshd->_write_fh($out_fn) or return;
    print $out_fh "=" x 80, "\ncmd: @cmd\n", "-" x 80, "\n";
    $sshd->{cmd_output_offset} = tell $out_fh;
    $sshd->{cmd_output_name} = $out_fn;

    if ($^O =~ /^MSWin/) {
        if (defined $password) {
            $sshd->_error('running commands with a password is not supported on windows');
            return;
        }
        local $@;
        my $r = eval {
            local (*STDIN, *STDOUT, *STDERR);
            open STDIN, '<', $dev_null or die $!;
            open STDOUT, '>>&', $out_fh or die $!;
            open STDOUT, '>>&', *STDOUT or die $!;
            ( delete $opts{async}
              ? ( system 1, @cmd )
              : ( system(@cmd) == 0 ) )
        };
        $@ and $sshd->_log($@);
        return $r;
    }
    else {
        my $pty;
        if (defined $password) {
            unless (eval { require IO::Pty; 1 }) {
                $sshd->_error("IO::Pty not available");
                return;
            }
            $pty = IO::Pty->new;
        }

        my $pid = fork;
        unless ($pid) {
            unless (defined $pid) {
                $sshd->_log("fork failed", $!);
                return;
            }
            eval {
                $pty->make_slave_controlling_terminal if $pty;
                open my $in, '</dev/null';
                open my $out2, '>>&', $out_fh or die $!;
                POSIX::dup2(fileno($in),   0) or die $!;
                POSIX::dup2(fileno($out2), 1) or die $!;
                POSIX::dup2(1, 2) or die $!;
                exec @cmd;
            };
            $@ and $sshd->_error($@);
            exit(1);
        }
        if (delete $opts{async}) {
            return (wantarray ? ($pid, $pty) : $pid);
        }
        else {
            local $SIG{PIPE} = 'IGNORE';
            my $end = time + $sshd->{timeout};
            my $buffer = '';
            while (1) {
                if (time > $end) {
                    kill ((time - $end > 3 ? 'KILL' : 'TERM'), $pid);
                }
                if (waitpid($pid, POSIX::WNOHANG()) > 0) {
                    if ($?) {
                        $sshd->_log("program failed, rc: $?");
                        return
                    }
                    return 1;
                }
                if ($pty) {
                    my $rv = '';
                    vec($rv, fileno($pty), 1) = 1;
                    if (select($rv, undef, undef, 0) > 0) {
                        sysread($pty, $buffer, 1024, length($buffer));
                        if ($buffer =~ s/.*[>:?]\s*$//s) {
                            print $pty "$password\n";
                        }
                    }
                }
                select(undef, undef, undef, 0.3);
            }
        }
    }
}

sub _capture_cmd {
    my $sshd = shift;
    $sshd->_run_cmd(@_);
    my $name = $sshd->{cmd_output_name};
    return unless defined $name;
    my $fh = $sshd->_read_fh($name);
    my $off = $sshd->{cmd_output_offset};
    seek($fh, $off, 0);
    do { local $/; <$fh> };
}

sub _test_server {
    my $sshd = shift;
    for my $cmd (@{$sshd->{test_commands}}) {
        if (defined $sshd->{requested_uri} or $sshd->_run_cmd($cmd)) {
            if ($sshd->_run_remote_cmd($cmd)) {
                $sshd->_log("connection ok");
                return 1;
            }
        }
    }
    ()
}

sub uri {
    my ($sshd, %opts) = @_;
    my $auth_method = $sshd->{auth_method};
    my $uri = URI->new;
    $uri->scheme('ssh');
    $uri->user($sshd->{user});
    $uri->host($sshd->{host});
    $uri->port($sshd->{port});
    if ($auth_method eq 'password') {
        $uri->password($opts{hidden_password} ? '*****' : $sshd->{password});
    }
    elsif ($auth_method eq 'publickey') {
        $uri->c_params(["key_path=$sshd->{key_path}"]);
    }
    $uri;
}

sub connection_params {
    my $sshd = shift;
    if (wantarray) {
        my @keys = qw(host port user);
        push @keys, ($sshd->{auth_method} eq 'password' ? 'password' : 'key_path');
        return map { $_ => $sshd->$_ } @keys;
    }
    else {
        return $sshd->uri;
    }
}



sub server_version {
    my $sshd = shift;
    unless (defined $sshd->{server_version}) {
        $sshd->_log("retrieving server version");
        require IO::Socket::INET;
        my $end = time + $sshd->{timeout};
        my $buffer = '';
        if (my $socket = IO::Socket::INET->new(PeerAddr => $sshd->{host},
                                               PeerPort => $sshd->{port},
                                               Timeout  => $sshd->{timeout},
                                               Proto    => 'tcp',
                                               Blocking => 0)) {
            while (time <= $end and $buffer !~ /\n/) {
                my $rv = '';
                vec($rv, fileno($socket), 1) = 1;
                if (select($rv, undef, undef, 1) > 0) {
                    sysread($socket, $buffer, 1024, length($buffer)) or last;
                }
            }
            if ($buffer =~ /^(.*)\n/) {
                $sshd->{server_version} = $1;
            }
            else {
                $sshd->_log("unable to retrieve server version");
            }
        }
        else {
            $sshd->_log("unable to connect to server", $!);
        }
    }
    $sshd->{server_version}
}

sub server_os {
    my $sshd = shift;
    unless (defined $sshd->{server_os}) {
        $sshd->_log("retrieving server operating system info");
    }
}

sub _rmdir {
	my ($sshd, $dir) = @_;
	if (opendir my $dh, $dir) {
		while (defined (my $entry = readdir $dh)) {
			next if $entry eq $up_dir or $entry eq $cur_dir;
			unlink File::Spec->join($dir, $entry); 
		}
		closedir $dh;
	}
	unlink $dir;
}

sub DESTROY {
    my $sshd = shift;
    local ($@, $!, $?, $^E);
    eval {
        if (defined (my $run_dir = $sshd->_run_dir)) {
            if (defined (my $last = $sshd->_run_dir_last)) {
				$sshd->_rmdir($run_dir);
                rename $sshd->{run_dir}, $last;
                $sshd->_log("SSH server logs moved to '$last'");
            }
        }
    };
}

1;
