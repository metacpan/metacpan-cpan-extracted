#!/usr/bin/perl -w
#
#  Small level 2.5 teletext browser
#
#  Copyright (C) 2007 Tom Zoerner
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

# $Id: browse-ttx.pl,v 1.2 2007/12/02 18:30:50 tom Exp tom $

use strict;
use blib;
use IO::Handle;
use Tk;
use Video::ZVBI qw(/^VBI_/);

my $pxc;
my $cap;
my $vtdec;
my $dec_entry = 100;
my $pg_disp = -1;
my $pg_sched = 0x100;
my $pg_lab = "Page ###.##";

my $tk;
my $canvas;
my $img_xpm;
my $font = ['courier', -12];
my $mode_xpm = 1;
my $redraw;

#
# This callback is invoked by the teletext decoder for every ompleted page.
# The function updates the page number display on top of the window and
# updates the display if the scheduled page has been captured.
#
sub pg_handler {
   my($type, $ev, $user_data) = @_;

   $pg_lab = sprintf "Page %03x.%02x ", $ev->{pgno}, $ev->{subno} & 0xFF;

   if ($ev->{pgno} == $pg_sched) {
      $redraw = 1;
   }
}

#
# This function is called every 10ms to capture VBI data.
# VBI frames are sliced and forwarded to the teletext decoder.
#
sub cap_frame {
   my $sliced;
   my $timestamp;
   my $n_lines;
   my $res;

   $res = $cap->pull_sliced($sliced, $n_lines, $timestamp, 50);
   die "Capture error: $!\n" if $res < 0;

   if ($res > 0) {
      $vtdec->decode($sliced, $n_lines, $timestamp);
   }

   if ($redraw) {
      pg_display();
      $redraw = 0;
   }
}

#
# This function is called once during start-up to initialize the
# device capture context and the teletext decoder
#
sub cap_init {
   my $opt_device = "/dev/vbi0";
   my $opt_buf_count = 5;
   my $opt_services = VBI_SLICED_TELETEXT_B;
   my $opt_strict = 0;
   my $opt_verbose = 0;
   my $err;

   $pxc = Video::ZVBI::proxy::create($opt_device, $0, 0, $err, $opt_verbose);
   if (defined $pxc) {
      $cap = Video::ZVBI::capture::proxy_new($pxc, 5, 0, $opt_services, $opt_strict, $err);
      undef $pxc unless defined $cap;
   }
   if (!defined $cap) {
      $cap = Video::ZVBI::capture::v4l2_new($opt_device, $opt_buf_count, $opt_services, $opt_strict, $err, $opt_verbose);
   }
   if (!defined $cap) {
      $cap = Video::ZVBI::capture::v4l_new($opt_device, 0, $opt_services, $opt_strict, $err, $opt_verbose);
   }
   if (!defined $cap) {
      $cap = Video::ZVBI::capture::bktr_new($opt_device, 0, $opt_services, $opt_strict, $err, $opt_verbose);
   }
   die "Failed to open video device: $err\n" unless $cap;

   $vtdec = Video::ZVBI::vt::decoder_new();
   die "failed to create teletext decoder\n" unless defined $vtdec;

   $vtdec->event_handler_add(VBI_EVENT_TTX_PAGE, \&pg_handler); 

   # install a Tk event handler for capturing in the background
   my $io = new IO::Handle;
   $io->fdopen($cap->fd(), 'r');
   $tk->fileevent($io, 'readable', \&cap_frame);
}

#
# This function is invoked out of the capture event handler when the page
# which is scheduled for display has been captured.
#
sub pg_display_xpm {
   my $pg = $vtdec->fetch_vt_page($pg_sched, 0, VBI_WST_LEVEL_3p5, 25, 1);
   if (defined $pg) {
      my ($h, $w) = $pg->get_page_size();

      # export page in XPM format (only supported starting with 0.2.26)
      my $err;
      my $ex = Video::ZVBI::export::new('xpm', $err);
      if (defined $ex) {
         # suppress all XPM extensions because Pixmap can't handle them
         $ex->option_set('creator', "") or die;
         $ex->option_set('titled', 0) or die;
         $ex->option_set('transparency', 0) or die;
         my $tmp = $ex->alloc($pg);
         $img_xpm = $tk->Pixmap(-data, $tmp);

      } else {
         my $fmt;
         # conversion of 8-bit palette image format into XPM is faster, so prefer that if supported
         if (Video::ZVBI::check_lib_version(0,2,26)) {
            $fmt = VBI_PIXFMT_PAL8;
         } else {
            $fmt = VBI_PIXFMT_RGBA32_LE;
         }
         my $img_canvas = $pg->draw_vt_page($fmt);
         undef $img_xpm;
         $img_xpm = $tk->Pixmap(-data, $pg->canvas_to_xpm($img_canvas, $fmt, 1));
      }

      $canvas->delete('all');
      $canvas->createImage(0, 0, -anchor, 'nw', -image, $img_xpm);
      $canvas->configure(-width, $img_xpm->width(), -height, $img_xpm->height());
      $pg_disp = $pg_sched;
   }
}

sub vbi_rgba {
   sprintf "#%02X%02X%02X", $_[0]&0xff, ($_[0]>>8)&0xff, ($_[0]>>16)&0xff;
}
sub pg_display_text {
   my $pg = $vtdec->fetch_vt_page($pg_sched, 0, VBI_WST_LEVEL_3p5, 25, 1);
   if (defined $pg) {
      $canvas->delete('all');
      my ($rows, $columns) = $pg->get_page_size();
      my $pal = $pg->get_page_color_map();
      my $text = $pg->get_page_text();
      my $prop = $pg->get_page_text_properties();
      my $fh = $canvas->fontMetrics($font, -linespace);
      my $fw = $canvas->fontMeasure($font, '0');
      my $i = 0;
      for (my $row = 0; $row < $rows; $row++) {
         for (my $col = 0; $col < $columns; $col++, $i++) {
            my $pp = $prop->[$i];
            $canvas->createRectangle($col * $fw, $row * $fh,
                                     ($col+1) * $fw, ($row+1) * $fh,
                                     -outline, undef,
                                     -fill, vbi_rgba($pal->[($pp>>8) & 0xFF]));
            $canvas->createText($col * $fw, $row * $fh,
                                -text, substr($text, $i, 1),
                                -anchor, 'nw', -font, $font,
                                -fill, vbi_rgba($pal->[$pp & 0xFF]));
         }
      }
      $canvas->configure(-width, $columns * $fw, -height, $rows * $fh);
      $pg_disp = $pg_sched;
   }
}

sub pg_display {
   if ($mode_xpm) {
      pg_display_xpm();
   } else {
      pg_display_text();
   }
}

#
# This callback is invoked when the user clicks into the teletext page.
# If there's a page number of FLOF link under the mouse pointer, the
# respective page is scheduled for display.
#
sub pg_link {
   my ($wid, $x, $y) = @_;

   if ($pg_disp != -1) {
      my $pg = $vtdec->fetch_vt_page($pg_disp, VBI_ANY_SUBNO, VBI_WST_LEVEL_1p5, 25, 1);
      my $fh;
      my $fw;
      if (defined $pg) {
         if ($mode_xpm) {
            # note: char width 12, char height 10*2 due to scaling in XPM conversion
            $fh = 20;
            $fw = 12;
         } else {
            $fh = $canvas->fontMetrics($font, -linespace);
            $fw = $canvas->fontMeasure($font, '0');
         }

         my $h = $pg->resolve_link($x / $fw, $y / $fh);
         if ($h->{type} == VBI_LINK_PAGE) {
            $pg_sched = $h->{pgno};
            $dec_entry = sprintf "%03X", $pg_sched;
            $redraw = 1;
         }
      }
   }
}

#
# This callback is invoked when the user hits the left/right buttons
# (actually this is redundant to the +/- buttons in the spinbox)
#
sub pg_plus_minus {
   my ($off) = @_;

   if ($off >= 0) {
      $off = 1;
   } else {
      $off = 0xF9999999;
   }
   $pg_sched = Video::ZVBI::add_bcd($pg_sched, $off);
   $pg_sched = 0x899 if $pg_sched < 0x100;
   $dec_entry = sprintf "%03X", $pg_sched;
   $redraw = 1;
}

#
# This callback is invoked when the user edits the page number
#
sub pg_change {
   if ($dec_entry =~ /^\d+$/) {
      $pg_sched = Video::ZVBI::dec2bcd($dec_entry);
      $redraw = 1;
   }
}

#
# This callback is invoked when the user hits the "TOP" button
# to display the TOP page table
#
sub pg_top_index {
   $pg_sched = 0x900;
   $dec_entry = 900;
   $redraw = 1;
}

#
# This function is called once during start-up to create the GUI.
#
sub gui_init {
   $tk = MainWindow->new();
   $tk->title('Teletext Level 2.5 Demo');
   $tk->resizable(0, 0);

   # frame holding control widgets at the top of the window
   my $wid_f1 = $tk->Frame();
   my $wid_f1_sp = $wid_f1->Spinbox(-from, 100, -to, 899, -width, 5,
                                    -textvariable, \$dec_entry,
                                    -command, \&pg_change);
   $wid_f1_sp->bind('<Return>', \&pg_change);
   $wid_f1_sp->pack(-side, "left", -anchor, "w");
   my $wid_f1_lab = $wid_f1->Label(-textvariable, \$pg_lab);
   $wid_f1_lab->pack(-side, "left",);
   $wid_f1->pack(-side, "top", -fill, "x");
   my $wid_f1_but1 = $wid_f1->Button(-text, "<<", -command, [\&pg_plus_minus, -1], -padx, 1);
   my $wid_f1_but2 = $wid_f1->Button(-text, ">>", -command, [\&pg_plus_minus, 1], -padx, 1);
   my $wid_f1_but3 = $wid_f1->Button(-text, "TOP", -command, [\&pg_top_index], -padx, 1);
   $wid_f1_but1->pack(-side, "left", -anchor, "e");
   $wid_f1_but2->pack(-side, "left", -anchor, "e");
   $wid_f1_but3->pack(-side, "left", -anchor, "e");
   my $wid_f1_mode = $wid_f1->Checkbutton(-variable, \$mode_xpm, -text, "XPM",
                                          -command, sub {$redraw = 1;});
   $wid_f1_mode->pack(-side, "left", -anchor, "e");

   # button to display the teletext page as image
   $canvas = $tk->Canvas(-borderwidth, 0, -relief, 'flat', -background, '#000000');
   $canvas->bindtags([$canvas, 'all']);
   $canvas->Tk::bind('<Key-q>', sub {exit;});
   $canvas->Tk::bind('<Button-1>', [\&pg_link, Ev('x'), Ev('y')]);
   $canvas->pack(-fill, 'both');
   $canvas->focus();

   $redraw = 0;
}

# create & display GUI
gui_init();

# start capturing teletext
cap_init();

# everything from here on is event driven
MainLoop;

