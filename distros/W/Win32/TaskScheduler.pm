package Win32::TaskScheduler;

use 5.006;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use TaskScheduler ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '2.0.3';

#variables exported to user scope
use constant TASK_SUNDAY=>1;
use constant TASK_MONDAY=>2;
use constant TASK_TUESDAY=>4;
use constant TASK_WEDNESDAY=>8;
use constant TASK_THURSDAY=>16;
use constant TASK_FRIDAY=>32;
use constant TASK_SATURDAY=>64;
use constant TASK_FIRST_WEEK=>1;
use constant TASK_SECOND_WEEK=>2;
use constant TASK_THIRD_WEEK=>3;
use constant TASK_FOURTH_WEEK=>4;
use constant TASK_LAST_WEEK=>5;
use constant TASK_JANUARY=>1;
use constant TASK_FEBRUARY=>2;
use constant TASK_MARCH=>4;
use constant TASK_APRIL=>8;
use constant TASK_MAY=>16;
use constant TASK_JUNE=>32;
use constant TASK_JULY=>64;
use constant TASK_AUGUST=>128;
use constant TASK_SEPTEMBER=>256;
use constant TASK_OCTOBER=>512;
use constant TASK_NOVEMBER=>1024;
use constant TASK_DECEMBER=>2048;
use constant TASK_FLAG_INTERACTIVE=>1;
use constant TASK_FLAG_DELETE_WHEN_DONE=>2;
use constant TASK_FLAG_DISABLED=>4;
use constant TASK_FLAG_START_ONLY_IF_IDLE=>16;
use constant TASK_FLAG_KILL_ON_IDLE_END=>32;
use constant TASK_FLAG_DONT_START_IF_ON_BATTERIES=>64;
use constant TASK_FLAG_KILL_IF_GOING_ON_BATTERIES=>128;
use constant TASK_FLAG_RUN_ONLY_IF_DOCKED=>256;
use constant TASK_FLAG_HIDDEN=>512;
use constant TASK_FLAG_RUN_IF_CONNECTED_TO_INTERNET=>1024;
use constant TASK_FLAG_RESTART_ON_IDLE_RESUME=>2048;
use constant TASK_FLAG_SYSTEM_REQUIRED=>4096;
use constant TASK_TRIGGER_FLAG_HAS_END_DATE=>1;
use constant TASK_TRIGGER_FLAG_KILL_AT_DURATION_END=>2;
use constant TASK_TRIGGER_FLAG_DISABLED=>4;
use constant TASK_MAX_RUN_TIMES=>1440;
use constant REALTIME_PRIORITY_CLASS=>256;
use constant HIGH_PRIORITY_CLASS=>128;
use constant NORMAL_PRIORITY_CLASS=>32;
use constant IDLE_PRIORITY_CLASS=>64;
use constant INFINITE=>-1;
use constant TASK_TIME_TRIGGER_ONCE=>0;
use constant TASK_TIME_TRIGGER_DAILY=>1;
use constant TASK_TIME_TRIGGER_WEEKLY=>2;
use constant TASK_TIME_TRIGGER_MONTHLYDATE=>3;
use constant TASK_TIME_TRIGGER_MONTHLYDOW=>4;
use constant TASK_EVENT_TRIGGER_ON_IDLE=>5;
use constant TASK_EVENT_TRIGGER_AT_SYSTEMSTART=>6;
use constant TASK_EVENT_TRIGGER_AT_LOGON=>7;

bootstrap Win32::TaskScheduler $VERSION;

# Preloaded methods go here.

1;
__END__

=head1 NAME

Win32::TaskScheduler - Perl extension for managing Win32 jobs scheduled via Task Scheduler

=head1 SYNOPSIS

	#################################################
	# Example 1. How to get/set account information for a task  
	#
	use Win32::TaskScheduler;

	$scheduler = Win32::TaskScheduler->New();
	$scheduler->Activate("My scheduled job");

	$runasuser=$scheduler->GetAccountInformation();
	die "Cannot set username\n" if (! $scheduler->SetAccountInformation('administrator','secret'));
	die "Cannot save changes username\n" if (! $scheduler->Save());

	#Release COM stuff (Optional)
	$scheduler->End();

	#################################################
	# Example 2. Create a task.
	#
	use Win32::TaskScheduler;

	$scheduler = Win32::TaskScheduler->New();

	#
	# This adds a daily schedule.
	#
	#%trig=(
	#	'BeginYear' => 2001,
	#	'BeginMonth' => 10,
	#	'BeginDay' => 20,
	#	'StartHour' => 14,
	#	'StartMinute' => 10,
	#	'TriggerType' => $scheduler->TASK_TIME_TRIGGER_DAILY,
	#	'Type'=>{
	#		'DaysInterval' => 3,
	#	},
	#);

	#
	# And this a monthly one, for first and last week.
	#
	%trig=(
		'BeginYear' => 2001,
		'BeginMonth' => 10,
		'BeginDay' => 20,
		'StartHour' => 14,
		'StartMinute' => 10,
		'TriggerType' => $scheduler->TASK_TIME_TRIGGER_MONTHLYDOW,
		'Type'=>{
			'WhichWeek' => $scheduler->TASK_FIRST_WEEK | $scheduler->TASK_LAST_WEEK,
			'DaysOfTheWeek' => $scheduler->TASK_FRIDAY | $scheduler->TASK_MONDAY,
			'Months' => $scheduler->TASK_JANUARY | $scheduler->TASK_APRIL | $scheduler->TASK_JULY | $scheduler->TASK_OCTOBER,
		},
	);

	#
	# Execute this task every 10th of january,april,july,october
	#
	# Please note that days are given in the conventional form 1,2,30,25 not
	# what m$ says in theyr APIs. This is the only exception to m$ APIs.
	#
	#%trig=(
	#	'BeginYear' => 2001,
	#	'BeginMonth' => 10,
	#	'BeginDay' => 20,
	#	'StartHour' => 14,
	#	'StartMinute' => 10,
	#	'TriggerType' => $scheduler->TASK_TIME_TRIGGER_MONTHLYDATE,
	#	'Type'=>{
	#		'Months' => $scheduler->TASK_JANUARY | $scheduler->TASK_APRIL | $scheduler->TASK_JULY | $scheduler->TASK_OCTOBER,
	#		'Days' => 10,
	#	},
	#);

	$tsk="alfred";

	foreach $k (keys %trig) {print "$k=" . $trig{$k} . "\n";}

	$scheduler->NewWorkItem($tsk,\%trig);
	$scheduler->SetApplicationName("winword.exe");

	$scheduler->Save();


=head1 DESCRIPTION

Win32::TaskScheduler is an extension which lets you manipulate Scheduled
Tasks in Perl.

Since release 2.0.0 Win32::TaskScheduler breaks backward compatibility with scripts
which worked with earlier versions, because of a more object oriented
approach.
One of the major advantages of this approach is that you can have more than one
scheduled task 'activated' at once (copying should be easier then) and that you
don't have to type all that Win32::TaskScheduler::SomeLongMethodName stuff.

Also, I believe this is more compliant to Perl standards.
Please note that if you're happy with the old syntax you can skip upgrading since
there are no new methods nor bugfixes.

With releases in the 1.x.x series when you told Perl to use Win32::TaskScheduler
the package would automatically instantiate a COM object to let you manipulate tasks.

Now you must do that manually by calling Win32::TaskScheduler->New(). See the examples
below.

To change or view a job's settings you must Activate() it and then, until you call
another Activate() or Save() or End() , the package will continue to use that
job as the primary subject for all of the following actions.
If you modify a job's settings and need it saved then you must call Save() .
If you need to remodify that job you must call Activate() again.

The End() method releases all COM instances.

=head2 CONSTANTS

TASK_SUNDAY

TASK_MONDAY

TASK_TUESDAY

TASK_WEDNESDAY

TASK_THURSDAY

TASK_FRIDAY

TASK_SATURDAY

TASK_FIRST_WEEK

TASK_SECOND_WEEK

TASK_THIRD_WEEK

TASK_FOURTH_WEEK

TASK_LAST_WEEK

TASK_JANUARY

TASK_FEBRUARY

TASK_MARCH

TASK_APRIL

TASK_MAY

TASK_JUNE

TASK_JULY

TASK_AUGUST

TASK_SEPTEMBER

TASK_OCTOBER

TASK_NOVEMBER

TASK_DECEMBER

TASK_FLAG_INTERACTIVE

TASK_FLAG_DELETE_WHEN_DONE

TASK_FLAG_DISABLED

TASK_FLAG_START_ONLY_IF_IDLE

TASK_FLAG_KILL_ON_IDLE_END

TASK_FLAG_DONT_START_IF_ON_BATTERIES

TASK_FLAG_KILL_IF_GOING_ON_BATTERIES

TASK_FLAG_RUN_ONLY_IF_DOCKED

TASK_FLAG_HIDDEN

TASK_FLAG_RUN_IF_CONNECTED_TO_INTERNET

TASK_FLAG_RESTART_ON_IDLE_RESUME

TASK_FLAG_SYSTEM_REQUIRED

TASK_TRIGGER_FLAG_HAS_END_DATE

TASK_TRIGGER_FLAG_KILL_AT_DURATION_END

TASK_TRIGGER_FLAG_DISABLED

TASK_MAX_RUN_TIMES

REALTIME_PRIORITY_CLASS

HIGH_PRIORITY_CLASS

NORMAL_PRIORITY_CLASS

IDLE_PRIORITY_CLASS

INFINITE

TASK_TIME_TRIGGER_ONCE

TASK_TIME_TRIGGER_DAILY

TASK_TIME_TRIGGER_WEEKLY

TASK_TIME_TRIGGER_MONTHLYDATE

TASK_TIME_TRIGGER_MONTHLYDOW

TASK_EVENT_TRIGGER_ON_IDLE

TASK_EVENT_TRIGGER_AT_SYSTEMSTART

TASK_EVENT_TRIGGER_AT_LOGON

=head2 METHODS

=head3 New()

Initialize COM objects that make it possible to access the Scheduler API and
returns a hash blessed into the Win32::TaskScheduler package.
Must be called again after a call to End() .

=head3 $result End()

Uninitialize COM objects that make it possible to access the Scheduler API.
To use this package after a call to End you must call New() .

=head3 @jobs Enum()

Returns an array filled with the names of the jobs on the targeted computer or
undef in case of failure.

=head3 $result Activate($jobName)

Sets the job on which the package will operate from now on.
The name must be without the .job extension and result will be:

=over

=item *

0 in case of failure

=item *

1 in case of success.

=back

=head3 $result SetTargetComputer($hostName)

Sets the host on which the package will operate from now on.
The name must be a valid UNC name (e.g.: \\myhost). Result will be:

=over

=item *

0 in case of failure

=item *

1 in case of success.

=back

=head3 $result SetAccountInformation($usr,$pwd)

Set account information for the currently active job. To schedule the job to run
as the System account specify the empty string for both username and password.
Return value will be:

=over

=item *

1 in case of success

=item *

0 in case of access denied

=item *

-1 in case an invalid argument is supplied

=item *

-2 out of memory

=item *

-3 the remote host does not support security services

=item *

-4 unspecified error

=back

=head3 $user GetAccountInformation()

Returns the username for the currently active job or undef
in case of error.

=head3 $result SetApplicationName($appname)

Sets the command that will be executed at the time specified for this
scheduled task.
Result will be:

=over

=item *

0 in case of failure

=item *

1 in case of success.

=back

=head3 $result GetApplicationName()

Gets the command that will be executed at the time specified for this
scheduled task.
Result will be:

=over

=item *

undef in case of failure

=item *

application name in case of success.

=back

=head3 $result SetParameters($param)

Sets the parameters passed to the command that will be executed at the time specified for this
scheduled task.
Result will be:

=over

=item *

0 in case of failure

=item *

1 in case of success.

=back

=head3 $result GetParameters()

Gets the parameters passed to the command that will be executed at the time specified for this
scheduled task.
Result will be:

=over

=item *

undef in case of failure

=item *

parameter, in case of success.

=back

=head3 $result SetWorkingDirectory($param)

Sets the working directory for this
scheduled task.
Result will be:

=over

=item *

0 in case of failure

=item *

1 in case of success.

=back

=head3 $dir GetWorkingDirectory()

Gets the working directory for this
scheduled task.
Result will be:

=over

=item *

undef in case of failure

=item *

parameter, in case of success.

=back

=head3 $result GetPriority($priority)

Gets the priority associated with the currently selected task.

=head3 $result SetPriority($priority)

Sets the priority associated with the currently selected task.

=head3 $result Delete($name)

Deletes the task with the specified name.

=head3 $result NewWorkItem($name,\%trigger)

Attempts to allocate a new job and to set a trigger for that job. Please note that this
method does not check for name conflicts and does not set the application to be run.
To accomplish that you must call SetApplicationName() and SetWorkingDirectory() .
Also remember to call Save() .
See examples for how to use this method.

It returns:

=over

=item *

0 if it cannot allocate a new trigger for the task

=item *

-1 if the trigger supplied by the user is not valid


=item *

1 in case of success.

=back


=head3 $result Save()

Saves the currently active task to disk, so that changes are put in effect.
It also releases all information relative to tasks. In order to modify this task
again you must call Activate() because there is no active task now.
It returns:

=over

=item *

0 in case of failure

=item *

1 in case of success.

=back

=head3 $result GetTriggerCount()

Returns the number of triggers associated with the currently selected task or -1 in case of errors.

=head3 $string GetTriggerString($index)

Returns the trigger string associated to the trigger at $index position.
$index must be lower than the value returned by GetTriggerCount() .

=head3 $result DeleteTrigger($index)

Deletes the trigger found at $index. Returns:

=over

=item *

0 in case of failure

=item *

1 in case of success.

=back

=head3 $result GetTrigger($index,\%Trigger)

Populates hash %Trigger with values contained in the TASK_TRIGGER structure associated with
the trigger at position $index for the current task. Returns:

=over

=item *

0 in case of failure

=item *

-1 if the extension could not map the trigger to the hash (should never happen)

=item *

1 in case of success.

=back

=head3 $result SetTrigger($index,\%Trigger)

Sets trigger at position $index to hash %Trigger. Returns:

=over

=item *

0 in case of failure

=item *

-1 if the trigger contains illegal/invalid data

=item *

1 in case of success.

=back

=head3 $result CreateTrigger(\%Trigger)

Adds a new trigger to the current Task. Returns:

=over

=item *

0 in case of failure

=item *

-1 if the trigger contains illegal/invalid data

=item *

1 in case of success.

=back

=head3 $result SetFlags($flags)

Sets flags for the current Task. Examples are: Win32::TaskScheduler::TASK_FLAG_DELETE_WHEN_DONE. Returns:

=over

=item *

0 in case of failure

=item *

1 in case of success.

=back

=head3 $result GetFlags($flags)

Gets flags for the current Task. Returns:

=over

=item *

0 in case of failure

=item *

1 in case of success.

=back

=head3 $result GetStatus($status)

Gets the status for the job currently active. It is a HRESULT varaible. Returns:

=over

=item *

0 in case of failure

=item *

1 in case of success.

=back

=head3 $result GetExitCode($code)

Gets the return code for the job currently active that was returned last time, if any,
the scheduler attempted to start it. Obviously the code is job dependant.
TIP: a good idea for implementing a monitor of your scheduled activities, until M$ puts some decent effort into this component,
would be to compare values returned between subsequent runs and to trigger alerts on changes.
If this is what you need to do then you might as well look at GetStatus() .
Returns:

=over

=item *

0 in case of failure

=item *

1 in case of success.

=back

=head3 $comment GetComment()

Returns comment associated with currently selected task. Returns undef on error.

=head3 $result SetComment($comment)

Sets the comment for the currently selected task. Returns 1 on success and 0 on failure.

=head3 $creator GetCreator()

Returns the creator of the currently selected task. Returns undef on error.

=head3 $result SetCreator($creator)

Sets the creator property for the currently selected task. Returns 1 on success and 0 on failure.

=head3 ($ms $sec $min $hour $day $dayofweek $month $year) GetNextRunTime()

returns the next run time for the currently selected task.
Time is represented as showed above. It returns undef on failure.

=head3 ($ms $sec $min $hour $day $dayofweek $month $year) GetMostRecentRunTime()

returns the next run time for the currently selected task.
Time is represented as showed above. It returns undef on failure.

=head3 $timeMilliSeconds GetMaxRunTime()

Returns the time in milliseconds that the job will be allowed to run before being sent a WM_CLOSE message.
Returns -1 if this is not set, thus allowing the job to run indefinitely, or 0 if there is
an error.

=head3 $result SetMaxRunTime($timeMilliSeconds)

Sets the time in milliseconds that the job will be allowed to run before being sent a WM_CLOSE message.
Set the value to INFINITE (see constants) to allow the task to run forever.
Returns 1 on success and 0 on failure.

=head3 $result Run()

Execute the currently active task. Please note that the returned value only indicates whether
the call to run has succeeded, not if the execution of the task was successful. Use
GetExitCode() or GetStatus for that.

=head3 $result Terminate()

Terminates the currently selected task. To tell if your call was successfull look at
$result and the call GetStatus() .

=head2 EXPORT

None.

=head1 AUTHOR and LICENSE

This module is licensed under the GPL (GNU Public License) and is provided "as is" without any explicit
or implicit guarantee.
Written by Umberto Nicoletti, E<lt>unicolet@netscape.netE<gt> in weekends of 2001-2002.

=head1 SEE ALSO

=cut
