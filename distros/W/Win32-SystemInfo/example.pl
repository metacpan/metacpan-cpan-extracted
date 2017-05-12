use Win32::SystemInfo;
use Data::Dumper;
my %mHash;
if (Win32::SystemInfo::MemoryStatus(%mHash,'GB'))
{
    print Dumper(\%mHash);
}
my ($proc,%pHash);
if ($proc = Win32::SystemInfo::ProcessorInfo(%pHash))
{
	print "proc: $proc\n";
	print Dumper(\%pHash);
}