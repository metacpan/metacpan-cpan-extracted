use Win32::TaskScheduler;

$scheduler=Win32::TaskScheduler->New();

$scheduler->SetTargetComputer("\\\\MYHOST");

foreach my $tsk ($scheduler->Enum()) {
  $scheduler->Activate($tsk);
  my $acct = $scheduler->GetAccountInformation();
  print "$tsk currently running as ($acct)\n";
  
  $pri=-1;
  $scheduler->GetPriority($pri);
  print "Task $tsk is running with priority: $pri but should be " . $scheduler->HIGH_PRIORITY_CLASS . "\n";
  
  if ($acct ne 'Domain\CorrectUser') {
 	$scheduler->SetAccountInformation("DOMAIN\\correctuser","password");
	$scheduler->Save();
   print "Task $tsk now runng as (DOMAIN\\correctuser)\n";
  }
}