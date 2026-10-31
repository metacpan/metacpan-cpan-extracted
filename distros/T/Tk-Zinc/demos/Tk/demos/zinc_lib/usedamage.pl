#!/usr/bin/perl -w
#
# Use damage test
#
# $Id$
# this simple test has been developped by A.Lemort lemort@intuilab.com


use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

use strict;
use Tk;
use Tk::Zinc;
use Tk::LabFrame;
use Time::HiRes;


#
# Mainwindow
#
my $mw = new MainWindow();
$mw->title("10.000 rectangles and a drag-n-droppable circle");

#
# Text zone
#
my $text = $mw->Scrolled(qw/Text -relief sunken -borderwidth 2 -setgrid true -height 8 -scrollbars e/);
$text->pack(-expand => 1, -fill => 'both');

$text->insert('0.0',
              'This toy-app illustrates how the -usedamage property can increase TkZinc performance.
The Following operations are possible:
   Press "0" to desactivate OpenGL optimization
   Press "1" to activate OpenGL optimization (same result as the old GL_DAMAGE compilation flag). These optimizations work well with Nvidia cards but it creates a strange trail effect with other cards (black trails)
   Press "2" to activate OpenGL optimization. These optimizations are a bit slower but they have a much better compatibility'
	      );

#
# Zinc
#
my $zinc = $mw->Zinc(
		     -render => 1,
		     -usedamage => 0,
		     -relief => 'flat',
		     -borderwidth => 0,
		     -highlightthickness => 0,
		     -width => 700,
		     -height => 600,
		     )->pack(
			     -expand => 1,
			     -fill => 'both',
			     );

# Seed our random generator
srand(1234567890);

# Add a lot of rectangles
my $Nrect = 10000;
foreach my $i (0...$Nrect) {
    $zinc->add('rectangle', 1, [50 + rand()*500, 50 + rand()*500, 50 + rand()*500, 50 + rand()*500], -filled => 1, -fillcolor => 'blue');
}

# Add a label
my $label = $zinc->add('text', 1, -position => [5, 10], -text => 'usedamage=0: Without OpenGL optimization');

# Add a moveable circle
my $circle = $zinc->add('arc', 1, [0,0,50,50], -filled => 1, -fillcolor => 'red', -linewidth => 2);
$zinc->translate($circle, 50, 50);

# Add bindings to move our circle
my ($X, $Y);
$zinc->bind($circle, '<ButtonPress-1>',[\&press, Ev('x'), Ev('y')]);
$zinc->bind($circle, '<B1-Motion>', [\&motion, Ev('x'), Ev('y')]);


# Add bindings to change the value of usedamage
$mw->bind('<KeyPress-0>', sub {
    # No optimization
    $zinc->configure(-usedamage => 0);
    $zinc->itemconfigure($label, -text => 'usedamage=0: Without OpenGL optimization');
});
$mw->bind('<KeyPress-1>', sub {
    # OpenGL optimization (best with Nvidia
    $zinc->configure(-usedamage => 1);
    $zinc->itemconfigure($label, -text => 'usedamage=1: With OpenGL optimization (better performance but works only with Nvidia cards)');
});
$mw->bind('<KeyPress-2>', sub {
    # OpenGL optimization (best with Nvidia
    $zinc->configure(-usedamage => 2);
    $zinc->itemconfigure($label, -text => 'usedamage=2: With OpenGL optimization (a bit slower but much better compatibility)');
});


#
# Commands
#

# Benchmark data
my $N = 50;
my $delta = 550/$N;

my $commandFrame = $mw->Frame()->pack(-expand => 1, -fill => 'both');
my $commandFrameTitle = $commandFrame->LabFrame(
                                                -label => 'Automatic benchmark: trasnlate our circle from top-left to bottom-right ('.$N.' steps)',
                                                )->pack(
                                                        -side => 'bottom',
                                                        -fill => 'both',
                                                        -expand => 1,
                                                        );

foreach my $i (0...2) {
   my $value = $i;
   
   # Label: display result
   my $label = $commandFrameTitle->Label(
                                         -text => 'Press button to start benchmark',
                                         )->grid(
                                                 -row => $i,
                                                 -column => 1,
                                                 );

   my $button = $commandFrameTitle->Button(
                                           -text => 'Test usedamage='.$value,
                                           -command => sub {
                                             benchmarkUsedamage($label, $value);
                                           },
                                           )->grid(
                                                   -row => $i,
                                                   -column => 0,
                                                   );
}


# Mainloop
MainLoop;



#
# Press
# 
sub press {
    my ($zinc, $x, $y) = @_;
    $X = $x;
    $Y = $y;
}


#
# Motion
#
sub motion {
    my ($zinc, $x, $y) = @_;
    $zinc->translate($circle, $x - $X, $y - $Y);
    $X = $x;
    $Y = $y;
}


#
# Benchmark usedamage
#
sub benchmarkUsedamage {
   my ($label, $usedamage) = @_;

   # Get usedamage value
   my $previousValue = $zinc->cget('-usedamage');

   # Force redisplay
   $zinc->tset($circle, 1, 0, 0, 1, 0, 0);
   $zinc->itemconfigure($circle, -sensitive => 0);
   $zinc->configure(-usedamage => $usedamage);
   $zinc->update();

   # Get current time
   my ($s0, $micros0) = Time::HiRes::gettimeofday();
   
   # Move our circle
   foreach my $i (1...$N) {
      $zinc->translate($circle, $delta, $delta);
      $zinc->update();
   }

   # Get current time
   my ($s, $micros) = Time::HiRes::gettimeofday();
   
   # Calculate delta time in ms
   my $time = ($s - $s0)*1000 + ($micros - $micros0)/1000;
   
   # Display time
   $label->configure(-text => $time.' ms');
   
   # Restore usedamage
   $zinc->configure(-usedamage => $previousValue);
   $zinc->itemconfigure($circle, -sensitive => 1);
}
