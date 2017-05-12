use Win32::Process::Info;
use Win32::Process::CommandLine;

#int GetPidCommandLine(int pid, char* cmdParameter)
my ($str, $pid);

$pi = Win32::Process::Info->new ();

@pids = $pi->ListPids ();	# Get all known PIDs

foreach(@pids){
	undef $str;
	$rs  = Win32::Process::CommandLine::GetPidCommandLine($_, $str);
	if( $rs > 0 && $_ > 0){
		print "  $_\t\t $str\n" 
	}
	$str = '';
}
