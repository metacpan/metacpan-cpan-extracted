#!/usr/local/bin/perl

# Callbacks demo program

use strict;
use Tk;
use Tk::Button;
use Tk::Checkbutton;
use Tk::LabFrame;
use Tk::Label;
use Tk::Listbox;
use Tk::NoteBook;
use Tk::Radiobutton;
use Tk::Text;

my $mw=MainWindow->new(-title=>'Callbacks demo');

use vars qw/$work_mode $todo/;

my $schedule = $mw -> NoteBook (  ) -> pack(-side=>'top', -fill=>'x', -anchor=>'nw', -padx=>10, -pady=>10);
my $workday = $schedule -> add ( 'workday', -justify=>'left', -label=>'working day', -state=>'normal' );
my $work_hard = $workday -> Checkbutton ( -text=>'Work mode', -variable=>\$work_mode, -relief=>'flat', -offvalue=>'snooze', -indicatoron=>0, -onvalue=>'work_hard', -justify=>'left', -selectcolor=>'Red', -command=>sub{print "work mode=$work_mode\n"}, -state=>'normal' ) -> pack();
my $Alternatives = $workday -> LabFrame ( -labelside=>'acrosstop', -relief=>'ridge', -label=>'Alternatives' ) -> pack();
my $make_phone_call = $Alternatives -> Radiobutton ( -text=>'Ring to mom', -variable=>\$todo, -relief=>'flat', -indicatoron=>1, -value=>'phone', -justify=>'left', -state=>'normal' ) -> pack(-anchor=>'nw');
my $take_a_coffe = $Alternatives -> Radiobutton ( -text=>'Take a cup of coffe', -variable=>\$todo, -relief=>'flat', -indicatoron=>1, -value=>'drink', -justify=>'left', -state=>'normal' ) -> pack();
my $vacation = $schedule -> add ( 'vacation', -label=>'vacation' );
my $flyto = $vacation -> Listbox ( -selectmode=>'single', -relief=>'sunken' ) -> pack(-side=>'left');
my $postcard_lbl = $vacation -> Label ( -text=>'postcard:', -relief=>'flat', -justify=>'left' ) -> pack();
my $postcard = $vacation -> Text ( -relief=>'sunken', -height=>6, -wrap=>'none', -width=>21, -state=>'normal' ) -> pack();
my $Help = $vacation -> Button ( -text=>'Help', -relief=>'raised', -command=>\&help, -state=>'normal' ) -> pack(-side=>'top', -anchor=>'n', -pady=>5);
my $status_button = $mw -> Button ( -text=>'Press to see the status', -relief=>'raised', -command=>\&show_status, -state=>'normal' ) -> pack(-pady=>15);
my $exit_button = $mw -> Button ( -text=>'Exit: you have 3 attempts!', -relief=>'raised', -command=>\&say_bye, -state=>'normal' ) -> pack();
MainLoop;

#===vptk end===
sub show_status
{
  print "Current status:\nWorking: $work_mode\nNow you have: $todo\n";
}

my $z;

sub help
{
  print "Help! Anybody Help Me!...\n";
}

sub say_bye
{
  $z++;
  print "Good bye #$z!\n";
  return if $z<3;
  exit;
}
