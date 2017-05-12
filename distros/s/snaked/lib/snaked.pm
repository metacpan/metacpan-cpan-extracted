package snaked;

use vars qw($VERSION);
$VERSION = '0.14';

use strict;
use warnings;
use Yandex::Tools;
use Time::HiRes;
use Schedule::Cron::Events;
use Time::Local;

$snaked::Daemon::runtime = {
  "type" => "master",

  "flags" => {
    "stop" => 0,
    "refresh_configuration" => 0,
    },

  "children" => {},

  "usec_2check_watchdog" => 0,
  "usec_2refresh_configuration" => 0,
  "usec_2wait_before_fork" => 0,

  "start_time" => my_clock(),

  "tasks" => {}, # mixed configuration and runtime task options/parameters

  "config" => {},

  };

sub clock_mono {
  return int(Time::HiRes::clock_gettime(Time::HiRes::CLOCK_MONOTONIC()));
}

sub clock_real {
  return int(Time::HiRes::clock_gettime(Time::HiRes::CLOCK_REALTIME()));
}

sub my_clock {
  return {
    'mono' => clock_mono(),
    'real' => clock_real(),
  };
}

sub refreshOptions {
  my ($dir, $opts) = @_;
  
  $opts = {} unless $opts;

  my $config = $snaked::Daemon::runtime->{'config'};
  my $tasks = $snaked::Daemon::runtime->{'tasks'};
  my $tmp;

  # read daemon options
  my $new_options = {};
  my $old_log_options = Yandex::Tools::get_log_options();

  $tmp = Yandex::Tools::read_dir($dir, {'output_type' => 'arrayref', 'only-files' => 1});
  foreach my $o (@{$tmp}) {
    next if $o =~ /^\./o;

    my $fileinfo = Yandex::Tools::fileinfo_struct({'absolute_name' => $dir . "/" . $o});

    $new_options->{$o} = 1;

    # option was not modified since we've read it
    if ($config->{$o} && $config->{$o}->{'mtime'} eq $fileinfo->{'mtime'}) {
      next;
    }

    my $option_updated = ($config->{$o} ? 1 : 0);

    $config->{$o}->{'mtime'} = $fileinfo->{'mtime'};
    $config->{$o}->{'value'} = Yandex::Tools::read_file_option($dir . "/" . $o);

    if ($option_updated) {
      Yandex::Tools::do_log("new value for option $o: " . $config->{$o}->{'value'});
    }
  }

  # remove old options
  foreach my $opt_name (keys %{$config}) {
    next if $new_options->{$opt_name};

    # should list all options which have defaults here
    next if $opt_name eq 'admin_email';
    next if $opt_name eq 'spool_directory';
    
    delete ($config->{$opt_name});
    Yandex::Tools::do_log("option $opt_name removed");
  }

  if (!$config->{'admin_email'}) {
    $config->{'admin_email'} = {
      'value' => 'root',
      'mtime' => 0,
      };
  }

  # configure logging (defaults to /tmp/ps-snaked.log, three 10MB files, rotated)
  #
  my $log_options = {};
  if ($config->{'log'}) {
    $log_options->{'filename'} = $config->{'log'}->{'value'};
  }
  else {
    $log_options->{'filename'} = ($ENV{'MY_ROOT'} eq "/" ? "" : $ENV{'MY_ROOT'}) . "/tmp/snaked.log";
  }
  if ($config->{'log_rotate_size'}) {
    $log_options->{'rotate_size'} = $config->{'log_rotate_size'}->{'value'};
  }
  else {
    $log_options->{'rotate_size'} = 1024 * 1024 * 10;
  }
  if ($config->{'log_rotate_keep_copies'}) {
    $log_options->{'rotate_keep_copies'} = $config->{'log_rotate_keep_copies'}->{'value'};
  }
  else {
    $log_options->{'rotate_keep_copies'} = 2;
  }
  Yandex::Tools::set_log_options($log_options);

  if (!Yandex::Tools::get_log_options() || !Yandex::Tools::can_log()) {
    if ($old_log_options) {
      Yandex::Tools::set_log_options($old_log_options);
    }
    else {
      Yandex::Tools::warn("Can not write to log file [$log_options->{'filename'}], check permissions; logging to STDERR");
    }
  }

  if (!$config->{'spool_directory'}) {
    my $spool_dir = $dir;
    $spool_dir =~ s/\//_/go;
    $config->{'spool_directory'} = {
      'value' => "/tmp/snaked.spool_" . $spool_dir,
      };
  }
  if (!Yandex::Tools::can_write($config->{'spool_directory'}->{'value'} . "/.exist")) {
    Yandex::Tools::do_log("unable to write to spool directory [" . $config->{'spool_directory'}->{'value'} . "]", {'stderr' => 1});
    delete($config->{'spool_directory'});
  }

  if ($config->{'debug_main_cycle'}) {
    if (! -d $config->{'debug_main_cycle'}->{'value'}) {
      my $e = mkdir $config->{'debug_main_cycle'}->{'value'};
      if (!$e) {
        Yandex::Tools::do_log("unable to create $config->{'debug_main_cycle'}->{'value'}, turning off debug_main_cycle", {'stderr' => 1});
        delete($config->{'debug_main_cycle'});
      }
    }
  }

  # in watchdog mode we don't need
  # to read job definitions
  return if $opts->{'no-jobs'};

  my $defined_jobs = {};

  # read daemon jobs
  if (-d "$dir/jobs") {
    $tmp = Yandex::Tools::read_dir($dir . "/jobs", {'output_type' => 'arrayref', 'only-directories' => 1});
    foreach my $o (@{$tmp}) {
      next if $o =~ /^\./o;

      $defined_jobs->{$o} = 1;

      my $dirinfo = Yandex::Tools::fileinfo_struct({'absolute_name' => $dir . "/jobs/" . $o});

      # job was not modified since we've read it
      if ($tasks->{$o} && $tasks->{$o}->{'mtime'} eq $dirinfo->{'mtime'}) {
        next;
      }
      if ($tasks->{$o}) {
        Yandex::Tools::do_log("[$$] reread job [$o] from disk");
      }

      # save execution schedule so we can decide below
      # whether we need to recalculate next_run time
      #
      if ($tasks->{$o}->{'execution_schedule'}) {
        $tasks->{$o}->{'previous_execution_schedule'} = $tasks->{$o}->{'execution_schedule'};
      }

      $tasks->{$o}->{'mtime'} = $dirinfo->{'mtime'};

      my $had_disabled;
      my $joptions = Yandex::Tools::read_dir($dir . "/jobs/" . $o, {'output_type' => 'arrayref', 'only-files' => 1});
      foreach my $jo (@{$joptions}) {
        if ($jo eq 'conflicts') {
          $tasks->{$o}->{$jo} = Yandex::Tools::read_file_array($dir . "/jobs/" . $o . "/" . $jo);
        }
        elsif ($jo eq 'cmd') {
          $tasks->{$o}->{$jo} = $dir . "/jobs/" . $o . "/" . $jo;
        }
        elsif ($jo eq 'disabled') {
          $had_disabled = 1;
          $tasks->{$o}->{'disabled'} = 1;
        }
        else {
          $tasks->{$o}->{$jo} = Yandex::Tools::read_file_option($dir . "/jobs/" . $o . "/" . $jo);
        }
      }

      if (!$had_disabled && defined($tasks->{$o}->{'disabled'})) {
        delete ($tasks->{$o}->{'disabled'});
      }

      $tasks->{$o}->{'dirinfo'} = $dirinfo;
    }
    
    # mark removed jobs, validate tasks
    TASKS: foreach my $task_name (keys %{$tasks}) {

      # task might be marked as TO_BE_REMOVED
      # but will not be removed till the time
      # it is chosen to be run again (which
      # takes some time in some cases)
      #
      if (!$defined_jobs->{$task_name}) {
        if (!$tasks->{$task_name}->{'TO_BE_REMOVED'}) {
          Yandex::Tools::do_log("job [$task_name] removed from configuration");
          $tasks->{$task_name}->{'TO_BE_REMOVED'} = 1;
        }

        next TASKS;
      }

      my $task = $tasks->{$task_name};

      if (!defined($task->{'execution_timeout'}) || !int($task->{'execution_timeout'})) {
        $task->{'execution_timeout'} = 0;
      }
      if (!defined($task->{'kill_timeout'}) ||
        !int($task->{'kill_timeout'}) && $task->{'kill_timeout'} ne 0) {

        # when lowering this timeout do not forget
        # that some tasks might need some time
        # to finish, and they might be important
        # like sync_applications doing
        # ps-snake --change-class
        #
        # if you decide to lower this limit for the whole installation
        # consider setting old default for every configured task

        $task->{'kill_timeout'} = 60;
      }

      foreach my $mp ("cmd") {
        if (!$task->{$mp}) {
          Yandex::Tools::do_log("skipping job [$task_name]: mandatory parameter [$mp] not specified");
          delete($tasks->{$task_name});
          next TASKS;
        }
      }
      if (! -x $task->{'cmd'}) {
        Yandex::Tools::do_log("skipping job [$task_name]: [$task->{'cmd'}] is not executable");
        delete($tasks->{$task_name});
        next TASKS;
      }

      # one of scheduling methods must be specified
      #
      if ((!$task->{'execution_interval'} && !$task->{'execution_schedule'}) ||
        ($task->{'execution_interval'} && $task->{'execution_schedule'})) {
        
        Yandex::Tools::do_log("skipping job [$task_name]: one and only one of (execution_interval, execution_schedule) must be defined");
        delete($tasks->{$task_name});
        next TASKS;
      }

      if ($task->{'execution_schedule'} &&
        (
          $task->{'previous_execution_schedule'} && $task->{'execution_schedule'} ne $task->{'previous_execution_schedule'} || # runtime
          !$task->{'previous_execution_schedule'} # start-up
        )
        ) {
        my $cron;
        eval {
          $cron = new Schedule::Cron::Events($task->{'execution_schedule'}, Seconds => clock_real());
        };

        if (!$cron) {
          my $msg = $@;
          # leave only first line
          $msg =~ s/[\r\n].+$//sgo;
          # remove filename in which the error was raised
          $msg =~ s/at\ \/.+$//sgo;
          $msg = ": $msg" if $msg;

          Yandex::Tools::do_log("skipping job [$task_name]: invalid execution_schedule $msg");
          delete($tasks->{$task_name});
          next TASKS;
        }
        $task->{'cron'} = $cron;
        $task->{'next_run'} = Time::Local::timelocal($task->{'cron'}->nextEvent);

        # new schedule was applied, do not bother doing it again
        $task->{'previous_execution_schedule'} = $task->{'execution_schedule'};
      }

      foreach my $dp ("execution_interval", "execution_timeout", "notification_interval", "start_random_sleep") {
        if ($task->{$dp} && !Yandex::Tools::is_digital($task->{$dp})) {
          Yandex::Tools::do_log("skipping job [$task_name]: [$dp] must be numeric");
          delete($tasks->{$task_name});
          next TASKS;
        }
      }

      if ($task->{'conflicts'} && ref($task->{'conflicts'}) ne 'ARRAY') {
        Yandex::Tools::do_log("skipping job [$task_name]: [conflicts] must be an array reference");
        delete($tasks->{$task_name});
        next TASKS;
      }
      if ($task->{'conflicts'}) {
        foreach my $c_task (@{$task->{'conflicts'}}) {
          if ($c_task eq $task_name) {
            Yandex::Tools::do_log("skipping job [$task_name]: task conflicts with itself.");
            delete($tasks->{$task_name});
            next TASKS;
          }
        }
      }

      # defaults
      $task->{'notification_interval'} = 0 unless $task->{'notification_interval'};
    }
  }

  # rebuild conflicts_hash for each task
  #
  foreach my $tn (keys %{$tasks}) {
    if ($tasks->{$tn}->{'conflicts_hash'}) {
      delete ($tasks->{$tn}->{'conflicts_hash'});
    }
  }
  
  foreach my $tn (keys %{$tasks}) {
    my $t = $tasks->{$tn};
    
    next unless $t->{'conflicts'};

    foreach my $ctn (@{$t->{'conflicts'}}) {
      my $ct = $tasks->{$ctn};

      # silently skip conflicting tasks
      # which are not configured (configuration typo)
      next unless $ct;

      # (possibly) add $t into $ct conflicts
      $ct->{'conflicts_hash'}->{$tn} = 1;

      # (possibly) add $ct into $t conflicts
      $t->{'conflicts_hash'}->{$ctn} = 1;
    }
  }
  
}


1;

__END__

=head1 NAME

snaked - cron as it should be. Or shouldn't? L<Please vote!|http://www.kohts.com/cron-5/vote/>

=head1 SYNOPSIS

  # import old cron jobs (TO BE IMPLEMENTED)
  snaked --import-crontabs

  # generate sample configuration (discussed below) in /etc/snaked
  snaked --sample-config

  # check which jobs are configured
  snaked --show-config

  # run in the foreground (CTRL-C to exit)
  snaked --debug

  # run in the background
  snaked --daemon

=head1 DESCRIPTION

B<snaked> is a job scheduler, just like cron,
which has several unique features making it
much more flexible and useful than any other
cron implementation.

It is heavily tested on Linux and FreeBSD
but might (and hopefully with your help will)
be run on any Perl + POSIX compliant system.

=head2 limit job execution time

You can choose to configure the maximum limit of time
for each job to finish. If job doesn't finish in time
it is killed. The limit is independently configurable
for each job. Forget about lockf, ps -ef | grep -v grep
and cron jobs being run twice and more times concurrently.

You can also configure the upper limit of execution time
of any job of the given snaked instance. This global limit
is checked independently of the individual
job execution time limits.

=head2 unique job id and job dependencies

Each snaked job has its unique job identifier
which is used to configure job dependencies:
for any job you can specify other jobs
(addressed by their identifiers) which
shouldn't be run with this job concurrently.

So if job A is being executed and time comes
to start job B which is configured as conflicting
with job A, then the start of job B is postponed
until job A is finished.

=head2 more often than once a minute

snaked allows jobs to be run more often than once a minute.

Actually snaked supports two execution schedule formats:
old cron format with not less than a minute time resolution
and snaked job schedule format which specifies how often
the jobs is run in seconds, making it possible to run job
even once a second!

=head2 run from any user, root is not required

Although configuration example below shows snaked run from root,
this is not a requirement. snaked doesn't require any specific
super-user privileges. Just specify configuration path
(with --cfg parameter) accessible by snaked (that's why
default log path for example points to /tmp) and run it
from any user.

=head1 CONFIGURATION EXAMPLE

snaked configuration is a directory which contains
global instance options (each option in separate file)
and associated job definitions where job definition
is also a directory with each job option
stored in a separate file:

  .
  |-- admin_email
  |-- jobs
  |   |-- every_hour
  |   |   |-- cmd
  |   |   `-- execution_schedule
  |   |-- every_ten_seconds
  |   |   |-- cmd
  |   |   `-- execution_interval
  |   `-- fast_job
  |       |-- cmd
  |       |-- conflicts
  |       `-- execution_interval
  `-- log

Above shown configuration (run "snaked --sample-config" from root to get it)
defines admin_email for the snaked instance (optional, defaults to root)
and log file path (optional, defaults to /tmp/snaked.log):

  testing18:/etc/snaked# cat admin_email
  root
  testing18:/etc/snaked# cat log
  /var/log/snaked/snaked.log

There are three jobs named every_hour, every_ten_seconds and fast_job
which append the result of 'uptime' command to /tmp/snaked_every_hour,
/tmp/snaked_ten_seconds and /tmp/snaked_fast_job. This is done by
running 'cmd' file which resides in job directory -- shell script
in sample configuration, this can be any executable allowed
by underlying operating system:

  testing18:/etc/snaked/jobs/every_hour# ls -l cmd
  -rwxr-xr-x 1 root root 0 2010-07-07 00:24 cmd
  testing18:/etc/snaked/jobs/every_hour# file cmd
  cmd: POSIX shell script text executable

First job, every_hour, has a parameter execution_schedule
which is an old cron schedule example (parsed by L<Schedule::Cron::Events>):

  testing18:/etc/snaked/jobs/every_hour# cat execution_schedule
  0 * * * *

Two other jobs use snaked execution_interval schedule,
specifying that every_ten_seconds job should be run
once in ten seconds, and fast_job should be run
once in every second.

  testing18:/etc/snaked/jobs/every_ten_seconds# cat execution_interval
  10
  testing18:/etc/snaked/jobs/fast_job# cat execution_interval
  1

To make it a bit more explanatory we've defined conflicts option
for fast_job which specifies that fast_job should not be run
if every_ten_seconds is running:

  testing18:/etc/snaked/jobs/fast_job# cat conflicts
  every_ten_seconds

Which translates to "try to run 'fast_job' as often as once a second,
but wait if 'every_ten_seconds' job is running".

=head1 DAEMON OPTIONS

=over 4

=item admin_email

Optional. Where to send emails about failing jobs. Defaults to root.

=item log

Optional. Name of the log filename which holds all the log messages
including informational and error messages. Defaults to /tmp/snaked.log.

=item log_errors

Optional. Name of the log filename used only for error messages.
Defaults to nothing, turning off separate error logging.

=item log_rotate_size

Optional. Size of the log file after which it is rotated.
Defaults to 10 MB.

=item log_rotate_keep_copies

Optional. Number of rotated log files to preserve.
Defaults to 2.

=item max_job_time

Optional. Specifies maximum exeuction time limit for all the jobs.
Defaults to 2 hours.

=item pidfile

Optional. Filename of the pidfile where snaked stores
the pid of its main process. Defaults to nothing,
which does not generate any pidfile.

=item spool_directory

Optional. Directory which is used to write detailed status
and debugging information (if configured).

Defaults to /tmp/snaked.spool__etc_snaked

=back

=head1 JOB OPTIONS

=over 4

=item admin_email

Optional. Where to send emails about failures of this job.
Defaults to global admin_email option (and overrides it). 

=item cmd

Mandatory. Executable with correct file permissions (executable bit on)
which is allowed by underlying operating system. Can be shell script or binary.

=item disabled

Optional. Existing file specifies that this job should not be run
(see also --enable-jobs and --disable-jobs command line parameters)

=item execution_interval, execution_schedule

Only one parameter, execution_interval or execution_schedule, is allowed
and is mandatory for one job. execution_interval specifies number of seconds
(positive integer) between invocations of cmd. execution_schedule specifies
standard cron format schedule (first five fields) for the job.

=item execution_timeout

Optional. Specifies time limit for the job, in seconds.
Defaults to nothing, turning time limit off.

=item kill_timeout

Optional. Specifies time in seconds between TERM and KILL signals
sent to the job when snaked needs to stop the job (when snaked
stop or restarts, when job runs too long). Defaults to 60 seconds.

=item notification_interval

Optional. Time period in seconds. Job failure emails are not sent
more often than this time period. First email is sent after
first time period of constant failures. This option is used
to suppress emails about accidental job failures. Defaults to 0,
which turns the feature off (delivers email on every job failure).

=item start_random_sleep

Optional. Time period in seconds which specifoes random
first run shift in time for the job. Defaults to 0,
which turns the feature off.

=item conflicts

Optional. Space/line separated list of job identifiers
which should wait while this job is running. If any job
from this list is currently being executed
then the job owning the option will not be executed.
Defaults to nothing, allowing the job to be run
independently of the status of any other job.

snaked organizes conflicting jobs into job groups,
running every job from the job group one by one
(if the time for the job has come). This guarantees
that every conflicting job is run from time to time
though its start time might be shifted because of
waiting for the conflicting jobs.

=back

=head1 DAEMON COMMAND-LINE PARAMETERS

=over 4

=item --daemon or --debug [--cfg PATH]

Two main (and mutually exclusive) command-line parameters are
--daemon (run in background) and --debug (run in foreground). 

--cfg option specifies snaked configuration which is to be used
for this snaked copy (defaults to /etc/snaked)

You can run several independent daemons with different configurations.

=item --stop [--cfg PATH] [--wait]

Request snaked to be stopped. With --wait option this request
will not return until snaked is actually stopped.

=item --configure [--cfg PATH]

Request snaked to reread configuration.

=item --restart [--cfg PATH]

Request snaked to restart. With --wait option this request
will not return until snaked is actually restarted.

=item --status [--cfg PATH]

Check whether snaked runs.

This is done by traversing all the running processes
and finding those which name matches snaked --cfg PATH.
If --cfg parameter is not specified then PATH
defaults to /etc/snaked

=item --detailed-status [--cfg PATH]

Dumps detailed state information into spool_directory.

=item --version

Show snaked version.

=item --show-config [--cfg PATH]

Dumps the configuration.

=item --enable-jobs <JOB_LIST> [--cfg PATH]

For every job in JOB_LIST (space separated) remove special
'disabled' file from job directory and request snaked to reread
configuration.

=item --disable-jobs <JOB_LIST> [--cfg PATH]

For every job in JOB_LIST (space separated) add special
'disabled' file tojob directory and request snaked to reread
configuration.

=item --add-job <JOB_NAME> --execution_interval N --cmd BASH_TEXT [--cfg PATH]

Add job named JOB_NAME to the snaked configuration pointed to by PATH
(defaults to /etc/snaked). execution_interval is set to N, cmd is set
to BASH_TEXT (protect shell special characters with quotes).

Other job parameters can be specified as well.

=item --delete-jobs <JOB_LIST> [--cfg PATH]

Delete jobs from snaked configuration pointed to by PATH (defaults
to /etc/snaked). This command does actually removes whole job directory,
consider using --disable-jobs <JOB_LIST> as it is safer.

=item --modify-job <JOB_NAME> <--parameter> <value> [--cfg PATH]

Replace current value of parameter of the specified job with new value
in the snaked configuration pointed to by PATH (defaults to /etc/snaked)

=item --sample-config [PATH]

Populate PATH or /etc/snaked (must not exist) with sample configuration

=back

=head1 CREDITS

Thanks to the whole Yandex team and personally to the following people (in alphabetic order):

  Denis Barov
  Maxim Dementyev
  Eugene Fedotov
  Andrey Grunau
  Andrey Ignatov
  Oleg Leksunin
  Dmitry Parfenov
  Alexey Simakov
  Dmitrij Tejblum
  Julie S Ukhlicheva
  Anton Ustyugov
  Andrey Zonov

for their bug reports, suggestions and contributions.

=head1 AUTHORS

Petya Kohts E<lt>petya@kohts.comE<gt>

=head1 COPYRIGHT

Copyright 2009 - 2013 Petya Kohts.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
