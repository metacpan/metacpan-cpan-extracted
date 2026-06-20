use strict;
use warnings;


use pEFL::Elm;
use pEFL::Evas;
use pEFL::Ecore;

use POSIX qw(WNOHANG); 
use IO::Handle;       
use IO::String; 

my ($win);
my $buffer = ""; 

pEFL::Elm::init($#ARGV, \@ARGV);

pEFL::Elm::policy_set(ELM_POLICY_QUIT, ELM_POLICY_QUIT_LAST_WINDOW_CLOSED);
$win = pEFL::Elm::Win->util_standard_add("progressbar", "Progressbar");
$win->autodel_set(1);
$win->resize(400,400);

my $bx = pEFL::Elm::Box->add($win);
$bx->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
$bx->size_hint_align_set(EVAS_HINT_FILL, EVAS_HINT_FILL);

my $button_text = pEFL::Elm::Button->new($bx);
$button_text->text_set("Click me");
$button_text->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
$button_text->size_hint_align_set(EVAS_HINT_FILL, 0.5);
$button_text->smart_callback_add("clicked", \&_button_click_cb, undef);
$bx->pack_end($button_text);
$button_text->show();

$bx->show();
$win->resize_object_add($bx);
$win->show();

pEFL::Elm::run();
pEFL::Elm::shutdown();


sub _button_click_cb {
    my ($data, $button, $event_info) = @_;
    
    pipe(my $read_fh, my $write_fh) or die "Pipe fehlgeschlagen: $!";
    $write_fh->autoflush(1);
    
    my $pid = fork();
    if (!defined $pid) { die "Fork fehlgeschlagen: $!"; }
    
    if ($pid == 0) {
        close $read_fh; 
        
        for my $i (1..5) {
            sleep 1;
            print $write_fh "Status: " . ($i * 20) . " %\n";
        }
        print "Success: 1\n";
        close $write_fh;
        exit 0;
    }
    else {
        close $write_fh; 
        # How does this all work? And why is there nowhere a select?
		# 1. Ecore FdHandler takes on the role of `select` and triggers the callback 
        #    ONLY when there is actually data in the pipe or the child process terminates.
		# 2. sysread does NOT block the GUI here, since with local pipes it 
        #    returns immediately as soon as the first bytes (e.g., status line) arrive.
        # 3. bytes_read == 0 is the signal for EOF with pipes
        # 
		
		# --- ALTERNATIVE: Especially for network sockets (TCP) instead of local pipes ---
        # If the data stream is traveling over a network, you should set the mode to 
        # non-blocking and handle errors to prevent GUI freezes:
        #
        # $read_fh->blocking(0); 
        #
		# In the callback, you must then include this check before the EOF check:
        # if (!defined $bytes_read) { return 1; } # Ignores EAGAIN false errors and similar
        # if ($bytes_read == 0)     { ... }       # Connection closed
        
        my $popup = pEFL::Elm::Popup->add($win);
        my $progress = pEFL::Elm::Progressbar->add($popup);
        $progress->pulse_set(0); 
        $progress->value_set(0.0);
        $popup->part_content_set("default", $progress);
        $popup->show();
        
        my $fd = fileno($read_fh);
        pEFL::Ecore::FdHandler->add($fd, ECORE_FD_READ, \&_pipe_read_cb, [$read_fh, $pid, $popup, $progress]);
    }
}

sub _pipe_read_cb {
    my ($data, $handler) = @_;
    my ($read_fh, $pid, $popup, $progress) = @$data;
    
    my $chunk;
    my $bytes_read = sysread($read_fh, $chunk, 1024);
    
    if ($bytes_read == 0) {
        close $read_fh;
        # A brief note on fork and efl/pEFL:
        # efl sets up a signal handler for SIGCHLD to begin as with almost all signals. 
        # So it converts USR1/USR2 to events. It ignores PIPE and ALRM signals. 
        # It converts HUP to an event as well as QUIT, just as INT and TERM and more signals
        #
        # Therefore we should never override SIGCHLD because this will break efl's auto-collection
        # above where ecore_exe which spawns hild processes can track exiting/end of the process spawned.
		# ecore_exe also handles stdin/out i/o to the child process etc. and efl handles
		# multiplexing all of that within the ecore event loop as events. Furthermor 
		# efl may spawn helper binaries and will rely on the above ecore events for i/o and knowing
		# when it existed and why. All this wouldn't work as it should when we override SIGCHLD
		#
		# To make it short: waitpid will here never called to the right time, because efl will 
		# already have collected the child processes. Just as a precaution, for safety's sake, 
		# and out of habit, we're doing it here anyway :-)
		#
		# waitpid will return 0, if the child process is still running and -1 if the child process 
		# no longer exists or another problem occures (check for details $!) 
        waitpid($pid, 0); 
        $popup->del();
        $buffer = ""; 
        return 0; # Deletes handler!  
    }
    
    $buffer .= $chunk;
    
    # With the in memory file (= the IO-String-Objekt) we can read single lines without blocking the GUI!
    # Why does this work here unlike normal pipes or STDIN/STDOUT
	# 1. IO::String operates exclusively in memory (RAM) on a variable.
	# 2. It never waits for the operating system, networks, or other processes 
	# That's the tifference to pipes or STDIN!!!
    # 3. If there is no ‘\n’ at the end of the buffer, Perl immediately recognizes the end of file (EOF).
    # 4. getline() then instantly returns the fragment (or undef), and the loop terminates without
    # delay.
	my $io_str = IO::String->new($buffer);
    while (my $line = $io_str->getline()) {
        
        # WICHTIG: Prüfen, ob die Zeile vollständig ist (endet mit \n)
        if ($line =~ /\n$/) {
            chomp($line);
            _process_child_line($line, $progress);
        }
    }
    
    # Remove bytes that have already been read from the global buffer
    # With IO::String, pos() returns the current byte position
    substr($buffer, 0, $io_str->pos()) = '';
    
    return 1; # Aktiv bleiben
}


sub _process_child_line {
    my ($line, $progress) = @_;
    
    if ($line =~ /^Status:\s*(\d+)/) {
        my $percent = $1;
        
        # Umrechnen in das EFL-Format (0.0 bis 1.0)
        my $efl_value = $percent / 100;
        
        # Wert begrenzen (Sicherheit gegen fehlerhafte Kind-Ausgaben > 100)
        $efl_value = 1.0 if $efl_value > 1.0;
        $efl_value = 0.0 if $efl_value < 0.0;
        
        warn "[GUI] Setze echten Fortschrittsbalken auf: $percent% (EFL-Wert: $efl_value)\n";
        $progress->value_set($efl_value);
    }
    elsif ($line =~ /^Success:\s*(\d+)/) {
        warn "[GUI] Erfolg-Status ausgewertet: $1\n";
    }
}
