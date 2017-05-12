##==============================================================================
## Tk::Task - allow multiple tasks to proceed at once
##==============================================================================
## Copyright 2002 Kevin Michael Vail.  All rights reserved.
## This program is free software.  You may redistribute and/or modify it
## under the same terms as Perl itself.
##==============================================================================
## $Id: Task.pm,v 1.1 2002/10/24 01:12:14 kevin Exp $
##==============================================================================
require 5.005_62;

package Tk::Task;
use strict;
use Tk;
use Tie::StrictHash;
use Carp;
use Exporter ();
use vars qw($VERSION @ISA @EXPORT);
($VERSION) = q$Revision: 1.1 $ =~ /^Revision:\s+(\S+)/ or $VERSION = "0.0";
@ISA = qw(Exporter);
@EXPORT = qw(TASK TASKPARM TASKQUEUE);

package Tk::Task::Instance;
use strict;
use Tk;
use Tie::StrictHash;

package Tk::Task::Queue;
use strict;
use Tk;
use Tie::StrictHash;
use Carp;

package Tk::Task::Step;
use strict;
use Tie::StrictHash;

package Tk::Task::Step::Method;
use strict;
use vars qw(@ISA);
@ISA = qw(Tk::Task::Step);

package Tk::Task::Step::Subroutine;
use strict;
use vars qw(@ISA);
@ISA = qw(Tk::Task::Step);

package Tk::Task::Step::Loop;
use strict;
use vars qw(@ISA);
@ISA = qw(Tk::Task::Step);

=head1 NAME

Tk::Task - allow multiple "tasks" to proceed at once

=head1 SYNOPSIS

	use Tk::Task;
	
	$mw = MainWindow->new;
	...
	$task = $mw->Task(
	    [
	        sub {
	           OpenCursor();
	        }
	    ],
	    [
	        [
	            sub {
	                my $task = shift;
	                if (FetchFromCursor()) {
	                    AddToTree;
	                } else {
	                    $task->break;
	                }
	            }
	        ],
	    ],
	    [
	        sub {
	            CloseCursor();
	        }
	    ]
	);
	
	$task->start;

=head1 DESCRIPTION

C<Tk::Task> is a module to allow a lengthy operation to be subdivided into
smaller pieces, with time to process events between pieces.  For example, a
program that loaded a large number of records from a database could make the
load process a task, allowing the program to remain responsive to events--for
example, to handle a Stop button!

The steps of each task are executed at idle time, one step each time, while
"normal" processing (handling the event loop) continues.  You might use a task
to do simple animations such as turning cards over in a game, or for other
purposes. For example, the L<Tk::TriangleTree|Tk::TriangleTree> widget uses a
Tk::Task to animate the disclosure triangle.

A Task is I<not> the same as a thread. It is more like a "poor man's" version
of threading. However, this is often quite good enough.

Each step of the task is a reference to an array which can contain one of the
following:

=over 4

=item C<< [ \&subroutine, I<@args> ] >>

A reference to a subroutine causes that subroutine to be called with the rest
of the elements of the array as parameters.

=item C<< [ 'method' => $object, I<@args> ] >>

A string is treated as a method; the class or object associated with the
method must be the second element of the array, and any other elements are
passed as parameters.

=item C<< [ [ ... ], [ ... ], ... ] >>

A reference to an array indicates a loop.  The steps within the outer array
are repeated until one of them calls the B<break> method, at which time the
first step after the outer array is executed.

=back

For example, the task structure shown in the L</SYNOPSIS> shows a task that
opens a database cursor, fetches each row and adds it to a tree, and then
closes the cursor and ends the task when there are no more rows to be
fetched.

There are three pseudo-arguments that can be specified when defining task steps.
These are exported by default.

=over 4

=item C<< TASK >>

This is replaced with a reference to the task object itself when the task
step runs.  This is necessary to allow the step to call the B<break> or
B<repeat> methods.

=item C<< TASKPARM(I<$name>) >>

This is replaced by the named parameter when the task step runs.  Parameters
are set when the task is started, or can be added later using the B<parameter>
method.

=item C<< TASKQUEUE >>

This is replaced by a reference to the queue containing the currently executing
task.

=back

=head2 Queues

Tasks are useful enough by themselves, but it is also possible to make a queue
of tasks.  Tasks can be added dynamically to the end of the queue, and will
execute when all tasks in front of them have executed.

=head1 METHODS

=head2 Task Methods

=over 4

=item I<$task> = I<$mw>->Task(I<@specifications>);

Creates a new task with the given steps.  This method is actually added to the
MainWindow class.

=cut

package Tk::Task;

##==============================================================================
## new
##==============================================================================
sub Tk::Widget::Task {
	my $mw = shift;

	my $task = new Tie::StrictHash items => [], main => $mw;

	bless $task, 'Tk::Task';
	$task->_process($task->{items}, [ @_ ]);
	return $task;
}

=pod

=item I<$instance> = I<$task>->start(I<parm1> => I<$value1>, ...);

Starts I<$task> executing from the beginning.  The given parameters are made
available to the steps of the task by use of the TASKPARM pseudo-argument.  Any
existing instance of I<$task> is unaffected.

=cut

##==============================================================================
## start
##==============================================================================
sub start {
	my $task = shift;
	my $instance = new Tk::Task::Instance $task, undef, @_;
	$instance->_run;
	return $instance;
}

=pod

=item I<$instance> = I<$task>->queue(I<$queue>, I<parm1> => I<$value1>, ...);

Same as B<start>, but also sets the queue that the instance is on.  This is
meant to be called only by the Tk::Task::Queue methods.

=cut

##==============================================================================
## queue
##==============================================================================
sub queue {
	my $task = shift;
	my $queue = shift;
	my $instance = new Tk::Task::Instance $task, $queue, @_;
	$instance->_run;
	return $instance;
}

##==============================================================================
## Internal Tk::Task methods
##------------------------------------------------------------------------------
## _process
## Convert the input step specifications to instances of Tk::Task::Step.
##==============================================================================
sub _process {
	my ($task, $items, $steps) = @_;

	foreach my $step (@$steps) {
		next unless ref $step eq 'ARRAY';
		my @parms = @$step;
		my $proc = shift(@parms);
		my $refstep = ref $proc;
		unless ($refstep) {
			push @$items, Tk::Task::Step::Method->new($proc, @parms);
		} elsif ($refstep eq 'CODE') {
			push @$items, Tk::Task::Step::Subroutine->new($proc, @parms);
		} elsif ($refstep eq 'ARRAY') {
			my $array = [];
			$task->_process($array, $step);
			push @$items, Tk::Task::Step::Loop->new($array);
		} else {
			croak "invalid reference type in task step definition - must be CODE or ARRAY";
		}
	}
}

##------------------------------------------------------------------------------
## _mainwindow
## Returns the main window associated with this task.  Called by Instance::new.
##------------------------------------------------------------------------------
sub _mainwindow {
	my $task = shift;
	return $task->{main};
}

##------------------------------------------------------------------------------
## _items
## Returns the list of items associated with this task.  Called by
## Instance::new.
##------------------------------------------------------------------------------
sub _items {
	my $task = shift;
	return $task->{items};
}

##==============================================================================
## Definitions of the pseudo-arguments TASK, TASKPARM, and TASKQUEUE.
##==============================================================================
sub _DummyProcTask {};
sub _DummyProcTaskParm {};
sub _DummyProcTaskQueue {};

sub TASK { \&_DummyProcTask };
sub TASKPARM { ( \&DummyProcTaskParm, $_[0]) };
sub TASKQUEUE { \&DummyProcTaskQueue };

=pod

=back

=head2 Instance Methods

A task instance is created automatically when you start a task.  This allows
each task to be executing multiple copies at the same time, without interfering
with one another.

=over 4

=item I<$instance>->repeat;

Prevents the instance from advancing to the next step; when the task is due to
run again, it will repeat the current step.

=cut

package Tk::Task::Instance;

##==============================================================================
## repeat
##==============================================================================
sub repeat {
	my $instance = shift;
	$instance->{repeat} = 1;
	return $instance;
}

=pod

=item I<$instance>->break;

Causes the instance to exit from the innermost loop; the next step executed will
be the one after the end of the loop.  If the current step is not part of a
loop, nothing happens.

=cut

##==============================================================================
## break
##==============================================================================
sub break {
	my $instance = shift;

	if (@{$instance->{stack}}) {
		@{$instance}{qw/current list/} = @{pop(@{$instance->{stack}})};
	}
	return $instance;
}

=pod

=item I<$instance>->cancel;

Causes the instance to stop after the end of the current step.  No further steps
will be executed.  If called from "outside" the task, between steps, then the
next step will never fire.

=cut

##==============================================================================
## cancel
##==============================================================================
sub cancel {
	my $instance = shift;
	$instance->{cancel} = 1;
	return $instance;
}

=pod

=item I<$instance>->delay(I<$milliseconds>);

Causes a delay of I<$milliseconds> between the time the current step finishes
and the next step begins.  Behavior if called from other than within a task step
is undefined.

=cut

##==============================================================================
## delay
##==============================================================================
sub delay {
	my ($instance, $milliseconds) = @_;
	$instance->{delay} = $milliseconds;
	return $instance;
}

=pod

=item I<$value> = I<$instance>->parameter(I<parm_name>);

Returns the value of the particular parameter set when the instance was started,
or changed later.

=item I<$instance>->parameter(I<parm_name> => I<$value>);

Sets the value of the named parameter.  This can be either a change to an
existing parameter or the creation of a new parameter.

=cut

##==============================================================================
## parameter
##==============================================================================
sub parameter {
	my ($instance, $parmname) = splice(@_, 0, 2);
	$instance->{parms}->{$parmname} = shift if @_;
	return $instance->{parms}->{$parmname};
}

##==============================================================================
## Internal Tk::Task::Instance methods
##------------------------------------------------------------------------------
## _fire
## The procedure that actually calls a task step.
##==============================================================================
sub _fire {
	my $instance = shift;

	##--------------------------------------------------------------------------
	## Execute the step at $task->{list}->[$task->{current}].
	##--------------------------------------------------------------------------
	$instance->{id} = undef;
	if ($instance->{current} < 0
	 || $instance->{current} >= @{$instance->{list}}
	 || $instance->{cancel}) {
		$instance->_finish;
		return;
	}
	$instance->{list}->[$instance->{current}]->call($instance);

	##--------------------------------------------------------------------------
	## Figure out which step to execute next, if any.  If they called repeat,
	## it will be the same step (actually it just indicates that the current
	## index won't be incremented); otherwise, increment the index and run that
	## step, if possible.  If we fall off the end of the task, just reset the
	## {running} flag and don't start another step.
	##--------------------------------------------------------------------------
	if ($instance->{repeat}) {
		$instance->{repeat} = 0;
	} elsif (++$instance->{current} >= @{$instance->{list}}) {
		if (@{$instance->{stack}}) {
			$instance->{current} = 0;
		} else {
			$instance->_finish;
		}
	}
	$instance->_run if $instance->{running};
}

##------------------------------------------------------------------------------
## _run
## Set up to run the current step.
##------------------------------------------------------------------------------
sub _run {
	my $instance = shift;
	if ($instance->{delay}) {
		$instance->{id} = $instance->{main}->after(
			$instance->{delay}, [ _fire => $instance ]
		);
		$instance->{delay} = 0;
	} else {
		$instance->{id} = $instance->{main}->afterIdle([ _fire => $instance ]);
	}
}

##------------------------------------------------------------------------------
## _finish
## Clean up when a task finishes, and let its queue know if it has one.
##------------------------------------------------------------------------------
sub _finish {
	my $instance = shift;

	$instance->{running} = 0;
	$instance->{queue}->notify($instance) if $instance->{queue};
}

##------------------------------------------------------------------------------
## new
## Create a new instance.  Should only be called from Task::start or Task::queue.
##------------------------------------------------------------------------------
sub new {
	my ($class, $task, $queue) = splice(@_, 0, 3);
	my $instance = new Tie::StrictHash
		task => $task, current => 0, stack => [], list => $task->_items,
		repeat => 0, id => undef, running => 1, delay => 0,
		main => $task->_mainwindow, queue => $queue, cancel => 0,
		parms => { @_ };
	return bless $instance, $class;
}

##------------------------------------------------------------------------------
## _setargs
## Convert the argument array for a task step.
## $instance->_setargs(\@args);
## Can also be called as Tk::Task::Instance->_setargs if no task is involved.
##------------------------------------------------------------------------------
sub _setargs {
	my ($instance, $args) = @_;
	my $queue = $instance->{queue};
	my @args;
	my $tctl0 = Tk::Task::TASK;
	my ($tctl1, undef) = Tk::Task::TASKPARM('x');
	my $tctl2 = Tk::Task::TASKQUEUE;
	my $state = 'regular';

	foreach (@$args) {
		if ($state eq 'parmname') {
			push @args, $instance->parameter($_);
			$state = 'regular';
		} elsif ($_ eq $tctl0) {
			push @args, $instance;
		} elsif ($_ eq $tctl1) {
			$state = 'parmname';
		} elsif ($_ eq $tctl2) {
			push @args, $queue;
		} else {
			push @args, $_;
		}
	}
	return @args;
}

##------------------------------------------------------------------------------
## _push
## $instance->_push($list);
## Save the current list and index within that list, then set the list to the
## given list and start at its beginning.
##------------------------------------------------------------------------------
sub _push {
	my ($instance, $list) = @_;
	push @{$instance->{stack}}, [ @{$instance}{qw/current list/} ];
	$instance->{list} = $list;
	$instance->{current} = 0;
}

=pod

=back

=head2 Queue Methods

=over 4

=item I<$queue> = new Tk::Task::Queue I<%options>;

Creates a new queue.  The following I<options> are supported:

=over 4

=item C<< -finish >>

A callback that is called when all tasks in the queue have been completed.

=item C<< -init >>

A callback that is called whenever a task starts when no task was running
before.

=back

The most common use for these two callbacks is to do something like calling Busy
on the main window when a lengthy task begins, and Unbusy when it ends.

Each callback can be either a reference to a subroutine, which is simply called
with a reference to the queue as its only parameter, or in the form of a task
step.  In the latter case, the TASKQUEUE pseudo-argument must be used to get a
reference to the queue.

=cut

package Tk::Task::Queue;

##==============================================================================
## new
##==============================================================================
sub new {
	my $class = shift;
	my $queue = new Tie::StrictHash
		list => [], current => undef, paused => 0, cancel => 0,
		-finish => undef, -init => undef;

	while (@_) {
		croak "odd number of options passed to $class\::new" if @_ % 2;
		my $name = shift;
		my $value = shift;
		if ($name =~ /^-/ && exists $queue->{$name}) {
			$queue->{$name} = $value;
		} else {
			croak "invalid option to $class\::new: '$name'";
		}
	}
	return bless $queue, $class;
}

=pod

=item I<$queue>->queue(I<$task>, I<parm1> => I<$value1>, ...);

Adds I<$task> to the end of I<$queue>, with the given parameters.  I<$task>
will execute when all tasks in front of it have completed; if there are no
tasks in the queue when this method is called, the task will start executing
immediately.

=cut

##==============================================================================
## queue
##==============================================================================
sub queue {
	my $queue = shift;
	push @{$queue->{list}}, [ @_ ];
	$queue->_dispatch unless $queue->{current} || $queue->{paused};
}

=pod

=item I<$queue>->pause;

Pauses execution of the queue after the current task is complete.  The next
task will not begin until the B<resume> method is called.

=cut

##==============================================================================
## pause
##==============================================================================
sub pause {
	my $queue = shift;
	$queue->{paused} = 1;
	return $queue;
}

=pod

=item I<$queue>->resume;

Resumes execution of the queue.  Nothing happens if the queue isn't paused.

=cut

##==============================================================================
## resume
##==============================================================================
sub resume {
	my $queue = shift;
	if ($queue->{paused}) {
		$queue->{paused} = 0;
		$queue->_dispatch;
	}
	return $queue;
}

=pod

=item I<$queue>->cancel;

Cancels execution of all tasks in the queue after the current one completes.

=cut

##==============================================================================
## cancel
##==============================================================================
sub cancel {
	my $queue = shift;
	$queue->{cancel} = 1;
	return $queue;
}

=pod

=item I<$queue>->abort;

Cancels execution of all tasks in the queue after the current step of the
current task completes.

=cut

##==============================================================================
## abort
##==============================================================================
sub abort {
	my $queue = shift;
	$queue->cancel;
	$queue->{current}->cancel if $queue->{current};
	return $queue;
}

=pod

=item I<$boolean> = I<$queue>->is_empty;

Returns true if there is nothing currently in the queue.  Note that this method
will also return true if called from the last task that was in the queue.

=cut

##==============================================================================
## is_empty
##==============================================================================
sub is_empty {
	my $queue = shift;
	return @{$queue->{list}} == 0;
}

=pod

=item I<$queue>->notify(I<$instance>);

Notifies the queue that the task instance specified by I<$instance> has
completed.  This is called automatically by I<$instance> when it finishes; you
shouldn't ever have to call it directly.  If I<$instance> isn't the instance
that's currently executing, nothing happens.

=cut

##==============================================================================
## notify
##==============================================================================
sub notify {
	my ($queue, $instance) = @_;
	$queue->_dispatch if $queue->{current} eq $instance;
	return $queue;
}

##==============================================================================
## Internal Tk::Task::Queue methods
##------------------------------------------------------------------------------
## _dispatch
## Execute the task at the front of the queue.
##==============================================================================
sub _dispatch {
	my $queue = shift;
	if ($queue->{cancel} || @{$queue->{list}} == 0) {
		$queue->_finish;
	} elsif (!$queue->{paused}) {
		$queue->_call('-init') unless defined $queue->{current};
		my $array = shift @{$queue->{list}};
		my $task = shift @$array;
		$queue->{current} = $task->queue($queue, @$array);
	}
}

##------------------------------------------------------------------------------
## _finish
## Execute the finish callback.
##------------------------------------------------------------------------------
sub _finish {
	my $queue = shift;
	$queue->_call('-finish');
	$queue->{paused}  = 0;
	$queue->{cancel}  = 0;
	$queue->{list}    = [];
	$queue->{current} = undef;
}

##------------------------------------------------------------------------------
## _call
## Call the -init or -finish callback.
##------------------------------------------------------------------------------
sub _call {
	my ($queue, $cbtype) = @_;

	if (my $callback = $queue->{$cbtype}) {
		if (ref $callback eq 'CODE') {
			$callback->($queue);
		} elsif (ref $callback eq 'ARRAY') {
			my @args = @$callback;
			my $proc = shift @args;
			@args = Tk::Task->setargs($queue, @args);
			$proc->(@args);
		} else {
			die "invalid $cbtype callback for " . ref $queue;
		}
	}

	return $queue;
}

################################################################################
## INTERNAL CLASSES
################################################################################
package Tk::Task::Step;

##------------------------------------------------------------------------------
## new
## Create a new task step.
##------------------------------------------------------------------------------
sub new {
	my ($class, $proc) = splice(@_, 0, 2);
	my $step = new Tie::StrictHash proc => $proc, args => [ @_ ];
	bless $step, $class;
}

package Tk::Task::Step::Method;

##------------------------------------------------------------------------------
## call
## Call a method from a step.
##------------------------------------------------------------------------------
sub call {
	my ($step, $instance) = @_;
	my @args = $instance->_setargs($step->{args});
	my $method = $step->{proc};
	my $object = shift(@args);
	$object->$method(@args);
}

package Tk::Task::Step::Subroutine;

##------------------------------------------------------------------------------
## call
##------------------------------------------------------------------------------
sub call {
	my ($step, $instance) = @_;
	my @args = $instance->_setargs($step->{args});
	$step->{proc}->(@args);
}

package Tk::Task::Step::Loop;

##------------------------------------------------------------------------------
## call
##------------------------------------------------------------------------------
sub call {
	my ($step, $instance) = @_;
	$instance->_push($step->{proc});
	$instance->repeat;				## so {current} doesn't get incremented
}

=pod

=back

=head1 DIAGNOSTICS

=over 4

=item invalid -finish callback for Tk::Task::Queue

The C<-finish> callback must be either a code reference or an array reference.

=item invalid reference type in task step definition - must be CODE or ARRAY

A task step that was neither a reference to a subroutine nor a reference to an
array was encountered.

=item odd number of options passed to I<class>::new

Self-explanatory.

=item invalid option to I<class>::new: 'I<name>'

Self-explanatory.

=back

=head1 SEE ALSO

L<Tk::after>

=head1 MODULES USED

L<Tie::StrictHash|Tie::StrictHash>

=head1 CHANGES

=over 4

=item 1.0

First release.

=item 1.1

Allow a Task to be created off of any widget, not just a MainWindow.

=back

=head1 COPYRIGHT

Copyright 2002 Kevin Michael Vail.  All rights reserved.

This program is free software.  You may redistribute and/or modify it under the
same terms as Perl itself.

=head1 AUTHOR

Kevin Michael Vail <kevin@vaildc.net>

=cut

1;

##==============================================================================
## $Log: Task.pm,v $
## Revision 1.1  2002/10/24 01:12:14  kevin
## Allow Task to be created from any widget, not just a MainWindow.
##
## Revision 1.0  2002/03/18 02:29:07  kevin
## Initial revision
##==============================================================================
