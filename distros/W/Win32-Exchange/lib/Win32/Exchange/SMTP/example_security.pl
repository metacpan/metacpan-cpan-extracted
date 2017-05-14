use Win32::Exchange;

$exch_server = "SOMESERVER";

$ipsec = Win32::Exchange::SMTP::Security->new();

$ipsec->Bind($exch_server,1);

$ipsec->GetIpSecurityList(\%hash);

foreach $key (keys %hash) {
  if (ref($hash{$key}) eq "ARRAY") {
    print "\n$key\n";
    foreach $entry (@{$hash{$key}}) {
      print "  $entry\n";
    }
  } else {
    print "$key - $hash{$key}\n";
  }
}

@list = ('1.1.1.1',
         '1.1.1.2',
        );

$type = "security";

if ($ipsec->IpListManip("add",\@list)) {
  print "Successfully added to the $type list\n";
}
if ($ipsec->IpListManip("delete",\@list)) {
  print "Successfully deleted from the $type list\n";
}

$ipsec->GetIpRelayList(\%hash);

$type = "relay";

if ($ipsec->IpListManip("add",\@list)) {
  print "Successfully added to the $type list\n";
}
if ($ipsec->IpListManip("delete",\@list)) {
  print "Successfully deleted from the $type list\n";
}
