#!/usr/bin/perl -w
#
#  libzvbi test
#
#  Copyright (C) 2000-2002, 2004 Michael H. Schimek
#  Copyright (C) 2003 James Mastros
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

# Perl $Id: osc.pl,v 1.2 2007/12/02 18:31:10 tom Exp tom $
# libzvbi #Id: osc.c,v 1.29 2006/10/08 06:19:48 mschimek Exp #

use blib;
use strict;
use Getopt::Long;
use Tk;
use IO::Handle;
use Video::ZVBI qw(/^VBI_/);

my $option_dev_name = "/dev/vbi0";
my $option_ignore_error = 0;
my $option_ntsc = 0;
my $option_pal = 0;
my $option_sim = 0;
my $option_v4l = 0;
my $option_v4l2_read = 0;
my $option_v4l2_mmap = 1;
my $option_proxy = 0;
my $option_verbose = 0;

my $cap;
my $par;
my $rawdec;
my $pxc;
my $src_w;
my $src_h;
my $dst_h = 64;
my $raw1;

my $tk;
my $canvas;
my $pgm;
my $canvas_pgm;
my $canvas_lid;
my $dec_text;

my $draw_row = 0;
my $draw_count = -1;
my $cur_x;
my $cur_y;

# from capture.c
sub PIL {
        my ($day, $mon, $hour, $min) = @_;
        ((($day) << 15) + (($mon) << 11) + (($hour) << 6) + (($min) << 0));
}

sub decode_ttx {
        my ($buf) = @_;

        my $packet_address = Video::ZVBI::unham16p ($buf);
        return "" if ($packet_address < 0);  # hamming error

        my $magazine = $packet_address & 7;
        my $packet = $packet_address >> 3;

        my $text = sprintf "pg %x%02d >", $magazine, $packet;

        Video::ZVBI::unpar_str ($buf);
        $buf =~ s#[\x00-\x1F\x7F]#.#g;

        return $text . substr($buf, 0, 42) . "<";
}

sub dump_pil {
        my($pil) = @_;

        my $day = $pil >> 15;
        my $mon = ($pil >> 11) & 0xF;
        my $hour = ($pil >> 6) & 0x1F;
        my $min = $pil & 0x3F;

        my $text;
        if ($pil == PIL(0, 15, 31, 63)) {
                $text = " PDC: Timer-control (no PDC)";
        } elsif ($pil == PIL(0, 15, 30, 63)) {
                $text = " PDC: Recording inhibit/terminate";
        } elsif ($pil == PIL(0, 15, 29, 63)) {
                $text = " PDC: Interruption";
        } elsif ($pil == PIL(0, 15, 28, 63)) {
                $text = " PDC: Continue";
        } elsif ($pil == PIL(31, 15, 31, 63)) {
                $text = " PDC: No time";
        } else {
                $text = sprintf " PDC: %05x, 200X-%02d-%02d %02d:%02d",
                                $pil, $mon, $day, $hour, $min;
        }
        return $text;
}

my $pr_label = "";
my $label = " " x 16;
my $label_off = 0;

sub decode_vps {
        my ($buf) = @_;
        my @ord = unpack "C15", $buf;

        my $text = "VPS: ";

        my $c = Video::ZVBI::rev8 ($ord[1]);
        if ($c & 0x80) {
                $pr_label = substr($label, 0, $label_off);
                $label_off = 0;
        }

        my $cp = $c & 0x7F;
        $cp =~ s#[\x00-\x1F\x7F]#.#g;
        substr($label, $label_off, 1) = pack "C", $cp;
        $label_off = ($label_off + 1) % 16;

        $text .= sprintf " 3-10: %02x %02x %02x %02x %02x %02x %02x %02x (\"%s\") ",
                         $ord[0], $ord[1], $ord[2], $ord[3], $ord[4], $ord[5], $ord[6], $ord[7],
                         $pr_label;

        my $pcs = $ord[2] >> 6;
        my $cni = + (($ord[10] & 3) << 10)
                  + (($ord[11] & 0xC0) << 2)
                  + (($ord[8] & 0xC0) << 0)
                  + ($ord[11] & 0x3F);
        my $pil = (($ord[8] & 0x3F) << 14) + ($ord[9] << 6) + ($ord[10] >> 2);
        my $pty = $ord[12];
        $text .= sprintf " CNI: %04x PCS: %d PTY: %d ", $cni, $pcs, $pty;

        $text .= dump_pil($pil);
   
        return $text;
}

# End from capture.c

sub draw {
        if (defined $_[0]) {
                # new frame available - handling freeze & single-stepping counter
                return if ($draw_count == 0);
                $draw_count-- if ($draw_count > 0);

                # store a copy of the raw data (to allow navigating during freeze)
                $raw1 = $_[0];
        }

        # display raw data as gray-scale image
        draw_pgm();

        if (($draw_row =~ /^\d+$/) && ($draw_row >= 0) && ($draw_row < $src_h)) {
                my $field = ($draw_row >= $par->{count_a});
                my $phys_line;
                my $nchars;
                if ((($field == 0) ? $par->{start_a} : $par->{start_b}) < 0) {
                        $nchars = sprintf "Row %d Line ? - ", $draw_row;
                        $phys_line = -1;
                } elsif ($field == 0) {
                        $phys_line = $draw_row + $par->{start_a};
                        $nchars = sprintf "Row %d Line %d - ", $draw_row, $phys_line;
                } else {
                        $phys_line = $draw_row - $par->{count_a} + $par->{start_b};
                        $nchars = sprintf "Row %d Line %d - ", $draw_row, $phys_line;
                }

                my $sliced;
                my $slines = $rawdec->decode($raw1, $sliced);
                # search the selected physical line in the slicer output
                my $found = 0;
                for (my $six = 0; $six < $slines; $six++) {
                        my ($sld, $slid, $slin) = Video::ZVBI::get_sliced_line($sliced, $six);
                        if ($slin == $phys_line) {
                                draw_dec($nchars, $sld, $slid, $slin);
                                $found = 1;
                                last;
                        }
                }
                # display decoder output
                draw_dec($nchars) unless $found;

                # plot that line
                draw_plot($draw_row);
        }
}

sub draw_pgm {
        my $pgm_str = "P5\n$src_w $src_h\n255\n" . $raw1;

        open X, ">raw.pgm";
        syswrite X, $pgm_str;
        close X;

        $pgm->read("raw.pgm");
        #$button->configure(-image, $pgm);
}

sub draw_dec {
        my ($nchars, $sld, $slid, $slin) = @_;
        my $buf;
        my $i;

        if (defined $sld) {
                if ($slid & VBI_SLICED_TELETEXT_B) {
                        $nchars .= decode_ttx($sld);

                } elsif ($slid & VBI_SLICED_VPS) {
                        $nchars .= decode_vps($sld);

                } elsif ($slid & (VBI_SLICED_CAPTION_625 | VBI_SLICED_CAPTION_525)) {
                        $nchars .= "Closed Caption";

                } else {
                        $nchars .= sprintf "Sliced service 0x%X", $slid;
                }
        } else {
                $nchars .= "Unknown signal";
        }
        $dec_text = $nchars;
}

sub draw_plot {
        my $start = $src_w * $draw_row;
        my $h0 = $src_h + $dst_h - unpack("x$start C1", $raw1) / 256;

        my @Poly = ();
        my $h;
        my $r = $src_h + 10 + $dst_h;
        my $i = 0;
        foreach $h (unpack("x$start C$src_w", $raw1)) {
                push @Poly, $i++, ($r - $h *$dst_h/256);
                $h0 = $h;
        }
        $canvas->coords($canvas_lid, @Poly);
}

sub resize_window {
        my ($self, $w, $h) = @_;

        $dst_h = $h - ($src_h + 10);
        $dst_h = $src_h if $dst_h < $src_h;

        # remove old grid
        foreach ($canvas->find('overlapping', 0, $src_h + 1,
                                              $src_w, $src_h + 1 + $dst_h*2)) {
                $canvas->delete($_);
        }
        # paint grid in the new size
        my $x=0;
        while ($x < $src_w) {
           $canvas->createLine($x, $src_h + 10, $x, $src_h + 12+$dst_h, -fill, '#AAAAAA');
           $x += 10;
        }
        # create plot element
        $canvas_lid = $canvas->createLine(0, $src_h+$dst_h, 0, $src_h+$dst_h, -fill, '#ffffff');

        draw() if $draw_count == 0;
}

sub init_window {
        $tk = MainWindow->new();
        $tk->title('Raw capture & plot');

        $canvas = $tk->Canvas(-borderwidth, 1, -relief, 'sunken', -background, '#000000',
                              -height, $src_h + 10 + $dst_h, -width, 640,
                              -scrollregion, [0, 0, $src_w, $src_h]);
        $canvas->pack(-side, 'top', -fill, 'x', -expand, 1);
        my $csb = $tk->Scrollbar(-orient, 'horizontal', -takefocus, 0, -width, 10, -borderwidth, 1,
                                 -command, [xview => $canvas]);
        $canvas->configure(-xscrollcommand, [set => $csb]);
        $csb->pack(-side, 'top', -fill, 'x');
        $canvas->pack(-side, 'top', -fill, 'both', -expand, 1);

        $canvas->Tk::bind('<Configure>', [\&resize_window, Ev('w'), Ev('h')]);
        $canvas->Tk::bind('<q>', sub {exit});
        $canvas->Tk::bind('<Down>', sub {if ($draw_row+1<$src_h){$draw_row += 1;}; draw(); Tk->break});
        $canvas->Tk::bind('<Up>', sub {if ($draw_row>0){$draw_row -= 1;}; draw(); Tk->break});
        $canvas->Tk::bind('<space>', sub {$draw_count = 1;});  # single-stepping
        $canvas->Tk::bind('<Return>', sub {$draw_count = -1;});  # live capture
        $canvas->bindtags([$canvas, 'all']);  # remove widget default bindings
        $canvas->focus();

        my $label = $tk->Entry(-textvariable, \$dec_text, -font, ['courier', -12],
                               -takefocus, 0, -width, 50);
        $label->pack(-side, 'top', -fill, 'x', -anchor, 'w');

        my $f = $tk->Frame();
        my $f_c = $f->Checkbutton(-text, 'Live capture',
                                  -offvalue, 1, -onvalue, -1, -variable, \$draw_count);
        my $f_l = $f->Label(-text, "Plot row:");
        my $f_s = $f->Spinbox(-from, 0, -to, $src_h - 1, -width, 5,
                              -textvariable, \$draw_row, -command, sub {draw()});
        $f_c->pack(-side, 'left', -padx, 10, -pady, 5);
        $f_l->pack(-side, 'left', -padx, 5);
        $f_s->pack(-side, 'left', -padx, 5, -pady, 5);
        $f->pack(-side, 'top', -anchor, 'w');

        $pgm = $tk->Photo();
        $canvas_pgm = $canvas->createImage(0, 0, -image, $pgm, -anchor, 'nw');
}

sub cap_frame {
        my $timestamp;
        my $raw2;

        # note: must use "read" and not "pull" since a copy of the data is kept in "raw1"
        my $r = $cap->read_raw($raw2, $timestamp, 100);

        if ($r == -1) {
                warn "VBI read error: $!\n";
                next if $option_ignore_error;
                exit(-1);
        } elsif ($r == 0) {
                warn "VBI read timeout\n";
                next if $option_ignore_error || defined $pxc;
                exit(-1);
        } elsif ($r == 1) {
                # ok
        } else {
                die "Unexpected capture result code $r\n";
        }

        draw($raw2);

        #printf "raw: %f; sliced: %d\n", $timestamp, $slines;
}

#static const char short_options[] = "123cd:enpsv";

my %CmdOpts = (
        "device=s" =>   \$option_dev_name, # 'd'
        "ignore-error" => \$option_ignore_error, # 'e'
        "ntsc" =>       \$option_ntsc, # 'n'
        "pal" =>        \$option_pal, # 'p'
        "v4l" =>        \$option_v4l, # '1'
        "v4l2-read" =>  \$option_v4l2_read, # '2'
        "v4l2-mmap" =>  \$option_v4l2_mmap, # '3'
        "proxy" =>      \$option_proxy, # '4'
        "verbose+" =>   \$option_verbose, # 'v'
);

sub main_func {
        my $errstr;
        my $scanning = 625;
        my $verbose = 0;
        my $interface = 0;
        my $c;
        my $index;

        GetOptions(%CmdOpts) || die "Invalid command line options\n";

        if ($option_ntsc) {
                $scanning = 525;
        } elsif ($option_pal) {
                $scanning = 625;
        }

        my $services = VBI_SLICED_VBI_525 | VBI_SLICED_VBI_625
                     | VBI_SLICED_TELETEXT_B | VBI_SLICED_CAPTION_525
                     | VBI_SLICED_CAPTION_625 | VBI_SLICED_VPS
                     | VBI_SLICED_WSS_625 | VBI_SLICED_WSS_CPR1204;

        my $strict = 0;

        while(1) {
                if ($option_v4l2_read || $option_v4l2_mmap) {
                        $cap = Video::ZVBI::capture::v4l2_new ($option_dev_name,
                                                    5, #/* buffers */ 5,
                                                    $services,
                                                    $strict,
                                                    $errstr,
                                                    $option_verbose);
                        last if defined $cap;

                        warn "Cannot capture vbi data with v4l2 interface:\n$errstr\n";
                }

                if ($option_v4l < 2) {
                        $cap = Video::ZVBI::capture::v4l_new ($option_dev_name,
                                                   $scanning,
                                                   $services,
                                                   $strict,
                                                   $errstr,
                                                   $option_verbose);
                        last if defined $cap;

                        warn "Cannot capture vbi data with v4l interface:\n$errstr\n";
                }

                if ($option_proxy) {
                        $pxc = Video::ZVBI::proxy::create($option_dev_name, "capture", 0,
                                                          $errstr, $option_verbose);
                        if (defined $pxc) {
                                # strip non-raw services, else request for raw is masked out 
                                my $sv = $services & (VBI_SLICED_VBI_525 |
                                                      VBI_SLICED_VBI_625);
                                $cap = Video::ZVBI::capture::proxy_new($pxc, 5, 0, $sv,
                                                            $strict, $errstr );
                                last if defined $cap;

                                warn "Cannot capture vbi data ".
                                         "through proxy:\n$errstr\n";
                        }
                        warn "Cannot initialize proxy\n$errstr\n";
                }

                # BSD interface */
                if (1) {
                        $cap = Video::ZVBI::capture::bktr_new ($option_dev_name,
                                                    $scanning,
                                                    $services,
                                                    $strict,
                                                    $errstr,
                                                    $option_verbose);
                        last if defined $cap;

                        warn "Cannot capture vbi data ".
                                 "with bktr interface:\n$errstr\n";
                }

                exit -1;
        }

        $rawdec = Video::ZVBI::rawdec::new($cap);
        die unless defined $rawdec;
        $rawdec->add_services($services, $strict) or die;

        $par = $cap->parameters();
        die unless defined $par;

        if ($option_verbose > 1) {
                #vbi_capture_set_log_fp ($cap, stderr);
                set_log_on_stderr(0);
        }

        die unless $par->{sampling_format} == VBI_PIXFMT_YUV420;

        $src_w = $par->{bytes_per_line};
        $src_h = $par->{count_a} + $par->{count_b};

        init_window();

        # install a Tk event handler for capturing in the background
        my $io = new IO::Handle;
        $io->fdopen($cap->fd(), 'r');
        $tk->fileevent($io, 'readable', \&cap_frame);

        # everything from here on is event driven
        MainLoop();
}

main_func();
