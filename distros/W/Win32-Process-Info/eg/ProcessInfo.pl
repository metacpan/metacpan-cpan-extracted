#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Getopt::Std;
use Win32::Process::Info;

local $| = 1;

my %opt;

(getopts ('bcdem:n:pr:stu:v:x', \%opt) && !($opt{s} && $opt{x}))
    or die <<"usage end";

Testbed and demonstrator for Win32::Process::Info V $Win32::Process::Info::VERSION

usage: perl ProcInfo.pl [options] [pid ...]
where the allowed options are:
  -b = brief (PIDs only - uses ListPids, not GetProcInfo)
  -c = elapsed times in clunks (100-nanosecond intervals)
  -d = formatted dates where applicable
  -e = require an <Enter> to exit
  -l = slow (lethargic)
  -mx = report on machine x (valid only with variant WMI)
  -nx = report on process name x (case-insensitive)
  -p = pulist output
  -rn = number of repeats to do
  -s = report SID rather than username with -p
  -t = report process tree (overrides -p)
  -u user:password = guess (valid only with WMI)
  -vx = variant (a comma-separated list of 'WMI', 'NT')
  -x = report executable path rather than username with -p

Note that you may need to specify domain\\user:password with the -u
option to get it to work.
usage end

$opt{n} = lc $opt{n} if $opt{n};
$opt{r} ||= 1;

my %arg;
if ($opt{u}) {
    my ($usr, $pwd) = split ':', $opt{u};
    $arg{user} = $usr || '';
    $arg{password} = $pwd || '';
    }

my $pi = Win32::Process::Info->new ($opt{m}, $opt{v}, \%arg);
$pi->Set (
    elapsed_in_seconds	=> !$opt{c},
    );

for (my $iter8 = 0; $iter8 < $opt{r}; $iter8++) {
    print STDERR "Information - Iteration @{[$iter8 + 1]} of $opt{r}\n"
	if $opt{r} > 1;
    if ($opt{b}) {
	print "PIDs:\n",
	    map {"    $_\n"} sort {$a <=> $b} $pi->ListPids (@ARGV);
	}
      elsif ($opt{t}) {
	my %tree = $pi->Subprocesses (@ARGV);
	local $Data::Dumper::Terse;
	$Data::Dumper::Terse = 1;
	print "Subprocesses: ", Dumper (\%tree);
	}
      else {
	my ($key, $head) = $opt{x} ? ('ExecutablePath', 'Executable') :
		$opt{s} ? ('OwnerSid', 'Owner SID') : ('Owner', 'Owner');
	print $opt{p} ?
	    sprintf "%-20s %4s  %s\n", 'Process', 'PID', $head :
	    "Process info by process:\n";
	foreach my $proc ($opt{s} ?
		@ARGV ? @ARGV : $pi->ListPids () :
		sort {$a->{ProcessId} <=> $b->{ProcessId}}
		$pi->GetProcInfo (@ARGV)) {
	    $proc = ${$pi->GetProcInfo ($proc)}[0] unless ref $proc;
	    next if $opt{n} && lc $proc->{Name} ne $opt{n};
	    if ($opt{p}) {
		printf "%-20s %4d  %s\n",
		    $proc->{Name} || '', $proc->{ProcessId},
		    $proc->{$key} || '';
		}
	      else {
		if ($opt{d}) {
		    foreach my $key (qw{CreationDate InstallDate TerminationDate}) {
			$proc->{$key} = localtime ($proc->{$key}) if $proc->{$key};
			}
		    }
		print "\n$proc->{ProcessId}\n",
		    map {"    $_ => @{[defined $proc->{$_} ?
			$proc->{$_} : '']}\n"} sort keys %$proc;
		}
	    }
	}
    }


if ($opt{e}) {
    print "Press <Enter> to exit: ";
    <>;
    }

