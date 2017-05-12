use Win32::ProcFarm::PerpetualPool;

use strict;

$ARGV[0] =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3})\.(\d{1,3})-(\d{1,3})$/ or
    die "Pass me the range to ping in the format start_address-end (i.e. 135.40.94.1-40) and the number of seconds for which to run.\n";
my($base, $start, $end) = ($1, $2, $3);

$ARGV[1] =~ /^(\d+)$/ or
    die "Pass me the range to ping AND the number of seconds for which to run.\n";
my $termination_time = $ARGV[1];

my $poolsize = int(($end-$start+5)/5);
$poolsize = 5 if $poolsize > 10;
print "Creating pool with $poolsize threads . . .\n"; &set_timer;

my $Pool = Win32::ProcFarm::PerpetualPool->new($poolsize, 9000, 'PingInconsistentChild.pl', Win32::GetCwd(),
    command => 'ping',
    list_check_intvl => 10,
    exit_check_intvl => 1,

    list_sub => sub {
      my(@new_list) = grep {rand() < 0.75} ($start..$end);
      print "\nNew list: ".join(", ", @new_list)."\n\n";
      return map {"$base.$_"} @new_list;
    },

    result_sub => sub {
      my($ip_addr, $ping) = @_;

      print "$ip_addr was ".($ping ? '' : 'not ')."pingable \n";
    },

    exit_sub => sub {
      if (time() > $termination_time) {
        print "Exiting.\n";
        return 1;
      }
      return 0;
    }
  );
print "Pool created in ".&get_timer." seconds.\n";

$termination_time += time();

$Pool->start_pool(0.1);

{
  my $start_clock;

  sub set_timer {
    $start_clock = Win32::GetTickCount();
  }

  sub get_timer {
    return (Win32::GetTickCount()-$start_clock)/1000;
  }
}
