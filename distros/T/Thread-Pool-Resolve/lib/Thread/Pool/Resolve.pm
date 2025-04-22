package Thread::Pool::Resolve;

# Make sure we have version info for this module
# Make sure we inherit from Thread::Pool
# Make sure we do everything by the book from now on

$VERSION = '0.13';
@ISA = qw(Thread::Pool);
use strict;

# Make sure we only load stuff when we actually need it

use load;

# Make sure we can have a pool of threads

use Thread::Pool ();

# Default timeout value to apply to default resolver

our $TIMEOUT = 60; # seconds

# Thread local reference to the shared resolved hash
# Thread local reference to the resolver routine
# Thread local reference to the shared status hash
# Thread local output handle

our $resolved;
our $resolver;
our $status;
our $output;

# Initialize the hash with module -> read method name translation

our %read_method = (
 'IO::Handle'		=> 'getline',
 'Thread::Conveyor'	=> 'take',
 'Thread::Queue'	=> 'dequeue',
);

# Initialize the list of letters for random domains

our @letter = split( '','abcdefghijklmnopqrstuvwxyz0123456789-' );
 
# Satisfy -require-

1;

#---------------------------------------------------------------------------

# The following subroutines are loaded on demand only

__END__

#---------------------------------------------------------------------------

# Class methods

#---------------------------------------------------------------------------
#  IN: 1 class for which to bless
#      2 reference to parameter hash (optional)
#      3..N any parameters to be passed to "pre" and "post" routines

sub new {

# Obtain the class for which to bless
# Obtain the parameter hash or create one
# Bless it for now

    my $class = shift;
    my $self = shift || {};
    bless $self,$class;

# If we're in a suspect version and we don't have a signal yet
#  If we're not in the main thread (and not primed)
#   Die now if we can't reliable use alarm()
#  Else (we're in the main thread and not primed)
#   Tell the world we're doing something naughty
#   Set ALRM signal to something to get alarm() to work inside threads

    if ($^V ge v5.8.0 and !$SIG{ALRM}) {
        if (threads->tid) {
            die "Cannot reliably use signals in threads\n" unless $SIG{ALRM};
        } else {
            warn "Priming \$SIG{ALRM} to get signals to work inside threads\n";
            $SIG{ALRM} = sub {};
        }
    }

# Die now if illegal fields specified
# Make sure we have code references for everything specified

    $self->_die( 'when resolving',qw(do stream) );
    $self->_makecoderef(caller().'::',qw(close monitor open post pre resolver));

# If there is a specific routine for opening the output file is specified
#  Die now if wrong field combination specified
#  Activate the special "pre" routine to handle that (closure)
#  Activate the special "post" routine to handle closing (closure) if specified
#  Activate the special "monitor" routine to handle writing

    if (exists( $self->{'open'} )) {
        $self->_die( "when using 'open'",qw(pre post monitor) );
        $self->{'pre'} = sub { $output = $self->{'open'}->( @_ ) };
        $self->{'post'} = sub { $self->{'close'}->( @_ ); close( $output ) }
         if exists( $self->{'close'} );
        $self->{'monitor'} = \&_monitor;

#  Elseif we have our own monitoring routine
#   Die now if a "close" field was specified

    } elsif (exists( $self->{'monitor'} )) {
        $self->_die( "when using 'monitor'",qw(close) );

# Else (no special output opening specified)
#  Just set the standard "open" and "monitor" routine to handle writing

    } else {
        @$self{qw(pre monitor)} = (\&_open,\&_monitor);
    }

# Make sure we have a hash reference for the resolved information
# Make sure it is shared (in case it isn't already)
# Set the resolver routine if none specified yet
# Set the thread local status reference

    $resolved = $self->{'resolved'} ||= {};
    threads::shared::share( %$resolved );
    $resolver = $self->{'resolver'} ||= \&_resolvr;
    $status = $self->{'status'};

# Set the "do" subroutine
# Set the initial number of workers if none specified yet
# Set flag for pre/post monitor only

    $self->{'do'} = \&_resolve;
    $self->{'workers'} ||= 10;
    $self->{'pre_post_monitor_only'} = 1;

# Create local copy of subref for pre-actions
# Set pre-action to this subroutine with closure
#  Load POSIX if not loaded yet (unfortunately needed)
#  Set the signal the difficult (but more reliable) way
#  Perform the original pre action if any available

    my $pre = $self->{'pre'};
    $self->{'pre'} = sub {
        require POSIX; # good thing that POSIX uses AutoLoader also
        POSIX::sigaction( "POSIX::SIGALRM"->(), # weird way of getting constant
	 POSIX::SigAction->new( sub {die "timed out\n"} ) );
        goto &$pre if $pre;
    };
        

# Create the subclassed Thread::Pool object with specific settings and return it

    $class->SUPER::new( $self,@_ );
} #new

#---------------------------------------------------------------------------

# Class methods

#---------------------------------------------------------------------------
#  IN: 1 class or instantiated object
# OUT: 1 reference to the shared resolved hash

sub resolved { ref($_[0]) ? $_[0]->{'resolved'} : $resolved } #resolved

#---------------------------------------------------------------------------
#  IN: 1 class or instantiated object
# OUT: 1 reference to resolver routine

sub resolver { ref($_[0]) ? $_[0]->{'resolver'} : $resolver } #resolver

#---------------------------------------------------------------------------
#  IN: 1 class or instantiated object
# OUT: 1 reference to status hash

sub status { ref($_[0]) ? $_[0]->{'status'} : $status } #status

#---------------------------------------------------------------------------
#  IN: 1 class or instantiated object
#      2 new timeout value for default resolver
# OUT: 1 current timeout value for default resolver

sub timeout {

# Set new timeout value if one given
# Return current timeout value

    $TIMEOUT = $_[1] if @_ > 1;
    $TIMEOUT;
} #timeout

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
# OUT: 1 a random domain

sub rand_domain {

# Start the domain with a random word
# Calculate a random number of words (at least 2)
# For all of the words that need to be added
#  Add another random word with a period in front of it
# Return the result

    my $domain = _word();
    my $words = 2+int(rand(4));
    foreach (1..$words) {
        $domain .= ('.'._word());
    }
    $domain;
} #rand_domain

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
# OUT: 1 a random IP number

sub rand_ip {
  int(rand(256)).'.'.int(rand(256)).'.'.int(rand(256)).'.'.int(rand(256));
} #rand_ip

#---------------------------------------------------------------------------

# Object methods

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 filename or object to read from (default: STDIN)
#      3 any PerlIO layers to apply (default: none)
# OUT: 1 instantiated object

sub read {

# Obtain the object
# Obtain the thingy to read from
# Obtain the IO layers (if any)
# Obtain the code reference to the line routine here

    my $self = shift;
    my $read = shift || \*STDIN;
    my $layer = shift || '';
    my $line = $self->can( 'line' );

# If the thingy is not an object and it appears to be a filename or scalar ref
#  Attempt to open the file for reading and die if failed
#  Use the handle from now on to read from
# Die now if we don't have a reference by now

    if (
     (!ref($read) and -e $read and !-d _ and !-z _) or
     (ref($read) eq 'SCALAR')) {
	open( my $handle,"<$layer",$read )
	 or die "Could not open file '$read' for reading: $!";
        $read = $handle;
    }
    die "Don't know how to handle '$read'" unless ref($read);

# Initialize module and method name
# Set the method if there is a direct match
# If we don't have a method yet
#  For all of the module/method pairs ($method undef on last iteration)
#   Outloop if the thingy inherits from a known module (keeps $method)

    my ($module,$method);
    $method = $read_method{$module} if $module = ref($read);
    unless ($method) {
        while (($module,$method) = each( %read_method )) {
            last if $read->isa( $module );
        }
    }

# If we have a module and a method now
#  Localize $_ (who knows will fool around with it)
#  If we can convert the method name to a code reference
#   While we get values from the read method
#    Return now if it was the undefined value
#    Resolve what we got

    if ($module and $method) {
        local( $_ );
        if (my $sub = UNIVERSAL::can( $read,$method )) {
            while (($_) = $sub->( $read )) {
                last unless defined();
                $line->( $self,$_ );
            }

#  Else (no code reference possible, use the slow way)
#   While we get values from the read method
#    Return now if it was the undefined value
#    Resolve what we got

        } else {
            while (($_) = $read->$method) {
                last unless defined();
                $line->( $self,$_ );
            }
        }

# Else (we don't have a method, assume readline() will know)
#  While we get a defined value
#   Resolve what we got
# Return (we're done)

    } else {
        while (defined( $_ = readline( $read ))) {
            $line->( $self,$_ );
        }
    }
    return $self;
} #read

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 one line to be resolved

sub line { goto &Thread::Pool::job } #line

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2..N lines to be resolved
# OUT: 1 instantiated object

sub lines {

# Obtain the object
# Obtain reference to the method
# Submit all the lines specified
# Return the instantiated object

    my $self = shift;
    my $line = $self->can( 'line' );
    $line->( $self,$_ ) foreach @_;
    $self;
} #lines

#--------------------------------------------------------------------

# Internal subroutines

#--------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 extra reason to show
#      3..N field names to check and die for if found

sub _die {

# Obtain the object
# Obtain the reason
# If there are any fields specified that are not allowed here
#  Die telling which fields are not allowed

    my $self = shift;
    my $reason = shift;
    if (my @found = map { exists( $self->{$_} ) ? ($_) : () } @_) {
        die "Cannot specify field(s) '".join("','",@found)."' $reason.";
    }
} #_die

#--------------------------------------------------------------------
#  IN: 1 log line to resolve
# OUT: 1 resolved log line (unless being resolved by other thread)

sub _resolve {

# Obtain the line to work with
# Return it now if it is already resolved (at least not an IP-number there)
# Save the IP number for later usage, line is now without IP-number

    my $line = shift;
    return $line unless $line =~ s#^(\d+\.\d+\.\d+\.\d+)##;
    my $ip = $1;

# Set local reference for message setting if we should
# Set status message if status should be set

    my $mess = $status ? \$status->{threads->tid} : '';
    $$mess = "About to resolve $ip" if $mess;

# Make sure we're the only one to access the resolved hash now
# If there is already information for this IP number
#  If we're not waiting for the result
#   If we should add a message
#    Set appropriate message
#   Return domain with the rest of the line

    {lock( %$resolved );
     if (exists( $resolved->{$ip} )) {
         unless (ref( $resolved->{$ip} )) {
             if ($mess) {
                 $$mess = $resolved->{$ip} ?
                  "Found $resolved->{$ip} for $ip in resolved hash" :
                  "$ip could not be resolved";
             }
             return ($resolved->{$ip} || $ip).$line;
         }

#  Set status is status should be set
#  Set the rest of the line in the todo hash, keyed to jobid
#  Set the flag that this result should not be set in the result hash
#  And return without anything (thread will continue with next job)

	 $$mess = "Queueing $ip to be resolved by other thread" if $mess;
         $resolved->{$ip}->{Thread::Pool->jobid} = $line;
         Thread::Pool->dont_set_result;
         return;

# Else (first time this IP-number is encountered)
#  Set status if status should be set
#  Create an empty shared hash with the rest of the line keyed to the jobid
#  Save a reference to the hash in the todo hash as info for this IP number

     } else {
         $$mess = "Initializing queue for resolving $ip" if $mess;
         my %hash : shared;
         $resolved->{$ip} = \%hash;
     }
    } #%$resolved

# If we should set status
#  Set status with appropriate info

    if ($mess) {
        $$mess = $TIMEOUT ?
         "Resolving $ip with timeout of $TIMEOUT seconds" :
         "Resolving $ip without specific timeout";
    }

# Do the actual name resolving (this may take quite some time)
# If we should set status
#  Set status with appropriate info

    my $domain = $resolver->( $ip ) || $ip;
    if ($mess) {
        $$mess = $domain ?
         "Resolved $ip to $domain" :
         "Could not resolve $ip";
    }

# Obtain local copy of the Thread::Pool object
# Obtain local copy of the todo hash
# Make sure we're the only one accessing the resolved hash (rest of this sub)

    my $pool = Thread::Pool->self;
    my $todo = $resolved->{$ip};
    lock( %$resolved );

# Set status if appropriate
# For all of the lines with this IP-number
#  Set the result for this line

    $$mess = "Processing queue for resolving of $ip" if $mess;
    while (my ($key,$value) = each( %{$todo} )) {
        $pool->set_result( $key,$domain.$todo->{$key} );
    }

# If status should be set
#  Set appropriate status

    if ($mess) {
        $$mess = $domain eq $ip ?
         "Finished resolving $ip: no result" :
         "Finished resolving $ip: found $domain";
    }

# Remove todo hash and replace by domain (or blank string)
# Return the result

    $resolved->{$ip} = $domain eq $ip ? undef : $domain;
    $domain.$line;
} #_resolve

#---------------------------------------------------------------------------
#  IN: 1 IP-number to resolve
# OUT: 1 domain name (undef if none available)

sub _resolvr {

# Initialize domain to be returned
# Make sure we can catch the alarm
#  If there is a timeout set
#   Set timer for timeout to be applied if one given
#   Attempt to obtain the domain
#   Reset the timer if one was given
#  Else (no timeout)
#   Attempt to obtain the domain

    my $domain;
    eval {
     if ($TIMEOUT) {
         alarm( $TIMEOUT );
         $domain = gethostbyaddr( pack( 'C4',split(/\./,shift)),2 );
         alarm( 0 );
     } else {
         $domain = gethostbyaddr( pack( 'C4',split(/\./,shift)),2 );
     }
    };

# Die now with unanticipated error if not anticipated
# Return whatever was (not) returned

    die $@ if $@ and $@ ne "timed out\n";
    $domain;
} #_resolvr

#---------------------------------------------------------------------------
#  IN: 1 file to open (default: STDOUT)
#      2 layers to be applied (default: none)

sub _open {

# If there is a filename and/or layers specified
#  Attempt to open the file for writing or die
# Else
#  Set to use STDOUT

    if (@_) {
        open( $output,">$_[1]",$_[0] ) or die "$_[0]: $!";
    } else {
        $output = \*STDOUT;
    }
} #_open

#---------------------------------------------------------------------------
#  IN: 1 line to monitor

sub _monitor { print $output $_[0] } #_monitor

#---------------------------------------------------------------------------
# OUT: 1 a random word

sub _word {

# Initialize by taking a random letter a-z
# For a random number of times
#  Add a random character from the whole range
# Finally, add a random letter from a-z again
# Return the result

    my $word = $letter[int(rand(26))];
    foreach (1..int(rand(5))) {
        $word .= $letter[int(rand(@letter))];
    }
    $word .= $letter[int(rand(26))];
    $word;
} #_word

#---------------------------------------------------------------------------

__END__

=head1 NAME

Thread::Pool::Resolve - resolve logs asynchronously

=head1 SYNOPSIS

 use Thread::Pool::Resolve;
 Thread::Pool::Resolve->timeout( 60 ); # only for default resolver
 
 $resolve = Thread::Pool::Resolve->new( {field => setting}, parameters );

 $resolve->read( | file | handle | socket | belt );
 $resolve->line( single_log_line );

=head1 DESCRIPTION

                 *** A note of CAUTION ***

 This module only functions on Perl versions 5.8.0 and later.
 And then only when threads are enabled with -Dusethreads.
 It is of no use with any version of Perl before 5.8.0 or
 without threads enabled.

                 *************************

The Thread::Pool::Resolve module allows you to resolve log-files (any source
of data in which the first characters on a line constitute an IP number) in
an asynchronous manner using threads.  Because threads are used to resolve
IP numbers in parallel, the wallclock time of the resolving process can be
significantly reduced.

Because the Thread::Pool::Resolve module is very flexible in its input and
output media, you can e.g. resolve log lines in real-time and store the
result in a data-base (rather than in a text-file).

If you are more interested in as low a CPU usage as possible, you should
probably just create a simple filter using the C<gethostbyaddr> function.

=head1 CLASS METHODS

This method can be called without an instantiated Thread::Pool::Resolve object.

=head2 new

 $resolve = Thread::Pool::Resolve->new(
  {
   open => sub { print "open output handle with @_\n",   # default: STDOUT
   close => sub { print "close output handle with @_\n", # default: none

   pre => sub { print "start monitoring yourself\n" },   # alternative
   monitor => sub { print "monitor yourself\n" },        # for
   post => sub { print "stop monitoring yourself\n" },   # open/close

   status => \%status,                    # monitor progress resolver
   checkpoint => sub { print "checkpointing\n" },
   frequency => 1000,

   resolved => \%resolved,                # default: empty hash
   resolver => \&myownresolver,           # default: gethostbyaddr()

   autoshutdown => 1, # default: 1 = yes

   workers => 10,     # default: 10
   maxjobs => 50,     # default: 5 * workers
   minjobs => 5,      # default: maxjobs / 2
  },

  qw(file layers)     # parameters to "open", "close", "pre" and "post"

 );

The "new" method returns an instantiated Thread::Pool::Resolve object.

The first input parameter is a reference to a hash with fields that adapt
settings for the resolving process.

The other input parameters are optional.  If specified, they are passed to the
the "open" or the "pre" routine when resolving is started.

There are basically two modes of operation: one mode in which the resolved log
is simply written to a file (specified with the "open" field) and a mode in
which you have complete control over what happens to each resolved log line
(specified with the "monitor" field).

=over 2

=item writing result to a file

The simplest way is to specify an "open" subroutine that returns the file
handle to which the output should be written.  This could be as simple as:

 open => sub { open( my $out,'>',$_[0] ) or die "$_[0]: $!"; $out },

The extra parameters that you specify with the L<new> method, are passed to
the "open" routine.  So if you pass the filename, it can be used by the "open"
routine to open the desired file for writing.

The reason it is not possible to specify a handle directly, is that the
file will only be opened in the monitoring thread.  This prevents any locking
or mutex problems at the file system level.  It also allows you to use PerlIO
layers that (as of yet) cannot be used in multiple threads at the same time,
such as the ":gzip" (PerlIO::gzip) IO layer (available from CPAN).  And it
allows you to use DBI::DBD drivers that are (as of yet) not threadsafe yet.

If you don't specify an "open" routine, and don't have a "monitor" routine
specified either, then a default "open" routine will be assumed that will
assume the first parameter to be the filename and the second parameter to
be any PerlIO layers to apply.  If no parameters are present, output will
be sent to STDOUT.

=item monitoring resolved lines yourself

If you're interested in any monitoring of the resolved log lines (e.g. if
you want to filter out certain domain names), you can specify a "monitor"
routine that will be called for each resolved log line.  You can set up
any file handles with the "pre" routine and perform any shutdown operations
with a "post" routine.

=back

These are all the possible fields that you may specify with the L<new> method.

=over 2

=item optimize

 optimize => 'cpu', # default: 'memory'

The "optimize" field specifies which implementation of the belt will be
selected.  Currently there are two choices: 'cpu' and 'memory'.  By default,
the "memory" optimization will be selected if no specific optmization is
specified.

You can call the class method L<optimize> to change the default optimization.

=item open

 open => 'open_output_file',		# name or code reference

The "open" field specifies the subroutine that determines to which file the
resolved log lines should be written.  It must be specified as either the
name of a subroutine or as a reference to a (anonymous) subroutine.

The "open" routine is expected to return a file handle to which the resolved
log files should be written.  Any extra parameters that are passed to L<new>,
will be passed through to this subroutine.  

If no "open" field is specified, and no "monitor" field is specified either,
then a default "open" routine will be assumed that interpretes the extra
parameters passed to L<new> as:
 
 1 name of file to write resolved log lines to (default: STDOUT)
 2 PerlIO layers to apply (default: none)

So, if you would like to write the log file to "resolved.gz" and use the
:gzip PerlIO layer (available from CPAN), you would specify this as:

 $resolve = Thread::Pool::Resolve->new( {},'resolved.gz',':gzip' );

Please note the empty hash reference as the first parameter in this case.

=item close

 close => 'close_output_file',		# name or code reference

The "close" field specifies the subroutine that will be called when an
"open" routine was specifically specified and the monitoring thread is
shutting down.  It must be specified as either the name of a subroutine
or as a reference to a (anonymous) subroutine.

The "close" routine allows you to do any B<extra> cleanup operations.  Please
note however that the file to which the resolved log lines were written,
is closed automatically, so you don't need to specify a "close" routine
for that.

Any extra parameters that are passed to L<new>, will be passed through to
the "close" subroutine.

=item pre

 pre => 'prepare_monitoring',		# name or code reference

The "pre" field specifies the subroutine to be executed once before the first
time the "monitor" routine is called.  It must be specified as either the name
of a subroutine or as a reference to a (anonymous) subroutine.

The specified subroutine should expect the following parameters to be passed:

 1..N  any additional parameters that were passed with the call to L<new>.

The "pre" routine executes in the same thread as the "monitor" routine.

=item monitor

 monitor => 'in_order_read',		# name or code reference

The "monitor" field specifies the subroutine to be executed for monitoring the
results of the resolving process.  If specified, the "monitor" routine is
called once for each resolved log line in the order in which the (unresolved)
lines occur in the original log.

The specified subroutine should expect the following parameters to be passed:

 1 resolved log line

Whatever the "monitor" routine does with the resolved log line, is up to the
developer.  Normally it would write the line into a file or an external
database.

=item post

 post => 'cleanup_after_monitoring',	# name or code reference

The "post" field specifies the subroutine to be executed when the
Thread::Pool::Resolve object is shutdown specifically or implicitely when
the object is destroyed.  It must be specified as either the name of a
subroutine or as a reference to a (anonymous) subroutine.

The specified subroutine should expect the following parameters to be passed:

 1..N  any additional parameters that were passed with the call to L<new>.

The "post" routine executes in the same thread as the "monitor" routine.

=item status

 status => \%status,

The "status" field specifies a reference to a B<shared> hash that will be
filled with the status messages of the resolving process.  A one line status
message will be set by the thread doing the resolving process, keyed to the
numerical thread id (tid) of the process.

No status will be set if no hash reference is specified (which is the
default).

=item checkpoint

 checkpoint => 'checkpointing',	         # name or code reference

The "checkpoint" field specifies the subroutine to be executed everytime a
checkpoint should be made by the monitoring routine (e.g. for saving or
updating status).  It must be specified as either the name of a subroutine
or as a reference to a (anonymous) subroutine.

It only makes sense to specify a checkpoint routine if there is also a
monitoring routine specified.  No checkpointing will occur by default if a
monitoring routine B<is> specified.  The frequency of checkpointing can
be specified with the "frequency" field.

The specified subroutine should not expect any parameters to be passed.  Any
values returned by the checkpointing routine, will be lost.

=item frequency

 frequency => 100,                             # default = 1000

The "frequency" field specifies the number of jobs that should have been
monitored before the "checkpoint" routine is called.  If a checkpoint routine
is specified but no frequency field is specified, then a frequency of B<1000>
will be assumed.

This field has no meaning if no checkpoint routine is specified with the
"checkpoint" field.  The default frequency can be changed with the frequency
method, which is inherited from Thread::Pool.

=item resolved

 resolved => \%resolved,

The "resolved" field specifies a reference to a B<shared> hash that contains
domain names keyed to IP numbers.  An empty shared hash will be used if the
"resolved" field is not specified.

The "resolved" hash contains the IP numbers as the keys and the domain names
as the associated values.  An IP number should still exist in the hash if the
IP number could not be resolved: its value could be either the undefined
value, the empty string or the IP number.

Use the L<resolved> object method to obtain a reference to the resolved
hash after the resolving process is completed (after a shutdown).  You can
then save the resolved hash (e.g. with the L<Storable> module) so that you
can later use these result for future resolving of other log files.

=item resolver

 resolver => \&resolver,		# name or code reference

The "resolver" field specifies the subroutine that should be called to
resolve an IP number.  A special internal resolver subroutine (based on
calling C<gethostbyaddr>) will be assumed if the "resolver" field is not
specified.

The "resolver" subroutine should expect the IP number (as a string) as its
input parameter.  It is expected to return the domain name associated with
the IP number, or the undefined value or empty string if resolving failed.

You can call the L<resolver> method to obtain the code reference of the
"resolver" subroutine actually used.

=item autoshutdown

 autoshutdown => 0, # default: 1

The "autoshutdown" field specified whether the shutdown method should be
called when the object is destroyed.  By default, this flag is set to 1
indicating that the shutdown method should be called when the object is
being destroyed.  Setting the flag to a false value, will cause the shutdown
method B<not> to be called, causing potential loss of data and error messages
when threads are not finished when the program exits.

The setting of the flag can be later changed by calling the inherited
autoshutdown method.

=item workers

 workers => 25, # default: 10

The "workers" field specifies the number of worker threads that should be
created when the pool is created.  If no "workers" field is specified, then
B<ten> worker threads will be created.  The inherited workers method can be
used to change the number of worker threads later. 

=item maxjobs

 maxjobs => 125, # default: 5 * workers

The "maxjobs" field specifies the B<maximum> number of lines that can be
waiting to be handled.  If a new log line would exceed this amount,
submission of log lines will be halted until the number of lines waiting
to be handled has become at least as low as the amount specified with the
"minjobs" field.

If the "maxjobs" field is not specified, an amount of 5 * the number of
worker threads will be assumed.  If you do not want to have any throttling,
you can specify the value "undef" for the field.  But beware!  If you do not
have throttling active, you may wind up using excessive amounts of memory
used for storing all of the log lines in memory before they are being handled.

The inherited maxjobs method can be called to change the throttling settings
during the lifetime of the object.

=item minjobs

 minjobs => 10, # default: maxjobs / 2

The "minjobs" field specified the B<minimum> number of log lines that can be
waiting to be handled before submission is allowed again (throttling).

If throttling is active and the "minjobs" field is not specified, then
half of the "maxjobs" value will be assumed.

The inherited minjobs method can be called to change the throttling settings
during the lifetime of the object.

=back

=head2 optimize

 Thread::Pool::Resolve->optimize( 'cpu' );

 $optimize = Thread::Pool::Resolve->optimize;

The "optimize" class method allows you to specify the default optimization
type that will be used if no "optimize" field has been explicitely specified
with a call to L<new>.  It returns the current default type of optimization.

Currently two types of optimization can be selected:

=over 2

=item memory

Attempt to use as little memory as possible.  Currently, this is achieved by
starting a seperate thread which hosts an unshared array.  This uses the
"Thread::Conveyor::Thread" sub-class.

=item cpu

Attempt to use as little CPU as possible.  Currently, this is achieved by
using a shared array (using the "Thread::Conveyor::Array" sub-class),
encapsulated in a hash reference if throttling is activated (then also using
the "Thread::Conveyor::Throttled" sub-class).

=back

=head2 timeout

 Thread::Pool::Resolve->timeout( 120 ); # default: 60

 Thread::Pool::Resolve->timeout( 0 );   # de-activate timeout checks

 $timeout = Thread::Pool::Resolve;

The "timeout" class method returns the current timout setting (in seconds)
that will be used by the default L<resolver>.  It can also be used to change
the timeout setting used by the default resolver.  A value of B<0> can be
used to disable timeout checking.

The timeout feature makes use of alarm(), which may cause problems on some
operating system and/or in conjunction with sleep().

=head1 OBJECT METHODS

These methods can be called on instantiated Thread::Pool::Resolve objects.

=head2 read

 $resolve->read;
 $resolve->read( 'file' );
 $resolve->read( 'file.gz',':gzip' );
 $resolve->read( $known );
 $resolve->read( $strange,'method' );

The "read" method specifies the source from which log lines will be read.
The STDIN handle will be assumed if no parameters are specified.

The first input parameter can either be a filename or a reference (to an
object).  If it is a file name, it is the name of the log file that will
be read to resolve the IP numbers.  In that case, the second input parameter
may be used to specify any PerlIO layers that should be applied to the
reading process.

If the first input parameter parameter is a reference (to an object), it is
assumed to have a method for obtaining lines one-by-one.  If the reference
or the object is recognized, the appropriate method will be automatically
selected.  The name of the method to be used B<must> be specified as the
second input parameter if the object is B<not> recognized.

Currently the following objects and reference types are recognized:

 objects             | references
 ================================
 IO::File            | GLOB
 IO::Handle          | SCALAR
 IO::Socket          |
 Thread::Conveyor    |
 Thread::Queue       |

Other object types and references may be added in the future.

The "read" method returns the object itself, which maybe handy for one-liners.

=head2 line

 $resolve->line( "1.2.3.4 accessed this" );

The "line" method allows you to submit a single line for resolving.  It is
intended to be used in real-time logging situations, specifically from
multiple threads.  Use the L<lines> method to submit more than one log line
at a time.  Use the L<read> method to submit all lines from a file or an
object.

=head2 lines

 $resolve->lines( @logline );

The "lines" method allows you to submit more than one line at a time for
resolving.  Use the L<line> method if you only want to submit a single
line for resolving.  Use the L<read> method to submit all lines from a
file or an object.

The "lines" method returns the object itself, which maybe handy for one-liners.

=head2 resolved

 $resolved = $resolve->resolved;

The "resolved" method returns a reference to the shared hash that contains
the IP number to domain name translations.  It either is the same as what
was specified with the L<new> method and the "resolved" field, or it is a
reference to a newly created shared hash.  It can be used to provide
persistence to the resolved hash, e.g. with the L<Storable> module.  Later
incarnations can then specify the "resolved" field to continue resolving
using the IP number to domain name translation information from previous
sessions.

=head2 status

 $status = $resolve->status;

The "status" method returns a reference to the shared hash that contains
the status information.  It is the same as what was specified with the
L<new> method and the "status" field.  It can be used to access the status
information mechanism in a custom monitoring routine.

=head1 INSIDE JOB METHODS

These methods can be called inside the "open", "close", "pre", "post" and
"monitor" routines.

=head2 resolved

 $resolved = Thread::Pool::Resolve->resolved;

The "resolved" method returns a reference to the shared hash that contains
the IP number to domain name translations.  It either is the same as what
was specified with the L<new> method and the "resolved" field, or it is a
reference to a newly created shared hash.

=head2 resolver

 $resolver = Thread::Pool::Resolve->resolver;

The "resolver" method returns a code reference to the routine that is
performing the actual resolving of IP numbers to domain name.  It either
is the same as what was specified with the L<new> method and the "resolver"
field, or it is a reference to the default resolver routine provided by
this module itself.

=head2 status

 $status = Thread::Pool::Resolve->status;

The "status" method returns a reference to the hash that is used to keep
status.  It is the same as what was specified with the L<new> method and
the "status" field.

=head1 INHERITED METHODS

The following methods (in alphabetical order) are inherited from
L<Thread::Pool>.  Please check the documentation there for more information
about these methods.

 add            add one or more worker threads
 autoshutdown   set behaviour when object is destroyed
 frequency      (set default) checkpointing frequency
 maxjobs        set maximum number of lines waiting to be handled
 minjobs        set minimum number of lines waiting to be handled
 remove         remove one or more worker threads
 shutdown       shutdown the resolving process
 todo           number of IP numbers left to resolve (approximate)
 workers        set number of worker threads

=head1 DEBUG METHODS

The following methods are for debugging purposes only.

=head2 rand_domain

 $domain = Thread::Pool::Resolve->rand_domain;

The "rand_domain" class method returns a random domain name.  It is a name
that roughly conforms to what is considered to be a valid domain name.  It
can be used in a L<resolver> routine if you want to quickly test your
log resolving application.

=head2 rand_ip

 $ip = Thread::Pool::Resolve->rand_ip;

The "rand_ip" class method returns a random IP number.  It is an IP number
that roughly conforms to what is considered to be a valid IP number
(basically a sequence of 4 numbers between 0 and 255, concatenated with
periods).  It can be used to create test log files (as is done in the
test-suite of this module).

=head1 REQUIRED MODULES

 load (any)
 Thread::Pool (0.29)

=head1 BUGS

Release 5.8.0 of Perl has a bug related to the usage of signals with threads.
Basically, signals within threads are only handled correctly if the main
thread has "activated" the signal handler before the thread that is to
receive a signal, is started.

Since the L<timeout> function of the default L<resolver> uses the alarm()
function (which uses signals) to time out any DNS request that just takes
too long, the B<ALRM> signal must be assigned before any threads that use
signals, are started.  The L<new> class method tries to be smart about
this and attempts to fix this.  However, it cannot fix this if it's not
called from the main thread.  So, in that case, it will die with the message:

 Cannot reliably use signals in threads

And when it B<is> able to fix this, it will output a warning:

 Priming $SIG{ALRM} to get signals to work inside threads

If you are calling method L<new> from a thread other than the main thread,
or you do not want to be alarmed (pun intended) by the warning, then you
B<must> assign the B<ALRM> signal in your main thread yourself.  This
can be as simple as:

 $SIG{ALRM} = sub {}; # workaround for 5.8.0 thread signal breakage

It can be placed anywhere in your main program, but B<before> you call method
L<new>.

=head1 EXAMPLES

There are four examples right now.  Of course, you can also check out the
test-suite for more examples of the usage of Thread::Pool::Resolve.

=head2 simple log resolving filter

Creating a log resolving filter is really simple:

 # Make sure we have the right modules loaded
 # Start resolving from STDIN and write to STDOUT

 use Thread::Pool::Resolve;
 Thread::Pool::Resolve->new->read;

That's all there is to it.  By default, resolving writes the result to STDOUT.
And the "read" method reads from STDIN by default.

=head2 simple log resolving program

The following version allows the input file to be specified as the first
parameter to the script, and the output file as the second parameter to
the script.  The first input parameter defaults to STDIN, the second to
STDOUT.

 # Make sure we have the right modules loaded
 # Start resolving from given input file and write to given output file

 use Thread::Pool::Resolve;
 Thread::Pool::Resolve->new( {},$ARGV[1] )->read( $ARGV[0] );

Again, pretty simple, eh?  Note the empty hash reference that needs to be
specified now in the call to L<new>.

=head2 resolve zipped log files

 # Make sure we have PerlIO::gzip (available from CPAN)
 # Make sure we can resolve

 use PerlIO::gzip;
 use Thread::Pool::Resolve;

 # Create a resolving object, writing gzipped to 'resolved.gz'
 # Read the unresolved file, gunzip on the fly and wait until all done

 my $resolve = Thread::Pool::Resolve->new( {},'resolved.gz',':gzip' );
 $resolve->read( 'unresolved.gz',':gzip' )->shutdown;

=head2 use existing IP number resolving information

 # Make sure we can resolve
 # Make sure we can have a persistent hash

 use Thread::Pool::Resolve;
 use Storable qw(store retrieve);

 # Create a resolver that starts with the information of the database

 my $resolve = Thread::Pool::Resolve->new(
  {
   resolved => retrieve( 'database.storable' )
  },
  'resolved'
 );

 # Read the log file from STDIN and wait until all done
 # Store the resulting database for later usage

 $resolve->read->shutdown;
 store( $resolve->resolved,'database.storable' );

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Maintained by LNATION, <email@lnation.org>

Please report bugs to <email@lnation.org>.

=head1 COPYRIGHT

Copyright (c) 2002-2003 Elizabeth Mattijsen <liz@dijkmat.nl>. 2025 LNATION <email@lnation.org>
All rights reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Thread::Pool>.

=cut
