#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use lib qw(../lib);
use Wx::App::AnnualCal::MyFrame;

my ($actual, $ideal, $button, $btnID, $event, $year);

my $frame = Wx::App::AnnualCal::MyFrame->new
  (
   undef,                  # parent window
   -1,                     # default id value
   'Test',                 # title
  );
isa_ok($frame, 'Wx::App::AnnualCal::MyFrame', '$frame');

$actual = $frame->build();
$ideal = 1;
is($actual, $ideal, "Wx::App::AnnualCal::MyFrame method 'build()' successfully executed");

$actual = $frame->{yeartxt}->GetValue();
$ideal = $year = (localtime())[5] + 1900;
is($actual, $ideal, "correct value in text control = $actual");

$button = $frame->{nextbtn};
$btnID = $button->GetId();
$event = Wx::CommandEvent->new(&Wx::wxEVT_COMMAND_BUTTON_CLICKED, $btnID);
$actual = $button->GetEventHandler->ProcessEvent($event);
$ideal = 1;
is($actual, $ideal, "NEXT button click event successfully processed");
$actual = $frame->{yeartxt}->GetValue();
$ideal = ++$year;
is($actual, $ideal, "correct value in text control after NEXT button click = $actual");

$button = $frame->{priorbtn};
$btnID = $button->GetId();
$event = Wx::CommandEvent->new(&Wx::wxEVT_COMMAND_BUTTON_CLICKED, $btnID);
$actual = $button->GetEventHandler->ProcessEvent($event);
$ideal = 1;
is($actual, $ideal, "PRIOR button click event successfully processed");
$actual = $frame->{yeartxt}->GetValue();
$ideal = --$year;
is($actual, $ideal, "correct value in text control after PRIOR button click = $actual");

$frame->{param}->{year} = 2000;
$actual = $frame->update();
$ideal = 1;
is($actual, $ideal, "Wx::App::AnnualCal::MyFrame method 'build()' successfully executed");
$actual = $frame->{yeartxt}->GetValue();
is($actual, 2000, "correct value in text control for input year = $actual");

done_testing();
