#!/usr/bin/perl -w
#
#  Copyright (C) 2007,2020 Tom Zoerner
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
#  Example for the use of class Video::ZVBI::dvb_mux. This script excercises
#  the DVB multiplexer functions: The script first opens a capture device
#  (normally this will be an analog device), then continuously captures VBI
#  data, encodes it in a DVB packet stream and wites the result to STDOUT. The
#  output stream can be decoded equivalently to that of capture.pl --pes,
#  which is:
#
#    ./dvb-mux.pl --pid NNN | ./decode.pl --pes --all

use strict;
use blib;
use Getopt::Long;
use Video::ZVBI qw(/^VBI_/);

my $opt_device = "/dev/dvb/adapter0/demux0";
my $opt_pid = 0;  # mandatory for DVB
my $opt_v4l2 = 0;
my $opt_use_feed = 0;
my $opt_use_read = 0;
my $opt_verbose = 0;
my $opt_help = 0;

# callback function invoked by Video::ZVBI::dvb_mux::feed()
sub feed_cb {
   my ($pkg, $user_data) = @_;

   syswrite STDOUT, $pkg;
   print STDERR "wrote ".length($pkg)."\n";
   # return 1, else multiplexing is aborted
   1;
}

sub main_func {
   my $opt_buf_count = 5;
   my $opt_services = VBI_SLICED_TELETEXT_B |
                      VBI_SLICED_VPS |
                      VBI_SLICED_CAPTION_625 |
                      VBI_SLICED_WSS_625;
   my $opt_strict = 0;
   my $err;
   my $pxc;
   my $cap;
   my $mux;

   if ($opt_v4l2 || (($opt_pid == 0) && ($opt_device !~ /dvb/))) {
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
   } else {
      warn "WARNING: DVB devices require --pid parameter\n" if $opt_pid <= 0;
      $cap = Video::ZVBI::capture::dvb_new2($opt_device, $opt_pid, $err, $opt_verbose);
   }

   if ($opt_verbose) {
      Video::ZVBI::set_log_on_stderr(0xFFFF);
   }

   # create DVB multiplexer
   if ($opt_use_feed) {
      $mux = Video::ZVBI::dvb_mux::pes_new(\&feed_cb);
   } else {
      $mux = Video::ZVBI::dvb_mux::pes_new();
   }
   die "failed to create dvb_mux: $!\n" unless defined $mux;

   while (1) {
      my $sliced;
      my $timestamp;
      my $n_lines;
      my $res;

      # read a sliced VBI frame
      if ($opt_use_read) {
         $res = $cap->read_sliced($sliced, $n_lines, $timestamp, 1000);
      } else {
         $res = $cap->pull_sliced($sliced, $n_lines, $timestamp, 1000);
      }
      die "Capture error: $!\n" if $res < 0;

      if ($opt_use_feed == 0) {
         my $sliced_left = $n_lines;

         # pass sliced data to multiplexer
         my $buf_size = 2048;
         my $buf_left = $buf_size;
         my $buf;
         while ($sliced_left > 0) {
            print STDERR "$timestamp $buf_left <- $n_lines+$sliced_left\n";
            if (!$mux->cor($buf, $buf_left, $sliced, $sliced_left, $opt_services, $timestamp*90000.0)) {

               # encoding error: dump the offending line
               print STDERR "ERROR in line ".($n_lines-$sliced_left)."\n";
               my($data,$id,$line) = Video::ZVBI::get_sliced_line($sliced, $n_lines-$sliced_left);
               Video::ZVBI::unpar_str($data);
               $data =~ s#[\x00-\x1F\x7F]#.#g;
               print STDERR "MUX ERROR in line idx:".($n_lines-$sliced_left)." ID:$id phys:$line >".substr($data,0,42)."<\n";

               $sliced_left -= 1 if $sliced_left > 0;
               last if $sliced_left == 0;
            }
            #die if $buf_left == 0;  # buffer too small
         }
         syswrite STDOUT, $buf, $buf_size-$buf_left if defined $buf;
         print STDERR "wrote ".($buf_size-$buf_left)."\n";

      } else {
         if (!$mux->feed($sliced, $n_lines, $opt_services, $timestamp*90000.0)) {
            print STDERR "ERROR in feed\n";
         }
      }
   }

   exit(-1);
}

sub usage {
        print STDERR "\
Example for DVB multiplexer in Video::ZVBI\
Copyright (C) 2007,2020 T. Zoerner\
This program is licensed under GPL 2 or later. NO WARRANTIES.\n\
Usage: $0 [OPTIONS]\n\
--device PATH     Specify the capture device\
--pid NNN         Specify the PES stream PID: Required for DVB\
--v4l2            Force device to be addressed via analog driver\
--use-read        Use \"read\" capture method instead of \"pull\"
--use-feed        Use feed/callback API of class Video::ZVBI::dvb_mux\
--verbose         Emit debug trace output\
--help            Print this message and exit\
";
  exit(1);
}
my %CmdOpts = (
        "device=s" =>  \$opt_device,
        "pid=i" =>     \$opt_pid,
        "v4l2" =>      \$opt_v4l2,
        "use-read" =>  \$opt_use_read,
        "use-feed" =>  \$opt_use_feed,
        "verbose" =>   \$opt_verbose,
        "help" =>      \$opt_help,
);
GetOptions(%CmdOpts) || usage();
usage() if $opt_help;
die "Options --v4l2 and --pid are mutually exclusive\n" if $opt_v4l2 && $opt_pid;

main_func();
