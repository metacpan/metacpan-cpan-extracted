#!/usr/bin/perl -w
#
#  libzvbi test
#
#  Copyright (C) 2000, 2001 Michael H. Schimek
#  Perl Port: Copyright (C) 2007 Tom Zoerner
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

# Perl $Id: caption.pl,v 1.1 2007/11/18 18:48:35 tom Exp tom $
# ZVBI #Id: caption.c,v 1.14 2006/05/22 08:57:05 mschimek Exp #

#
#  Rudimentary render code for Closed Caption (CC) test.
#

use blib;
use strict;
use IO::Handle;
use Switch;
use Tk;
use Video::ZVBI qw(/^VBI_/);

my $vbi;
my $pgno = -1;
my $dx;

my $infile;
my $read_elapsed = 0;

use constant DISP_WIDTH      => 640;
use constant DISP_HEIGHT     => 480;
use constant CELL_WIDTH      => 16;
use constant CELL_HEIGHT     => 26;
use constant DISP_X_OFF      => 40;
use constant DISP_Y_OFF      => 45;

my $tk;
my $canvas;

# hash array to hold IDs of rolling text rows in the canvas
my %shift;
use constant shift_step => 2;

# canvas background color - visible where video would look through
use constant COLORKEY => "#80FF80";

#
#  Remove one row's text content (i.e. all pixmaps in the row's area)
#
sub draw_blank {
        my ($row, $col, $n_cols) = @_;
        my $cid;

        foreach $cid ( $canvas->find( "overlapping",
                                      $col * CELL_WIDTH + 1 + DISP_X_OFF,
                                      $row * CELL_HEIGHT + 1 + DISP_Y_OFF,
                                      ($col + $n_cols) * CELL_WIDTH - 2 + DISP_X_OFF,
                                      ($row + 1) * CELL_HEIGHT - 2 + DISP_X_OFF ) ) {

                my $img = $canvas->itemcget($cid, -image);

                # remove the pixmap from the canvas
                $canvas->delete($cid);

                # destroy the image (important to free the image's memory)
                $img->delete();
        }
}

sub is_transp {
        (($_[0] >> 16) & 0x0F) == VBI_TRANSPARENT_SPACE;
}

#
#  Draw one row of text
#
sub draw_row {
        my ($pg, $row) = @_;
        my $col;

        my ($rows, $columns) = $pg->get_page_size();
        my $prop = $pg->get_page_text_properties();

        # first remove all old text in the row
        draw_blank($row, 0, $columns);

        for ($col = 0; $col < $columns; $col++) {
                # skip transparent characters
                if (is_transp($prop->[$row * $columns + $col])) {
                        next;
                }
                # count number of subsequent non-transparent characters
                # (required as optimisation - drawing each char separately is very slow)
                my $i = $col + 1;
                while (($i < $columns) &&
                                !is_transp($prop->[$row * $columns + $i])) {
                        $i++;
                }
                # create RGBA image of the character sequence
                my $vbi_canvas;
                my $fmt;
                if (Video::ZVBI::check_lib_version(0,2,26)) {
                        $fmt = VBI_PIXFMT_PAL8;
                } else {
                        $fmt = VBI_PIXFMT_RGBA32_LE;
                }
                $pg->draw_cc_page_region ($fmt,
                                          $vbi_canvas, -1, $col, $row, $i - $col, 1);

                # convert into a pixmap via XPM
                my $img = $tk->Pixmap(-data, $pg->canvas_to_xpm($vbi_canvas, $fmt));

                # finally, display the pixmap in the canvas
                my $cid = $canvas->createImage($col * CELL_WIDTH + DISP_X_OFF,
                                               $row * CELL_HEIGHT + DISP_Y_OFF,
                                               -anchor, "nw", -image, $img);
                $col = $i;
        }
}

#
#  Timer event for rolling text rows
#
sub bump {
        my ($snap) = @_;
        my $cid;
        my $renew = 0;

        foreach $cid (keys %shift) {
                my $d = $shift{$cid};
                my $step;
                if ($snap) {
                        $step = $d;
                } else {
                        $step = (($d < shift_step) ? $d : shift_step);
                }
                $canvas->move($cid, 0, 0 - $step);

                $shift{$cid} -= $step;
                if ($shift{$cid} <= 0) {
                        delete $shift{$cid};
                } else {
                        $renew = 1;
                }
        }

        if ($renew) {
                $tk->after(20 * shift_step, sub {bump(0)});
        }
}

#
#  Scroll a range of rows upwards
#
sub roll_up {
        my ($pg, $first_row, $last_row) = @_;
        my $cid;

        if (1) { # ---- soft scrolling ----

                # snap possibly still moving rows into their target positions
                bump(1);

                foreach $cid ( $canvas->find("overlapping",
                                             0,
                                             $first_row * CELL_HEIGHT + 1 + DISP_Y_OFF,
                                             DISP_WIDTH,
                                             ($last_row + 1) * CELL_HEIGHT - 1 + DISP_Y_OFF) ) {

                        $shift{$cid} = CELL_HEIGHT;

                        # start time to trigger smooth scrolling
                        $tk->after(20 + 20 * shift_step, sub {bump(0)});
                }

        } else { # ---- jumpy scrolling ----

                foreach ( $canvas->find("overlapping",
                                        0,
                                        $first_row * CELL_HEIGHT + DISP_Y_OFF,
                                        DISP_WIDTH,
                                        ($last_row + 1) * CELL_HEIGHT - 1 + DISP_Y_OFF) ) {

                        $canvas->move($_, 0, 0 - CELL_HEIGHT);
                }
        }
}

#
#  Update a range of text rows
#
sub render {
        my ($pg, $y0, $y1) = @_;

        # snap possibly still moving rows into their target positions
        bump(1);

        foreach my $row ($y0 .. $y1) {
                draw_row ($pg, $row);
        }
}


#
#  Clear all text on-screen
#
sub clear {
        foreach my $cid ( $canvas->find( "all" ) ) {
                my $img = $canvas->itemcget($cid, -image);
                $canvas->delete($cid);
                $img->delete();
        }
}

#
#  Callback invoked by the VBI decoder when a new CC line is available
#
sub cc_handler {
        my ($type, $ev) = @_;

        if ($pgno != -1 && $ev->{pgno} != $pgno) {
                return;
        }

        # Fetching & rendering in the handler
        # is a bad idea, but this is only a test

        my $pg = $vbi->fetch_cc_page ($ev->{pgno});
        die "failed to fetch page $pgno\n" unless defined $pg;

        my ($rows, $columns) = $pg->get_page_size();
        my ($y0, $y1, $roll) = $pg->get_page_dirty_range();

        if (abs ($roll) > $rows) {
                clear ();
        } elsif ($roll == -1) {
                #draw_blank($y0, 0, $columns);
                roll_up ($pg, $y0+1, $y1);
        } else {
                render ($pg, $y0, $y1);
        }
}

#
#  Callback bound to CC channel changes
#
sub reset {
        my $pg = $vbi->fetch_cc_page ($pgno);
        if (defined $pgno) {

                my ($rows, $columns) = $pg->get_page_size();

                render ($pg, 0, $rows - 1);
        } else {
                clear ();
        }
}

#
#  Create the GUI
#
sub init_window {
        my $f;
        my $b;

        $tk = MainWindow->new();

        # at the top: button array to switch CC channels
        $f = $tk->Frame();
        $b = $f->Label(-text, "Page:");
        $b->pack(-side, "left");
        for (my $i=1; $i <= 8; $i++) {
                $b = $f->Radiobutton(-text, $i, -value, $i, -variable, \$pgno, -command, \&reset);
                $b->pack(-side, "left");
        }
        $f->pack(-side, "top");

        # canvas to display CC text (as pixmaps)
        $canvas = $tk->Canvas(-borderwidth, 1, -relief, "sunken",
                              -background, COLORKEY,
                              -height, DISP_HEIGHT, -width, DISP_WIDTH);
        $canvas->pack(-side, "top");
        $canvas->focus();
}

#
#  Feed caption from live stream or file with sample data
#

sub pes_mainloop {
        my $buffer;
        my $bytes_left;
        my $sliced;
        my $n_lines;
        my $pts;

        while (read (STDIN, $buffer, 2048)) {
                my $bytes_left = length($buffer);

                while ($bytes_left > 0) {

                        $n_lines = $dx->cor ($sliced, 64, $pts, $buffer, $bytes_left);
                        if ($n_lines > 0) {
                                $vbi->decode ($sliced, $n_lines, $pts / 90000.0);
                        }
                }

                $tk->after(20, \&pes_mainloop);
                return;
        }
        print STDERR "\rEnd of stream\n";
}

sub old_mainloop {
        my $sliced;
        my $timestamp;
        my $n_lines;

        # one one frame's worth of sliced data from the input stream or file
        ($n_lines, $timestamp, $sliced) = read_sliced ();
        if (defined $n_lines) {
                my $buf = "";
                my $set;
                # pack the read data into the normal slicer output format
                # (i.e. the format delivered by the librarie's internal slicer)
                foreach $set (@$sliced) {
                        $buf .= pack "LLa56", @$set;
                }
                # pass the full frame's data to the decoder
                $vbi->decode ($buf, $n_lines, $timestamp);

                # FIXME: reading from STDIN, so $tk->fileevent(readable) could be used instead of polling
                $tk->after(20, \&old_mainloop);
        } else {
                print STDERR "\rEnd of stream\n";
        }
}

# ----------------------------------------------------------------------------
#
#  Generate artificial caption data
#
my @sim_buf;
my $cmd_time;

sub cmd {
        my ($n) = @_;
        my $sliced;

        $sliced = pack "LLCCx54", VBI_SLICED_CAPTION_525,
                                  21,
                                  Video::ZVBI::par8 ($n >> 8),
                                  Video::ZVBI::par8 ($n & 0x7F);

        push @sim_buf, ["sliced", $sliced, $cmd_time];
        #$vbi->decode ($sliced, 1, $cmd_time);

        $cmd_time += 1 / 29.97;
}

sub printc {
        cmd ($_[0] * 256 + 0x80);

        push @sim_buf, ["delay", 1];
}

sub prints {
        my @s = unpack "C*", $_[0];
        my $i;

        for ($i=0; $s[$i] && $s[$i+1]; $i += 2) {
                cmd ($s[$i] * 256 + $s[$i+1]);
        }
        if ($s[$i]) {
                cmd ($s[$i] * 256 + 0x80);
        }
        push @sim_buf, ["delay", 1];
}

use constant white => 0;
use constant green => 1;
use constant red => 4;
use constant yellow => 5;
use constant blue => 2;
use constant cyan => 3;
use constant magenta => 6;
use constant black => 7;

use constant mapping_row => (2, 3, 4, 5,  10, 11, 12, 13, 14, 15,  0, 6, 7, 8, 9, -1);

use constant italic => 7;
use constant underline => 1;
use constant opaque => 0;
use constant semi_transp => 1;

my $ch;

sub BACKG {           cmd (0x2000);
                      cmd (0x1020 + (($ch & 1) << 11) + ($_[0] << 1) + $_[1]); }
sub PREAMBLE {
                      cmd (0x1040 + (($ch & 1) << 11) + (((mapping_row)[$_[0]] & 14) << 7)
                           + (((mapping_row)[$_[0]] & 1) << 5) + ($_[1] << 1) + $_[2]); }
sub INDENT {
                      cmd (0x1050 + (($ch & 1) << 11) + (((mapping_row)[$_[0]] & 14) << 7)
                           + (((mapping_row)[$_[0]] & 1) << 5) + (($_[1] / 4) << 1) + $_[2]); }
sub MIDROW          { cmd (0x1120 + (($ch & 1) << 11) + ($_[0] << 1) + $_[1]); }
sub SPECIAL_CHAR    { cmd (0x1130 + (($ch & 1) << 11) + $_[0]) }
sub CCODE           { ($_[0] + (($_[1] & 1) << 11) + (($_[1] & 2) << 7)) }
sub RESUME_CAPTION  { cmd (CCODE (0x1420, $ch)) }
sub BACKSPACE       { cmd (CCODE (0x1421, $ch)) }
sub DELETE_EOR      { cmd (CCODE (0x1424, $ch)) }
sub ROLL_UP         { cmd (CCODE (0x1425, $ch) + $_[0] - 2) }
sub FLASH_ON        { cmd (CCODE (0x1428, $ch)) }
sub RESUME_DIRECT   { cmd (CCODE (0x1429, $ch)) }
sub TEXT_RESTART    { cmd (CCODE (0x142A, $ch)) }
sub RESUME_TEXT     { cmd (CCODE (0x142B, $ch)) }
sub END_OF_CAPTION  { cmd (CCODE (0x142F, $ch)) }
sub ERASE_DISPLAY   { cmd (CCODE (0x142C, $ch)) }
sub CR              { cmd (CCODE (0x142D, $ch)) }
sub ERASE_HIDDEN    { cmd (CCODE (0x142E, $ch)) }
sub TAB             { cmd (CCODE (0x1720, $ch) + $_[0]) }
sub TRANSP          { (cmd (0x2000), cmd (0x172D + (($ch & 1) << 11))) }
sub BLACK           { (cmd (0x2000), cmd (0x172E + (($ch & 1) << 11) + $_[0])) }

sub PAUSE {
        my ($n_frames) = @_;

        push @sim_buf, ["delay", $n_frames];
}

sub hello_world {
        my $i;

        @sim_buf = ();
        $cmd_time = 0.0;
        $pgno = -1;

        prints (" HELLO WORLD! ");
        PAUSE (30);

        $ch = 4;
        TEXT_RESTART;
        prints ("Character set - Text 1");
        CR; CR;
        for ($i = 32; $i <= 127; $i++) {
                printc ($i);
                if (($i & 15) == 15) {
                        CR;
                }
        }
        MIDROW (italic, 0);
        for ($i = 32; $i <= 127; $i++) {
                printc ($i);
                if (($i & 15) == 15) {
                        CR;
                }
        }
        MIDROW (white, underline);
        for ($i = 32; $i <= 127; $i++) {
                printc ($i);
                if (($i & 15) == 15) {
                        CR;
                }
        }
        MIDROW (white, 0);
        prints ("Special: ");
        for ($i = 0; $i <= 15; $i++) {
                SPECIAL_CHAR ($i);
        }
        CR;
        prints ("DONE - Text 1 ");
        PAUSE (50);

        $ch = 5;
        TEXT_RESTART;
        prints ("Styles - Text 2");
        CR; CR;
        MIDROW (white, 0); prints ("WHITE"); CR;
        MIDROW (red, 0); prints ("RED"); CR;
        MIDROW (green, 0); prints ("GREEN"); CR;
        MIDROW (blue, 0); prints ("BLUE"); CR;
        MIDROW (yellow, 0); prints ("YELLOW"); CR;
        MIDROW (cyan, 0); prints ("CYAN"); CR;
        MIDROW (magenta, 0); prints ("MAGENTA"); BLACK (0); CR;
        BACKG (white, opaque); prints ("WHITE"); BACKG (black, opaque); CR;
        BACKG (red, opaque); prints ("RED"); BACKG (black, opaque); CR;
        BACKG (green, opaque); prints ("GREEN"); BACKG (black, opaque); CR;
        BACKG (blue, opaque); prints ("BLUE"); BACKG (black, opaque); CR;
        BACKG (yellow, opaque); prints ("YELLOW"); BACKG (black, opaque); CR;
        BACKG (cyan, opaque); prints ("CYAN"); BACKG (black, opaque); CR;
        BACKG (magenta, opaque); prints ("MAGENTA"); BACKG (black, opaque); CR;
        PAUSE (200);
        TRANSP;
        prints (" TRANSPARENT BACKGROUND ");
        BACKG (black, opaque); CR;
        MIDROW (white, 0); FLASH_ON;
        prints (" Flashing Text  (if implemented) "); CR;
        MIDROW (white, 0); prints ("DONE - Text 2 ");
        PAUSE (50);

        $ch = 0;
        ROLL_UP (2);
        ERASE_DISPLAY;
        prints (" ROLL-UP TEST "); CR; PAUSE (20);
        prints ("The ZVBI library provides"); CR; PAUSE (20);
        prints ("routines to access raw VBI"); CR; PAUSE (20);
        prints ("sampling devices (currently"); CR; PAUSE (20);
        prints ("the Linux V4L and and V4L2"); CR; PAUSE (20);
        prints ("API and the FreeBSD, OpenBSD,"); CR; PAUSE (20);
        prints ("NetBSD and BSDi bktr driver"); CR; PAUSE (20);
        prints ("API are supported), a versatile"); CR; PAUSE (20);
        prints ("raw VBI bit slicer, decoders"); CR; PAUSE (20);
        prints ("for various data services and"); CR; PAUSE (20);
        prints ("basic search, render and export"); CR; PAUSE (20);
        prints ("functions for text pages. The"); CR; PAUSE (20);
        prints ("library was written for the"); CR; PAUSE (20);
        prints ("Zapping TV viewer and Zapzilla"); CR; PAUSE (20);
        prints ("Teletext browser."); CR; PAUSE (20);
        CR; PAUSE (30);
        prints (" DONE - Caption 1 ");
        PAUSE (30);

        $ch = 1;
        RESUME_DIRECT;
        ERASE_DISPLAY;
        MIDROW (yellow, 0);
        INDENT (2, 10, 0); prints (" FOO "); CR;
        INDENT (3, 10, 0); prints (" MIKE WAS HERE "); CR; PAUSE (20);
        MIDROW (red, 0);
        INDENT (6, 13, 0); prints (" AND NOW... "); CR;
        INDENT (8, 13, 0); prints (" TOM'S THERE TOO "); CR; PAUSE (20);
        PREAMBLE (12, cyan, 0);
        prints ("01234567890123456789012345678901234567890123456789"); CR;
        MIDROW (white, 0);
        prints (" DONE - Caption 2 "); CR;
        PAUSE (30);
}

#
#  Play back the buffered (simulated) CC data
#
sub play_world {
        while ($#sim_buf >= 0) {
                $a = shift @sim_buf;
                if ($a->[0] eq "delay") {
                        # delay event -> stop play-back and start timer
                        $tk->after(25 * $a->[1], \&play_world);
                        last;
                } else {
                        # pass VBI Data to the decoder context
                        # (will trigger display via the CC callback function)
                        $vbi->decode ($a->[1], 1, $a->[2]);
                }
        }
}

# ------- slicer.c -----------------------------------------------------------
#
# Read one frame's worth of sliced data (written by decode.pl)
# from a file or pipe (not used in demo mode)
#
sub read_sliced {
        my $buf;

	#die "stream error: $!\n" if ($infile->ferror ());

	if ($infile->eof () || !($buf = $infile->gets ())) {
		return undef;
        }

	# Time in seconds since last frame.
        die "invalid timestamp in input\n" unless $buf =~ /^(-?\d+|(-?\d*\.\d+))$/;
	my $dt = $buf + 0.0;
	if ($dt < 0.0) {
		$dt = -$dt;
	}

	my $timestamp = $read_elapsed;
	$read_elapsed += $dt;

	my $n_lines = unpack "C", $infile->getc ();
	die "invalid line count in input: $n_lines\n" if ($n_lines < 0);

        my @sliced = ();

	for (my $n = 0; $n < $n_lines; $n++) {

		my $index = unpack "C", $infile->getc ();
		die "invalid index: $index\n" if ($index < 0);

		my $line = (unpack("C", $infile->getc())
			   + 256 * unpack("C", $infile->getc())) & 0xFFF;

		die "IO: $!\n" if ($infile->eof () || $infile->error ());

                my $id;
                my $data;

		switch ($index) {
		case 0 {
			$id = VBI_SLICED_TELETEXT_B;
			$infile->read ($data, 42);
		}
		case 1 {
			$id = VBI_SLICED_CAPTION_625; 
			$infile->read ($data, 2);
		}
		case 2 {
			$id = VBI_SLICED_VPS;
			$infile->read ($data, 13);
		}
		case 3 {
			$id = VBI_SLICED_WSS_625; 
			$infile->read ($data, 2);
		}
		case 4 {
			$id = VBI_SLICED_WSS_CPR1204; 
			$infile->read ($data, 3);
		}
		case 7 {
			$id = VBI_SLICED_CAPTION_525; 
			$infile->read($data, 2);
		}
		else {
			die "\nOops! Unknown data type $index ".
				 "in sliced VBI file\n";
		}
                }

		die "IO: $!\n" if ($infile->error ());

		push @sliced, [$id, $line, $data];
	}

	return ($n_lines, $timestamp, \@sliced);
}

# ----------------------------------------------------------------------------

sub main_func {
        my $success;

        # create the GUI
        init_window ();

        # create a decoder context and enable Closed Captioning decoding
        $vbi = Video::ZVBI::vt::decoder_new ();
        die "Failed to create VT decoder\n" unless defined $vbi;

        $success = $vbi->event_handler_add (VBI_EVENT_CAPTION, \&cc_handler);
        die "Failed to add event handler\n" unless $success;

        if (-t STDIN) {
                # no file or stream on STDIN -> generate demo data
                hello_world ();
                # start play back of the demo data (timer-based, to give control to the main loop below)
                play_world ();
        } else {
                $pgno = 1;

                $infile = new IO::Handle;
                $infile->fdopen(fileno(STDIN), "r");

                my $c = ord($infile->getc() || 1);
                $infile->ungetc($c);

                if (0 == $c) {
                        $dx = Video::ZVBI::dvb_demux::pes_new ();
                        die "Failed to create DVB demuxer\n" unless defined $dx;

                        $tk->after(20, \&pes_mainloop);
                } else {
                        # install timer to poll for incoming data
                        $tk->after(20, \&old_mainloop);
                }
        }

        # everything from here on is event driven
        MainLoop;
}

main_func();

