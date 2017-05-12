#!/usr/bin/perl
#
#
#

use strict;
use warnings;
use Yandex::Tools;

package Yandex::Tools::ProcessList;

package psProcess;
sub pid { my ($self) = @_; return $self->{'pid'}; }
sub ppid { my ($self) = @_; return $self->{'ppid'}; }
sub pgrp { my ($self) = @_; return $self->{'pgid'}; }
sub pgid { my ($self) = @_; return $self->{'pgid'}; }
sub cmndline { my ($self) = @_; return $self->{'cmd'}; }
sub cmd { my ($self) = @_; return $self->{'cmd'}; }
sub start_time { my ($self) = @_; return $self->{'start_time'}; }

package Yandex::Tools::ProcessList;

my $runtime = {};
my $config = {};

sub set_options {
  my ($opts) = @_;

  Yandex::Tools::die("set_options expects program cmd line regexp")
    unless $opts->{'daemon_match'} && ref($opts->{'daemon_match'}) eq 'ARRAY';

  Yandex::Tools::die("set_options expects program cmd line regexp during startup")
    unless $opts->{'daemon_match_startup'} && ref($opts->{'daemon_match_startup'}) eq 'ARRAY';

  $config = $opts;
}

sub code_may_fail {
  my ($code, $opts) = @_;

  die("Need coderef (something to execute)")
    unless $code && ref($code) eq 'CODE';
  
  $opts = {} unless $opts;
  $opts->{'tries'} = 1 unless $opts->{'tries'};
  $opts->{'sleep_between_tries'} = 1 unless $opts->{'sleep_between_tries'};

  my $i = 0;
  my $lastwarn = "";
  my $code_result;

  while ($i < $opts->{'tries'}) {
    $i = $i + 1;

    $SIG{'__WARN__'} = sub { $lastwarn = join("\n", @_); };
    eval { $code_result = $code->(); };
    delete($SIG{'__WARN__'});

    if ($lastwarn && $i < $opts->{'tries'}) {
      $lastwarn = "";
      sleep $opts->{'sleep_between_tries'};
    }
  }

  return {
    'result' => $code_result,
    'warn' => $lastwarn,
    'try' => $i,
    };
}

# returns
#   * 0 if process does not exist at all (no /proc/PID directory),
#   * undef if its /proc/PID entry is in some inconsistent state
#   * psProcess object if pid was found and successfully read with (pid, ppid, pgid, cmd) methods
#
sub get_process_by_pid {
  my ($pid) = @_;

  my $read_may_fail = sub {
    my ($filename) = @_;
    my $filecontent;
    if (open F, $filename) {
      { local $/ = undef; $filecontent = <F>; }
      close F;
    }
    return $filecontent;
  };

  my $pid_dir = "/proc/$pid";

  return 0 if ! -d $pid_dir;

  my $cmd = $read_may_fail->("$pid_dir/cmdline");
  $cmd =~ s/\0/ /goi if $cmd;

  my $ppid;
  my $pgid;
  my $seconds_since_boot = 0;

  if (-e "$pid_dir/stat") { # linux path
    my $stat = $read_may_fail->("$pid_dir/stat");
    return undef unless $stat;

    my @stat_arr = split(" ", $stat);
    return undef if ! scalar(@stat_arr) > 5;

    if (!$cmd) {
      $cmd = $stat_arr[1];
    
      if ($cmd) {
        $cmd =~ s/[\(\)]//goi;
        $cmd = "[" . $cmd . "]";
      }
    }

    $ppid = $stat_arr[3];
    $pgid = $stat_arr[4];
    $seconds_since_boot = int($stat_arr[21] / 100);
  }
  elsif (-e "$pid_dir/status") { # bsd path
    my $stat = $read_may_fail->("$pid_dir/status");
    return undef unless $stat;

    my @stat_arr = split(" ", $stat);
    return undef if ! scalar(@stat_arr) > 5;

    if (!$cmd) {
      $cmd = $stat_arr[0];
    
      if ($cmd) {
        $cmd =~ s/[\(\)]//goi;
        $cmd = "[" . $cmd . "]";
      }
    }

    $ppid = $stat_arr[2];
    $pgid = $stat_arr[3];
  }

  # Get btime
  my $start_time;
  my $stat = $read_may_fail->("/proc/stat");
  $start_time = undef;
  my @stat = split("\n",$stat);
  for (@stat) {
    if (/^btime (\d+)/) {
      $start_time = $seconds_since_boot + $1;
      last;
    }
  }

  return undef if ! $cmd;
  return undef if $ppid !~ /^[0-9]+$/o;
  return undef if $pgid !~ /^[0-9]+$/o;

  my $p = {
    'pid' => $pid,
    'ppid' => $ppid,
    'pgid' => $pgid,
    'cmd' => $cmd,
    'start_time' => $start_time,
    };

  bless ($p, 'psProcess');
  return $p;
}

sub get_process_table {
  my $ptable;

  my @all_entries;
  if (-d "/proc") {
    my $i = 0;

    my $dummy;
    my $open_res;
    while (!($open_res = opendir($dummy, "/proc")) && $i < 2) {
      sleep 1;
      $i++;
    }
    if (!$open_res) {
      Yandex::Tools::die("unable to read /proc");
    }

    $i = 0;
    while (scalar(@all_entries) < 3 && $i < 2) {
      @all_entries = readdir($dummy);
      sleep 1 if $i > 0;
      $i++;
    }
    close($dummy);
  }
  else {
    # try to use Proc::ProcessTable on BSD when /proc is not available
    if ($^O ne 'linux') {
      require Proc::ProcessTable;
    }
  }

  # Proc::ProcessTable has some leaks on linux
  # which leads to process dying
  #
  # use procfs if available
  #
  if ($^O eq 'linux' || scalar(@all_entries) > 3) {
    $ptable = [];
    
    # . + .. eq 2
    if (scalar(@all_entries) < 3) {
      Yandex::Tools::die("/proc is not mounted");
    }

    foreach my $e (sort @all_entries) {
      next if $e eq '.' || $e eq '..';
      next if $e !~ /^\d+$/o;

      my $p = get_process_by_pid($e);
      
      if ($p) {
        push (@{$ptable}, $p);
      }
    }

    return $ptable;
  }
  else {
    my $r = code_may_fail(sub {return Proc::ProcessTable->new()->table}, {'tries' => 3});

    if (!$r->{'result'}) {
      Yandex::Tools::die("unable to get process table: " . $r->{'warn'});
    }
    
    $ptable = $r->{'result'};
  }

  my $i = 0;
  while (scalar(@{$ptable}) < 2 && $i < 3) {
    $i++;
    sleep 1;
    $ptable = get_process_table();
  }

  if (scalar(@{$ptable}) < 2) {
    Yandex::Tools::die("unable to read process table");
  }

  return $ptable;
}

sub get_process_by_id {
  my ($pid, $opts) = @_;

  $opts = {} unless $opts;

  my $processes;
  if ($opts->{'processes'}) {
    $processes = $opts->{'processes'};
  }
  else {
    if (!$runtime->{'startup_processes'}) {
      $runtime->{'startup_processes'} = get_process_table();
    }
    $processes = $runtime->{'startup_processes'};
  }

  foreach my $p (@$processes) {
    my $r = code_may_fail(sub {return $p->pid});

    if (!$r->{'result'}) {
#      print STDERR
#        "empty pid: " . $p->cmndline . "; " .
#        ((-f $p->cmndline) ? "file exists" : "file does not exist") .
#        "; my pid [" . $$ . "]" .
#        "\n";
#
# dvina: empty pid: /proc/23263/cmdline; file does not exist; my pid [23348]
# dunai: empty pid: /proc/31978/cmdline; file does not exist; my pid [32072]

      next;
    }
    
    return $p if $r->{'result'} eq $pid;
  }

  return undef;
}

# get the pid of my parent process (by command line)
# 
sub get_my_process {
  my ($pid) = @_;

  my $orig_pid = $pid;

  # trying to find daemon with the same --cfg option
  #
  while ($pid ne 1) {
    my $pid_p = get_process_by_id($pid);

    if (!$pid_p) {
      Yandex::Tools::die("unable to find [$pid] in process list");
    }

    if ($pid_p->cmndline &&
      Yandex::Tools::matches_with_one_of_regexps($pid_p->cmndline, $config->{'daemon_match'})
      ) {

      return $pid_p;
    }

    $pid = $pid_p->ppid;
  }

  # backward compatibility: trying to find
  # any daemon without --cfg option
  $pid = $orig_pid;
  while ($pid ne 1) {
    my $pid_p = get_process_by_id($pid);
    if (!$pid_p) {
      Yandex::Tools::die("unable to find [$pid] in process list");
    }

    if ($pid_p->cmndline &&
      Yandex::Tools::matches_with_one_of_regexps($pid_p->cmndline, $config->{'daemon_match_startup'}) &&
      !Yandex::Tools::matches_with_one_of_regexps($pid_p->cmndline, $config->{'daemon_match'})) {

      return $pid_p;
    }

    $pid = $pid_p->ppid;
  }

  return undef;
}

# get pid of other daemon started with the same --cfg option
#
sub get_other_daemon_process {
  my ($opts) = @_;
  $opts = {} unless $opts;

  my $processes;
  if (!$runtime->{'startup_processes'} || $opts->{'refresh_startup_processes'}) {
    $runtime->{'startup_processes'} = get_process_table();
  }
  $processes = $runtime->{'startup_processes'};

  # this doesn't mean "always find my process",
  # name of the sub is not consistent!!!
  #
  # it usually returns undef (during --stop for example)
  #
  my $my_process = get_my_process($$);

  my $r;

  # trying to find other daemon with the same --cfg option
  #
  foreach my $p (@$processes) {
    my $p_pid;
    my $p_cmndline;
    my $p_pgrp;
    $r = code_may_fail(sub {$p_pid = $p->pid});
    $r = code_may_fail(sub {$p_cmndline = $p->cmndline});
    $r = code_may_fail(sub {$p_pgrp = $p->pgrp});

    next unless $p_cmndline;
    next if !Yandex::Tools::matches_with_one_of_regexps($p_cmndline, $config->{'daemon_match'});

    # find process with given command line
    # from other process group
    if ($my_process) {
      next if $p->pgrp eq $my_process->pgrp;
    }

    # if we are looking for daemon then its parent should be init
    if ($p_cmndline !~ /--debug/o && $p->ppid ne 1) {
      next;
    }

    my $real_daemon = get_process_by_id($p_pgrp);
    
    # found a process for which group leader doesn't exist
    # (shouldn't happen but just in case of some error)
    # 
    #
    # real world situation:
    #
    # pechora:~# ps -eo pid,ppid,pgrp,cmd | grep snak | grep -v grep
    #  5674     1  5674 /usr/bin/perl /usr/local/ps-snake/bin/snaked --watchdog --cfg /etc/ps-farm/options/ps-snaked
    # 26550     1 25742 /usr/bin/perl /usr/local/ps-snake/bin/snaked --daemon --cfg /etc/ps-farm/options/ps-snaked
    # 29634     1 25742 /usr/bin/perl /usr/local/ps-snake/bin/snaked --daemon --cfg /etc/ps-farm/options/ps-snaked
    #
    # corresponding log message about parent pid:
    # Sat Apr 10 16:37:52 2010 [/usr/local/ps-snake/bin/snaked] [25742] started
    # 
    # both 26550 and 29634 were not snaked daemons
    # but were forks doing some work (actually locked
    # during log operation or something) but
    # watchdog doesn't detect difference between
    # snaked daemon and its children forks
    # (it should and will do it one day probably)
    # 
    # and manual `snaked --daemon` also didn't detect them,
    # now it kills them (their process group)
    # before spawning new daemon
    # 
    if (!$real_daemon) {
      print STDERR "cleaning up stuck process group [$p_pgrp]\n";
      kill(-9, $p_pgrp);
    }
    
    return $real_daemon;
  }

  # backward compatibility: trying to find
  # any other daemon without --cfg option
  #
  foreach my $p (@$processes) {
    my $p_pid;
    my $p_cmndline;
    my $p_pgrp;
    $r = code_may_fail(sub {$p_pid = $p->pid});
    $r = code_may_fail(sub {$p_cmndline = $p->cmndline});
    $r = code_may_fail(sub {$p_pgrp = $p->pgrp});

    next unless $p_cmndline;
    next if !Yandex::Tools::matches_with_one_of_regexps($p_cmndline, $config->{'daemon_match_startup'});
    next if Yandex::Tools::matches_with_one_of_regexps($p_cmndline, $config->{'daemon_match'});

    if ($my_process) {
      next if $p->pgrp eq $my_process->pgrp;
    }

    my $real_daemon = get_process_by_id($p_pgrp);
    return $real_daemon;
  }

  return undef;
}

sub get_my_path_commandline {
  my ($opts) = @_;
  my $my_path;
  my $my_command_line;

  my $me = Yandex::Tools::ProcessList::get_process_by_id($$, $opts);
  Yandex::Tools::die("[$$]: unable to find myself in process list") unless $me;
  $my_path = $FindBin::Bin;
  Yandex::Tools::die("[$$]: unable to find my path") unless $my_path;
  $my_command_line = $me->cmndline;
  Yandex::Tools::die("[$$] unable to determine my command line") unless $my_command_line;

  return ($my_path, $my_command_line);
}


1;
