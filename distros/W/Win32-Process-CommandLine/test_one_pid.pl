use Win32::Process::CommandLine;

#int GetPidCommandLine(int pid, char* cmdParameter)
my ($str, $pid);

print "  Tell me a process id:";
$pid = <STDIN>;
chomp $pid;

$rs  = Win32::Process::CommandLine::GetPidCommandLine($pid, $str);

print "  return code is the length of command line (include \\0) : $rs\n  command line of pid $pid: $str\n" ;
