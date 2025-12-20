use 5.014;
use warnings;
use if $ENV{DEBUG_THREAD_SUBS} => 'Debug::Comments';

my $DEFAULT = 'DEFAULT'; # default pool name
my $SIG     = 'CONT';
my $THREADS = threads::posix->can('create') ? 'threads::posix' : 'threads';
my $MAIN    = $THREADS->can('self') && $THREADS->self;

# "CRITICAL" indicates an operation which must be signal-safe
# (i.e. uninterruptible), not just thread-safe.

package Thread::Subs;
our $VERSION = '1.000';

use threads::shared;
use POSIX (); # sigprocmask-related
use Scalar::Util qw(looks_like_number);
use Sub::Util qw(set_subname subname);
use Time::HiRes qw(time);

our @CARP_NOT = qw(attributes);

# If a _die message starts with "BUG", it's meant to be unreachable.
sub _die { exists(&Carp::croak) ? goto &Carp::croak : die "@_\n" }
sub _bad { _die("Invalid Thread attribute: @_") }
sub _nap { select(undef, undef, undef, 0.05) } # microsleep

my %POOL;          # per-pool worker count
my %SHIM;          # per-package auto-shim setting
my %CLIM  :shared; # per-sub concurrency limit (shared scalar ref)
my %DEFER :shared; # per-sub array for concurrency limits
my %QLIM  :shared; # per-sub queue limit Thread::Subs::qlim
my %REQ   :shared; # per-pool request arrays
my %SUB;           # all subs Thread::Subs::attr
my %TASK  :shared; # per-thread current sub

my $ENDWAIT = 0;
my $STAGE :shared = 0; # 0: defs, 1: pools, 2: workers, 3: shims, 4: stop

our @AllowSig;
$AllowSig[$_] = 1 for
    POSIX::SIGFPE(),
    POSIX::SIGILL(),
    POSIX::SIGPIPE(),
    POSIX::SIGSEGV(),
    ;

our $Caller; # for _name() qualification

# start_workers redefines this with signal details
sub _send_callback_signal { _die("Signal not settled yet") }

sub import {
    my $class = shift;
    my $caller = caller;
    unless ($STAGE > 0 or exists $SHIM{$caller}) {
        no strict 'refs';
        push @{"${caller}::ISA"}, 'Thread::Subs::attributes';
    }
    $SHIM{$caller} = 1;
    for (@_) {
        if ($_ eq 'noshim') { $SHIM{$caller} = 0 }
        else { _die("Invalid $class import option '$_'") }
    }
    return;
}

sub _name {
    my ($sub) = @_;
    if (ref $sub) { $sub = subname($sub) // _die("BUG: sub has no name") }
    elsif ($Caller and $sub !~ /:/) { $sub = "${Caller}::$sub" }
    no strict 'refs';
    _die("Sub '$sub' does not exist")
        unless exists &$sub;
    return $sub;
}

sub _attr { local $Caller = caller; $SUB{&_name} } # used by t/01-nothreads.t

sub _define_one {
    _die("Too late to define sub attributes")
        if $STAGE > 0;
    my ($sub, $prop) = @_;
    $sub = _name($sub);
    my $attr = $SUB{$sub} //= Thread::Subs::attr->new;
    for (keys %$prop) {
        _die("Invalid attribute '$_' in definition of $sub")
            unless m/^(?:pool|clim|qlim|shim)$/;
        my $val = $prop->{$_};
        _die("Attribute '$_' must be numeric in definition of $sub")
            if /^[cq]lim$/ && $val && $val =~ /\D/;
        $attr->$_($val);
    }
    if (my $clim = $attr->clim) {
        $CLIM{$sub} = shared_clone(\$clim);
        $DEFER{$sub} = shared_clone([]);
    }
    else {
        delete $CLIM{$sub};
        delete $DEFER{$sub};
    }
    if ($attr->qlim) { $QLIM{$sub} = Thread::Subs::qlim->new($attr->qlim) }
    else             { delete $QLIM{$sub} }
    return;
}

sub define {
    local $Caller = caller;
    if (@_ == 1 and ref($_[0]) eq 'HASH') {
        my ($hash) = @_;
        _define_one($_, $hash->{$_})
            for keys %$hash;
    }
    elsif (@_ >  1 and ref($_[1]) eq 'HASH') {
        _define_one(shift, shift)
            while @_;
    }
    else  {
        my ($sub, %opts) = @_;
        _define_one($sub, \%opts);
    }
    return;
}

my %_ATTR = (
    clim => sub { m/^=(\d+)$/ ? $1 : _bad("clim$_") },
    pool => sub { m/^=(\w+)$/ ? $1 : _bad("pool$_") },
    qlim => sub { m/^=(\d+)$/ ? $1 : _bad("qlim$_") },
    );
sub _attribute {
    my ($class, $sub) = @_;
    return 1 unless /^Thread(?:\(|$)/;
    $sub = _name($sub);
    my @attr = /^Thread\((.+)\)$/ ? ($1 =~ m/[^, ]+/g) : ();
    #@! Handling attributes for $sub
    my %opt = (shim => $SHIM{$class} ? 1 : 0);
    for (@attr) {
        my ($name, $val) = /^(\w+)(=.+)?$/;
        _bad("'$_' is unrecognised")
            unless $name && exists($_ATTR{$name});
        _bad("multiple '$name' definitions")
            if exists $opt{$name};
        $opt{$name} = $_ATTR{$name}->() for $val//'';
    }
    if ($opt{pool}) {
        if    ($opt{pool} eq 'SUB') { $opt{pool} = $sub   }
        elsif ($opt{pool} eq 'PKG') { $opt{pool} = $class }
    }
    _define_one($sub, \%opt);
    return;
}

sub MODIFY_CODE_ATTRIBUTES {
    my ($class, $code, @attr) = @_;
    return grep { _attribute($class, $code) } @attr;
}
*Thread::Subs::attributes::MODIFY_CODE_ATTRIBUTES = \&MODIFY_CODE_ATTRIBUTES;

sub end_definitions {
    if ($STAGE == 0) {
        $STAGE = 0.5; # intermediate
        for (values %SUB) {
            my $p = $_->pool;
            my $c = $_->clim;
            $POOL{$p} //= 1;
            $POOL{$p} = $c if $c > $POOL{$p};
        }
        $STAGE = 1; # %POOL now valid
    }
    return wantarray ? %POOL : scalar(keys %POOL);
}

sub set_pool {
    _die("set_pool called in stage $STAGE (stage 0 or 1 required)")
        unless $STAGE == 0 or $STAGE == 1;
    end_definitions() if $STAGE == 0;
    unshift @_, $DEFAULT
        if @_ == 1;
    while (@_) {
        my $pool = shift;
        _die("No subs use '$pool' worker pool")
            unless exists $POOL{$pool};
        my $count = shift;
        _die("Invalid worker count '$count' for '$pool' pool")
            if $count =~ /\D/ or $count < 1;
        $POOL{$pool} = $count;
    }
    return end_definitions();
}

sub signal {
    if (@_) {
        my ($sig) = @_;
        _die("Invalid signal '$sig'")
            if $sig and not exists $SIG{$sig};
        _die("Too late to change signal (stage $STAGE)")
            if $STAGE > 1;
        $SIG = $sig || '';
    }
    return $SIG;
}

sub safe_create_thread {
    my $orig = POSIX::SigSet->new;
    my $safe = POSIX::SigSet->new;
    $safe->fillset;
    $safe->delset($_)
        for grep { $_ && $AllowSig[$_] } keys @AllowSig;
    POSIX::sigprocmask(POSIX::SIG_BLOCK(), $safe, $orig)
        // _die("Can't set sigprocmask: $!");
    # SigSet objects segfault perl v5.12 on threads->create
    my $thread = $THREADS->create(@_);
    POSIX::sigprocmask(POSIX::SIG_SETMASK(), $orig)
        // _die("Can't restore sigprocmask: $!");
    return $thread;
}

sub _be_worker {
    my ($pool) = @_;
    my $id = join('-', $THREADS->tid, $pool);
    #@! Worker $id spawned
    do { lock(%TASK); $TASK{$id} = ''; cond_signal(%TASK) };
    my $queue = $REQ{$pool};
    my ($work, $result, $sub, @arg, $clim, $qlim);
    my $obtain_sub = sub {
        lock(@$queue);
        {   # redo point
            unless (@$queue) {
                if ($STAGE < 4) { cond_wait(@$queue); redo }
                else            { cond_signal(@$queue); return 0 }
            }
            $work = shift @$queue;
            $sub  = $work->[0];
            $clim = $CLIM{$sub};
            if ($clim) {
                lock($$clim); # exclusive on $clim and $DEFER{$sub}
                unless ($$clim > 0) {
                    #@! Request for $sub deferred due to concurrency limit
                    push @{$DEFER{$sub}}, $work;
                    undef $work;
                    redo;
                }
                --$$clim;
            }
        }
        #@! Worker $id assigned to $sub
        $TASK{$id} = $sub;
        cond_signal(@$queue) if @$queue;
        return 1;
    };
    while (&$obtain_sub) {
        $qlim = $QLIM{$sub};
        while ($work) {
            (undef, $result, @arg) = @$work;
            undef $work;
            $qlim->out if $qlim;
            my @res = eval { no strict 'refs'; $sub->(@arg) };
            if (my $ex = $@) { $result->croak($ex) }
            else             { $result->send(@res) }
            #@! Worker $id executed $sub
            if ($clim) {
                lock($$clim); # exclusive on $clim and $DEFER{$sub}
                $work = shift @{$DEFER{$sub}};
                ++$$clim unless $work;
            }
        }
        #@! Worker $id finished handling $sub
        $TASK{$id} = '';
    }
    #@! Worker $id exits
    return;
}

sub start_workers {
    _die("Can't start workers: threads not available")
        unless $MAIN;
    end_definitions() if $STAGE == 0;
    _die("start_workers only available in stage 1 (now stage $STAGE)")
        if $STAGE != 1;
    $STAGE = 1.5; # intermediate
    no warnings 'redefine';
    if (!$SIG) {
        #@! No signal or handler for callbacks
        *_send_callback_signal = sub { };
    }
    elsif ($THREADS ne 'threads') {
        #@! Using $THREADS->kill($SIG) for callbacks
        *_send_callback_signal = sub {
            #@! Sending $SIG via $THREADS->kill
            $MAIN->kill($SIG);
            return;
        };
    }
    else {
        #@! Using kill $SIG for callbacks
        *_send_callback_signal = sub {
            #@! Sending $SIG to PID=$$
            kill $SIG, $$;
            return;
        };
    }
    lock(%TASK);
    for my $pool (keys %POOL) {
        my $count = $POOL{$pool};
        #@! Starting '$pool' worker pool ($count)
        $REQ{$pool} = shared_clone([]);
        for (1..$count) {
            my $tid = safe_create_thread(\&_be_worker, $pool)->tid;
            cond_wait(%TASK) until exists($TASK{"$tid-$pool"});
        }
    }
    $SIG{$SIG} = \&Thread::Subs::result::run_callback_queue
        if $SIG;
    $STAGE = 2;
    return end_definitions();
}

sub shim {
    _die("Shim requested before workers started")
        if $STAGE < 2;
    my ($sub) = @_;
    local $Caller = caller;
    $sub = _name($sub);
    my $attr = $SUB{$sub} or _die("Can't shim non-thread sub '$sub'");
    my $pool = $attr->pool;
    my $qlim = $QLIM{$sub};
    my $queue = $REQ{$pool};
    return set_subname "$sub<shim>" => sub {
        _die("Shim for '$sub' called after workers stopped")
            unless $STAGE < 4;
        #@! Requesting $sub pool=$pool @{[$qlim ? 'qlim='.$qlim->slack : '']}
        my $res = Thread::Subs::result->new;
        $res->fatal("Exception in sub '$sub'")
            unless defined(wantarray) or $THREADS->tid;
        my $req = shared_clone([$sub, $res, @_]);
        $qlim->in if $qlim; # can block
        lock(@$queue);
        push @$queue, $req; # CRITICAL
        cond_signal(@$queue);
        return $res;
    };
}

sub deploy_shims {
    _die("deploy_shims only available in stage 2 (now stage $STAGE)")
        unless $STAGE == 2;
    _die("Attempt to deploy shims in a thread")
        if $THREADS->tid;
    $STAGE = 2.5; # intermediate
    for (grep { $SUB{$_}->shim } keys %SUB) {
        no strict 'refs';
        no warnings 'redefine';
        *{$_} = shim($_);
        #@! Deployed shim for $_
    }
    $STAGE = 3;
    return;
}

sub startup {
    _die("Workers already started")
        if $STAGE > 1;
    &set_pool if @_;
    start_workers();
    deploy_shims();
    return end_definitions();
}

sub endwait {
    _die("Attempt to use endwait in a thread")
        if $MAIN and $THREADS->tid;
    if (@_) {
        my ($t) = @_;
        _die("Invalid endwait '$t'")
            unless looks_like_number($t) and $t >= 0;
        $ENDWAIT = $t;
    }
    return $ENDWAIT;
}

sub stop_workers {
    if ($STAGE < 4) {
        #@! Stopping workers
        $STAGE = 4;
        for my $queue (values %REQ) {
            lock(@$queue);
            cond_signal(@$queue);
        }
    }
    return;
}

sub running_workers {
    return () if $STAGE < 2;
    my ($sig, @thr);
    do {
        local $SIG{$SIG} = sub { $sig = 1 } if $SIG;
        for (keys %TASK) {
            if (my $t = $THREADS->object(/^(\d+)/)) {
                if    ($t->is_joinable) { $t->join; delete $TASK{$_} }
                elsif ($t->is_running)  { push @thr, $t }
            }
            else { delete $TASK{$_} } # detached thread terminated?
        }
    };
    _send_callback_signal() if $sig;
    return @thr;
}

sub stop_and_wait {
    _die("Attempt to stop_and_wait in a thread")
        if $MAIN and $THREADS->tid;
    stop_workers();
    #@! Waiting for workers
    _nap() while running_workers();
    #@! All worker threads joined
    Thread::Subs::result::run_callback_queue();
    return;
}

sub current_tasks { running_workers(); return %TASK }

sub queue_slack {
    _die("queue_slack not available until stage 1 (now stage $STAGE)")
        unless $STAGE >= 1;
    local $Caller = caller;
    if (@_) {
        my $sub = &_name;
        return exists($QLIM{$sub}) ? $QLIM{$sub}->slack : undef;
    }
    my %q;
    $q{$_} = $QLIM{$_}->slack
        for keys %QLIM;
    return %q;
}

sub is_idle {
    return if $STAGE < 2;
    _die("No such worker pool '$_'")
        for grep { !defined($REQ{$_}) } @_;
    my @pool = @_ ? @_ : keys(%REQ);
    lock(@$_) for map { $REQ{$_} } @pool;
    return 0 if grep { @{$REQ{$_}} > 0 } @pool;
    my $pools = join('|', map { quotemeta($_) } @pool);
    return 0
        for grep { $TASK{$_} and /^\d+-(?:$pools)$/ } keys %TASK;
    return 1;
}

END {
    #@! Thread::Subs END (ENDWAIT=$ENDWAIT)
    &stop_workers;
    my $lim = time + $ENDWAIT;
    while (&running_workers) {
        if (time < $lim) { _nap() }
        else {
            #@! Detaching remaining workers
            $_->detach for &running_workers;
            return;
        }
    }
    #@! Clean exit
}


package Thread::Subs::attr;
sub new  { bless [] }
sub pool { @_ == 1 ? $_[0][0] || $DEFAULT : do { $_[0][0] = $_[1]; $_[0] } }
sub clim { @_ == 1 ? $_[0][1] || 0        : do { $_[0][1] = $_[1]; $_[0] } }
sub qlim { @_ == 1 ? $_[0][2] || 0        : do { $_[0][2] = $_[1]; $_[0] } }
sub shim { @_ == 1 ? !!$_[0][3]           : do { $_[0][3] = $_[1]; $_[0] } }


package Thread::Subs::qlim;

use threads::shared;

# Queue limits can't be handled with a simple semaphore because we
# need to maintain an order of arrival across threads.  This object
# limits the queue using a ticket dispenser: calls to in() block when
# the limit is reached, and unblock on a FIFO basis per call to out().

sub new {
    my ($class, $lim) = @_;
    return bless shared_clone([0, $lim]);
}

sub slack {
    my ($self) = @_;
    lock($self);
    return $self->[1] - $self->[0];
}

sub in {
    my ($self) = @_;
    lock($self);
    my $ticket = $self->[0]++; # CRITICAL
    cond_wait($self) until $ticket < $self->[1];
    return;
}

sub out {
    my ($self) = @_;
    lock($self);
    $self->[1]++; # CRITICAL
    cond_broadcast($self);
    return;
}


package Thread::Subs::result;

use threads::shared;
use Scalar::Util qw(refaddr);

# %CB requires careful management.  Callback CODE refs can't be
# shared, so they have to be stored in this hash in the main thread.
# It's important that callbacks be executed so as to clear out the
# hash entry: you can't simply catch object expiry with DESTROY for
# shared objects.

my %CB;
my @CBQ :shared;     # callback queue (ready result objects)
my $CBF :shared = 0; # callbacks running flag (do not signal when true)

sub _die { exists(&Carp::croak) ? goto &Carp::croak : die "@_\n" }

END {
    $CBF = -1; # disable run_callback_queue and inhibit signals
    #@! Thread::Subs::result END: Cancel callbacks (@{[scalar keys %CB]})
    %CB = ();
}

sub new { bless shared_clone([0, 0]) }

sub _id { $MAIN ? is_shared($_[0]) // _die("BUG: result object not shared") : refaddr($_[0]) }

# NB: this can be executed directly or by a signal handler, so it can
# interrupt itself!  $CBF handles self-exclusion.
sub run_callback_queue {
    return 0 if $CBF; # at END or already executing
    _die("Callbacks must be executed in the main thread")
        if $MAIN and $THREADS->tid;
    $CBF = 1; # exclude self and inhibit signals
    #@! Invoking callbacks
    my $n = 0;
    while ($CBF) {
        my $result = do {
            lock(@CBQ);
            if (@CBQ) { shift @CBQ }
            else { $CBF = 0; $CBF = 1 if @CBQ } # signal race possile
        };
        if (ref $result) {
            $n++;
            eval {
                my $id = $result->_id;
                if ($id && $CB{$id}) {
                    _die("BUG: attempt to invoke callback on unready result")
                        unless $result->[0];
                    (delete $CB{$id})->($result);
                    #@! Callback executed successfully
                }
                return 1;
            } or do { $CBF = 0; die $@ };
        }
    }
    #@! Callback processing complete ($n)
    return $n;
}

sub cb {
    _die("Thread::Subs::result cb method only available in the main thread")
        if $MAIN and $THREADS->tid;
    my ($self, $cb) = @_;
    my $id = $self->_id;
    return $CB{$id} if @_ == 1;
    return $self if $CBF == -1; # no-op if END reached
    my $sig;
    do {
        local $SIG{$SIG} = sub { $sig = 1 } if $SIG; # defer callbacks
        lock($self);
        if ($cb) { $CB{$id} = $cb  }
        else     { delete $CB{$id} }
        if ($self->[0] == 0) { $self->[1] = $cb ? 1 : 0 }
        elsif ($cb) {
            lock(@CBQ);
            push @CBQ, $self; # CRITICAL
            $sig = $SIG;
        }
    };
    Thread::Subs::_send_callback_signal()
        if $sig;
    return $self;
}

sub ready  { $_[0][0] }
sub failed { $_[0][0] < 0 }

sub _set {
    my $self = shift;
    my $args = shared_clone([@_]);
    my $sig;
    do {
        local $SIG{$SIG} = sub { $sig = 1 }       # defer callbacks
            if $SIG && !($MAIN && $THREADS->tid); # if main thread
        lock($self);
        if ($self->[0] == 0) {
            my $cb = $self->[1];
            @$self = @$args;
            if ($cb && $CBF != -1) {
                lock(@CBQ);
                push @CBQ, $self; # CRITICAL
                $sig = $SIG;
            }
            cond_broadcast($self);
        }
    };
    Thread::Subs::_send_callback_signal()
        if $sig && !$CBF;
    return $self;
}

sub send  { shift()->_set( 1, @_) }
sub croak { shift()->_set(-1, @_) }

sub data {
    my ($self) = @_;
    lock($self);
    cond_wait($self) until $self->[0];
    my (undef, @data) = @$self;
    return wantarray ? @data : $data[0];
}

sub recv {
    my ($self) = @_;
    my @data = $self->data;
    _die(@data) if $self->failed;
    return wantarray ? @data : $data[0];
}

sub warn {
    my ($self, $msg) = @_;
    $msg ||= "Exception in threaded sub";
    my $cb = sub {
        warn "$msg: @{[$_[0]->data]}"
            if $_[0]->failed;
    };
    return $self->cb($cb);
}

sub fatal {
    my ($self, $msg) = @_;
    $msg ||= "Exception in threaded sub";
    my $cb = sub {
        die "$msg: @{[$_[0]->data]}"
            if $_[0]->failed;
    };
    return $self->cb($cb);
}

sub ae_cv {
    my ($self) = @_;
    my $cv = AE::cv();
    my $cb = sub {
        my @data = $_[0]->data;
        if ($_[0]->failed) { $cv->croak(@data) }
        else { $cv->send(@data) }
        return;
    };
    $self->cb($cb);
    return $cv;
}

sub mojo_promise {
    my ($self) = @_;
    my $p = Mojo::Promise->new;
    my $cb = sub {
        my @data = $_[0]->data;
        if ($_[0]->failed) { $p->reject(@data) }
        else { $p->resolve(@data) }
        return;
    };
    $self->cb($cb);
    return $p;
}

sub future {
    my ($self) = @_;
    my $f = Future->new;
    my $cancel = sub {
        $self->cb(undef);
        $self->croak("cancelled");
        return;
    };
    $f->on_cancel($cancel);
    my $cb = sub {
        my @data = $_[0]->data;
        if ($_[0]->failed) { $f->fail(@data) }
        else { $f->done(@data) }
        return;
    };
    $self->cb($cb);
    return $f;
}

1;
__END__

=head1 NAME

Thread::Subs - Execute selected subs concurrently in worker threads

=head1 SYNOPSIS

    # Simple usage
    use threads;
    use Thread::Subs;
    sub foo :Thread { something_complex }
    Thread::Subs::startup();
    my $result = foo();
    # ... do other things while something_complex happens ...
    my @data = $result->recv;

=head1 DESCRIPTION

This module provides a relatively simple way to execute subroutines
concurrently in separate threads.  All "simplicity" is relative where
parallelism is concerned, but this module manages the creation and
termination of worker threads, provides attributes whereby a sub can
be marked as threaded, allows limits to be placed on concurrency and
outstanding requests, and provides an asynchronous results interface.

The net effect is that you can mark a sub with the "Thread" attribute
then call it as usual: it immediately returns a lightweight result
object (very similar to an L<AnyEvent> condition variable) while the
actual work proceeds in a worker thread.  Data passed to and returned
from the sub must be sharable via L<threads::shared>.

Unlike most thread-pool or fork-manager modules, Thread::Subs aims to
provide a high-level abstraction that minimises cognitive overhead.
After the one-time pool startup, the presence of worker threads is
almost invisible in application code.  The ideal is that one simply
declares a sub to be threaded; in practice you also need to change the
sub call to accommodate the fact that it becomes non-blocking, but
this will be familiar to anyone who has used an event loop.

Note that this documentation is not a tutorial on threading or even on
Perl threads in particular.  It aims to be as accessable as possible,
but some understanding of the Perl L<threads> and L<threads::shared>
mechanisms are assumed.  That may be quite a lot to assume, because
that documentation itself discourages its own use.  Rest assured that
the aim of this module is to make threads far more practical.

There are quite a few moving parts behind the scenes which make this
all work.  Here's the big-picture view of what's going on.

=head2 Sub Attributes

Perl has an L<attributes> mechanism which allows the language to be
extended in various ways.  This module uses that mechanism to add a
"Thread" attribute to sub declarations.  This allows the user to
declare specific subs as threaded and express some parameters such as
concurrency limits.  These attributes can also be applied through
explicit function calls, but attributes allow the properties to be
expressed as part of the static sub declaration.

Here is a basic example.

    sub foo :Thread(qlim=10 clim=1) { ... }

This declares that sub foo() can be called in a thread: "qlim=10"
means there can be up to ten such calls waiting to execute; "clim=1"
means only one instance of the sub can execute concurrently.  These
parameters and others are described in more detail later.

=head2 Workers

The threads which execute the subs are "workers", potentially divided
into named "pools" associated with particular subs.  In the simplest
case, all workers are part of the "DEFAULT" pool.  Workers are spawned
early in the process lifecycle and persist until shut down, minimising
the associated overhead.  This design trades off some flexibility for
simplicity and efficiency: you can configure the number of workers per
pool at startup, but not dynamically afterwards.

Each worker pool is associated with a queue (a shared array) into
which requests are inserted; workers take from the head of this queue
when ready.  Insertion into the queue is subject to an optional "qlim"
limit which can cause the request to block.  Execution is also subject
to optional concurrency limits, and requests will be placed into a
per-sub "deferred" queue if that limit is reached, to be handled as
soon as a worker currently processing such a sub is ready.

=head2 Results

Because the results of threaded subs only become available some time
later, the value returned immediately is a "result" object with an API
very similar to an L<AnyEvent> condition variable.  This object also
provides methods to convert the result into other popular async result
methods such as L<Future> and L<Mojo::Promise>.

You can obtain the final value from a "result" object in two ways:
block with C<< ->recv >>, or set a callback function.  The blocking
mode uses L<threads::shared> C<cond_wait()> to wait for the worker to
signal completion.  In the callback case, the function is invoked from
a signal handler in the main thread when the result is ready.

Note that the "result" object is capable of conveying either a list of
returned data or an exception condition.  The execution context for a
threaded sub is always a list, but if the sub raises an exception it
will be caught and then re-thrown when the result is evaluated.

=head2 Shims

A "shim" is a function or library which transparently intercepts API
calls and changes the arguments passed, handles the operation itself
or redirects the operation elsewhere.  A related term is "wrapper",
which is simply a thin layer of additional logic around pre-existing
functionality.  This module turns ordinary subs into threaded subs
using this kind of mechanism: the logic which converts an ordinary
function call into a complex, asynchronous, queued dispatch process to
a worker pool with concurrency limits is simply called a "shim" here.

The process can't be completely transparent because calls change from
blocking/synchronous to nonblocking/asynchronous, and it's very hard
to hide such a fundamental change.  Aside from the "result" object, as
discussed in the previous section, however, the change is surprisingly
transparent.  Once the properties of all threaded subs are declared
and the worker threads start up, the original subs can be replaced (in
the main thread only) with shims by installing them directly into the
original subroutines' symbol table slots.  This means they are called
as normal, modulo the fact that they immediately return a "result"
object instead of blocking.  The code inside a threaded sub need not
do anything special at all: data in and out is handled as usual.

Replacing the original subs with shims is not always the best option,
but the shim itself is simply a CODE reference (a closure) which can
be generated for any given threaded sub.  You can use this value in
all the usual ways, as you prefer, and opt out of auto-shims if they
don't help.  Note, however, that CODE references are not portable
between threads: a thread must generate its own shims, and only the
main thread offers automated shim deployment.

=head1 IMPORTING

First, note that you should "use threads" before using this module or
any other module which uses this module if you intend to make use of
its functionality.  Using this module does not oblige you to use
threads, but it is effectively a no-op unless you do.  You may want to
tune the thread stack size while you're at it.

Importing this module enables the "Thread" attribute for subs in the
importing package.  The details of attribute syntax are given in the
L<ATTRIBUTES> section.  This feature works by adding a sub-package to
the caller's @ISA array which containins the C<MODIFY_CODE_ATTRIBUTES>
method which implements sub attribute processing.  If your package
implements that method itself or imports it from elsewhere, you'll
need to make special arrangements.

All subs declared with the "Thread" attribute are replaced by a shim
when L</"deploy_shims"> is called unless you specify "noshim" as an
argument to the import.  There are no other valid arguments to import
at this time, and unrecognised arguments will raise an exception.

=head1 ATTRIBUTES

Where the module is imported or some other technique is used to invoke
the C<MODIFY_CODE_ATTRIBUTES> method from your package at compile
time, subs can declare a "Thread" attribute with the following syntax.

All parameters are optional; where any parameters are present, they
must be enclosed in parentheses, as in "Thread(clim=1)".  Parameters
are separated by spaces and/or commas when more than one is present,
as in "Thread(clim=1, pool=SUB)".  The parameter name must be followed
immediately by an equals sign and the value, no quotes.

Unrecognised parameter names produce a compile-time failure.  Valid
names and their associated values are as follows.

=head2 clim

Concurrency limit: an upper limit on how many worker threads may
execute this sub simultaneously; also used as a hint to suggest a size
for the worker pool, as the pool would need to be at least this large
for the value to be meaningful as a limit.  The associated value must
be an integer of one or more.  Where absent, no limit is applied other
than the natural limit of the number of running workers.  A common
case is "clim=1", which allows the sub to be concurrent with the main
thread and other subs, but not itself: see L</"The Power of One">.

=head2 pool

The worker pool name which executes the sub, which is "DEFAULT" unless
specified otherwise.  The special name "SUB" is replaced by the full
name of the sub itself (e.g. "main::foo") to facilitate worker pools
dedicated to a particular sub.  Similarly, "PKG" is replaced by the
package name in which the sub resides, facilitating a package-specific
pool.  Names must otherwise be at least one character long and consist
of alphanumerics and underscore - a limitation imposed to keep the
attribute syntax simple, not a limitation on pool names as such.

=head2 qlim

Queue limit: an upper limit on the number of requests for a particular
sub which can be outstanding, with no assigned worker.  This value
must be an integer of at least one.  Where absent, there is no limit,
which means requests never block, but the request queue can grow
indefinitely.  Where present, the call will block until the request
can be inserted into the queue without exceeding the limit.  Note that
this blocking is not event-loop-friendly, so you may want to manage
limits some other way if using one.

The main thread is usually the only thread making such requests, but
it is possible to make requests from worker threads as well.  As such,
more than one thread might block on a queue limit.  If so, they will
unblock in FIFO order.  Beware of possible deadlock in this case: see
L</"Threads Calling Threads"> for more detail.

=head1 FUNCTIONS

The module is primarily driven by functions, but also has a "result"
object to convey the results of subs executed in worker threads.  This
section deals with the functions; see L</"RESULTS"> for the object.

No functions are imported and the import semantics do not support it.
Functions should be called with their fully qualified names.  Note
also that these functions are highly dependent on execution order.
The overall process is divided up into stages, and each function is
valid only in particular stages, as outlined below.

=over 4

=item *

Stage zero is available immediately after the module is imported, and
is the stage where sub attributes are defined, either by the attribute
mechanism or calls to C<define()> (or both).

=item *

Stage one, triggered by C<end_definitions()>, closes off definitions
and evaluates worker pools implied by those definitions.  The pools
can be resized with C<set_pool()> in this stage.

=item *

Stage two, triggered by C<start_workers()>, starts up the worker
pools, at which point it becomes possible to generate shims and
actually call the subs.

=item *

Stage three, triggered by C<deploy_shims()>, replaces the threaded
subs in the main thread with shims (unless disabled).  This is the
normal operation stage.

=item *

Stage four, triggered by C<stop_workers()>, commences shutdown by
closing off the request queues and terminating idle workers.

=back

The functions are presented below in the natural calling order, along
with their associated restrictions.  Violation of the calling order
requirements will result in an exception.  Simple use cases will only
require sub attributes and the L</"startup"> function.

Functions are not guaranteed safe to call from signal handlers (or
signal-based callbacks) unless noted otherwise.  See L</"SIGNALS">.

=head2 define

    Thread::Subs::define(\%defs);              # single hashref
    Thread::Subs::define($sub, \%params, ...); # sub-hashref pairs
    Thread::Subs::define($sub, %params);       # sub, name-value pairs

This is a more flexible alternative to the L<ATTRIBUTES> mechanism,
allowing the properties of threaded subs to be specified.  It is not
mutually exclusive with attributes, though for the sake of clarity I
suggest that you don't override attribute definitions.  It is only
available in stage zero.

The calling semantics permit one or many subs to be defined in a
single call, but the all-in-one hashref approach can only identify
functions by name because hash keys are necessarily strings.  The
other approaches permit $sub to be either a string or a reference to
the sub, but see L</"Quirks of Sub Names"> for caveats about using
references.  String-based names which do not include a colon will have
the caller's package prepended.

Anonymous subs are not allowed because CODE references are not a
thread-sharable data type: a request to execute a sub must refer to
the sub by name.  You can assign an anonymous sub to a glob, then use
C<define()> on that name, but bear in mind that you can't dynamically
alter the sub in this way: the worker threads see whatever code was in
effect when they started.

The %parameters are the same as the L</"ATTRIBUTES"> parameters with a
couple of exceptions arising from the difference between attribute
strings and name-value pairs.  First, the "pool" name can be any
string; "SUB" and "PKG" are not special cases: use the literal sub or
package name if you want to achieve the same effect.  Second, there is
a "shim" parameter, boolean and default false, which declares whether
the L</"deploy_shims"> function should redefine it.  This parameter is
implicitly true for attribute-defined functions unless the import
option "noshim" was specified.

Note that C<define()> always overrides any previous definition, which
includes definitions from sub attributes.  Only the parameters which
are specified change: other parameters retain existing values, so
partial redefinition is possible.  There is no symmetric "undefine"
mechanism which restores defaults or makes the sub non-threaded.

=head2 end_definitions

    %pool = Thread::Subs::end_definitions();

If called in stage zero, this function calculates base worker pool
sizes from definitions currently in effect.  All pools will have at
least one worker, but the number will be increased to match the
largest "clim" value in the pool, if any.  On return, stage one has
commenced and no further calls to C<define()> are permitted.

In a list context, a list of name-value pairs is returned, where the
names are all the pool names and the values are the base worker count.
In a scalar context, the number of pools is returned.  Unless you need
these values for pool planning, calling this function is optional
because C<set_pool()> and C<start_workers()> call it on demand.

If called in any stage other than zero, the function has no effect and
simply returns the current worker pool configuration.

=head2 set_pool

    %pool = Thread::Subs::set_pool($count);
    %pool = Thread::Subs::set_pool($pool, $count, ...);

This function is permitted in stages zero and one; if called in stage
zero it calls C<end_definitions()> on your behalf to commence stage
one.  It allows the number of workers per pool to be adjusted from the
base values, as returned by C<end_definitions()>.  It's not possible
to create or delete pools this way: all threaded subs are associated
with a pool at this point, and all such pools must have at least one
worker, so all you can do is adjust the numbers.  An exception is
raised if any $pool argument does not match an existing name, or if
any $count is not an integer greater than zero.

The single-argument version sets the 'DEFAULT' pool count.  The return
value is as per C<end_definitions()>, post-adjustment.

=head2 signal

    $sig = Thread::Subs::signal();
    $sig = Thread::Subs::signal($sig);

Gets and optionally sets the signal name (%SIG key) used by callbacks,
default 'CONT'.  The get operation, with no arguments, can be called
at any time.  The set operation, with one argument, is permitted in
stages zero and one, before workers are started.

The callback mechanism relies on worker threads sending this signal to
the main thread when ready.  The callback is then executed in the main
thread in the context of this signal handler.  If you set $sig to a
false value, then no signal handler is installed and callbacks won't
work unless you poll L</"run_callback_queue">; the returned $sig will
be empty string in this case.

The signal handler is installed right after the workers start if true.
Selecting a signal in this manner means you are delegating control of
the %SIG entry to this module: it will not only install the signal
handler, but occasionally localise it to something else.

See L</"SIGNALS"> for more detail.

=head2 start_workers

This function is permitted in stages zero and one; if called in stage
zero it calls C<end_definitions()> on your behalf to commence stage
one.  It then spawns all the threads in the worker pools, creates the
associated queue arrays, and installs the signal handler for callbacks
unless it is disabled.  When it returns, stage two has commenced.  The
function takes no arguments and returns the same pool size data as
C<set_pool()> and C<end_definitions()>, except that it's final this
time and reflects what's actually running.

=head2 startup

    %pool = Thread::Subs::startup($count);
    %pool = Thread::Subs::startup($pool, $count, ...);

This is an all-in-one convenience function to get things started with
minimal fuss.  It is permitted in stages zero and one; in stage zero
it calls C<end_definitions()> on your behalf to commence stage one.
It then calls C<set_pool()> with the arguments you pass to it (if
any), then C<start_workers()>, and C<deploy_shims()>.  It returns
%pool data from C<start_workers()>.

If successful, stage three has commenced when this function returns.

=head2 shim

    $code = Thread::Subs::shim($sub);

This function is only available in stage two and up.  It returns a
$code ref which can be used to call $sub in a worker thread.  The $sub
can be given as a name or as a reference, but it must have "Thread"
attributes or have been the subject of an earlier C<define()> call.
See L</"Quirks of Sub Names"> for caveats relating to the use of sub
references.  String-based names with no colon will have the caller's
package prepended.  An exception is raised if there is no such sub or
it has not been defined as a Thread sub.

The specific parameters which affect the shim are "pool", which tells
it where to send the request, and "qlim", which tells it to possibly
block before returning.  The "shim" option has no effect on this
function: that option only alters the behaviour of C<deploy_shims()>.

Note that when $code is called in a void context it will automatically
apply the L</"fatal"> method to the otherwise-ignored result object.
This means that an exception thrown in the threaded sub can ultimately
cause an exception in the main thread.  If this isn't the behaviour
you want, handle the result object explicitly in some other way.

The $code returned has its name property set to the original sub name
appended with "<shim>".  This provides more context information in the
Perl debugger than an anonymous sub.

Calling this function from a signal handler is permitted, but note
that the caller's package is indeterminate in this case, so don't use
relative sub names.

=head2 deploy_shims

This function is only available in stage two.  It takes no arguments,
returns nothing, and can only be called from the main thread.  When it
returns, stage three has commenced.  It replaces all the threaded subs
bearing the "shim" option with shims, meaning that subsequent calls to
those subs will use the asynchronous interface and run in a worker.
This change only affects the main thread and any threads you spawn
subsequently: the workers continue to see the original sub.

This replacement has pros and cons.  See the earlier discussion of
L</"Shims"> for details and alternatives.  You are under no strict
obligation to use this function, but it may be tidier than the
alternative, which involves more explicit use of C<shim()>.

Once a sub is replaced by its shim, you can't (in the main thread)
pass a reference to the sub to C<shim()>: it's now the wrong code, and
doesn't have the original name.  The reference to the sub I<is> the
shim now.  Calling C<shim()> with the string-based name still works
correctly, however.

=head2 endwait

    $sec = Thread::Subs::endwait();
    $sec = Thread::Subs::endwait($sec);

Gets and optionally sets the "endwait" period (in seconds), default
zero.  Can be called in either form at any time, but $sec must be a
numeric value of zero or more in set mode or an exception is raised.
This function is only available in the main thread.

When the process exits, some worker threads may still be running,
either because the work takes a while or because there are still
requests in the queue.  This value gives the number of seconds to wait
in the END phase before giving up and detaching them.  The workers
will stop naturally if they complete all remaining work before this
time limit.

Setting this to a small non-zero value can help to prevent spurious
warnings about still-running threads at exit.  You may want to set
this to a larger value if your threads are potentially doing something
you'd rather not interrupt, but the trade-off is that process exit may
be delayed.  Bear in mind that this delay applies both to explicit
C<exit()> and abnormal exits via C<die()>, but not uncaught signals.

This function is safe to call from a signal handler.

=head2 stop_workers

This function takes no arguments and returns nothing.  It is valid at
any stage, and when it returns, stage four has commenced.  It shuts
down the queues so that no further subs can be requested: any requests
already in the queue will still be processed, and worker threads will
exit when there is no further work to do.  Attempting to use a shim in
stage four (to submit more work) will raise an immediate exception.

Calling this function is optional as it is always called during END
processing, with possible additional delay if L</"endwait"> was given
a positive value.  The function effectively becomes a no-op once
called, and it is not possible to restart the workers once stopped.

If your code includes thread-to-thread calls, this operation might be
disruptive because those calls will start to fail.  You may want to
poll the L</"is_idle"> function before stopping workers in this case.

This function is safe to call from a signal handler.

=head2 stop_and_wait

As per L</"stop_workers">, but does not return until all worker
threads have exited and all callbacks have executed.  This is very
convenient for simple scripts, but it can hang on a stuck worker.
This function is only available in the main thread.

=head2 running_workers

    @threads = Thread::Subs::running_workers();

This function, primarily intended for internal use, returns a list of
worker L<threads> objects which are still running.  It also "joins"
any workers which have ended.  May be called at any time, but returns
an empty list immediately when called before stage two.

A possible use for this is to detect dead workers.  It's important for
workers to keep running, so simple exceptions will not take them down,
but there are edge cases beyond control which can theoretically cause
a worker thread to die.  If you have a long-running process, you may
want to do an occasional worker head-count with this function and bail
out if any have gone missing.

This function is safe to call from the callback signal handler.

=head2 current_tasks

    %tasks = Thread::Subs::current_tasks();

Provides a snapshot of the current state of workers in the form of ID
and sub-name pairs.  The ID is a combination of the thread ID and the
pool name ("$tid-$pool").  Idle workers have an empty string for the
sub name.  May be called at any time.

This function is safe to call from the callback signal handler.

=head2 queue_slack

    $slack = Thread::Subs::queue_slack($sub);
    %slack = Thread::Subs::queue_slack();

Provides a snapshot of the current state of queue limits.  It is only
available in stage one and beyond.

Where a $sub is specified, it returns the current $slack in the queue
for that $sub, or undef if it has no queue limit.  The $slack is the
number of requests which can still be made without blocking.  This can
be zero or even negative (meaning that something is currently
blocked).  The semantics of $sub are as per L</"shim">.

Where no $sub is specified, returns a list of name-value pairs for all
subs with a queue limit and their current slack.

Bear in mind that these are volatile numbers, and reality can easily
have changed by the time you see them.

Calling this function from a signal handler is permitted, but note
that the caller's package is indeterminate in this case, so don't use
relative sub names.

=head2 is_idle

    $bool = Thread::Subs::is_idle(@pools);

Returns true if the queues for all specified @pools are empty, and the
associated workers are idle.  If @pools is an empty list, all pools
are checked.  This is not a lightweight operation: all the associated
request queues must be locked while checked.  An exception is raised
if @pools contains a non-existent pool name.  The function returns
undef immediately with no further checking if workers have not been
started yet (before stage two).

This function is safe to call from a signal handler.

=head2 safe_create_thread

    $thread = Thread::Subs::safe_create_thread($sub, @args);

This is a wrapper around C<< threads->create($sub, @args) >> (or class
L<threads::posix>, if loaded) which uses C<POSIX::sigprocmask()> to
block most signals to the thread.  With few exceptions, signals should
be handled by the main thread only.  You can change the set of signals
permitted via @Thread::Subs::AllowSig: any element of the array with a
true value permits the corresponding signal number.  Such changes only
affect subsequent calls to this function, not existing threads.

By default, the following signals are allowed: FPE, ILL, SEGV, and
PIPE.  The first three are "synchronous" signals which are likely to
result in a core dump regardless of the thread in which they occur.
PIPE is permitted because it can be raised against a thread in normal
IO operations, and will continue its default behaviour of killing the
process if not handled.  Changes to C<$SIG{PIPE}> in a thread sub are
best performed with C<local> to keep things orderly.  If any of these
signals are blocked when you call the function, they remain blocked in
the new thread.

You'll want to use this function if creating a thread other than a
worker thread; without this, a thread might receive a signal for a
callback which it can't serve, losing the signal at best, killing the
thread at worst.  Worker threads are also created via this function,
ensuring that general signal handling happens in the main thread.  See
L</"SIGNALS"> for further details on the subject.

=head1 RESULTS

The "result" sub-object (Thread::Subs::result) is returned by the shim
code which requests that a worker execute a sub.  The interface is
very similar to "condition variables" in L<AnyEvent> with some minor
tweaks and caveats.  It's unlikely that you'll want to create any of
these objects, so the documentation starts with the methods of most
interest given that you already have one.

=head2 recv

    @data = $result->recv;

This is a blocking receive operation: it will block until a result has
been sent, then either return that @data or raise an exception if the
result was a failure.  Returns C<$data[0]> in a scalar context.

Be warned that this kind of blocking is not signal-friendly.  Signal
handlers will not get a chance to run while you are waiting.  This
includes other callbacks you may have requested.  If you receive too
many signals while blocked, perl may bail out.

=head2 data

    @data = $result->data;

As per C<recv()>, but returns the exception string as data in the case
of failure rather than raising an exception.  See also L</"failed">.
This has no equivalent in L<AnyEvent>.

=head2 cb

    $code = $result->cb;
    $result = $result->cb($code);

Gets or sets the callback for the $result.  This can only be done from
the main thread: it's possible in principle to have callbacks to any
thread, but it would be very complex to implement and use, so support
is limited to the simple case.  Unlike its L<AnyEvent> equivalent, the
set mode returns self.

You can only set one callback: a second set operation replaces the old
callback if it has not yet been called, and a false argument cancels
the callback.  The callback is also removed on execution.  If the
$result is ready when you set a callback, and callbacks are driven by
a signal (default behaviour), that signal is raised before this method
returns.  In this case it is likely that the callback has executed as
well, but it is not guaranteed: make no assumptions about timing.

While the timing of callbacks can vary, some guarantees are offered
for order of execution, particularly for "clim=1" subs.  In short, if
you call such a sub more than once and set callbacks on the results in
the same order, the callbacks will execute in that order.  Generally,
callbacks are added to the queue at whatever moment they become both
data-ready and callback-set, and it's a race as to the order in which
that happens.

Callbacks are executed by the L</"run_callback_queue"> function, which
is normally invoked as a signal handler, so callback code should be
constrained to the same basics which are suitable in a signal handler.
In particular, avoid blocking: you might block on something which
won't be ready until the code you interrupted completes, resulting in
deadlock.  This includes calls to thread subs with a "qlim" value,
which block when that limit is reached.  Calls to thread subs with no
qlim are safe, however.  See L</"SIGNALS"> for more detail.

If you need to execute something modestly complex, it's best to raise
a flag and deal with it outside the callback context.  Event loops can
also be used to defer execution: see L</"Async Adaptors">, below.

The callback is invoked in a void context with the $result passed as
the only argument.  Any returned value is ignored.  Exceptions raised
in callbacks will normally be fatal because the signal handler won't
catch them.

Once you've set a callback, you are not obliged to keep the $result
object: it will be kept alive by the worker thread which is providing
the result, and then by the callback itself.  If no further references
to it are created, it will be destroyed when the callback completes.

Note that all outstanding callbacks are cancelled when the process
reaches the END phase, and any attempt to set a new one is ignored.
Avoid C<exit()> before callbacks are complete if that's undesirable.

=head2 fatal

    $result = $result->fatal($msg);

Sets the callback to raise an exception if an exception occurred in
the sub.  The output is "$msg: $@"; default text is provided for $msg
if it is false.  This makes exceptions fatal as usual, but ensures
they happen in the main thread rather than killing off workers.  Be
aware that this exception will likely occur in a signal handler where
it can't be caught.  Returns self; has no equivalent in L<AnyEvent>.

Note that L</"shim"> adds this callback if you call a sub in a void
context.  It includes the sub name in the $msg for context.

=head2 warn

    $result = $result->warn($msg);

As per L</"fatal">, but emits a warning message instead of raising an
exception.  This is generally the bare minimum one should do with a
result object if it returns no data, otherwise exceptions will be
completely invisible, including those caused by errors in your code.

=head2 ready

Boolean: true if the result is ready, false if it isn't.

=head2 failed

Boolean: true if the result is ready and it is a failure (generated by
C<croak()>).  This has no equivalent in L<AnyEvent>.  The typical use
case is in callback code like the following.

    my $cb = sub {
        my ($result) = @_;
        my @data = $result->data;
        if ($result->failed) { do_failure_thing(@data) }
        else { do_success_thing(@data) }
    };

=head2 run_callback_queue

    $count = Thread::Subs::result::run_callback_queue();

This is a function which takes no arguments, but it can be invoked as
a method if desired.  It is normally installed as the signal handler
specified by the L</"signal"> function, but you'll need to make other
arrangements if you've disabled it for some reason.  When called (from
the main thread only), it executes callbacks on any ready results with
an associated callback until the queue is empty, including any results
which enter the queue while it is being processed.  Returns the number
of callbacks executed.

If a callback dies, the exception will be passed through.  This will
normally occur in the signal handler context and result in the process
exiting.  If you install a wrapper which catches the exceptions, you
should bear in mind that the callback queue may not be empty after
such an exception: the offending callback will no longer be in the
queue, but others may still be waiting, so call it again if you intend
to carry on.

When the program reaches the END phase, all still-pending callbacks
are cancelled, and this function becomes a no-op.  Anything still in
the queue awaiting execution at this point is lost.

It is not safe to call this function from a signal handler context
other than the one specified by L</"signal">: multiple parts of the
module need to know what that signal is and whether it is in use.

=head2 Async Adaptors

There are three methods designed to adapt this async result object to
other similar systems.  All of these methods rely on the callback
mechanism, so they are mutually exclusive with each other per object
and will replace any existing callback.  Their documentation follows,
but first, a caveat.

As discussed in the L<AnyEvent> "signal watchers" documentation, it is
not possible to have general race-free signal handling in pure Perl,
so use any pure Perl event loop at your own risk.  This module uses
guard variables internally to prevent such races, but the technique
can't be applied to external modules.  As such, it is possible for an
event loop to wait for a signal that it has already missed, and this
will manifest as an apparent lock-up or lengthy delay.  The length of
that delay can be limited by setting up a recurrent timer.

=head3 ae_cv

This requires L<AnyEvent> to be loaded and returns a real L<AnyEvent>
condition variable.  This is preferable if you are using L<AnyEvent>,
because calling C<< ->recv >> on it will run the event loop, whereas
the base result object would block.  It also provides a safer context
for callback execution than the default signal handler context.

=head3 mojo_promise

This requires L<Mojo::Promise> to be loaded and returns an object of
that type which will C<< ->resolve >> or C<< ->reject >> in accordance
with the result object.

=head3 future

This requires L<Future> to be loaded and returns an object of that
type which will be C<< ->done >> or C<< ->fail >> in accordance with
the result object.  If you C<< ->cancel >> the Future, the callback is
removed and the result object is failed with a "cancelled" message.
If this module is extended to permit interruption of running thread
subs in future, then this will also abort the sub.

Be aware that the Future and result have mutual references such that
both will persist until the callback occurs or you cancel the Future.

If you have L<Future::AsyncAwait> loaded, you can C<await> this in the
context of an C<async sub>, per the following example.

    sub foo :Thread { ... }
    async sub bar {
        ...
        my @result = await foo(@args)->future;
        ...
    }

=head2 Other Methods

The following methods are primarily intended for internal use.  They
correspond to the same methods for L<AnyEvent> condition variables,
but note that C<< ->send >> and C<< ->croak >> only have an effect
when the object is in the pending state.  This means that the first
such method sets the final state, and any subsequent calls are no-ops.
The rationale is that we deal with a lot of races, and we are more
interested in who came first than last.  If you want to know whether
you won the race, check the data afterwards.

=head3 new

Class method: returns a new object in the "pending" (not ready) state.

=head3 send

If the object is "pending", it becomes "ready" and the data passed as
arguments become the result data; no effect otherwise.  Returns self.

=head3 croak

If the object is "pending", it becomes "ready" and "failed"; the data
passed becomes the exception reason.  No effect otherwise.  Returns
self.

=head1 SIGNALS

As mentioned in the documentation for the L</"signal"> function and
the L</"run_callback_queue"> function, result callbacks require the
use of a signal to execute callbacks in the main thread.  This is the
'CONT' signal unless specified otherwise.

'CONT' is a slightly cheeky choice of signal as the default: given the
standard meaning of 'CONT' (resume if stopped), it would normally be
pointless for a process to send itself such a signal because if it can
send itself a signal then it's not stopped.  Even so, 'CONT' is a
signal which can be handled like any other, and we are technically
telling something to continue by using it.  You can still suspend the
process with 'STOP'; the callback queue will be checked on resume due
to the 'CONT' signal, but this is harmless.

The primary advantage of 'CONT' is simply that nothing else is likely
to use it.  If it's too exotic for your tastes, select a conventional
user signal instead.  Just ensure that nothing else installs a %SIG
handler for the chosen signal.

Note also that Perl's support for thread-specific signals is poor.
The signals built into the threads module are not real OS signals and
do not interrupt system calls.  This generally won't work with event
loops, so this module uses a plain C<kill()> to send real OS signals.
Such process-based signals can be delivered to any thread, however, so
worker threads block nearly all the available signals, leaving signal
processing to the main thread: see L</"safe_create_thread">.  If you
start any other threads, you should at least block the callback signal
there as well, or risk callbacks being delayed or lost.

If you use L<threads::posix> instead of L<threads>, the kill method is
a real thread-specific signal, and the callback signal will be sent to
the main thread specifically instead of the whole process.

This module is designed to handle its own signals: significant effort
has been invested to ensure that the callback process is safe and free
of race conditions.  If using an event loop which handles signals,
ensure that it does not interfere with the signal used for callbacks.
Note that pure Perl event loops are likely to contain race conditions:
see L</"Async Adaptors">.  L<EV> is recommended.

=head2 Limitations of Signal Handlers

You can safely call thread subs with no qlim from signal handlers, and
you can safely set a callback on that result.  Some L</"FUNCTIONS">
are also safe to call in a signal handler, or at least the callback
signal handler.  Such safety is explicitly mentioned where available.

That's the good news; read on for the bad news.

Programming within the limitations of signals and callbacks does not
scale well, so you should plan to integrate with an event loop in any
serious project, using callbacks only to set up event loop work.  That
said, be aware of the following issues if using this module without an
event loop, because you're exposing yourself to parallelism headaches
you could otherwise avoid.

Callbacks generally execute in a signal handler context, so it's
important to know what that entails.  The key thing to understand is
that signals interrupt something, and you have no idea what.  Blocking
in such a context is generally unsafe: the code you interrupted may
hold locks which are in turn blocking other things, and deadlock can
result.  As such, the first rule is don't block, and try to be quick.
Thread subs with a qlim can block, so calling one in a signal handler
is risky.  If you're using thread-based locking, don't lock anything
that could violate your lock acquisition ordering rules, or deadlock
may occur.

The asynchronous nature of signals can turn normal code into critical
sections.  A critical section is any section of code which contains
intermediate states that would be a problem if exposed.  In parallel
programming, such exposure is normally prevented using a lock which
ensures that only one thread can be inside such a section at any given
time.  Alas, the thread-based techniques do not work for signals, and
Perl's native tools for signal management do not include a way to mark
a section as unsafe for interruption, so signal handlers can execute
in the middle of a critical section.  This becomes a problem if the
handler code then interacts with that intermediate data.

Examples of such critical sections exist in this module.  For example,
the "result" object has C<< ->send >> and C<< ->croak >> methods to
set the result, and there is more than one step involved in getting an
object from the pending to ready states.  If a signal interrupts the
code part-way through a set operation, the entire object is unsafe to
use in the associated signal handler.  This would render the module
completely unsafe, of course, so the critical sections are guarded
with temporary signal handlers which postpone callback processing.

This only makes the object safe in the callback handler, however: in
other signal handler contexts, the object remains unsafe.  There are
special cases where it is safe, though: result objects created inside
a signal handler, such as by any call to a thread sub, are known to be
in a valid state.  The shim code which sends the request and creates
the object is also signal-safe (modulo the qlim caveat).  As such, you
may safely invoke thread subs in any signal handler, but result
objects created elsewhere are only safe in the callback handler.

The important thing to note, however, is that you can easily create
critical sections of your own unintentionally.  If your callbacks or
signal handlers share any data with the main context, including via
subs with static data, you run the risk of turning otherwise valid
code into unguarded critical sections.  As such, it's best to keep
callbacks and signal handlers extremely simple, and ensure that any
manipulation of shared data uses atomic operations like C<push @x, $y>
or C<$x++> which leave no invalid intermediate state that would be a
problem if an ill-timed signal exposed it.

Event loop programming can seem awkward, but this is the kind of Hell
from which it is saving you.

=head2 Signals in Workers

Worker threads should only make limited use of signals, such as PIPE,
and do so by using C<local> on the relevant handler.  Most signals are
blocked by default in workers: see L</"safe_create_thread">.  Worker
threads can't use callbacks, so thread subs are not appropriate for
use in worker signal handlers in most cases, but they are safe to call
if they have no qlim.

A future version of this module may use a worker signal to cancel subs
which are in progress.

=head2 Operating Without Signals

If you really can't use the callback signal at all, you can disable it
with C<Thread::Subs::signal('')> before starting workers, but you will
need to poll C<Thread::Subs::result::run_callback_queue()> via some
other mechanism (like an event loop timer) in this case for callbacks
to work.  It is not safe to call it from a signal handler in this way.

=head1 NOTES

=head2 Version Compatibility

This module requires Perl v5.14 or higher.  The recommended minimum is
v5.18, however, as it's possible to cause thread-related segfaults in
earlier versions from reasonable code.  As of Perl v5.22, all the
dependencies of this module are included in the core.

=head2 Use Cases

Dispatching subs to separate threads carries a fair bit of overhead
compared to normal in-thread calls, but there are some compelling use
cases which make the cost worth it.  These scenarios represent good
opportunities to improve throughput.

Ultimately there is no substitute for empirical testing when trying
to determine whether threaded subs improve your performance or not,
but these guidelines will help you to find the low-hanging fruit.

=head3 CPU-Intensive Work

The first case is CPU-intensive work which can be parallelised for
speed.  Multi-core CPUs are common now, so parallelism can pay big
dividends.  CPU-bound work should generally be applied to a single
pool which is slightly smaller than your total CPU count, the intent
being to ensure there is spare CPU for other activities.

A more sophisticated approach is to adjust thread priority, lowering
the priority of CPU-bound code, but this is not easy to do portably.
If you happen to be using Linux, the L<POSIX> C<nice()> function can
be used to temporarily lower the priority of a thread, even though the
POSIX standard says it should operate on the whole process.

=head3 Resource Pools

A second use case is exemplified by database interaction.  A common
pattern is that of a web-based application with information in a
database.  On the one side there are many concurrent clients, and on
the other there are limited database connection resources.  A thread
pool offers a good solution to this mismatch, since it allows a large
number of event-driven clients in the main thread access to a limited
pool of database workers, each with its own connection.  Idle database
connections are minimised.

The fact that each thread has its own copy of the global space can be
quite useful in this context.  Each of the DB worker threads can do
its own lazy-open on the database, caching the handle while valid,
just as one might in a single-threaded application.

=head3 The Power of One

Lastly, do not overlook the utility of dedicated specialist workers.
At first glance, "clim=1" may seem like it defeats the whole purpose
of threads, but it actually has a lot to offer.  Parallelism can be
much easier to manage in such a localised manner.  A simple example is
a log-writing thread: you likely want to emit log messages at various
points in your code without delaying the primary task, and this is a
good case for a specialist threaded sub because the concurrency limit
means you never have overlapping writes.

Specialists in a dedicated pool of one ("clim=1, pool=SUB") are able
to maintain state with almost no limitations.  The same worker always
executes the sub, so it has the entire interpreter context to itself,
acting more like a dedicated sub-program.  Subs with "clim=1" in a
larger pool don't get this level of convenience: they can store state
in shared variables without additional locking if the variables are
private to the sub, but they are still subject to the usual limits of
shared variables (e.g. no filehandles).

In short, the "clim=1" pattern gives you some parallelism at almost no
complexity cost.  It is the equivalent of wrapping the entire sub in a
critical section without the drawback of potentially blocking other
threads which want to perform the same operation, because requests are
queued unless they hit the queue limit.  It is a compromise which
offers the best of both worlds and has many practical uses.

=head3 Bad Ideas

Very short-running subs called with high frequency are the worst kind
of thing to delegate to workers.  You not only pay a significant cost
in overhead for the call, but will probably pay even more because of
contention for the associated locks.

Having said that, the frequency must be very high and the execution
time must be very short for it to be a bad idea.  If a sub takes one
millisecond to execute, the theoretical maximum synchronous call rate
is one thousand per second.  This is still well within the bounds
where parallelism can increase the throughput.

=head2 Quirks of Sub Names

The dispatch mechanism passes a fully qualified sub name to the
worker, which then invokes the sub using a symbolic reference.  As
such, subs must appear in the global symbol table to be executable in
this way.  Depending on how the sub was created, however, its "name"
may or may not match its global symbol entry.  Subs declared using the
"sub" keyword and a name will be fine, but if you create a sub by
assigning a CODE reference to a glob, the "name" is a property of the
CODE reference, not the glob.  A lot of importing happens this way.

What this means, in simple terms, is that using a CODE reference in a
C<define()> call to select the sub might not work, even if it's a
reference to the global symbol like C<\&foo>.  If it was created using
an alias, like C<*foo = \&bar;>, the "name" will be the name of the
original sub, which may or may not work.  Using a plain string is the
safer approach.  The usual argument against it is that there is no
compile-time checking of the name, but run-time checking is performed
by C<define()> fairly early in the process lifecycle, and that's just
as good if the name is stored in a constant or similar.

=head2 Limitations and Workarounds

Thread subs can't receive or return the more esoteric data types such
as globs, code refs, or C<qr//> regexes.  The glob limitation affects
filehandles, so you'll need to make special arrangements for files.

The simplest approach is to pass filenames instead of handles, though
this may result in excessive opening and closing if done naively.  A
good cheat is to have a dedicated worker assigned to a set of subs
that deal with a particular file.  The worker is then able to store
related state in global variables without difficulty.  A dedicated
package suits this pattern well.

You can also pass C<fileno()> file descriptors rather than file names
if they are real OS-based files.

=head2 Objects

Passing objects back and forth between threaded subs may or may not
work, as it depends on the object implementation.  Also, if the object
is not already shared when passed, you'll pass a shared clone, which
may not have the desired effect.  The safest approach is to make an
explicit shared clone of the object and use that.

It's possible to design an object such that some methods are threaded
subs, should you wish to do that.  The object must constrain itself to
the limits of L<threads::shared> data, return a shared reference from
the new() method, and share any data stored outside the object itself.
You are then at liberty to make method subs threaded as appropriate,
but it may become confusing if threaded and non-threaded methods call
each other because of shimming.  For simplicity, non-threaded methods
should not call threaded ones; the rule is then that all internal
calls are synchronous: only clients use the async interface.

Rather than construct a fully thread-aware package, it may be simpler
to construct some threaded wrappers around an otherwise synchronous
object, particularly if concurrency limits eliminate the need for
additional locking.  Consider your options.

=head2 Original or Shim?

If you are deploying shims to replace the original subs, the original
interface still applies in certain contexts.  First and foremost, it
applies from any code which runs in a worker, which means code inside
any threaded sub (including recursive calls).  It could also apply to
a CODE ref taken before shims were deployed.

If you aren't deploying shims, of course, then the original interface
always applies: only CODE references returned by C<shim()> provide the
async interface; all direct calls are synchronous.  If you want the
flexibility of calling some subs both synchronously or asynchronously,
this is the best approach.  You can even assign the shim to a glob to
make it available by name, as in the following example.

    use Thread::Subs 'noshim';
    sub foo :Thread { ... }
    Thread::Subs::startup();
    *foo_async = Thread::Subs::shim(\&foo);
    my $async_result = foo_async(...);
    my @sync_result = foo(...);

An environment containing both auto-shimmed and original subs is
possible but discouraged as it encompasses some confusing edge cases.
For example, consider the following case.

    use threads;
    use Thread::Subs;
    sub foo { ... }
    sub bar { ... }
    Thread::Subs::define(
        \&foo => { shim => 0 },
        \&bar => { shim => 1 },
    );
    Thread::Subs::startup();

Once this code has executed, C<foo()> still refers to the original
sub, but C<bar()> refers to a shim.  What should you do if you want to
call C<bar()> from within C<foo()>?  The normal rule is that you call
it via the original interface, but if C<foo()> is called directly from
the main thread, the shimmed interface will still be current.  If it's
called via a shim, on the other hand, the code executes in a worker
thread which sees the original interface.  This is a mess.

Of course, if you never call C<bar()> from within C<foo()>, then none
of this matters.  Well, not immediately, at least, but it potentially
leaves an open pit into which someone may eventually fall.

=head2 Threads Calling Threads

It's possible for worker threads to call other threaded subs, subject
to some limitations.  Most of the time it's simply best to call other
subs the old fashioned synchronous way, but there are reasonable cases
where you may prefer an asynchronous call, particularly if the sub has
a "clim=1" constraint you may otherwise violate.

The first major rule is that worker threads can only call threaded
subs via a closure returned from C<shim()>.  The C<deploy_shims()>
operation happens after worker threads start, so workers always see
the original global subs, not the shimmed replacements.

The second major rule is that worker threads can only obtain results
via the blocking C<< ->recv >> or C<< ->data >> methods, not callbacks
or any of the methods which rely on them: callbacks are strictly
limited to the main thread.  As such, a shim called in a void context
in a worker thread does not apply the L</"fatal"> method to the
result: exceptions will simply be ignored silently.

Lastly, watch out for potential deadlock situations.  A worker that
blocks waiting for other workers is a potential source of deadlock,
and it's on you to ensure the potential can't become reality.  This
potential is amplified greatly if you call a sub with a "qlim" limit,
so avoid that scenario unless you can prove it safe.

Bear in mind that calls to shims start to fail when L</"stop_workers">
is invoked, and this will impact thread-to-thread calls, so using this
pattern is likely to add complexity to the shutdown process.

=head1 SEE ALSO

=head2 Enhancements

L<threads::posix> enhances L<threads> to use real signals instead of
pseudo-signals.  Replace C<use threads> with C<use threads::posix> in
your code, and this module will auto-detect it.  Recommended if you're
creating additional threads and using signals to coordinate them.

This module has built-in support for L<AnyEvent>, L<Mojolicious> (via
L<Mojo::Promise>), and L<Future> async interfaces.  It doesn't depend
on any of them, however: the associated functionality is available if
the relevant module is already loaded.

This module contains comments suitable for L<Debug::Comments>.  If you
want debug output which shows dispatching and callback activity, you
can produce it if L<Debug::Comments> is available and the environment
variable "DEBUG_THREAD_SUBS" is set to a true value.

Exception messages are produced by L<Carp> C<croak()> if it is already
loaded, or by plain old C<die()> with no line numbers if not.  Error
messages may be more informative if you use L<Carp>.

=head2 Alternatives

L<Thread::Pool> is a mature alternative to this module which requires
much more active management of the workers and offers no syntactic
sugar, but it is more appropriate if you need dynamic worker pools.

L<Parallel::ForkManager> provides process-based parallelism, which
avoids the limitations of shared memory but incurs higher overhead per
task.  Suitable for coarse-grained work with fully independent tasks.

L<MCE> (Many-Core Engine) is a comprehensive parallel processing
ecosystem offering both thread and process-based parallelism with many
options for data flow and coordination.  It is considerably more
powerful and correspondingly more complex than this module.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Brett Watson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
