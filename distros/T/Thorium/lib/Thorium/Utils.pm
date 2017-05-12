package Thorium::Utils;
{
  $Thorium::Utils::VERSION = '0.510';
}
BEGIN {
  $Thorium::Utils::AUTHORITY = 'cpan:AFLOTT';
}

# ABSTRACT: additional utilities

use Thorium::Protection;

# core
use Fcntl ':flock';
use FindBin qw();
use Time::HiRes qw();

# CPAN
use File::Slurp qw(read_file);
use IPC::Cmd qw();
use Params::Util qw();
use Proc::ProcessTable;
use Sub::Exporter;

my @funcs_names = qw(block_new_invocations unblock_new_invocations page execute already_running halt run);

Sub::Exporter::setup_exporter(
    {
        'exports' => \@funcs_names,
        'groups'  => {'default' => \@funcs_names}
    }
);

our $Lock_FH;
our $Lock_Filename;

my %old_sig_int_handlers;

for my $sig_name (qw(INT TERM)) {
    if ($SIG{$sig_name} && defined(&{$SIG{$sig_name}})) {
        $old_sig_int_handlers{$sig_name} = $SIG{$sig_name};
    }
}

# Allows the END {} block below to be called
sub _sig_handler {
    my ($sig_name) = @_;

    if ($old_sig_int_handlers{$sig_name}) {
        $old_sig_int_handlers{$sig_name}->(@_);
    }

    die("Caught $sig_name, aborting\n");
}

local $SIG{'INT'}  = \&_sig_handler;
local $SIG{'TERM'} = \&_sig_handler;

sub block_new_invocations {
    my ($lock_file) = @_;

    unless ($lock_file) {
        my $username = getlogin || getpwuid($<) || 'unknown';
        my $s = $FindBin::Script;

        # clean up the filename so it's easier to read and Unix-safe
        $s =~ s/[.\-]/_/g;
        $s =~ s/[\{\[\(\<>)\]\}~\|\/]/_/g;
        $s =~ s/[\p{Zs}\t]+/_/g;
        $s =~ s/\&+/_and_/g;
        $s =~ s/[^\p{Alphabetic}\p{Nd}\-\.\+_]//g;

        $lock_file = sprintf('/tmp/thorium_utils_lock_file_%s_%s.lock', $username, $s);
    }

    if (-e $lock_file) {
        die("The lock file, $lock_file, already exists, most likely this process ($FindBin::Script) is already running. If not, delete the file and run again.\n");
    }

    if ($Lock_FH && Params::Utils::_HANDLE($Lock_FH)) {
        warn('The global file handle has already been initialized. Call Thorium::Utils::unblock_new_invocations() to release lock.');
        return;
    }

    open($Lock_FH, '>', $lock_file) or die("Could not create/open lock file '$lock_file' - $!\n");

    unless (flock($Lock_FH, LOCK_EX | LOCK_NB)) {
        $Lock_FH = undef;

        die("flock() failed - $!\n");
    }

    $Lock_Filename = $lock_file;

    return $Lock_FH;
}

sub unblock_new_invocations {
    if ($Lock_FH) {
        flock($Lock_FH, LOCK_UN);
        close($Lock_FH);
        unlink($Lock_Filename);
    }

    return;
}

sub already_running {
    my $filename   = Params::Util::_STRING(shift(@_)) or die("Please pass the full file path to the pid file as the first argument to already_running()\n");
    my $executable = Params::Util::_STRING(shift(@_)) or die("Please pass the full executable file path as the second argument to already_running()\n");

    if (-e -r -s $filename) {
        my $pt = Proc::ProcessTable->new;

        my $pid = read_file($filename);

        foreach my $p (@{$pt->table}) {
            if ($p->pid == $pid && $p->cmndline =~ $executable) {
                return 1;
            }
        }
    }

    return 0;
}

sub halt {
    my $pid = Params::Util::_POSINT(shift(@_)) or die("Please pass a process ID as the only argument to halt()\n");

    my $pt = Proc::ProcessTable->new;

    my $deadline = time() + 8;    # 8 seconds should be enough time ...

    unless (grep { $pid == $_->pid } @{$pt->table}) {
        warn("$pid is not currently running\n");
    }

    foreach my $p (@{$pt->table}) {
        if ($p->pid == $pid) {
            if (kill(15, $p->pid)) {
                while (time() < $deadline) {
                    if (kill(0, $p->pid) > 0) {
                        Time::HiRes::usleep(100);
                    }
                    elsif ($!{'ESRCH'}) {
                        return 0;
                    }
                    else {
                        return 0;
                    }
                }
            }
            else {
                die('Failed to send SIGINT to process ID ', $p->pid, "\n");
            }
        }
    }

    return 0;
}

sub run {
    my @command = @_;

    Params::Util::_ARRAY(\@command) or die("Please pass a command to system()\n");

    unless (-e -r -x $command[0]) {
        die($command[0], " either doesn't exist, not readable or not executable\n");
    }

    my ($success) = IPC::Cmd::run('command' => \@command, 'verbose' => 1);

    return $success;
}

sub execute {
    my @command = @_;

    Params::Util::_ARRAY(\@command) or die("Please pass a command to execute()\n");

    unless (-e -r -x $command[0]) {
        die($command[0], " either doesn't exist, not readable or not executable\n");
    }

    exec(@command) or die($!);
}

sub page {
    my ($text) = @_;

    return unless ($text);

    my $pager;

    foreach my $exe ($ENV{'PAGER'}, '/usr/bin/less', '/bin/less') {
        if (-x $exe) {
            $pager = $exe;
            last;
        }
    }

    local $SIG{'PIPE'} = 'IGNORE';

    if ($pager) {
        my $fh;
        open($fh, "| $pager") && select($fh); ## no critic

        print {$fh} $text;
    }

    return;
}

END {
    if ($Lock_Filename && -e $Lock_Filename) {
        warn("Warning: $Lock_Filename still exists. You should probably delete this.\n");
    }
}

1;



=pod

=head1 NAME

Thorium::Utils - additional utilities

=head1 VERSION

version 0.510

=head1 SYNOPSIS

    use Thorium::Utils;

    Thorium::Utils::block_new_invocations();

    ...

    END {
        Thorium::Utils::unblock_new_invocations();
    }

=head1 SUBROUTINES/METHODS

=over

=item B<block_new_invocations([$filename])>

Creates a file lock on a temporary file, or you may pass in your own file
name. The lock file handle is global and should not be tampered with outside the
library interface.

=item B<unblock_new_invocations()>

Release the lock on the temporary file.

=item B<page($text)>

Pipe $text through a pager.

=item B<already_running($filename, $executable)>

Returns 1 if the process ID listed in C<$filename> and C<$executable> are currently running, 0 otherwise.

=item B<halt($pid)>

Sends C<SIGTERM> to C<$pid> and waits up to 8 seconds for it be terminated.

=item B<run(@command)>

Executes C<@command> and blocks until it finishes. Returns a true value if successful, false otherwise.

=item B<execute(@command)>

C<fork()>s C<@command> and C<exec()>s.

=back

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>, CIDC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

