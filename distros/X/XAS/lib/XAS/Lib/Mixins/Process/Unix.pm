package XAS::Lib::Mixins::Process::Unix;

our $VERSION = '0.01';

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  mixins  => 'proc_status',
  utils   => 'run_cmd trim :validation',
;

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub proc_status {
    my $self = shift;
    my ($pid, $alias) = validate_params(\@_, [
        1,
        { optional => 1, default => "" },
    ]);

    my $stat = 0;
    my $cmd = "ps -p $pid -o state=";
    my ($output, $rc, $sig) = run_cmd($cmd);

    if (defined($rc) && $rc == 0) {

        my $line = trim($output->[0]);

        # UNIX states
        # from man ps
        #
        #   D    Uninterruptible sleep (usually IO)
        #   R    Running or runnable (on run queue)
        #   S    Interruptible sleep (waiting for an event to complete)
        #   T    Stopped, either by a job control signal or because it 
        #        is being traced.
        #   W    paging (not valid since the 2.6.xx kernel)
        #   X    dead (should never be seen)
        #   Z    Defunct ("zombie") process, terminated but not reaped 
        #        by its parent.

        $stat = 6 if ($line eq 'T');    # suspended ready
        $stat = 5 if ($line eq 'D');    # suspended blocked
#        $stat = 4 if ($line eq '?');    # blocked
        $stat = 3 if ($line eq 'R');    # running
        $stat = 2 if ($line eq 'S');    # ready
        $stat = 1 if ($line eq 'Z');    # other
#        $stat = 0 if ($line eq '?');    # unknown

    }

    return $stat;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Mixins::Process::Unix - A mixin for the XAS environment

=head1 SYNOPSIS

 use XAS::Class
   debug   => 0,
   version => '0.01',
   base    => 'XAS::Base',
   mixin   => 'XAS::Lib::Mixins::Process::Unix'
;

=head1 DESCRIPTION

This mixin provides a method to check for running processes on Unix.

=head1 METHODS

=head2 proc_status($pid)

Check for the running process. It can return one of the following status codes.

    6 - Stopped, either by a job control signal or it is being traced.
    5 - Uninterruptible sleep (usually IO)
    3 - Running or runnable (on run queue)
    2 - Interruptible sleep (waiting for an event to complete)
    1 - Defunct ("zombie") process, terminated but not reaped by its parent
    0 - Unknown

=over 4

=item B<$pid>

The process id to check for.

=back

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
