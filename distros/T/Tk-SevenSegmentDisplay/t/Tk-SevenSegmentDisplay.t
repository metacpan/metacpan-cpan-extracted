#*** Tk-SevenSegmentDisplay.t ***#
# Copyright (C) 2009 by Torsten Knorr
# create-soft@freenet.de
# All rights reserved!
#-------------------------------------------------
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tk-SevenSegmentDisplay.t'
#-------------------------------------------------
 use Test::More tests => 88;
 #use Test::More 'no_plan';
#-------------------------------------------------
 BEGIN
 	{
 	use_ok('Tk');
 	use_ok('Tk::Frame');
 	use_ok('Tk::Canvas');
 	use_ok('Tk::SevenSegmentDisplay');
 	};
 	ok(7 == @{Tk::SevenSegmentDisplay::_PT_SEGMENTS()});	
 	ok(2 == @{Tk::SevenSegmentDisplay::_PT_COLON()});
 	ok(8 == @{Tk::SevenSegmentDisplay::_PT_DOT()});
#-------------------------------------------------
 my $mw = eval { MainWindow->new(); };
 warn("\n --- " . $@ . " --- \n") if($@);
#-------------------------------------------------
 SKIP:
 	{
 	skip("no tests without valid screen\n", 81)
 		unless(ref($mw) && $mw->isa('MainWindow'));
 	$mw->title('Test Tk-SevenSegmentDisplay');
 	$mw->geometry('+5+5');
 	can_ok($mw, 'SevenSegmentDisplay');
#-------------------------------------------------
# test a clock
 	ok(my $clock = $mw->SevenSegmentDisplay(
 		-format	=> 'dd:dd:dd'
 		));
 	isa_ok($clock, 'Tk::Frame');
 	isa_ok($clock, 'Tk::SevenSegmentDisplay');
 	can_ok($clock, 'CalculateDisplay');
 	can_ok($clock, 'DrawNew');
 	can_ok($clock, 'ChangeColor');
 	can_ok($clock, 'ChangeSequence');
 	can_ok($clock, 'SetValue');
 	can_ok($clock, 'SetInt');
 	can_ok($clock, 'Subwidget');
 	can_ok($clock, 'digitwidth');
 	can_ok($clock, 'digitheight');
 	can_ok($clock, 'space');
 	can_ok($clock, 'format');
 	can_ok($clock, 'background');
 	can_ok($clock, 'foreground');
 	$clock->configure(
 		-digitwidth => 109,
 		-digitheight	=> 186,
 		-space	=> 10
 		);
 	ok($clock->CalculateDisplay());
 	ok($clock->grid(
 		-row	=> 0,
 		-column	=> 0,
 		-sticky	=> 'w'
 		));
 	my ($s, $m, $h);
 	ok($clock->repeat(1000, sub
 		{
 		($s, $m, $h) = localtime();
 		if(0 != $h)
 			{
 			$clock->SetValue(1, $h / 10);
 			$clock->SetValue(2, $h % 10);
 			}
 		else
 			{
 			$clock->SetValue(1, 0);
 			$clock->SetValue(2, 0);
 			}
 		if(0 != $m)
 			{
 			$clock->SetValue(3, $m / 10);
 			$clock->SetValue(4, $m % 10);
 			}
 		else
 			{
 			$clock->SetValue(3, 0);
 			$clock->SetValue(4, 0);
 			}
 		if(0 != $s)
 			{
 			$clock->SetValue(5, $s / 10);
 			$clock->SetValue(6, $s % 10);
 			}
 		else
 			{
 			$clock->SetValue(5, 0);
 			$clock->SetValue(6, 0);
 			}
 		$clock->DrawNew();
 		}));
#-------------------------------------------------
# test date display
 	ok(my $date = $mw->SevenSegmentDisplay(
 		-format		=> 'dd-dd-dddd',
 		-space		=> 8,
 		-digitwidth	=> 50,
 		-digitheight	=> 128
 		)->grid(
 		-row	=> 1,
 		-column	=> 0,
 		-sticky	=> 'w'
 		));
 	isa_ok($date, 'Tk::Frame');
 	isa_ok($date, 'Tk::SevenSegmentDisplay');
 	can_ok($date, 'CalculateDisplay');
 	can_ok($date, 'DrawNew');
 	can_ok($date, 'ChangeColor');
 	can_ok($date, 'ChangeSequence');
 	can_ok($date, 'SetValue');
 	can_ok($date, 'SetInt');
 	can_ok($date, 'Subwidget');
 	can_ok($date, 'digitwidth');
 	can_ok($date, 'digitheight');
 	can_ok($date, 'space');
 	can_ok($date, 'format');
 	can_ok($date, 'background');
 	can_ok($date, 'foreground');
 	$date->configure(
		-foreground	=> '#0000FF',
 		-background	=> '#000000'
		);
 	ok($date->CalculateDisplay());
 	my ($day, $month, $year) = ((localtime())[3, 4, 5]);
 	$year += 1900;
 	$month++;
 	ok($date->SetValue(1, $day / 10));
 	ok($date->SetValue(2, $day % 10));
 	ok($date->SetValue(3, $month / 10));
 	ok($date->SetValue(4, $month % 10));
 	ok($date->SetValue(5, $year / 1000));
	$year %= 1000;
 	ok($date->SetValue(6, $year / 100));
 	$year %= 100;
 	ok($date->SetValue(7, $year / 10));
 	ok($date->SetValue(8, $year % 10));
 	ok($date->DrawNew());
#-------------------------------------------------
# test a counter
 	ok(my $counter = $mw->SevenSegmentDisplay(
 		-foreground	=> '#FF0000',
 		-background	=> '#5A0000',
 		-format		=> 'ddddddddd',
 		-space		=> 6,
 		)->grid(
 		-row	=> 2,
 		-column	=> 0,
 		-sticky	=> 'w'
 		));
 	ok($counter->CalculateDisplay());
 	isa_ok($counter, 'Tk::Frame');
 	isa_ok($counter, 'Tk::SevenSegmentDisplay');	
 	can_ok($counter, 'CalculateDisplay');
 	can_ok($counter, 'DrawNew');
 	can_ok($counter, 'ChangeColor');
 	can_ok($counter, 'ChangeSequence');
 	can_ok($counter, 'SetValue');
 	can_ok($counter, 'SetInt');
 	can_ok($counter, 'Subwidget');
 	can_ok($counter, 'digitwidth');
 	can_ok($counter, 'digitheight');
 	can_ok($counter, 'space');
 	can_ok($counter, 'format');
 	can_ok($counter, 'background');
 	can_ok($counter, 'foreground');
 	my $int = 0;
 	$counter->repeat(300, sub
 		{
 		$counter->SetInt($int++);
		$counter->ChangeSequence();
 		});
#------------------------------------------------- 	
# test sign
 	ok(my $sign = $mw->SevenSegmentDisplay(
 		-format	=> '-dd.dd-dd.dd',
 		-background	=> '#000000',
 		-foreground	=> '#FFFFFF',
 		)->grid(
 		-row	=> 3,
 		-column	=> 0,
 		-sticky	=> 'w'
 		));
 	ok($sign->CalculateDisplay());
 	isa_ok($sign, 'Tk::Frame');
 	isa_ok($sign, 'Tk::SevenSegmentDisplay');	
 	can_ok($sign, 'CalculateDisplay');
 	can_ok($sign, 'DrawNew');
 	can_ok($sign, 'ChangeColor');
 	can_ok($sign, 'ChangeSequence');
 	can_ok($sign, 'SetValue');
 	can_ok($sign, 'SetInt');
 	can_ok($sign, 'Subwidget');
 	can_ok($sign, 'digitwidth');
 	can_ok($sign, 'digitheight');
 	can_ok($sign, 'space');
 	can_ok($sign, 'format');
 	can_ok($sign, 'background');
 	can_ok($sign, 'foreground');
 	my $signvalue = 0;
 	my $flip_flop = 0;
 	$sign->repeat(1500, sub
 		{
 		if($flip_flop)
 			{
 			$sign->SetInt($signvalue);
			}
 		else
 			{
 			$sign->SetInt(abs($signvalue));
 			}
 		$sign->ChangeColor();
		$signvalue--;
 		$flip_flop ^= 1;
 		});
#-------------------------------------------------
 	ok($mw->after(30000, sub { $mw->destroy(); }));
 	MainLoop();
 	}
#-------------------------------------------------













