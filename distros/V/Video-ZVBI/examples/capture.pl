#!/usr/bin/perl -w
#
#  libzvbi test
#
#  Copyright (C) 2000-2006 Michael H. Schimek
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

# Perl $Id: capture.pl,v 1.1 2007/11/18 18:48:35 tom Exp tom $
# ZVBI #Id: capture.c,v 1.26 2006/10/08 06:19:48 mschimek Exp #

use blib;
use strict;
use Getopt::Long;
use POSIX;
use IO::Handle;
use Video::ZVBI qw(/^VBI_/);

my $cap;
my $par;
my $mx;
my $quit;
my $outfile;

my $dev_name = "/dev/vbi";
my $dump = 0;
my $dump_ttx = 0;
my $dump_xds = 0;
my $dump_cc = 0;
my $dump_wss = 0;
my $dump_vps = 0;
my $dump_sliced = 0;
my $bin_sliced = 0;
my $bin_pes = 0;
my $bin_ts = 0;
my $do_read = 1;
my $do_sim = 0;
my $ignore_error = 0;
my $desync = 0;
my $strict = 0;
my $pid = -1;
my $scanning_ntsc = 0;
my $scanning_pal = 0;
my $api_v4l = 0;
my $api_v4l2 = 0;
my $verbose = 0;

#extern void
#vbi_capture_set_log_fp         (vbi_capture *          capture,
#                                FILE *                 fp);
#extern vbi_bool vbi_capture_force_read_mode;

#
#  Dump
#

sub PIL {
        my ($day, $mon, $hour, $min) = @_;
        return (($day << 15) + ($mon << 11) + ($hour << 6) + ($min << 0));
}

sub dump_pil
{
        my ($pil) = @_;

        my $day = $pil >> 15;
        my $mon = ($pil >> 11) & 0xF;
        my $hour = ($pil >> 6) & 0x1F;
        my $min = $pil & 0x3F;

        if ($pil == PIL(0, 15, 31, 63)) {
                $outfile->print(" PDC: Timer-control (no PDC)\n");
        } elsif ($pil == PIL(0, 15, 30, 63)) {
                $outfile->print(" PDC: Recording inhibit/terminate\n");
        } elsif ($pil == PIL(0, 15, 29, 63)) {
                $outfile->print(" PDC: Interruption\n");
        } elsif ($pil == PIL(0, 15, 28, 63)) {
                $outfile->print(" PDC: Continue\n");
        } elsif ($pil == PIL(31, 15, 31, 63)) {
                $outfile->print(" PDC: No time\n");
        } else {
                $outfile->printf(" PDC: %05x, 200X-%02d-%02d %02d:%02d\n",
                        $pil, $mon, $day, $hour, $min);
        }
}

my $pr_label = "";
my $label = " " x 16;
my $label_off = 0;

sub decode_vps {
        my ($inbuf) = @_;
        my @buf = unpack "C13", $inbuf;

        return if !$dump_vps;

        $outfile->print("\nVPS:\n");

        my $c = Video::ZVBI::rev8 ($buf[1]);

        if ($c & 0x80) {
                $pr_label = substr($label, 0, $label_off);
                $label_off = 0;
        }

        ($c &= 0x7F) =~ s#[\x00-\x1F\x7F]#.#g;

        substr($label, $label_off, 1) = pack "C", $c;

        $label_off = ($label_off + 1) % 16;

        printf(" 3-10: %02x %02x %02x %02x %02x %02x %02x %02x (\"%s\")\n",
                $buf[0], $buf[1], $buf[2], $buf[3], $buf[4], $buf[5], $buf[6], $buf[7], $pr_label);

        my $pcs = $buf[2] >> 6;

        my $cni = + (($buf[10] & 3) << 10)
                  + (($buf[11] & 0xC0) << 2)
                  + (($buf[8] & 0xC0) << 0)
                  + ($buf[11] & 0x3F);

        my $pil = (($buf[8] & 0x3F) << 14) + ($buf[9] << 6) + ($buf[10] >> 2);

        my $pty = $buf[12];

        printf(" CNI: %04x PCS: %d PTY: %d ", $cni, $pcs, $pty);

        dump_pil($pil);
}

sub decode_wss_625 {
        my ($inbuf) = @_;
        my @buf = unpack "C2", $inbuf;

        my @formats = (
                "Full format 4:3, 576 lines",
                "Letterbox 14:9 centre, 504 lines",
                "Letterbox 14:9 top, 504 lines",
                "Letterbox 16:9 centre, 430 lines",
                "Letterbox 16:9 top, 430 lines",
                "Letterbox > 16:9 centre",
                "Full format 14:9 centre, 576 lines",
                "Anamorphic 16:9, 576 lines"
        );
        my @subtitles = (
                "none",
                "in active image area",
                "out of active image area",
                "<invalid>"
        );
        my $g1 = $buf[0] & 15;
        my $parity;

        if ($dump_wss) {
                $parity = $g1;
                $parity ^= $parity >> 2;
                $parity ^= $parity >> 1;
                $g1 &= 7;

                $outfile->print("WSS PAL: ");
                if (!($parity & 1)) {
                        $outfile->print("<parity error> ");
                }
                $outfile->printf("%s; %s mode; %s colour coding; %s helper; ".
                        "reserved b7=%d; %s Teletext subtitles; ".
                        "open subtitles: %s; %s surround sound; ".
                        "copyright %s; copying %s\n",
                        $formats[$g1],
                        ($buf[0] & 0x10) ? "film" : "camera",
                        ($buf[0] & 0x20) ? "MA/CP" : "standard",
                        ($buf[0] & 0x40) ? "modulated" : "no",
                        ($buf[0] & 0x80) != 0,
                        ($buf[1] & 0x01) ? "have" : "no",
                        $subtitles[($buf[1] >> 1) & 3],
                        ($buf[1] & 0x08) ? "have" : "no",
                        ($buf[1] & 0x10) ? "asserted" : "unknown",
                        ($buf[1] & 0x20) ? "restricted" : "not restricted");
        }
}

sub decode_wss_cpr1204 {
        my ($inbuf) = @_;
        my @buf = unpack "C13", $inbuf;
        my $poly = (1 << 6) + (1 << 1) + 1;
        my $g = ($buf[0] << 12) + ($buf[1] << 4) + $buf[2];

        if ($dump_wss) {
                my $crc = $g | (((1 << 6) - 1) << (14 + 6));

                for (my $j = 14 + 6 - 1; $j >= 0; $j--) {
                        if ($crc & ((1 << 6) << $j)) {
                                $crc ^= $poly << $j;
                        }
                }

                printf STDERR "WSS CPR >> g=%08x crc=%08x\n", $g, $crc;
        }
}

sub decode_sliced {
        my ($cap, $sliced, $time, $lines) = @_;
        my ($data, $id, $line);

        if ($dump_sliced) {
                $outfile->printf("Sliced time: %f\n", $time);

                for (my $i = 0; $i < $lines; $i++) {
                        ($data, $id, $line) = Video::ZVBI::get_sliced_line($sliced, $i);
                        $outfile->printf("%04x %3d > ", $id, $line);

                        for (my $j = 0; $j < length $data; ++$j) {
                                $outfile->printf("%02x ", ord(substr($data, $j, 1)));
                        }

                        $outfile->print(" ");

                        Video::ZVBI::unpar_str($data);
                        $data =~ s#[\x00-\x1F\x7F]#.#g;
                        $outfile->print($data);

                        $outfile->print("\n");
                }
        }

        for (my $i2 = 0; $i2 < $lines; $i2++) {
                ($data, $id, $line) = Video::ZVBI::get_sliced_line($sliced, $i2);

                if ($id == 0) {
                        next;
                } elsif ($id & VBI_SLICED_VPS) {
                      decode_vps($data);
                } elsif ($id & VBI_SLICED_TELETEXT_B) {
                      # Use ./decode instead.
                } elsif ($id & VBI_SLICED_CAPTION_525) {
                      # Use ./decode instead.
                } elsif ($id & VBI_SLICED_CAPTION_625) {
                      # Use ./decode instead.
                } elsif ($id & VBI_SLICED_WSS_625) {
                      decode_wss_625($data);
                } elsif ($id & VBI_SLICED_WSS_CPR1204) {
                        decode_wss_cpr1204($data);
                } else {
                        printf STDERR "Oops. Unhandled vbi service %08x\n", $id;
                }
        }
}

#
#  Sliced, binary
#

# hysterical compatibility
# (syntax note: "&" is required here to avoid auto-quoting of the bareword before "=>")
my %ServiceWidth = (
        &VBI_SLICED_TELETEXT_B => [42, 0],
        &VBI_SLICED_CAPTION_625 => [2, 1],
        &VBI_SLICED_VPS => [13, 2],
        &VBI_SLICED_WSS_625 => [2, 3],
        &VBI_SLICED_WSS_CPR1204 => [3, 4],
        &VBI_SLICED_CAPTION_525 => [2, 7],
);

sub binary_sliced {
        my ($cap, $sliced, $time, $lines) = @_;
        my $last = 0.0;
        my $i;

        if ($last > 0.0) {
                $outfile->printf("%f\n%c", $time - $last, $lines);
        } else {
                $outfile->printf("%f\n%c", 0.04, $lines);
        }

        for ($i = 0; $i < $lines; $i++) {
                my ($data, $id, $line) = Video::ZVBI::get_sliced_line($sliced, $i);
                if (defined($ServiceWidth{$id}) && ($ServiceWidth{$id}->[0] > 0)) {
                        $outfile->printf("%c%c%c", $ServiceWidth{$id}->[1],
                                         $line & 0xFF, $line >> 8);
                        $outfile->write($data, $ServiceWidth{$id}->[0]);
                        $last = time;
                }
        }

        $outfile->flush();
}

sub binary_ts_pes {
        my ($user_data, $packet, $packet_size) = @_;

        $outfile->write($packet, $packet_size);
        $outfile->flush();

        return 1;
}

sub mainloop {
        my $sliced;
        my $lines;
        my $raw;
        my $timestamp;

        for ($quit = 0; !$quit; ) {
                my $r;

                if ($do_read) {
                        $r = $cap->read($raw, $sliced, $lines, $timestamp, 2000);
                } else {
                        $r = $cap->pull($raw, $sliced, $lines, $timestamp, 2000);
                }

                if (0) {
                        $| = 1;
                        $outfile->print(".");
                }
 
                if ($r == -1) {
                        warn "VBI read error: $!\n";
                        next if $ignore_error;
                        exit(-1);
                } elsif ($r == 0) {
                        warn "VBI read timeout\n";
                        next if $ignore_error;
                        exit(-1);
                } elsif ($r == 1) {
                        # ok
                } else {
                        die "Unexpected capture result code $r\n";
                }

                if ($dump) {
                        decode_sliced($cap, $sliced, $timestamp, $lines);
                }
                if ($bin_sliced) {
                        binary_sliced($cap, $sliced, $timestamp, $lines);
                }
                if ($bin_pes || $bin_ts) {
                        # XXX shouldn't use system time
                        my $pts = $timestamp * 90000.0;
                        _vbi_dvb_mux_feed ($mx, $pts, $sliced, $lines, -1); # service_set: all
                }
        }
}

#static const char short_options[] = "123cd:elnpr:stvPT";

my %CmdOpts = (
        "desync" =>     \$desync,
        "device=s" =>   \$dev_name,
        "ignore-error" => \$ignore_error,
        "pid=i" =>      \$pid,
        "dump-ttx" =>   \$dump_ttx,
        "dump-xds" =>   \$dump_xds,
        "dump-cc" =>    \$dump_cc,
        "dump-wss" =>   \$dump_wss,
        "dump-vps" =>   \$dump_vps,
        "dump-sliced" => \$dump_sliced,
        "pes" =>        \$bin_pes,
        "sliced" =>     \$bin_sliced,
        "ts" =>         \$bin_ts,
        "read" =>       \$do_read,
        "pull" =>       \$do_read,
        "strict=i" =>   \$strict,
        "sim" =>        \$do_sim,
        "ntsc" =>       \$scanning_ntsc,
        "pal" =>        \$scanning_pal,
        "v4l" =>        \$api_v4l,
        "v4l2" =>       \$api_v4l2,
        "v4l2-read" =>  \$api_v4l2, # FIXME
        "v4l2-mmap" =>  \$api_v4l2, # FIXME
        "verbose+" =>   \$verbose,
);

sub main_func {
        my $errstr;
        my $services;
        my $scanning = 0;
        my $verbose = 0;

        GetOptions(%CmdOpts) || die "";

        $scanning = 625 if $scanning_pal;
        $scanning = 525 if $scanning_ntsc;

        if ($dump_ttx | $dump_cc | $dump_xds) {
                print STDERR "Teletext, CC and XDS decoding are no longer supported by this tool.\n".
                             "Run  ./capture --sliced | ./decode --ttx --cc --xds  instead.\n";
                exit -1;
        }

        $dump = $dump_wss | $dump_vps | $dump_sliced;

        $services = VBI_SLICED_VBI_525 |
                    VBI_SLICED_VBI_625 |
                    VBI_SLICED_TELETEXT_B |
                    VBI_SLICED_CAPTION_525 |
                    VBI_SLICED_CAPTION_625 |
                    VBI_SLICED_VPS |
                    VBI_SLICED_WSS_625 |
                    VBI_SLICED_WSS_CPR1204;

        if ($do_sim) {
                #$cap = Video::ZVBI::sim_new ($scanning, $services, 0, !$desync);
                $par = $cap->parameters();
                die unless defined $par;
        } else {
                while (1) {
                        if (-1 != $pid) {
                                $cap = Video::ZVBI::capture::dvb_new ($dev_name,
                                                           $scanning,
                                                           $services,
                                                           $strict,
                                                           $errstr,
                                                           $verbose != 0);
                                if (defined $cap) {
                                        $cap->dvb_filter ($pid);
                                        last;
                                }

                                die "Cannot capture vbi data with DVB interface:\n$errstr\n";
                        }

                        if (!$api_v4l) {
                                $cap = Video::ZVBI::capture::v4l2_new ($dev_name,
                                                            5, # buffers
                                                            $services,
                                                            $strict,
                                                            $errstr,
                                                            $verbose != 0);
                                last if defined $cap;

                                die "Cannot capture vbi data with v4l2 interface:\n$errstr\n";

                        }
                        
                        if (!$api_v4l2) {
                                $cap = Video::ZVBI::capture::v4l_new ($dev_name,
                                                           $scanning,
                                                           $services,
                                                           $strict,
                                                           $errstr,
                                                           $verbose != 0);
                                last if $cap;

                                die "Cannot capture vbi data with v4l interface:\n$errstr\n";
                        }

                        # BSD interface
                        if (1) {
                                $cap = Video::ZVBI::capture::bktr_new ($dev_name,
                                                            $scanning,
                                                            $services,
                                                            $strict,
                                                            $errstr,
                                                            $verbose != 0);
                                last if defined $cap;

                                die "Cannot capture vbi data with bktr interface:\n$errstr\n";
                        }

                        warn "Nothing to do - exiting.\n";
                        exit(-1);

                }

                $par = $cap->parameters();
                die unless defined $par;
        }

        if ($verbose > 1) {
                #TODO $cap->set_log_fp (STDERR);
        }

        if (-1 == $pid) {
                die unless ($par->{sampling_format} == VBI_PIXFMT_YUV420);
        }

        if ($bin_pes) {
                $mx = _vbi_dvb_mux_pes_new (0x10, # data_identifier
                                           8 * 184, # packet_size
                                           0, #TODO VBI_VIDEOSTD_SET_625_50,
                                           \&binary_ts_pes);
                die unless defined $mx;
        } elsif ($bin_ts) {
                $mx = _vbi_dvb_mux_ts_new (999, # pid
                                          0x10, # data_identifier
                                          8 * 184, # packet_size
                                          0, #TODO VBI_VIDEOSTD_SET_625_50,
                                          \&binary_ts_pes);
                die unless defined $mx;
        }

        $outfile = new IO::Handle;
        $outfile->fdopen(fileno(STDOUT), "w");

        mainloop();
}

main_func();

