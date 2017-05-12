use Net::Ping;
use Win32::Registry;

require 'Win32/ProcFarm/Child.pl';

&init;
while(1) { &main_loop };

#ping will ping a remote host and return 1 if successful, 0 if not.  Attempts three pings.

sub ping {
  my($host) = @_;

  $p or $p = Net::Ping->new("icmp", 2);
  my $i = 0;
  until ($p->ping($host)) {
    $i++ > 2 and return 0;
  }
  return 1;
}

#nslookup will execute a gethostbyname on the passed value

sub nslookup {
  my($name) = @_;
  my($name2,$aliases,$addrtype,$length,@addrs) = gethostbyname($name);
  return join('.', unpack('C4', $addrs[0]));
}

#loggedin will check to see if anyone is logged in.  returns 1 if it fails to check or if someone is logged in.
sub loggedin {
  my($machine) = @_;

  my($hku, @keys, %retval);

  if ($HKEY_USERS->Connect($machine, $hku)) {
    unless ($hku->GetKeys(\@keys)) {
      $hku->Close;
      return 1;
    }
    $hku->Close;
    return (scalar(@keys) > 1) ? 1 : 0;
  } else {
    return 1;
  }
}
