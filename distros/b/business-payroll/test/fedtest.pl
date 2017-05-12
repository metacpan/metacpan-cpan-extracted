#!/usr/bin/perl
#Fedtest.pl
#to test the payroll modules
#JT Moree, moreejt@pcxperience.com
#Copyright 2002 Xperience, Inc.
#This package is released under the GNU General Public License.
#You should have recieved a copy of the GPL with it.
# Copyright (c) 2002 http://www.pcxperience.org  All rights reserved.
# $Id: fedtest.pl,v 1.3 2004/11/26 19:16:03 pcxuser Exp $

use strict;
use Business::Payroll::US::FedIncome;

my @testData;
my $fedIncome = Business::Payroll::US::FedIncome->new();

if (not defined $fedIncome)
{
        print "Error: Fed Income object was NOT created!\n";
        print $fedIncome->errorMessage();
}
else
{

 print "\nTesting error method\n";
 $fedIncome->error("Error: is set\n");
 print $fedIncome->errorMessage() . "\n";
 $fedIncome->{errorString} = "";
 $fedIncome->error(errorString => "Error2: is set");
 print $fedIncome->errorMessage() . "\n";

  print "\nTesting generateTable method\n";
  my @testData2 = (
         { period => "monthly", marital => "single", debug => 'yes', answer => "-1" },
  );
  for (my $i=0; $i < scalar @testData2; $i++)
  {
        my $result = $fedIncome->generateTable(date => '20010701', period => $testData2[$i]{period} , mariital =>$testData2[$i]{marital}, debug =>$testData2[$i]{debug});
        if (not defined $result)
        {  print "$fedIncome->errorMessage()\n"; }
        else
        {  print "$result\n"; }
  }

  print "\nTesting calculate method...\n";
  my @testData2 = (
  #      { gross => "alkdf",  date => '20010801', method => "", allowances => 0, period => "annual", marital => "single", 'round' => "yes", answer => "-undef"},
         {gross => "1000",  date => '20010801', method => "", allowances => 0, period => "weekly", marital => "single", 'round' => "yes", answer => "-197.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 1, period => "weekly", marital => "single", 'round' => "yes", answer => "-182.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 2, period => "weekly", marital => "single", 'round' => "yes", answer => "-167.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 3, period => "weekly", marital => "single", 'round' => "yes", answer => "-152.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 4, period => "weekly", marital => "single", 'round' => "yes", answer => "-137.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 5, period => "weekly", marital => "single", 'round' => "yes", answer => "-122.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 6, period => "weekly", marital => "single", 'round' => "yes", answer => "-107.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 7, period => "weekly", marital => "single", 'round' => "yes", answer => "-92.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 8, period => "weekly", marital => "single", 'round' => "yes", answer => "-77.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 9, period => "weekly", marital => "single", 'round' => "yes", answer => "-68.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 10, period => "weekly", marital => "single", 'round' => "yes", answer => "-59.00" },

         {gross => "400",  date => '20010801', method => "", allowances => 0, period => "daily", marital => "married", 'round' => "yes", answer => "-81.00" },

         {gross => "1000",  date => '20010801', method => "", allowances => 0, period => "weekly", marital => "married", 'round' => "yes", answer => "-138.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 1, period => "weekly", marital => "married", 'round' => "yes", answer => "-124.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 2, period => "weekly", marital => "married", 'round' => "yes", answer => "-115.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 3, period => "weekly", marital => "married", 'round' => "yes", answer => "-107.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 4, period => "weekly", marital => "married", 'round' => "yes", answer => "-99.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 5, period => "weekly", marital => "married", 'round' => "yes", answer => "-90.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 6, period => "weekly", marital => "married", 'round' => "yes", answer => "-82.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 7, period => "weekly", marital => "married", 'round' => "yes", answer => "-74.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 8, period => "weekly", marital => "married", 'round' => "yes", answer => "-65.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 9, period => "weekly", marital => "married", 'round' => "yes", answer => "-57.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 10, period => "weekly", marital => "married", 'round' => "yes", answer => "-48.00" },

         {gross => "255",  date => '20010801', method => "", allowances => 0, period => "biweekly", marital => "married", 'round' => "yes", answer => "-1.00" },
         {gross => "255",  date => '20010801', method => "", allowances => 1, period => "biweekly", marital => "married", 'round' => "yes", answer => "-0.00" },
         {gross => "255",  date => '20010801', method => "", allowances => 2, period => "biweekly", marital => "married", 'round' => "yes", answer => "-0.00" },
         {gross => "255",  date => '20010801', method => "", allowances => 3, period => "biweekly", marital => "married", 'round' => "yes", answer => "-0.00" },
         {gross => "255",  date => '20010801', method => "", allowances => 4, period => "biweekly", marital => "married", 'round' => "yes", answer => "-0.00" },
         {gross => "255",  date => '20010801', method => "", allowances => 5, period => "biweekly", marital => "married", 'round' => "yes", answer => "-0.00" },
         {gross => "255",  date => '20010801', method => "", allowances => 6, period => "biweekly", marital => "married", 'round' => "yes", answer => "-0.00" },
         {gross => "255",  date => '20010801', method => "", allowances => 7, period => "biweekly", marital => "married", 'round' => "yes", answer => "-0.00" },
         {gross => "255",  date => '20010801', method => "", allowances => 8, period => "biweekly", marital => "married", 'round' => "yes", answer => "-0.00" },
         {gross => "255",  date => '20010801', method => "", allowances => 9, period => "biweekly", marital => "married", 'round' => "yes", answer => "-0.00" },
         {gross => "255",  date => '20010801', method => "", allowances => 10, period => "biweekly", marital => "married", 'round' => "yes", answer => "-0.00" },

         {gross => "2321",  date => '20010801', method => "", allowances => 0, period => "monthly", marital => "single", 'round' => "yes", answer => "-318.00" },
         {gross => "2321",  date => '20010801', method => "", allowances => 1, period => "monthly", marital => "single", 'round' => "yes", answer => "-282.00" },
         {gross => "2321",  date => '20010801', method => "", allowances => 2, period => "monthly", marital => "single", 'round' => "yes", answer => "-245.00" },
         {gross => "2321",  date => '20010801', method => "", allowances => 3, period => "monthly", marital => "single", 'round' => "yes", answer => "-209.00" },
         {gross => "2321",  date => '20010801', method => "", allowances => 4, period => "monthly", marital => "single", 'round' => "yes", answer => "-173.00" },
         {gross => "2321",  date => '20010801', method => "", allowances => 5, period => "monthly", marital => "single", 'round' => "yes", answer => "-137.00" },
         {gross => "2321",  date => '20010801', method => "", allowances => 6, period => "monthly", marital => "single", 'round' => "yes", answer => "-100.00" },
         {gross => "2321",  date => '20010801', method => "", allowances => 7, period => "monthly", marital => "single", 'round' => "yes", answer => "-64.00" },
         {gross => "2321",  date => '20010801', method => "", allowances => 8, period => "monthly", marital => "single", 'round' => "yes", answer => "-28.00" },
         {gross => "2321",  date => '20010801', method => "", allowances => 9, period => "monthly", marital => "single", 'round' => "yes", answer => "-0.00" },
         {gross => "2321",  date => '20010801', method => "", allowances => 10, period => "monthly", marital => "single", 'round' => "yes", answer => "-0.00" },

         {gross => "16",  date => '20010801', method => "", allowances => 0, period => "daily", marital => "single", 'round' => "yes", answer => "-1.00" },
         {gross => "5880",  date => '20010801', method => "", allowances => 0, period => "monthly", marital => "married", 'round' => "yes", answer => "-1003.00" },
         {gross => "5880",  date => '20010801', method => "", allowances => 1, period => "monthly", marital => "married", 'round' => "yes", answer => "-937.00" },
         {gross => "5880",  date => '20010801', method => "", allowances => 2, period => "monthly", marital => "married", 'round' => "yes", answer => "-872.00" },
         {gross => "5880",  date => '20010801', method => "", allowances => 3, period => "monthly", marital => "married", 'round' => "yes", answer => "-807.00" },
         {gross => "5880",  date => '20010801', method => "", allowances => 4, period => "monthly", marital => "married", 'round' => "yes", answer => "-742.00" },
         {gross => "5880",  date => '20010801', method => "", allowances => 5, period => "monthly", marital => "married", 'round' => "yes", answer => "-676.00" },
         {gross => "5880",  date => '20010801', method => "", allowances => 6, period => "monthly", marital => "married", 'round' => "yes", answer => "-611.00" },
         {gross => "5880",  date => '20010801', method => "", allowances => 7, period => "monthly", marital => "married", 'round' => "yes", answer => "-546.00" },
         {gross => "5880",  date => '20010801', method => "", allowances => 8, period => "monthly", marital => "married", 'round' => "yes", answer => "-508.00" },
         {gross => "5880",  date => '20010801', method => "", allowances => 9, period => "monthly", marital => "married", 'round' => "yes", answer => "-472.00" },
         {gross => "5880",  date => '20010801', method => "", allowances => 10, period => "monthly", marital => "married", 'round' => "yes", answer => "-436.00" },

         {gross => "1000",  date => '20010801', method => "", allowances => 7, period => "weekly", marital => "single", 'round' => "yes", answer => "-92.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 8, period => "weekly", marital => "single", 'round' => "yes", answer => "-77.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 9, period => "weekly", marital => "single", 'round' => "yes", answer => "-68.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 10, period => "weekly", marital => "single", 'round' => "yes", answer => "-59.00" },

         {gross => "400",  date => '20010801', method => "", allowances => 0, period => "daily", marital => "married", 'round' => "yes", answer => "-81.00" },

         {gross => "1000",  date => '20010801', method => "", allowances => 0, period => "weekly", marital => "married", 'round' => "yes", answer => "-138.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 1, period => "weekly", marital => "married", 'round' => "yes", answer => "-124.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 2, period => "weekly", marital => "married", 'round' => "yes", answer => "-115.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 3, period => "weekly", marital => "married", 'round' => "yes", answer => "-107.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 4, period => "weekly", marital => "married", 'round' => "yes", answer => "-99.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 5, period => "weekly", marital => "married", 'round' => "yes", answer => "-90.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 6, period => "weekly", marital => "married", 'round' => "yes", answer => "-82.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 7, period => "weekly", marital => "married", 'round' => "yes", answer => "-74.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 8, period => "weekly", marital => "married", 'round' => "yes", answer => "-65.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 9, period => "weekly", marital => "married", 'round' => "yes", answer => "-57.00" },
         {gross => "1000",  date => '20010801', method => "", allowances => 10, period => "weekly", marital => "married", 'round' => "yes", answer => "-48.00" },

         {gross => "255",  date => '20010801', method => "", allowances => 0, period => "biweekly", marital => "married", 'round' => "yes", answer => "-1.00" },
         {gross => "255",  date => '20010801', method => "", allowances => 1, period => "biweekly", marital => "married", 'round' => "yes", answer => "-0.00" },
         {gross => "255",  date => '20010801', method => "", allowances => 2, period => "biweekly", marital => "married", 'round' => "yes", answer => "-0.00" },
         {gross => "255",  date => '20010801', method => "", allowances => 3, period => "biweekly", marital => "married", 'round' => "yes", answer => "-0.00" },
         {gross => "255",  date => '20010801', method => "", allowances => 4, period => "biweekly", marital => "married", 'round' => "yes", answer => "-0.00" },
         {gross => "255",  date => '20010801', method => "", allowances => 5, period => "biweekly", marital => "married", 'round' => "yes", answer => "-0.00" },
         {gross => "255",  date => '20010801', method => "", allowances => 6, period => "biweekly", marital => "married", 'round' => "yes", answer => "-0.00" },
         {gross => "255",  date => '20010801', method => "", allowances => 7, period => "biweekly", marital => "married", 'round' => "yes", answer => "-0.00" },
         {gross => "255",  date => '20010801', method => "", allowances => 8, period => "biweekly", marital => "married", 'round' => "yes", answer => "-0.00" },
         {gross => "255",  date => '20010801', method => "", allowances => 9, period => "biweekly", marital => "married", 'round' => "yes", answer => "-0.00" },
         {gross => "255",  date => '20010801', method => "", allowances => 10, period => "biweekly", marital => "married", 'round' => "yes", answer => "-0.00" },

         {gross => "2321",  date => '20010801', method => "", allowances => 0, period => "monthly", marital => "single", 'round' => "yes", answer => "-318.00" },
         {gross => "2321",  date => '20010801', method => "", allowances => 1, period => "monthly", marital => "single", 'round' => "yes", answer => "-282.00" },
         {gross => "2321",  date => '20010801', method => "", allowances => 2, period => "monthly", marital => "single", 'round' => "yes", answer => "-245.00" },
         {gross => "2321",  date => '20010801', method => "", allowances => 3, period => "monthly", marital => "single", 'round' => "yes", answer => "-209.00" },
         {gross => "2321",  date => '20010801', method => "", allowances => 4, period => "monthly", marital => "single", 'round' => "yes", answer => "-173.00" },
         {gross => "2321",  date => '20010801', method => "", allowances => 5, period => "monthly", marital => "single", 'round' => "yes", answer => "-137.00" },
         {gross => "2321",  date => '20010801', method => "", allowances => 6, period => "monthly", marital => "single", 'round' => "yes", answer => "-100.00" },
         {gross => "2321",  date => '20010801', method => "", allowances => 7, period => "monthly", marital => "single", 'round' => "yes", answer => "-64.00" },

#2002
         {gross => "16",  date => '20020801', method => "", allowances => 0, period => "daily", marital => "single", 'round' => "yes", answer => "-1.00" },
         {gross => "16",  date => '20020801', method => "", allowances => 5, period => "daily", marital => "single", 'round' => "yes", answer => "-0.00" },
         {gross => "5830",  date => '20020801', method => "", allowances => 6, period => "monthly", marital => "married", 'round' => "yes", answer => "-520.00" },
         {gross => "6000",  date => '20020801', method => "", allowances => 3, period => "monthly", marital => "married", 'round' => "yes", answer => "-771.76" },
         {gross => "1000",  date => '20020801', method => "", allowances => 8, period => "weekly", marital => "single", 'round' => "yes", answer => "-68.00" },
#2003
         {gross => "224",  date => '20030101', method => "", allowances => 0, period => "daily", marital => "single", 'round' => "yes", answer => "-44.00" },
         {gross => "224",  date => '20030101', method => "", allowances => 5, period => "daily", marital => "married", 'round' => "yes", answer => "-19.00" },
         {gross => "5830",  date => '20030101', method => "", allowances => 6, period => "monthly", marital => "married", 'round' => "yes", answer => "-514.00" },
         {gross => "3000",  date => '20030101', method => "", allowances => 3, period => "monthly", marital => "single", 'round' => "yes", answer => "-281.00" },
         {gross => "6000",  date => '20030101', method => "", allowances => 2, period => "monthly", marital => "married", 'round' => "yes", answer => "-828.49" },
         {gross => "16",  date => '20030801', method => "", allowances => 0, period => "daily", marital => "single", 'round' => "yes", answer => "-1.00" },
         {gross => "16",  date => '20030801', method => "", allowances => 5, period => "daily", marital => "single", 'round' => "yes", answer => "-1.00" },
         {gross => "400",  date => '20030801', method => "", allowances => 2, period => "weekly", marital => "married", 'round' => "yes", answer => "-13.00" },
         {gross => "3000",  date => '20030801', method => "", allowances => 3, period => "monthly", marital => "single", 'round' => "yes", answer => "-274.00" },
         {gross => "6000",  date => '20030801', method => "", allowances => 8, period => "monthly", marital => "married", 'round' => "yes", answer => "-430.40" },
  );
  print "GROSS\tEXPECT\tACTUAL\tY/N\n";
  for (my $i=0; $i < scalar @testData2; $i++)
  {
     print "$testData2[$i]{gross}\t$testData2[$i]{answer}\t";
      my $answer = $fedIncome->calculate(
        gross => $testData2[$i]{gross},
        date => $testData2[$i]{date},
        method => $testData2[$i]{method},
        allowances => $testData2[$i]{allowances},
        period => $testData2[$i]{period},
        marital => $testData2[$i]{marital},
        'round' => $testData2[$i]{'round'},
        debug => "no"
        );
     if (not defined $answer)
     {
        my $error = $fedIncome->errorMessage;
        print "\nError: $error  ";
     }
     else
     {
        print "$answer\t";
     }
     my $diff = $answer - $testData2[$i]{answer};
     my $float ;
     if ($answer == 0)
     { $float = 0; }
     else
     {
       $float = ($diff)/$answer * 100 ;
     }
     $float =~s/^-//;
     print  sprintf("%.2f", $float) . " %" ;
     if ($float <= 5.0 )
     { print "\tY "; }
     else
     {
       print "\tN   $testData2[$i]{date}, $testData2[$i]{allowances}, $testData2[$i]{period}, $testData2[$i]{marital}, $testData2[$i]{'round'},  $testData2[$i]{method} ";
     }
     print "\n";
  }

}
