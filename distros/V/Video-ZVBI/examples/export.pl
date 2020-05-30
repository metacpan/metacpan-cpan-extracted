#!/usr/bin/perl -w
#
#  libzvbi test of page export in different formats
#
#  Copyright (C) 2000, 2001 Michael H. Schimek
#  Perl Port: Copyright (C) 2006, 2007, 2020 Tom Zoerner
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

# Description:
#
#   Example for the use of export actions in class Video::ZVBI::export.
#   The script captures from a device until the page specified on the
#   command line is found and then exports the page content in a requested
#   format.  Alternatively, the script can be used to continuously export
#   a single or all received pages. Examples:
#
#     ./export.pl text 100       # teletext page 100 as text
#     ./export.pl text all       # continuously all teletext pages
#     ./export.pl --loop text 1  # continuously closed caption
#     ./export.pl "png;reveal=1" 100 > page_100.png
#
#   Use ./explist.pl for listing supported export formats (aka "modules")
#   and possible options. Note options are appended to the module name,
#   separated by semicolon as shown in the second example.
#
#   (This is a direct translation of test/export.c in libzvbi.)

use blib;
use strict;
use Getopt::Long;
use POSIX;
use IO::Handle;
use Video::ZVBI qw(/^VBI_/);

my $vbi;
my $ex;
my $extension;
my $pgno;
my $quit = 0;
my $cr;

my $opt_device = "/dev/dvb/adapter0/demux0";
my $opt_pid = 0;  # mandatory for DVB
my $opt_v4l2 = 0;
my $opt_pes = 0;
my $opt_to_file = 0;
my $opt_loop = 0;
my $opt_verbose = 0;
my $opt_help = 0;

sub ttx_handler {
        my($type, $ev, $user_data) = @_;

        printf STDERR "${cr}Page %03x.%02x ",
                $ev->{pgno},
                $ev->{subno} & 0xFF;

        if ($pgno != -1 && $ev->{pgno} != $pgno) {
                return;
        }

        print STDERR "\nSaving page $ev->{pgno}... ";
        print STDERR "\n" if !$opt_to_file;
        #IO::Handle::flush(fileno(STDERR));

        # Fetching & exporting here is a bad idea,
        # but this is only a test.
        my $page = $vbi->fetch_vt_page($ev->{pgno}, $ev->{subno},
                                       VBI_WST_LEVEL_3p5, 25, 1) || die;

        my $io = new IO::Handle;
        # Just for fun
        if ($opt_to_file) {
                my $name = sprintf("ttx-%03x-%02x.%s",
                                   $ev->{pgno}, $ev->{subno}, $extension);
                $io->open($name, "w") || die "create $name: $!\n";
        } else {
                $io->fdopen(fileno(STDOUT), "w");
        }

        if (!$ex->stdio($io, $page)) {
                print STDERR "failed: ". $ex->errstr() ."\n";
                exit(-1);
        } else {
                print STDERR "done\n";
        }
        ##my $img = $ex->alloc($page);
        #my $img = "";
        #my $s = $ex->mem($img, $page);
        #die "Export failed: ". $ex->errstr() ." ($s)\n" if $s < 0;
        #$img = "." x $s;
        #$s = $ex->mem($img, $page);
        #die "Export failed: ". $ex->errstr() ." ($s)\n" if $s < 0;
        #die "Export failed: Buffer too small (need $s, have ".length($img).")\n" if $s > length($img);
        #print $io $img;
        #$io->close();
        #print STDERR "Image size: ".length($img)."\n";

        undef $page;

        if (!$opt_loop && $pgno != -1) {
                $quit = 1;
        }
}

sub cc_handler {
        my($type, $ev, $user_data) = @_;

        printf STDERR "${cr}CC page %d ", $ev->{pgno};

        if ($pgno != -1 && $ev->{pgno} != $pgno) {
                return;
        }

        print STDERR "\nSaving... ";
        print STDERR "\n" if !$opt_to_file;

        my $page = $vbi->fetch_cc_page($ev->{pgno}) || die;

        if ($opt_to_file) {
                my $name = sprintf("ttx-%03x-%02x.%s",
                                   $ev->{pgno}, $ev->{subno}, $extension);
                $ex->file($name, $page) || die "Export failed: ".$ex->errstr() ."\n";
        } else {
                my $buf;
                $ex->mem($buf, $page);
                print $buf . "\n";
        }

        undef $page;

        if (!$opt_loop && $pgno != -1) {
                $quit = 1;
        }
}

sub pes_mainloop {
        my $buffer;
        my $sliced;
        my $lines;
        my $pts;

        my $dx = Video::ZVBI::dvb_demux::pes_new ();
        die unless defined $dx;

        while (read (STDIN, $buffer, 2048)) {
                my $buf_left = length($buffer);

                while ($buf_left > 0) {
                        $lines = $dx->cor ($sliced, 64, $pts, $buffer, $buf_left);
                        if ($lines > 0) {
                                $vbi->decode ($sliced, $lines, $pts / 90000.0);
                        }

                        return if $quit;
                }
        }

        printf STDERR "\rEnd of stream, page %03x not found\n", $pgno unless $quit;
}

sub old_mainloop {
        my $cap;
        my $err;

        if ($opt_v4l2 || (($opt_pid == 0) && ($opt_device !~ /dvb/))) {
                my $opt_buf_count = 5;
                my $opt_services = VBI_SLICED_TELETEXT_B;
                my $opt_strict = 0;

                $cap = Video::ZVBI::capture::v4l2_new($opt_device, $opt_buf_count, $opt_services, $opt_strict, $err, $opt_verbose) || die "V4l open: $!\n";
        }
        else {
                warn "WARNING: DVB devices require --pid parameter\n" if $opt_pid == 0;
                $cap = Video::ZVBI::capture::dvb_new2($opt_device, $opt_pid, $err, $opt_verbose);
        }
        die "Failed to open video device: $err\n" unless $cap;

        while (!$quit) {
                my $sliced;
                my $timestamp;
                my $n_lines;

                #my $res = $cap->read_sliced($sliced, $n_lines, $timestamp, 1000);
                my $res = $cap->pull_sliced($sliced, $n_lines, $timestamp, 1000);
                die "Capture error: $!\n" if $res < 0;
                warn "Capture timeout\n" if $res == 0;

                $vbi->decode($sliced, $n_lines, $timestamp) if $res > 0;
        }

        printf STDERR "\rEnd of stream, page %03x not found\n", $pgno unless $quit;
}

sub main_func {
        my $module;
        my $t;

        usage() if ($#ARGV < 1);
        die "No PES data on stdin, which is a terminal\n" if ($opt_pes && -t);

        $module = $ARGV[0];
        if ($ARGV[1] eq "all") {
                $pgno = -1;
        } else {
                $pgno = hex($ARGV[1]);
                die "Parameter \"$ARGV[1]\" is neither a valid teletext nor a CC page\n"
                        unless (($pgno >= 0x100 && $pgno <= 0x8FF) || ($pgno >= 1 && $pgno <= 8));
        }

        $cr = (-t STDERR) ? "\r" : "\n";

        $ex = Video::ZVBI::export::new($module, $t);
        die "Failed to open export module '$module': $t\n" unless defined $ex;

        my $xi = $ex->info_export();
        die "Failed to create export context\n" unless defined $xi;
        $extension = $xi->{extension};
        $extension =~ s#,.*##;
        undef $xi;

        $vbi = Video::ZVBI::vt::decoder_new();
        die "Failed to create VT decoder\n" unless defined $vbi;

        my $ok = $vbi->event_handler_register(VBI_EVENT_TTX_PAGE, \&ttx_handler) &&
                 $vbi->event_handler_register(VBI_EVENT_CAPTION, \&cc_handler);
        die "Failed to install event handlers\n" unless $ok;

        if ($opt_pes) {
                pes_mainloop ();
        } else {
                old_mainloop ();
        }
}

sub usage {
        print STDERR "\
libzvbi test of page export in different formats
Copyright (C) 2000, 2001 Michael H. Schimek
This program is licensed under GPL 2 or later. NO WARRANTIES.\n\
Usage: $0 [OPTIONS] MODULE PAGE_NO\n\
Where:
MODULE            One of the supported export formats (see explist.pl)\
PAGE_NO           A teletext or CC page number, or \"all\"\n\
Options:\
--device PATH     Specify the capture device\
--pid NNN         Specify the PES stream PID: Required for DVB\
--v4l2            Force device to be addressed via analog driver\
--pes             Read DVB PES input stream from STDIN
--loop            Do not exit after exporting; repeat for every reception\
--to-file         Store to file named ttx-PGNO-SUBPG.dat or CC-PGNO.dat\
--verbose         Emit debug trace output\
--help            Print this message and exit\
";
  exit(1);
}
my %CmdOpts = (
        "device=s" =>  \$opt_device,
        "pid=i" =>     \$opt_pid,
        "v4l2" =>      \$opt_v4l2,
        "pes" =>       \$opt_pes,
        "to-file" =>   \$opt_to_file,
        "loop" =>      \$opt_loop,
        "verbose" =>   \$opt_verbose,
        "help" =>      \$opt_help,
);
GetOptions(%CmdOpts) || usage();
usage() if $opt_help;
die "Options --v4l2 and --pid are mutually exclusive\n" if $opt_v4l2 && $opt_pid;
die "Options --pes and --v4l2/--pid are mutually exclusive\n" if $opt_pes && ($opt_v4l2 || $opt_pid);

main_func();
