#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

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
use Prima 'Application';

# uncomment this to run the ### lines
use Smart::Comments;

{
  # Prima::Object post message
  my $obj = Prima::Object->new (onPostMessage => sub {
                                  ### onPostMessage(): @_
                                });
  $obj->post_message (123);
  exit 0;
}
{
  # mouse wheel args
  my $main = Prima::MainWindow->new
    (onMouseWheel => sub {
       shift;
       ### onMouseWheel: @_
     });
  Prima->run;
  exit 0;
}

{
  require Prima::PS::Drawable;
  my $drawable = Prima::PS::Drawable->create (onSpool => sub {
                                                open FH, '>/tmp/x' or die;
                                                print FH $_[1] or die;
                                                print $_[1];
                                              });
  my $w = $drawable->width;
  my $h = $drawable->height;
  ### $w
  ### $h

  $drawable->begin_doc;
  $drawable->color (cl::Black);

  # $drawable->fillPattern(fp::Solid);
  # $drawable->rop(rop::CopyPut);
  # $drawable->rop2(rop::CopyPut);
  #$drawable-> text_out( "Z", 100, 100);
  #$drawable-> text_out( "Z", 100, 100);

  $drawable->clipRect (0,0,$h,$w);;
  ### clip: $drawable->{'clipRect'}
  $drawable->bar (0,0, $w,$h);
  $drawable->new_page;

  $drawable->clipRect (0,0,$w,$h-2000);;
  ### clip: $drawable->{'clipRect'}
  $drawable->bar (0,0, $w,$h);
  $drawable->new_page;

  $drawable->clipRect (0,0,0,0);;
  ### clip: $drawable->{'clipRect'}
  $drawable->bar (0,0, $w,$h);

  # die "error:$@" unless $drawable-> begin_doc;
  # $drawable-> font-> size( 30);
  #$drawable-> text_out( "Z", 100, 100);

  $drawable->end_doc;
  exit 0;
}

{
  #   require Prima;
  #   require Prima::Const;
  Prima->import('Application');
  use Prima 'Application';

  #  Prima::MainWindow->new;

  #   use Prima::StdDlg;
  #   use Prima::FileDialog;
  #   my $dialog = Prima::FileDialog->create;
  #   $dialog->execute;

  require App::MathImage::Prima::About;
  my $about = App::MathImage::Prima::About->popup;
  #  $about->execute;

  Prima->run;
  exit 0;
}

{
  # sub expose {
    #           if ( $d-> begin_paint) {
    #              $d-> color( cl::Black);
    #              $d-> bar( 0, 0, $d-> size);
    #              $d-> color( cl::White);
    #              $d-> fill_ellipse( $d-> width / 2, $d-> height / 2, 30, 30);
    #              $d-> end_paint;
    #           } else {
    #              die "can't draw on image:$@";
    #           }
  exit 0;
}
