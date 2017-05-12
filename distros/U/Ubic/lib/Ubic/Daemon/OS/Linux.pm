package Ubic::Daemon::OS::Linux;
$Ubic::Daemon::OS::Linux::VERSION = '1.60';
use strict;
use warnings;

# ABSTRACT: linux-specific daemonize helpers


use POSIX;

use parent qw(Ubic::Daemon::OS);

sub pid2guid {
    my ($self, $pid) = @_;

    unless (-d "/proc/$pid") {
        return; # process not found
    }
    my $opened = open(my $fh, '<', "/proc/$pid/stat");
    unless ($opened) {
        # open failed
        my $error = $!;
        unless (-d "/proc/$pid") {
            return; # process exited right now
        }
        die "Open /proc/$pid/stat failed: $!";
    }
    my $line = <$fh>;
    # cut first two fields (pid and process name)
    # since process name can contain spaces, we can't just split line by \s+
    $line =~ s/^\d+\s+\([^)]*\)\s+//;

    my @fields = split /\s+/, $line;
    my $guid = $fields[19];
    return $guid;
}

sub pid2cmd {
    my ($self, $pid) = @_;

    my $daemon_cmd_fh;
    unless (open $daemon_cmd_fh, '<', "/proc/$pid/cmdline") {
        # this can happen if pid got reused and now it belongs to the kernel process, e.g., [kthreadd]
        warn "Can't open daemon's cmdline: $!";
        return 'unknown';
    }
    my $daemon_cmd = <$daemon_cmd_fh>;
    unless ($daemon_cmd) {
        # strange, open succeeded but file is empty
        # this can happen, though, for example if pid belongs to the kernel thread
        warn "Can't read daemon cmdline";
        return 'unknown';
    }
    $daemon_cmd =~ s/\x{00}$//;
    $daemon_cmd =~ s/\x{00}/ /g;
    close $daemon_cmd_fh;

    return $daemon_cmd;
}

sub close_all_fh {
    my ($self, @except) = @_;

    my @fd_nums = map { s!^.*/!!; $_ } glob("/proc/$$/fd/*");
    for my $fd (@fd_nums) {
        next if grep { $_ == $fd } @except;
        POSIX::close($fd);
    }
}

sub pid_exists {
    my ($self, $pid) = @_;
    return (-d "/proc/$pid");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ubic::Daemon::OS::Linux - linux-specific daemonize helpers

=head1 VERSION

version 1.60

=head1 DESCRIPTION

These functions use C<< /proc >> virtual filesystem for some operations.

There is another C<< Ubic::Daemon::OS::POSIX >> module, which is more generic and should work on all POSIX-compatible systems.
But this module is older and supposedly more stable. (Also, sometimes it's more optimal, compare implementation of C<close_all_fh()>, for example).

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
