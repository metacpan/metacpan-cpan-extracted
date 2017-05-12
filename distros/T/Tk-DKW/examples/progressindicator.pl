#! /usr/bin/perl

use Tk;

use Tk::ProgressIndicator;

my $l_MainWindow = MainWindow->new();

my $l_ProgressIndicator = $l_MainWindow->ProgressIndicator
   (
    '-current' => 0,
    '-limit' => 200,
    '-increment' => 10,
    '-height' => 20,
    '-width' => 400
   );

$l_AfterID = $l_MainWindow->repeat (500, sub {Repeater();});

$l_Counter = 0;

$l_ProgressIndicator->pack();

Tk::MainLoop();

sub Repeater
   {
    $l_ProgressIndicator->configure ('-current' => $l_Counter);

    if (($l_Counter += 10) > 200)
       {
        $l_MainWindow->afterCancel ($l_AfterID);
       }
   }