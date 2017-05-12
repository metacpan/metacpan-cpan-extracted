use Win32::ProcFarm::TkPool;
use Tk;
use Tk::Table;

use strict;

$ARGV[0] =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3})\.(\d{1,3})-(\d{1,3})$/ or
  die "Pass me the range to ping in the format start_address-end (i.e. 135.40.94.1-40).\n";
my($base, $start, $end) = ($1, $2, $3);

my $poolsize = int(sqrt(($end-$start)*2)+1);
20 < $poolsize and $poolsize = 20;

my $mw = new Tk::MainWindow;

my $count = 0;
my $msg = $mw->Label(-text => "Created $count of $poolsize threads . . .")->pack(-side => 'top');;
$mw->update;

my $TkPool = Win32::ProcFarm::TkPool->new($poolsize, 9000, 'PingChild.pl', Win32::GetCwd,
    'mw' => $mw, 'connect_callback' => sub {
        $count++;
        $msg->configure(-text => "Create $count of $poolsize threads . . .");
        $mw->update;
    }, 'cnd_callback' => sub {
      my $self = shift;
      $msg->configure(-text => "There are ".$self->count_waiting." jobs waiting and ".$self->count_running." jobs running.");
    });

my $tbl_results = $mw->Table(-columns => 2, -scrollbars => 'e', -fixedrows => 1, -fixedcolumns => 2)->pack(-side => 'top');
$tbl_results->put(1, 1, "IP Address");
$tbl_results->put(1, 2, "Status");

my $i = 1;
foreach my $lo ($start..$end) {
  $i++;
  my $ip_addr = "$base.$lo";
  $tbl_results->put($i, 1, $ip_addr);
  my $status = $tbl_results->Label(-text => "Waiting . . .");
  $tbl_results->put($i, 2, $status);
  $TkPool->add_waiting_job(command => 'ping', params => [$ip_addr], start_callback => sub {
      $status->configure(-text => "Running . . .")
    }, return_callback => sub {
      $status->configure(-text => $_[0] ? "Host present" : "Host not present")
    });

}

&MainLoop;
