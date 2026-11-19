use strict; use warnings; use feature qw(say state signatures);
# vi:set ai expandtab ts=4:

package Thread::DependentJobs;

our @ISA       = qw/Exporter/;
our @EXPORT    = ();
our @EXPORT_OK = qw/my_jobid/;

{ no strict 'refs'; ${__PACKAGE__."::VER"."SION"} //= 997.999; }
our $VERSION = '1.3'; # VERSION from Dist::Zilla::Plugin::OurPkgVersion
our $DATE = '2026-11-18'; # DATE from Dist::Zilla::Plugin::OurDate

use threads;
use threads::shared;
use Thread::Queue;
use List::Util qw/all any/;
use List::MoreUtils qw/firstidx/;
use Scalar::Util 1.10 qw(looks_like_number blessed);
use Carp;
use Data::Dumper::Interp qw/visnew vis visq viso avis hvis
                            dvis dviso ivis visr addrvis u qsh qshlist/;
use Spreadsheet::Edit::Log qw/:btw oops get_logdest/;
use File::Basename qw/basename/;
use Guard qw/scope_guard/;
use overload ();

use constant SEMA_PKG => __PACKAGE__."::sema";

# Remember Job Schedulers for cleanup in the main thread's END{}
# ('threads' doc warns thread ops within a thread-specific END
# may deadlock; I hope this is not a problem for main thread's END)
our %schedulers :shared;  # uniqeuid => { ... }
our $sseq :shared = 0;

$SIG{SEGV} = sub($sig,@) { btwbt "Caught $sig"; _exit(9); };
$SIG{TERM}  =
$SIG{QUIT}  =
$SIG{INT}  = sub($sig,@) { btwbt "Interrupted by SIG$sig"; };

# global Configure options
my $allserial :shared = 0;
our $debug = 0;  # not shared for speed; set in new() before creating threads

our $warnlock : shared;
sub _install_warn_hook() {
  my $origwarn = $SIG{__WARN__};
  $SIG{__WARN__} = sub {
    lock $warnlock;
    ($origwarn || \&CORE::warn)->(@_);
  };
}

our $curr_jobid = undef; # not shared, but per-thread
our $curr_job;           # not shared, but per-thread

sub _is_stringish($thing) {
  my $class;
  defined($thing) && (
    (ref($thing) eq "")
    ||
    (defined($class = blessed($thing)) && overload::Method($class,'""'))
  )
}

my $global_initialized;
sub _global_init() {
    _check_on_main_thread();

    lock %schedulers;

    if (! $global_initialized) {
      _install_warn_hook();
      $global_initialized = 1;
    }
}
sub _check_on_main_thread() {
    confess "Should only be called by the main thread\n"
      unless threads->tid() == 0;
}

sub fmt_jobid($self, $jobid, $longform=1) { # %$self must be locked
  oops unless defined($jobid);
  my $finished = "";
  my $job = $self->{JOBS}->{$jobid};
  if (! $job) {
    $job = $self->{FINISHED_JOBS}->{$jobid} // oops;
    $finished = " (finished)";
  }
  my ($subname,$args,$inputs,$outputs) = @$job{qw/subname args inputs outputs/};
  oops dvis '$jobid $job $self->{JOBS} $self->{FINISHED_JOBS}' unless defined $subname;
  $longform
    ? "$jobid: $subname(args=>".vis($args).",inputs=>".vis($inputs).",outputs=>".vis($outputs).")$finished"
    : "$jobid: $subname(...)$finished"
}

sub _get_Semaphore_id($s) {
  # Return the shared-object id (breaking encapsulation of Thread::Semaphore)
  is_shared($s) // oops dvis '$s';
}
sub _get_Semaphore_val($s) {
  # Breaking encapsulation of Thread::Semaphore.  Just for debug messages!
  $$s
}

sub _fmt_sema($sema) {
oops unless defined $sema;
  my ($s, $down_count, $up_count) = @$sema;
  my $id = _get_Semaphore_id($s);
  my $msg;
  if ($down_count == $up_count) {
    if ($down_count == 1) {
      $msg = "Semaphore<$id>";
    } else {
      $msg = "[Semaphore<$id>, $down_count]";
    }
  } else {
    $msg = "[Semaphore<$id>, $down_count, $up_count]";
  }
  $msg." (current:"._get_Semaphore_val($s).")";
}

# Create a token info hash, if it does not already exist,
# at $self->{TOKENS}->{tokname} .
#   Throws an error if the tokname is invalid.
# If jobid_if_output is given, sets or updates {PRODUCER_JOBID}
#   if it is not already set (or the token is new), but
# Throws an error the token already exists with PRODUCER_JOBID set.
# Returns a ref to the tokinfo hash
sub _get_tokinfo($self, $tokname, $jobid_if_output=undef) {
  # %$self must be locked!
  if (! _is_stringish($tokname)) {
    confess "Token '",u($tokname),"' is not a string";
  }
  my $tokinfo = $self->{TOKENS}->{$tokname};
  if ($tokinfo) {
    if ($jobid_if_output && (my $producer=$tokinfo->{PRODUCER_JOBID})) {
      confess "Attempt to re-use output token '$tokname'\n",
              "(it is already an output for job $producer)\n";
    }
  } else {
    $tokinfo = $self->{TOKENS}->{$tokname} = &share({});
    $tokinfo->{WAITING} = &share([]);
  }
  $tokinfo->{PRODUCER_JOBID} = $jobid_if_output if $jobid_if_output;
  return $tokinfo;
}

sub Configure :prototype($@) ($class, @args) {
    oops unless eval{ $class->isa(__PACKAGE__) };
    my %opts = (@args==1 ? (%{$args[0]}) : @args);
    _check_on_main_thread();
    foreach (keys %opts) {
      # Previously we used a common thread pool for all Job Schedulers
      # and so NUMTHREADS was accepted here.  No longer.
      if (/^DEBUG$/)  { $debug = delete $opts{$_}; }
      elsif (/^ALLSERIAL$/)  { $allserial = delete $opts{$_}; }
      else  { croak "Invalid Thread::DependentJob->Configure option '${_}'\n"; }
    }
    die if %opts;
    _global_init();
}

sub new($class, %options) {
    $class = ref($class) || $class;
    if (exists $options{DEBUG}) {
      $debug = delete $options{DEBUG}; # global, affects all Job Schedulers
    }
    _global_init();

    # c.f. https://api.metacpan.org/source/JDHEDDEN/threads-shared-1.59/examples/class.pl
    share(my %hash);
    $hash{TIDS}      = &share([]);
    $hash{JOBS}      = &share({}); # incomplete jobs
    $hash{FINISHED_JOBS} = &share({}); # jobid => { JOBS hash plus RESULT }
    $hash{QUEUED}    = &share({}); # jobid => 1
    $hash{TOKENS}    = &share({}); # all tokens we ever heard of:
              # tokname => { PRODUCER_JOBID => ...
              #              POISONED => boolean
              #              WAITING => [jobids waiting for it]
              #            }
    $hash{QUEUE}     = shared_clone( Thread::Queue->new() );
    $hash{JSEQ }     = 0;

    my $numthreads = delete $options{NUMTHREADS};
    if (! defined $numthreads) {
      my $numcpus = $ENV{NUMBER_OF_PROCESSORS}
                    || (`grep "processor\t:" /proc/cpuinfo  | wc -l`)
                    || 1;
      chomp $numcpus;
      $numthreads = $numcpus + 1;
    }
    croak "Unknown ",__PACKAGE__,"->new option '$_'" for keys %options;

    my $obj = bless(\%hash, $class);

    lock %schedulers;
    $obj->{SNUM} = $sseq++;
    my $jobschid = "js".$obj->{SNUM};
    oops if exists $schedulers{$jobschid};
    $schedulers{$jobschid} = $obj;
    $obj->{WSID} = $jobschid;

    while (@{$obj->{TIDS}} < $numthreads) { # zero is allowed
        my $thr = threads->create({context => 'void'}, \&_thread_main, $jobschid);
        confess "threads->create failed ($!)" unless $thr;
        my $tid = $thr->tid();
        push @{$obj->{TIDS}}, $tid;
    }

    warn ">>> $obj: Created Job Scheduler with ",scalar(@{$obj->{TIDS}})," threads.\n" if $debug;
    return $obj;
}#new

sub get_numthreads($self) { scalar( @{ $self->{TIDS} } ) }

sub _canon_sema($sema) {
  if (blessed($sema) && $sema->isa("Thread::Semaphore")) {
    $sema = [$sema, 1];
  }
  elsif (ref($sema) eq "ARRAY" && (@$sema==2 || @$sema==3)
           && blessed($$sema[0]) && $$sema[0]->isa("Thread::Semaphore")
           && (all{ looks_like_number($_) && int($_)==$_ && $_ >= 0 } @$sema[1..$#$sema])
        ) {
    # already [semaphore,count] or [semaphore,upcount,downcount]
  }
  else {
    confess "Invalid sema ",visnew->vis($sema);
  }
  if (@$sema==2) { push @$sema, $sema->[1] }  # [sem,N] --> [sem,N,N]
  return shared_clone($sema);
}

sub sched($self, %opts) {
    my $mytid = threads->tid();

    share(my %job);

    my $subname = delete($opts{subname}) // croak "'subname' is required";
    $subname = (caller)[0]."::".$subname unless $subname =~ /:/;
    $job{subname} = $subname;

    my $context = delete($opts{context}) // (wantarray ? "list" : "scalar");
    croak "context value must be 'list', 'scalar' or 'void' (not '$context')\n"
      unless $context =~ /^(?:list|scalar|void)$/;
    $job{context} = $context;

    for my $key (qw/args inputs outputs/) {
      $job{$key} = shared_clone( delete($opts{$key}) // [] );
    }
    $job{semas} = shared_clone( [
                       # sort by mem addr to avoid deadlock
                       sort{ _get_Semaphore_id($a->[0]) <=> _get_Semaphore_id($b->[0]) }
                       map{ _canon_sema($_) }
                       @{ delete($opts{semas}) // [] }
                  ] );

    croak "Unknown option '$_'\n" for (keys %opts);

    my $jobid;
    { lock $self;

      # Canonical jobids are "J<scheduler_number>.<job_number>" but omit the
      # scheduler number on the first (typically only) Job Scheduler instantiation
      my ($snum, $jnum) = ($self->{SNUM}, $self->{JSEQ}++);
      $jobid = "J".($snum==0 ? "" : "${snum}.").$jnum;
      $job{JOBID} = $jobid;
      $self->{JOBS}->{$jobid} = \%job;

      # Register tokens, checking for errors
      foreach my $tokname (@{ $job{inputs} }) {
        my $tokinfo = _get_tokinfo($self, $tokname, undef);
        push @{ $tokinfo->{WAITING} }, $jobid;
      }
      foreach my $tokname (@{ $job{outputs} }) {
        _get_tokinfo($self, $tokname, $jobid);
      }

      btwN \3, "### [$mytid] Scheduling ",$self->fmt_jobid($jobid),"\n" if $debug;

      $self->_enqueue_if_ready([$jobid]);
    }
    threads->yield();

    $jobid;
}#sched

sub _run_queue_directly($self) {
    # ?? do we need to worry about delete() being called concurrently?
    my $q = $self->{QUEUE};
    if ($q->pending) {
      warn "### serial mode, running jobs on main thread\n" if $debug;
      while (defined (my $jobid = $q->dequeue_nb())) {
          $self->_run_workitem($jobid);
      }
    }
}

sub wait($self) {
    confess "Must be called on a Job Scheduler *OBJECT*\n" unless ref($self);
    lock $self;
    my $mytid = threads->tid();
    btwN \3, ">>> [$mytid] Starting wait $self" if $debug;
    while (keys %{ $self->{JOBS} }) {
        if( @{$self->{TIDS}} == 0 ) {
            $self->_run_queue_directly;
            # We can detect deadlock in serial mode!
            if (my @lines = $self->_unfinished_job_info) {
              confess "DEADLOCK?  Some job(s) never ran:\n", @lines;
            }
            last;
        } else {
            if ($debug) {
              my @jobids = keys %{$self->{JOBS}};
              btwbt ">>> [$mytid] wait: cond_wait %{ ",addrvis($self),"} (current jobs: @jobids) ...\n";
            }
            cond_wait %$self;  # cond_broadcast at end of _run_job
            btwbt ">>> [$mytid] back from cond_wait" if $debug;
        }
    }
    $self->_abort_if_jobs_remain;

    # Return hash mapping
    #   jobid => {inputs=>[...], outputs=>[...], result=> scalar} }
    my $result = $self->{FINISHED_JOBS};
    $self->{FINISHED_JOBS} = shared_clone({});

    if (!defined wantarray) {
      # results not being checked -- warn of aborted jobs
      for my $jobid (keys %$result) {
        my $job = $result->{$jobid};
        oops unless $job->{JOBID} eq $jobid;
        if (my $msg = $job->{ABORTMSG}) {
          chomp $msg;
          warn "Jobid $jobid : $msg\n";
        } else {
          oops if $job->{EXCEPTION};
        }
      }
    }
    btwbt ">>> [$mytid] wait returning ${\(visnew->Refaddr(1)->vis($result))}" if $debug;
    return $result
}

sub abort_job($self, $jobid, $msg="") {
    lock $self;
    $msg = ":$msg" if $msg;
    my $job = $self->{JOBS}->{$jobid};
    if (! $job) {
      return 1 if exists $self->{FINISHED_JOBS}->{$jobid};
      confess "abort_job: $jobid is not defined\n";
    }
    if (my $tid = $job->{TID}) {
      btwbt ">>> abort_job: KILLING ",$self->fmt_jobid($jobid,0)," on tid $tid\n" if $debug;
      $job->{ABORTMSG} //= "[killed by abort_job${msg}]";
      threads->object($tid)->kill('SIGTERM');
    } else {
      btwbt ">>> abort_job: CANCELLING ",$self->fmt_jobid($jobid,0)," ...\n" if $debug;
      $job->{ABORTMSG} //= "[cancelled before running by abort_job${msg}]";
      $self->_enqueue_if_ready([$jobid]) unless $self->{QUEUED}->{$jobid};
    }
    # The job still exists; you must call 'wait' to clean it up.
    #
    # If executing, the job was signaled and will stop promptly.
    # If still queued, it will start as soon as a worker thread becomes
    # available and then immediately abort without calling the user's code.
    return 0;
}

sub delete_tokens($self, @toknames_to_delete) {
  lock $self;
  my $my_jobid = my_jobid()//"";
  foreach my $job (values %{$self->{JOBS}}) {
    if ($job->{JOBID} ne $my_jobid) { # ok to delete our own input
      foreach my $tokname (@{$job->{inputs}}) {
        if (any{ $_ eq $tokname } @toknames_to_delete) {
          croak "Can not delete token '$tokname' because it is an input token for unfinished job $job->{JOBID}";
        }
      }
      foreach my $tokname (@{$job->{outputs}}) {
        if (any{ $_ eq $tokname } @toknames_to_delete) {
          croak "Can not delete token '$tokname' because it is an output token for unfinished job $job->{JOBID}";
        }
      }
    }
  }
  for my $tokname (@toknames_to_delete) {
    my $tokinfo = $self->{TOKENS}->{$tokname}
       // croak "'$tokname' is an unknown token name";
    if (! $tokinfo->{PRODUCED}) {
      oops dvis 'BUG: $tokname was never PRODUCED\n$tokinfo';
    }
    for my $dependent (grep{defined} @{ $tokinfo->{WAITING} }) {
      oops dvis 'BUG: $tokname : $dependent is WAITING \n$tokinfo';
    }
    if (exists $tokinfo->{POISONED}) {
      # nothing special to do?
    }
    oops "unimplemented" ### FIXME
  }
}

sub all_jobids($self) {
  lock $self;
  return( keys %{$self->{JOBS}}, keys %{$self->{FINISHED_JOBS}} );
}

# Wait for any remaining jobs to complete, shut down threads, and delete
# internal references to the object
sub delete($self) {
    my $tid = threads->tid();
    btw ">>> [$tid] Starting delete of ${\addrvis($self)} ...\n" if $debug;
    my @worker_tids;
    { lock $self;
      oops "[$tid] Already deleted ($self->{DESTROYED})!" if $self->{DESTROYED};
      $self->{DESTROYED} = "started";
      @worker_tids = @{$self->{TIDS}};
    }
    # Calling wait in void context so it will warn of abnormally-terminated jobs.
    $self->wait(); # wait for jobs to run and finish
    { lock $self;
      for (1..@{$self->{TIDS}}) {
        $self->{QUEUE}->enqueue(undef); # send EOF, one per thread
      }
    }
    foreach my $tid (@worker_tids) {
      my $thr = threads->object($tid);
      oops if $thr->is_detached();
      btw ">>>     joining tid $tid ...\n" if $debug;
      $thr->join();
      btw ">>>     tid $tid has joined\n" if $debug;
    }
    oops dviso '$self' if keys %{$self->{QUEUED}};
    oops dviso '$self' if keys %{$self->{JOBS}};
    oops dviso '$self' if keys %{$self->{FINISHED_JOBS}};
    oops dviso '$self' if $self->{QUEUE}->pending() != 0;
    $self->{DESTROYED} = "finished";
    lock %schedulers;
    delete $schedulers{$self->{WSID}} // oops;
}

sub _has_unfinished_jobs($self) {
    $self->_run_queue_directly if @{$self->{TIDS}} == 0;
    lock $self;
    return scalar %{ $self->{JOBS} }
}
sub _unfinished_job_info($self) {
    # Returns a list of strings, one per waiting job
    $self->_run_queue_directly if @{$self->{TIDS}} == 0;
    my @result;
    lock $self;
    foreach my $jobid (keys %{$self->{JOBS}}) {
      my $job = $self->{JOBS}->{$jobid};
      my @unsatisfied_inputs;
      foreach my $tokname (@{$job->{inputs}}) {
        my $tokinfo = $self->{TOKENS}->{$tokname} // oops;
        if (! $tokinfo->{PRODUCED}) {
          push @unsatisfied_inputs, $tokname;
        }
      }
      if (@unsatisfied_inputs) {
        push @result, $self->fmt_jobid($jobid,0)
                     ." has unsatisfied inputs (never produced): "
                     .join(", ", @unsatisfied_inputs)
                     ."\n";
      }
      elsif ($self->{QUEUED}->{$jobid}) {
        push @result, $self->fmt_jobid($jobid,0)
                     ." is enqueued, waiting for a free thread.\n";
      }
      elsif (my $tid = $job->{TID}) {
        push @result, $self->fmt_jobid($jobid,0)
                     ." is currently executing on tid $tid.\n";
      }
      else {
        confess "[${\(threads->tid)}] bug: bad state for $jobid (no unsatisfied inputs)\n",
                visnew->dviso('$self\n');
      }
    }
    return @result;
}

sub _abort_if_jobs_remain($self) {
    lock $self;
    if (%{ $self->{JOBS} }) {
      my @descrips = $self->_unfinished_job_info();
      oops unless @descrips;  # jobs remain but none are waiting for anything
      # Nevertheless, I think this still implies a bug in Job Scheduler!
      confess "Some job(s) never ran:\n", @descrips;
    }
}

END{
    local($., $@, $!, $^E, $?);
    btw ">>> Starting Job Scheduler END block (PHASE ${^GLOBAL_PHASE})\n" if $debug;

    _check_on_main_thread();

    # Circular or cross-thread references to Job Scheduler objects would often
    # prevent automatic cleanup via DESTROY, and weak references don't work
    # in shared data.  So instead we keep a global list of all Job Scheduler
    # objects and clean up here.

    for(;;) {
        lock %schedulers;
        if ((my @wsids = keys %schedulers)) {
          for my $jobschid (@wsids) {
            my $jobsch = $schedulers{$jobschid};
            $jobsch->delete();
          }
        } else {
          last;
        }
        threads->yield;
        # Repeat in case a job created a new Job Scheduler (really allowed?)
    }

    btw ">>> Leaving Job Scheduler END block\n" if $debug;
}#END

#INTERNAL
sub _enqueue_if_ready ($self, $jobids) { # Job Scheduler must be locked
    my $tid = threads->tid();

    my %jobid2ready;  # 0 if still waiting, 1 if ready to start
   JOB:
    foreach my $jobid (@$jobids) {
        # @$jobids may include the same value several times
        next if exists $jobid2ready{$jobid};
        $jobid2ready{$jobid} = 0;

        my $job = $self->{JOBS}->{$jobid} // oops;

        my @unavail_semas;
        my @unavail_inputs;
        my @got_semas;
        CHECK: {
          last CHECK if $job->{ABORTMSG};
          foreach my $tokname (@{$job->{inputs}}) {
            my $tokinfo = $self->{TOKENS}->{$tokname} // oops;
            if (exists $tokinfo->{POISONED}) {
              $job->{ABORTMSG} = "[cancelled: need '$tokname' from aborted job $tokinfo->{PRODUCER_JOBID}]";
              btw "Start ${jobid}: input token '$tokname' was poisoned\n" if $debug;
              last;
            }
            elsif ($tokinfo->{PRODUCED}) {
              btw "Start ${jobid}: input '$tokname' is ready\n" if $debug;
            }
            else {
              push @unavail_inputs, $tokname;
              last CHECK unless $debug; # check all if tracing
              btw "Start ${jobid}: input '$tokname' is has not yet been produced\n" if $debug;
            }
          }
          foreach my $sema (@{$job->{semas}}) {
            my ($s, $down_count, $up_count) = @$sema;
            next if $down_count == 0;
            if ($s->down_nb($down_count)) {
              push @got_semas, $sema;
              btw "Start ${jobid}: \"downed\" ", _fmt_sema($sema),"\n" if $debug;
            } else {
              push @unavail_semas, $sema;
              btw "Start ${jobid}: COULD NOT \"down\" ", _fmt_sema($sema),"\n" if $debug;
              last CHECK unless $debug; # check all if tracing
            }
          }
          # semas will be "up"d in _wrapup_job
        }
        if (@unavail_inputs or @unavail_semas or $job->{ABORTMSG}) {
          for my $sema (@got_semas) {
            my ($s, $down_count) = @$sema;
            $s->up($down_count); # un-do
            btw "Start ${jobid}: \"un-downed\" (due to unready condition) ", _fmt_sema($sema),"\n" if $debug;
          }
          if ($job->{ABORTMSG}) {
            $self->_wrapup_job($job, 0);
            next JOB;
          }
          if ($debug) {
            foreach (@unavail_semas) {
              warn "$jobid is waiting for ", _fmt_sema($_);
            }
            foreach my $tokname (@unavail_inputs) {
              warn "$jobid is waiting for input '$tokname'\n";
            }
          }
          next JOB
           if (@unavail_semas or @unavail_inputs);
           # Aborted jobs are queued and fake-executed...

        }

        btwbt "### [$tid] Enqueuing ",$self->fmt_jobid($jobid,0),"\n" if $debug;

        oops if $self->{QUEUED}->{$jobid};
        $self->{QUEUED}->{$jobid} = 1;

        # Zap (set to undef) the entry in token WAITING lists for this job
        # (faster than squishing, and shared arrays don't support splice())
        foreach my $tokname (@{$job->{inputs}}) {
          my $tokinfo = $self->{TOKENS}->{$tokname};
          my $ix = firstidx{ defined($_) && $_ eq $jobid } @{ $tokinfo->{WAITING} };
          oops if $ix < 0;
          $tokinfo->{WAITING}->[$ix] = undef;
        }

        my $q = $self->{QUEUE};
        $q->enqueue($jobid);
    }
}#_enqueue_if_ready

#INTERNAL
sub _set_aborted_job_result($job) {
    oops if exists $job->{RESULT};
    my $context = $job->{context} // oops;
    $job->{RESULT} = shared_clone( $context eq "list" ? [] : undef )
      unless $context eq "void";
}

# Call user's code (unless ABORTMSG is set) with a signal handler, etc.
# job->{TID} is set around the call and removed before returning.
sub _call_usersub($self, $tid, $job) {
    local $SIG{__WARN__} = $SIG{__WARN__};
    local $SIG{__DIE__} = $SIG{__DIE__};
    # localize these to simulate thread effects in SERIAL mode
    local $curr_jobid = $job->{JOBID} // oops;
    local $curr_job = $job;
    $@ = "";

    scope_guard {
      lock $self;
      delete $job->{TID};
    };

    local $SIG{'TERM'} = sub ($sig,@) {
      lock $self;
      $job->{KILLED} = 1;
      die "$curr_jobid aborted (caught SIG${sig})\n";
    };

    my $subname = $job->{subname} // oops viso($job);
    { lock $self;
      oops if $job->{KILLED};
      oops if exists $job->{TID};
      oops dviso('$self') unless delete $self->{QUEUED}->{$curr_jobid};
      return
        if $job->{ABORTMSG};
      $job->{TID} = $tid;
    }

    # user's sub is called in whatever context we are called in
    no strict 'refs';
    &$subname(js => $self,
              args => $job->{args},
              inputs => $job->{inputs},
              outputs => $job->{outputs},
             );
}

sub _run_job($self, $jobid) {
    my $tid = threads->tid();

    my ($job, $context);
    { lock $self;
      $job = $self->{JOBS}->{$jobid} // oops;
      $context = $job->{context};
      btw "[$tid] EXECUTING ",$self->fmt_jobid($jobid,0),"\n" if $debug;
      confess "bug" if defined $curr_job;
    }

    # _call_usersub returns immediately if ABORTMSG is set.
    my $result;
    if ($context eq "void") {
      eval{ $self->_call_usersub($tid, $job); };
      $result = "(nothing:void context)";
    }
    elsif ($context eq "scalar") {
      $result = eval{ $self->_call_usersub($tid, $job); };
    }
    elsif ($context eq "list") {
      $result = [ eval{ $self->_call_usersub($tid, $job); } ];
    }
    else { oops };

    lock $self;
    my $abortmsg = $job->{ABORTMSG};
    unless ($abortmsg) {
      $abortmsg = "[killed]" if $job->{KILLED};
      if (my $ex = $@) {
        $job->{EXCEPTION} = shared_clone($ex);
        if (ref($ex)) {
          $abortmsg //= "[die called with object or other non-scalar]";
        } else {
          chomp $ex;
          $abortmsg //= "[died: $ex]";
        }
      }
      if ($debug && !$abortmsg) {
        btw "[$tid] $jobid ",$job->{subname}," returned ",vis($result)," ($context context)\n";
      }
    }#not already aborting

    oops dvis '$job' if exists $job->{RESULT};
    if ($abortmsg) {
      btw "### [$tid] $jobid : ABORTMSG:=$abortmsg\n" if $debug;
      $job->{ABORTMSG} = $abortmsg;
      # setting $result to an explanatory string looks nice for debugging,
      # but violates the API which says undef or [] will be returned for
      # aborted or cancelled jobs.
      #$result = $abortmsg;
      _set_aborted_job_result($job);
    } else {
      $job->{RESULT} = shared_clone($result) unless $context eq "void";
    }
    $self->_wrapup_job($job, 1);

    if ($debug) {
      my @jobids = keys %{$self->{JOBS}};
      btw "### [$tid] $jobid cond_broadcast ",addrvis($self);
    }
    cond_broadcast %$self;
}#_run_job_

sub _wrapup_job($self, $job, $up_semas) {
    # $self must be locked
    my $jobid = $job->{JOBID};
    my $abortmsg = $job->{ABORTMSG};

    my @dependent_jobids; # dups ok

    foreach my $tokname (@{ $job->{outputs} }) {
      my $tokinfo = $self->{TOKENS}->{$tokname} // oops;
      oops dvis '$tokinfo' unless $tokinfo->{PRODUCER_JOBID} eq $jobid;
      oops if exists $tokinfo->{PRODUCED};
      $tokinfo->{PRODUCED} = 1;
      push @dependent_jobids, grep{defined} @{ $tokinfo->{WAITING} };

      if ($abortmsg) {
        $tokinfo->{POISONED} = 1;
        btw "'$tokname' POISONED by ", $self->fmt_jobid($jobid), ":$abortmsg\n" if $debug;
      } else {
        btw "'$tokname' produced by ", $self->fmt_jobid($jobid), "\n" if $debug;
      }
    }
    if ($up_semas) {
      foreach my $sema (@{$job->{semas}}) {
        my ($s, $down_count, $up_count) = @$sema;
        if ($up_count != 0) {
          btw "${jobid} done: \"upping\" ", _fmt_sema($sema),"\n" if $debug;
          $s->up($up_count);
        }
      }
    }
    oops if $self->{FINISHED_JOBS}->{$jobid};
    delete( $self->{JOBS}->{$jobid} );
    $self->{FINISHED_JOBS}->{$jobid} = $job;

    $self->_enqueue_if_ready(\@dependent_jobids);
}#_wrapup_job

sub my_jobid {
  # This actually can be called as a class method, object method,
  # or plain function

  #confess "my_jobid() may only be called from an executing job\n"
  #  unless defined $my_jobid;
  return $curr_jobid;
}
sub _thread_main($jobschid) {
    _install_warn_hook();
    my $jobsch = $schedulers{$jobschid} // oops;
    btwbt "tid ",threads->tid(),ivis ': _thread_main($jobschid) starting...\n' if $debug;
    my $queue = $jobsch->{QUEUE};
    for (;;) {
      btwbt "[",threads->tid(),"] dequeue... (curr. ",
                                  $queue->pending()," items)" if $debug;
      my $jobid = $queue->dequeue();
      last if ! defined $jobid;
      btw "[",threads->tid(),"] dequeued $jobid" if $debug;
      $jobsch->_run_job($jobid);
    }
    btw "[",threads->tid(),"] EOF msg from queue\n" if $debug;
}

1;

__END__

=head1 NAME

Thread::DependentJob - Run interdependent jobs using a pool of worker threads

=head1 SYNOPSIS

  use Thread::DependentJob;
  use Thread::Semaphore ();

  my $jobsch = Thread::DependentJob->new();

  sub do_work_func(...) {
    ... consume whatever is represented by input tokens ...
    ... produce whatever is represented by output tokens ...
    return ...;
  }

  my $sema = Thread::Semaphore->new(3);

  $jobsch->sched(subname => "do_work_func",
                 args    => [arguments for &do_work_func],
                 inputs  => [input tokens],
                 outputs => [output tokens]),
                 semas   => [$sema],
                 context => "list"|"scalar"|"void",
                );
  $jobsch->sched( ... );
  $jobsch->sched( ... );

  my $results = $jobsch->wait();
  foreach my $jobid (keys %$results) {
    print "Job $jobid returned ", $results->{$jobid}, "\n";
  }

=head1 DESCRIPTION

This package allows self-contained "jobs" to be executed concurrently,
initiated using an arbitrary graph of dependencies.

A single pool of "worker" threads is used to execute all jobs.

Each job has sets of input and output "tokens".  A job will not
start until its input tokens are available,
and upon termination (normal or abnormal), it's output tokens are produced.

Jobs may also be regulated by semaphore(s), which are "downed" when the job
starts and "upped" at completion.

NOTE: Jobs may not depend on each other while running, i.e.,
once started a job must complete regardless of what other jobs do.
I<The only way to coordinate jobs is for a common predecessor job
(or the main program) to schedule the jobs with appropriate token dependencies.>

See C<perldoc threads> for limitations of the thread model.
In particular, C<chdir> is global and affects all threads,
and C<system> et. al. always use the main thread's %ENV.

=head2 Aborting Jobs

Jobs may terminate abnormally by calling die() in the usual way.
Jobs should never call exit(), as the entire process will terminate.

If a job dies or is aborted (see C<< abort_job >>),
it's output tokens are immediately produced but
marked "poisoned", and other jobs which depend on them
will be cancelled.

=head2 $jobsch = Thread::DependentJob->new(OPTIONS);

Create a job scheduler object.  Options are key => value pairs.

=head3 OPTIONS

=over

=item NUMTHREADS => $number

=item NUMTHREADS => 0

Set the number of worker threads.
The default is 1 greater than the number of CPUs.

If zero is specified then concurrent threads are not used and jobs are executed
sequentially when C<< $jobsch->wait >> is called.
This is useful for debugging.

=back

C<Configure> global options may also be passed to C<new>, but still affect
all Job Schedulers.

=head2 $jobid   = $jobsch->sched(PARAMETERS)

=head2 ($jobid) = $jobsch->sched(PARAMETERS)

Schedule a job to run when specified inputs and semaphores are available
and which produces specified outputs
(with no inputs or semaphores the job can can start immediately).

PARAMETERS are key => value pairs:

=over

=item subname => "name" (required)

The name of the function to be called on a worker thread (a sub ref will not work).
It must be in the caller's package unless package:: qualifiers are included.

The function will be called as follows:

=over

 name(args => [args], inputs => [inputs], outputs => [outputs],
      js => job_scheduler_object)

=back

The first three parameters are the corresponding C<sched> parameter values
(actually the results of calling C<shared_clone>).

The I<context> of the function call (list, scalar, or void)
is determined by the 'context' parameter, if specified,
otherwise the context of the call to C<< $jobsch->sched(...) >>.
This contols how return values are handled, see C<<wait>>.

=item args => [...]

"User" arguments for the function.

=item inputs => [token,...]

The tokens, if any, which must be produced before this job can start.

=item outputs => [token,...]

The tokens which are implicitly produced when this job finishes.

=item semas => [SEMSPEC,...]

Semaphores which are all "downed" when the job starts, deferring
the job until that is possible; and "upped" when the job completes.

Each B<SEMSPEC> may be just a Thread::Semaphore object ref (which will be downed/upped by 1)
or a tuple [semaphore, down_up_count] or [semaphore, down_count, up_count].

=item context => "list" | "scalar" | "void"

The context to use when calling B<subname>.
In the function, I<wantarray> will be true, false, or undefined respectively.

If not specified, "list" context is assumed if $jobsch->sched() is called in
list context, otherwise "scalar" is assumed.

Return value(s) are saved and returned in the results from C<<wait>>.

=back

RETURNS: A Job ID identifier string.  Job IDs are never recycled.

The job will run in an indeterminate thread, possibly in the main thread
when C<< $jobsch->wait() >> is called.

=head3 B<Tokens>

Tokens are arbitrary strings.
For example, if a job writes a file to be read by subsequent job(s),
the pathname might be used as the corresponding token.

Tokens may be produced only once but consumed any number of times.
That is to say: They may (actually: must) be an output token for a single job
but may be an input token for any number of dependent jobs.

Tokens may (but need not) be explicitly forgotten when
no longer needed using I<delete_tokens>.

=head3 B<Semaphores>

Semaphores are used to allocate "reusable" resources to jobs.

For example, you might want to limit the number
of disk-intensive jobs to prevent thrashing.  This could be done
using a semaphore initialized to the maximum concurrency allowed,
and specifying that semaphore when scheduling disk-intensive jobs.

A job can start only when its semaphore(s) can all be immediately "downed" by 1
(or by the indicated count) without becoming negative.
When a job finishes, it's semaphores are "upped" (by 1 or the indicated count).

=head2 $results = $jobsch->wait();

Wait until all jobs (managed by Thread::DependentJob instance B<$jobsch>) have completed.

If called in void context (i.e. the results will not be examined), then warnings
are issued about any jobs which aborted.  Silent if called in non-void context.

The return value is a ref to a hash with these members:

    jobid => {RESULT => value | [list of values],
              ABORTMSG => "...",
              EXCEPTION => anything,
             }

RESULT gives the return value from the function specified when scheduling the job.
If the job had "list" context (see C<< sched >>), the RESULT value will be
an array reference to the values returned.
If the job had void context RESULT will be absent.

ABORTMSG will be an explanatory string if the job terminated abnormally for
any reason.  The reasons include:

=over

=item 1)

B<< The job called C<die> >>:  String(s) passed to 'die' will be included in ABORTMSG.
EXCEPTION will contain exactly $@, or rather a shared_clone of it (could be an object
or unblessed container).

=item 2)

B<< The job depended on a poisoned input >>.
This occurs if an 'input' token was to be produced by a precursor job which itself aborted.

=item 3)

B<<< C<< abort_job() >> was called for the job. >>>

=back

If jobs schedule other jobs, C<< $jobsch->wait() >> will wait until
all of them complete.

=head2 $jobsch->abort_job($jobid, [$msg]);

Nothing is done if the job has already completed.
Otherwise the job is killed if running or cancelled if not yet started, and ABORTMSG set
in the job's result hash (see C<wait>).  If B<$msg> is provided it will be included
in the ABORTMSG string.

Returns true if the job was cancelled or killed, false if the job was already complete.

=head2 $jobsch->delete_tokens(token)

=head2 $jobsch->delete_tokens([token, ...]

Tokens must be unique and by default may not be re-used.
A fatal error occurs if an attempt is made to produce the same token twice.

C<< delete_tokens >> may be called to forget tokens which can no longer
influence any scheduled job; thereafter the same identifier strings may be
used for new tokens.  It is not necessary to do this unless
the same token string must be re-used, or to reduce memory usage.

A running job may delete it's own input tokens, but otherwise tokens
used by incomplete jobs may not be deleted.

In practice, B<delete_tokens> may only be by
called by the main thread after return from C<< $jobsch->wait >>,
or from a job which consumes (specifies as it's inputs)
an output token from every other job which might not yet be complete.

=head2 @jobids = $jobsch->all_jobids()

Returns the identifiers for all jobs which have not been "reaped" by
calling C<< $jobsch->wait() >>.

=head2 $jid = my_jobid()

Returns the current job's jobid, or undef if not called from a running job.

=head2 $jobsch->delete()

Waits for any incomplete jobs to finish, and issues warnings about failed jobs (see C<wait>).
Then internal references are broken, allowing the job-scheduler object to be destroyed.

This is not normally necessary, as it is done implicitly at process exit.

=head2 Thread::DependentJob->Configure(global_options...)

Set global options, which affect all job scheduler instances.
These options may also be passed to C<< Thread::DependentJob->new >>
but affect all instances.

=over

=item ALLSERIAL => $boolean

If true, NUMTHREADS defaults to zero (see C<sched>).

=item DEBUG => $boolean

If true, trace messages are printed.

=back

=for Pod::Coverage fmt_jobid get_numthreads

=cut

1;

__END__

### TESTER

#!/usr/bin/perl
use strict; use warnings;
use threads; use threads::shared;
use Thread::DependentJob;
use Carp;
use Data::Dumper::Interp;
select STDERR; $|=1; select STDOUT; $|=1;

$Thread::DependentJob::debug = 0;
Thread::DependentJob->Configure({NUMTHREADS => 3});

our %jobids_seen : shared ;

#sub eat { for (my $i=0; $i < 10*1000000; ++$i) { local $a=$i+3; } }
sub eat { }

our %resources : shared;
our @sidechannel : shared;
sub inner($&) {
  my ($args, $code) = @_;
  my $n = shift @$args;
  #warn dvis '# # # inner: $n @sidechannel\n';
  #sleep(5);
  my ($inputs,$outputs) = @{ $sidechannel[$n] };
  my $outer_name = (caller(1))[3];
  my $tid = threads->tid();
  my $jobid = my_jobid();
  { lock $Thread::DependentJob::warnlock;
    warn ivis "[tid $tid] jobid $jobid: ${outer_name}\@\$args Starting...\\n";
    if ($jobids_seen{$jobid}) { warn "jobid used previously!?!"; exit 1; }
    $jobids_seen{$jobid} = 1;
    foreach (@$inputs) {
      next if ref;
      if (! $resources{$_}) { warn ivis "\%resources\\nINPUT '$_' WASNT PRODUCED?!?"; exit 1; }
      warn " (TESTER: Confirmed '$_' as previous output)\n";
    }
    foreach (@$outputs) {
      next if ref;
      if (my $ojobid = $resources{$_}) {
        warn "$outer_name (jid $jobid): OVERWRITING OLD OUTPUT '$_' from jid $ojobid\n"
      }
      $resources{$_} = 0;
    }
  }
  &$code();
  { lock $Thread::DependentJob::warnlock;
    warn ivis "[tid $tid] jobid $jobid: ${outer_name}\@\$args Finishing...\\n";
    foreach (@$outputs) {
      next if ref;
      if (my $ojobid = $resources{$_}) {
        warn "$outer_name (jid $jobid): OUTPUT '$_' PRODUCED BY SOMEONE ELSE (jobid $ojobid) !\n"
      }
      $resources{$_} = $jobid;
    }
  }
  # ?? remove refs to inputs & outputs
  $resources{(my $copy = $_)} = $resources{$_} for (keys %resources);
  $sidechannel[$n] = undef;
}
sub task1      { inner(\@_, \&eat); 100 }
sub task2      { inner(\@_, \&eat); 200 }
sub task2b     { inner(\@_, \&eat); "2b res" }
sub task2c     { inner(\@_, \&eat); "2c res" }
sub task2d     { inner(\@_, \&eat); "2d res" }
sub task2e     { inner(\@_, \&eat); "2e res" }
sub task3      { inner(\@_, \&eat); 300 }
sub task9      { inner(\@_, \&eat); 900 }
sub taskN      { inner(\@_, \&eat); "N res" }
sub diertask   { inner(\@_, \&eat); die "Die from job"; "should have died" }
sub indep_task { inner(\@_, \&eat); "indep res" }
sub loopertask { inner(\@_, sub {
                              while(1) {
                                warn "loopertask sleeping...\n"; sleep(2);
                              }
                            }); "should not return normally" }

confess "bug" if defined my_jobid();

our $jobsch;
sub dosched($$$;$) {
  my ($inputs, $outputs, $subname, $args) = @_;
  my $n = @sidechannel;
  push @sidechannel, shared_clone( [$inputs,$outputs] );
  unshift @$args,$n; # send sidechannel index as first arg
  $jobsch->sched(inputs=>$inputs, outputs=>$outputs, subname=>$subname, args=>$args);
}

sub run_tests($) {
  my ($opts) = @_;
  warn "==================== START TEST WITH ",vis($opts),"========================\n";

  my $jobsch0 = Thread::DependentJob->new($opts);
  warn "TESTER: Created dummy Job Scheduler $jobsch0 (will not be used)\n";
  #$jobsch0->wait();

  $jobsch = Thread::DependentJob->new($opts);
  warn "TESTER: Created Job Scheduler $jobsch\n";
  confess "bug" if defined my_jobid;

  dosched([],[],'task1',[qw(sleepy brown fox)]);
  $jobsch->wait2();

  my $sem1 = $jobsch->sema("MySema");

  dosched([],[],'indep_task',[qw(nobody cares about me)]);
  my $dier_jobid = dosched([],[],'diertask',[qw()]);
  my $looper_jobid = dosched(['looperexit'],['looperexit'],'taskN',[qw(should never start)]);
  dosched(['the first tok'],[qw(a b c d e)],'task1',[qw(quick brown fox)]);
  dosched([qw(b c d)],[qw(g h i j)],'task2');
  dosched([qw(b),$sem1],[qw(),$sem1],'task2b');
  dosched([qw(c),$sem1],[qw(),$sem1],'task2c');
  dosched([qw(d),$sem1],[qw(),$sem1],'task2d');
  dosched([qw(e)],[qw()],'task2e');
  dosched([qw(a g)],[qw(kkk l m n o p)],'main::task3',undef);
  dosched([qw(p)],[],'main::task9');
  #for (1..1000) {
  #  dosched(['the first tok'],[],'taskN',[qw(quick brown fox)]);
  #}
  confess "bug" if defined my_jobid;
  threads->yield();

  $jobsch->produce('bogus token');
  threads->yield();

  $resources{'the first tok'} = 1;
  $jobsch->produce('the first tok');

  warn "TESTER: Unfinished jobs (first showing):\n", $jobsch->_unfinished_job_info();
  $jobsch->abort_job($looper_jobid);

  while ($jobsch->_has_unfinished_jobs()) {
    my @descrips = $jobsch->_unfinished_job_info();
    warn "TESTER: Unfinished jobs remain:\n",@descrips,
         "\nCalling yield a million times...\n";
    for (0..1000000) { threads->yield(); }
    warn "TESTER: Calling sleep...\n";
    sleep 1;
  }
  #warn "TESTER: sleep 2...\n"; sleep(2);

  # old api...
  #my $results = $jobsch->wait();
  #print dvis '$results\n%jobids_seen\n';

  my $finished_jobs = $jobsch->wait2();
  print dvis '$finished_jobs\n%jobids_seen\n';
  my $results = { map{ ($_ => $finished_jobs->{$_}->{RESULT}) } keys %$finished_jobs };

  confess "bug" if defined my_jobid;
  foreach my $jid (keys %$results) {
    die "bug" unless exists $jobids_seen{$jid} or $jid eq $looper_jobid;
    die "bug" if $jid eq $dier_jobid && defined $results->{$jid};
  }
}

$Thread::DependentJob::debug = 1; # show final cleanup messages
$Thread::DependentJob::debug = 0; # don't show final cleanup messages

run_tests({DEBUG => 0, SERIAL => 1});
run_tests({DEBUG => 0, SERIAL => 0});

#warn "### TEMP setting js=undef - SHOULD NOT BE NEEDED!\n";
#$jobsch = undef;

print "Done.\n";

exit 0;

0;
