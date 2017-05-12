#! perl

use lib 'blib/lib';
use lib 'blib/arch';

use Win32::Monitoring::WindowPing qw(:all);

use Data::Dumper;

while(1){
   sleep(1);
   my $HWND = GetActiveWindow();
   print Dumper($HWND);

   my $result = PingWindow($HWND, 5);
   print Dumper($result);

   my $status = PingStatus($result);
   print Dumper($status);

   my $caption = GetWindowCaption($HWND);
   print Dumper($caption);

   my $processid = GetProcessIdForWindow($HWND);
   print Dumper($processid);

   my $nameforprocid = GetNameForProcessId($processid);
   print Dumper($nameforprocid);
  
}

