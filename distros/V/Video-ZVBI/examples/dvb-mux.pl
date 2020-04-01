#!/usr/bin/perl -w
#
#  Very simple test of the DVB PES multiplexer:
#  - reading sliced data from an analog capture device
#  - multiplexer output is written to STDOUT
#  - output can be decoded with examples/decode.pl --pes --all
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

# $Id: dvb-mux.pl,v 1.2 2020/04/01 07:31:19 tom Exp tom $

use strict;
use blib;
use Video::ZVBI qw(/^VBI_/);

# callback function invoked by Video::ZVBI::dvb_mux::feed()
sub feed_cb {
   my ($pkg, $user_data) = @_;

   syswrite STDOUT, $pkg;
   print STDERR "wrote ".length($pkg)."\n";
   # return 1, else multiplexing is aborted
   1;
}

sub main_func {
   my $opt_device = "/dev/vbi0";
   my $opt_buf_count = 5;
   my $opt_services = VBI_SLICED_TELETEXT_B_625;
   #my $opt_services = VBI_SLICED_TELETEXT_A;
   my $opt_strict = 0;
   my $opt_verbose = 0;
   my $opt_use_feed = 0;
   my $err;
   my $pxc;
   my $cap;
   my $mux;

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

   Video::ZVBI::set_log_on_stderr(0xFFFF);

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
      $res = $cap->pull_sliced($sliced, $n_lines, $timestamp, 1000);
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

main_func();

