#!/usr/bin/perl
#statetest.pl
#to test the payroll modules
#JT Moree, moreejt@pcxperience.com
#Copyright 2002 Xperience, Inc.
#This package is released under the GNU General Public License.
#You should have recieved a copy of the GPL with it.
# Copyright (c) 2002 http://www.pcxperience.org  All rights reserved.
# $Id: MOtest.pl,v 1.3 2004/10/08 20:02:20 pcxuser Exp $

use strict;
use Business::Payroll::US::MO::StateIncome;

my @testData;
my $stateIncome = Business::Payroll::US::MO::StateIncome->new();

if (not defined $stateIncome)
{
        print "Error: State Income object was NOT created!\n";
        print $stateIncome->errorMessage();
}
else
{
  print "\nTesting for valid data in StateIncome . . . periodDays\n";
  foreach my $period (keys %{$stateIncome->{periodDays}})
  {
    print "$stateIncome->{periodDays}->{$period} \t: $period\n";
  }
  print "\n. . . dataTables\n";
  foreach my $period (keys %{$stateIncome->{dataTables}})
  {
    print "$period\n";
    print "  $stateIncome->{dataTables}->{$period}->{federalLimit}->{single}\t: Federal Limit (single)\n";
    print "  $stateIncome->{dataTables}->{$period}->{federalLimit}->{married}\t: Federal Limit (married)\n";
    print "  $stateIncome->{dataTables}->{$period}->{federalLimit}->{spouseWorks}\t: Federal Limit (Spouse Works)\n";
    print "  Standard Deductions\n";
    foreach my $ded ( keys %{$stateIncome->{dataTables}->{$period}->{standardDeduction}} )
    {  print "    $stateIncome->{dataTables}->{$period}->{standardDeduction}->{$ded}\t: $ded\n";  }
    for (my $x = 1; $x <= 5; $x++)
    {
      my $allow = "allowance" . $x;
      print "  Allowance $x\n";
      foreach my $ded (keys %{$stateIncome->{dataTables}->{$period}->{$allow}})
      {  print "    $stateIncome->{dataTables}->{$period}->{$allow}->{$ded}\t: $ded\n";  }
    }
  }

  print "\nTesting annualize methods...\n";
  @testData = (
        ["annual", 0 , 0] ,
        ["annual", 1000 , 1000] ,
        ["daily", 1 , 260] ,
        ["weekly", 1 , 52] ,
        ["monthly", 1 , 12] ,
        ["biweekly", 1 , 26] ,
        ["semimonthly",  1, 24] ,
        ["quarterly",  1, 4] ,
        ["semiannual",  1, 2] ,
        ["foobar", 45 , 'nodef'] ,
        ["daily", -22 , 'nodef' ] ,
        ["nodef", "nodef" , 'nodef'] ,
        ["daily", -22 , 'nodef' ] ,
   );
  print "PERIOD      \tAMOUNT\tEXPECT      FORWARD\tY/N\tREVERSE\tY/N\n";
  for (my $i=0; $i < scalar @testData; $i++)
  {
    print "$testData[$i][0]    \t$testData[$i][1]\t: $testData[$i][2]\t?= ";
   my $answer = $stateIncome->annualize(period =>$testData[$i][0], amount => $testData[$i][1]);
   my $reverse = $stateIncome->annualize(reverse => "yes", period =>$testData[$i][0], amount => $testData[$i][2]);
    if (not defined $answer)
    {  $answer = "nodef"; }
    if (not defined $reverse)
    {  $reverse = "nodef"; }
    print " $answer     ";
    if ($answer eq $testData[$i][2])
    {  print "\t Y";    }
    else
    {  print "\t N";    }
    print "\tR: $reverse";
    if ($reverse eq $testData[$i][1])
    {  print "\t Y";    }
    else
    {  print "\t N";    }
    print "\n";
  }
  print "\nTesting lookupDate...\n";
  @testData = (
        ["20020101", "20020101"] ,
        ["20020101", "40020101"] ,
        ["19990101", "19990909"] ,
        ["undef    ", "19000101"] ,
        ["undef    ", "foobar   "] ,
  );
  print "INPUT\t\tEXPECT\t\tACTUAL\t\tY/N\n";
  for (my $i=0; $i < scalar @testData; $i++)
  {
     print "$testData[$i][1]\t$testData[$i][0]\t";
     my $answer = $stateIncome->lookupDate(date => $testData[$i][1]);
     if (not defined $answer)
     { $answer = "undef    "; }
     print "$answer\t";
     if ($answer eq $testData[$i][0])
     { print "Y"; }
     else
     {  print "N"; }
     print "\n";
  }
  print "\nTesting calculate method...\n";
  @testData = (
        { gross => "12adf45",  date => '20050101', method => "", allowances => 0, period => "monthly", marital => "single", federal => 0, fYTD => 0, 'round' => "yes", answer => "undef"},
        { gross => 0,  date => '20020101', method => "", allowances => 0, period => "monthly", marital => "single", federal => 0, fYTD => 0, 'round' => "yes", answer => '0.00'},
        { gross => 10,  date => '20020101', method => "", allowances => 0, period => "annual", marital => "single", federal => 0, fYTD => 0, 'round' => "yes", answer => '0.00'},
        { gross => 100,  date => '20020101', method => "", allowances => 0, period => "annual", marital => "single", federal => 0, fYTD => 0, 'round' => "yes", answer => '0.00'},
        { gross => 1000,  date => '20020101', method => "", allowances => 0, period => "semimonthly", marital => "single", federal => 121, fYTD => 0, 'round' => "yes", answer => '-32.00'},
        { gross => 10000,  date => '20020101', method => "", allowances => 0, period => "semimonthly", marital => "single", federal => '2944', fYTD => 0, 'round' => "yes", answer => '-566.00'},
        { gross => 5000,  date => '19990501', method => "", allowances => 0, period => "semimonthly", marital => "single", federal => '1242.00', fYTD => 0, 'round' => "yes", answer => '-266.00'},
        { gross => 10000,  date => '', method => "", allowances => 0, period => "annual", marital => "single", federal => 0, fYTD => 0, 'round' => "yes", answer => '0.00'},
  );
  print "GROSSt\tEXPECT\tACTUAL\tY/N\n";
  for (my $i=0; $i < scalar @testData; $i++)
  {
     print "$testData[$i]{gross}\t$testData[$i]{answer}\t";
      my $answer = $stateIncome->calculate(
        gross => $testData[$i]{gross},
        date => $testData[$i]{date},
        method => $testData[$i]{method},
        allowances => $testData[$i]{allowances},
        period => $testData[$i]{period},
        marital => $testData[$i]{marital},
        federal => $testData[$i]{federal},
        fYTD => $testData[$i]{fYTD},
        'round' => $testData[$i]{'round'}
        );
     if (not defined $answer)
     {
        my $error = $stateIncome->errorMessage;
        print "Error: $error  ";
     }
     else
     {
        print "$answer\t";
     }
     if ($answer eq $testData[$i]{answer})
     { print "Y"; }
     else
     {  print "N"; }
     print "\n";
  }

}
