#!/usr/bin/perl

use strict;
use warnings;

use Win32::Process;
use Win32::Process::List;

# -----------------

my($processor)	= Win32::Process::List -> new();
my(%process)	= $processor -> GetProcesses();

my($p, $pid);

for $p (keys %process)
{
	$pid = $process{$p} if ($p eq 'XMail.exe');
}

if ($pid)
{
	Win32::Process::KillProcess($pid, 0);

	print "Stopped XMail. \n";
}
else
{
	print "XMail is not running. \n";
}
