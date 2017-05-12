#!/usr/bin/perl
#to test the payroll modules
#JT Moree, moreejt@pcxperience.com
#Copyright 2002 Xperience, Inc.
#This package is released under the GNU General Public License.
#You should have recieved a copy of the GPL with it.
# Copyright (c) 2002 http://www.pcxperience.org  All rights reserved.
# $Id: medtest.pl,v 1.4 2004/11/26 19:16:03 pcxuser Exp $

use strict;
use Business::Payroll::US::Medicare;

my @testData;
my $Medicare = Business::Payroll::US::Medicare->new(debug => "yes");

if (not defined $Medicare)
{
        print "Error: Medicare object was NOT created!\n";
        print $Medicare->errorMessage();
}
else
{
 print "\nTesting rateCap method\n";
 my @rateCap = $Medicare->rateCap("20020101");
 if (@rateCap[1] eq "")
 { print "Error! rateCap Failed!\n".$Medicare->errorMessage."\n";}
 else
 { print "Rate: '$rateCap[0]'\nCap: '$rateCap[1]'\n\n"; }

 print "\nTesting error method\n";
 $Medicare->error("Error:  is set");
 print $Medicare->errorMessage() . "\n";
 $Medicare->{errorString} = "";
 $Medicare->error(errorString => "Error2: set");
 print $Medicare->errorMessage() . "\n";

 print "\nTesting Date methods\n";
 my $result = $Medicare->firstDate() ;
 if (defined $result)
 {  print "First: " . $result . " \n"; }
 else
 { print $Medicare->errorMessage(); }
 $result = $Medicare->lastDate() ;
 if (defined $result)
 {  print "Last: " . $result . " \n"; }
 else
 { print $Medicare->errorMessage(); }
 $result = $Medicare->lookupDate(date=> "20010101")    ;
 if (defined $result)
 {  print "Lookup: " . $result . " \n"; }
 else
 { print $Medicare->errorMessage(); }

  print "\nTesting calculate method...\n";
  my @testData2 = (
         {gross => "1000",  date => '20010801', YTD => '0', round => "no", answer => "-14.50" },
         {gross => "1000",  date => '19960801', YTD => '0', round => "no", answer => "" },
         {gross => "1000",  date => '20010801', YTD => '80399', round => "no", answer => "-14.50" },
         {gross => "1000",  date => '20010801', YTD => '80400', round => "no", answer => "-14.50" },
         {gross => "1000",  date => '20010801', YTD => '80500', round => "no", answer => "-14.50" },
         {gross => "100",  date => '20010801', YTD => '1', round => "no", answer => "-1.45" },
         {gross => "1000",  date => '20010801', YTD => '80300', round => "no", answer => "-14.50" },
  );
  print "GROSS\tEXPECT\tACTUAL\tY/N\n";
  for (my $i=0; $i < scalar @testData2; $i++)
  {
     print "$testData2[$i]{gross}\t$testData2[$i]{answer}\t";
      my $answer = $Medicare->calculate(
        gross => $testData2[$i]{gross},
        date => $testData2[$i]{date},
        round => $testData2[$i]{'round'},
        YTD => $testData2[$i]{YTD},
        debug => "yes"
        );
     if (not defined $answer)
     {
        my $error = $Medicare->errorMessage;
        print "\nError: $error  ";
     }
     else
     {
        print "$answer\t";
     }
     if ($answer eq $testData2[$i]{answer})
     { print "Y"; }
     else
     {  print "N"; }
     print "\n";
  }

}
