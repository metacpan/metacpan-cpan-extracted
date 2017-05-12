# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tk-TimePick.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

 use Test::More tests => 125;
# use Test::More "no_plan";
BEGIN { use_ok('Tk::TimePick') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
 use_ok('Tk');
 ok(my $mw = MainWindow->new());
 $mw->title("Test TimePick");
 $mw->geometry("+10+10");
 can_ok($mw, "TimePick");
 ok(my $tp = $mw->TimePick(
 	-order		=> "hms",
 	-separator	=> ':',
 	-seconds		=> "00",
 	-maxhours	=> 23,
 	));
 isa_ok($tp, "Tk::TimePick");
 isa_ok($tp, "Tk::Frame");
 can_ok($tp, "pack");
 ok($tp->pack());

 ok($tp->SetSeconds(10));
 can_ok($tp, "SecondsReduce");
 ok($tp->SecondsReduce()) for(1..5);
 ok(my $s_2 = $tp->Get_Seconds());		# AUTOLOAD
 cmp_ok($s_2, "==", 5);
 can_ok($tp, "SecondsIncrease");
 ok($tp->SecondsIncrease()) for(1..10);
 ok(my $s_3 = $tp->get_seconds());		# AUTOLOAD
 cmp_ok($s_3, "==", 15);

 ok($tp->SetMinutes(20));
 can_ok($tp, "MinutesReduce");
 ok($tp->MinutesReduce()) for(1..6);
 ok(my $m_2 = $tp->Get_minutes());		# AUTOLOAD
 cmp_ok($m_2, "==", 14);
 can_ok($tp, "MinutesIncrease");
 ok($tp->MinutesIncrease()) for(1..11);
 ok(my $m_3 = $tp->get_minutes());		# AUTOLOAD
 cmp_ok($m_3, "==", 25);

 ok($tp->SetHours(14));
 can_ok($tp, "HoursReduce");
 ok($tp->HoursReduce()) for(1..4);
 ok(my $h_2 = $tp->Get_Hours());		# AUTOLOAD
 cmp_ok($h_2, "==", 10);
 can_ok($tp, "HoursIncrease");
 ok($tp->HoursIncrease()) for(1..3);
 ok(my $h_3 = $tp->gethours());		# AUTOLOAD
 cmp_ok($h_3, "==", 13);

 can_ok($tp, "insert");
 ok($tp->insert("33::24::13"));
 ok(my $ts_1 = $tp->GetTimeString());
 can_ok($tp, "GetTimeString");		# AUTOLOAD
 cmp_ok($ts_1, "eq", "33::24::13");

 can_ok($tp, "SetTime");
 ok($tp->SetTime(7, 45, 40));
 ok(my $t_1 = $tp->GetTimeString());
 cmp_ok("7::45::40", "eq", $t_1);
 
 can_ok($tp, "SetSeconds");
 ok($tp->SetSeconds(33));
 ok(my $s_1 = $tp->GetSeconds());		# AUTOLOAD
 cmp_ok($s_1, "==", 33);

 can_ok($tp, "SetMinutes");
 ok($tp->SetMinutes(55));
 ok(my $m_1 = $tp->getminutes());		# AUTOLOAD
 cmp_ok($m_1, "==", 55);

 can_ok($tp, "SetHours");
 ok($tp->SetHours(14));
 ok(my $h_1 = $tp->get_hours());		# AUTOLOAD
 cmp_ok($h_1, "==", 14);

 ok($tp->SetSeparator('+'));
 can_ok($tp, "SetSeparator");		# AUTOLOAD
 ok(my $sep_1 = $tp->Get_Separator());
 can_ok($tp, "Get_Separator");		# AUTOLOAD
 cmp_ok($sep_1, "eq", '+');

 can_ok($tp, "SetOrder");
 ok($tp->SetOrder("smh"));
 ok(my $o_1 = $tp->get_Order());		# AUTOLOAD
 cmp_ok($o_1, "eq", "smh");

 can_ok($tp, "GetTime");
 ok(my $t_2 = $tp->GetTime());
 cmp_ok("33+55+14", "eq", $t_2);

 can_ok($tp, "SetMaxHours");
 ok($tp->SetMaxHours(12));
 ok(my $mh_1 = $tp->GetMaxHours());	# AUTOLOAD	
 cmp_ok($mh_1, "==", 12);

 ok($tp->SetRegexTimeFormat(qr/(\d{1,2})(.+?)(\d{1,2})(.+?)(\d{1,2})/o)); # AUTOLOAD
 can_ok($tp, "SetRegexTimeFormat");

 ok($tp->SetTimeString("12::45::22"));
 can_ok($tp, "SetTimeString");
 ok(my $string_1 = $tp->GetTimeString());
 can_ok($tp, "GetTimeString");
 cmp_ok($string_1, "eq", "12::45::22");
 ok($tp->insert("23<>44<>55"));
 ok(my $sep_2 = $tp->get_separator());	# AUTOLOAD
 can_ok($tp, "get_separator");
 cmp_ok($sep_2, "eq", "<>");

 ok($tp->SetOrder("hms"));
 ok($tp->SetSeparator(':'));
 ok($tp->SetMaxHours(23));
 ok($tp->SetSeconds(30));
 ok($tp->SetMinutes(30));
 ok($tp->SetHours(12));
 ok($tp->GetTime());

 can_ok($tp, "Subwidget");
 $tp->Subwidget("EntryTime")->configure(
 	-font		=> "{Times New Roman} 18 {bold}"
 	);
 for(qw/
 	ButtonSecondsReduce
 	ButtonSecondsIncrease
 	ButtonMinutesReduce
 	ButtonMinutesIncrease
 	ButtonHoursReduce
 	ButtonHoursIncrease
 	/)
 	{
 	$tp->Subwidget($_)->configure(
 		-font		=> "{Times New Roman} 14 {bold}",
 		);
 	}
 for(qw/
 	FrameSeconds
 	FrameMinutes
 	FrameHours
 	/)
 	{
 	$tp->Subwidget($_)->configure(
 		-background	=> "#00FF00"
 		);
 	}
 $mw->Button(
 	-text		=> "Exit",
 	-command	=> sub { exit(); },
 	)->pack();
#-------------------------------------------------
 $mw->after(2000, sub { $mw->destroy(); });
 MainLoop();
#-------------------------------------------------







