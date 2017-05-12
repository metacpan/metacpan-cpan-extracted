use Net::Ping;

require 'Win32/ProcFarm/Child.pl';

&init;
while(1) { &main_loop };

sub ping {
  my($host, $delay) = @_;

  $p or $p = Net::Ping->new('icmp', 1);
  if ($p->ping($host)) {
    $delay > 2 and die;
    return 'Host present';
  } else {
    sleep($delay);
    return 'Host not present';
  }
}
