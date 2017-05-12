package Test::SSH::Backend::OpenSSH;

use strict;
use warnings;

use IO::Socket::INET;

require Test::SSH::Backend::Base;
our @ISA = qw(Test::SSH::Backend::Base);

sub new {
    my ($class, %opts) = @_;
    my $override_server_config = delete $opts{override_server_config} || {};
    my $sshd = $class->SUPER::new(%opts, auth_method => 'publickey');
    unless ($sshd->{run_server}) {
        $sshd->_log("backend skipped because run_server is set to false");
        return;
    }

    my $exe = $sshd->_sshd_executable or return;
    $sshd->_create_keys or return;
    my $run_dir = $sshd->_run_dir;
    my $port = $sshd->{port} = $sshd->_find_unused_port;
    use Tie::IxHash; # order must be preserved because Port must come before ListenAddress

    tie my %Config, 'Tie::IxHash',
        (                HostKey            => $sshd->{host_key_path},
                         AuthorizedKeysFile => $sshd->_user_key_path_quoted . ".pub",
                         AllowUsers         => $sshd->{user}, # only user running the script can log
                         AllowTcpForwarding => 'yes',
                         GatewayPorts       => 'no', # bind port forwarder listener to localhost only
                         ChallengeResponseAuthentication => 'no',
                         PasswordAuthentication => 'no',
                         Port               => $port,
                         ListenAddress      => "localhost:$port",
                         LogLevel           => 'INFO',
                         PermitRootLogin    => 'yes',
                         PidFile            => "$run_dir/sshd.pid",
                         PrintLastLog       => 'no',
                         PrintMotd          => 'no',
                         Subsystem          => 'sftp /usr/lib/openssh/sftp-server',
                         UseDNS             => 'no',
                         UsePrivilegeSeparation => 'no',
        );
    while (my($k,$v) = each %$override_server_config) {
        if (defined $v) {
            $Config{$k} = $v;
        } else {
            delete $Config{$k};
        }
    }
    $sshd->_write_config(%Config)
        or return;

    $sshd->_log('starting SSH server');
    unless ($sshd->{server_pid} = $sshd->_run_cmd({out_name => 'server',
                                                   async => 1},
                                                  $exe,
                                                  '-D', # no daemon
                                                  '-e', # send output to STDERR
                                                  '-f', $sshd->{config_file})) {
        $sshd->_error("unable to start SSH server at '$exe' on port $port", $!);
        return undef;
    }

    $sshd->_log("SSH server listening on port $port");

    $sshd->_log("trying to authenticate using keys");
    $sshd->{auth_method} = 'publickey';
    for my $key (@{$sshd->{user_keys}}) {
        $sshd->_log("trying user key '$key'");
        $sshd->{key_path} = $key;
        if ($sshd->_test_server) {
            $sshd->_log("key '$key' can be used to connect to host");
            return $sshd;
        }
    }
    ()
}

sub _write_config {
    my $sshd = shift;
    my $fn = $sshd->{config_file} = "$sshd->{run_dir}/sshd_config";
    if (open my $fn, '>', $fn) {
        while (@_) {
            my $k = shift;
            my $v = shift;
            print $fn "$k=$v\n";
        }
        close $fn and return 1
    }
    $sshd->_error("unable to create sshd configuration file at '$fn': $!");
    ()
}

sub _is_server_running {
    my $sshd = shift;
    if (defined (my $pid = $sshd->{server_pid})) {
        my $rc = waitpid($pid, POSIX::WNOHANG());
        $rc <= 0 and return $sshd->SUPER::_is_server_running;
        delete $sshd->{server_pid};
        $sshd->_log("server process has terminated (rc: $?)");
    }
    $sshd->_error("SSH server is not running");
    return
}

sub DESTROY {
    my $sshd = shift;
    local ($@, $!, $?, $^E);
    eval {
        if (defined (my $run_dir = $sshd->_run_dir)) {
            for my $signal (qw(TERM TERM TERM TERM KILL)) {
                open my $fh, '<', "$run_dir/sshd.pid" or last;
                my $pid = <$fh>;
                defined $pid or last;
                chomp $pid;
                $pid or last;
                $sshd->_log("sending $signal signal to server (pid: $pid)");
                kill $signal => $pid;
                sleep 1;
            }
        }
        $sshd->SUPER::DESTROY;
    };
}

sub _sshd_executable { shift->_find_executable('sshd', '-zalacain', 5) }

sub _ssh_keygen_executable { shift->_find_executable('ssh-keygen') }

sub _create_key {
    my ($sshd, $fn) = @_;
    -f $fn and -f "$fn.pub" and return 1;
    $sshd->_log("generating key '$fn'");
    my $tmpfn = join('.', $fn, $$, int(rand(9999999)));
    if ($sshd->_run_cmd( { search_binary => 1 },
                         'ssh_keygen', -t => 'rsa', -b => 1024, -f => $tmpfn, -P => '')) {
        unlink $fn;
        unlink "$fn.pub";
        if (rename $tmpfn, $fn and
            rename "$tmpfn.pub", "$fn.pub") {
            $sshd->_log("key generated");
            return 1;
        }
    }
    $sshd->_error("key generation failed");
    return;
}

sub _user_key_path_quoted {
    my $sshd = shift;
    my $key = $sshd->{user_key_path};
    $key =~ s/%/%%/g;
    $key;
}

sub _create_keys {
    my $sshd = shift;
    my $kdir = $sshd->_private_dir('openssh/keys') or return;
    my $user_key = $sshd->{user_key_path} = "$kdir/user_key";
    my $host_key = $sshd->{host_key_path} = "$kdir/host_key";
    $sshd->{user_keys} = [$user_key];
    $sshd->_create_key($user_key) and
    $sshd->_create_key($host_key);
}

sub _find_unused_port {
    my $sshd = shift;
    $sshd->_log("looking for an unused TCP port");
    for (1..32) {
        my $port = 5000 + int rand 27000;
        unless (IO::Socket::INET->new(PeerAddr => "localhost:$port",
                                      Proto => 'tcp',
                                      Timeout => $sshd->{timeout})) {
            $sshd->_log("port $port is available");
            return $port;
        }
    }
    $sshd->_error("Can't find free TCP port for SSH server");
    return;
}

1;
