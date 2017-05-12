use Win32::TaskScheduler;

$scheduler=Win32::TaskScheduler->New();

#
# This adds a daily schedule.
#
#%trig=(
#	'BeginYear' => 2001,
#	'BeginMonth' => 10,
#	'BeginDay' => 20,
#	'StartHour' => 14,
#	'StartMinute' => 10,
#	'TriggerType' => $scheduler->TASK_TIME_TRIGGER_DAILY,
#	'Type'=>{
#		'DaysInterval' => 3,
#	},
#);

%trig2=(
	'BeginYear' => 2001,
	'BeginMonth' => 10,
	'BeginDay' => 20,
	'StartHour' => 14,
	'StartMinute' => 10,
	'TriggerType' => $scheduler->TASK_TIME_TRIGGER_MONTHLYDOW,
	'Type'=>{
		'WhichWeek' => $scheduler->TASK_FIRST_WEEK,
		'DaysOfTheWeek' => $scheduler->TASK_FRIDAY | $scheduler->TASK_MONDAY,
		'Months' => $scheduler->TASK_JANUARY | $scheduler->TASK_APRIL | $scheduler->TASK_JULY | $scheduler->TASK_OCTOBER,
	},
);

%trig=(
	'BeginYear' => 2001,
	'BeginMonth' => 10,
	'BeginDay' => 20,
	'StartHour' => 14,
	'StartMinute' => 10,
	'TriggerType' => $scheduler->TASK_TIME_TRIGGER_MONTHLYDATE,
	'Type'=>{
		'Months' => $scheduler->TASK_JANUARY | $scheduler->TASK_APRIL | $scheduler->TASK_JULY | $scheduler->TASK_OCTOBER,
		'Days' => 15,
	},
);

%trig3=(
	'BeginYear' => 2001,
	'BeginMonth' => 10,
	'BeginDay' => 20,
	'StartHour' => 14,
	'StartMinute' => 10,
	'TriggerType' => $scheduler->TASK_TIME_TRIGGER_MONTHLYDATE,
	'Type'=>{
		'Months' => $scheduler->TASK_JANUARY | $scheduler->TASK_APRIL | $scheduler->TASK_JULY | $scheduler->TASK_OCTOBER,
		'Days' => 10,
	},
);

$tsk="alfred";

foreach $k (keys %trig) {print "$k=" . $trig{$k} . "\n";}

print $scheduler->NewWorkItem($tsk,\%trig);
print $scheduler->SetApplicationName("winword.exe");

print $scheduler->Save();
$scheduler->Activate($tsk);

$triggerCount=$scheduler->GetTriggerCount();
for ($i=0;$i<$triggerCount;$i++) {
	$scheduler->GetTrigger($i,\%trg);
	foreach $k (keys %trg) {
		if ($k eq "Type") {
			print "TYPE\n";
			$newhash=$trg{$k};
			foreach $c (keys %{$newhash}) {
				print "$c=" . $newhash->{$c} . "\n";
			}
		} else {
			print "$k=" . $trg{$k} . "\n";
		}
	}
}

$scheduler->CreateTrigger(\%trig2);
$scheduler->CreateTrigger(\%trig3);
print $scheduler->Save();