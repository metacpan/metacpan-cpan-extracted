package forks;   # make sure CPAN picks up on forks.pm
$VERSION = '0.36';

# Allow external modules to defer shared variable init at require

$DEFER_INIT_BEGIN_REQUIRE = 0 unless $DEFER_INIT_BEGIN_REQUIRE;

package
    threads; # but in fact we're masquerading as threads.pm

# Make sure we have version info for this module
# Set flag to indicate that we're really the original threads implementation
# Set flag to indicate that we're not really the original threads implementation
# Flag whether or not module is loaded in namespace override mode (e.g. threads.pm)
# Be strict from now on

BEGIN {
    $VERSION = '1.92';
    $threads        = $threads        = 1; # twice to avoid warnings
    $forks::threads = $forks::threads = 1; # twice to avoid warnings
    $forks::threads_override = $forks::threads_override = 0; # twice to avoid warnings
}

# Standard forks behavior (extra features), or emulate threads to-the-letter

BEGIN {
    if ($forks::threads_override) {
        $forks::threads_native_emulation = 1;
    } elsif (exists $ENV{'THREADS_NATIVE_EMULATION'}) {
        $ENV{'THREADS_NATIVE_EMULATION'} =~ m#^(.*)$#s;
        $forks::threads_native_emulation = $1 ? 1 : 0;
    } else {
        $forks::threads_native_emulation = 0;
    }
    *forks::THREADS_NATIVE_EMULATION = sub { $forks::threads_native_emulation };
}

# Use strict pragma
# Use warnings pragma
# Register 'threads' namespace with warnings (if not already present)
# Make sure we can die with lots of information

use strict;
use warnings;
use warnings::register;
use Carp ();

#---------------------------------------------------------------------------
# Set when to execute check and end blocks

BEGIN {
    if ($^C) {
        eval "CHECK { _CHECK() }";
    } elsif (defined &DB::DB) {
        # TODO: no end block for now, as debugger halts on it (ignoring $DB::inhibit_exit)
    } else {
        $] < 5.008 ? eval "END { eval{ _END() } }" : eval "END { _END() }";
    }
} #BEGIN

# Fake that threads.pm was really loaded, before loading any other modules

BEGIN {
    my $module = 'forks';
    if (defined $INC{'forks.pm'}) {
        $INC{'threads.pm'} ||= $INC{'forks.pm'};
    } elsif (defined $INC{'threads.pm'} && $forks::threads_override) {
        $module = 'threads';
        $INC{'forks.pm'} ||= $INC{'threads.pm'}
    } elsif (defined $INC{'threads.pm'} && !$forks::threads_override) {
        die( "Can not mix 'use forks' with real 'use threads'" )
    }

    $module = 'threads' if eval{forks::THREADS_NATIVE_EMULATION()};
    Carp::carp "Warning, $module\::shared has already been loaded"
        if defined $INC{'forks/shared.pm'};
}

# Load signal handler libraries

BEGIN {
    require sigtrap;
    require forks::signals;
}

# Import additional scalar methods for refs and objects
# Load library to set temp dir for forks data
# Load library that to support unblessing objects

use Scalar::Util qw(reftype blessed refaddr);
use File::Spec;
use forks::Devel::Symdump; # Perl 5.10.x patch for Devel::Symdump 2.08
use Acme::Damn ();

# Set constant for IPC temp dir
# Set constant for IPC temp thread signal notifications

use constant ENV_ROOT   => File::Spec->tmpdir().'/perlforks';
use constant ENV_SIGNALS => ENV_ROOT.'/signals';

# Set constants for threads->list() operations: all, running, and joinable

use constant all      => ();
use constant running  => 1;
use constant joinable => 0;

# Set constants for threads exit

use constant EXIT_THREAD_ONLY => 'thread_only';
use constant EXIT_THREADS_ONLY => 'threads_only';

# (bug?) Perl 5.11+ each function may not correctly set hash iterator when using refs as keys
use constant RESET_EACH_ITER => $] >= 5.011;

#---------------------------------------------------------------------------
# Modify Perl's Config.pm to simulate that it was built with ithreads

BEGIN {
    require Config;
    my $h = tied %Config::Config;
    $h->{useithreads} = 1;
}

#---------------------------------------------------------------------------

# Global debug flag
# Global socket server Nice value
# Global CHLD force IGNORE flag
# Global UNIX socket flag
# Global INET socket IP mask regex value
# Do this at compile time
#  If there is a THREADS_DEBUG specification
#   Untaint value
#   Set its value
#   Make sure access is done with the DEBUG sub
#  Else (we never need any debug info)
#   Make DEBUG a false constant: debugging code should be optimised away
#  If there is a THREADS_SOCKET_UNIX specification
#   Set its value
#   Make sure socket is available; die if non-socket object exists
#   Remove existing socket file if defined
#   Make sure access is done with the THREADS_UNIX sub
#  Else 
#   Make THREADS_UNIX a false constant: default to INET sockets
#  If there is a THREADS_IP_MASK specification
#   Set its value
#  Else
#   Use default localhost mask
#  If there is a THREADS_DAEMON_MODEL specification
#   Enable integrated threads (server process child of main thread)
#  Else
#   Enable normal threads (server process parent of main thread)
#  If there is a PERL5_ITHREADS_STACK_SIZE specification
#   Set this as the new default size
#  Else
#   Set to the system default size (0 == use system default)

my $DEBUG;
my $SERVER_NICE;
my $FORCE_SIGCHLD_IGNORE;
my $THREADS_UNIX;
my $INET_IP_MASK;
my $THREADS_INTEGRATED_MODEL;
my $ITHREADS_STACK_SIZE;

BEGIN {
    if (exists $ENV{'THREADS_DEBUG'}) {
        $ENV{'THREADS_DEBUG'} =~ m#^(.*)$#s;
        $DEBUG = $1;
    } else {
        $DEBUG = 0;
    }
    *DEBUG = sub () { $DEBUG };

    if (exists $ENV{'THREADS_NICE'}) {
        $ENV{'THREADS_NICE'} =~ m#^(.*)$#s;
        $SERVER_NICE = $1;
    } else {
        $SERVER_NICE = 0;
    }

    if (exists $ENV{'THREADS_SIGCHLD_IGNORE'}) {
        $ENV{'THREADS_SIGCHLD_IGNORE'} =~ m#^(.*)$#s;
        $FORCE_SIGCHLD_IGNORE = $1;
    } else {
        $FORCE_SIGCHLD_IGNORE = 0;
    }

    my $threads_socket_unix = '/var/tmp/perlforks.';
    if (defined $ENV{'THREADS_SOCKET_UNIX'} && $ENV{'THREADS_SOCKET_UNIX'} ne "") {
        #$ENV{'THREADS_SOCKET_UNIX'} =~ m#^(.*)$#s;
        $THREADS_UNIX = $threads_socket_unix;
    } else {
        $THREADS_UNIX = 0;
    }

    if (exists $ENV{'THREADS_IP_MASK'}) {
        $ENV{'THREADS_IP_MASK'} =~ m#^(.*)$#s;
        $INET_IP_MASK = $1;
    } else {
        $INET_IP_MASK = '^127\.0\.0\.1$';
    }

    if (exists $ENV{'THREADS_DAEMON_MODEL'}) {
        $ENV{'THREADS_DAEMON_MODEL'} =~ m#^(.*)$#s;
        $THREADS_INTEGRATED_MODEL = $1 ? 0 : 1;
    } else {
        $THREADS_INTEGRATED_MODEL = 1;
    }

    if (exists $ENV{'PERL5_ITHREADS_STACK_SIZE'}) {
        $ENV{'PERL5_ITHREADS_STACK_SIZE'} =~ m#^(\d+)$#s;
        $ITHREADS_STACK_SIZE = $1;
    } else {
        $ITHREADS_STACK_SIZE = 0;
    }
} #BEGIN

# Load the XS stuff

require XSLoader;
XSLoader::load( 'forks',$forks::VERSION );

# Make sure we can do sockets and have the appropriate constants
# Make sure we can do select() on multiple sockets
# Make sure we have the necessary POSIX constants
# Make sure that we can freeze and thaw data structures
# Allow for chainable child reaping functions
# Enable hi-res time

use Socket     qw(SOMAXCONN);
use IO::Socket ();
use IO::Select ();
use POSIX      qw(WNOHANG
    BUFSIZ O_NONBLOCK F_GETFL F_SETFL
    SIG_BLOCK SIG_UNBLOCK SIGCHLD SIGKILL
    ECONNABORTED ECONNRESET EAGAIN EINTR EWOULDBLOCK ETIMEDOUT
    SA_RESTART SA_NOCLDSTOP
    WIFEXITED WIFSIGNALED);
use Storable   ();
use Time::HiRes qw(time);
use List::MoreUtils;

# Flag whether or not forks has initialized the server process
# Thread local query server object
# The port on which the thread server is listening
# The process id in which the shared variables are stored
# The main thread process id
# Initialize thread local hash (key: pid) whether this process is a thread
# Initialize local flag whether main thread received ABRT signal
# Initialize local flag whether main thread exited due to ABRT signal
# Initialize local flag whether main thread should be signalled with ABRT on server shutdown
# Initialize hash (key: pid) of child thread PIDs
# Thread local flag whether we're shutting down
# Thread local flag whether we're shutting down in END block
# Thread local flag whether we're shut down

my $HANDLED_INIT = 0;
my $QUERY;
my $PORT;
my $SHARED;
my $PID_MAIN_THREAD;
my %ISATHREAD;
my $MAIN_ABRT_HANDLED = 0;
my $MAIN_EXIT_WITH_ABRT = 0;
my $MAIN_EXIT_NO_ABRT = 0;
my %CHILD_PID;
my $SHUTTING_DOWN = 0;
my $SHUTTING_DOWN_END = 0;
my $SHUTDOWN = 0;

# Initialize the flag that indicates that we're still running
# Initialize value that stores the desired application exit value
# Initialize the number of bytes to read at a time
# List of signals that forks intelligently monitors and traps to insure inter-thread signal stability
# Initialize hash (key: sig name) of base not-defined signal behavior to use with forks::signals
# Initialize hash (key: sig name) of base defined signal behavior to use with forks::signals
# Pseudo-signal mask indicating signals to handle when thread finished current server message handling
# Initialize flag that indicates whether thread is send data with shared process
# Initialize flag that indicates whether thread is recv data with shared process
# Initialize variable for shared server received data
# Boolean indicating whether or not platform requires a custom CHLD handler
# Max sleep time of main server loop before looping once
# Initialize hash (key: client) with info to be written to client threads
# Initialize hash (key: client) with clients that we're done with
# Initialize the "thread local" thread id
# Initialize the pid of the thread
# Return context of thread (possible values are same as those of CORE::wantarray)
# Initialize hash (key: package) with code references of CLONE subroutines
# Initialize hash (key: package) with code references of CLONE_SKIP subroutines
# Initialize hash (key: package) with object references for CLONE_SKIP-enabled classes

my $RUNNING = 1;
my $EXIT_VALUE;
my $BUFSIZ  = BUFSIZ;
my @TRAPPED_SIGNAL;
BEGIN {
    foreach my $signal (qw(HUP INT PIPE TERM USR1 USR2 ABRT EMT QUIT TRAP)) {
        push @TRAPPED_SIGNAL, $signal if grep(/^$signal$/,
            split(/\s+/, $Config::Config{sig_name}));
    }
}
my %THR_UNDEFINED_SIG = map { $_ => \&_sigtrap_handler_undefined } @TRAPPED_SIGNAL;
my %THR_DEFINED_SIG = map { $_ => \&_sigtrap_handler_defined } @TRAPPED_SIGNAL;
my @DEFERRED_SIGNAL = ();
$threads::SEND_IN_PROGRESS = 0;
$threads::RECV_IN_PROGRESS = 0;
$threads::RECV_DATA = '';
my $CUSTOM_SIGCHLD = 0;
my $MAX_POLL_SLEEP = 60;    #seconds
my %WRITE;
my %DONEWITH;
my $TID;
my $PID;
my $THREAD_CONTEXT;
my %CLONE;
our %CLONE_SKIP;
our %CLONE_SKIP_REF;

# Initialize the next thread ID to be issued
# Initialize hash (key: tid) with the thread id to client object translation
# Initialize hash (key: client) with the client object to thread id translation
# Initialize hash (key: tid) with the thread id to process id translation
# Initialize hash (key: pid) with the process id to thread id translation
# Initialize hash (key: ppid) with the parent pid to child tid queue (value: array ref)
# Initialize hash (key: tid) with the thread id to thread join context translation
# Initialize hash (key: tid) with the thread id to thread stack size translation

my $NEXTTID = 0;
my %TID2CLIENT;
my %CLIENT2TID;
my %TID2PID;
my %PID2TID;
my %PPID2CTID_QUEUE;
my %TID2CONTEXT;
my %TID2STACKSIZE;

# Initialize flag with global thread exit method (1=thread; 0=check %THREAD_EXIT)
# Initialize hash (key: tid) with threads that should threads->exit() on exit()
# Initialize scalar with tid's (comma-separated) that have been detached
# Initialize hash (key: tid) with detached threads are still running
# Initialize hash (key: tid) with results from threads
# Initialize hash (key: tid) with terminal errors from threads
# Initialize hash (key: tid) with threads that have not yet been joined

my $THREADS_EXIT = 0;
my %THREAD_EXIT;
my $DETACHED = '';
my %DETACHED_NOTDONE;
my %RESULT;
my %ERROR;
my %NOTJOINED;

# Initialize hash (key: ppid) with clients blocking of ppid->ctid conversion
# Initialize hash (key: tid) with clients blocking for join() result
# Initialize period (seconds) of BLOCKING_JOIN check (abnormal thread death protection)
# Initialize time of next BLOCKING_JOIN check

my %BLOCKING_PPID2CTID_QUEUE;
my %BLOCKING_JOIN;
my $BLOCKING_JOIN_CHECK_PERIOD = 15;
my $BLOCKING_JOIN_CHECK_TS_NEXT = 0;

# Initialize hash (key: fq sub) with code references to tie subroutines
# List with objects of shared (tied) variables
# Ordinal number of next shared (tied) variable

my %DISPATCH;
my @TIED;
my $NEXTTIED = 1;

# Initialize list (key: ordinal) of threads that have the lock for a variable
# Initialize hash (key: ordinal) of TID caller information from the (non-recursive) lock()
# Initialize list (key: ordinal) of threads that have a recursive lock
# Initialize list (key: ordinal) of threads that want to lock a variable
# Initialize list (key: ordinal) of threads are waiting in cond_wait
# Initialize hash (key: ordinal) of threads are waiting in cond_timedwait
# Initialize scalar representing unique ID of each timed event
# Initialize list (order: expiration time) representing a sorted version (pseudo-index) of %TIMEDWAITING
# Initialize scalar indicating when %TIMEDWAITING has changed and @TIMEDWAITING_IDX should be recalculated
# Initialize list (key: ordinal; subkey: tid) of TIMEDWAITING events that have timed out

my @LOCKED;
my %TID2LOCKCALLER;
my @RECURSED;
my @LOCKING;
my @WAITING;
my %TIMEDWAITING;
my $TIMEDWAITING_ID = 0;
my @TIMEDWAITING_IDX;
my $TIMEDWAITING_IDX_EXPIRED = 0;
my @TIMEDWAITING_EXPIRED;

# Initialize hash (key: tid, value=signal) with clients to send sigals to

my %TOSIGNAL;

# Flag indicating whether deadlock detection enabled (default: disabled)
# Deadlock detection period (0 => sync detection; else async detect every N sec)
# Time of next deadlock detection event, if in asynchronous mode
# Initialize hash (key: tid; value: tid of blocker) with clients that are deadlocked
# Flag of whether server should terminate one thread of each deadlocked thread pair
# Signal to use to kill deadlocked processes

my $DEADLOCK_DETECT = 0;
my $DEADLOCK_DETECT_PERIOD = 0;
my $DEADLOCK_DETECT_TS_NEXT = 0;
my %DEADLOCKED;
my $DEADLOCK_RESOLVE = 0;
my $DEADLOCK_RESOLVE_SIG = SIGKILL;

# Create packed version of undef
# Create packed version of zero-length string
# Create packed version of false
# Create packed version of true
# Create packed version of empty list

my $undef = _pack_response( [undef],  );
my $defined = _pack_response( [''],  );
my $false = _pack_response( [0], '__boolean' );
my $true  = _pack_response( [1], '__boolean' );
my $empty = _pack_response( [],  );

# Miscellaneous command-related constants
# Command filters (closures) for optimized request/response handling

my %cmd_filter;
my @cmd_filtered;
my @cmd_num_to_filter;
my @cmd_num_to_type;
my %cmd_type_to_num;
BEGIN {
    use constant CMD_FLTR_REQ    => 0;
    use constant CMD_FLTR_RESP   => 1;
    use constant CMD_FLTR_ENCODE => 0;
    use constant CMD_FLTR_DECODE => 1;

    use constant CMD_TYPE_DEFAULT    => 0;   #entire content is frozen
    use constant CMD_TYPE_INTERNAL   => 1;   #msg has a custom filter

    use constant MSG_LENGTH_LEN                  => 4;
    use constant CMD_TYPE_IDX                    => 0;
    use constant CMD_TYPE_LEN                    => 1;
    use constant CMT_TYPE_FROZEN_CONTENT_IDX     => 1;
    use constant CMD_TYPE_INTERNAL_SUBNAME_IDX   => 1;
    use constant CMD_TYPE_INTERNAL_SUBNAME_LEN   => 2;
    use constant CMD_TYPE_INTERNAL_CONTENT_IDX   => 3;
    %cmd_filter = (  #pack: 1 arrayref input param; unpack: 1 scalar input param; pack/unpack: list output
        __boolean   => [    #client-to-server
            [   #request
                sub { $_[0]->[0] ? '1' : '0'; }, #pack
                sub { $_[0]; }  #unpack
            ],
            [   #response
                sub { $_[0]->[0] ? '1' : '0'; }, #pack
                sub { $_[0]; }  #unpack
            ],
        ],
    );
    %cmd_filter = (  #pack: 1 arrayref input param; unpack: 1 scalar input param; pack/unpack: list output
        %cmd_filter,
        _lock   => [    #client-to-server
            [   #request
                sub { pack('IIa*', @{$_[0]}[0..2]); }, #pack
                sub { unpack('IIa*', $_[0]); }  #unpack
            ],
            $cmd_filter{__boolean}->[CMD_FLTR_RESP]   #response
        ],
        _unlock   => [    #client-to-server
            [   #request
                sub { pack('I', $_[0]->[0]); }, #pack
                sub { unpack('I', $_[0]); }  #unpack
            ],
            $cmd_filter{__boolean}->[CMD_FLTR_RESP]   #response
        ],
    );
    @cmd_filtered = sort { lc($a) cmp lc($b) } keys %cmd_filter;
    for (my $i = 0; $i < scalar @cmd_filtered; $i++) {
        $cmd_num_to_filter[$i] = $cmd_filter{$cmd_filtered[$i]};
        $cmd_num_to_type[$i] = $cmd_filtered[$i];
        $cmd_type_to_num{$cmd_filtered[$i]} = $i;
    }
} #BEGIN

# Make sure that equality works on thread objects

use overload
 '==' => \&equal,
 '!=' => \&nequal,
 'fallback' => 1,
;

# Keep reference to pre-existing exit function
my $old_core_global_exit;
BEGIN {
    $old_core_global_exit = sub { CORE::exit(@_) };
}

# Create new() -> create() equivalence
# Initialize thread server at runtime, in case import was skipped

*create = \&new; create() if 0; # to avoid warning
_init() unless $forks::DEFER_INIT_BEGIN_REQUIRE;

# Functions to allow external modules an API hook to specific runtime states
# These may be used to build a new CORE::GLOBAL::fork state
# General rule is that forks.pm will never define anything but CORE::fork
#  in _fork function, so this is the function to overload if you must
#  completely handle the core fork event; otherwise, all other methods
#  should be referenced and called like:
#    my $_old_fork_post_child = \&threads::_fork_post_child;
#    *threads::_fork_post_child = sub {
#        $_old_fork_post_child->();
#        ...
#    }
#  when building a new CORE::GLOBAL::fork state.
#  See forks.pm CORE::GLOBAL::fork definition as an example.

# Block all process signals when forking, to insure most stable behavior.
my $_fork_block_sigset;
BEGIN {
    $_fork_block_sigset = POSIX::SigSet->new();
    $_fork_block_sigset->fillset();
}

sub _fork_pre {

# Block all signals during fork to prevent interruption

    POSIX::sigprocmask(SIG_BLOCK, $_fork_block_sigset);
} #_fork_pre
sub _fork { return CORE::fork; } #_fork
sub _fork_post_parent {

# Restore signals blocked during fork

    POSIX::sigprocmask(SIG_UNBLOCK, $_fork_block_sigset);
} #_fork_post_parent
sub _fork_post_child {

# Restore signals blocked during fork
# Reset some important state variables
# Reset CORE::GLOBAL::exit(); will be redefined in _init_thread

    POSIX::sigprocmask(SIG_UNBLOCK, $_fork_block_sigset);
    delete $ISATHREAD{$$};
    undef( $TID );
    undef( $PID );
    {
        no warnings 'redefine';
        *CORE::GLOBAL::exit = $old_core_global_exit;
    }
} #_fork_post_child

# Overload global fork for best protection against external fork.

BEGIN {
    no warnings 'redefine';
    *CORE::GLOBAL::fork = *CORE::GLOBAL::fork = sub {
    
# Perform the fork
# Handle post-fork in parent and child processes, if fork was successful
# Return the forked pid
        
        _fork_pre(@_);
        my $pid = _fork(@_);
        if (defined $pid) {
            if ($pid == 0) { #in child
                _fork_post_child(@_);
            } else {
                _fork_post_parent(@_);
            }
        }
        return $pid;
    };
} #BEGIN

# Overload global, Time::HiRes sleep functions to reduce CHLD signal side-effects
# Define flag toggled when REAPER has been called but user hasn't defined handler

our $IFNDEF_REAPER_CALLED = 0;
BEGIN {
    no warnings 'redefine';

# Store Time::HiRes sleep function for internal use

    my $proto = prototype 'CORE::sleep';
    my $sleep = *sleep = *sleep = \&Time::HiRes::sleep;
    my $sub = sub {

# Get requested sleep time
# Initialize a few variables
# Localize signal indicator for use only for this system call
# While sleep time hasn't yet been exhausted
#  Calculate remaining sleep time
#  Reset signal indicator
#  Sleep and store total time slept
#  Exit loop if sleep exited for some reason other than a CHLD signal
# Return total time slept

        my $s = shift;
        my $t = 0;
        my $f = 0;
        my $sig;
        local $IFNDEF_REAPER_CALLED;
        while ($s - $t > 0) {
            $s -= $t;
            $IFNDEF_REAPER_CALLED = 0;
            $f += $t = $sleep->($s);
            last unless $IFNDEF_REAPER_CALLED;
        }
        return sprintf("%.0f", $f); 
    };
    Scalar::Util::set_prototype(\&{$sub}, $proto);
    *CORE::GLOBAL::sleep = *CORE::GLOBAL::sleep = $sub;

# Generate same function wrapper for Time::HiRes sleep, usleep, and nanosleep.
# For usleep and nanosleep, only overload if they are defined.

    $proto = prototype 'Time::HiRes::sleep';
    $sub = sub {
        my $s = shift;
        my $t = 0;
        my $f = 0;
        my $sig;
        local $IFNDEF_REAPER_CALLED;
        while ($s - $t > 0) {
            $s -= $t;
            $IFNDEF_REAPER_CALLED = 0;
            $f += $t = $sleep->($s);
            last unless $IFNDEF_REAPER_CALLED;
        }
        return $f; 
    };
    Scalar::Util::set_prototype(\&{$sub}, $proto);
    *Time::HiRes::sleep = *Time::HiRes::sleep = $sub;

    if (&Time::HiRes::d_usleep
        && defined(my $t = eval { Time::HiRes::usleep(0) }) && !$@) {
        $proto = prototype 'Time::HiRes::usleep';
        my $usleep = \&Time::HiRes::usleep;
        $sub = sub {
            my $s = shift;
            my $t = 0;
            my $f = 0;
            my $sig;
            local $IFNDEF_REAPER_CALLED;
            while ($s - $t > 0) {
                $s -= $t;
                $IFNDEF_REAPER_CALLED = 0;
                $f += $t = $usleep->($s);
                last unless $IFNDEF_REAPER_CALLED;
            }
            return $f; 
        };
        Scalar::Util::set_prototype(\&{$sub}, $proto);
        *Time::HiRes::usleep = *Time::HiRes::usleep = $sub;
    }

    if (&Time::HiRes::d_nanosleep
        && defined(my $t = eval { Time::HiRes::nanosleep(0) }) && !$@) {
        $proto = prototype 'Time::HiRes::nanosleep';
        my $nanosleep = \&Time::HiRes::nanosleep;
        $sub = sub {
            my $s = shift;
            my $t = 0;
            my $f = 0;
            my $sig;
            local $IFNDEF_REAPER_CALLED;
            while ($s - $t > 0) {
                $s -= $t;
                $IFNDEF_REAPER_CALLED = 0;
                $f += $t = $nanosleep->($s);
                last unless $IFNDEF_REAPER_CALLED;
            }
            return $f; 
        };
        Scalar::Util::set_prototype(\&{$sub}, $proto);
        *Time::HiRes::nanosleep = *Time::HiRes::nanosleep = $sub;
    }
} #BEGIN

#---------------------------------------------------------------------------

# class methods

#---------------------------------------------------------------------------
#  IN: 1 class
#      2 subroutine reference of sub to start execution with
#      3..N any parameters to be passed
# OUT: 1 instantiated object

sub new {

# Obtain the class
# Obtain the subroutine reference
# Initialize some local vars
# Parse stack_size of this object (if new called with object reference)
# If sub is a hash ref
#  Assume thread-specific params were defined
#  Obtain the actual subroutine
#  Parse stack_size
#  Parse thread context (presidence given to param over implicit context)
#  Parse thread exit behavior
# Else
#  Store implicit thread context
    my $class = shift;
    my $sub = shift;
    my ($param, $stack_size, $thread_context, $thread_exit);
    if (ref($class) && defined( my $size = $class->get_stack_size )) {
        $stack_size = $size;
    }
    if (ref($sub) eq 'HASH') {
        $param = $sub;
        $sub = shift;
        if (exists $param->{'stack_size'} && defined $param->{'stack_size'}) {
            $stack_size = $param->{'stack_size'};
        }
        if (exists $param->{'stack'} && defined $param->{'stack'}) {
            $stack_size = $param->{'stack'};
        }
        if ((exists $param->{'context'} && $param->{'context'} =~ m/^list|array$/o)
            || (exists $param->{'list'} && $param->{'list'} || (exists $param->{'array'} && $param->{'array'})))
        {
            $thread_context = 1;
        } elsif ((exists $param->{'context'} && $param->{'context'} eq 'scalar')
            || (exists $param->{'scalar'} && $param->{'scalar'}))
        {
            $thread_context = 0;
        } elsif ((exists $param->{'context'} && $param->{'context'} eq 'void')
            || (exists $param->{'void'} && $param->{'void'}))
        {
            $thread_context = undef;
        } else {
            $thread_context = CORE::wantarray;
        }
        
        if (exists $param->{'exit'}) {
            if ($param->{'exit'} eq EXIT_THREAD_ONLY) {
                $thread_exit = EXIT_THREAD_ONLY;
            } elsif ($param->{'exit'} eq EXIT_THREADS_ONLY) {
                $thread_exit = EXIT_THREADS_ONLY;
            }
        }
    } else {
        $thread_context = CORE::wantarray;
    }

# If it is not a code ref yet (other refs will bomb later)
#  Make the subroutine fully qualified if it is not yet
#  Turn the name into a reference

    unless (ref($sub)) {
        $sub = caller().'::'.$sub unless $sub =~ m#::#;
        $sub = \&{$sub};
    }

# Initialize the process id of the thread
# Get results of _run_CLONE_SKIP
# If it seems we're in the child process
#  If the fork failed
#   Print a detailed warning
#   Return undefined to indicate the failure

    my $pid;
    my $clone_skip = _run_CLONE_SKIP();
    unless ($pid = fork) {
        unless (defined( $pid )) {
            warnings::warnif("Thread creation failed: Could not fork child from pid $$, tid $TID: ".($! ? $! : ''));
            return undef;
        }

#  Set up the connection for handling queries
#  Set appropriate thread exit behavior
#  If thread context is defined
#   If context is list
#    Execute the routine that we're supposed to execute (list context)
#   Else
#    Execute the routine that we're supposed to execute (scalar context)
#  Else
#    Execute the routine that we're supposed to execute (void context)
#  Print warning if thread terminated abnormally (if not main thread)
#  Mark this thread as shutting down
#  Save the result
#  And exit the process

        _init_thread($clone_skip, $thread_context, undef, $stack_size);
        if (defined($thread_exit) && $thread_exit eq EXIT_THREAD_ONLY) {
            threads->set_thread_exit_only(1);
        } elsif (defined($thread_exit) && $thread_exit eq EXIT_THREADS_ONLY) {
            _command( '_set_threads_exit_only',1 );
        }
        my @result;
        my $error;
        if (defined $thread_context) {
            if ($thread_context) {
                eval { @result = $sub->( @_ ); };
            } else {
                eval { $result[0] = $sub->( @_ ); };
            }
        } else {
            eval { $sub->( @_ ); };
        }
#warn "$TID: context = ".(defined $thread_context ? $thread_context ? 'array' : 'scalar' : 'void').",result (".scalar(@result).")=".CORE::join(',',@result); #TODO: for debugging only
        if ($@) {
            $error = $@;
            warn "Thread $TID terminated abnormally: $@"
                if $TID && warnings::enabled();
        }
        $SHUTTING_DOWN = 1;
        _command( '_tojoin',$error,@result );
        CORE::exit();
    }

# Mark PID for reaping, if using custom CHLD signal handler
# Obtain the thread id from the thread just started
# Create an object for it and return it

    $CHILD_PID{$pid} = undef;
    my ($tid) = _command( '_waitppid2ctid',$$ );
    $class->_object( $tid,$pid );
} #new

#---------------------------------------------------------------------------

sub isthread {

# Die now if this process is already marked as a thread
# Set up stuff so this process is now a detached thread
# Mark this thread as a detached thread (and run clone skip, even though we're not in parent)

    _croak( "Process $$ already registered as a thread" )
     if exists( $ISATHREAD{$$} );
    _init_thread( _run_CLONE_SKIP(), undef, 1 );
} #isthread

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new value of debug flag (optional)
# OUT: 1 current value of debug flag

sub debug { $DEBUG = $_[1] if @_ > 1; $DEBUG } #debug

#---------------------------------------------------------------------------
#  IN: 1 class or instantiated object
# OUT: 1 thread id

sub tid {

# Obtain the object
# Return the thread local tid if called as a class method
# Return the field in the object, or fetch and set and return that

    my $self = shift;
    return $TID unless ref($self);
    $self->{'tid'} ||= _command( '_pid2tid',$self->{'pid'} );
} #tid

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
# OUT: 1 instantiated object

sub self { shift->_object( $TID,$$ ) } #self

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 thread id
# OUT: 1 instantiated object or undef if no thread by that tid or detached

sub object {

# Obtain the parameters
# If there is a defined thread id (and tid is not main thread)
#  Obtain the associated process id
#  Return blessed object if we actually got a process id
# Indicate we couldn't make an object

    my ($class,$tid) = @_;
    if (defined($tid) && $tid != 0) {
        return if $tid == 0;
        my $pid = _command( '_tid2pid',$tid );
        return $class->_object( $tid,$pid ) if defined( $pid );
    }
    undef;
} #object

#---------------------------------------------------------------------------
#  IN: 1 class
#  IN: 2 (optional) boolean value indicating type of list desired
# OUT: 1..N instantiated objects

sub list {

# Obtain the class
# Obtain the hash with process ID's keyed to thread ID's
# Initialize list of objects
# For all of the threads, ordered by ID
#  Add instantiated object for this thread
# Return the list of instantiated objects, or num of objects in scalar context

    my $class = shift;
    my %hash = _command( '_list_tid_pid', @_ );
    my @object;
    foreach (sort {$a <=> $b} keys %hash) {
        push( @object,$class->_object( $_,$hash{$_} ) );
    }
    wantarray ? @object : scalar @object;
} #list

#---------------------------------------------------------------------------

sub yield { sleep 0.001; } #yield

#---------------------------------------------------------------------------
#  IN: 1 class or instantiated object
# OUT: 1..N state of the indicated thread

sub is_detached { _command( '_is_detached',shift->tid ) } #is_detached

#---------------------------------------------------------------------------
#  IN: 1 class or instantiated object
# OUT: the memory location of the internal thread structure
# Note: this won't guarantee reusable address, as it's dynamically generated

sub _handle {

# Obtain the class or object
# If is an object, return address of object
# Otherwise, return address of class

    my $self = shift;
    return refaddr( $self->_object( $self->tid,$self->{'pid'} ) )
        if ref($self);
    return refaddr( $self->_object( $self->tid,$$ ) );

} #_handle

#---------------------------------------------------------------------------
#  IN: 1 class or instantiated object
# OUT: the thread (process) stack size

sub get_stack_size {

# Obtain the class or object
# Return the current size

    my $self = shift;
    return _command( '_get_set_stack_size',ref($self) ? $self->tid : undef );
} #get_stack_size

#---------------------------------------------------------------------------
#  IN: 1 class or instantiated object
#      2 new default stack size
# OUT: the old default thread (process) stack size

sub set_stack_size { shift; return _command( '_get_set_stack_size',undef,shift() ) } #set_stack_size

#---------------------------------------------------------------------------
#  IN: 1 class
#  IN: 2 exit status

sub exit {
    shift;
    defined $_[0] ? CORE::exit($_[0]) : CORE::exit();
} #exit

#---------------------------------------------------------------------------

# instance methods

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#  IN: 2 boolean value
# OUT: 1..N error result (if any) of the indicated thread

sub set_thread_exit_only {
    _command( '_set_thread_exit_only',shift->tid,shift );
} #set_thread_exit_only

#---------------------------------------------------------------------------
#  IN: 1 class or instantiated object
# OUT: 1..N state of the indicated thread

sub wantarray {

# Obtain the class or object
# If is an object, return thread context of specified thread
# Otherwise, return thread context of current thread

    my $self = shift;
    return _command( '_wantarray',$self->tid ) if ref($self);
    return $THREAD_CONTEXT;
} #wantarray

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1..N results of the indicated thread

sub detach {

# Obrain the result
# Die if an error occured
# Otherwise, return true

    my ($success, $errtxt) = _command( '_detach',shift->tid );
    Carp::croak($errtxt) unless $success;
    return 1;
} #detach

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1..N results of the indicated thread

sub join {

# Obrain the result
# Die if an error occured
# Otherwise, return joined result (returned by joined thread) in appropriate context

    my ($success, @result) = _command( '_join',shift->tid );
    Carp::croak(@result) unless $success;
    return defined CORE::wantarray ? CORE::wantarray ? @result : $result[-1] : ();
} #join

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1..N error result (if any) of the indicated thread

sub error { _command( '_error',shift->tid ) } #error

#---------------------------------------------------------------------------
#  IN: 1 instantiated threads object
#      2 other instantiated threads object
# OUT: 1 whether they refer to the same thread

sub equal { $_[0]->tid == $_[1]->tid } #equal

#---------------------------------------------------------------------------
#  IN: 1 instantiated threads object
#      2 other instantiated threads object
# OUT: 1 whether they refer to the same thread

sub nequal { $_[0]->tid != $_[1]->tid } #nequal

#---------------------------------------------------------------------------
#  IN: 1 instantiated threads object
# OUT: 1 tid of the object

sub stringify { $_[0]->tid } #stringify

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 state of the indicated thread

sub is_running { _command( '_is_running',shift->tid ) } #is_running

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 state of the indicated thread

sub is_joinable { _command( '_is_joinable',shift->tid ) } #is_joinable

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 state of the indicated thread

sub is_deadlocked { _command( '_is_deadlocked',shift->tid ) } #is_deadlocked

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 signal number or name to send
# OUT: 1 thread object

sub kill {

# Get the object
# Get the signal
# Die if incorrect usage
# Return immediately if no signal defined
# Die unless signal is valid
# Send signal
# Return thread object

    my $self = shift;
    my $signal = shift;
    Carp::croak("Usage: \$thr->kill('SIG...')") unless blessed($self);
    return $self unless defined $signal;
    Carp::croak("Unrecognized signal name or number: $signal")
        unless grep(/^$signal$/,
            map('SIG'.$_, split(/\s+/, $Config::Config{sig_name})),
            split(/\s+/, $Config::Config{sig_name}),
            split(/\s+/, $Config::Config{sig_num}));
    _command( '_kill',$self->tid,$signal );
    $self;
} #kill

#---------------------------------------------------------------------------

# exportables

#---------------------------------------------------------------------------
#  IN: 1 subroutine reference of sub to start execution with
#      2..N any parameters to be passed
# OUT: 1 instantiated object

sub async (&;@) {
    if (defined CORE::wantarray) {
        if (CORE::wantarray) {
            my @result = new( 'threads',@_ );
        } else {
            my $result = new( 'threads',@_ );
        }
    } else {
        new( 'threads',@_ );
    }
} #async

#---------------------------------------------------------------------------

# standard Perl features

#---------------------------------------------------------------------------
# Default reaper, if using custom CHLD signal handler (prevents thread zombies)

sub REAPER {

# Localize system error and status variables
# Toggle flag indicating that reaper was called, if user hasn't defined a CHLD handler
# For just child thread processes, loop and reap
#  If we are main thread, exit if shared process exited and main thread running

    local $!; local $?;
    $IFNDEF_REAPER_CALLED = 1 unless forks::signals->is_sig_user_defined('CHLD');
    while (my $pid = each %CHILD_PID) {
        my $waitpid = waitpid($pid, WNOHANG);
        if (defined($waitpid) && $waitpid == $pid && (WIFEXITED($?) || WIFSIGNALED($?))) {
            delete( $CHILD_PID{$pid} );
            if ($$ == $PID_MAIN_THREAD) {
                CORE::exit() if $waitpid == $SHARED && !$MAIN_EXIT_WITH_ABRT;
            }
        }
    }
} #REAPER

#---------------------------------------------------------------------------
# Shared server reaper

sub REAPER_SHARED_DAEMON {

# Localize system error and status variables
# While we have zombie processes, loop and reap
#  Store exit value if process was main thread and exit value not already set
#  Immediately exit shared server

    local $!; local $?;
    while ((my $pid = waitpid(-1, WNOHANG)) > 0) {
        if ($pid == $PID_MAIN_THREAD && (WIFEXITED($?) || WIFSIGNALED($?))) {
            $EXIT_VALUE = ($? >> 8) & 0xFF unless defined($EXIT_VALUE);
            $RUNNING = 0;
        }
    }
} #REAPER_SHARED_DAEMON

#---------------------------------------------------------------------------
# Special ABRT signal handler for main thread

sub _sigtrap_handler_main_abrt {

# Revert to system default CHLD handler (most portable exit behavior)
# Just reutrn if ABRT already handled, or if main thread is shutting down
# Mark main thread as exiting due to ABRT from shared process
# Exit immediately

    $forks::signals::sig->{CHLD} = 'DEFAULT';
    return if $MAIN_ABRT_HANDLED++ || $SHUTTING_DOWN || $SHUTTING_DOWN_END;
    $MAIN_EXIT_WITH_ABRT = 1;
    CORE::exit();
} #_sigtrap_handler_main_abrt

#---------------------------------------------------------------------------
# Default sigtrap handler

sub _sigtrap_handler_defined {

# Obtain the signal sent
# If valid signal and this is a valid thread
#  If not main thread and currently not exchanging with server
#   Add signal to deferred list unless it is already in the list
#   Return immediately with false (void) value
# Return with true value

    my ($sig) = @_;
    if ($sig && exists($ISATHREAD{$$}) && defined($PID) && $$ == $PID) {
        if ($threads::SEND_IN_PROGRESS
                || ($threads::RECV_IN_PROGRESS && length($threads::RECV_DATA) > 0)) {
            push @DEFERRED_SIGNAL, $sig unless grep(/^$sig$/, @DEFERRED_SIGNAL);
            return;
        }
    }
    return 1;
}

sub _sigtrap_handler_undefined {

# Call defined thread sig handler routine (to handle deferred signal logic, if required)
# If valid signal and this is a valid thread (not main thread)
#  Print a general warning
# Mark this thread as shutting down (for quiet exit)
# Exit

    my ($sig) = @_;
    return unless _sigtrap_handler_defined(@_);
    if ($sig && exists($ISATHREAD{$$}) && defined($PID) && $$ == $PID && $TID) {
        print STDERR "Signal SIG$sig received, but no signal handler set"
            ." for thread $TID\n"
            if warnings::enabled('threads');
    }
    $SHUTTING_DOWN = 1;
    CORE::exit();
} #_sigtrap_handler_undefined

#---------------------------------------------------------------------------
# Shared variable server sigtrap handler

sub _sigtrap_handler_shared {

# Obtain the signal sent
# Propegate signal to main thread

    my ($sig) = @_;
    CORE::kill($sig, $PID_MAIN_THREAD);
} #_sigtrap_handler_shared

#---------------------------------------------------------------------------
# Default module initializaton handler

sub _init {

# Return if module already initialized

    return if $HANDLED_INIT;

_log( " ! global startup" ) if DEBUG;

# Create a server that can only take one connection at a time or die now
# Find out the port we're running on and save that for later usage
# Make sure that the server is non-blocking

    if ($THREADS_UNIX) {
        _croak( "UNIX socket file '$THREADS_UNIX$$' in use by non-socket file" )
            if -e $THREADS_UNIX.$$ && !-S $THREADS_UNIX.$$;
        _croak( "Unable to delete UNIX socket file '$THREADS_UNIX$$'" )
            if -S $THREADS_UNIX.$$ && !unlink($THREADS_UNIX.$$);
        $QUERY = IO::Socket::UNIX->new(
         Local  => $THREADS_UNIX.$$,
         Listen => SOMAXCONN,
        ) or _croak( "Couldn't start the listening server: $@" );
        chmod 0777, $THREADS_UNIX.$$;
        $PORT = $THREADS_UNIX.$$;
    } else {
        $QUERY = IO::Socket::INET->new(
         LocalAddr => '127.0.0.1',
         Listen    => SOMAXCONN,
        ) or _croak( "Couldn't start the listening server: $@" );
        $PORT = $QUERY->sockport;
    }
    _nonblock( $QUERY );

# Perform the fork
# Die if the fork really failed

    my $forkpid = fork;
    _croak( "Could not start initial fork" ) unless defined( $forkpid );

# If shared server should be child process of main thread
#  If we are in the parent (main thread)
#   Do stuff
#  Else (we are in the child (shared server))
#   Do stuff
# Else
#  If we are in the parent (shared server)
#   Do stuff
#  Else (we are in the child (main thread))
#   Do stuff

    if ($THREADS_INTEGRATED_MODEL) {
        if ($forkpid) {
            $PID_MAIN_THREAD = $$;
            $SHARED = $forkpid;
            _init_main(1);
        } else {
            $PID_MAIN_THREAD = getppid();
            $SHARED = $$;
            _server_pre_startup();
            _init_server();
        }
    } else {
        if ($forkpid) {
            $PID_MAIN_THREAD = $forkpid;
            $SHARED = $$;
            _server_pre_startup();
            _init_server(1);
        } else {
            $PID_MAIN_THREAD = $$;
            $SHARED = getppid();
            _init_main();
        }
    }

# Mark forks initialization as complete

    $HANDLED_INIT = 1;
} #_init

#---------------------------------------------------------------------------
# Default main thread initialization handler

sub _init_main {
    my $is_parent = shift;

# Use forks::signal to overload %SIG for safest forks-aware signal behavior

# TODO: consider this case as a less-invasive signal handling system, for
#       cases where users wish to have fully overloadable signals via %SIG
#    foreach (@TRAPPED_SIGNAL) {
#        import sigtrap 'handler', (defined($SIG{$_})
#            ? \&_sigtrap_handler_defined
#            : \&_sigtrap_handler_undefined), $_;
#    }
#    import sigtrap ('handler', \&_sigtrap_handler_main_abrt, 'ABRT');
#    import sigtrap ('handler', ($FORCE_SIGCHLD_IGNORE ? 'IGNORE' : \&REAPER), 'CHLD');
    import forks::signals
        ifndef => {
            %THR_UNDEFINED_SIG,
            ABRT => \&_sigtrap_handler_main_abrt,
            CHLD => $FORCE_SIGCHLD_IGNORE ? 'IGNORE' : [\&REAPER, SA_NOCLDSTOP | SA_RESTART]
        },
        ifdef => {
            %THR_DEFINED_SIG,
            ABRT => \&_sigtrap_handler_main_abrt,
            CHLD => $FORCE_SIGCHLD_IGNORE ? 'IGNORE' : \&REAPER
        };

# Make this thread 0

    _init_thread(_run_CLONE_SKIP());
} #_init_main

#---------------------------------------------------------------------------
# Default thread server initializaton handler

sub _init_server {
    my $is_parent = shift;

# Reset all signal handlers to default
# If is parent
#  Configure signal handlers
#  Configure child signal handler
# Prevent server taking over TTY on exit when in debugger
# Start handling requests as the server

    delete( @SIG{keys %SIG} );
    if ($is_parent) {
        import sigtrap ('handler', \&_sigtrap_handler_shared,
            qw(normal-signals USR1 USR2 die error-signals));
        $SIG{CHLD} = \&REAPER_SHARED_DAEMON;
    }

    $DB::inhibit_exit = 0;
    &_server;
} #_init_server

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2..N subroutines to export (default: async only)

sub import {

# Obtain the class

    my $self = shift;

# Overload string context of thread object to return TID, if requested

    if ((my $idx = List::MoreUtils::firstidx(
        sub { $_ eq 'stringify' }, @_)) >= 0) {
        import overload '""' => \&stringify;
        splice(@_, $idx, 1);
    }

# Initialize module thread server process, if required

    _init();

# Set exit context of threads, if requested

    if ((my $idx = List::MoreUtils::firstidx(
        sub { $_ eq 'exit' }, @_)) >= 0) {
        my @args = splice(@_, $idx, 2);
        if ($args[1] eq EXIT_THREADS_ONLY) {
            _command( '_set_threads_exit_only',1 );
        } elsif ($args[1] eq EXIT_THREAD_ONLY) {
            threads->set_thread_exit_only(1);
        }
    }

# Set thread stack size, if requested

    if ((my $idx = List::MoreUtils::firstidx(
        sub { $_ eq 'stack_size' }, @_)) >= 0) {
        my @args = splice(@_, $idx, 2);
        _command( '_get_set_stack_size',undef,$ITHREADS_STACK_SIZE || $args[1] );
    }

# Perform the export needed

    _export( scalar(caller()),@_ );        
} #import

BEGIN {

# forks::shared and threads::shared share same import method

    *forks::import = *forks::import = \&import;
} #_BEGIN

# Functions to allow external modules an API hook to specific runtime states

sub _server_pre_startup {}
sub _server_post_startup {}
sub _end_server_pre_shutdown {}
sub _end_server_post_shutdown {}

#---------------------------------------------------------------------------

my $END_CALLED;
sub _END {

# Revert to default CHLD handler to insure portable, reliable shutdown
# Prevent ths subroutine from ever being called twice
# Localize $! and $? to prevent accidental override during shutdown
# If this process is the shared server
#  Calculate and report stats on running and/or unjoined threads (excluding main thread)
#  Forcefully terminate any lingering thread processes (except main thread)
#  Forcefully terminate main thread (allowing END block to perform cleanup)
#  Shutdown the socket server
#  Delete UNIX socket file if the socket file exists
#  Allow external modules opportunity to clean up thread process group resources
# If this process is a valid thread (including main thread if $THREADS_INTEGRATED_MODEL)
#  Mark this thread as shutting down
#  Reset CORE::GLOBAL::exit to default
#  Indicate that this process has been shut down to the server (if appropriate)
#  Mark this thread as shut down (so we won't send or receive anymore)
#  If this is main thread using non-daemon model
#   Wait a bit for shared process to exit (or hard kill if it doesn't respond)
#   Synchronize thread exit status with shared process (as required)
# Alter exit status, if required

    $forks::signals::sig->{CHLD} = 'DEFAULT';
    LOCALEXITBLOCK: {
        last if $END_CALLED;
        $END_CALLED = 1;
        local $!; local $?;
        if (!exists( $ISATHREAD{$$} ) && defined($SHARED) && $$ == $SHARED) {
            my $running_and_unjoined = 0;
            my $finished_and_unjoined = 0;
            my $running_and_detached = 0;
            foreach my $tid (grep(!/^0$/, keys %TID2PID)) {
                if ($DETACHED !~ m/\b$tid\b/) {
                    $running_and_unjoined++
                        if !exists $RESULT{$tid} && exists $NOTJOINED{$tid};
                    $finished_and_unjoined++ if exists $RESULT{$tid};
                }
            }
            foreach (grep(!/^0$/, keys %DETACHED_NOTDONE)) {
                $running_and_detached++;
            }

            print STDERR "Perl exited with active threads:\n"
                ."\t$running_and_unjoined running and unjoined\n"
                ."\t$finished_and_unjoined finished and unjoined\n"
                ."\t$running_and_detached running and detached\n"
                if ($running_and_unjoined 
                    || $finished_and_unjoined || $running_and_detached);

            my @pidtokill;
            while (my ($tid, $client) = each %TID2CLIENT) {
                eval {
                    my $written = send( $client,'',0 );
                    if (defined( $written )) {
                        push @pidtokill, $TID2PID{$tid}
                            if $tid && defined $TID2PID{$tid}
                                && CORE::kill(0, $TID2PID{$tid});
                    };
                };
            }
            CORE::kill('SIGKILL', $_) foreach @pidtokill;
            CORE::kill('SIGABRT', $PID_MAIN_THREAD)
                if !$MAIN_EXIT_NO_ABRT && CORE::kill(0, $PID_MAIN_THREAD);

            $QUERY->shutdown(2) if defined $QUERY;
            unlink($PORT) if $THREADS_UNIX && -S $PORT;

            _end_server_post_shutdown();
        } elsif (exists( $ISATHREAD{$$} ) && defined($PID) && $$ == $PID && ($THREADS_INTEGRATED_MODEL || $TID)) {
            $SHUTTING_DOWN_END = 1;
            {
                no warnings 'redefine';
                *CORE::GLOBAL::exit = $old_core_global_exit;
            }
            _command( '_shutdown',$TID )
                if CORE::kill(0, $SHARED) && ($TID > 0 || !$MAIN_ABRT_HANDLED);
            $SHUTDOWN = 1;

            if ($THREADS_INTEGRATED_MODEL && $TID == 0) {
                local $!;
                local $SIG{ALRM} = sub { die };
                alarm(3);
                eval { waitpid($SHARED, 0); alarm(0); };
                if ($@) {
                    CORE::kill('SIGHUP', $SHARED) if CORE::kill(0, $SHARED);   #TODO: do we really need to be this agressive?
                } else {
                    $EXIT_VALUE = ($? >> 8) & 0xFF if $MAIN_EXIT_WITH_ABRT;
                }
            }
        }
    }
    $? = $EXIT_VALUE if defined $EXIT_VALUE && !$END_CALLED;
} #_END

#---------------------------------------------------------------------------

sub _CHECK {

# Call end block routine
# Exit with non-zero value if shared server, to prevent multiple compile check reports

    _END();
    CORE::exit(1)
        if (!exists( $ISATHREAD{$$} ) && defined($SHARED) && $$ == $SHARED);
} #_CHECK

#---------------------------------------------------------------------------

# internal subroutines server-side

#---------------------------------------------------------------------------

sub _server {

# Set nice value if environment variable set and if we're running as root
# Mark the parent thread id as detached

    { my $oldfh = select(STDOUT); $| = 1; select($oldfh); }
    POSIX::nice( $SERVER_NICE ) if $SERVER_NICE && !$<;
    $DETACHED = $NEXTTID;

# Create the select object in which all the connections are stored
# Initialize the length of message to be received hash
# Initialize the received message hash
# Initialize the var to hold current time (for time calculations each loop)

    my $select = IO::Select->new( $QUERY );
    my %toread;
    my %read;
    my $curtime;
    
# Localize Storable variables to allow CODE refs, if using Storable >= 2.05

    local $Storable::Deparse = 1 if $Storable::VERSION >= 2.05;
    local $Storable::Eval = 1 if $Storable::VERSION >= 2.05;

# Initialize the number of polls
# While we're running in the main dispatch loop
#  Update timedwaiting index
#  Get current time
#  Load next event timedwaiting expiration time (if any)
#  Wait until there is something to do or a cond_timedwaiting event has expired
#  Get current time
#  Increment number of polls
#  Handle any timedwaiting events that may have expired

    my $polls = 0;
    _server_post_startup();
    while ($RUNNING || %DONEWITH) {
if (DEBUG) {
 my $clients = keys %WRITE;
 _log( " ! $clients>>" ) if $clients;
}
        my $write = (keys %WRITE)[0] || '';
        _update_timedwaiting_idx();
        $curtime = time();
        my ($sleep_min) = $write ? (.001) : List::MoreUtils::minmax(
            @TIMEDWAITING_IDX ? $TIMEDWAITING_IDX[0]->[2] - $curtime : $MAX_POLL_SLEEP,
            $DEADLOCK_DETECT_TS_NEXT ? $DEADLOCK_DETECT_TS_NEXT - $curtime : $MAX_POLL_SLEEP,
            $BLOCKING_JOIN_CHECK_TS_NEXT ? $BLOCKING_JOIN_CHECK_TS_NEXT - $curtime : $MAX_POLL_SLEEP        
        );
_log( " ! max sleep time = $sleep_min" ) if DEBUG;
        my @reading = $select->can_read( $sleep_min > 0 ? $sleep_min : 0.001 );
        $curtime = time();
_log( " ! <<".@reading ) if DEBUG and @reading;
        $polls++;
        _handle_timedwaiting();
        
#  For all of the clients that have stuff to read
#   If we're done with this client, ignore further input until socket closed
#   If this is a new client
#    Accept the connection
#    If using INET sockets
#     Check if client is in the allow list
#      Immediately close client socket if not in allow list
#      And reloop
#    Make sure the client is non-blocking

        foreach my $client (@reading) {
            next if exists( $DONEWITH{$client} );
            if ($client == $QUERY) {
                $client = $QUERY->accept();
                unless ($THREADS_UNIX) {
                    if ($INET_IP_MASK ne '' && $client->peerhost() !~ m/$INET_IP_MASK/) {
                        warn 'Thread server rejected connection: '
                            .$client->peerhost().':'.$client->peerport().' does not match allowed IP mask'."\n";
                        close( $client );
                        next;
                    }
                }
                _nonblock( $client );

#    Save refs to real client object keyed to thread id and stringified object
#    Make sure the reverse lookup will work
#    Add the client to the list of sockets that we can select on
#    Send the thread ID to the client and increment (now issued) thread ID
#    And reloop

_log( " ! adding thread $NEXTTID" ) if DEBUG;
                $TID2CLIENT{$NEXTTID} = $client;
                $CLIENT2TID{$client} = $NEXTTID;
                $select->add( $client );
                $WRITE{$client} = _pack_response( ['_set_tid',$NEXTTID++] );
                next;
            }

#   Initialize the number of bytes to be read per block
#   If we haven't received the length of the message yet
#    Obtain the length, reloop if no length yet
#    Reduce first read to exactly match block size

            my $size = $BUFSIZ;
            unless ($toread{$client}) {
                next unless $toread{$client} = _length( $client );
#_log( " <$CLIENT2TID{$client} $toread{$client} length" ) if DEBUG;
                $size -= MSG_LENGTH_LEN;
            }

#   Initialize scalar to receive data in
#   If something went wrong with reading
#    Die (we can't have this going about now can we)
#     unless call would block or was interrupted by signal
#   Add the data to the request read for this client if anything was read

            my $data;
            unless (defined( recv($client,$data,$size,0) ) and length($data)) {
                _croak( "Error ".($! ? $! + 0 : '')." reading from $CLIENT2TID{$client}: ".($! ? $! : '') )
                    unless ($! == EWOULDBLOCK || $! == EAGAIN || $! == EINTR);
            }
_log( " <$CLIENT2TID{$client} ".length($data)." of $toread{$client}" ) if DEBUG;
            $read{$client} .= $data if defined($data);
        }

#  For all of the clients for which we have read stuff
#   If we have read something already
#    If we have all we're expecting

        keys %read if RESET_EACH_ITER;
        while (my $client = each %read) {
            if (my $read = length( $read{$client} )) {
                if ($read == $toread{$client}) {
_log( " =$CLIENT2TID{$client} ".CORE::join(' ',(_unpack_request( $read{$client} ) || '')) ) if DEBUG;

#     Create untainted version of what we got
#     Go handle that
#     Remove the number of characters to read
#    Elseif we got too much
#     Die now

                    $read{$client} =~ m#^(.*)$#s;
                    _handle_request( $client,$1 );
                    delete( $toread{$client} );
                    delete( $read{$client} );
                } elsif ($read > $toread{$client}) {
                    _croak( "Got $read bytes, expected only $toread{$client} from $CLIENT2TID{$client}: ".CORE::join( ' ',_unpack_request( $read{$client} ) ) );
                }
            }
        }

#  While there is a client to which we can write
#   Verify that there still is data to be written (may have changed after read)
#   Try to write whatever there was to write
#   If write was successful
#    If number of bytes written exactly same as what was supposed to be written
#     Just remove everything that was supposed to be removed
#    Elsif we've written some but not all because of blocking
#     Remove what was written, still left for next time
#    Else (something seriously wrong)
#     Die now
#   Else (something seriously wrong)
#    Die now
#   Fetch the next client to write to

        while ($write && ($write = each %WRITE)) {
            unless (defined $WRITE{$write}) {
                delete( $WRITE{$write} );
                next;
            }
            my $written =
             send( $TID2CLIENT{$CLIENT2TID{$write}},$WRITE{$write},0 );
_log( " >$CLIENT2TID{$write} $written of ".length($WRITE{$write}) ) if DEBUG;
            if (defined( $written )) {
                if ($written == length( $WRITE{$write} )) {
                    delete( $WRITE{$write} );
                } else {
                    substr( $WRITE{$write},0,$written ) = '';
                }
            } elsif ($! == EWOULDBLOCK || $! == EAGAIN || $! == EINTR) {
                #defer writing this time around
            } elsif ($! == ECONNRESET && $CLIENT2TID{$write} == 0) {
                #main thread exited: wait for SIGCHLD
                delete( $WRITE{$write} );
            } else {
                _croak( "Error ".($! ? $! + 0 : '').": Could not write ".(length $WRITE{$write})
                    ." bytes to $CLIENT2TID{$write}: ".($! ? $! : '') );
            }
        }
my $error = [$select->has_exception( .1 )] if DEBUG;
if (DEBUG) { _log( " #$CLIENT2TID{$_} error" ) foreach @$error; }

#  If asynchronous deadlock detection enabled and next event time has expired

        if ($DEADLOCK_DETECT && $DEADLOCK_DETECT_PERIOD && $curtime >= $DEADLOCK_DETECT_TS_NEXT) {
            _detect_deadlock_all();
            $DEADLOCK_DETECT_TS_NEXT = $curtime + $DEADLOCK_DETECT_PERIOD;
        }

#  If deadlock resolution is enabled and there are deadlocked threads
#   Get only one thread from each pair of deadlocked threads
#   Schedule signal for each pid to terminate to resolve deadlock
#   Clear deadlocked thread list

        if ($DEADLOCK_RESOLVE && %DEADLOCKED) {
            my @tid_to_kill;
            while (my $tid = each %DEADLOCKED) {
                push @tid_to_kill, $tid
                    if defined $DEADLOCKED{$DEADLOCKED{$tid}}
                        && $tid == $DEADLOCKED{$DEADLOCKED{$tid}};
                delete $DEADLOCKED{$tid};
            }
            foreach my $tid (@tid_to_kill) {
                print STDERR "Deadlock resolution: Terminating thread"
                    ." $tid (PID $TID2PID{$tid}) with signal $DEADLOCK_RESOLVE_SIG\n"
                    if warnings::enabled();
                $TOSIGNAL{$tid} = $DEADLOCK_RESOLVE_SIG;
            }
            %DEADLOCKED = ();
        }

#  For all of the clients that we need to send signals to
#   Make sure we won't check this client again
#   Skip this client if it's already terminated
#   Send requested signal to appropriate thread
#   If signal was SIGKILL, manually handle clean up
#   (note: this assumes any other signal would result in process safe exit)

        while (my ($tid, $signal) = each %TOSIGNAL) {
            delete( $TOSIGNAL{$tid} );
            next unless defined $TID2CLIENT{$tid};
            my $success = _signal_thread($tid, $signal);
            CORE::kill('SIGKILL', $TID2PID{$tid})
                unless $success;
_log( "sent $TID2PID{$tid} signal ".($signal =~ m/^\d+$/ ? abs($signal) : $signal) ) if DEBUG;
            _cleanup_unsafe_thread_exit($tid)
                if !$success || $signal eq 'KILL' || $signal eq 'SIGKILL'
                    || ($signal =~ m/^\d+$/ && $signal == SIGKILL);
        }

# If next check time has expired
#  For all of the clients that are currently blocking on threads
#   Check that process is still alive; otherwise, cleanup dead thread
#    If that did not clear the waiting thread
#     Output a warning (from server)
#     Notify the thread with undef (should really be an error)
#  Also check that main thread is still alive
        if ($curtime >= $BLOCKING_JOIN_CHECK_TS_NEXT) {
            while (my $tid = each %BLOCKING_JOIN) {
                unless (CORE::kill(0, $TID2PID{$tid})) {
                    _cleanup_unsafe_thread_exit($tid);
                    if (exists $BLOCKING_JOIN{$tid}) {
                        warn "BLOCKING_JOIN manually cleared for tid #$tid";
                        $WRITE{$TID2CLIENT{$tid}} = $undef;
                    }
                }
            }
            $BLOCKING_JOIN_CHECK_TS_NEXT = $curtime + $BLOCKING_JOIN_CHECK_PERIOD;
            $RUNNING = 0 unless CORE::kill(0, $PID_MAIN_THREAD);
        }

#  For all of the clients that we're done with
#   Reloop if there is still stuff to send there
#   Make sure we won't check this client again

        keys %DONEWITH if RESET_EACH_ITER;
        while (my $client = each %DONEWITH) {
            next if $RUNNING && exists( $WRITE{$client} );
_log( " !$CLIENT2TID{$client} shutting down" ) if DEBUG;
            delete( $DONEWITH{$client} );

#   Obtain the thread id
#   Obtain the client object (rather than its stringification)
#   Remove the client from polling loop
#   Properly close the client from this end
#   If we were waiting for this client to exit
#    Mark that main thread should not be ABRT signalled, if main thread is shutting down
#    Mark server to shutdown

            my $tid = $CLIENT2TID{$client};
            $client = $TID2CLIENT{$tid};
            $select->remove( $client );
            close( $client );
            if ($RUNNING eq $client) {
                $MAIN_EXIT_NO_ABRT = 1 if $tid == 0;
                $RUNNING = 0;
            }

#   Do the clean up

            my $pid = $TID2PID{$tid};
            delete( $TID2CLIENT{$tid} );
            delete( $CLIENT2TID{$client} );
            delete( $PID2TID{$pid} ) if defined $pid;
            if ($DETACHED =~ m/\b$tid\b/ or !exists( $NOTJOINED{$tid} )) {
                delete( $TID2PID{$tid} );
                delete( $TID2STACKSIZE{$tid} );
                delete( $TID2CONTEXT{$tid} );
            }
        }
    }

# Allow external modules opportunity to clean up thread process group resources
# Exit now, we're in the shared process and we've been told to exit

_log( " ! global exit: did $polls polls" ) if DEBUG;
    _end_server_pre_shutdown();
    defined $EXIT_VALUE ? CORE::exit($EXIT_VALUE) : CORE::exit();
} #_server

#---------------------------------------------------------------------------
#  IN: 1 tid to cleanup
#      2 (optional) error text to report

sub _cleanup_unsafe_thread_exit {

# Get tid of thread to cleanup
# Get error text to display in stack trace

    my $tid = shift;
    my $errtxt = shift || '';
    Carp::cluck( "Performing cleanup for dead thread $tid: $errtxt" )
        if warnings::enabled() && $errtxt ne '';   #TODO: disable these conditions?

# If thread isn't already joined and shutdown
#  Mark this thread as shutdown
#  Delete any messages that might have been pending for this client

    if (defined $TID2CLIENT{$tid}) {
        _shutdown($TID2CLIENT{$tid}, $tid);
        delete( $WRITE{$TID2CLIENT{$tid}} );
    }
} #_cleanup_unsafe_thread_exit

#---------------------------------------------------------------------------

sub _update_timedwaiting_idx {

#  If timedwaiting index expired flag set
#   Translate timedwaiting hash to sorted (index) array of all events
#   Reset index expired flag

    if ($TIMEDWAITING_IDX_EXPIRED) {
        @TIMEDWAITING_IDX = ();
        if (keys %TIMEDWAITING) {
            push @TIMEDWAITING_IDX, map($_, sort {$a->[2] <=> $b->[2]} map(@{$TIMEDWAITING{$_}}, keys %TIMEDWAITING));
        }
        $TIMEDWAITING_IDX_EXPIRED = 0;
    }
} #_update_timedwaiting_idx

#---------------------------------------------------------------------------

sub _handle_timedwaiting {
    
#  For all timed wait events
#   Obtain the tid, time, and ordinal event
#   If this timed event is expired and a timed event exists for this ordinal
#    Parse all timed events
#     If current event in list of timed events is the matching event to what has expired
#      Get the tid and target lock ordinal of the event
#      Delete event from list & expire timed event index
#      If ordinal is currently locked
#       Signal this variable for when the target locked variable is unlocked later
#      Else (ordinal not locked)
#       Assign lock to this tid
#       Immediately notify blocking thread that it should continue
#   Else last loop: minimize index parsing, as when current event isn't expired, remaining (ordered) events in array aren't either

    foreach (@TIMEDWAITING_IDX) {
        my (undef, $ordinal, $time, undef, $id) = @{$_};
        if ($time <= time() && defined $TIMEDWAITING{$ordinal} && ref($TIMEDWAITING{$ordinal}) eq 'ARRAY' && @{$TIMEDWAITING{$ordinal}}) {
            my @tw_events = @{$TIMEDWAITING{$ordinal}};
            for (my $i = 0; $i < scalar @tw_events; $i++) {
                if ($tw_events[$i]->[4] == $id) {
                    my ($tid, $l_ordinal) = @{splice(@{$TIMEDWAITING{$ordinal}}, $i, 1)}[0,3];
                    delete $TIMEDWAITING{$ordinal} unless @{$TIMEDWAITING{$ordinal}};
                    $TIMEDWAITING_IDX_EXPIRED = 1;
                    if (defined $LOCKED[$l_ordinal]) {
                        push @{$TIMEDWAITING_EXPIRED[$ordinal]}, [$tid, $l_ordinal];
                    } else {
                        $LOCKED[$l_ordinal] = $tid;
                        $WRITE{$TID2CLIENT{$tid}} = $false;
                    }
                    last;
                }
            }
        } else { 
            last;
        }
    }
} #_handle_timedwaiting

#---------------------------------------------------------------------------
#  IN: 1 socket to put into nonblocking mode

sub _nonblock { # not sure whether needed, this is really cargo-culting

# Obtain the socket in question
# Obtain the current flags
# Set the non-blocking flag onto the current flags

    my $socket = shift;
    my $flags = fcntl( $socket, F_GETFL, 0 )
     or _croak( "Error ".($! ? $! + 0 : '').": Can't get flags for socket: ".($! ? $! : '') );
    fcntl( $socket, F_SETFL, $flags | O_NONBLOCK )
     or _croak( "Error ".($! ? $! + 0 : '').": Can't make socket nonblocking: ".($! ? $! : '') );
} #_nonblock

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      3 flag whether to automatically detect deadlocks
#      2 detection period, in seconds
#      3 flag whether to resolve deadlock conflicts

sub _set_deadlock_option {

# Obtain client
# Set deadlock detection flag and period
# If period was changed
#  Set deadlock detection period (stored as a positive number)
#  Set next deadlock detection event,
# Set deadlock resolution flag
# If deadlock resolver is enabled, immediately do global deadlock detection
# Make sure the client knows the result

    my $client = shift;
    $DEADLOCK_DETECT = shift @_ ? 1 : $DEADLOCK_DETECT;
    my $period = shift @_;
    if (defined $period) {
        $DEADLOCK_DETECT_PERIOD = abs($period) + 0;
        $DEADLOCK_DETECT_TS_NEXT = time() + $DEADLOCK_DETECT_PERIOD;
    }
    $DEADLOCK_RESOLVE = shift @_ ? 1 : $DEADLOCK_RESOLVE;
    my $signal = shift @_;
    $DEADLOCK_RESOLVE_SIG = abs($signal) if $signal;
    _detect_deadlock_all() if $DEADLOCK_RESOLVE;
    $WRITE{$client} = $true;
} #_set_deadlock_option

#---------------------------------------------------------------------------
#  IN: 1 TID of thread waiting to lock
#      2 Ordinal of variable TID is waiting to lock
# OUT: 1 True or false, indicating whether or not deadlock was detected
#      2 TID of thread deadlocked with input TID
#      3 Ordinal of other variable involved in deadlock that is locked by output TID

sub _detect_deadlock {

# Obtain thread TID (1) and ordinal that it wants to lock
# Verify that that the ordinal is already locked (and not by the thread to analyze)
#  Get TID (2) of current ordinal locker
#  Get ordinal that TID (2) is currently blocking on
#  If TID (2) is blocking on TID (1) locked variable
#   Warn of the deadlock
#   Mark thread pair as deadlocked
#   Return true result
# Return false (no deadlock detected)

    my ($tid1, $tid1_locking_ordinal) = @_;
    if (defined $LOCKED[$tid1_locking_ordinal] && $LOCKED[$tid1_locking_ordinal] != $tid1) {
        my $tid2 = $LOCKED[$tid1_locking_ordinal];
        my $tid2_locking_ordinal = List::MoreUtils::firstidx(
            sub { ref($_) eq 'ARRAY' ? grep(/^$tid2$/, @{$_}) : 0 }, @LOCKING);
        if ($tid2_locking_ordinal != -1 && defined $LOCKED[$tid2_locking_ordinal]) {
            print STDERR "Deadlock detected:\n"
                .sprintf("% 7s% 12s% 13s   %s\n",'TID','SV LOCKED','SV LOCKING','Caller')
                .sprintf("% 7d% 12d% 13d   %s\n", $tid1, $tid2_locking_ordinal,
                    $tid1_locking_ordinal, CORE::join(' at line ', @{$TID2LOCKCALLER{$tid1}}[1..2]))
                .sprintf("% 7d% 12d% 13d   %s\n", $tid2, $tid1_locking_ordinal,
                    $tid2_locking_ordinal, CORE::join(' at line ', @{$TID2LOCKCALLER{$tid2}}[1..2]))
                if warnings::enabled();
            $DEADLOCKED{$tid1} = $tid2;
            $DEADLOCKED{$tid2} = $tid1;
            return CORE::wantarray ? (1, $tid2, $tid2_locking_ordinal) : 1;
        }
    }
    return 0;
} #_detect_deadlock

#---------------------------------------------------------------------------
# OUT: 1 Total number of deadlock (in terms of thread pairs) detected
#      2 Num of unique deadlock pairs detected

sub _detect_deadlock_all {

# Initialize counter
# For each ordinal in @LOCKING
#  If any threads are waiting to lock this ordinal
#   Increment deadlock counter foreach deadlock (unless thread is marked deadlocked)
# Return count of deadlocked pairs

    my $num_deadlocks = 0;
    for (my $ord = 0; $ord <= scalar @LOCKING; $ord++) {
        if (defined $LOCKING[$ord] && ref($LOCKING[$ord]) eq 'ARRAY') {
            foreach my $tid (@{$LOCKING[$ord]}) {
                $num_deadlocks += _detect_deadlock($tid, $ord)
                    unless exists $DEADLOCKED{$tid};
            }
         }
    }
    return $num_deadlocks;
} #_detect_deadlock_all

#---------------------------------------------------------------------------
#  IN: 1 TID of thread to signal
#      2 Signal to send (ID, name, or SIGname)

sub _signal_thread {

# Obtain the TID to signal
# Obtail the signal to send
# Determine the signal name or ID
# Send the signal

    my $tid = shift;
    my $signal = shift;
    my $mysig = uc($signal);

    $mysig = $1 if $mysig =~ m/^SIG(\w+)/;
    my $sigidx = List::MoreUtils::firstidx( sub { $_ eq $mysig },
        split(/\s+/, $Config::Config{sig_name}));
    my $signum = $sigidx == -1
        ? $signal : (split(/\s+/, $Config::Config{sig_name}))[$sigidx];
    
    if (CORE::kill(0, $TID2PID{$tid})) {
        return CORE::kill($signal, $TID2PID{$tid});
    } else {
        return 0;
    }
} #_signal_thread

#---------------------------------------------------------------------------

# internal subroutines client-side

#---------------------------------------------------------------------------
#  IN: 1 namespace to export to
#      2..N subroutines to export

sub _export {

# Obtain the namespace
# If we're supposed to debug the server also
#  Set debug flag
#  Lose the parameter

    my $namespace = shift().'::';
    if (defined( $_[0] ) and $_[0] eq 'debug') {
        $DEBUG = 1;
        shift;
    }

# Set the defaults if nothing specified
# Allow for evil stuff
# Export whatever needs to be exported

    @_ = qw(async) unless @_;
    no strict 'refs';
    *{$namespace.$_} = \&$_ foreach @_;
} #_export

#---------------------------------------------------------------------------
#  IN: 1 flag: whether to mark the thread as detached

sub _init_thread {

# Get results of _run_CLONE_SKIP from parent
# Get return context of thread
# Get flag whether this thread should start detached or not
# Get stack size for this thread
# Mark this process as a thread
# Reset thread local tid value (so the process doesn't have its parent's tid)
# Reset thread local pid value (so the process doesn't have its parent's pid)
# Store the return context of this thread

    my $clone_skip = shift;
    my $thread_context = shift;
    my $is_detached = shift;
    my $stack_size = shift;
    $ISATHREAD{$$} = undef;
    undef( $TID );
    undef( $PID );
    $THREAD_CONTEXT = $thread_context;

# Attempt to create a connection to the server or die

    if ($THREADS_UNIX) {
        $QUERY = IO::Socket::UNIX->new(
         Peer => $PORT,
        ) or _croak( "Couldn't connect to query server: $@" );
    } else {
        $QUERY = IO::Socket::INET->new(
         PeerAddr => '127.0.0.1',
         PeerPort => $PORT,
        ) or _croak( "Couldn't connect to query server: $@" );
    }

# Obtain the initial message from the query server
# Die now if it is the wrong type of message
# Set the tid
# Set the pid
# Disable debug on process exit if this isn't main thread
# Send the command to register the pid (unless starting detached or is main thread)
# Execute all of the CLONE subroutines if not in the base thread

    my @param = _receive( $QUERY );
    _croak( "Received '$param[0]' unexpectedly" ) if $param[0] ne '_set_tid';
    $TID = $param[1];
    $PID = $$;
    $DB::inhibit_exit = 0 if $TID;
    _send( $QUERY,'_register_pid',$TID,$$,($is_detached || !$TID ? undef : getppid()),$thread_context,$is_detached,$stack_size );
    _run_CLONE($clone_skip) if $TID;
    
# Wait for result of registration, die if failed
# If this is not main thread
#  Use forks::signal to overload %SIG for safest forks-aware signal behavior

    _croak( "Could not register pid $$ as tid $TID" ) unless _receive( $QUERY );
    if ($TID > 0) {
        import forks::signals
            ifndef => {
                %THR_UNDEFINED_SIG,
                CHLD => $FORCE_SIGCHLD_IGNORE ? 'IGNORE' : [\&REAPER, SA_NOCLDSTOP | SA_RESTART]
            },
            ifdef => {
                %THR_DEFINED_SIG,
                CHLD => $FORCE_SIGCHLD_IGNORE ? 'IGNORE' : \&REAPER
            };
    }

# Reinitialize random number generator (as we're simulating new interpreter creation)
# Overload global exit to conform to ithreads API (exits all threads).

    srand;
    {
        no warnings 'redefine';
        *CORE::GLOBAL::exit = sub {
            threads::_command( '_toexit',$_[0] );
            defined $_[0] ? CORE::exit($_[0]) : CORE::exit();
        };
    }

    return 1;
} #_init_thread

#---------------------------------------------------------------------------

# internal subroutines, both server-side as well as client-side

#---------------------------------------------------------------------------
#  IN: 1 arrayref of parameters to be put in message
#  IN: 2 command filter type (request or response)
#  IN: 3 command name
# OUT: 1 formatted message (MSG_LENGTH_LEN bytes packed length + CMD_TYPE_INTERNAL + data)

sub _pack {
    my $data_aref = shift;
    my $cmd_fltr_type = shift;
    my $cmd_name = shift;
    my $cmd_num = $cmd_type_to_num{$cmd_name} if $cmd_name;
    my $is_default_pack_type = defined $cmd_fltr_type && defined $cmd_num ? 0 : 1;
    
# If using default pack type
#  Freeze the parameters that have been passed
# Else
#  Pack data using custom filter
    
    my $data;
    if ($is_default_pack_type) {
        $data = pack('C', CMD_TYPE_DEFAULT).Storable::freeze( $data_aref );
    } else {
        my $filter = $cmd_num_to_filter[$cmd_num]->[$cmd_fltr_type]->[CMD_FLTR_ENCODE];
        $data = pack('C', CMD_TYPE_INTERNAL).pack('S', $cmd_num).$filter->($data_aref);
    }

# Calculate the length, pack it and return it with the frozen stuff

    pack( 'N',length( $data ) ).$data;
} #_pack_internal

#---------------------------------------------------------------------------
#  IN: 1 arrayref of parameters to be put in message
#  IN: 2 command name
# OUT: 1 formatted message

sub _pack_request { _pack(shift, CMD_FLTR_REQ, @_); } #_pack_request

#---------------------------------------------------------------------------
#  IN: 1 arrayref of parameters to be put in message
#  IN: 2 command name
# OUT: 1 formatted message

sub _pack_response { _pack(shift, CMD_FLTR_RESP, @_); } #_pack_response

#---------------------------------------------------------------------------
#  IN: 1 formatted message (without MSG_LENGTH_LEN byte length info)
#  IN: 2 command filter type (request or response)
# OUT: 1..N [msg name (if known), whatever was passed to "_pack"]

sub _unpack {

# Handle either default or custom filtered messages

    my $msg = shift;
    my $cmd_fltr_type = shift;
    my $type = unpack('C', substr($msg, CMD_TYPE_IDX, CMD_TYPE_LEN));
    if ($type == CMD_TYPE_DEFAULT) {
        return (undef, @{Storable::thaw( substr($msg, CMT_TYPE_FROZEN_CONTENT_IDX) )});
    } elsif ($type == CMD_TYPE_INTERNAL) {
        my $cmd_num = unpack('S', substr($msg, CMD_TYPE_INTERNAL_SUBNAME_IDX, CMD_TYPE_INTERNAL_SUBNAME_LEN));
        my $filter = $cmd_num_to_filter[$cmd_num]->[$cmd_fltr_type]->[CMD_FLTR_DECODE];
        return ($cmd_num_to_type[$cmd_num], $filter->(substr($msg, CMD_TYPE_INTERNAL_CONTENT_IDX)));
    } else {
        _croak ( "Unknown command type: $type" );
    }
} #_unpack

#---------------------------------------------------------------------------
#  IN: 1 formatted message (without MSG_LENGTH_LEN byte length info)
# OUT: 1..N [msg name (if known), whatever was passed to "_pack"]

sub _unpack_request { _unpack(shift, CMD_FLTR_REQ); } #_unpack_request

#---------------------------------------------------------------------------
#  IN: 1 formatted message (without MSG_LENGTH_LEN byte length info)
# OUT: 1..N [msg name (if known), whatever was passed to "_pack"]

sub _unpack_response { _unpack(shift, CMD_FLTR_RESP); } #_unpack_response

#---------------------------------------------------------------------------
#  IN: 1 client object
#      2 flag: don't croak if there is no length yet
# OUT: 1 length of message to be received

sub _length {

# Obtain client
# Initialize length variable
# While true
#  If we successfully read
#   Add length read to total
#   If we read successfully
#    If we got enough bytes for a length
#     Return the actual length
#    Elsif we didn't get anything
#     Return 0 if we don't need to croak yet
#     Break out of loop (no data found, where data was expected)
#    Decrease how much left there is to read by how much we just read
#  Elsif action would block or was interrupted by a signal
#   Sleep for a short time (i.e. don't hog CPU)
#  Else
#   Break out of loop (as some other error occured)

    my $client = shift;
    my $total_length = 0;
    my $todo = MSG_LENGTH_LEN;
    while ($total_length < MSG_LENGTH_LEN) {
        my $result = recv( $client,my $length,$todo,0 );
        if (defined( $result )) {
            $total_length += length( $length );
            if ($total_length == MSG_LENGTH_LEN) {
                return unpack( 'N',$length );
            } elsif ($total_length == 0) {
                return 0 if shift;
                last;
            }
            $todo -= length( $length );
        } elsif ($! == EWOULDBLOCK || $! == EAGAIN || $! == EINTR) {
            sleep 0.001;
        } else {
            last;
        }
    }

# If was ECONNABORTED (server abort) or ECONNRESET (client abort)
#  If is a thread
#   Warn and exit immediately (server connection terminated, 
#    likely due to main thread shutdown)
#  Else (is shared server)
#   Clear the error if this was main thread exiting
#   Cleanup "dead" thread
#   Report no data (length 0)
# Unless we're shutting down and we're not running in debug mode
#  Die, there was an error

    my $tid = defined $TID ? 'server' : $CLIENT2TID{$client};
    my $errtxt = "Error ".($! ? $! + 0 : '')
        .": Could not read length of message"
        .(defined $tid ? " from $tid" : '').": ".($! ? $! : '') if $!;
    if (!$! || $! == ECONNABORTED || $! == ECONNRESET) {
        if (exists( $ISATHREAD{$$} )) {
            $SHUTTING_DOWN = 1;
_log( "Thread $TID terminated abnormally: $errtxt" ) if DEBUG;
#warn "***_length: Thread $TID terminated abnormally: $errtxt";  #TODO: for debugging only
            CORE::exit();
        } else {
            $errtxt = undef if $CLIENT2TID{$client} == 0;
            _cleanup_unsafe_thread_exit($CLIENT2TID{$client}, $errtxt);
            return 0;
        }
    }
    _croak( $errtxt ) unless (($SHUTTING_DOWN || $SHUTTING_DOWN_END) && !DEBUG);
} #_length

#---------------------------------------------------------------------------
#  IN: 1 client object
#      2 frozen message to send

sub _send {

# Obtain the client object
# Create frozen version of the data
# Calculate the length of data to be sent

    my $client = shift;
    my $frozen = grep(/^$_[0]$/, @cmd_filtered) ? _pack_request( \@_, shift ) : _pack_request( \@_, $_[0] );
    my $length = length( $frozen );
_log( "> ".CORE::join(' ',map {$_ || ''} eval {_unpack_request( substr($frozen,MSG_LENGTH_LEN) )}) )
 if DEBUG;

# Localize and set thread data comm flag
# Loop while there is data to send
#  Send the data, find out how many really got sent
#  If data was sent
#   Remove sent data from string buffer
#   Increment total bytes sent
#  Elsif action would block or was interrupted by a signal
#   Sleep for a short time (i.e. don't hog CPU)
#  Else (an error occured)
#   If was ECONNABORTED (server abort) or ECONNRESET (client abort)
#    Warn and exit immediately (server connection terminated, likely due to main thread shutdown)
#   Die now unless shuttind down and not in debug mode
#   Return immediately

    $frozen =~ m#^(.*)$#s;
    my ($data, $total_sent) = ($1, 0);
    DEFERREDSIGBLOCK: {
        local $threads::SEND_IN_PROGRESS = 1;
        while ($total_sent < $length) {
            my $sent = send( $client,$data,0 );
            if (defined( $sent )) {
                substr($data, 0, $sent) = '';
                $total_sent += $sent;
            } elsif ($! == EWOULDBLOCK || $! == EAGAIN || $! == EINTR) {
                sleep 0.001;
            } else {
                my $errtxt = "Error ".($! ? $! + 0 : '')
                    ." when sending message to server: ".($! ? $! : '');
                if (!$! || $! == ECONNABORTED || $! == ECONNRESET) {
                    warn "Thread $TID terminated abnormally: $errtxt"
                        if warnings::enabled() && $TID
                            && !$SHUTTING_DOWN && !$SHUTTING_DOWN_END;
                    $SHUTTING_DOWN = 1;
#warn "===Thread $TID terminated abnormally: $errtxt";   #TODO: for debugging only
                    CORE::exit();
                }
                _croak( $errtxt )
                    unless (($SHUTTING_DOWN || $SHUTTING_DOWN_END) && !DEBUG);
                return;
            }
        }
    }

# Handle deferred signals
# Reset deferred signal list

    $SIG{$_}->($_) foreach (@DEFERRED_SIGNAL);
    @DEFERRED_SIGNAL = ();
} #_send

#---------------------------------------------------------------------------
#  IN: 1 client object
# OUT: 1..N parameters of message

sub _receive {

# Obtain the client object
# Localize and set thread comm flag
# Block signals, if using custom CHLD signal handler
# Obtain the length
# Initialize the data to be received

    my $client = shift;
    DEFERREDSIGBLOCK: {
        local $threads::RECV_IN_PROGRESS = 1;
        my $length = my $todo = _length( $client );
        my $frozen;

# While there is data to get
#  Get some data
#  If we got data
#   Add what we got this time
#   If we got it all
#    Untaint what we got
#    Obtain any parameters if possible
#    Remove method type from parameters
#    Return the result
#   Set up for next attempt to fetch
#  ElseIf call would block or was interrupted by signal
#   Sleep a bit (to not take all CPU time)

        while ($todo > 0) {
            local $threads::RECV_DATA = '';
            my $result = recv( $client,$threads::RECV_DATA,$todo,0 );
            if (defined $result) {
                $frozen .= $threads::RECV_DATA;
                if (length( $frozen ) == $length) {
                    $frozen =~ m#^(.*)$#s;
                    my @result = _unpack_response( $1 );
                    shift @result;
_log( "< @{[map {$_ || ''} @result]}" ) if DEBUG;
                    return CORE::wantarray ? @result : $result[0];
                }
                $todo -= length( $threads::RECV_DATA );
            } elsif ($! == EWOULDBLOCK || $! == EAGAIN || $! == EINTR) {
                sleep 0.001;
            } else {
                last;
            }
        }
    }

# Handle deferred signals
# Reset deferred signal list

    $SIG{$_}->($_) foreach (@DEFERRED_SIGNAL);
    @DEFERRED_SIGNAL = ();

# Unless we're shutting down and we're not running in debug mode
#  Die now (we didn't get the data)

    unless (($SHUTTING_DOWN || $SHUTTING_DOWN_END) && !DEBUG) {
        _croak( "Error ".($! ? $! + 0 : '').": Did not receive all bytes from $CLIENT2TID{$client}: ".($! ? $! : '') );
    }
} #_receive

#---------------------------------------------------------------------------

# all client-side handler internal subroutines from here on

#---------------------------------------------------------------------------
#  IN: 1 command to execute
#      2..N parameters to send
# OUT: 1 values returned by server

sub _command {

# Return now if this thread has shut down already or if server already shutdown
# Send the command + parameters
# Return immediately if main thread is shutting down in non-daemon mode
# Return the result

    return if (defined($PID) && $$ != $PID) || $SHUTDOWN
        || (($SHUTTING_DOWN || $SHUTTING_DOWN_END) && !$QUERY);
    _send( $QUERY,@_ );
    return if $$ == $PID_MAIN_THREAD
        && $SHUTTING_DOWN_END && $THREADS_INTEGRATED_MODEL;
    _receive( $QUERY );
} #_command

#---------------------------------------------------------------------------
#  IN: 1 class
#      2 thread id
#      3 process id
# OUT: 1 instantiated thread object

sub _object { bless {tid => $_[1], pid => $_[2]},ref($_[0]) || $_[0] } #_object

#---------------------------------------------------------------------------

# all server-side handler internal subroutines from here on

#---------------------------------------------------------------------------
#  IN: 1 instantiated socket
#      2 frozen data to be handled

sub _handle_request {

# Obtain the socket
# Get the command name and its parameters
# If this is CMD_TYPE_DEFAULT command, get sub from parameters
# Allow for variable references (sub name is not a ref)
# Execute the command, be sure to pass the socket

    my $client = shift;
    my ($sub,@param) = _unpack_request( shift );
    $sub = shift @param unless defined $sub;
    no strict 'refs';
    &{$sub}( $client,@param );
} #_handle_request

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 tid to register
#      3 pid to associate with the tid
#      4 flag: whether to mark thread as detached
# OUT: 1 whether successful (sent to client)

sub _register_pid {

# Obtain the parameters
# Initialize the status as error
# If we received a process id
#  If there is a client object for this thread
#   If this is the first time this thread is being registered
#    Register this thread
#    Make sure we can do a reverse lookup as well
#    Push tid on ppid2tid queue, if thread has a parent (e.g. not main thread)
#    If thread is marked as detached
#     Add to the list of detached threads
#     Store return context of thread
#    Else
#     Mark thread as joinable
#     Store the return context of the thread
#    Set status to indicate success

    my ($client,$tid,$pid,$ppid,$thread_context,$detach,$stack_size) = @_;
    my $status = 0;
    if ($pid) {
        if (defined $TID2CLIENT{$tid}) {
            unless (exists $PID2TID{$pid}) {
                $TID2PID{$tid} = $pid;
                $PID2TID{$pid} = $tid;
                $TID2STACKSIZE{$tid} = defined $stack_size ? $stack_size : $ITHREADS_STACK_SIZE;
                push @{$PPID2CTID_QUEUE{$ppid}}, $tid if $ppid;
                if ($detach) {
                    $DETACHED .= ",$tid";
                    $DETACHED_NOTDONE{$tid} = undef;
                } else {
                    $NOTJOINED{$tid} = undef;
                    $TID2CONTEXT{$tid} = $thread_context;
                }
                $status = 1;
            }
        }

#   If thread has a parent and there is a thread waiting for this ppid/ctid pair
#    Let that thread know
#    And forget that it was waiting for it

        if (defined $ppid && exists $BLOCKING_PPID2CTID_QUEUE{$ppid}) {
            _ppid2ctid_shift( $BLOCKING_PPID2CTID_QUEUE{$ppid},$ppid );
            delete( $BLOCKING_PPID2CTID_QUEUE{$ppid} );
        }
    }

# Let the client know how it went

    $WRITE{$client} = _pack_response( [$status] );
} #_register_pid

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 thread id to find associated process id of
# OUT: 1 associated process id

sub _tid2pid { $WRITE{$_[0]} = _pack_response( [$TID2PID{$_[1]}] ) } #_tid2pid

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 process id to find associated thread id of
# OUT: 1 associated thread id

sub _pid2tid { $WRITE{$_[0]} = _pack_response( [$PID2TID{$_[1]}] ) } #_pid2tid

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 process id of thread calling this method
# OUT: 1 associated thread id

sub _ppid2ctid_shift {
    $WRITE{$_[0]} = _pack_response( [shift @{$PPID2CTID_QUEUE{$_[1]}}] );
} #_ppid2ctid_shift

#---------------------------------------------------------------------------
#  IN: 1 client socket
#  IN: 2 (optional) boolean value indicating type of list desired
# OUT: 1..N tid/pid pairs of all threads

sub _list_tid_pid {

# Obtain the socket
# Initialize the parameters to be sent
# For all of the registered threads
#  Obtain the thread id
#  If user specified an argument to list()
#   If argument was a "true" value
#    (running) Reloop if it is detached or joined or no longer running (non-detached)
#    or a thread is already blocking to join it
#   Else
#    (joinable) Reloop if it is detached or joined or still running (non-detached)
#  Else
#   (all) Reloop if it is detached or joined or a thread is already blocking to join it
#  Add this tid and pid to the list
# Store the response

    my $client = shift;
    my @param;
    while (my($tid,$pid) = each %TID2PID) {
        if (@_) {
            if ($_[0]) {
                next if $DETACHED =~ m/\b$tid\b/ or !exists( $NOTJOINED{$tid} )
                    or exists( $RESULT{$tid} ) or exists( $BLOCKING_JOIN{$tid} );
            } else {
                next if $DETACHED =~ m/\b$tid\b/ or !exists( $NOTJOINED{$tid} )
                    or !exists( $RESULT{$tid} );
            }
        } else {
            next if $DETACHED =~ m/\b$tid\b/ or !exists( $NOTJOINED{$tid} )
                or exists( $BLOCKING_JOIN{$tid} );
        }
        push( @param,$tid,$pid );
    }
    $WRITE{$client} = _pack_response( [@param] );
} #_list_tid_pid

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 client process exit value
# OUT: 1 thread exit status

sub _toexit {

# Obtain the client object
# Unless thread exit should be localized to thread, main thread exited,
# or another thread performed global exit (waiting for it to shutdown)
#  Store exit value
#  Mark server process as ready to exit when this thread exits
# Make sure the client continues

    my $client = shift;
    my $exit_value = shift;
    unless ($CLIENT2TID{$client} == 0
            || defined ( $EXIT_VALUE ) || $THREADS_EXIT
            || exists( $THREAD_EXIT{$CLIENT2TID{$client}} )) {
        $EXIT_VALUE = $exit_value;
        $RUNNING = $client;
    }
    $WRITE{$client} = $true;
} #_toexit

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 thread id to which rule will apply
#      3 boolean state rule
# OUT: 1 thread exit status

sub _set_thread_exit_only {

# Obtain the client object
# Set the appropriate client thread exit method
# Make sure the client continues

    my $client = shift;
    my $tid = shift;
    my $thread_exit_only = shift @_ ? 1 : 0;
    if ($thread_exit_only) {
        $THREAD_EXIT{$tid} = undef;
    } else {
        delete( $THREAD_EXIT{$tid} );
    }
    $WRITE{$client} = $true;
} #_set_thread_exit_only

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 thread id calling this method
# OUT: 1 thread exit status

sub _set_threads_exit_only {

# Obtain the client object
# Set the global thread exit override state
# Make sure the client continues

    my $client = shift;
    $THREADS_EXIT = $_[0] ? 1 : 0;
    $WRITE{$client} = $true;
} #_set_threads_exit_only

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2..N result of thread
# OUT: 1 whether saving successful

sub _tojoin {

# Obtain the client object
# Obrain the client error (if any)
# Store the client error if there was an error
# If there is a thread id for this client, obtaining it on the fly
#  If there is a thread waiting for this result, obtaining client on the fly
#   Join the thread with this result
#  Elseif the thread was not detached
#   Save the result for later fetching
#  Elseif the thread was detached
#   Mark this detached thread as done
# Make sure the client knows the result

    my $client = shift;
    my $error = shift;
    $ERROR{$CLIENT2TID{$client}} = $error if defined $error;
    if (my $tid = $CLIENT2TID{$client}) {
        if (exists $BLOCKING_JOIN{$tid}) {
#warn "case 1: the result I got was ".scalar(@_).": ".CORE::join(',', @_);  #TODO: for debugging only
            _isjoined( $BLOCKING_JOIN{$tid},$tid,@_ );
        } elsif ($DETACHED !~ m/\b$tid\b/) {
            $RESULT{$tid} = \@_;
        } elsif ($DETACHED =~ m/\b$tid\b/) {
            delete( $DETACHED_NOTDONE{$tid} );
        }
    }
    $WRITE{$client} = $true;
} #_tojoin

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 thread id of thread to detach
# OUT: 1 whether first time detached

sub _detach {

# Obtain the parameters
# Set flag whether first time detached
# If another thread is already waiting to join this thread
#  Don't allow thread to become deached (return local thread exception)
# Else
#  Detach this thread
#  If target thread is still running
#   Mark it as detached and running
#  Else
#   Cleanup internal states (results) related to thread exit
# Let the client know the result

    my ($client,$tid) = @_;
    my $can_detach = $DETACHED !~ m/\b$tid\b/;
    my $errtxt = $can_detach ? '' : 'Thread already detached';
    if (exists $BLOCKING_JOIN{$tid} || ($can_detach && !exists( $NOTJOINED{$tid} ))) {
        $can_detach = 0;
        $errtxt = 'Cannot detach a joined thread';
#warn "Thread $CLIENT2TID{$client} attempted to detach a thread ($tid) pending join by another thread ($CLIENT2TID{$BLOCKING_JOIN{$tid}})"; #TODO: debugging
    }
    if ($can_detach) {
        $DETACHED .= ",$tid";
        if (defined $NOTJOINED{$tid}) {
            $DETACHED_NOTDONE{$tid} = undef;
        } else {
            delete( $RESULT{$tid} );
        }
        delete( $TID2CONTEXT{$tid} );
        delete( $TID2STACKSIZE{$tid} );
    }
    $WRITE{$client} = _pack_response( [$can_detach, $errtxt] );
} #_detach

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 process id to find associated thread id of

sub _waitppid2ctid {

# If there is already a thread id for this process id, set that
# Start waiting for the tid to arrive

    return &_ppid2ctid_shift if defined $PPID2CTID_QUEUE{$_[1]} && @{$PPID2CTID_QUEUE{$_[1]}};
    $BLOCKING_PPID2CTID_QUEUE{$_[1]} = $_[0];
} #_waitppid2ctid

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 thread id of thread to wait for result of

sub _join {

# If the thread is detached
#  Propagate error to thread
# ElseIf there is already a result for this thread
#  Mark the thread as joined and use the pre-saved result
# Elseif the results were fetched before
#  Propagate error to thread
# Elseif the thread terminated without join (i.e. terminated abnormally)
#  Return undef to thread
# Elseif thread process not running (i.e. thread death w/ no _shutdown)
#  Return undef to thread
# Elseif someone is already waiting to join this thread
#  Propagate error to thread
# Elseif thread is attempting to join on itself
#  Propagate error to thread
# Else
#  Start waiting for the result to arrive

    my ($client,$tid) = @_;
    if ($DETACHED =~ m/\b$tid\b/) {
#warn "Thread $CLIENT2TID{$client} attempted to join a detached thread: $tid";  #TODO: for debugging only
        $WRITE{$client} = _pack_response( [0, 'Cannot join a detached thread'] );
    } elsif (exists $RESULT{$tid}) {
#warn "case 2: $CLIENT2TID{$client} joining $tid immediately";  #TODO: for debugging only
        _isjoined( $client,$tid,@{$RESULT{$tid}} );
    } elsif (!exists( $NOTJOINED{$tid} )) {
#warn "Thread $CLIENT2TID{$client} attempted to join an already joined thread: $tid";   #TODO: for debugging only
        $WRITE{$client} = _pack_response( [0, 'Thread already joined'] );
    } elsif (!exists $TID2CLIENT{$tid}) {
#warn "case 4: $CLIENT2TID{$client} cannot join $tid";  #TODO: for debugging only
        $WRITE{$client} = _pack_response( [0, 'Cannot join a detached or already joined thread'] );
    } elsif (!exists( $TID2PID{$tid} ) || !CORE::kill(0, $TID2PID{$tid})) {
#warn "case 5: $CLIENT2TID{$client} cannot join $tid";  #TODO: for debugging only
        $WRITE{$client} = _pack_response( [0, 'Cannot join a detached or already joined thread'] );
    } elsif (defined $BLOCKING_JOIN{$tid}) {
#warn "Thread $CLIENT2TID{$client} attempted to join a thread already pending join: $tid";  #TODO: for debugging only
        $WRITE{$client} = _pack_response( [0, 'Thread already joined'] );
    } elsif ($CLIENT2TID{$client} == $tid) {
        $WRITE{$client} = _pack_response( [0, 'Cannot join self'] );
    } else {
#warn "case 6: $CLIENT2TID{$client} blocking on $tid";  #TODO: for debugging only
        $BLOCKING_JOIN{$tid} = $client;
    }
} #_join

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 thread id of thread to return result of

sub _error {

# Obtain the waiting client and the tid of which to check error status
# Write the current error state response

    my ($client,$tid) = @_;
    $WRITE{$client} = exists $ERROR{$tid}
        ? _pack_response( [$ERROR{$tid}] )
        : $undef;
} #error

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 thread id of thread, or not defined (if we want global stack size)
#      3 new default stack size (defined if this is a set operation)

sub _get_set_stack_size {

# Obtain client socket and TID
# Look up old stack size for this thread
# Set new stack size, if defined and is a valid integer
# Return old stack size

    my ($client,$tid,$size) = @_;
    my $old = defined $tid && exists $TID2STACKSIZE{$tid} ? $TID2STACKSIZE{$tid} : $ITHREADS_STACK_SIZE;
    $ITHREADS_STACK_SIZE = $size if defined $size && $size =~ m/^\d+$/o;
    $WRITE{$client} = _pack_response( [$old] );
} #_get_set_stack_size

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 thread id of thread to check state

sub _is_detached {

# Obtain client socket and TID
# Return boolean value to thread whether deatched or not

    my ($client,$tid) = @_;
    $WRITE{$client} = $DETACHED =~ m/\b$tid\b/ ? $true : $false;
} #_is_detached

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 thread id of thread to check state

sub _is_running {

# Obtain client socket and TID
# Return boolean value to thread whether running or not

    my ($client,$tid) = @_;
    $WRITE{$client} = ($DETACHED =~ m/\b$tid\b/ && exists $DETACHED_NOTDONE{$tid})
        || (defined $TID2PID{$tid} && !exists $RESULT{$tid} && exists $NOTJOINED{$tid})
        ? $true : $false;
} #_is_running

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 thread id of thread to check state

sub _is_joinable {

# Obtain client socket and TID
# Return boolean value to thread whether joinable or not

    my ($client,$tid) = @_;
    $WRITE{$client} = exists $RESULT{$tid} ? $true : $false;
} #_is_joinable

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 thread id of thread to check state

sub _is_deadlocked {

# Obtain client socket and TID
# Obtain ordinal of shared that TID is currently trying to lock (if any)
# If TID is not trying to lock anything
#  Return false to client
# Else
#  Check if thread is deadlocked and write appropriate value to client
# Return boolean value to thread whether deadlocked or not

    my ($client,$tid) = @_;
    my $ordinal = List::MoreUtils::firstidx(
        sub { ref($_) eq 'ARRAY' ? grep(/^$tid$/, @{$_}) : 0 }, @LOCKING);
    if ($ordinal == -1) {
        $WRITE{$client} = $false;
    } else {
        $WRITE{$client} = _detect_deadlock($tid, $ordinal) ? $true : $false;
    }
} #_is_deadlocked

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 thread id of thread to signal
#      3 (optional) signal to send

sub _kill {

# Obtain client socket, TID, and signal
# Mark the thread to be signaled with the specified signal
# Make sure the client continues

    my ($client,$tid,$signal) = @_;
    $TOSIGNAL{$tid} = $signal;
    $WRITE{$client} = $true;
} #_kill

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 thread id of thread to check state

sub _wantarray {

# Obtain client socket and TID
# Return thread context (true, defined, or undef)

    my ($client,$tid) = @_;
    $WRITE{$client} = defined $TID2CONTEXT{$tid} ? $TID2CONTEXT{$tid}
        ? $true : $defined : $undef;
} #_wantarray

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 reference to hash with parameters
#      3..N any extra values specified
# OUT: 1 tied ordinal number

sub _tie {

# Obtain client socket
# Obtain local copy of remote object
# Create the name of the routine to fake tying with here, in shared "thread"

    my $client = shift;
    my $remote = shift;
    my $tiewith = 'TIE'.uc($remote->{'type'});

# Obtain the module we should tie with
# If we could load that module successfully
#  Evaluate any code that needs to be evaluated
#  If there are module(s) to be used
#   If there is more than one
#    Use all of them
#   Else
#    Just use this one

    my $module = $remote->{'module'};
    if (eval "use $module; 1") {
        eval $remote->{'eval'} if defined( $remote->{'eval'} );
        if (my $use = $remote->{'use'} || '') {
            if (ref($use)) {
                eval "use $_" foreach @$use;
            } else {
                eval "use $use";
            }
        }

#  Obtain the ordinal number to be used for this shared variable
#  If successful in tieing it and save the object for this shared variable
#   Return the ordinal (we need that remotely to link with right one here)
# Return indicating error

        my $ordinal = $NEXTTIED++;
        if ($TIED[$ordinal] = $module->$tiewith( @_ )) {
            $WRITE{$client} = _pack_response( [$ordinal] );
            return;
        }
    }
    $WRITE{$client} = $undef;
} #_tie

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 ordinal number of variable
#      3 fully qualified name of subroutine to execute
#      4..N parameters to be passed
# OUT: 1..N parameters to be returned

sub _tied {

# Obtain the client socket
# Obtain the object to work with
# Obtain subroutine name to execute

    my $client = shift;
    my $object = $TIED[shift];
    my $sub = shift;

# Initialize code reference
# If there is a code reference already (fetch it on the fly)
# Elseif this is the first time we try this subroutine
#  Create a non-fully qualified version of the subroutine
#  Attempt to get a code reference for that and save it
# Call the subroutine if there is one and return the result

    my $code;
    if (exists $DISPATCH{$sub} && ($code = $DISPATCH{$sub})) {
    } elsif( !exists( $DISPATCH{$sub} ) ) {
    $sub =~ m#^(?:.*)::(.*?)$#;
        $code = $DISPATCH{$sub} = $object->can( $1 );
    }
    my @result;
    if ($code) {
        foreach ($code->( $object,@_ )) {
            if (my $ref = reftype($_)) {
                my $tied = $ref eq 'SCALAR' ? tied ${$_}
                    : $ref eq 'ARRAY' ? tied @{$_}
                    : $ref eq 'HASH' ? tied %{$_}
                    : $ref eq 'GLOB' ? tied *{$_}
                    : undef;
                if (defined $tied && blessed($tied) eq 'threads::shared') {
                    my $ref_obj = $TIED[$tied->{'ordinal'}];
                    bless($_, blessed(${$ref_obj})) if blessed(${$ref_obj});                    
                }
            }
            push @result, $_;
        }
    }
    $WRITE{$client} = $code ? _pack_response( \@result ) : $undef;
} #_tied

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 ordinal number of variable to bless
#      3 class type with which bless object
# OUT: 1 whether successful

sub _bless {

# Obtain the socket
# Obtain the ordinal number of the variable
# Set the tied object's blessed property

    my $client = shift;
    my $ordinal = shift;
    my $class = shift;
    bless(${$TIED[$ordinal]}, $class);

# Indicate that we're done to the client

    $WRITE{$client} = $true;
} #_bless

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 ordinal number of variable to analyze
# OUT: 1 refaddr of variables

sub _id {

# Obtain the socket
# Obtain the object to work with

    my $client = shift;
    my $object = $TIED[shift];

# Write response to client

    $WRITE{$client} = _pack_response( [refaddr( ${$object} )] );
} #_id

#---------------------------------------------------------------------------
#  IN: 1 client sockets
#      2 ordinal number of variable to remove
# OUT: 1 whether successful

sub _untie {

# Obtain the socket
# Obtain the ordinal number of the variable
# Obtain the object
# If we can destroy the object, obtaining code ref on the fly
#  Perform whatever needs to be done to destroy

    my $client = shift;
    my $ordinal = shift;
    my $object = $TIED[$ordinal];
    if (my $code = $object->can( 'DESTROY' )) {
        $code->( $object );
    }

# Kill all references to the variable
# Indicate that we're done to the client

    undef( $TIED[$ordinal] );
    $WRITE{$client} = $true;
} #_untie

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 ordinal number of variable to lock

sub _lock {

# Obtain the client socket
# Obtain the thread id of the thread
# Obtain the ordinal number of the shared variable
# Obtain the client caller filename and line

    my $client = shift;
    my $tid = $CLIENT2TID{$client};
    my $ordinal = shift;
    my $line = shift;
    my $filename = shift;

# If this shared variable is already locked, obtaining its tid on the fly
#  If it's the same thread id
#   Indicate a recursive lock for this variable
#   Let the client continue
#  Else
#   Add the thread to the list of ones that want to lock (and let it block)
#   Perform deadlock deadlock detection immediately, if appropriate

    if (defined $LOCKED[$ordinal]) {
        if ($tid == $LOCKED[$ordinal]) {
            $RECURSED[$ordinal]++;
            $WRITE{$client} = $undef;
        } else {
            push( @{$LOCKING[$ordinal]},$tid );
            $TID2LOCKCALLER{$tid} = [$ordinal, $filename, $line];
            _detect_deadlock($tid, $ordinal)
                if $DEADLOCK_DETECT && !$DEADLOCK_DETECT_PERIOD;
        }

# Else (this variable was not locked yet)
#  Lock this variable
#  Let the client continue

    } else {
        $LOCKED[$ordinal] = $tid;
        $TID2LOCKCALLER{$tid} = [$ordinal, $filename, $line];
        $WRITE{$client} = $undef;
    }
} #_lock

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 ordinal number of variable to unlock

sub _unlock {

# Obtain the client socket
# Obtain ordinal while checking whether locked
# Do the actual unlock
# Make sure the client continues

    my $client = shift;
    my $ordinal = _islocked( $client,shift );
    _unlock_ordinal( $ordinal ) if $ordinal;
    $WRITE{$client} = $true;
} #_unlock

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 ordinal number of (signal) variable to start waiting for
#      3 (optional) ordinal number of lock variable

sub _wait {

# If this is second form of cond_wait
#  Store ordinal of signal variable
#  Check if the lock variable is locked and return ordinal number and thread id
# Else
#  Check if the variable is locked and return ordinal number and thread id
#  Lock ordinal and ordinal are the same in this case; assign ordinal value to lock ordinal
# Unlock the variable
# Add this thread to the list of threads in cond_wait on this variable

    my ($ordinal,$tid,$l_ordinal);
    if (scalar @_ > 2) {
        $ordinal = $_[1];
        ($l_ordinal,$tid) = _islocked( @_[0,2],'cond_wait' );
    } else {
        ($ordinal,$tid) = _islocked( @_,'cond_wait' );
        $l_ordinal = $ordinal;
    }
    _unlock_ordinal( $l_ordinal );
    push( @{$WAITING[$ordinal]},[$tid, $l_ordinal] );
} #_wait

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 ordinal number of variable to start timed waiting for
#      3 absolute expiration time (epoch seconds) of timedwait event
#      4 (optional) ordinal number of lock variable

sub _timedwait {

# If this is second form of cond_wait
#  Store ordinal of signal variable
#  Check if the lock variable is locked and return ordinal number and thread id
# Else
#  Check if the variable is locked and return ordinal number and thread id
#  Lock ordinal and ordinal are the same in this case; assign ordinal value to lock ordinal
# Unlock the variable
# Add this thread to the list of threads in cond_timedwait on this variable

    my ($ordinal,$tid,$l_ordinal);
    my $time = splice(@_, 2, 1);
    if (scalar @_ > 2) {
        $ordinal = $_[1];
        ($l_ordinal,$tid) = _islocked( @_[0,2],'cond_timedwait' );
    } else {
        ($ordinal,$tid) = _islocked( @_,'cond_timedwait' );
        $l_ordinal = $ordinal;
    }
    _unlock_ordinal( $l_ordinal );
    push( @{$TIMEDWAITING{$ordinal}},[$tid, $ordinal, $time, $l_ordinal, ++$TIMEDWAITING_ID] );
    $TIMEDWAITING_IDX_EXPIRED = 1;
} #_timedwait

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 ordinal number of variable to signal one

sub _signal {

# Obtain local copy of the client
# Obtain ordinal

    my $client = shift;
    my $ordinal = shift;

# Get random number to determine which lock waiting list to use first
# Obtain the thread id, target lock ordinal from randomly chosen list
# Obtain the information from alternate list if there is no thread id yet

    my $rand = rand;
    my ($tid, $l_ordinal) = $rand > 0.5
        ? _signal_timedwaiting($ordinal) : _signal_waiting($ordinal);
    ($tid, $l_ordinal) = $rand > 0.5
        ? _signal_waiting($ordinal) : _signal_timedwaiting($ordinal)
        unless defined $tid;

# If a tid was found to be waiting
#  If the signal ordinal is the same as the lock ordinal or the variable they are waiting to relock is currently locked
#   Add the next thread id from the list of waiting or timed waiting threads (if any) to the head of the locking list
#  Else (lock var is not same as signal var and lock var is currently unlocked)
#   Assign lock to this tid
#   Immediately notify blocking thread that it should continue

    if (defined $tid) {
        if ($ordinal == $l_ordinal || defined $LOCKED[$l_ordinal]) {
            unshift( @{$LOCKING[$l_ordinal]}, $tid );
        } else {
            $LOCKED[$l_ordinal] = $tid;
            $WRITE{$TID2CLIENT{$tid}} = $true;
        }
    }

# Make sure the client continues

    $WRITE{$client} = $undef;
} #_signal

#---------------------------------------------------------------------------
#  IN: 1 ordinal number of variable to signal one
# OUT: 1 tid to signal
#      2 ordinal for thread to lock

sub _signal_waiting {

# Initialize the thread id and target lock ordinal
# If there exists a waiting event for this ordinal
#  Get the next thread id from the list of waiting threads (if any)

    my ($tid, $l_ordinal);
    if (defined $WAITING[$_[0]] && ref($WAITING[$_[0]]) eq 'ARRAY'
            && @{$WAITING[$_[0]]}) {
        ($tid, $l_ordinal) = @{shift(@{$WAITING[$_[0]]})};
    }
    return ($tid, $l_ordinal);
}

#---------------------------------------------------------------------------
#  IN: 1 ordinal number of variable to signal one
# OUT: 1 tid to signal
#      2 ordinal for thread to lock

sub _signal_timedwaiting {

# Initialize the thread id and target lock ordinal
# If there exists a timedwaiting event for this ordinal
#  Assign lock to this tid

    my ($tid, $l_ordinal);
    if (defined $TIMEDWAITING{$_[0]} && ref($TIMEDWAITING{$_[0]}) eq 'ARRAY'
            && @{$TIMEDWAITING{$_[0]}}) {
        ($tid, $l_ordinal) = @{shift(@{$TIMEDWAITING{$_[0]}})}[0,3];
        delete $TIMEDWAITING{$_[0]} unless @{$TIMEDWAITING{$_[0]}};
        $TIMEDWAITING_IDX_EXPIRED = 1;
    }
    return ($tid, $l_ordinal);
}

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 ordinal number of variable to signal all

sub _broadcast {

# Obtain local copy of the client
# Obtain ordinal
# If there are threads waiting or timed waiting
#  For all waiting or timed waiting threads
#   If the signal ordinal is the same as the lock ordinal or the variable they are waiting to relock is currently locked
#    Add it to the head of the locking list
#    Purge waiting list for this ordinal (as it's been transferred to locking list)
#    (Perl < 5.8 delete appears to sometimes corrupt array, so use undef in these cases)
#   Else (lock var is not same as signal var and lock var is currently unlocked)
#    Assign lock to this tid
#    Immediately notify blocking thread that it should continue
# Make sure the client continues

    my $client = shift;
    my $ordinal = shift;
    my ($tid, $l_ordinal);
    if (defined $WAITING[$ordinal] && ref($WAITING[$ordinal]) eq 'ARRAY' && @{$WAITING[$ordinal]}) {
        foreach (@{$WAITING[$ordinal]}) {
            ($tid, $l_ordinal) = @{$_};
            if ($ordinal == $l_ordinal || defined $LOCKED[$l_ordinal]) {
                unshift( @{$LOCKING[$l_ordinal]}, $tid );
            } else {
                $LOCKED[$l_ordinal] = $tid;
                $WRITE{$TID2CLIENT{$tid}} = $true;
            }
        }
        if ($] < 5.008) {
            $WAITING[$ordinal] = undef;
        } else {
            delete $WAITING[$ordinal];
        }
    }
    if (defined $TIMEDWAITING{$ordinal} && ref($TIMEDWAITING{$ordinal}) eq 'ARRAY' && @{$TIMEDWAITING{$ordinal}}) {
        foreach (@{$TIMEDWAITING{$ordinal}}) {
            ($tid, $l_ordinal) = @{$_}[0,3];
            if ($ordinal == $l_ordinal || defined $LOCKED[$l_ordinal]) {
                unshift( @{$LOCKING[$l_ordinal]}, $tid );
            } else {
                $LOCKED[$l_ordinal] = $tid;
                $WRITE{$TID2CLIENT{$tid}} = $true;
            }
            $TIMEDWAITING_IDX_EXPIRED = 1;
        }
        delete $TIMEDWAITING{$ordinal};
    }
    
    $WRITE{$client} = $undef;
} #_broadcast

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 thread id that was shutdown

sub _shutdown {

# Obtain the client socket
# Obtain the thread id
# If thread did not appear to exit cleanly
#  Simulate join of the thread with no result
# If it is not the main thread shutting down
#  Unlock all locked variables
#  Reset one of the following events (as thread can only be in one blocking state)
#   Try removing TID from @LOCKING
#   Try removing TID from @WAITING
#   Try removing TID from %TIMEDWAITING
#  Delete any messages that might have been pending for this client
# Else (it's the main thread shutting down and main thread is parent process)
#  Update running flag for pending server shutdown
# Mark this client for deletion
# Send result to thread to allow it to shut down

    my $client = shift;
    my $tid = shift;
    if ((exists $NOTJOINED{$tid} && !exists $RESULT{$tid})
        || ($DETACHED =~ m/\b$tid\b/ && exists $DETACHED_NOTDONE{$tid})) {
        _tojoin($client);   #TODO: report error here ($thr->error reportable)?
    }
    if ($tid) {
        while ((my $ordinal = List::MoreUtils::firstidx(
            sub { defined $_ ? $_ eq $tid : 0 }, @LOCKED)) >= 0) {
            $RECURSED[$ordinal] = 0;
            _unlock_ordinal($ordinal);
        }
        BLOCKING_EVENT: {
            if ((my $ordinal = List::MoreUtils::firstidx(
                sub { ref($_) eq 'ARRAY' ? grep(/^$tid$/, @{$_}) : 0 }, @LOCKING)) >= 0) {
                $LOCKING[$ordinal] = [grep(!/^$tid$/, @{$LOCKING[$ordinal]})];
                last BLOCKING_EVENT;
            }
            if ((my $ordinal = List::MoreUtils::firstidx(
                sub { ref($_) eq 'ARRAY' ? (grep { $_->[0] == $tid } @{$_}) : 0 }, @WAITING)) >= 0) {
                $WAITING[$ordinal] = [grep { $_->[0] != $tid } @{$WAITING[$ordinal]}];
                last BLOCKING_EVENT;
            }
            if ((my $ordinal = List::MoreUtils::firstidx(
                sub { $_->[0] == $tid }, @TIMEDWAITING_IDX)) >= 0) {
                if ((my $idx = List::MoreUtils::firstidx(sub { $_->[0] == $tid }, @{$TIMEDWAITING{$ordinal}})) >= 0) {
                    splice(@{$TIMEDWAITING{$ordinal}}, $idx, 1);
                    $TIMEDWAITING_IDX_EXPIRED = 1;
                    last BLOCKING_EVENT;
                }
            }
        }
    } elsif ($THREADS_INTEGRATED_MODEL) {
        $RUNNING = $client;
    }
    $DONEWITH{$client} = undef;
    $WRITE{$client} = $true;    #TODO: make sure socket is still alive, otherwise could cause server to croak on dead socket (need to protect server with correct error state--EPIPE?)
} #_shutdown

#---------------------------------------------------------------------------
#  IN: 1 ordinal number of shared variable to unlock

sub _unlock_ordinal {

# Obtain the ordinal number
# If this is a recursive lock
#  Remove one recursion
#  And return

    my $ordinal = shift;
    if ($RECURSED[$ordinal]) {
        $RECURSED[$ordinal]--;
        return;
    }

# Get random number to determine which lock waiting list to use first
# Obtain the thread id, target lock ordinal, response from randomly chosen list
# Obtain the information from alternate list if there is no thread id yet

    my $rand = rand;
    my ($tid, $l_ordinal, $response) = $rand > 0.5
        ? _unlock_ordinal_timedwaiting_expired($ordinal) : _unlock_ordinal_locking($ordinal);
    ($tid, $l_ordinal, $response) = $rand > 0.5
        ? _unlock_ordinal_locking($ordinal) : _unlock_ordinal_timedwaiting_expired($ordinal)
        unless defined $tid;

# If there is a thread id for the lock
#  Make that the thread locking the variable
#  And have that thread continue
# Else (still no thread wanting to lock)
#  Just reset the lock for this variable

    if (defined $tid){
        $LOCKED[$l_ordinal] = $tid;
        $WRITE{$TID2CLIENT{$tid}} = $response;
    } else {
        $LOCKED[$l_ordinal] = undef;
    }
} #_unlock_ordinal

#---------------------------------------------------------------------------
#  IN: 1 ordinal number of shared variable to unlock
# OUT: 1 tid to acquire ordinal lock
#      2 ordinal being locked
#      3 response for waiting thread

sub _unlock_ordinal_locking {

# Obtain thread id from locking list and return the results

    return (shift(@{$LOCKING[$_[0]]}), $_[0], $true);
}

#---------------------------------------------------------------------------
#  IN: 1 ordinal number of shared variable to unlock
# OUT: 1 tid to acquire ordinal lock
#      2 ordinal being locked
#      3 response for waiting thread

sub _unlock_ordinal_timedwaiting_expired {
    
# Initialize the thread id and target lock ordinal
# Initialize default response to true
# If there exist any timed waiting events that expired and are waiting to relock
#  Get the thread id and target lock ordinal
#  Set response to false (indicating this event timed out)
# Else
#  Assign default target lock ordinal
# Returns the results

    my ($tid, $l_ordinal);
    my $response = $true;
    if (ref($TIMEDWAITING_EXPIRED[$_[0]]) eq 'ARRAY' && @{$TIMEDWAITING_EXPIRED[$_[0]]}) {
        ($tid, $l_ordinal) = @{shift @{$TIMEDWAITING_EXPIRED[$_[0]]}};
        $response = $false;
    } else {
        $l_ordinal = $_[0];
    }
    return ($tid, $l_ordinal, $response);
}

#---------------------------------------------------------------------------
#  IN: 1 client socket
#      2 ordinal number of variable to start waiting for
#      3 function name to show when there is an error (undef: no error if wrong)
# OUT: 1 ordinal number of variable
#      2 thread id that keeps it locked

sub _islocked {

# Obtain the client socket
# Obtain the thread id of the thread
# Obtain the ordinal number of the shared variable
# If we're not the one locking
#  Return now with nothing if we don't want an error message
#  Die (we want an error message)
# Return the ordinal number and/or thread id

    my $client = shift;
    my $tid = $CLIENT2TID{$client};
    my $ordinal = shift;
    if (!defined $LOCKED[$ordinal] || $tid != $LOCKED[$ordinal]) {
        return unless $_[0];
        _croak( "You need a lock before you can $_[0]: variable #$ordinal ($tid != $LOCKED[$ordinal])" );
    }
    CORE::wantarray ? ($ordinal,$tid) : $ordinal;
} #_islocked

#---------------------------------------------------------------------------
#  IN: 1 client socket to which result will be sent
#      2 thread id of thread with result
#      3..N the result to be sent

sub _isjoined {

# Obtain the client
# Obtain the thread id

    my $client = shift;
    my $tid = shift;

# Unblock the client with the result
# Forget about that someone is waiting for this thread
# Forget about the result (if any)
# Forget about listing in ->list if this thread was shutdown already
# Mark that thread as joined
# Delete thread context information
# Delete thread stack size information

    $WRITE{$client} = _pack_response( [1, @_] );
#warn "case 7: tid $tid had this to say (".scalar(@_)."): ".CORE::join(',', @_);    #TODO: for debugging only
    delete( $BLOCKING_JOIN{$tid} );
    delete( $RESULT{$tid} );
    delete( $TID2PID{$tid} ) unless exists( $TID2CLIENT{$tid} );
    delete( $NOTJOINED{$tid} );
    delete( $TID2CONTEXT{$tid} );
    delete( $TID2STACKSIZE{$tid} );
} #_isjoined

#---------------------------------------------------------------------------

# debugging routines

#---------------------------------------------------------------------------
#  IN: 1 message to display

sub _croak { return &Carp::confess((defined $TID ? $TID : '')." ($$): ".shift) } #_croak

#---------------------------------------------------------------------------
#  IN: 1 message to log

sub _log {

# Obtain the message
# If it is a thread message
#  Obtain the thread id
#  Prefix thread id value
# Shorten message if _very_ long
# Log it

    my $message = shift;
    if (substr($message,0,1) ne ' ') {
        my $tid = defined($TID) ? $TID : '?';
        $message = "$tid $message";
    }
    $message = substr($message,0,256)."... (".(length $message)." bytes)"
     if length( $message ) > 256;
    print STDERR "$message\n";
}#_log

#---------------------------------------------------------------------------
#  IN: 1 client object
# OUT: 1 associated tid
#      2 associated pid

sub _client2tidpid {

# Obtain the thread id
# Return thread and process id

    my $tid = $CLIENT2TID{ (shift) };
    ($tid,$TID2PID{$tid});
} #_client2tidpid

#---------------------------------------------------------------------------

sub _run_CLONE_SKIP {

# Prepare hash for results
# For every package loaded (including main::)
#  Initialize code reference
#  If we tried to get the code reference before (may be undef if not found)
#   Use that

    my %result;
    $result{pkg} = ['main',
        grep { $_ !~ /^CORE::|::SUPER$/o } forks::Devel::Symdump->rnew->packages];
    foreach my $package (@{$result{pkg}}) {
        my $code;
        if (exists $CLONE_SKIP{$package}) {
            $code = $CLONE_SKIP{$package};

#  Else
#   Attempt to obtain the code reference, don't care if failed
#  Execute the CLONE_SKIP subroutine if found, and save result
# Return results

        } else {
            $code = $CLONE_SKIP{$package} = eval { $package->can( 'CLONE_SKIP' ) };
        }
        $result{skip}{$package} = $code->($package) if $code;
    }
    
    return \%result;
} #_run_CLONE_SKIP

#---------------------------------------------------------------------------

sub _run_CLONE {

# Load results of _run_CLONE_SKIP
# For every package loaded (including main::)
#  Initialize code reference
#  If this package CLONE_SKIP returned a true value
#   Find all blessed objects from this class
#    First, "damn" object to unbless and prevent DESTROY
#    Now replace value with an undef SCALAR ref, or undef the existing datastructure
#   Remove package from tracked entities
#   Immediately check next package (skip clone)
#  If we tried to get the code reference before (may be undef if not found)
#   Use that

    my $clone = shift || { skip => undef, pkg => ['main',
        grep { $_ !~ /^CORE::|::SUPER$/o } forks::Devel::Symdump->rnew->packages]};
    CLONE_LOOP: foreach my $package (@{$clone->{pkg}}) {
        my $code;
        if (exists( $clone->{skip}{$package} ) && $clone->{skip}{$package}) {
            $CLONE_SKIP_REF{$package} = {} unless $CLONE_SKIP_REF{$package};
            while (my ($addr, $ref) = each %{$CLONE_SKIP_REF{$package}}) {
                my $class = blessed(${$ref});
                if ($class && $class eq $package) {
                    Acme::Damn::damn(${$ref});
                    if (reftype( ${$CLONE_SKIP_REF{$package}{$addr}} ) eq 'HASH') {
                        undef %{${$CLONE_SKIP_REF{$package}{$addr}}};
                    } elsif (reftype( ${$CLONE_SKIP_REF{$package}{$addr}} ) eq 'ARRAY') {
                        undef @{${$CLONE_SKIP_REF{$package}{$addr}}};
                    } else {
                        undef ${${$CLONE_SKIP_REF{$package}{$addr}}};
                    }
                }
            }
            delete $CLONE_SKIP_REF{$package};
            next CLONE_LOOP;
        } elsif (exists $CLONE{$package}) {
            $code = $CLONE{$package};

#  Else
#   Attempt to obtain the code reference, don't care if failed
#  Execute the CLONE subroutine if found

        } else {
            $code = $CLONE{$package} = eval { $package->can( 'CLONE' ) };
        }
        $code->($package) if $code;
    }
} #_run_CLONE

#---------------------------------------------------------------------------

package
    forks::shared::_preload; # Preload forks::shared for seamless 'require threads::shared'

require forks::shared
 unless exists( $ENV{'THREADS_NO_PRELOAD_SHARED'} ) && $ENV{'THREADS_NO_PRELOAD_SHARED'};

#---------------------------------------------------------------------------

# Satisfy -require-

1;

__END__
=pod

=head1 NAME

forks - drop-in replacement for Perl threads using fork()

=head1 VERSION

This documentation describes version 0.36.

=head1 SYNOPSIS

  use forks;    #ALWAYS LOAD AS FIRST MODULE, if possible
  use warnings;

  my $thread = threads->new( sub {       # or ->create or async()
    print "Hello world from a thread\n";
  } );

  $thread->join;
  
  $thread = threads->new( { 'context' => 'list' }, sub {
    print "Thread is expected to return a list\n";
    return (1, 'abc', 5);
  }
  my @result = $thread->join();

  threads->detach;
  $thread->detach;

  my $tid    = $thread->tid;
  my $owntid = threads->tid;

  my $self    = threads->self;
  my $threadx = threads->object( $tidx );

  my @running = threads->list(threads::running);
  $_->join() foreach (threads->list(threads::joinable));
  $_->join foreach threads->list; #block until all threads done

  unless (fork) {
    threads->isthread; # could be used a child-init Apache handler
  }

  # Enable debugging
  use forks qw(debug);
  threads->debug( 1 );
  
  # Stringify thread objects
  use forks qw(stringify);
  
  # Check state of a thread
  my $thr = threads->new( ... );
  if ($thr->is_running()) {
    print "Thread $thr running\n"; #prints "Thread 1 running"
  }
  
  # Send a signal to a thread
  $thr->kill('SIGUSR1');

  # Manual deadlock detection
  if ($thr->is_deadlocked()) {
    print "Thread $thr is currently deadlocked!\n";
  }
  
  # Use forks as a drop-in replacement for an ithreads application
  perl -Mforks threadapplication
  
See L<threads/"SYNOPSIS"> for more examples.
  
=head1 DESCRIPTION

The "forks" pragma allows a developer to use threads without having to have
a threaded perl, or to even run 5.8.0 or higher.

Refer to the L<threads> module for ithreads API documentation.  Also, use

    perl -Mforks -e 'print $threads::VERSION'
    
to see what version of L<threads> you should refer to regarding supported API
features.

There were a number of goals that I am trying to reach with this implementation.

=over 2

Using this module B<only> makes sense if you run on a system that has an
implementation of the C<fork> function by the Operating System.  Windows
is currently the only known system on which Perl runs which does B<not>
have an implementation of C<fork>.  Therefore, it B<doesn't> make any
sense to use this module on a Windows system.  And therefore, a check is
made during installation barring you from installing on a Windows system.

=back

=head2 module load order: forks first

Since forks overrides core Perl functions, you are *strongly* encouraged to
load the forks module before any other Perl modules.  This will insure the
most consistent and stable system behavior.  This can be easily done without
affecting existing code, like:

    perl -Mforks  script.pl

=head2 memory usage

The standard Perl 5.8.0 threads implementation is B<very> memory consuming,
which makes it basically impossible to use in a production environment,
particularly with mod_perl and Apache.  Because of the use of the standard
Unix fork() capabilities, most operating systems will be able to use the
Copy-On-Write (COW) memory sharing capabilities (whereas with the standard Perl
5.8.0 threads implementation, this is thwarted by the Perl interpreter
cloning process that is used to create threads).  The memory savings have
been confirmed.

=head2 mod_perl / Apache

This threads implementation allows you to use a standard, pre-forking Apache
server and have the children act as threads (with the class method
L</"isthread">).

=head2 same API as threads

You should be able to run threaded applications unchanged by simply making
sure that the "forks" and "forks::shared" modules are loaded, e.g. by
specifying them on the command line.  Forks is currently API compatible with
CPAN L<threads> version C<1.53>.

Additionally, you do not need to worry about upgrading to the latest Perl
maintenance release to insure that the (CPAN) release of threads you wish to
use is fully compatibly and stable.  Forks code is completely independent of
the perl core, and thus will guarantee reliable behavior on any release of
Perl 5.8 or later.  (Note that there may be behavior variances if running
under Perl 5.6.x, as that version does not support safe signals and requires
a source filter to load forks).

=head2 using as a development tool

Because you do not need a threaded Perl to use forks.pm, you can start
prototyping threaded applications with the Perl executable that you are used
to.  Just download and install the "forks" package from CPAN.  So
the threshold for trying out threads in Perl has become much lower.  Even
Perl 5.005 should, in principle, be able to support the forks.pm module;
however, some issues with regards to the availability of XS features between
different versions of Perl, it seems that 5.6.0 (unthreaded) is what you need
at least.

Additionally, forks offers a full thread deadlock detection engine, to help
discover and optionally resolve locking issues in threaded applications.  See
L<forks::shared/"Deadlock detection and resolution"> for more information.

=head2 using in production environments

This package has successfully been proven as stable and reliable in production 
environments.  I have personally used it in high-availability, database-driven, 
message processing server applications since 2004 with great success.

Also, unlike pure ithreads, forks.pm is fully compatible with all perl modules,
whether or not they have been updated to be ithread safe.  This means that you
do not need to feel limited in what you can develop as a threaded perl
application, a problem that continues to plague the acceptance of ithreads in
production enviroments today.  Just handle these modules as you would when
using a standard fork: be sure to create new instances of, or connections to,
resources where a single instance can not be shared between multiple processes.

The only major concern is the potentially slow (relative to pure ithreads)
performance of shared data and locks.  If your application doesn't depend on
extensive semaphore use, and reads/writes from shared variables moderately
(such as using them primarily to deliver data to a child thread to process
and the child thread uses a shared structure to return the result), then this
will likely not be an issue for your application.  See the TODO section
regarding plans to tackle this issue.

Also, you may wish to try L<forks::BerkeleyDB>, which has shown signifigant
performance gains and consistent throughoutput in high-concurrency shared
variable applications.

=head2 Perl built without native ithreads

If your Perl release was not built with ithreads or does not support ithreads,
you will have a compile-time option of installing forks into the threads and
threads::shared namespaces.  This is done as a convenience to give users a
reasonably seamless ithreads API experience without having to rebuild their
distribution with native threading (and its slight performance overhead on all
perl runtime, even if not using threads).

B<Note:> When using forks in this manner (e.g. "use threads;") for the first
time in your code, forks will attempt to behave identically to threads relative
to the current version of L<threads> it supports (refer to $threads::VERSION),
even if the behavior is (or was) considered a bug.  At this time, this means
that shared variables will lose their pre-existing value at the time they are
shared and that splice will die if attempted on a shared scalar.

If you use forks for the first time as "use forks" and other loaded code uses
"use threads", then this threads behavior emulation does not apply. 

=head1 REQUIRED MODULES

 Acme::Damn (any)
 Attribute::Handlers (any)
 Devel::Symdump (any)
 File::Spec (any)
 if (any)
 IO::Socket (1.18)
 List::MoreUtils (0.15)
 Scalar::Util (1.11)
 Storable (any)
 Sys::SigAction (0.11)
 Test::More (any)
 Time::HiRes (any)

=head1 IMPLEMENTATION

This version is mostly written in Perl.  Inter-process communication
is done by using sockets, with the process that stores the shared variables
as the server and all the processes that function as threads, as clients.

=head2 why sockets?

The reason I chose sockets for inter-thread communication above using a shared
memory library, is that a blocking socket allows you to elegantly solve the
problem of a thread that is blocking for a certain event.  Any polling that
might occur, is not occurring at the Perl level, but at the level of the
socket, which should be much better and probably very optimized already.

=head1 EXTRA CLASS METHODS

Apart from the standard class methods, the following class methods are supplied
by the "forks" threads implementation.

=head2 isthread

 unless (fork) {
   threads->isthread; # this process is a detached thread now
   exit;              # can not return values, as thread is detached
 }

The C<isthread> class method attempt to make a connection with the shared
variables process.  If it succeeds, then the process will function as a
detached thread and will allow all the threads methods to operate.

This method is mainly intended to be used from within a child-init handler
in a pre-forking Apache server.  All the children that handle requests become
threads as far as Perl is concerned, allowing you to use shared variables
between all of the Apache processes.  See L<Apache::forks> for more information.

=head2 debug

 threads->debug( 1 );
 $debug = threads->debug;

The "debug" class method allows you to (re)set a flag which causes extensive
debugging output of the communication between threads to be output to STDERR.
The format is still subject to change and therefore still undocumented.

Debugging can B<only> be switched on by defining the environment variable
C<THREADS_DEBUG>.  If the environment variable does not exist when the forks.pm
module is compiled, then all debugging code will be optimised away to create
a better performance.  If the environment variable has a true value, then
debugging will also be enabled from the start.

=head1 EXTRA FEATURES

=head2 Native threads 'to-the-letter' emulation mode

By default, forks behaves slightly differently than native ithreads, regarding
shared variables.  Specifically, native threads does not support splice() on
shared arrays, nor does it retain any pre-existing values of arrays or hashes
when they are shared; however, forks supports all of these functions.  These are
behaviors are considered limitations/bugs in the current native ithread
implementation.

To allow for complete drop-in compatibility with scripts and modules written for
threads.pm, you may specify the environment variable C<THREADS_NATIVE_EMULATION>
to a true value before running your script.  This will instruct forks to behave
exactly as native ithreads would in the above noted situations.

This mode may also be enabled by default (without requiring this environment variable
if you do not have a threaded Perl and wish to install forks as a full drop-in
replacement.  See L</"Perl built without native ithreads"> for more information.

=head2 Deadlock detection

Forks also offers a full thread deadlock detection engine, to help discover
and optionally resolve locking issues in threaded applications.  See
L<forks::shared/"Deadlock detection and resolution"> for more information.

=head2 Perl debugger support

Forks supports basic compabitility with the Perl debugger.  By default, only the
main thread to the active terminal (TTY), allowing for debugging of scripts where
child threads are run as background tasks without any extra steps.

If you wish to debug code executed in child threads, you may need to perform a few
steps to prepare your environment for multi-threaded debugging.

The simplest option is run your script in xterm, as Perl will automatically create
additional xterm windows for each child thread that encounters a debugger breakpoint.

Otherwise, you will need to manually tell Perl how to map a control of thread to a
TTY.  Two undocumented features exist in the Perl debugger:

1. Define global variable C<$DB::fork_TTY> as the first stem in the subroutine for
a thread.  The value must be a valid TTY name, such as '/dev/pts/1' or '/dev/ttys001';
valid names may vary across platforms.  For example:

    threads->new(sub {
        $DB::fork_TTY = '/dev/tty003'; #tie thread to TTY 3
        ...
    });
    
Also, the TTY must be active and idle prior to the thread executing.  This normally
is accomplished by opening a new local or remote session to your machine, identifying
the TTY via `tty`, and then typing `sleep 10000000` to prevent user input from being
passed to the command line while you are debugging.

When the debugger halts at a breakpoint in your code in a child thread, all output and
user input will be managed via this TTY.

2. Define subroutine DB::get_fork_TTY()

This subroutine will execute once each child thread as soon as it has spawned.  Thus,
you can create a new TTY, or simply bind to an existng, active TTY.  In this subroutine,
you should define a unique, valid TTY name for the global variable C<$DB::fork_TTY>.

For example, to dynamically spawn a new xterm session and bind a new thread to it, you
could do the following:

sub DB::get_fork_TTY {
    open XT, q[3>&1 xterm -title 'Forked Perl debugger' -e sh -c 'tty1>&3;\ sleep 10000000' |];
    $DB::fork_TTY = <XT>;
    chomp $DB::fork_TTY;
}

For more information and tips, refer to this excellent Perl Monks thread:
L<<a href="http://www.perlmonks.org/?node_id=128283">Debugging Several Proccesses
at Same Time</a>>.

=head2 INET socket IP mask

For security, inter-thread communication INET sockets only will allow connections
from the default local machine IPv4 loopback address (e.g 127.0.0.1).  However,
this filter may be modified by defining the environment variable C<THREADS_IP_MASK>
with a standard perl regular expression (or with no value, which would disable the
filter).

=head2 UNIX socket support

For users who do not wish to (or can not) use TCP sockets, UNIX socket support
is available.  This can be B<only> switched on by defining the environment
variable C<THREADS_SOCKET_UNIX>.  If the environment variable has a true value, then
UNIX sockets will be used instead of the default TCP sockets.  Socket descriptors 
are currently written to /var/tmp and given a+rw access by default (for cleanest 
functional support on multi-user systems).

This feature is excellent for applications that require extra security, as it
does not expose forks.pm to any INET vunerabilities your system may be
subject to (i.e. systems not protected by a firewall).  It also may
provide an additional performance boost, as there is less system overhead
necessary to handle UNIX vs INET socket communication.

=head2 Co-existance with fork-aware modules and environments

For modules that actively monitor and clean up after defunct child processes
like L<POE>, forks has added support to switch the methodology used to maintain
thraad group state.  This feature is switched on by defining the environment
variable C<THREADS_DAEMON_MODEL>.  An example use might be:

    THREADS_DAEMON_MODEL=1 perl -Mforks -MPOE threadapplication

This function essentially reverses the parent-child relationship between the
main thread and the thread state process that forks.pm uses.  Extra care has
gone into retaining full system signal support and compatibility when using
this mode, so it should be quite stable.

=head1 NOTES

Some important items you should be aware of.

=head2 Signal behavior

Unlike ithreads, signals being sent are standard OS signals, so you should
program defensively if you plan to use inter-thread signals.

Also, be aware that certain signals may untrappable depending on the target
platform, such as SIGKILL and SIGSTOP.  Thus, it is recommended you only use
normal signals (such as TERM, INT, HUP, USR1, USR2) for inter-thread signal
handling.

=head2 exit() behavior

If you call exit() in a thread other than the main thread and exit behavior
is configured to cause entire application to exit (default behavior), be aware
that all other threads will be agressively terminated using SIGKILL.  This
will cause END blocks and global destruction to be ignored in those threads.

This behavior conforms to the expected behavior of native Perl threads. The
only subtle difference is that the main thread will be signaled using SIGABRT
to immediately exit.

If you call C<fork()> but do not call <threads->isthread()>, then the child
process will default to the pre-existing CORE::GLOBAL::exit() or CORE::exit()
behavior.  Note that such processes are exempt from application global
termination if exit() is called in a thread, so you must manually clean up
child processes created in this manner before exiting your threaded application.

=head2 END block behavior

In native ithreads, END blocks are only executed in the thread in which the
code was loaded/evaluated.  However, in forks, END blocks are processed in
all threads that are aware of such code segments (i.e. threads started after
modules with END blocks are loaded).  This may be considered a bug or a feature
depending on what your END blocks are doing, such as closing important external
resources for which each thread may have it's own handle.

In general, it is a good defensive programming practice to add the following to
your END blocks when you want to insure sure they only are evaluated in the thread
that they were created in:

    {
        my $tid = threads->tid if exists $INC{'threads.pm'};
        END {
            return if defined($tid) && $tid != threads->tid;
            # standard end block code goes here
        }
    }

This code is completely compatible with native ithreads.  Note that this
behavior may change in the future (at least with THREADS_NATIVE_EMULATION mode).

=head2 Modifying signals

Since the threads API provides a method to send signals between threads
(processes), untrapped normal and error signals are defined by forks with
a basic exit() shutdown function to provide safe termination.

Thus, if you (or any modules you use) modify signal handlers, it is important
that the signal handlers at least remain defined and are not undefined (for
whatever reason).  The system signal handler default, usually abnormal
process termination which skips END blocks, may cause undesired behavior if
a thread exits due to an unhandled signal.

In general, the following signals are considered "safe" to trap and use in
threads (depending on your system behavior when such signals are trapped):

    HUP INT PIPE TERM USR1 USR2 ABRT EMT QUIT TRAP

=head2 Modules that modify %SIG or use POSIX::sigaction()

To insure highest stability, forks ties some hooks into the global %SIG hash
to co-exist as peacefully as possible with user-defined signals.  This has a 
few subtle, but important implications:

    - As long as you modify signals using %SIG, you should never encounter any
    unexpected issues.

    - If you use POSIX::sigaction, it may subvert protections that forks has
    added to the signal handling system.  In normal circumstances, this will not
    create any run-time issues; however, if you also attempt to access shared
    variables in signal handlers or END blocks, you may encounter unexpected
    results.  Note: if you do use sigaction, please avoid overloading the ABRT
    signal in the main thread, as it is used for process group flow control.

=head2 Modules that modify $SIG{CHLD}

In order to be compatible with perl's core system() function on all platforms,
extra care has gone into implementing a smarter $SIG{CHLD} in forks.pm.  The
only functional effect is that you will never need to (or be able to) reap
threads (processes) if you define your own CHLD handler.

You may define the environment variable THREADS_SIGCHLD_IGNORE to to force 
forks to use 'IGNORE' on systems where a custom CHLD signal handler has been
automatically installed to support correct exit code of perl core system()
function.  Note that this should *not* be necessary unless you encounter specific
issues with the forks.pm CHLD signal handler.

=head2 $thr->wantarray() returns void after $thr->join or $thr->detach

Be aware that thread return context is purged and $thr->wantarray will return
void context after a thread is detached or joined.  This is done to minimize
memory in programs that spawn many (millions of) threads.  This differs from
default threads.pm behavior, but should be acceptable as the context no longer
serves a functional purpose after a join or detach.
Thus, if you still require thread context information after a join, be sure to
request and store the value of $thr->wantarray first.

=head2 $thr->get_stack_size() returns default after $thr->join or $thr->detach

Thread stack size information is purged and $thr->get_stack_size will return
the current threads default after a thread is detached or joined.  This is done
to minimize memory in programs that spawn many (millions of) threads.  This
differs from default threads.pm behavior, which retains per-thread stack size
information indefinitely.
Thus, if you require individual thread stack size information after a join or
detach, be sure to request and store the value of $thr->get_stack_size first.

=head2 Modules that modify CORE::GLOBAL::fork()

This modules goes to great lengths to insure that normal fork behavior is
seamlessly integrated into the threaded environment by overloading
CORE::GLOBAL::fork.  Thus, please refrain from overloading this function unless
absolutely necessary.  In such a case, forks.pm provides a set of four functions:

    _fork_pre
    _fork
    _fork_post_parent
    _fork_post_child

that represent all possible functional states before and after a fork occurs.
These states must be called to insure that fork() works for both threads and
normal fork calls.

Refer to forks.pm source code, *CORE::GLOBAL::fork = sub { ... } definition
as an example usage.  Please contact the author if you have any questions
regarding this.

=head1 CAVEATS

Some caveats that you need to be aware of.

=head2 Greater latency

Because of the use of sockets for inter-thread communication, there is an
inherent larger latency with the interaction between threads.  However, the
fact that TCP sockets are used, may open up the possibility to share threads
over more than one physical machine.

You may decrease some latency by using UNIX sockets (see L</"UNIX socket support">).

Also, you may wish to try L<forks::BerkeleyDB>, which has shown signifigant performance
gains and consistent throughoutput in applications requiring high-concurrency shared
variable access.

=head2 Module CLONE & CLONE_SKIP functions and threads

In rare cases, module CLONE functions may have issues when being auto-executed
by a new thread (forked process).  This only affects modules that use XS data
(objects or struts) created by to external C libraries.  If a module attempts
to CLONE non-fork safe XS data, at worst it may core dump only the newly
created thread (process).

If CLONE_SKIP function is defined in a package and it returns a true value, all
objects of this class type will be undefined in new threads.  This is generally the
same behavior as native threads with Perl 5.8.7 and later.  See <<a href="http://perldoc.perl.org/perlmod.html#Making-your-module-threadsafe-threadsafe-thread-safe-module%2c-threadsafe-module%2c-thread-safe-CLONE-CLONE_SKIP-thread-threads-ithread">perlmod</a>>
for more information.

However, two subtle behavior variances exist relative to native Perl threads:

    1. The actual undefining of variables occurs in the child thread.  This should
    be portable with all non-perl modules, as long as those module datastructures can be
    safely garbage collected in the child thread (note that DESTROY will not be called).
    
    2. Arrays and hashes will be emptied and unblessed, but value will not be converted
    to an undef scalar ref.  This differs from native threads, where all references
    become an undef scalar ref.  This should be generally harmless, as long as you are
    careful with variable state checks (e.g. check whether reference is still blessed,
    not whether the reftype has changed, to determine if it is still a valid object
    in a new thread).

Overall, if you treat potentially sensitive resources (such as L<DBI> driver instances) as 
non-thread-safe by default and close these resources prior to creating a new
thread, you should never encounter any portability issues.

=head2 Can't return unshared filehandles from threads

Currently, it is not possible to return a file handle from a thread to the
thread that is joining it.  Attempting to do so will throw a terminal error.
However, if you share the filehandle first with L<forks::shared>, you can safely
return the shared filehandle.

=head2 Signals and safe-signal enabled Perl

In order to use signals, you must be using perl 5.8 compiled with safe signal
support.  Otherwise, you'll get a terminal error like "Cannot signal threads
without safe signals" if you try to use signal functions.

=head2 Source filter

To get forks.pm working on Perl 5.6.x, it was necessary to use a source
filter to ensure a smooth upgrade path from using forks under Perl 5.6.x to
Perl 5.8.x and higher.  The source filter used is pretty simple and may
prove to be too simple.  Please report any problems that you may find when
running under 5.6.x.

=head1 TODO

See the TODO file in the distribution.

=head1 KNOWN PROBLEMS

These problems are known and will hopefully be fixed in the future:

=over 2

=item test-suite exits in a weird way

Although there are no errors in the test-suite, the test harness sometimes
thinks there is something wrong because of an unexpected exit() value.  This
is an issue with Test::More's END block, which wasn't designed to co-exist
with a threads environment and forked processes.  Hopefully, that module will
be patched in the future, but for now, the warnings are harmless and may be
safely ignored.

And of course, there might be other, undiscovered issues.  Patches are welcome!

=back

=head1 CREDITS

Refer to the C<CREDITS> file included in the distribution.

=head1 CURRENT AUTHOR AND MAINTAINER

Eric Rybski <rybskej@yahoo.com>.  Please send all module inquries to me.

=head1 ORIGINAL AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c)
 2005-2014 Eric Rybski <rybskej@yahoo.com>,
 2002-2004 Elizabeth Mattijsen <liz@dijkmat.nl>.
All rights reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<threads>, L<forks::BerkeleyDB>, L<Apache::forks>.

=cut
