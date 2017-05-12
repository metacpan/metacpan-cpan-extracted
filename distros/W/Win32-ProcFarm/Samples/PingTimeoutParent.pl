use Win32::ProcFarm::Pool;

use strict;

$ARGV[0] =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3})\.(\d{1,3})-(\d{1,3})$/ or
    die "Pass me the range to ping in the format start_address-end (i.e. 135.40.94.1-40).\n";
my($base, $start, $end) = ($1, $2, $3);

my $poolsize = int(sqrt(($end-$start)*2)+1);
20 < $poolsize and $poolsize = 20;

print "Creating pool with $poolsize threads . . .\n"; &set_timer;

my $Pool = Win32::ProcFarm::Pool->new($poolsize, 9000, 'PingTimeoutChild.pl', Win32::GetCwd, timeout => 2);
print "Pool created in ".&get_timer." seconds.\n";

&set_timer;

foreach my $i ($start..$end) {
  my $ip_addr = "$base.$i";
  $Pool->add_waiting_job($ip_addr, 'ping', $ip_addr, rand(3));
}

$Pool->do_all_jobs(0.1);

my(%ping_data) = $Pool->get_return_data;
$Pool->clear_return_data;

my $retval = 0;
foreach my $i ($start..$end) {
  my $ip_addr = "$base.$i";
  print "$ip_addr\t".($ping_data{$ip_addr}->[0] || 'Child process terminated')."\n";
  $ping_data{$ip_addr}->[0] eq 'Host present' and $retval++;
}
print "Total of $retval addresses responded in ".&get_timer." seconds.\n";

{
  my $start_clock;

  sub set_timer {
    $start_clock = Win32::GetTickCount();
  }

  sub get_timer {
    return (Win32::GetTickCount()-$start_clock)/1000;
  }
}

