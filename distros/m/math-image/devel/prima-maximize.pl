#!/usr/bin/perl -w

# Copyright 2013 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Image is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Prima;
use Prima::Buttons;
use Prima::Label;
use Prima 'Application';

# uncomment this to run the ### lines
use Smart::Comments;

{
  # maximize menu
  my $main = Prima::MainWindow->new
    (size => [100,100],
     onWindowState => sub {
       my ($main, $windowstate) = @_;
       ### onWindowstate: $windowstate
       $main->menu->checked('fullscreen', $windowstate == ws::Maximized());
     },
     menuItems =>
     [ [ ef => "~View" =>
         [
          [ 'fullscreen', '~Fullscreen', sub {
              my ($main, $itemname) = @_;
              ### fullscreen menu entry, current: $main->menu->checked($itemname)
              flood($main);
              $main->windowState ($main->menu->checked($itemname)
                                  ? ws::Normal() : ws::Maximized()); # opposite
            } ],
         ]],
     ],
    );
  $main->insert ('Label',
                 text => 'Blah',
                 pack => { side => 'top' },
                );
  Prima->run;
  exit 0;
}
{
  # maximize buttons
  my $main = Prima::MainWindow->new (size => [100,100],
                                     onWindowState => sub {
                                       my ($main, $state) = @_;
                                       ### onWindowstate: $state
                                     });
  $main->insert ('Button',
                 text => 'Maximize',
                 pack => { side => 'top' },
                 onClick  => sub {
                   my ($button) = @_;
                   print "windowState was ",$main->windowState,"\n";
                   print "maximize\n";
                   flood($main);
                   $main->maximize;
                   print " windowState now ",$main->windowState,"\n";
                   print "\n";
                 });
  $main->insert ('Button',
                 text => 'Restore',
                 pack => { side => 'top' },
                 onClick  => sub {
                   my ($button) = @_;
                   print "windowState was ",$main->windowState,"\n";
                   print "restore\n";
                   flood($main);
                   $main->restore;
                   my $state = $main->windowState;
                   print " windowState now $state\n";
                   print "\n";
                 });
  Prima->run;

  sub flood {
    my ($main) = @_;
    $main->begin_paint or die "can't draw:$@";
    foreach (1 .. 100) {
      $main-> color( cl::Black);
      $main-> bar( 0, 0, $main-> size);
      $main-> color( cl::White);
      $main-> fill_ellipse( $main-> width / 2, $main-> height / 2, 30, 30);
    }
    $main-> end_paint;
  }
  exit 0;
}
{
  # maximize
  my $main = Prima::MainWindow->new (size => [100,100]);
  my $timer = Prima::Timer->create
    (timeout => 2000,
     onTick  => sub {
       my $state = $main->windowState;
       print "tick, state=$state\n";
       if ($state == ws::Maximized()) {
         print " set windowstate normal\n";
         $main->windowState(ws::Normal());
       } else {
         print " set windowstate maximized\n";
         $main->windowState(ws::Maximized());
         $state = $main->windowState;
         print " state now $state\n";
       }
     },
    );
  $timer->start;
  Prima->run;
  exit 0;
}

