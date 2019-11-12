package Thread::Status;

# Make sure we can do signals to threads

use Thread::Signal ();

# Make sure we have version info for this module
# Make sure we do everything by the book from now on

$VERSION = '0.05';
use strict;

# Make sure we only load stuff when we actually need it

use load;

# Remember the base thread id (only one allowed to make changes and start)
# Initialize the thread id of the monitoring thread
# Initialize the process id of the monitoring thread

our $base_tid = threads->tid;
our $monitor_tid : shared;
our $monitor_pid : shared;

# Initialize the number of seconds between every status report
# Initialize the format
# Initialize XML encoding
# Initialize the output direction
# Initialize the signal name
# Initialize the number of callers
# Initialize the shorten flag

our $every : shared = 5;
our $format : shared = 'plain';
our $output : shared = 'STDERR';
our $encoding : shared = 'iso-latin-1';
our $signal = 'HUP';
our $callers : shared = 0;
our $shorten : shared = 1;

# Initialize the running flag
# Initialize the wakeup flag
# Initialize the sweeping lock
# Initialize the number of threads swept lock
# Initialize the info hash
# Initialize the flag to indicate we need to return

our $running : shared = 0;
our $wakeup : shared = 0;
our $sweeping : shared = 0;
our $swept: shared;
our %info : shared;    # must all be our because of AutoLoader usage
our $dump : shared = 0;

# Initialize the thread local thread id (so we don't need threads->tid always)

our $tid;

# Create match string for paths
# Make sure periods are really periods during matching
# Make a regular exprssion of it

our $paths = join( '/|',sort {length($b) - length($a)} @INC ).'/';
$paths =~ s#\.#\\\.#sg;
$paths = qr#^(?:$paths)#;

# Satisfy -require-

1;

#---------------------------------------------------------------------------

# internal subroutines

#---------------------------------------------------------------------------

sub _sweep {

# Return now if switched off
# If we're called to wake up from the main monitoring loop
#  Reset the wakup flag
#  And exit the main processing loop in the monitoring thread

    return unless $running;
    if ($wakeup and threads->tid == $monitor_tid) {
        $wakeup = 0;
        die;
    }

# Attempt to get the lock
# If another thread is already sweeping
#  Remember where we are
#  Increment counter for number of threads swept
#  Signal the main thread that we're done here
#  And return (this thread is done and should allow other threads now)
# Indicate we're sweeping
# Reset the number of threads swept

    {lock( $sweeping );
     if ($sweeping) {
         _remember( 2 );
         $swept++;
         {no warnings 'threads'; threads::shared::cond_signal( $swept )};
	 return;
     }
     $sweeping = 1;
     $swept = 0
    } #$sweeping

# Initialize local copy of info hash
# Initialize number of threads swept (already stored info)
# Make sure we're the only one collecting
# Signal all of the other threads and remember how many were signalled
# Wait for all to have reported in

    my %stuff;
    {lock( $swept );
     my %waiting = %info;
     $swept = keys %waiting;
     my $tids = Thread::Signal->signal( $signal,-2 );
     threads::shared::cond_wait( $swept ) until $swept == $tids;

# Create local copy of the shared hash with info
# Reset the shared hash (we don't want to have any info oozing through)
# Mark that we're done sweeping

     %stuff = %info;
     %info = %waiting;
     $sweeping = 0;
    } #$swept

# If a specific dump is requested
#  Make sure we're the only ones now
#  Freeze our stuff in the dump area
#  And signal that we're ready
# Else (just need to report)
#  Perform basic, normal reporting

    if ($dump == 1) {
        lock( $dump );
        $dump = join( "\0",map {"$_\n$stuff{$_}"} keys %stuff );
        threads::shared::cond_signal( $dump );
    } else {
        _report( \%stuff );
    }

# Exit now if the signal used indicates we need to quit

    exit() if $signal eq 'INT';
} #_sweep

#---------------------------------------------------------------------------

# The following subroutines are loaded on demand only

__END__

#---------------------------------------------------------------------------

# class methods

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new number of seconds between updates
# OUT: 1 current number of seconds between updates

sub every {

# If we have a new time specification
#  Die now if we're not in the base thread
#  Set new value
#  If there is a monitoring thread running
#   Make sure the monitoring thread will wakeup only
#   Wake up the monitoring thread
# Return whatever is the current time specification

    if (@_ > 1) {
        die "Can only set time specification from the base thread\n"
         if threads->tid != $base_tid;
        $every = $_[1];
        if ($running) {
            $wakeup = 1;
            kill $signal,$monitor_pid;
        }
    }
    $every;
} #every

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new format
# OUT: 1 current format

sub format {

# If we have a new format specification
#  Die now if we're not in the base thread
#  Die now if unknown format
#  Set the new format
# Return whatever is the current format

    if (@_ > 1) {
        die "Can only set format from the base thread\n"
         if threads->tid != $base_tid;
        die "Unknown format specification '$_[1]'\n"
         unless $_[1] =~ m#^(?:plain|raw|xml)$#;
        $format = $_[1];
    }
    $format;
} #format

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new encoding setting
# OUT: 1 current encoding setting

sub encoding {

# Set if a new setting is specified
# Return current setting

    $encoding = $_[1] if @_ == 2;
    $encoding;
} #encoding

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new output destination
# OUT: 1 current output destination

sub output {

# If we have a new output specification
#  Die now if we're not in the base thread
#  Set the new output
# Return whatever is the current output

    if (@_ > 1) {
        die "Can only set output destination from the base thread\n"
         if threads->tid != $base_tid;
        $output = $_[1];
    }
    $output;
} #output

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new callers setting
# OUT: 1 current callers setting

sub callers {

# If a new setting is specified
#  Die now if invalid parameter
#  Set new parameter
# Return current setting

    if (@_ == 2) {
        die "Invalid parameter $_[1] to callers\n" unless $_[1] =~ m#^\d+$#;
        $callers = $_[1];
    }
    $callers;
} #callers

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new shorten setting
# OUT: 1 current shorten setting

sub shorten {

# Set if a new setting is specified
# Return current setting

    $shorten = $_[1] if @_ == 2;
    $shorten;
} #shorten

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new signal to initiate status sweep (default: no change)
# OUT: 1 current signal to initiate status sweep

sub signal {

# If we have a new signal specification
#  Die now if we're monitoring already
#  Die now if we're not in the base thread
#  Set the local informational copy of the signal
# Return whatever is the current sweep signal

    if (@_ > 1) {
        die "Can only change signal before monitoring has started\n"
         if $monitor_tid;
        die "Can only set signal from the base thread\n"
	 if threads->tid != $base_tid;
        $signal = $_[1];
    }
    $signal;
} #signal

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 flag: whether to let the world know the process ID (internal only)

sub start {

# Die now if we're already monitoring
# Die now if we're not in the base thread

    die "Can only start status monitoring once\n" if $monitor_pid;
    die "Can only start status monitoring in base thread\n"
     if threads->tid != $base_tid;

# Die now if we don't have a signal
# Register the signal
# Make all threads do it automatically

    die "Must have a signal to be able to monitor status\n" unless $signal;
    Thread::Signal->register( $signal => \&_sweep );
    Thread::Signal->automatic( $signal );

# Indicate we're running
# Reset monitor pid
# Create a new thread and save its thread id
#  While monitoring is active (allows stopping, or resetting automatic time)
#   Make sure we eval, so that we can die out of this loop
#    Loop forever (dieing is the only way out)
#     Sleep for the amount that we need to do until the next dump
#     Do a dump if we're actually monitoring automatically
# Wait until the process id of the monitoring thread is set

    $running = 1;
    $monitor_pid = 0;
    $monitor_tid = threads->new( sub {
        while ($running) {
            eval {
                while (1) {
                    sleep( $every || 3600 );
                    _sweep() if $every;
                }
            }
        }
    } )->tid;
    threads->yield until $monitor_pid = $Thread::Signal::pid{$monitor_tid};

# If we're to show how
#  Obtain the pid of the monitoring thread
#  Show what we need to do to get a status report

    if ($_[1]) {
        warn $every ? <<EOD1 : <<EOD2;
Thread::Status: $format report every $every seconds to "$output"
EOD1
Thread::Status: 'kill -$signal $monitor_pid' for $format report to "$output"
EOD2
    }
} #start

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)

sub report {

# Die now if we're in the wrong thread

    die "Can only report from base thread\n" if threads->tid != $base_tid;

# Initialize reference to stuff hash
# Make sure we're the only one dumping
# Set flag that we want a dump
# Wake up the monitoring thread
# Wait for it to finish

    my %stuff;
    {lock( $dump );
     $dump = 1;
     kill $signal,$monitor_pid;
     threads::shared::cond_wait( $dump );

# For all of the threads that we have in the dump
#  Split into thread ID and the info of that thread
#  Save it in the local hash
# Reset the dump flag
# Perform an ordinary report and return if called in void context

     foreach my $thread (split( "\0",$dump )) {
         my ($tid,$info) = split( "\n",$thread,2 );
         $stuff{$tid} = $info;
     }
     $dump = 0;
    } #$dump
    return _report( \%stuff ) unless defined(wantarray);

# For all of the threads for which we have information
#  Convert the info to a list ref of list refs
# Return the reference to the converted structure

    foreach my $tid (keys %stuff) {
        $stuff{$tid} = [map {[split( '|' )]} split( "\n",$stuff{$tid})];
    }
    return \%stuff;
} #report

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)

sub stop {

# Die now if we're in the wrong thread
# If monitoring already stopped
#  Warn
#  And stop doing anything here

    die "Can only stop status monitoring from base thread\n"
     if threads->tid != $base_tid;
    unless ($running) {
        warn "Already stopped monitoring\n";
	return;
    }

# Set to stop running
# Save the thread id of the monitoring thread
# Signal the monitoring thread to stop
# Wait for the thread to actually finish

    $running = 0;
    my $tid = $monitor_tid;
    kill $signal,$monitor_pid;
    threads->object( $tid )->join;
} #stop

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
# OUT: 1 thread id of monitor thread

sub monitor_tid { $monitor_tid } #monitor_tid

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
# OUT: 1 process id of monitor thread

sub monitor_pid { $monitor_pid } #monitor_pid

#---------------------------------------------------------------------------

# standard Perl features

#---------------------------------------------------------------------------
#  IN: 1 class
#      2..N parameter hash

sub import {

# Obtain the class
# Die now if number of parameters incorrect

    my $class = shift;
    die qq(Thread::Status: Wrong number of parameters at startup: @_!\n)
     unless @_ % 2 == 0;

# Get the parameter hash
# For all of the methods and values
#  Die now if invalid method
#  Call the method with the value

    my %param = @_;
    while (my ($method,$value) = each( %param )) {
        die "Cannot call method $method during initialization\n" unless $method
	 =~ m#^(?:callers|every|encoding|format|output|shorten|signal)$#;
        $class->$method( $value );
    }

# Start monitoring now if not monitoring yet (show how if from command line)

    $class->start( (caller())[2] == 0 ) unless $monitor_tid;
} #import

#---------------------------------------------------------------------------

# internal subroutines

#---------------------------------------------------------------------------

sub _remember {

# Initialize the caller information
# Initialize the level from which we're getting information
# Save the thread id of this thread if not set yet
# While there is caller information to be obtained
#  Ignore stuff that is caused by hijacks
#  Make something sensible out of the cond_wait() hijack
#  Save the info in the order we want

    my @caller;
    my $level = shift;
    $tid = threads->tid unless defined( $tid );
    while (my @level = caller($level++)) {
        next if $level[0] =~ m#^Thread::S(?:ignal|tatus)#;
        $level[3] = 'threads::shared::cond_wait'
	 if $level[3] eq 'Thread::Status::__ANON__';
        push( @caller,join( '|',$tid,@level ) );
    }

# Save the caller info of this thread
# Append any info we have from before this thread was started
# Save that into the shared hash

    my $info = join( "\n",@caller );
    $info .= "\n$Thread::Signal::caller{$tid}" if $Thread::Signal::caller{$tid};
    $info{$tid} = $info;
} #_remember

#---------------------------------------------------------------------------
#  IN: 1 reference to hash with stuff

sub _report {

# Obtain the reference to the hash
# Obtain the handle to write to
# Output the raw format if so requested

    my $stuff = shift;
    my $handle = _handle( $output );
    return print {$handle} _raw( $stuff ) if $format eq 'raw';

# For all of the threads
#  Split the info of a thread
#  Only keep the number of callers we want
#  For all of the lines left
#   Split the fields of a line into an array
#   Remove autosplit reference if needed
#   Shorten package names if so required
#   Set reference to this array for this line in this thread
#  Save reference to these lines as info for this thread

    foreach my $tid (keys %$stuff) {
        my @line = split( "\n",$stuff->{$tid} );
        @line = @line[0..$callers] if $#line > $callers;
        foreach (@line) {
            my @field = split( '\|' );
            $field[2] =~ s# \(autosplit(?:[^)]+)\)##;
            $field[2] =~ s#$paths## if $shorten;
            $_ = \@field;
        }
        $stuff->{$tid} = \@line;
    }

# Allow for naughty things
# Call the appropriate format routine and print its result

    no strict 'refs';
    print $handle "_$format"->( $stuff );
} #_report

#---------------------------------------------------------------------------
#  IN: 1 reference to hash with stuff
# OUT: 1 data for report

sub _raw {

# Obtain the reference to the hash
# Initialize the report
# For all of the threads in the stuff
#  Add it to the report
# Return final report

    my $stuff = shift;
    my $report = '';
    foreach (sort {$a <=> $b} keys %$stuff) {
        $report .= "$_: $stuff->{$_}\n\n";
    }
    $report;
} #_raw

#---------------------------------------------------------------------------
#  IN: 1 reference to hash with stuff

sub _plain {

# Obtain the reference to the hash
# Initialize report to be generated

    my $stuff = shift;
    my $report = '';

# For all of the threads of which we have information
#  Initialize the offset
#  Save the thread id that we last handled

    foreach my $tid (sort {$a <=> $b} keys %$stuff) {
        my $offset = '';
        my $lasttid = $tid;

#  For all of the lines of caller information
#   If the info is from another thread
#    Save the thread id
#    Make sure following lines are moved to the right
#   Obtain the subroutine info
#   Reset info if it is in an eval
#   Add the info for this caller info
#  Add an extra seperator for the next originating thread

        foreach my $line (@{$stuff->{$tid}}) {
            if ($line->[0] != $lasttid) {
                $lasttid = $line->[0];
                $offset .= '  '
            }
            my $sub = $line->[4];
            $sub = $sub eq '(eval)' ? '' : "$sub in ";
            $report .= "$offset$line->[0]: line $line->[3] in $line->[2] ($sub$line->[1])\n";
        }
        $report .= "\n";
    }

# Return final report

    $report;
} #_plain

#---------------------------------------------------------------------------
#  IN: 1 output specification
#      2 open mode (default: '>')
# OUT: 1 opened handle

sub _handle {

# Obtain the output specification
# Obtain open mode
# Initialize handle to write to

    my $filename = shift;
    my $mode = shift || '>';
    my $handle;

# If we have the default value
#  Set to write to standard error
# Elseif we just want to print
#  Set to write to standard output

    if ($filename eq 'STDERR') {
        $handle = *STDERR;
    } elsif ($filename eq 'STDOUT') {
        $handle = *STDOUT;

# Elseif successful in opening it as a file (no action)
# Else (not successful in opening file)
#  Set to use standard error
#  And let the world know why

    } elsif (open( $handle,$mode,$filename )) {
    } else {
        $handle = *STDERR;
	print $handle <<EOD;
Could not report to $filename ($!)
Writing to STDERR instead
EOD
    }

# Return the resulting handle

    $handle;
} #_handle

#---------------------------------------------------------------------------

__END__

=head1 NAME

Thread::Status - report stack status of all running threads

=head1 SYNOPSIS

  perl -MThread::Status program # send SIGHUP for standard report to STDERR

  use Thread::Status;           # start monitoring using default settings

  use Thread::Status
   every   => 1,                # defaults to every 5 seconds
   callers => 4,                # defaults to 0
   shorten => 0,                # defaults to 1
   format  => 'xml',	        # defaults to 'plain'
   output  => 'filename',       # defaults to STDERR
   signal  => 'HUP',            # default
  ;                             # starts monitoring automatically

  use Thread::Status ();                # don't start anything yet

  Thread::Status->every( 1 );           # every second
  Thread::Status->every( 0 );           # disable, must signal manually
  $every = Thread::Status->every;

  Thread::Status->callers( 0 );         # default, show no caller lines
  Thread::Status->callers( 4 );         # show 4 caller lines
  $callers = Thread::Status->callers;

  Thread::Status->shorten( 1 );         # default: shorten package names
  Thread::Status->shorten( 0 );         # do not shorten package names
  $shorten = Thread::Status->shorten;

  Thread::Status->output( 'filename' );
  $output = Thread::Status->output;

  Thread::Status->format( 'plain' );    # default
  Thread::Status->format( 'xml' );      # report in XML format
  $format = Thread::Status->format;

  Thread::Status->encoding('iso-latin-1'); # only needed for XML format
  $encoding = Thread::Status->encoding;

  Thread::Status->signal( 'USR1' );     # only once, before monitoring starts
  $signal = Thread::Status->signal;

  Thread::Status->start;                # starts monitoring

  Thread::Status->report;               # status in format to output desired
  $report = Thread::Status->report;     # hash reference with all information

  Thread::Status->stop;                 # stops monitoring

  $tid = Thread::Status->monitor_tid;   # thread id of monitoring thread
  $pid = Thread::Status->monitor_pid;   # process id of monitoring thread

=head1 DESCRIPTION

                  *** A note of CAUTION ***

 This module only functions on Perl versions 5.8.0 and later.
 And then only when threads are enabled with -Dusethreads.  It
 is of no use with any version of Perl before 5.8.0 or without
 threads enabled.

                  *************************

The Thread::Status module is mainly intended as a debugging aid for developers
of threaded programs.  It can generate a report of where processing is
occurring in all available threads, either automatically every X seconds, or
by the application of an external signal, or under program control.

The good thing is that you do B<not> need to change your program in any way.
By a smart use of signals, the code running in each thread is interrupted to
report its status.  And that is immediately the bad news: signals in threads
currently B<only work under Linux>.

To get a status report sent to STDERR every 5 seconds, simply add:

 -MThread::Status

to the command line.  So, if you would call your program with:

 perl yourprogram parameters

then

 perl -MThread::Status yourprogram parameters

will report the status of all the thread every 5 seconds on STDERR.

If you would like to have e.g. the output appear in a file with e.g. two levels
of caller information, you can specify the parameters on the command line as
well:

 perl -MThread::Status=output,filename,callers,2 yourprogram parameters

A typical output would be:

 0: line 19 in test1 (main)
 0: line 23 in test1 (main::run_the_threads in main)

 2: line 15 in test1 (main)
   0: line 17 in test1 (threads::new in main)
   0: line 23 in test1 (main::run_the_threads in main)

 3: line 11 in test1 (main)
   2: line 13 in test1 (threads::new in main)
     0: line 17 in test1 (threads::new in main)

=head1 CLASS METHODS

These are the class methods.

=head2 every

 Thread::Status->every( 5 );         # default, report every 5 seconds

 Thread::Status->every( 0 );         # do not create reports automatically

 $every = Thread::Status->every;

The "every" class method sets and returns the number of seconds that will pass
before the next report is automatically generated.  By default a report will
be created every B<5> seconds.  The value B<0> can be used to indicate that
no automatic reports should be generated.

=head2 callers

 Thread::Status->callers( 0 );       # default, return no caller lines
 
 Thread::Status->callers( 4 );       # return 4 callers

 $callers = Thread::Status->callers;

The "callers" class method sets and returns the number of callers that should
be shown in the report.  By default, no callers will be shown.

=head2 shorten

 Thread::Status->shorten( 1 );       # default, shorten
 
 Thread::Status->shorten( 0 );       # do not shorten package names

 $shorten = Thread::Status->shorten;

The "shorten" class method sets and returns whether package names should be
shortened in the report.  By default, package names will be shortened, to
create a more readable report.

=head2 format

 Thread::Status->format( 'plain' );  # default, make plain text report

 Thread::Status->format( 'xml' );    # make xml report

 $format = Thread::Status->format;

The "format" class method sets and returns the format in which the report
will be generated.  By default, the report will be created in plain text.
If you select 'xml', you may want to change the L<encoding> setting of the
XML that will be generated.

=head2 encoding

 Thread::Status->encoding( 'iso-latin-1' );  # default

 $encoding = Thread::Status->encoding;

The "encoding" class method sets and returns the encoding in which the report
will be generated if B<xml> was selected as the L<format>.  By default, the
report will be created in 'ISO-Latin-1' encoding.

=head2 output

 Thread::Status->output( 'filename' );  # write to specific file

 $output = Thread::Status->output;      # obtain current setting

The "output" class method returns the current output setting for the thread
report.  It can also be used to set the name of the file to which the report
will be written.  The strings "STDOUT" and "STDERR" can be used to indicate
standard output and standard error respectively.

=head2 signal

 Thread::Status->signal( 'HUP' );       # default

 $signal = Thread::Status->signal;      # obtain current setting

The "signal" class method sets and returns the signal that will be used
internally (and possibly externally if no automatic reports are generated).
By default the B<HUP> signal will be used.

Please note that the signal can B<only> be changed if monitoring has not yet
started.

=head2 start

 Thread::Status->start;

The "start" class method starts the thread that will perform the status
monitoring.  It can only be called once (or again after method L<stop> was
called).  Reports will be generated automatically depending on values
previously set with methods L<every>, L<callers>, L<shorten>, L<output>,
L<format> and L<encoding>.

=head2 report

 Thread::Status->report;

 $report = Thread::Status->report;

The "report" class method can be called in two ways:

=over 2

=item in void context

Generates a status report depending on values previously set with methods
L<every>, L<callers>, L<shorten>, L<output>, L<format> and L<encoding>.

=item in scalar context

Creates a data-structure of the status of all of the threads and returns a
reference to it.  The data-structure has the following format:

 - hash, keyed to thread id, filled with
 -  a reference to a list for each of the callers, in which element is
 -   a reference to a list with thread id and all of the fields of caller()

so that:

 foreach my $tid (sort {$a <=> $b} keys %{$report}) {
   print "Thread $tid:\n";
   my $level = 0;
   foreach my $level (@{$report->{$tid}}) {
     print "  Level $level: $level->[2], line $level->[3]\n";
   }
 }

will give you an overview of the status.

=head2 stop

The "stop" class method stops the thread that performs the status monitoring.
It can only be called after method L<start> has been called.

=head2 monitor_tid

 $tid = Thread::Status->monitor_tid;

The "monitor_tid" class method returns the thread id of the thread that
performs the status monitoring.

=head2 monitor_pid

 $pid = Thread::Status->monitor_pid;

The "monitor_pid" class method returns the process id of the thread that
performs the status monitoring.

=head1 OPTIMIZATIONS

This module uses L<load> to reduce memory and CPU usage. This causes
subroutines only to be compiled in a thread when they are actually needed at
the expense of more CPU when they need to be compiled.  Simple benchmarks
however revealed that the overhead of the compiling single routines is not
much more (and sometimes a lot less) than the overhead of cloning a Perl
interpreter with a lot of subroutines pre-loaded.

=head1 CAVEATS

This module relies on the L<Thread::Signal> module.  There are currently a
number of limitations when using the Thread::Signal module.  Check the CAVEATS
section of that module for up-to-date information.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2002-2003 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<AutoLoader>, L<Thread::Signal>.

=cut
