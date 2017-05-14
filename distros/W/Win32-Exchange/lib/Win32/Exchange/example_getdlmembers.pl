use Win32::Exchange;
$info_store_server = "YOURSERVERHERE";
$prop = "cn";
$dlname = "THISDISTLIST";

if (!Win32::Exchange::GetVersion($info_store_server,\%ver)) {
  die   "$rtn - Error returning from GetVersion\n";
}
print "ver = $ver{'ver'}\n";
if ($ver{'ver'} eq "5.5") {
  #E55 -- need testing
  $prop = "displayname";#change this to see different values
  $provider = Win32::Exchange::Mailbox->new($info_store_server);
  
  if ($provider->GetDLMembers($info_store_server,$dl_name,\@members,$prop)) {
    foreach $member (@members) {
      print "$prop = $member\n";
    }
  } else {
    print "didn't work\n";
  }
} elsif ($ver{'ver'} eq "6.0") {
  #E2K -- I've tested this one...
  $prop = "cn";#change this to see different values
  $provider = Win32::Exchange::Mailbox->new($info_store_server);
  
  if ($provider->GetDLMembers($dl_name,\@members,$prop)) {
    foreach $member (@members) {
      print "$prop = $member\n";
    }
  } else {
    print "didn't work\n";
  }
}