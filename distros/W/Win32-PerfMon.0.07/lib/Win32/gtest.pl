use Win32::PerfMon;

my $xxx = Win32::PerfMon->new("\\\\SMALLGT3");

if($xxx)
{
	my $Data = $xxx->ListObjects();
	
	foreach my $index (@$Data)
	{
		print "$index\n";
	}
	
	print "\n\n";
	
	$Data = $xxx->ListCounters("System");
		
		if($Data == -1)
		{
			print "ERROR: ". $xxx->{'ERRORMSG'} ."\n";
		}
		else
		{
			foreach my $index (@$Data)
			{
				print "$index\n";
			}
	}
	
	$Data = $xxx->ListInstances("System");
	
	if($Data == -1)
	{
		print "ERROR: ". $xxx->{'ERRORMSG'} ."\n";
	}
	else
	{
		foreach my $index (@$Data)
		{
			print "$index\n";
		}
	}
}