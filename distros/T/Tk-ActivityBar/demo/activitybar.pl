#!/usr/bin/perl -w

use Tk;
use Tk::ActivityBar;

$WINDOW_WIDTH = 500;
$WINDOW_HEIGHT = 300;

$mw = MainWindow->new;

$screen_width = $mw->screenwidth();
$screen_height = $mw->screenheight();
$mw->geometry(sprintf("%dx%d+%d+%d", $WINDOW_WIDTH, $WINDOW_HEIGHT, 
		      $screen_width / 2 - $WINDOW_WIDTH / 2,
		      2 * $screen_height / 5 - $WINDOW_HEIGHT / 2));

$begin = $mw->Frame()->pack(-fill => 'both', -expand =>1);

$activity = $begin->ActivityBar(-anchor => 'w')->pack(-expand => 1);

$begin->Button(-text => 'Activity', -command => [$activity => 'startActivity'])
  ->pack(-anchor => 'se');
$begin->Button(-text => 'Increment', -command => 
	       sub { my $x = $activity->cget('-value');
		     $activity->configure('-value' => $x+5); })
  ->pack(-anchor => 'se');

MainLoop();
