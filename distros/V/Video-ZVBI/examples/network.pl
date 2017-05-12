#!/usr/bin/perl -w
#
#  libzvbi network identification example.
#
#  Copyright (C) 2006 Michael H. Schimek
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

# Perl $Id: network.pl,v 1.1 2007/11/18 18:48:35 tom Exp tom $
# ZVBI #Id: network.c,v 1.2 2006/10/27 04:52:08 mschimek Exp #

# This example shows how to identify a network from data transmitted
# in XDS packets, Teletext packet 8/30 format 1 and 2, and VPS packets.

use blib;
use strict;
use Getopt::Long;
use Encode;
use Video::ZVBI qw(/^VBI_/);

my $cap;
my $dec;
my $quit;

my $option_vps = 0;
my $option_8301 = 0;
my $option_8302 = 0;
my $option_help = 0;
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

        $quit = 1 if $ev->{cni_vps} != 0 && $option_vps;
        $quit = 1 if $ev->{cni_8301} != 0 && $option_8301;
        $quit = 1 if $ev->{cni_8302} != 0 && $option_8302;
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
        print STDERR "$0 - network identification test\n".
                     "Options:\n".
                     "\t--vps\tStop after receiving VPS\n".
                     "\t--8301\tStop after receiving packet 8/30/1\n".
                     "\t--8302\tStop after receiving packet 8/30/2\n".
                     "\t--help\tPrint this usage info\n";
        exit(1);
}

my %CmdOpts = (
        "vps" =>       \$option_vps,
        "8301" =>      \$option_8301,
        "8302" =>      \$option_8302,
);

sub main_func
{
	my $errstr;
	my $success;

        GetOptions(%CmdOpts) || usage();

        if (!$option_vps && !$option_8301 && !$option_8302) {
                $option_vps = $option_8301 = $option_8302 = 1;
        }

	$services = (VBI_SLICED_TELETEXT_B |
		     VBI_SLICED_VPS |
		     VBI_SLICED_CAPTION_525);

        # open VBI device (buffers:=5, strict:=0, verbose:=FALSE
	$cap = Video::ZVBI::capture::v4l2_new ("/dev/vbi0", 5, $services, 0, $errstr, 0);
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

