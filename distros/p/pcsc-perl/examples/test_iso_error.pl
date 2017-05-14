#!/usr/bin/perl

#    test_iso_error.pl: simple program to test the pcsc Perl wrapper
#    Copyright (C) 2003 Ludovic Rousseau
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# $Id: test_iso_error.pl,v 1.2 2006-08-12 17:35:53 rousseau Exp $

use ExtUtils::testlib;
use Chipcard::PCSC::Card;

use warnings;
use strict;

my ($sw1, $sw2, $sw1hex, $sw2hex, $sw, $error);

for $sw1 (0..255)
{
	$sw1hex = sprintf "%02X", $sw1;
	for $sw2 (0..255)
	{
		$sw2hex = sprintf "%02X", $sw2;

		$sw = "$sw1hex $sw2hex";
		$error = &Chipcard::PCSC::Card::ISO7816Error($sw);
		print "$sw: $error\n" unless ($error =~ m/not defined by ISO/); 
	}
}

