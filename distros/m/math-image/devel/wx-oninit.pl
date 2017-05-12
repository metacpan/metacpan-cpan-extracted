#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

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

use 5.004;
use strict;
use Wx;

# uncomment this to run the ### lines
use Devel::Comments;

{
  package myApp;
  use base 'Wx::App';
  sub OnInit {
    ### myApp OnInit() ...
    return ['hello'];
  }
}
{
  package myFrame ;
  use base 'Wx::Frame';
  use Wx qw( wxDEFAULT_FRAME_STYLE );

  sub new {
    my $app = shift ;
    my( $frame ) = $app->SUPER::new( $_[0] , -1, 'wxPerl Test' ,
                                     [0,0] , [400,300] ) ;
    return( $frame ) ;
  }
}

use Wx;
my $myApp = myApp->new;

# my $win = Wx::Frame->new($myApp, Wx::wxID_ANY(), 'my frame', [0,0], [400,300]);
my $win = myFrame->new;
$win->Show(1) ;

$myApp->MainLoop();
