#! perl

use lib 'blib/lib';
use lib 'blib/arch';

use Win32::OLE;
use Win32::Monitoring::DLLInject;
use Data::Dumper;

my $WshShell = Win32::OLE->new("WScript.Shell");
$WshShell->Run("notepad", 5);

sleep(1);

my %processes;

for my $line (`tasklist /v /nh`) {
 chomp($line);
 if ( $line ne "" ) {
  # extract PID
  my $pid = substr($line, 26, 8);
  # remove leading spaces
  $pid =~ s/^ *([0-9]+)$/$1/g;

  # extract process
  my $proc = substr($line, 0, 24);#.substr($line, 152, 72);
  # change multiple spaces to single spaces
  $proc =~ s/\s\s\s*/ /g;
  # remove trailing space
  $proc =~ s/\s$//g;
  # remove trailing N/A
  $proc =~ s/ N\/A$//g;

  # print tab seperated fields
  # print $pid, " ", $proc, "\n";
  $processes{$proc} = $pid;
  } 
}

my $P = Win32::Monitoring::DLLInject->new($processes{'notepad.exe'},'Y:\\perl\\Win32-Monitoring-DLLInject\\HookedFunctions.dll');

print Dumper($P);

while(1)
{
    sleep(1);
    my $msg_cnt = $P->StatMailSlot();
    for (my $i = 0; $i < $msg_cnt; $i++) {
        print $P->GetMessage(), "\n";
     }
}


