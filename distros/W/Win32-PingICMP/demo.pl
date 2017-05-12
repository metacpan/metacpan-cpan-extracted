use Win32::PingICMP;
use Data::Dumper;

my $p = Win32::PingICMP->new();

if ($p->ping(@ARGV)) {
	print "Ping took ".$p->details->{roundtriptime}."\n";
} else {
	print "Ping unsuccessful: ".$p->details->{status}."\n";
}
print Data::Dumper->Dump([$p->details()]);



$p->ping_async(@ARGV);

until ($p->wait(0)) {
	Win32::Sleep(10);
	print "Waiting\n";
}

if ($p->details()->{status} eq 'IP_SUCCESS') {
	print "Ping took ".$p->details()->{roundtriptime}."\n";
} else {
	print "Ping unsuccessful: ".$p->details()->{status}."\n";
}
print Data::Dumper->Dump([$p->details()]);
