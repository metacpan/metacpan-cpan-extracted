package Win32::JobAdd;
use strict;
use warnings;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(
    createJobObject assignProcessToJobObject closeHandle
);

our $VERSION = '1.00';

require XSLoader;
XSLoader::load('Win32::JobAdd', $VERSION);

1;
__END__

=head1 NAME

Win32::JobAdd - Add subprocesses to a "job" environment.

=head1 SYNOPSIS

   use Win32::JobAdd;

   my $job = createJobObject( 'job_foo' );
   my $pid = open O, q[perl -E "system 1, 'calc.exe';
                                system 1, 'notepad.exe';
                                sleep 100" |] or die $^E;

   assignProcessToJobObject( $job, $pid );

   # do something with the subprocess

   closeHandle( $job );

=head1 PLATFORMS

Win32::JobAdd requires Windows XP or later. Windows 95, 98, NT, Me and 2000 are not
supported.

=head1 DESCRIPTION

A "job" is a collection of processes which can be controlled as a single unit. For example, you can reliably kill a
process and all of its children by launching the process in a job, then telling Windows to kill all processes in the job.

There is another module L<Win32::Job> which is fine when you don't need to do anything with the processes it spawns for you,
but is limited otherwise.

With Win32::JobAdd you can create processes in a job environment and e.g. read the STDOUT from them.

See the EXAMPLE section for a useful scenario.

=head1 FUNCTIONS

=over 4

=item JOB createJobObject JOB_NAME

   my $job = createJobObject( 'job_foo' );

Returns a JOB named JOB_NAME if it succeeds.
Returns zero if it fails.
Look at C<$^E> for more detailed error information.

=item assignProcessToJobObject JOB PID

   assignProcessToJobObject( $job, $pid );

Assigns a PID (process ID) to the JOB.
This means that the process and all its children are now part of this JOB.
Returns nonzero if it succeeds.
Returns zero if it fails.

=item closeHandle JOB

      closeHandle( $job );

Kills all processes and all its children which are part of the JOB.
Returns nonzero if it succeeds.
Returns zero if it fails.

=back


=head1 EXAMPLE

The following code shows a non-blocking Tk GUI which reads from a child process which spawns another process.
When pressing the "CANCEL" button or when the GUI is closed, the whole process tree is killed.

Without adding the child process to a job the grandchild process "calc" would still be alive and stay as a
zombie process.

    #!/usr/bin/perl

    use strict;
    use threads;
    use Thread::Queue;

    use Win32::JobAdd;

    ## A shared var to communicate progess between work thread and TK
    my $Q = new Thread::Queue;

    my $job:shared = createJobObject( 'counter_and_calc_job' );

    sub work{
        my $pid = open PROC,
        q[perl -le "$|=1; system 1, 'calc.exe'; print and select(undef,undef,undef,0.1) for 1 .. 1000" |]
            or die $!;
        assignProcessToJobObject( $job, $pid );

        while( <PROC> ) {
            $Q->enqueue( $_ );
        }
        close PROC;
    }

    threads->new( \&work )->detach;

    ## For lowest memory consumption require (not use)
    ## Tk::* after you've started the work thread.
    require Tk::ProgressBar;

    my $mw = MainWindow->new;
    my $pb = $mw->ProgressBar()->pack();
    my $button = $mw->Button(-text => 'CANCEL',
                             -command => sub { closeHandle( $job ) } )->pack();

    my $repeat;
    $repeat = $mw->repeat( 100 => sub {
        while( $Q->pending ) {
            my $progress = $Q->dequeue;
            return unless $progress;
            $repeat->cancel if $progress == 100;
            $pb->value( $progress )
        }
    });

    $mw->MainLoop;

=head1 SEE ALSO

For more information about jobs, see Microsoft's online help at

   http://msdn.microsoft.com/

For another module which does a similar thing, see:

=over 4

=item Win32::Job

Run subprocesses in a job environment. See L<Win32::Job>.

=back

=head1 AUTHOR

BrowserUk (browseruk@cpan.org)
Dirk Joos (dirk@dirkundsari.de)

=head1 COPYRIGHT

Copyright (c) 2012, BrowserUk, Dirk Joos. All Rights Reserved.
This program is free software; you may use it and/or redistribute it under the same terms as Perl itself.

=cut
