# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tk-Schedule.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

 use Test::More tests => 55;
# use Test::More "no_plan";
BEGIN { use_ok('Tk::Schedule') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
 use_ok('Tk');
 use_ok('Time::Local');
 ok(my $mw = MainWindow->new());
 isa_ok($mw, "MainWindow");

 can_ok($mw, "Schedule");
 ok(my @lt = localtime());
 $lt[0] = 30;
 $lt[1] = 30;
 $lt[2] = 12;
 ok(my $tl = timelocal(@lt));
 ok(my $s = $mw->Schedule(
 	-interval		=> 1,
 	-repeat		=> "once",
 	-command	=> sub { print("Hello World\n"); },
 	-comment	=> "send Message",
 	-scheduletime	=> $tl
 	));
 can_ok($s, "pack");
 ok($s->pack());
 can_ok($s, "configure");

 can_ok($s, "command");
 ok($s->command(sub { print("Hello World\n"); }));
 ok($s->configure(-command => sub { print("Hello World\n"); }));
 ok($s->command([\&Code, "Hello", "World", '!']));
 sub Code { print("Hello World\n"); }

 can_ok($s, "interval");
 ok($s->interval(2));
 ok($s->configure(-interval => 3));

 can_ok($s, "repeat");
 ok($s->repeat("daily"));
 ok($s->configure(-repeat => "monthly"));

 can_ok($s, "comment");
 ok($s->comment("send e-mail"));
 ok($s->configure(-comment => "send SMS"));

 can_ok($s, "scheduletime");
 ok($s->scheduletime(time()));

 can_ok($s, "insert");
 ok($s->insert());
 ok($s->insert(
 	-repeat		=> "once"
 	));
 ok($s->insert(
 	-command	=> sub { }
 	));
 ok($s->insert(
 	-comment	=> "new task"
 	));
 ok($s->insert(
 	-scheduletime	=> time()
 	));
 ok($s->insert(
 	-repeat		=> "hourly",
 	-command	=> sub { print("every hour\n"); },
 	-comment	=> "every hour",
 	-scheduletime	=> time()
 	));
 
 can_ok($s, "CheckForTime");
 ok($s->CheckForTime());

 ok(my $time = time());
 ok($s->{schedule}{$time} = [sub { }, "once", "comment"]);
 can_ok($s, "ReworkSchedule");
 ok($s->ReworkSchedule($time));

 can_ok($s, "AddTime");
 ok($s->AddTime());

 can_ok($s, "ShowSchedule");
 ok($s->ShowSchedule());

 $s->{listbox}->selectionSet(0);
 can_ok($s, "DeleteTime");
 ok($s->DeleteTime());

 can_ok($mw, "Button");
 ok(my $button_exit = $mw->Button(
 	-text	=> "Exit",
 	-command	=> sub {exit(); }
 	));
 can_ok($button_exit, "pack");
 ok($button_exit->pack());

 can_ok($s, "Subwidget");
 for(qw/
 	ScheduleEntryComment
 	ScheduleChooseDate
 	ScheduleTimePick
 	ScheduleRadioOnce
 	ScheduleRadioYearly
 	ScheduleRadioMonthly
 	ScheduleRadioWeekly
 	ScheduleRadioDaily
 	ScheduleRadioHourly
 	ScheduleListbox
 	ScheduleButtonDelete
 	ScheduleButtonAdd
 	/)
 	{
 	$s->Subwidget($_)->configure(
 		-font		=> "{Times New Roman} 12 {bold}"
 		);
 	}
 $s->Subwidget("ScheduleListbox")->configure(
 	-background	=> "#FFFFFF"
 	);
 $s->Subwidget("ScheduleChooseDate")->configure(
 	-orthodox	=> 0
 	);
 can_ok($mw, "destroy");
 can_ok($mw, "after");
 ok($mw->after(10000, sub { $mw->destroy(); }));
 can_ok($mw, "MainLoop");
 MainLoop();
#-------------------------------------------------








