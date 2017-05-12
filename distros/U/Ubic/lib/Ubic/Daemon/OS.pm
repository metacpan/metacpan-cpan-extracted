package Ubic::Daemon::OS;
$Ubic::Daemon::OS::VERSION = '1.60';
use strict;
use warnings;

# ABSTRACT: base class for os-specific daemon methods

sub new {
    return bless {} => shift;
}

sub pid2guid {
    die 'not implemented';
}

sub pid2cmd {
    die 'not implemented';
}

sub close_all_fh {
    die 'not implemented';
}

sub pid_exists {
    die 'not implemented';
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ubic::Daemon::OS - base class for os-specific daemon methods

=head1 VERSION

version 1.60

=head1 METHODS

=over

=item B<new>

Trivial constructor.

=item B<pid2guid($pid)>

Get pid's guid. Guid is some kind of additional process identifier on systems where we can think of one.

On Linux, for example, it's the timestamp in jiffies when process started.

Returns undef if pid not found, throws exception on other errors.

=item B<pid2cmd($pid)>

Get process cmd line from pid.

=item B<close_all_fh(@except)>

Close all file descriptors except ones specified as arguments.

=item B<pid_exists($pid)>

Check if process with given pid exists.

=back

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
