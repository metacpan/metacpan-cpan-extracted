# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
##############################################################################
# Last Modified on:     $Date: 2000/05/17 12:41:03 $
# By:                   $Author: unrzc9 $
# Version:              $Revision: 1.3 $
######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use lib './';
use web;
$loaded = 1;
print "web::version: $web::VERSION\n";
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
##############################################################################
print "(2) Starting security-filecheck...\n";
my $file = "/etc/passwd/abc123!@#$%^&*()_+|";

$file =~ s/[^$web::OKCHARS]//g;
print "\tfile = $file\n";
$file2 =  "/etc/passwd/abc123!@#$%^&*()_+|";
$file2 = Check_Name($file2);
print "\tfile = $file2\n";
print "ok 2\n";
##############################################################################
my @jahrliste = (1992, 1993, 1994, 1995, 1999, 2000, 1765, 1777, 1900, 1800, 1600, 1604);
print "(3) Checking for leapyear...\n";
for ($i=0; $i<=$#jahrliste; $i++) {
  print "\t$jahrliste[$i]: ";
  if (isLeapYear($jahrliste[$i])) {
   print "Leapyear\n";
  } else {
   print "---\n";
  }
} 
print "ok 3\n";
##############################################################################
print "(4) Negotiating system...\n";
print "\tSystem: $web::OS\n";
print "ok 4\n";
##############################################################################
print "(5) Testing Add_Days_to_Date()\n";
$startdate = "1.2.2000";
$modi_days = 27;
$enddate = Add_Days_to_Date($startdate,$modi_days);
print "\t$startdate + $modi_days Day(s) = $enddate\n";
$startdate = "31.1.2000";
$modi_days = 29;
$enddate = Add_Days_to_Date($startdate,$modi_days);
print "\t$startdate + $modi_days Day(s) = $enddate\n";
$startdate = "31.1.2000";
$modi_days = -31;
$enddate = Add_Days_to_Date($startdate,$modi_days);
print "\t$startdate + $modi_days Day(s) = $enddate\n";
print "ok 5\n";
##############################################################################
print "(6) Testing isIP()\n";
$ip = "131.188.3.9";
print "\tIP: $ip....";
if (isIP($ip)) {
  print "valid\n";
} else {
  print "invalid\n";
}
$ip = "hgs.2.34.32";
print "\tIP: $ip....";
if (isIP($ip)) {
  print "valid\n";
} else {
  print "invalid\n";
}
$ip = "0.-2.0.256";
print "\tIP: $ip....";
if (isIP($ip)) {
  print "valid\n";
} else {
  print "invalid\n";
}
print "ok 6\n";
##############################################################################
print "(7) Testing GetPassedDaysbyMonth()\n";
$month = 2;
print "Startmonth: $month\n";
$passed_days = GetPassedDaysbyMonth($month);
print "$passed_days days have passed, before the $month. month came\n";
print "ok 7\n";

