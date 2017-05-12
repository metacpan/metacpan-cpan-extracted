#!perl
BEGIN { $ENV{WXPPS_MULTITEST} ||= 10; $ENV{WXPPS_POLLINTERVAL} ||= 100;}
package main;

use strict;
use Test::More tests => 57 + $ENV{WXPPS_MULTITEST};
use lib 't';
use Wx;
use WxTesting qw( app_from_wxtesting_frame );

my $app = app_from_wxtesting_frame( 'ProcessStreamTestingFrame' );
$app->MainLoop;

package ProcessStreamTestingFrame;
use strict;
use base qw(WxTesting::Frame);
use Wx::Perl::ProcessStream 0.30 qw( :everything );
use Test::More;
use Time::HiRes qw( sleep );


sub new {
    my $class = shift;
    my $self = $class->SUPER::new( undef, -1, 'Testing Wx::Perl::ProcessStream ');
    EVT_WXP_PROCESS_STREAM_STDOUT( $self, \&evt_process);
    EVT_WXP_PROCESS_STREAM_STDERR( $self, \&evt_process);
    EVT_WXP_PROCESS_STREAM_EXIT(   $self, \&evt_process);
    EVT_WXP_PROCESS_STREAM_MAXLINES(   $self, \&evt_process);
    $self->{_stdout} = [];
    $self->{_stderr} = [];
    $self->{_exitcode} = undef;
    $self->{_eventmode} = 'single';
    return $self;
}

sub RunTests {
    my $self = shift;   
    my $perl = $^X;
    
    # speed up tests
    Wx::Perl::ProcessStream->SetPollInterval($ENV{WXPPS_POLLINTERVAL});
    
    # test group 1
    my $cmd;
    my $process;
    my $errs;
    
    if($^O =~ /^MSWin/) {
        $cmd = [ $perl, '-e', q(print 0, qq(\n);) ];
    } else {
        $cmd = [ $perl, '-e', q(print 0, qq(\n);) ];
    }
    
    {
        $process = $self->start_process_a( $cmd );
        #ok( $process->IsAlive() );
        $self->wait_for_test_complete();
        is( $process->IsAlive(), 0 );
        is( $self->{_stdout}->[0], '0' );
        $errs = join('', @{ $self->{_stderr} });
        $errs ||= '';
        is( $errs, '' );
        is( $self->{_exitcode}, 0 );
        is( $process->GetExitCode() , 0 );
        $process->Destroy;
        $process = undef;
    }
    
    if($^O =~ /^MSWin/) {
        $cmd = [ $perl, '-e', q(print 'HELLO WORLD', qq(\n);) ];
    } else {
        $cmd = [ $perl, '-e', q(print 'HELLO WORLD', qq(\n);) ];
    }
    
    {
        $process = $self->start_process_a( $cmd );
        #ok( $process->IsAlive() );
        $self->wait_for_test_complete();
        is( $process->IsAlive(), 0 );
        is( $self->{_stdout}->[0], 'HELLO WORLD' );
        $errs = join('', @{ $self->{_stderr} });
        $errs ||= '';
        is( $errs, '' );
        is( $self->{_exitcode}, 0 );
        is( $process->GetExitCode() , 0 );
        $process->Destroy;
        $process = undef;
    }
    {
        $process = $self->start_process_b( $cmd );
        #ok( $process->IsAlive() );
        $self->wait_for_test_complete();
        is( $process->IsAlive(), 0 );
        is( $self->{_stdout}->[0], 'HELLO WORLD' );
        $errs = join('', @{ $self->{_stderr} });
        $errs ||= '';
        is( $errs, '' );
        is( $self->{_exitcode}, 0 );
        is( $process->GetExitCode() , 0 );
        $process->Destroy;
        $process = undef;
    }
    
    # test group 1a - arrref
    
    if($^O =~ /^MSWin/) {
        $cmd = [ $perl, '-e', q(print 'HELLO WORLD', qq(\n);) ];
    } else {
        $cmd = [ $perl, '-e', q(print 'HELLO WORLD', qq(\n);) ];
    }
    
    {
        $process = $self->start_process_a( $cmd );
        #ok( $process->IsAlive() );
        $self->wait_for_test_complete();
        is( $process->IsAlive(), 0 );
        is( $self->{_stdout}->[0], 'HELLO WORLD' );
        $errs = join('', @{ $self->{_stderr} });
        $errs ||= '';
        is( $errs, '' );
        is( $self->{_exitcode}, 0 );
        is( $process->GetExitCode() , 0 );
        $process->Destroy;
        $process = undef;
    }
    {
        $process = $self->start_process_b( $cmd );
        #ok( $process->IsAlive() );
        $self->wait_for_test_complete();
        is( $process->IsAlive(), 0 );
        is( $self->{_stdout}->[0], 'HELLO WORLD' );
        $errs = join('', @{ $self->{_stderr} });
        $errs ||= '';
        is( $errs, '' );
        is( $self->{_exitcode}, 0 );
        is( $process->GetExitCode() , 0 );
        $process->Destroy;
        $process = undef;
    }
    
    # test group 2
    $cmd = $perl . ' notarealtestascript.pl';
    $process = $self->start_process_b( $cmd );
    #ok( $process->IsAlive() );
    $self->wait_for_test_complete();
    is( $process->IsAlive(), 0 );
    my $out = join('', @{ $self->{_stdout} });
    $out ||= '';
    is( $out, '' );
    $errs = join('', @{ $self->{_stderr} });
    $errs ||= '';
    isnt( $errs, '' );
    isnt( $self->{_exitcode}, 0 );
    $process->Destroy;
    $process = undef;
    
    # test group 3
    if($^O =~ /^MSWin/) {
        $cmd = [ $perl, '-e', q($|=1;print 'ONE', qq(\n);sleep 1;print 'TWO', qq(\n);sleep 1;print 'THREE',qq(\n);sleep 1;print STDERR 'FOUR', qq(\n);exit(5);) ];
    } else {
        $cmd = [ $perl, '-e', q($|=1;print 'ONE', qq(\n);sleep 1;print 'TWO', qq(\n);sleep 1;print 'THREE',qq(\n);sleep 1;print STDERR 'FOUR', qq(\n);exit(5);) ];
    }
    $process = $self->start_process_b( $cmd );
    #ok( $process->IsAlive() );
    $self->wait_for_test_complete();
    is( $process->IsAlive(), 0 );
    my $bufferline = join('-', @{ $self->{_stdout } });
    $bufferline =~ s/^\-+//;
    $bufferline =~ s/\-+$//;
    is($bufferline, 'ONE-TWO-THREE' );
    $bufferline = join('-', @{ $self->{_stderr } });
    $bufferline =~ s/^\-+//;
    $bufferline =~ s/\-+$//;
    is($bufferline, 'FOUR' );
    is($self->{_exitcode}, 5 );
    $process->Destroy;
    $process = undef;
    
    # test group 4 - write STDIN
    $cmd = $perl . ' t/echo.pl';
    $process = $self->start_process_b( $cmd );
    #ok( $process->IsAlive() );
    
    $process->WriteProcess( qq(TEST STDIN 1\n) );
    $process->WriteProcess( qq(TEST STDIN 2\n) );
    $process->CloseInput();
    $self->wait_for_test_complete();
    is( $process->IsAlive(), 0 );
    $bufferline = join('-', @{ $process->GetStdOutBuffer() });
    $bufferline =~ s/^\-+//;
    $bufferline =~ s/\-+$//;
    is($bufferline, 'ECHO:TEST STDIN 1-TEST STDIN 2' );
    $errs = join('', @{ $self->{_stderr} });
    $errs ||= '';
    is( $errs, '' );
    is( $process->GetExitCode(), 123 );
    $process->Destroy;
    $process = undef;
    
    # test group 5 - shell echo program 
    if($^O =~ /^MSWin/) {
        $cmd = 'cmd.exe /C ' . $perl . ' t/shelltest.pl';
    } else {
        $cmd = '/bin/sh t/shelltest.sh';
    }

    $process = $self->start_process_b( $cmd );
    #ok( $process->IsAlive() );

    while(!defined($self->{_exitcode})) {
        if(join('-', @{ $process->GetStdOutBuffer() }) eq 'WXTEST INPUT') {
            $process->WriteProcess(qq(WX TEST DATA\n));
            $process->CloseInput();
        }
        Wx::Perl::ProcessStream::Yield();
    }
    
    is( $process->IsAlive(), 0 );
    $bufferline = join('-', @{  $self->{_stdout} });
    $bufferline =~ s/^\-+//;
    $bufferline =~ s/\-+$//;
    is($bufferline, 'WXTEST INPUT-ECHO:WX TEST DATA' );
    $errs = join('', @{ $process->GetStdErrBuffer() });
    $errs ||= '';
    is( $errs, '' );
    is( $process->GetExitCode(), 0 );
    $process->Destroy;
    $process = undef;
    
    # test group 6 - multiple instance
    
    my @multiprocs;
    $self->{_eventmode} = 'multi';
    
    for (my $i = 0; $i < $ENV{WXPPS_MULTITEST}; $i ++) {
        my $sleeptime =  1 + (int(rand(10))/ 10); # sleep between 1.1 and 1.9 seconds - we want instances to exit in random order
        my $exitcode = 1 + int(rand(100)); # exitcodes 1 to 100
        my $multicmd = 'perl -e "use Time::HiRes qw( sleep ); sleep ' . $sleeptime . '; print qq(GOODBYE WORLD FROM PID: $$ INSTANCE: ' . $i . '\n); exit(' . $exitcode . ');"';
        my $multiprocess = $self->start_process_b( $multicmd );
        my $multipid = $multiprocess->GetPid;
        $self->{_multiresult}->{$multipid}->{expected} = $exitcode;
        push(@multiprocs, $multiprocess);
    }
    # wait for all procs to end
    {
        my $stillrunning = 1;
        while($stillrunning) {
            $stillrunning = 0;
            foreach my $mpid (sort keys( %{ $self->{_multiresult} } ) ) {
                $stillrunning ++ if(!defined($self->{_multiresult}->{$mpid}->{received}));
            }
            Wx::Perl::ProcessStream::Yield();
        }
    }
    for( @multiprocs ) {
        $_->Destroy;
    }
    @multiprocs = ();
    
    foreach my $mpid (sort keys( %{ $self->{_multiresult} } ) ) {
        my $mresult = $self->{_multiresult}->{$mpid};
        ok( $mresult->{expected} > 0 && ($mresult->{expected} eq $mresult->{received}), 'check expected vs received exit code' ) or
            diag(qq(PID $mpid expected : $self->{_multiresult}->{$mpid}->{expected} : received : $self->{_multiresult}->{$mpid}->{received}));
    }
    
    # test group 7 - num procs should be zero
    
    is(Wx::Perl::ProcessStream::ProcessCount(), 0, 'check process count is zero');
    
    
    # test group 8 - maxline testing
    {
        $self->{_eventmode} = 'single';
        
        if($^O =~ /^MSWin/) {
            $cmd = [ $perl, '-e', q($x = 1200; while($x){ print qq($x\n); $x--; };) ];
        } else {
            $cmd = [ $perl, '-e', q($x = 1200; while($x){ print qq($x\n); $x--; };) ];
        }
        $self->{_maxlineevtcount} = 0;
        $process = $self->start_process_b( $cmd );
        #ok( $process->IsAlive() );
        $self->wait_for_test_complete();
        is( $process->IsAlive(), 0 );
        is( $self->{_stdout}->[0], 1200 );
        my $num = scalar @{$self->{_stdout}};
        is( $self->{_stdout}->[$num -1], 1 );
        is( $num, 1200 );
        is( $self->{_exitcode}, 0 );
        is( $process->GetExitCode() , 0 );
        $process->Destroy;
        $process = undef;
        is( $self->{_maxlineevtcount}, 1 );
        
        Wx::Perl::ProcessStream->SetDefaultMaxLines(10);
        is( Wx::Perl::ProcessStream->GetDefaultMaxLines, 10 );
        $self->{_maxlineevtcount} = 0;
        
        $process = $self->start_process_b( $cmd );
        #ok( $process->IsAlive() );
        $self->wait_for_test_complete();
        is( $process->IsAlive(), 0 );
        is( $self->{_stdout}->[0], 1200 );
        $num = scalar @{$self->{_stdout}};
        is( $self->{_stdout}->[$num -1], 1 );
        is( $num, 1200 );
        is( $self->{_exitcode}, 0 );
        is( $process->GetExitCode() , 0 );
        $process->Destroy;
        $process = undef;
        is( $self->{_maxlineevtcount}, 120 );
        
    }
    
    return 1;
}

sub start_process_a {
    my ($self, $cmd) = @_;
    $self->{_stdout} = [];
    $self->{_stderr} = [];
    $self->{_exitcode} = undef;
    my $process = Wx::Perl::ProcessStream->OpenProcess( $cmd, 'TestCmd', $self );
    die 'Failed to launch process' if(!$process);
    return $process;
}

sub start_process_b {
    my ($self, $cmd) = @_;
    $self->{_stdout} = [];
    $self->{_stderr} = [];
    $self->{_exitcode} = undef;
    my $process = Wx::Perl::ProcessStream::Process->new( $cmd, 'TestCmd', $self )->Run;
    die 'Failed to launch process' if(!$process);
    return $process;
}
    
sub wait_for_test_complete {
    my $self = shift;
    while(!defined($self->{_exitcode})) {
        Wx::Perl::ProcessStream::Yield();
        sleep 0.1;
    }
}

sub evt_shell_stdout {
    my ($self, $event) = @_;
    $event->Skip(1);
    my $line = $event->GetLine();
    push(@{ $self->{_stdout} }, $line);
    my $process = $event->GetProcess();
    if($line eq 'WXTEST INPUT') {
        $process->WriteProcess( qq(WX TEST DATA\n));
        $process->CloseInput();
    }
}
    
sub evt_process {
    my ($self, $event) = @_;
    $event->Skip(1);
    
    my $evttype = $event->GetEventType();
    my $line = $event->GetLine();
    my $process = $event->GetProcess();
    # calling with perl one liners confuses line endings
    
    if($evttype == wxpEVT_PROCESS_STREAM_STDOUT) {
        push(@{ $self->{_stdout} }, $line);
    } elsif ( $evttype == wxpEVT_PROCESS_STREAM_STDERR) {
        push(@{ $self->{_stderr} }, $line);
    } elsif ( $evttype == wxpEVT_PROCESS_STREAM_MAXLINES) {
       $self->{_maxlineevtcount} ++;
    } elsif ( $evttype == wxpEVT_PROCESS_STREAM_EXIT) {
        if( $self->{_eventmode} ne 'multi') {
            $self->{_exitcode} = $process->GetExitCode();
        } else {
            my $pid = $process->GetPid();
            my $exitcode = $process->GetExitCode();
            $self->{_multiresult}->{$pid}->{received} = $exitcode;
        }
    }
}

1;
