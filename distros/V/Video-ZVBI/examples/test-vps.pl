#!/usr/bin/perl -w
#
#  libzvbi test
#  Copyright (C) 2006 Michael H. Schimek
#  Perl Port: Copyright (C) 2007 Tom Zoerner
#

# Perl $Id: test-vps.pl,v 1.1 2007/11/18 18:48:35 tom Exp tom $
# #Id: test-vps.c,v 1.3 2006/10/08 06:19:48 mschimek Exp $

use strict;
use blib;
use Video::ZVBI;

sub main
{
	my @cnis = ( 0x000, 0x001, 0x5A5, 0xA5A, 0xFFF );
	my @rands;
	my $buffer1;
	my $buffer2;
	my $cni2;
	my $i;

	for ($i = 0; $i < 13; ++$i) {
                push @rands, int(rand(256));
        }

	$buffer2 = pack("C13", @rands);
	$buffer1 = $buffer2;

        $cni2 = Video::ZVBI::decode_vps_cni($buffer2);

        $buffer1 = Video::ZVBI::encode_vps_cni ($cni2);
        die unless defined $buffer1;
	#die unless ($buffer1 eq $buffer2);

	for ($i = 0; $i <= $#cnis; ++$i) {
		my $cni;

		$buffer1 = Video::ZVBI::encode_vps_cni ($cnis[$i]);
		die unless defined $buffer1;

		$cni = Video::ZVBI::decode_vps_cni ($buffer1);
		die unless defined $cni;
		die unless ($cni == $cnis[$i]);
	}

	$buffer1 = Video::ZVBI::encode_vps_cni (-1) and die;
	$buffer1 = Video::ZVBI::encode_vps_cni (0x1000) and die;
	$buffer1 = Video::ZVBI::encode_vps_cni ((1<<31)-1) and die;
}

srand;
main();

