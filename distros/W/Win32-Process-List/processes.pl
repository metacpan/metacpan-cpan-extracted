#!c:/perl/bin/perl -w
use Win32::Process::List;
use strict;

my $P = Win32::Process::List->new();
if($P->IsError == 1)
{
	print "an error occured: " . $P->GetErrorText . "\n";
}

my %list = $P->GetProcesses();
my $anz = scalar keys %list;
print "Anzal im Array= $anz\n";
my $count = 0;
foreach my $key (keys %list) {
	# $list{$key} is now the process name and $key is the PID
	print sprintf("%20s has PID %10s", $list{$key}, $key) . "\n";
	$count++;
}
print "Number of processes: $count\n";
my $process = "explorer";
my %hPIDS = $P->GetProcessPid($process);
print keys (%hPIDS) . "\n";
if(%hPIDS) {
	foreach (keys  %hPIDS) {
		print "$_ has PID " . $hPIDS{$_} . "\n";
	}
} else
{
	print "Process(s) not found\n";
	exit;
}
