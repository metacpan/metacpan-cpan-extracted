package Thread::Task::Concurrent;

use warnings;
use strict;
use 5.010;

my $can_use_threads = $threads::threads;

use threads::shared;

use Thread::Queue;
use Thread::Task::Concurrent::Util qw/unshared_clone/;

my ($tmsg_sub);

if ($can_use_threads) {
    $tmsg_sub = sub { say STDERR '[' . ( $_[1] // threads->tid ) . '] ' . $_[0]; };
} else {
    warn "threads module not loaded, working in serial mode";
    $tmsg_sub = sub { say STDERR '[' . ( $_[1] // "main" ) . '] ' . $_[0]; }
}

use Mouse;

use Mouse::Exporter;

Mouse::Exporter->setup_import_methods( as_is => ['tmsg'] );

our $VERSION = 0.01_05;

has queue         => ( is => 'rw' );
has task          => ( is => 'rw', required => 1 );
has arg           => ( is => 'rw' );
has max_instances => ( is => 'rw', default => 4 );
has threads       => ( is => 'rw' );
has verbose       => ( is => 'rw' );
has result_queue  => ( is => 'rw' );
has finished      => ( is => 'rw' );
has _start_time   => ( is => 'rw' );
has _real_task    => ( is => 'rw' );

sub BUILD {
    my ($self) = @_;

    my $q = Thread::Queue->new();
    $self->queue($q);

    $self->result_queue( Thread::Queue->new() );
}

{
    my $enqueue_finished : shared;
    my $wait : shared;
    my $tasks_running : shared;

    sub start {
        my ($self) = @_;

        tmsg( "starting", "main" ) if ( $self->verbose );
        $self->_start_time(time);

        my $q  = $self->queue;
        my $rq = $self->result_queue;

        my $task = $self->task;
        my $arg  = $self->arg;

        $tasks_running = 0;

        my $real_task = sub {
        ELEMENT:
            while (1) {
                {
                    lock($enqueue_finished);
                    if ( $enqueue_finished && $q->pending == 0 ) {
                        #broadcast as much as possible, so no thread gets stuck
                        lock($wait);
                        cond_broadcast($wait);
                        last ELEMENT;
                    }
                }

                my $i = $q->dequeue_nb;
                unless ( defined($i) ) {
                    lock($wait);
                    cond_wait($wait);
                    next ELEMENT;
                }
                {
                    lock($tasks_running);
                    $tasks_running++;
                }

                tmsg("running task ...") if ( $self->verbose );
                my @result = $task->( $i, $arg );
                $rq->enqueue(@result) if ( @result && @result > 0 );

                {
                    lock($tasks_running);
                    $tasks_running--;

                    tmsg( "task done, tasks running: " . $tasks_running . ", pending: " . $q->pending )
                        if ( $self->verbose );
                }
            }
        };

        $self->_real_task($real_task);
        my @threads;
        for ( my $i = 0; $i < $self->max_instances; $i++ ) {
            # early exit if no threads are loaded/supported
            last unless ($can_use_threads);
            push @threads, threads->create($real_task);

        }
        $self->threads( \@threads );

        return $self;
    }

    sub join {
        my ($self) = @_;

        {
            lock($enqueue_finished);
            $enqueue_finished = 1;
        }

        my $threads = $self->threads;
        for my $t (@$threads) {

            #broadcast as much as possible, so no thread gets stuck
            {
                lock($wait);
                cond_broadcast($wait);
            }
            tmsg( "waiting for thread " . $t->tid, 'main' ) if ( $self->verbose );
            $t->join;
            tmsg( "thread " . $t->tid . " joined successfully", 'main' ) if ( $self->verbose );
        }

        #execute task if we have no thread support (@$threads is empty)
        $self->_real_task->() unless ($can_use_threads);

        $self->finished(1);
        tmsg( "time: " . sprintf( "%dd %dh %dm %ds", ( gmtime( time - $self->_start_time ) )[ 7, 2, 1, 0 ] ),
            'main' )
            if ( $self->verbose );
        $self;
    }

    sub enqueue {
        my ($self) = shift;

        $self->queue->enqueue(@_);
        lock($wait);
        cond_broadcast($wait);
        return $self;
    }

    sub result {
        my ($self) = @_;

        $self->join
            unless ( $self->finished );
        my $rq = $self->result_queue;
        my @results;
        while ( defined( my $item = $rq->dequeue_nb ) ) {
            push @results, unshared_clone($item);
        }

        if ( @results && @results > 0 ) {
            return \@results;
        } else {
            return;
        }
    }
}

sub tmsg { return $tmsg_sub->(@_); }

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Thread::Task::Concurrent - Make simple task pocessing simple

=head1 SYNOPSIS

    use Thread::Task::Concurrent qw(tmsg);

    my @data = qw(a b c d e f g h i j k l m n o p q);

    my $tq = Thread::Task::Concurrent->new( task => \&task, max_instances => 4, verbose => 1 );
    my $result = $tq->enqueue(@data)->start->join->result;

    sub task {
        my $char = shift;

        # sleep some time
        my $sleep_time = int rand 10;
        sleep $sleep_time;

        #calculate result
        my $result = "I'm thread " . threads->tid . " and I slept $sleep_time sec. My result was " . $char x 3;

        return $result;
    }

=head1 DESCRIPTION

If you have input data and you want to pocess it in the same way,
L<Thread::Task::Concurrent> gives you an easy to use interface to
getthingsdone(TM).

=head1 SUBROUTINES

=over 4

=item B<< tmsg($string_message) >>

=item B<< tmsg($string_message, $tid_to_display) >>

Spits out the C<$string_message> in the form:

    [thread_id] <message>

thread_id is by default C<< threads->tid >>, but you can also set it artificially
via the C<$tid_to_display> variable.

=back

=head1 METHODS

=over 4

=item B<< Thread::Task::Concurrent->new(%arg) >>

=over 4

=item task => sub { ... }

Set the subroutine for the task. Example:

    sub {
        my ($item, $task_arg) = @_;
        
        return $result_item;
    }

=item arg => $task_arg

Add an additional arg hash/array/scalar to the task/subroutine call.

=item max_instances => 4

Set the maximum number of threads. Default is 4.

=item verbose => 0

Switch on/off verbose reporting.

=back

=item B<< $ttc = $ttc->start() >>

Start processing.

=item B<< $ttc = $ttc->join() >>

Wait for processing end.

=item B<< $ttc = $ttc->enqueue(@data) >>

Enqueue items.

=item B<< $ttc = $ttc->result() >>

Gather the result.

=back

=head1 ACCESSORS

=over 4

=item B<< $q = $ttc->queue >>

=item B<< $rq = $ttc->result_queue >>

=item B<< $task_code_ref = $ttc->task >>

=item B<< $task_arg = $ttc->arg >>

=item B<< $num = $ttc->max_instances >>

=item B<< $threads = $ttc->threads >>

=item B<< $is_verbose = $ttc->verbose >>

=item B<< $is_finished = $ttc->finished >>

=back

=head1 SEE ALSO

-

=head1 AUTHOR

jw bargsten, C<< <cpan at bargsten dot org> >>

=cut
