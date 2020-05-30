#!/usr/bin/perl -w
#
#  libzvbi network identification example.
#
#  Copyright (C) 2006 Michael H. Schimek
#  Perl Port: Copyright (C) 2007,2020 Tom Zoerner
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
#   Example for the use of class Video::ZVBI::vt, type VBI_EVENT_NETWORK.
#   This script shows how to identify a network from data transmitted in
#   XDS packets, Teletext packet 8/30 format 1 and 2, and VPS packets. The
#   script captures from a device until the currently tuned channel is
#   identified by means of VPS, PDC et.al.
#
#   (This is a direct translation of examples/network.c in libzvbi.)

use blib;
use strict;
use Getopt::Long;
use Encode;
use Video::ZVBI qw(/^VBI_/);

my $cap;
my $dec;
my $quit;

my $opt_device = "/dev/dvb/adapter0/demux0";
my $opt_pid = 0;  # mandatory for DVB
my $opt_v4l2 = 0;
my $opt_verbose = 0;
my $opt_help = 0;
my $opt_vps = 0;
my $opt_8301 = 0;
my $opt_8302 = 0;
my $services;

sub handler {
        my($ev_type, $ev, $user_data) = @_;

	my $event_name;
	my $call_sign;
	my $network_name;

	# VBI_EVENT_NETWORK_ID is always sent when the decoder
	# receives a CNI. VBI_EVENT_NETWORK only if it can
	# determine a network name.

	if ($ev_type == VBI_EVENT_NETWORK) {
		$event_name = "VBI_EVENT_NETWORK";

	} elsif ($ev_type == VBI_EVENT_NETWORK_ID) {
		$event_name = "VBI_EVENT_NETWORK_ID";

        } else {
		die "Unexpected event type: $ev_type\n";
	}

	if (defined $ev->{name}) {
                # The network name is an ISO-8859-1 string (the API is
                # quite old...) so we convert it to locale encoding,
                # nowadays usually UTF-8.
                $network_name = decode("ISO-8859-1", $ev->{name});
        } else {
                $network_name = "unknown";
        }

	# ASCII.
	if (defined $ev->{call}) {
		$call_sign = $ev->{call};
        } else {
                $call_sign = "unknown";
        }

	printf  "%s: receiving: \"%s\" call sign: \"%s\" " .
	        "CNI VPS: 0x%x 8/30-1: 0x%x 8/30-2: 0x%x\n",
		$event_name,
		$network_name,
		$call_sign,
		$ev->{cni_vps},
		$ev->{cni_8301},
		$ev->{cni_8302};

        $quit = 1 if $ev->{cni_vps} != 0 && $opt_vps;
        $quit = 1 if $ev->{cni_8301} != 0 && $opt_8301;
        $quit = 1 if $ev->{cni_8302} != 0 && $opt_8302;
}

sub mainloop {
	my $timeout;
	my $sliced_buffer;
	my $n_frames;

	# Don't wait more than two seconds for the driver to return data.
	$timeout = 2000;

	# Should receive a CNI within two seconds, call sign within ten seconds(?).
	if ($services & VBI_SLICED_CAPTION_525) {
		$n_frames = 11 * 30;
	} else {
		$n_frames = 3 * 25;
        }

	for (; $n_frames > 0; --$n_frames) {
		my $n_lines;
	        my $timestamp;
		my $r;

		$r = $cap->pull_sliced ( $sliced_buffer,
                                         $n_lines,
                                         $timestamp,
				         $timeout);
		if ($r == -1) {
			# Could be ignored, esp. EIO with some drivers.
			die "VBI read error: $!\n";

                } elsif ($r == 0) {
			die "VBI read timeout\n";

                } elsif ($r == 1) {
			# continue

                } else {
			die "Unexpected result code from pull_sliced: $r\n";
		}

		$dec->decode ( $sliced_buffer, $n_lines, $timestamp );

                return if defined $quit;
	}

	print "No network ID received or network unknown.\n";
}

sub usage {
        print STDERR "Network identification test\n".
                     "Copyright (C) 2006 Michael H. Schimek\n".
                     "This program is licensed under GPL 2 or later. NO WARRANTIES.\n".
                     "Usage: $0 [OPTIONS]\n".
                     "--device PATH\tSpecify the capture device\n".
                     "--pid NNN\tSpecify the PES stream PID: Required for DVB\n".
                     "--v4l2\t\tForce device to be addressed via analog driver\n".
                     "--vps\t\tStop after receiving VPS\n".
                     "--8301\t\tStop after receiving packet 8/30/1\n".
                     "--8302\t\tStop after receiving packet 8/30/2\n".
                     "--verbose\tEmit debug trace output\n".
                     "--help\t\tPrint this usage info\n";
        exit(1);
}

my %CmdOpts = (
        "device=s" =>  \$opt_device,
        "pid=i" =>     \$opt_pid,
        "v4l2" =>      \$opt_v4l2,
        "verbose" =>   \$opt_verbose,
        "vps" =>       \$opt_vps,
        "8301" =>      \$opt_8301,
        "8302" =>      \$opt_8302,
        "help" =>      \$opt_help,
);

sub main_func {
	my $errstr;
	my $success;

        GetOptions(%CmdOpts) || usage();
        usage() if $opt_help;

        if (!$opt_vps && !$opt_8301 && !$opt_8302) {
                $opt_vps = $opt_8301 = $opt_8302 = 1;
        }

	$services = (VBI_SLICED_TELETEXT_B |
		     VBI_SLICED_VPS |
		     VBI_SLICED_CAPTION_525);

        if ($opt_v4l2 and ($opt_pid != 0)) {
                print STDERR "Options --v4l2 and --pid are mutually exclusive\n";
                exit(1)
        }
        if (!$opt_v4l2 && ($opt_pid == 0) && ($opt_device !~ /dvb/)) {
                # open VBI device (buffers:=5, strict:=0, verbose:=FALSE
                $cap = Video::ZVBI::capture::v4l2_new ($opt_device, 5, $services, 0, $errstr, 0);
        }
        else {
                warn "WARNING: DVB devices require --pid parameter\n" if $opt_pid <= 0;
                $cap = Video::ZVBI::capture::dvb_new2($opt_device, $opt_pid, $errstr, 0);
        }
        die "Cannot capture VBI data with V4L2 interface: $errstr\n" unless $cap;

	$dec = Video::ZVBI::vt::decoder_new ();
	die "Failed to create VT decoder\n" unless $dec;

	$success = $dec->event_handler_add ( (VBI_EVENT_NETWORK |
                                              VBI_EVENT_NETWORK_ID),
					     \&handler );
	die "Failed to install event handler\n" unless $success;

	mainloop ();
}

main_func();
