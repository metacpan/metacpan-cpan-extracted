use Win32::SystemInfo::CpuUsage;

my $i = 0;
my $s = 0;
while($i < 5){
	$i++;
	my $usage = Win32::SystemInfo::CpuUsage::getCpuUsage(1000);
	print "$i: cpu usage $usage\n";
	$s += $usage ;
}
print $s;