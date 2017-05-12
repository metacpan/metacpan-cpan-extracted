package Ubic::Daemon::OS::POSIX;
$Ubic::Daemon::OS::POSIX::VERSION = '1.60';
use strict;
use warnings;

# ABSTRACT: POSIX-compatible daemonize helpers

use Params::Validate qw(:all);
use POSIX qw(:unistd_h);

use parent qw(Ubic::Daemon::OS);

sub pid2guid {
    my ($self, $pid) = validate_pos(@_, 1, { type => SCALAR, regex => qr/^\d+$/ });

    return unless $self->pid_exists($pid);

    return 'NULL'; # no guid on mac os x yet
}

sub pid2cmd {
    my ($self, $pid) = validate_pos(@_, 1, { type => SCALAR, regex => qr/^\d+$/ });

    # see POSIX specification - http://pubs.opengroup.org/onlinepubs/009696799/utilities/ps.html
    my $result = qx(ps -p $pid -o pid,comm 2>/dev/null);
    $result =~ s/^.*\n//; # drop first line
    my ($ps_pid, $ps_command) = $result =~ /^\s*(\d+)\s+(.*)$/;
    unless ($ps_pid) {
        warn "Daemon $pid not found";
        return 'unknown';
    }
    unless ($ps_pid == $pid) {
        die "Internal error, expected pid $pid, got pid $ps_pid";
    }

    return $ps_command;
}

sub close_all_fh {
    my ($self, @except) = @_;

    for my $fd (0 .. POSIX::sysconf(POSIX::_SC_OPEN_MAX)) {
        next if grep { $_ == $fd } @except;
        POSIX::close($fd);
    }
}

sub pid_exists {
    my ($self, $pid) = validate_pos(@_, 1, { type => SCALAR, regex => qr/^\d+$/ });
    my $result = qx(ps -p $pid -o pid 2>/dev/null);
    if ($result =~ /\d/) {
        return 1;
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ubic::Daemon::OS::POSIX - POSIX-compatible daemonize helpers

=head1 VERSION

version 1.60

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
