use Win32::Service;

$|=1;

%h=();
Win32::Service::GetServices("", \%h);
print "1..", scalar keys %h, "\n";
while (my($k,$v) = each %h) {
    print "# $k|$v\n";
    my %status = ();
    Win32::Service::GetStatus("", $v, \%status);
    while (my($k,$v) = each %status) {
	print "#\t$k\t\t$v\n";
    }
    $i++;
    print "ok $i\n";
}

