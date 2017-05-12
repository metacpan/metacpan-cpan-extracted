# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Win32-Process-CommandLine.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Win32::Process::CommandLine') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
use_ok('Win32::Process');

#########################

#copy from test.pl, make sure no error
use Win32::Process;
use Win32::Process::CommandLine;

#int GetPidCommandLine(int pid, char* cmdParameter)
my ($str, $pid);

#print "  Tell me a process id:";
#$pid = <STDIN>;
#chomp $pid;

$txtFile = "t/Win32-Process-CommandLine.t";
$notepad = $ENV{'SystemRoot'} . "\\system32\\notepad.exe";

if(-e $txtFile){
	#start notepad.exe boot.ini
	Win32::Process::Create($gProcessObj,
	"$notepad",
	"$notepad $txtFile",
	0,
	NORMAL_PRIORITY_CLASS,
	"." ) ;

	$pid = $gProcessObj->GetProcessID();
	$exitCode = $gProcessObj->GetExitCode($exitCode);
	print "  notepad.exe started with pid $pid\n";

	sleep 1;
	$rs  = Win32::Process::CommandLine::GetPidCommandLine($pid, $str);

	print "  return code is the length of command line (include \\0) : $rs\n  command line of pid $pid: $str\n" ;

	$gProcessObj->Kill(8);

	#print  (($str =~ /Win32-Process-CommandLine/) ? 'ok' : 'fail');

	ok($str =~ /Win32-Process-CommandLine/);
}