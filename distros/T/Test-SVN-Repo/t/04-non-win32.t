#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
require Test::NoWarnings if $ENV{RELEASE_TESTING};

use IPC::Cmd qw( can_run run );
use IPC::Run ();
use Probe::Perl;

use Test::SVN::Repo;

if ($^O eq 'MSWin32') {
    plan skip_all => 'Tests not valid on Win32';
    exit;
}

my $svn;
unless ($svn = can_run('svn')) {
    plan skip_all => 'Subversion not installed';
    exit;
}

my %users = ( userA => 'passA', userB => 'passB' );

note 'Port range tests'; {

    # This mysteriously doesn't work on win32.
    # I can manually start multiple svnserve instances on a single port.
    # Its as if they get queued up - the first one serves the requests,
    # and the second takes over once the first has exited.

    my $repo = Test::SVN::Repo->new( users      => \%users,
                                     start_port => 50000,
                                     end_port   => 60000 );
    my $port = $repo->server_port;
    ok($port >= $repo->start_port, '... port is within specified range');
    ok($port <= $repo->end_port,   '... port is within specified range');

    # Try creating a server on a port we know is taken
    my $retry_count = 5;
    my $tempdir = File::Temp->newdir;
    throws_ok { Test::SVN::Repo->new(users       => \%users,
                                     start_port  => $port,
                                     end_port    => $port,
                                     retry_count => $retry_count,
                                     root_path   => $tempdir,
                                     keep_files  => 0) }
        qr/Giving up after $retry_count attempts/,
        '... server gives up if no ports available';
    ok(! -d $tempdir, '... and root path gets cleaned up');
}

note 'Check that svnserve gets cleaned up'; {

    # Killing the child process doesn't seem to work on win32.
    # IPC::Run confirms this behaviour. Processes can only be KILLED
    # under win32.

    for my $signame ( qw( ABRT BUS EMT FPE HUP ILL INT PIPE QUIT SEGV SYS TERM TRAP ) ) {
        next unless exists $SIG{$signame};

        my $pid;
        lives_ok { $pid = spawn_and_signal($signame) }
            '... child process started okay';

        like($pid, qr/^\d+$/, '... got valid pid for server process');

        # Check that the server (grandchild process) exits if we
        # kill its parent
        ok(! process_exists($pid), '... svnserve process has shutdown after receiving signal ' . $signame)
    }
}

note 'Forking'; {

    # Two repos, one local, one global
    our $global_repo = Test::SVN::Repo->new( users => \%users );
    my  $local_repo  = Test::SVN::Repo->new( users => \%users );

    ok(run_ok($svn, 'info', $global_repo->url), '... global server is up');
    ok(run_ok($svn, 'info', $local_repo->url),  '... local server is up');

    my $child_count = 0;
    for (1 .. 8) {
        my $pid = fork;
        next unless defined $pid;
        if ($pid) {
            $child_count++;
        }
        else {
            # Just exit in the child
            exit 0;
        }
    }
    for (1 .. $child_count) {
        waitpid(-1, 0);
    }

    ok(run_ok($svn, 'info', $global_repo->url),
        '... global server is still up');

    ok(run_ok($svn, 'info', $local_repo->url),
        '... local server is still up');
}

note 'Exit time cleanup for non-server mode'; {
    my $tempdir = File::Temp->newdir;
    in_child(sub {
        our $repo =
            Test::SVN::Repo->new( root_path => $tempdir, keep_files => 0 );
    });

    ok(! -d $tempdir, '... root path got cleaned up');
}

note 'Exit time file cleanup for server mode'; {
    my $tempdir = File::Temp->newdir;
    in_child(sub {
        our $repo =
            Test::SVN::Repo->new( root_path  => $tempdir,
                                  keep_files => 0,
                                  users      => \%users );
    });

    ok(! -d $tempdir, '... root path got cleaned up');
}

note 'Exit time server cleanup for server mode'; {
    my $tempdir = File::Temp->newdir;
    my $server_pid = run_repo_in_child($tempdir);
    ok(! process_exists($server_pid), '... server got cleaned up');
}

note 'Exit time foreign process non-cleanup'; {
    my $tempdir = File::Temp->newdir;
    my $repo = Test::SVN::Repo->new( users => \%users );

    my $server_pid = run_repo_in_child($tempdir);
    ok(! process_exists($server_pid), '... child server got cleaned up');

    ok(process_exists($repo->server_pid), '... parent server still running');
    ok(-d $repo->root_path, '... parent root path still there');
}

Test::NoWarnings::had_no_warnings() if $ENV{RELEASE_TESTING};
done_testing();

#------------------------------------------------------------------------------

sub process_exists {
    my ($pid) = @_;
    return kill(0, $pid);
}

sub run_ok {
    my (@cmd) = @_;
    return scalar run( command => \@cmd );
}

sub spawn_and_signal {
    my ($signal) = @_;

    my $code = <<'END';
my $repo = Test::SVN::Repo->new( users => { a => 'b' } );
$| = 1;
print $repo->server_pid, "\n";
1 while 1;
END

    # Spawn a child process that starts a server (grandchild process).
    my $perl = Probe::Perl->find_perl_interpreter;
    my @cmd = ( $perl, '-MTest::SVN::Repo', '-e' => $code);
    my ($in, $out, $err);
    my $h = IPC::Run::start(\@cmd, \$in, \$out, \$err);

    # Obtain the server pid (grandchild)
    my $pid;
    while (not $pid) {
        die "Child process has died: $err" if not $h->pumpable;
        $h->pump;
        $pid = $out;
        chomp $pid;
    }

    # Kill the child process
    $h->signal($signal);
    $h->finish;

    return $pid;
}

sub in_child {
    my $coderef = shift;
    my $pid = fork;
    return unless defined $pid;
    exit($coderef->()) unless $pid;
    waitpid($pid, 0);
    return ($? >> 8);
}

sub run_repo_in_child {
    my ($root_path) = @_;

    my $pid_file = 'server.pid';
    in_child(sub {
        our $repo =
            Test::SVN::Repo->new( root_path  => $root_path,
                                  keep_files => 1,
                                  users      => \%users );

        # Write the server pid to a file in tempdir
        $repo->root_path->file($pid_file)->spew($repo->server_pid);
        return 0;
    });

    # And read the server pid back in again
    my $server_pid = Path::Class::File->new($root_path, $pid_file)->slurp;
    return $server_pid;
}
