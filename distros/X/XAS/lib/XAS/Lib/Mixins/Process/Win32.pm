package XAS::Lib::Mixins::Process::Win32 ;

our $VERSION = '0.01';

use Win32::OLE('in');

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  utils   => ':validation dotid',
  mixins  => 'proc_status',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub proc_status {
    my $self = shift;
    my ($pid, $alias) = validate_params(\@_, [
        1,
        { optional => 1, default => '' },
    ]);
    
    my $stat = 0;
    my $computer = 'localhost';

    $self->log->debug("$alias: entering stat_process");

    # query wmi for the an existing process with this pid

    my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\CIMV2") or
      $self->throw_msg(
          dotid($self->class) . '.stat_process.winole',
          'unexpected',
          'WMI connection failed'
      );

    my $colItems = $objWMIService->ExecQuery(
        "SELECT * FROM Win32_Process WHERE ProcessID = $pid",
        "WQL",
        wbemFlagReturnImmediately | wbemFlagForwardOnly
    );

    foreach my $objItem (in $colItems) {

        if ($objItem->{'ProcessID'} eq $pid) {

            my $handle = $objItem->{'Handle'};

            # win32 wmi ExecutionState codes
            # from http://msdn.microsoft.com/en-us/library/aa394372(v=vs.85).aspx
            #
            # unknown           - 0
            # other             - 1
            # ready             - 2
            # running           - 3
            # blocked           - 4
            # suspended blocked - 5
            # suspended ready   - 6
            #
            # Sadly not implemented, ExceutionState will always be null
            # This is true for Win32_Process and Win32_Thread
            #
            # So you need to query the threads of the process to see
            # what's up, and then roll your own pseudo ExecutionState.
            # 
            # To bad Microsoft doesn't do this for you. Then there
            # would be one version of the truth. Instead of this made
            # up one or some random implementation from a blog posting...
            #

            my $threadList = $objWMIService->ExecQuery(
                "SELECT * FROM Win32_Thread WHERE ProcessHandle = $handle",
                'WQL',
                wbemFlagReturnImmediately | wbemFlagForwardOnly
            );

            # ThreadState
            # from https://msdn.microsoft.com/en-us/library/aa394494%28v=vs.85%29.aspx
            #
            # 0 - Initialized — It is recognized by the microkernel
            # 1 - Ready       - It is prepared to run on the next available processor
            # 2 - Running     — It is executing.
            # 3 - Standby     — It is about to run, only one thread may be in this state at a time
            # 4 - Terminated  — It is finished executing
            # 5 - Waiting     — It is not ready for the processor, when ready, it will be rescheduled
            # 6 - Transition  — The thread is waiting for resources other than the processor
            # 7 - Unknown     — The thread state is unknown
            #
            # when ThreadState = 5, you need to query the ThreadWaitReason to find out why.
            #
            # ThreadWaitReason
            #
            # 0  - executive
            # 1  - free page
            # 2  - page in
            # 3  - pool allocation
            # 4  - execution delay
            # 5  - free page
            # 6  - page in
            # 7  - executive
            # 8  - free page
            # 9  - page in
            # 10 - pool allocation
            # 11 - execution delay
            # 12 - free page
            # 13 - page in
            # 14 - event pair high
            # 15 - event pair low
            # 16 - local rpc receive
            # 17 - local rpc reply
            # 18 - virtual memory
            # 19 - page out
            # 20 - unkown
            #
            # from http://library.wmifun.net/cimv2/win32_thread.html
            #
            # The ThreadWaitReason property indicates why the thread is
            # waiting. The value is only valid if the ThreadState member
            # is set to Waiting (ie 5).
            #
            # 0 or 7 denote that the thread is waiting for the Executive
            # 1 or 8 for a Free Page
            # 2 or 9 for a Page In
            # 3 or 10 for a Pool Allocation
            # 4 or 11 for an Execution Delay
            # 5 or 12 for a Suspended condition
            # 6 or 13 for a User Request
            # 14 for an Event Pair High
            # 15 for an Event Pair Low
            # 16 for an Local Procedure Call (LPC) Receive
            # 17 for an LPC Reply, 18 for Virtual Memory
            # 19 for a Page Out
            # 20 and higher are not assigned
            #
            # -----
            # This gets intersting, and is my interpetation of reality.
            #

            foreach my $thread (in $threadList) {

                $self->log->debug(sprintf('%s: stat_process - ThreadState: %s', $alias, $thread->{'ThreadState'}));

                if ($thread->{'ThreadState'} == 1) {

                    $stat = 2;

                } elsif ($thread->{'ThreadState'} == 2) {

                    $stat = 3;

                } elsif ($thread->{'ThreadState'} == 3) {

                    $stat = 2;

                } elsif ($thread->{'ThreadState'} == 5) {

                    $self->log->debug(sprintf('%s: stat_process - ThreadWaitReason: %s', $alias, $thread->{'ThreadWaitReason'}));

                    $stat = 1;

                    if (($thread->{'ThreadWaitReason'} == 5)  ||
                        ($thread->{'ThreadWaitReason'} == 12)) {

                        $stat = 6;

                    } elsif (($thread->{'ThreadWaitReason'} == 6) ||
                             ($thread->{'ThreadWaitReason'} == 13)) {

                        $stat = 2;

                    } elsif (($thread->{'ThreadWaitReason'} > 13) &&
                             ($thread->{'ThreadWaitReason'} < 18)) {

                        $stat = 5;

                    }

                } elsif ($thread->{'ThreadState'} == 6) {

                    $stat = 4;

                }

            }

        }

    }

    $self->log->debug("$alias: leaving stat_process");

    return $stat;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Mixins::Process::Win32 - A mixin for the XAS environment

=head1 SYNOPSIS

 use XAS::Class
   debug   => 0,
   version => '0.01',
   base    => 'XAS::Base',
   mixin   => 'XAS::Lib::Mixins::Process'
;

=head1 DESCRIPTION

This mixin provides a method to check for running processes on Win32.

=head1 METHODS

=head2 proc_status($pid)

Check for the running process. It can return one of the following status codes.

    6 - Suspended ready
    5 - Suspended blocked
    4 - Blocked
    3 - Running
    2 - Ready
    1 - Other
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
