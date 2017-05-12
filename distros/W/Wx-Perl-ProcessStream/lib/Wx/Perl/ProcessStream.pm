#############################################################################
## Name:        Wx/Perl/ProcessStream.pm
## Purpose:     capture async process STDOUT/STDERR
## Author:      Mark Dootson
## Modified by:
## Created:     11/05/2007
## Copyright:   (c) 2007-2010 Mark Dootson
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::Perl::ProcessStream;

our $VERSION = '0.32';

=head1 NAME

Wx::Perl::ProcessStream - access IO of external processes via events

=head1 VERSION

Version 0.32

=head1 SYNOPSYS

    use Wx::Perl::ProcessStream qw( :everything );
    
    EVT_WXP_PROCESS_STREAM_STDOUT    ( $self, \&evt_process_stdout );
    EVT_WXP_PROCESS_STREAM_STDERR    ( $self, \&evt_process_stderr );
    EVT_WXP_PROCESS_STREAM_EXIT      ( $self, \&evt_process_exit   );
    EVT_WXP_PROCESS_STREAM_MAXLINES  ( $self, \&evt_process_maxlines  );
    
    my $proc1 = Wx::Perl::ProcessStream::Process->new('perl -e"print qq($_\n) for(@INC);"', 'MyName1', $self);
    $proc1->Run;
    
    my $command = 'executable.exe parm1 parm2 parm3'
    my $proc2 = Wx::Perl::ProcessStream::Process->new($command, 'MyName2', $self)
                                                ->Run;
                                                
    my @args = qw( executable.exe parm1 parm2 parm3 );
    my $proc3 = Wx::Perl::ProcessStream::Process->new(\@args, 'MyName2', $self);
    $proc3->Run;
    
    my $proc4 = Wx::Perl::ProcessStream::Process->new(\@args, 'MyName2', $self, 'readline')->Run;
    
    my $proc5 = Wx::Perl::ProcessStream::Process->new(\@args, 'MyName2', $self);
        
    sub evt_process_stdout {
        my ($self, $event) = @_;
        $event->Skip(1);
        my $process = $event->GetProcess;
        my $line = $event->GetLine;
        
        if($line eq 'something we are waiting for') {
            $process->WriteProcess('a message to stdin');
            
            $process->CloseInput() if($finishedwriting);
        }
        ............
        # To Clear Buffer
        my @buffers = @{ $process->GetStdOutBuffer };
        
    }
    
    sub evt_process_stderr {
        my ($self, $event) = @_;
        $event->Skip(1);
        my $process = $event->GetProcess;
        my $line = $event->GetLine;
        print STDERR qq($line\n);
        # To Clear Buffer
        my @errors = @{ $process->GetStdErrBuffer };
    }
    
    sub evt_process_exit {
        my ($self, $event) = @_;
        $event->Skip(1);
        my $process = $event->GetProcess;
        my $line = $event->GetLine;
        my @buffers = @{ $process->GetStdOutBuffer };
        my @errors = @{ $process->GetStdErrBuffer };
        my $exitcode = $process->GetExitCode;
        ............
        $process->Destroy;
    }
    
    sub evt_process_maxlines {
        my ($self, $event) = @_;
        my $process = $event->GetProcess;
        
        ..... bad process
        
        $process->Kill;
    }
    

=head1 DESCRIPTION

This module provides the STDOUT, STDERR and exit codes of asynchronously running processes via events.
It may be used for long running or blocking processes that provide periodic updates on state via STDOUT. Simple IPC is possible via STDIN.

Do not use this module simply to collect the output of another process. For that, it is much simpler to do:

    my ($status, $output) = Wx::ExecuteStdout( 'perl -e"print qq($_\n) for(@INC);"' );


=head2 Wx::Perl::ProcessStream::Process

=head3 Methods

=over 12

=item new

Create a new Wx::Perl::ProcessStream::Process object. You must then use the Run method to execute
your command.

    my $process = Wx::Perl::ProcessStream::Process->new($command, $name, $eventhandler, $readmethod);

    $command      = command text (and parameters) you wish to run. You may also pass a
                    reference to an array containing the command and parameters.
    $name         = an arbitray name for the process.
    $eventhandler = the Wx EventHandler (Wx:Window) that will handle events for this process.
    $readmethod   = 'read' or 'readline' (default = 'readline') an optional param. From Wx version
                    0.75 you can specify the method you wish to use to read the output of an
                    external process.
                    The default depends on your Wx version ( 'getc' < 0.75,'readline' >= 0.75) 
                    read       -- uses the Wx::InputStream->READ method to read bytes. 
                    readline   -- uses the Wx::InputStream->READLINE method to read bytes
                    getc       -- alias for read (getc not actually used)

=item SetMaxLines

Set the maximum number of lines that will be read from a continuous stream before raising a
EVT_WXP_PROCESS_STREAM_MAXLINES event. The default is 1000. A continuous stream will cause
your application to hang.

    $process->SetMaxLines(10);

=item Run

Run the process with the parameters passed to new. On success, returns the process object itself.
This allows you to do: my $process = Wx::Perl::ProcessStream->new($command, $name, $self)->Run;
Returns undef if the process could not be started.

    my $process = Wx::Perl::ProcessStream::Process->new($command, $name, $eventhandler, $readmethod);
    $process->Run;    

=item CloseInput

Close the STDIN stream of the external process. (Some processes may not close until STDIN is closed.)

    $process->CloseInput();

=item GetAppCloseAction

Returns the current process signal that will used on application exit. Either wxpSIGTERM or wxpSIGKILL.
See SetAppCloseAction.

    my $action = $process->GetAppCloseAction();

=item GetExitCode

Returns the process exit code. It is undefined until a wxpEVT_PROCESS_STREAM_EXIT event has been received.

    my $exitcode = $process->GetExitCode();

=item GetProcessName

Returns the process name as passed to the OpenProcess constructor.

    my $processname = $process->GetProcessName();

=item GetStdErrBuffer

This returns a reference to an array containing all the lines sent by the process to stderr.
Calling this clears the process object internal stderr buffer.
(This has no effect on the actual process I/O buffers.)

    my $arryref = $process->GetStdErrBuffer();

=item GetStdOutBuffer

This returns a reference to an array containing all the lines sent by the process to stdout.
Calling this clears the process object internal stdout buffer.
(This has no effect on the actual process I/O buffers.)

    my $arryref = $process->GetStdOutBuffer();

=item GetStdErrBufferLineCount

This returns the number of lines currently in the stderr buffer.

    my $count = $process->GetStdErrBufferLineCount();

=item GetStdOutBufferLineCount

This returns the number of lines currently in the stdout buffer.

    my $count = $process->GetStdOutBufferLineCount();

=item PeekStdErrBuffer

This returns a reference to an array containing all the lines sent by the process to stderr.
To retrieve the buffer and clear it, call GetStdErrBuffer instead.

    my $arryref = $process->PeekStdErrBuffer();

=item PeekStdOutBuffer

This returns a reference to an array containing all the lines sent by the process to stdout.
To retrieve the buffer and clear it, call GetStdOutBuffer instead.

    my $arryref = $process->PeekStdOutBuffer();

=item GetProcessId

Returns the process id assigned by the system.

    my $processid = $process->GetProcessId();

=item GetPid

Returns the process id assigned by the system.

    my $processid = $process->GetPid();

=item IsAlive

Check if the process still exists in the system.
Returns 1 if process exists, 0 if process does not exist. If the process has already
signalled its exit, the IsAlive method will always return 0. Therefore IsAlive should 
always return 0 (false) once a EVT_WXP_PROCESS_STREAM_EXIT event has been sent.

    my $isalive = $process->IsAlive();

=item KillProcess

Send a SIGKILL signal to the external process.

    $process->KillProcess();

=item SetAppCloseAction

When your application exits, any remaining Wx::Perl::ProcessStream::Process objects will be signaled to close.
The default signal is wxpSIGTERM but you can change this to wxpSIGKILL if you are sure this is what you want.

    $process->SetAppCloseAction( $newaction );

    $newaction = one of wxpSIGTERM, wxpSIGKILL

=item TerminateProcess

Send a SIGTERM signal to the external process.

    $process->TerminateProcess();

=item WriteProcess

Write to the STDIN of process.

    $process->WriteProcess( $writedata . "\n" );

    $writedata = The data you wish to write. Remember to add any appropriate line endings your external process may expect.

=back

=head2 Wx::Perl::ProcessStream


=head3 Methods


=over 12

=item OpenProcess

Run an external process. DEPRECATED - use Wx::Perl::ProcessStream::Process->new()->Run;
If the process is launched successfully, returns a Wx::Perl::ProcessStream::Process object.
If the process could not be launched, returns undef;

    my $process = Wx::Perl::ProcessStream->OpenProcess($command, $name, $eventhandler, $readmethod);

    $command      = command text (and parameters) you wish to run. You may also pass a
                    reference to an array containing the command and parameters.
    $name         = an arbitray name for the process.
    $eventhandler = the Wx object that will handle events for this process.
    $process      = Wx::Perl::ProcessStream::Process object
    $readmethod   = 'getc' or 'readline' (default = 'readline') an optional param. From Wx version
                    0.75 you can specifiy the method you wish to use to read the output of an
                    external process. The default depends on your Wx version ( 'getc' < 0.75, 
                    'readline' >= 0.75) 
                    'getc' uses the Wx::InputStream->GetC method to read bytes. 
                    'readline', uses the wxPerl implementation of Wx::InputStream->READLINE.

If the process could not be started then zero is returned.
You should destroy each process after it has completed. You can do this after receiving the exit event.


=item GetDefaultAppCloseAction

Returns the default on application close action that will be given to new processes.
When your application exits, any remaining Wx::Perl::ProcessStream::Process objects will be signalled to close.
The default signal is wxpSIGTERM but you can change this to wxpSIGKILL if you are sure this is what you want.
Whenever a mew process is opened, it is given the application close action returned by GetDefaultAppCloseAction.
You can also set the application close action at an individual process level.

    my $def-action = Wx::Perl::ProcessStream->SetDefaultAppCloseAction();

    $def-action will be one of wxpSIGTERM or wxpSIGKILL; (default wxpSIGTERM)


=item SetDefaultAppCloseAction

Sets the default on application close action that will be given to new processes.
See GetDefaultAppCloseAction.

    Wx::Perl::ProcessStream->SetDefaultAppCloseAction( $newdefaction );

    $newdefaction = one of wxpSIGTERM or wxpSIGKILL

=item SetDefaultMaxLines

Sets the default maximum number of lines that will be processed continuously from
an individual process. If a process produces a continuous stream of output, this would
hang your application. This setting provides a maximum number of lines that will be
read from the process streams before control is yielded and the events can be processed.
Additionally, a EVT_WXP_PROCESS_STREAM_MAXLINES event will be sent to the eventhandler.
The setting can also be set on an individual process basis using $process->SetMaxLines

    Wx::Perl::ProcessStream->SetDefaultMaxLines( $maxlines );
    
    the default maxlines number is 1000

=item GetPollInterval

Get the current polling interval. See SetPollInterval.

    $milliseconds = Wx::Perl::ProcessStream->GetPollInterval();

=item SetPollInterval

When all buffers are empty but there are still running external process, the module will pause before polling the processes again for output.
By default, the module waits for 500 milliseconds. You can set the value of this polling intrval with this method.
Internally, a Wx::Timer object is used to handle polling and the value you set here is passed directly to that.
The precision of the intervals is OS dependent.

    Wx::Perl::ProcessStream->SetPollInterval( $milliseconds );

    $milliseconds = number of milliseconds to wait when no buffer activity

=back

=head2 Wx::Perl::ProcessStream::ProcessEvent

A Wx::Perl::ProcessStream::ProcessEvent is sent whenever an external process started with OpenProcess writes to STDOUT, STDERR or when the process exits.


=head3 Event Connectors

=over 12

=item EVT_WXP_PROCESS_STREAM_STDOUT

Install an event handler for an event of type wxpEVT_PROCESS_STREAM_STDOUT exported on request by this module.
The event subroutine will receive a Wx::Perl::ProcessStream::ProcessEvent for every line written to STDOUT by the external process.

    EVT_WXP_PROCESS_STREAM_STDOUT( $eventhandler, $codref );

=item EVT_WXP_PROCESS_STREAM_STDERR

Install an event handler for an event of type wxpEVT_PROCESS_STREAM_STDERR exported on request by this module.
The event subroutine will receive a Wx::Perl::ProcessStream::ProcessEvent for every line written to STDERR by the external process.

    EVT_WXP_PROCESS_STREAM_STDERR( $eventhandler, $codref );

=item EVT_WXP_PROCESS_STREAM_EXIT

Install an event handler for an event of type wxpEVT_PROCESS_STREAM_EXIT exported on request by this module.
The event subroutine will receive a Wx::Perl::ProcessStream::ProcessEvent when the external process exits.

    EVT_WXP_PROCESS_STREAM_EXIT( $eventhandler, $codref );

=item EVT_WXP_PROCESS_STREAM_MAXLINES

Install an event handler for an event of type wxpEVT_PROCESS_STREAM_MAXLINES exported on request by this module.
The event subroutine will receive a Wx::Perl::ProcessStream::ProcessEvent when the external process produces
a continuous stream of lines on stderr and stdout that exceed the max lines set via $process->SetMaxLines or
Wx::Perl::ProcessStream->SetDefaultMaxLines.

    EVT_WXP_PROCESS_STREAM_MAXLINES( $eventhandler, $codref );

=back

=head3 Methods

=over 12

=item GetLine

For events of type wxpEVT_PROCESS_STREAM_STDOUT and wxpEVT_PROCESS_STREAM_STDERR this will return the line written by the process.

=item GetProcess

This returns the process that raised the event. If this is a wxpEVT_PROCESS_STREAM_EXIT event you should destroy the process with $process->Destroy; 

=back

=head1 COPYRIGHT & LICENSE

Copyright (C) 2007-2010 Mark Dootson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

Thanks to Johan Vromans for testing and suggesting a better interface.

=head1 AUTHOR

Mark Dootson, C<< <mdootson at cpan.org> >>

=head1 SEE ALSO

The distribution includes examples in the 'example' folder.
From the source root, run

    perl -Ilib example/psexample.pl

You can enter commands, execute them and view results.

You may also wish to consult the wxWidgets manuals for:

Wx::Process

Wx::Execute

Wx::ExecuteArgs

Wx::ExecuteCommand

Wx::ExecuteStdout 

Wx::ExecuteStdoutStderr

=cut

#-----------------------------------------------------
# PACKAGE Wx::Perl::ProcessStream
#-----------------------------------------------------

package Wx::Perl::ProcessStream;
use strict;
use Wx 0.50 qw( wxEXEC_ASYNC wxSIGTERM wxSIGKILL);
require Exporter;
use base qw(Exporter);
use Wx::Perl::Carp;

#-----------------------------------------------------
# check wxWidgets version
#-----------------------------------------------------
if( Wx::wxVERSION() < 2.0060025) {
    croak qq(Wx $Wx::VERSION compiled with $Wx::wxVERSION_STRING.\n\nMinimum wxWidgets version 2.6.3 required for Wx::Perl::ProcessStream $VERSION);
}

#-----------------------------------------------------
# initialise
#-----------------------------------------------------

our ($ID_CMD_EXIT, $ID_CMD_STDOUT, $ID_CMD_STDERR, $ID_CMD_MAXLINES,
     $WXP_DEFAULT_CLOSE_ACTION, $WXP_DEFAULT_MAX_LINES, $WXPDEBUG);

$ID_CMD_EXIT   = Wx::NewEventType();
$ID_CMD_STDOUT = Wx::NewEventType();
$ID_CMD_STDERR = Wx::NewEventType();
$ID_CMD_MAXLINES = Wx::NewEventType();

$WXP_DEFAULT_CLOSE_ACTION = wxSIGTERM;
$WXP_DEFAULT_MAX_LINES = 1000;

our @EXPORT_OK = qw( wxpEVT_PROCESS_STREAM_EXIT
                     wxpEVT_PROCESS_STREAM_STDERR
                     wxpEVT_PROCESS_STREAM_STDOUT
                     wxpEVT_PROCESS_STREAM_MAXLINES
                     EVT_WXP_PROCESS_STREAM_STDOUT
                     EVT_WXP_PROCESS_STREAM_STDERR
                     EVT_WXP_PROCESS_STREAM_EXIT
                     EVT_WXP_PROCESS_STREAM_MAXLINES
                     wxpSIGTERM
                     wxpSIGKILL
                    );
                    
our %EXPORT_TAGS = ();

$EXPORT_TAGS{'everything'} = \@EXPORT_OK;
$EXPORT_TAGS{'all'} = \@EXPORT_OK;

our $ProcHandler = Wx::Perl::ProcessStream::ProcessHandler->new();

sub wxpEVT_PROCESS_STREAM_EXIT     () { $ID_CMD_EXIT }
sub wxpEVT_PROCESS_STREAM_STDERR   () { $ID_CMD_STDERR }
sub wxpEVT_PROCESS_STREAM_STDOUT   () { $ID_CMD_STDOUT }
sub wxpEVT_PROCESS_STREAM_MAXLINES () { $ID_CMD_MAXLINES }
sub wxpSIGTERM () { wxSIGTERM }
sub wxpSIGKILL () { wxSIGKILL }

sub EVT_WXP_PROCESS_STREAM_STDOUT   ($$) { $_[0]->Connect(-1,-1,&wxpEVT_PROCESS_STREAM_STDOUT, $_[1] ) };
sub EVT_WXP_PROCESS_STREAM_STDERR   ($$) { $_[0]->Connect(-1,-1,&wxpEVT_PROCESS_STREAM_STDERR, $_[1] ) };
sub EVT_WXP_PROCESS_STREAM_EXIT     ($$) { $_[0]->Connect(-1,-1,&wxpEVT_PROCESS_STREAM_EXIT,   $_[1] ) };
sub EVT_WXP_PROCESS_STREAM_MAXLINES ($$) { $_[0]->Connect(-1,-1,&wxpEVT_PROCESS_STREAM_MAXLINES,   $_[1] ) };

sub Yield { Wx::YieldIfNeeded; }

# Old interface - call Wx::Perl::ProcessStream::new

sub OpenProcess {
    my $class = shift;
    my( $command, $procname, $handler, $readmethod ) = @_;
    my $process = Wx::Perl::ProcessStream::Process->new( $command, $procname, $handler, $readmethod );
    return ( $process->Run ) ? $process : undef;
}

sub SetDefaultAppCloseAction {
    my $class = shift;
    my $newaction = shift;
    $WXP_DEFAULT_CLOSE_ACTION = ($newaction == wxSIGTERM||wxSIGKILL) ?  $newaction : $WXP_DEFAULT_CLOSE_ACTION;
}

sub GetDefaultAppCloseAction { $WXP_DEFAULT_CLOSE_ACTION; }

sub SetDefaultMaxLines {
    my $class = shift;
    $WXP_DEFAULT_MAX_LINES = shift || 1;
}

sub GetDefaultMaxLines { $WXP_DEFAULT_MAX_LINES; }

sub GetPollInterval {
    $ProcHandler->GetInterval();
}

sub SetPollInterval {
    my ($class, $interval) = @_;
    $ProcHandler->_set_poll_interval($interval);
}

sub ProcessCount { $ProcHandler->ProcessCount; }
    

#-----------------------------------------------------
# PACKAGE Wx::Perl::ProcessStream::ProcessHandler;
#
# Inherits from timer and cycles througn running
# processes raising events for STDOUT/STDERR/EXIT
#-----------------------------------------------------

package Wx::Perl::ProcessStream::ProcessHandler;
use strict;
use Wx qw( wxSIGTERM wxSIGKILL);
use base qw( Wx::Timer );
use Wx::Perl::Carp;

sub DESTROY {
    my $self = shift;
    
    ## clear any live procs
    for my $process (@{ $self->{_procs} }) {
        my $procid = $process->GetProcessId() if($process->IsAlive());
        $process->Detach;
        Wx::Process::Kill($procid, $process->GetAppCloseAction());
    }       
    $self->SUPER::DESTROY if $self->can("SUPER::DESTROY");
    
}

sub new {
    my $self = shift->SUPER::new(@_);
    $self->{_procs} = [];
    $self->{_pollinterval} = 500;
    return $self;
}

sub _set_poll_interval {
    my $self = shift;
    $self->{_pollinterval} = shift;
    if($self->IsRunning()) {
        $self->Stop();
        $self->Start( $self->{_pollinterval} );
    }
}

sub Notify {
    my ($self ) = @_;
    return 1 if($self->{_notify_in_progress}); # do not re-enter notify proc
    $self->{_notify_in_progress} = 1;
    
    my $continueprocessloop = 1;
    my $eventscreated = 0;
    
    while( $continueprocessloop  ) {
    
        $continueprocessloop = 0;
        
        my @checkprocs = @{ $self->{_procs} };
        
        for my $process (@checkprocs) {
            
            # process inout actions
            while( my $action = shift( @{ $process->{_await_actions} }) ) {
                
                $continueprocessloop ++;
                
                if( $action->{action} eq 'terminate' ) {
                    $process->CloseOutput() if( defined(my $handle = $process->GetOutputStream() ) );
                    Wx::Process::Kill($process->GetProcessId(), wxSIGTERM);
      
                }elsif( $action->{action} eq 'kill' ) {
                    $process->CloseOutput() if( defined(my $handle = $process->GetOutputStream() ) );
                    Wx::Process::Kill($process->GetProcessId(), wxSIGKILL);
                    
                }elsif( $action->{action} eq 'closeinput') {
                    $process->CloseOutput() if( defined(my $handle = $process->GetOutputStream() ) );
                    
                } elsif( $action->{action} eq 'write') {
                    if(defined( my $fh = $process->GetOutputStream() )) {
                        print $fh $action->{writedata};
                    }
                }    
            }
            
            my $procexitcode = $process->GetExitCode;
            my $linedataread = 0;
            my $maxlinecount = $process->GetMaxLines;
            $maxlinecount = 1 if $maxlinecount < 1; 
            if(!$process->_exit_event_posted) {
            
                # STDERR
                while( ( my $linebuffer = $process->__read_error_line ) ){
                    $continueprocessloop ++;
                    $linedataread ++;
                    $linebuffer =~ s/(\r\n|\n)$//;
                    my $event = Wx::Perl::ProcessStream::ProcessEvent->new( &Wx::Perl::ProcessStream::wxpEVT_PROCESS_STREAM_STDERR, -1 );
                    push(@{ $process->{_stderr_buffer} }, $linebuffer);
                    $event->SetLine( $linebuffer );
                    $event->SetProcess( $process );
                    $process->__get_handler()->AddPendingEvent($event);
                    $eventscreated ++;
                    last if $linedataread == $maxlinecount;
                }


                # STDOUT
                if( $linedataread < $maxlinecount ) {
                    while( ( my $linebuffer = $process->__read_input_line ) ){  
                        $continueprocessloop ++;
                        $linedataread ++;
                        $linebuffer =~ s/(\r\n|\n)$//;
                        my $event = Wx::Perl::ProcessStream::ProcessEvent->new( &Wx::Perl::ProcessStream::wxpEVT_PROCESS_STREAM_STDOUT, -1 );
                        push(@{ $process->{_stdout_buffer} }, $linebuffer);
                        $event->SetLine( $linebuffer );
                        $event->SetProcess( $process );
                        $process->__get_handler()->AddPendingEvent($event);
                        $eventscreated ++;
                        last if $linedataread == $maxlinecount;
                    }
                }
            }
            
            if(defined($procexitcode) && !$linedataread) {
                # defer exit event until we think all IO buffers are empty
                # post no more events once we post exit event;
                $process->_set_exit_event_posted(1);
                my $event = Wx::Perl::ProcessStream::ProcessEvent->new( &Wx::Perl::ProcessStream::wxpEVT_PROCESS_STREAM_EXIT, -1);
                $event->SetLine( undef );
                $event->SetProcess( $process );
                $process->__get_handler()->AddPendingEvent($event);
                $eventscreated ++;
            }
            
            # raise the maxline event if required
            # this will be actioned during outer loop yield
            if($linedataread == $maxlinecount) {
                my $event = Wx::Perl::ProcessStream::ProcessEvent->new( &Wx::Perl::ProcessStream::wxpEVT_PROCESS_STREAM_MAXLINES, -1 );
                $event->SetLine( undef );
                $event->SetProcess( $process );
                $process->__get_handler()->AddPendingEvent($event);
                $eventscreated ++;
            }
            
        } # for my $process (@checkprocs) {
        
        #-----------------------------------------------------------------
        # yield to allow changes to $self->{_procs}
        # we will not exit this outer loop until $continueprocessloop == 0
        # events we have raised may not get processed in this Yield
        # Taht may not happen until the outer ->ProcessPendingEvents
        #-----------------------------------------------------------------
        
        Wx::Perl::ProcessStream::Yield();
                
    } # while( $continueprocessloop ) {
    # ProcessPendingEvents happens once per eventloop
    # Below seems to improve response AND is necessary
    # in some cases
    Wx::wxTheApp->ProcessPendingEvents if $eventscreated;
    $self->{_notify_in_progress} = 0;
    $self->Stop() unless( $self->ProcessCount  );
    return 1;
}

sub Start {
    my $self = shift;
    my @args = @_;
    $self->SUPER::Start(@args);   
}

sub Stop {
    my $self = shift;
    
    $self->SUPER::Stop();   
}

sub AddProc {
    my $self = shift;
    my $newproc = shift;
    push(@{ $self->{_procs} }, $newproc );
    $self->Start($self->{_pollinterval}) if(!$self->IsRunning());
}

sub RemoveProc {
    my($self, $proc) = @_;
    my $checkpid = $proc->GetPid;
    my @oldprocs = @{ $self->{_procs} };
    my @newprocs = ();
    for ( @oldprocs ) {
        push(@newprocs, $_) if $_->GetPid != $checkpid;
    }
    $self->{_procs} = \@newprocs;
    delete $Wx::Perl::ProcessStream::Process::_runningpids->{$checkpid};
}

sub FindProc {
    my($self, $pid) = @_;
    my $foundproc = undef;
    for ( @{ $self->{_procs} } ) {
        if ($pid == $_->GetPid) {
            $foundproc = $_;
            last;
        }
    }
    return $foundproc;
}

sub ProcessCount {
    my $self = shift;
    return scalar @{ $self->{_procs} };
}

#-----------------------------------------------------
# PACKAGE Wx::Perl::ProcessStream::Process
#
# Adds some extra methods to Wx::Process
#-----------------------------------------------------

package Wx::Perl::ProcessStream::Process;
use strict;
use Wx 0.50 qw(
    wxSIGTERM
    wxSIGKILL
    wxSIGNONE
    wxKILL_OK
    wxKILL_BAD_SIGNAL
    wxKILL_ACCESS_DENIED
    wxKILL_NO_PROCESS
    wxKILL_ERROR
    wxEXEC_ASYNC
    wxID_ANY
    wxTheApp
    );

use base qw( Wx::Process );
use Wx::Perl::Carp;
use Time::HiRes qw( sleep );

our $_runningpids = {};
our $_eventhandler = Wx::Perl::ProcessStream::ProcEvtHandler->new();

sub new {
    my ($class, $command, $procname, $handler, $readmethod) = @_;
    
    $procname   ||= 'any';
    $readmethod ||= ($Wx::VERSION > 0.74) ? 'readline' : 'read';
    
    my $self = $class->SUPER::new($_eventhandler);
    
    $self->Redirect();
    $self->SetAppCloseAction(Wx::Perl::ProcessStream->GetDefaultAppCloseAction());
    $self->SetMaxLines(Wx::Perl::ProcessStream->GetDefaultMaxLines());
    $self->{_readlineon} = ( lc($readmethod) eq 'readline' ) ? 1 : 0;
    if($self->{_readlineon} && ($Wx::VERSION < 0.75)) {
        carp('A read method of "readline" cannot be used with Wx versions < 0.75. Reverting to default "read" method');
        $readmethod = 'read';
        $self->{_readlineon} = 0;
    }
    
    print qq(read method is $readmethod\n) if($Wx::Perl::ProcessStream::WXPDEBUG);
    
    $self->__set_process_name($procname);
    $self->__set_handler($handler);
    $self->{_await_actions} = [];
    $self->{_stderr_buffer} = [];
    $self->{_stdout_buffer} = [];
    $self->{_arg_command} = $command;
    return $self;
}

sub Run {
    my $self = shift;
    
	my $command = $self->{_arg_command};
	
	my $procid = (ref $command eq 'ARRAY') 
	    ? Wx::ExecuteArgs   ( $command, wxEXEC_ASYNC, $self )
	    : Wx::ExecuteCommand( $command, wxEXEC_ASYNC, $self );
        
    if($procid) {
        $self->__set_process_id( $procid );
        $Wx::Perl::ProcessStream::ProcHandler->AddProc( $self );
        return $self;
    } else {
        $self->Destroy;
        return undef;
    }
}

sub SetMaxLines { $_[0]->{_max_read_lines} = $_[1]; }
sub GetMaxLines { $_[0]->{_max_read_lines} }

sub __read_input_line {
    my $self = shift;
    my $linebuffer;
    my $charbuffer = '0';
    use bytes;
    if($self->{_readlineon}) {
        print qq(readline method used for pid: ) . $self->GetPid . qq(\n) if($Wx::Perl::ProcessStream::WXPDEBUG);
        if( $self->IsInputAvailable() && defined( my $tempbuffer = readline( $self->GetInputStream() ) ) ){
            $linebuffer = $tempbuffer;
        }        
    } else {
        print qq(read method used for pid: ) . $self->GetPid . qq(\n) if($Wx::Perl::ProcessStream::WXPDEBUG);
        while( $self->IsInputAvailable() && ( my $chars = read($self->GetInputStream(),$charbuffer,1 ) ) ) {
            last if(!$chars);
            $linebuffer .= $charbuffer;
            last if($charbuffer eq "\n");
        }
    }
    no bytes;
    return $linebuffer;
}

sub __read_error_line {
    my $self = shift;
    my $linebuffer;
    my $charbuffer = '0';
    use bytes;
    if($self->{_readlineon}) {
        print qq(readline method used for pid: ) . $self->GetPid . qq(\n) if($Wx::Perl::ProcessStream::WXPDEBUG);
        if( $self->IsErrorAvailable() && defined( my $tempbuffer = readline( $self->GetErrorStream() ) ) ){
            $linebuffer = $tempbuffer;
        }
    } else {
        print qq(read method used for pid: ) . $self->GetPid . qq(\n) if($Wx::Perl::ProcessStream::WXPDEBUG);
        while($self->IsErrorAvailable() && ( my $chars = read($self->GetErrorStream(),$charbuffer,1 ) ) ) {
            last if(!$chars);
            $linebuffer .= $charbuffer;
            last if($charbuffer eq "\n");
        }
    }
    no bytes;
    return $linebuffer;
}

sub __get_handler {
    my $self = shift;
    return $self->{_handler};
}

sub __set_handler {
    my $self = shift;
    $self->{_handler} = shift;
}

sub GetAppCloseAction {
    my $self = shift;
    return $self->{_closeaction};
}

sub SetAppCloseAction {
    my $self = shift;
    my $newaction = shift;
    $self->{_closeaction} = ($newaction == wxSIGTERM||wxSIGKILL) ?  $newaction : $self->{_closeaction};
}

sub GetProcessName {
    my $self = shift;
    return $self->{_procname};
}

sub __set_process_name {
    my $self = shift;
    $self->{_procname} = shift;
}

sub GetExitCode { 
    my $self = shift;
    if(!defined($self->{_stored_event_exit_code})) {
        my $pid = $self->GetPid;
        $self->{_stored_event_exit_code} = $_runningpids->{$pid};
    }
    return $self->{_stored_event_exit_code};
}

sub GetStdOutBuffer {
    my $self = shift;
    my @buffers = @{ $self->{_stdout_buffer} };
    $self->{_stdout_buffer} = [];
    return \@buffers;
}

sub GetStdErrBuffer {
    my $self = shift;
    my @buffers = @{ $self->{_stderr_buffer} };
    $self->{_stderr_buffer} = [];
    return \@buffers;
}

sub GetStdOutBufferLineCount {
    my $self = shift;
    return scalar @{ $self->{_stdout_buffer} };
}

sub GetStdErrBufferLineCount {
    my $self = shift;
    return scalar @{ $self->{_stderr_buffer} };
}

sub PeekStdOutBuffer {
    my $self = shift;
    my @buffers = @{ $self->{_stdout_buffer} };
    return \@buffers;
}

sub PeekStdErrBuffer {
    my $self = shift;
    my @buffers = @{ $self->{_stderr_buffer} };
    return \@buffers;
}

sub GetProcessId {
    my $self = shift;
    return $self->{_processpid};
}

sub GetPid { shift->GetProcessId; }

sub __set_process_id {
    my $self = shift;
    $self->{_processpid} = shift;
}

sub TerminateProcess {
    my $self = shift;
    push(@{ $self->{_await_actions} }, { action => 'terminate', } );
}

sub KillProcess {
    my $self = shift;
    push(@{ $self->{_await_actions} }, { action => 'kill', } );
}

sub WriteProcess {
    my ($self, $writedata) = @_;
    push(@{ $self->{_await_actions} }, { action => 'write', writedata => $writedata } );
}

sub CloseInput {
    my $self = shift;
    push(@{ $self->{_await_actions} }, { action => 'closeinput', } );
}

sub _exit_event_posted { $_[0]->{_exit_event_posted} }

sub _set_exit_event_posted { $_[0]->{_exit_event_posted} = $_[1]; }

sub IsAlive {
    my $self = shift;
    
    # if we already have the exitcode from the system
    # we should return 0 - regardless if system tells
    # us process is still hanging around - as it will
    # sometimes
    
    return 0 if defined( $self->GetExitCode );
    
    # otherwise, return the system result
    
    return (  Wx::Process::Exists( $self->GetProcessId() ) ) ? 1 : 0;
    
}

sub Destroy {
    my $self = shift;
    Wx::Process::Kill($self->GetPid(), wxSIGKILL) if $self->IsAlive; 
    $Wx::Perl::ProcessStream::ProcHandler->RemoveProc( $self );
    $self->SUPER::Destroy;
    $self = undef;
}

sub DESTROY {
    my $self = shift;
    print qq(DESTROY method for ) . $self->GetPid . qq(\n) if($Wx::Perl::ProcessStream::WXPDEBUG);
    $self->SUPER::DESTROY if $self->can('SUPER::DESTROY');
}

#-----------------------------------------------------
# PACKAGE Wx::Perl::ProcessStream::ProcessEvent
#
# STDOUT, STDERR, EXIT events
#-----------------------------------------------------

package Wx::Perl::ProcessStream::ProcessEvent;
use strict;
use Wx;
use base qw( Wx::PlCommandEvent );

sub new {
    my( $class, $type, $id ) = @_;
    my $self = $class->SUPER::new( $type, $id );
    return $self;
}

sub GetLine {
    my $self = shift;
    return $self->{_outputline};
}

sub SetLine {
    my $self = shift;
    $self->{_outputline} = shift;
}

sub GetProcess {
    my $self = shift;
    return $Wx::Perl::ProcessStream::ProcHandler->FindProc( $self->_get_pid );
    
}

sub SetProcess {
    my ($self, $process) = @_;
    $self->_set_pid( $process->GetPid );
}

sub _get_pid { $_[0]->{_pid}; }
sub _set_pid { $_[0]->{_pid} = $_[1]; }

sub Clone {
    my $self = shift;
    my $class = ref $self;
    my $clone = $class->new( $self->GetEventType(), $self->GetId() );
    $clone->SetLine( $self->GetLine );
    $clone->_set_pid( $self->_get_pid );
    return $clone;
}

package Wx::Perl::ProcessStream::ProcEvtHandler;
use strict;
use Wx 0.50 qw( wxID_ANY );
use base qw( Wx::Process );
use Wx::Event qw(EVT_END_PROCESS);

sub new {
    my ($class, @args) = @_;
    
    my $self = $class->SUPER::new(@args);
    
    EVT_END_PROCESS($self, wxID_ANY, sub { shift->OnEventEndProcess(@_); });
    
    return $self;
}

sub OnEventEndProcess {
    my ($self, $event) = @_;
    $event->Skip(0);
    my $pid = $event->GetPid;
    my $exitcode = $event->GetExitCode;
    $Wx::Perl::ProcessStream::Process::_runningpids->{$pid} = $exitcode;
}

1;

__END__


