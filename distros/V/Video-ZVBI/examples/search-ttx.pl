#!/usr/bin/perl -w
#
#  libzvbi test of teletext search
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

# $Id: search-ttx.pl,v 1.3 2020/04/01 07:34:29 tom Exp tom $

use strict;
use blib;
use Video::ZVBI qw(/^VBI_/);

my $cr;

sub pg_handler {
   my($type, $ev, $lcr) = @_;

   printf STDERR "${lcr}Page %03x.%02x ",
           $ev->{pgno},
           $ev->{subno} & 0xFF;
}

sub progress {
   my ($pg,$user_data) = @_;
   my ($page,$sub) = $pg->get_page_no();
   printf "${cr}Search #$user_data->[0] %03X.%04x ", $page, $sub;
}

sub search {
   my ($vtdec) = @_;
   my $pat;
   print "\nEnter search pattern: ";
   chomp($pat = <STDIN>);
   if (defined($pat) && ($pat ne "")) {
      my $srch;
      my $pg;
      my $stat;
      my $any_sub = VBI_ANY_SUBNO;
      my $last_page;
      my $last_sub;

      #my $rand = [int(rand(1000))];
      #print "Search rand user data $rand->[0]\n";
      $srch = Video::ZVBI::search::new($vtdec, 0x100, $any_sub, $pat, 0, 0, \&progress);
      die "failed to initialize search: $!\n" unless $srch;

      while (($stat = $srch->next($pg, 1)) == VBI_SEARCH_SUCCESS) {
         # match found
         my ($page,$sub) = $pg->get_page_no();
         if (!defined($last_page) || !defined($last_sub) ||
             ($page != $last_page) || ($sub != $last_sub)) {

            printf "\nFound match: %03X.%04X\n", $page, $sub;
            my ($rows, $cols) = $pg->get_page_size();
            my $txt = $pg->get_page_text();
            for (my $row = 0; $row < $rows; $row++) {
               print substr($txt, $row*$cols, $cols) . "\n";
            }
            $last_page = $page;
            $last_sub = $sub;
         }
      }
      print "\n";
      die "search \"$pat\": result code $stat\n" unless $stat == VBI_SEARCH_NOT_FOUND;
   }
}

sub main_func {
   my $opt_device = "/dev/vbi0";
   my $opt_buf_count = 5;
   my $opt_services = VBI_SLICED_TELETEXT_B;
   my $opt_strict = 0;
   my $opt_verbose = 0;
   my $err;
   my $pxc;
   my $cap;
   my $vtdec;
   my $exp;

   $pxc = Video::ZVBI::proxy::create($opt_device, $0, 0, $err, $opt_verbose);
   if (defined $pxc) {
      # work-around for bug in proxy_new() prior to libzvbi 0.2.26 which closed STDIN
      open OLDSTDIN, "<&", \*STDIN;

      $cap = Video::ZVBI::capture::proxy_new($pxc, 5, 0, $opt_services, $opt_strict, $err);
      undef $pxc unless defined $cap;

      open STDIN, "<&OLDSTDIN"; # work-around cntd.
      close OLDSTDIN;
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

   $cr = (-t STDERR) ? "\r" : "\n";

   $vtdec = Video::ZVBI::vt::decoder_new();
   die "failed to create teletext decoder: $!\n" unless defined $vtdec;

   $vtdec->event_handler_register(VBI_EVENT_TTX_PAGE, \&pg_handler, $cr); 

   print STDERR "Press RETURN to stop capture and enter a search pattern\n";

   while (1) {
      my $sliced;
      my $timestamp;
      my $n_lines;
      my $res;

      my $rin = '';
      vec($rin, fileno(STDIN),1) = 1;
      if (select($rin, undef, undef, 0) > 0) {
         <STDIN>;
         search($vtdec);
      }

      $res = $cap->pull_sliced($sliced, $n_lines, $timestamp, 1000);
      die "Capture error: $!\n" if $res < 0;

      if ($res != 0) {
         $vtdec->decode($sliced, $n_lines, $timestamp);
      }
   }

   exit(-1);
}

main_func();

