# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
use Win32;
BEGIN { plan tests => 1 };
use Win32::TaskScheduler;
ok(1); # If we made it this far, we're ok.

#########################

$taskMGR1 = Win32::TaskScheduler->New();
$taskMGR2 = Win32::TaskScheduler->New();
ok(1);

@a = $taskMGR1->Enum();
foreach $tsk (@a) { print "$tsk\n";}
ok(1);

#########################

$tsk1 = shift @a; 
$taskMGR1->Activate($tsk1);
print "1. $tsk1 running as =" . $taskMGR1->GetAccountInformation() . "\n";
$tsk2 = shift @a; 
$taskMGR2->Activate($tsk2);
print "2. $tsk2 running as =" . $taskMGR2->GetAccountInformation() . "\n";
ok(1);

#########################

print "---using taskMGR1---\n";
print "$tsk1 is working in " . $taskMGR1->GetWorkingDirectory() . ".\n";
for(my $i=0;$i<$taskMGR1->GetTriggerCount();$i++)
	{ print "$tsk1 ($i) scheduled at " . $taskMGR1->GetTriggerString($i) . "\n"; }
print "---using taskMGR2---\n";
print "$tsk2 is working in " . $taskMGR2->GetWorkingDirectory() . ".\n";
for(my $i=0;$i<$taskMGR2->GetTriggerCount();$i++)
	{ print "$tsk2 ($i) scheduled at " . $taskMGR2->GetTriggerString($i) . "\n"; }
ok(1);

#########################

print "\n\n---using taskMGR1---\n";
@a = $taskMGR1->Enum();
foreach my $tsk (@a) { 
$taskMGR1->Activate($tsk);
for(my $i=0;$i<$taskMGR1->GetTriggerCount();$i++)
	{ 
	$taskMGR1->GetTrigger($i,\%Trigger);
	foreach my $key (keys %Trigger)
		{\print "$tsk ($i): Trigger\{$key\}=" . $Trigger{$key} . "\n"; }
	}
}
ok(1);

#########################

print "***Now I'll modify a trigger...Get/SetTrigger***\n";
print "Working on $a[0].\n";
$taskMGR1->Activate($a[0]);
$taskMGR1->GetTrigger(0,\%OldTrigger);
print "Begin Year is: $OldTrigger{BeginYear}, will be changed to $OldTrigger" . ($OldTrigger{BeginYear}+1) . "\n";
%NewTrigger=%OldTrigger;
$NewTrigger{BeginYear}+=1;
#print $NewTrigger{BeginYear};
$taskMGR1->SetTrigger(0,\%NewTrigger);
$taskMGR1->Save();
print "Now checking changes...\n";
$taskMGR1->Activate($a[0]);
undef %Trigger;
$taskMGR1->GetTrigger(0,\%Trigger);
print "Begin Year is: $Trigger{BeginYear}\n";
if ($Trigger{BeginYear} == $NewTrigger{BeginYear})
	{ print "\tTest Successful.\n"; }
else { print "\tTest Failed.\n"; }
$taskMGR1->SetTrigger(0,\%OldTrigger);
$taskMGR1->Save();
undef %Trigger;
$taskMGR1->Activate($a[0]);
$taskMGR1->GetTrigger(0,\%Trigger);
print "Begin Year has been restored to: $Trigger{BeginYear}\n";
ok(1);

print "***Now I'll Create a trigger...CreateTrigger***\n";
print "Working on $a[0].\n";
undef %OldTrigger;
$taskMGR1->Activate($a[0]);
$taskMGR1->GetTrigger(0,\%OldTrigger);
$taskMGR1->CreateTrigger(\%OldTrigger);
$taskMGR1->Save();
ok(1);

#########################
print "***Get/SetMaxRunTime***\n";
print "Working on $a[0].\n";
$taskMGR1->Activate($a[0]);
$maxRunTime=$taskMGR1->GetMaxRunTime();
$taskMGR1->SetMaxRunTime($maxRunTime+(60*1000)); # adding a minute
$taskMGR1->Save();
$taskMGR1->Activate($a[0]);
if ($maxRunTime+(60*1000) == $taskMGR1->GetMaxRunTime()) { ok(1); }
else { print "Test failed:" . $maxRunTime . "\n"; }
