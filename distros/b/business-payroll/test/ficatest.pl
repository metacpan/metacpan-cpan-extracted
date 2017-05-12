#!/usr/bin/perl
#to test the payroll modules
#JT Moree, moreejt@pcxperience.com
#Copyright 2002 Xperience, Inc.
#This package is released under the GNU General Public License.
#You should have recieved a copy of the GPL with it.
# Copyright (c) 2002 http://www.pcxperience.org  All rights reserved.
# $Id: ficatest.pl,v 1.4 2004/11/26 19:16:03 pcxuser Exp $

use strict;
use Business::Payroll::US::FICA;

my @testData;
my $FICA = Business::Payroll::US::FICA->new(debug => "yes");

if (not defined $FICA)
{
        print "Error: FICA object was NOT created!\n";
        print $FICA->errorMessage();
}
else
{
 print "\nTesting rateCap method\n";
 my @rateCap = $FICA->rateCap("20020101");
 if (@rateCap[1] eq "")
 { print "Error! rateCap Failed!\n".$FICA->errorMessage."\n";}
 else
 { print "Rate: '$rateCap[0]'\nCap: '$rateCap[1]'\n\n"; }
 print "\nTesting error method\n";
 $FICA->error("Error:  is set");
 print $FICA->errorMessage() . "\n";
 $FICA->{errorString} = "";
 $FICA->error(errorString => "Error2: set");
 print $FICA->errorMessage() . "\n";

 print "\nTesting Date methods\n";
 my $result = $FICA->firstDate() ;
 if (defined $result)
 {  print "First: " . $result . " \n"; }
 else
 { print $FICA->errorMessage(); }
 $result = $FICA->lastDate() ;
 if (defined $result)
 {  print "Last: " . $result . " \n"; }
 else
 { print $FICA->errorMessage(); }
 $result = $FICA->lookupDate(date=> "20010101")    ;
 if (defined $result)
 {  print "Lookup: " . $result . " \n"; }
 else
 { print $FICA->errorMessage(); }

  print "\nTesting calculate method...\n";
  my @testData2 = (
         {gross => "1000",  date => '20010801', YTD => '800.00', round => "no", answer => "-62.00" },
         {gross => "100",  date => '20010801', YTD => '79999.99', round => "no", answer => "-6.20" },
         {gross => "1000",  date => '20010801', YTD => '80399', round => "no", answer => "-0.06" },
         {gross => "1000",  date => '20010801', YTD => '80400', round => "no", answer => "0.00" },
         {gross => "1000",  date => '20010801', YTD => '80500', round => "no", answer => "0.00" },
         {gross => "1000",  date => '20010801', YTD => '80300', round => "no", answer => "-6.20" },
         {gross => "1000",  date => '19960801', YTD => '0', round => "no", answer => "" },
  );
  print "GROSS\tEXPECT\tACTUAL\tY/N\n";
  for (my $i=0; $i < scalar @testData2; $i++)
  {
     print "$testData2[$i]{gross}\t$testData2[$i]{answer}\t";
      my $answer = $FICA->calculate(
        gross => $testData2[$i]{gross},
        date => $testData2[$i]{date},
        round => $testData2[$i]{'round'},
        YTD => $testData2[$i]{YTD},
        debug => "no"
        );
     if (not defined $answer)
     {
        my $error = $FICA->errorMessage;
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
