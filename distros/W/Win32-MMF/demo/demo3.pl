use strict;
use warnings;
use Data::Dumper;
use CGI;

# Process synchronization between processes
# Object Oriented Approach

# fork a process
defined(my $pid = fork()) or die "Can not fork a child process!";

if ($pid) {
   require Win32::MMF;
   my $ns1 = new Win32::MMF;

   my $cgi = new CGI;
   my $hash = {a=>[1,2,3], b=>4, c=>"A\0B\0C\0"};
   my $str = "Hello World!";

   $ns1->setvar("HASH", $hash);
   $ns1->setvar("CGI", $cgi);
   $ns1->setvar("STRING", $str);

   print "--- PROC1 - Sent ---\n";
   print Dumper($hash), "\n";
   print Dumper($cgi), "\n";
   print Dumper($str), "\n";

   # signal proc 2
   $ns1->setvar("SIG", 1);

   # wait for ACK variable to come alive
   while (!$ns1->getvar("ACK")) {};
   $ns1->setvar("ACK", '');

   # debug current MMF structure
   $ns1->debug();

} else {
   require Win32::MMF;
   my $ns1 = new Win32::MMF;

   while (!$ns1->getvar("SIG")) {};
   $ns1->setvar("SIG", '');

   my $cgi = $ns1->getvar("CGI");
   my $str = $ns1->getvar("STRING");
   my $hash = $ns1->getvar("HASH");

   print "--- PROC2 - Received ---\n";
   print Dumper($hash), "\n";
   print Dumper($cgi), "\n";

   print "--- PROC2 - Use Received Object ---\n";
   # use the object from another process :-)
   print $cgi->header(),
         $cgi->start_html(), "\n",
         $cgi->end_html(), "\n\n";

   # signal proc 1
   $ns1->setvar("ACK", 1);
}

