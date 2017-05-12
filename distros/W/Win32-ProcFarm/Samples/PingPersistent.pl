use Win32::ProcFarm::Pool;

use strict;

@ARGV == 1 or die "Pass me the number of threads you wish to create.\n";

my $poolsize = $ARGV[0];
print "Creating pool with $poolsize threads . . .\n"; &set_timer;

my $Pool = Win32::ProcFarm::Pool->new($poolsize, 9000, 'PingChild.pl', Win32::GetCwd);
print "Pool created in ".&get_timer." seconds.\n";

while (1) {
  my($retval);
  print "\nEnter start_address-end (i.e. 135.40.94.1-40) or q to quit: ";
  my $temp = <STDIN>;
  $temp =~ /^q/i and last;
  unless ($temp =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3})\.(\d{1,3})-(\d{1,3})$/) {
    print "You did not pass me a legal string.\n";
    next;
  }
  my ($base, $start, $end) = ($1, $2, $3);

  &set_timer;

  foreach my $i ($start..$end) {
    my $ip_addr = "$base.$i";
    $Pool->add_waiting_job($ip_addr, 'ping', $ip_addr);
  }

  foreach my $i ($start..$end) {
    my $ip_addr = "$base.$i";
    until (exists $Pool->{return_data}->{$ip_addr}) {
      $Pool->cleanse_and_dispatch;
      Win32::Sleep(100);
    }
    if ($Pool->{return_data}->{$ip_addr}->[0]) {
      print "$ip_addr\n";
      $retval++;
    }
  }

  print "Total of $retval addresses responded in ".&get_timer." seconds.\n";
  $Pool->clear_return_data;
}

{
  my $start_clock;

  sub set_timer {
    $start_clock = Win32::GetTickCount();
  }

  sub get_timer {
    return (Win32::GetTickCount()-$start_clock)/1000;
  }
}
