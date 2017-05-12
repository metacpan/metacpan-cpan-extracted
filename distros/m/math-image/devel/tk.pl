#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use Tk;
use Scalar::Util;

# uncomment this to run the ### lines
use Smart::Comments;


{
  my $mw = MainWindow->new;
  require App::MathImage::Tk::Diagnostics;
  {
    my $diagnostics = App::MathImage::Tk::Diagnostics->new ($mw);
    $diagnostics->Show;
  }
  # {
  #   my $diagnostics = $mw->AppMathImageTkDiagnostics;
  #   $diagnostics->Show;
  # }
  MainLoop;
  exit 0;
}
{
  my $mw = MainWindow->new;
  require App::MathImage::Tk::About;
  {
    my $about = App::MathImage::Tk::About->new ($mw);
    $about->Show;
  }
  # {
  #   my $about = $mw->AppMathImageTkAbout;
  #   $about->Show;
  # }
  MainLoop;
  exit 0;
}

{
  require App::MathImage::Tk::About;
  require Class::ISA;
  my @classes = Class::ISA::super_path('App::MathImage::Tk::About');
  ### @classes

  dump_ISA('App::MathImage::Tk::About');
  sub dump_ISA {
    my ($class, $indent) = @_;
    $indent ||= 0;
    no strict 'refs';
    foreach my $isa (@{"${class}::ISA"}) {
      print ' 'x$indent,$isa,"\n";
      dump_ISA($isa,$indent+2);
    }
  }
  exit 0;
}

{
  use FindBin;
  my $progname = $FindBin::Script;

  my $mw = MainWindow->new;
  Scalar::Util::weaken($mw);
  # ### $mw

  my $label = $mw->Label(-text => 'hello');
  # $label->pack;
  Scalar::Util::weaken($label);
  ### $label

  my $id = $mw->after(10_000, sub { print "after\n"; });
  Scalar::Util::weaken($id);
  ### id class: ref $id
  ### $id

  use Devel::FindRef;
  print Devel::FindRef::track($id);

  my @ret = $mw->afterInfo($id);
  ### @ret

  MainLoop;
  exit 0;
}

{
  my $mw = MainWindow->new;
  require Tk::WidgetDump;
  my @configure = $mw->configure;
  ### @configure
  $mw->WidgetDump;
  MainLoop;
  exit 0;
}
{
  my $mw = MainWindow->new;
  my $label = $mw->Label(-text => 'hello');
  $label->pack;
  { my @wrap = $mw->wrapper;
    ### @wrap
  }
  { my @wrap = $label->wrapper;
    ### @wrap
  }
  MainLoop;
  exit 0;
}
{
  # pTk/tkProperty.c
  # get window Atom ?xid?
  # set window Atom type format value ?xid?
  #
  # WmWrapperCmd
  # tkWinWm.c empty
  # tkUnixWm.c (window,menuheight)
  #
  require Tk::OlWm;
  my $mw = MainWindow->new;
  print "wrapper ",$mw->wrapper,"\n";
  $mw->OL_DECOR(CLOSE  => 1,
                FOOTER => 0,
                HEADER => 0,
                RESIZE => 0,
                PIN    => 1,
                # ICON_NAME => flag,
               );
  # $mw->property('set','MY_PROP','INTEGER', 32, 123,$mw->wrapper,$mw->wrapper,$mw->wrapper);

  $mw->property('set','MY_STR', 'STRING', 8, 'hello',$mw->wrapper);

  #  $mw->property('set','MY_PROP_BY_ID','INTEGER',123,$mw->wrapper);

  # my @wrap = $mw->wrapper->[0];
  # ### @wrap
  # #my $xid = $mw->wrapper->[0];
  # my $xid = $wrap[0];

  my ($xid) = $mw->wrapper;
  ### $xid
  #  $xid = 0x1000003;
  print "name ",$mw->property('get','WM_NAME',$xid),"\n";
  #print "name ",$mw->property('get','WM_NAME'),"\n";
  MainLoop;
  exit 0;
}
