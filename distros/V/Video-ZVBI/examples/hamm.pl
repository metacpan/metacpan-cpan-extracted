#!/usr/bin/perl -w
#
#  libzvbi test
#
#  Copyright (C) 2003, 2005 Michael H. Schimek
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

# Perl $Id: hamm.pl,v 1.1 2007/11/18 18:48:35 tom Exp tom $
# ZVBI #Id: hamm.c,v 1.2 2006/03/17 13:37:05 mschimek Exp #

# Automated test of the odd parity and Hamming test/set routines.

use blib;
use strict;
use Video::ZVBI;

sub sizeof { 4 }
sub CHAR_BIT { 8 }
sub cast_unsigned_int { $_[0] & 0xFFFFFFFF }
sub cast_int { $_[0] & 0xFFFFFFFF }
sub mrand48 { int(rand(0xFFFFFFF)) * (rand() >= 0.5 ? 1 : -1) }

sub parity {
        my ($n) = @_;
	my $sh;

	for ($sh = sizeof ($n) * CHAR_BIT() / 2; $sh > 0; $sh >>= 1) {
		$n ^= $n >> $sh;
        }

	return $n & 1;
}

sub BC { (($_[0]) * cast_unsigned_int(0x01010101)); } #0x0101010101010101

sub population_count {
        my ($n) = @_;

	$n -= ($n >> 1) & BC (0x55);
	$n = ($n & BC (0x33)) + (($n >> 2) & BC (0x33));
	$n = ($n + ($n >> 4)) & BC (0x0F);

	return ($n * BC (0x01)) >> (sizeof ("unsigned int") * 8 - 8);
}

sub hamming_distance {
        my ($a, $b) = @_;

	return population_count ($a ^ $b);
}

sub main_func {
        my ($d, $n , $r, $i, $j, $nn, $dd);
        my ($A, $B, $C, $D, $E, $F);
        my @intbuf;
	my $buf;

        $| = 1;
        print "Testing parity...";

	for ($i = 0; $i < 10000; ++$i) {
		$n = ($i < 256) ? $i : cast_unsigned_int(mrand48 ());
		$buf = pack("C3", $n&0xFF, ($n >> 8)&0xFF, ($n >> 16)&0xFF );

		for ($r = 0, $j = 0; $j < 8; ++$j) {
			if ($n & (0x01 << $j)) {
				$r |= 0x80 >> $j;
                        }
                }

		die unless ($r == Video::ZVBI::rev8 ($n));

		if (parity ($n & 0xFF)) {
			die unless (Video::ZVBI::unpar8 ($n) == cast_int($n & 127));
		} else {
			die unless (-1 == Video::ZVBI::unpar8 ($n));
                }

		die unless (Video::ZVBI::unpar8 (Video::ZVBI::par8 ($n)) >= 0);

		Video::ZVBI::par_str ($buf);
		die unless (Video::ZVBI::unpar_str ($buf) >= 0);
                @intbuf = unpack "C3", $buf;
		die unless (0 == (($intbuf[0] | $intbuf[1] | $intbuf[2]) & 0x80));

		$intbuf[1] = Video::ZVBI::par8 ($intbuf[1]);
		$intbuf[2] = $intbuf[1] ^ 0x80;
		$buf = pack("C3", @intbuf);

		die unless (Video::ZVBI::unpar_str ($buf) < 0);
                @intbuf = unpack "C3", $buf;
		die unless ($intbuf[2] == ($intbuf[1] & 0x7F));
	}
        print "OK\n";
        print "Testing Hamming-8/4...";

	for ($i = 0; $i < 10000; ++$i) {
		$n = ($i < 256) ? $i : cast_unsigned_int(mrand48());

		$A = parity ($n & 0xA3);
		$B = parity ($n & 0x8E);
		$C = parity ($n & 0x3A);
		$D = parity ($n & 0xFF);

		$d = (+ (($n & 0x02) >> 1)
		      + (($n & 0x08) >> 2)
		      + (($n & 0x20) >> 3)
		      + (($n & 0x80) >> 4));

		if ($A && $B && $C) {
			$nn = $D ? $n : ($n ^ 0x40);

			die unless (Video::ZVBI::ham8 ($d) == ($nn & 255));
			die unless (Video::ZVBI::unham8 ($nn) == $d);
		} elsif (!$D) {
			$dd = Video::ZVBI::unham8 ($n);
			die unless ($dd >= 0 && $dd <= 15);

			$nn = Video::ZVBI::ham8 ($dd);
			die unless (hamming_distance ($n & 255, $nn) == 1);
		} else {
			die unless (Video::ZVBI::unham8 ($n) == -1);
		}

		#Video::ZVBI::ham16 (buf, $n);
		#die unless (Video::ZVBI::unham16 (buf) == (int)($n & 255));
	}
        print "OK\n";
        print "Testing Hamming-24/18...";

	for ($i = 0; $i < (1 << 24); ++$i) {
		$buf = pack "C3", $i&0xFF, ($i >> 8)&0xFF, ($i >> 16)&0xFF;

		$A = parity ($i & 0x555555);
		$B = parity ($i & 0x666666);
		$C = parity ($i & 0x787878);
		$D = parity ($i & 0x007F80);
		$E = parity ($i & 0x7F8000);
		$F = parity ($i & 0xFFFFFF);

		$d = (+ (($i & 0x000004) >> (3 - 1))
		      + (($i & 0x000070) >> (5 - 2))
		      + (($i & 0x007F00) >> (9 - 5))
		      + (($i & 0x7F0000) >> (17 - 12)));
		
		if ($A && $B && $C && $D && $E) {
			die unless (Video::ZVBI::unham24p ($buf) == $d);
		} elsif ($F) {
			die unless (Video::ZVBI::unham24p ($buf) < 0);
		} else {
			my $err = (($E << 4) | ($D << 3)
			         | ($C << 2) | ($B << 1) | $A) ^ 0x1F;

			die unless ($err > 0);

			if ($err >= 24) {
				die unless (Video::ZVBI::unham24p ($buf) < 0);
				next;
			}

			my $ii = $i ^ (1 << ($err - 1));

			$A = parity ($ii & 0x555555);
			$B = parity ($ii & 0x666666);
			$C = parity ($ii & 0x787878);
			$D = parity ($ii & 0x007F80);
			$E = parity ($ii & 0x7F8000);
			$F = parity ($ii & 0xFFFFFF);

			die unless ($A && $B && $C && $D && $E && $F);

			$d = (+ (($ii & 0x000004) >> (3 - 1))
			      + (($ii & 0x000070) >> (5 - 2))
			      + (($ii & 0x007F00) >> (9 - 5))
			      + (($ii & 0x7F0000) >> (17 - 12)));

			die unless (Video::ZVBI::unham24p ($buf) == $d);
		}

                print "." if ($i & 0x00FFFF) == 0;
	}
        print "OK\n";

	return 0;
}

main_func();

