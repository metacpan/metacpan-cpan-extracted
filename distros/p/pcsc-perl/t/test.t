#!/usr/bin/perl

#    test.pl: simple sample program based on test.pl to test the pcsc
#    Perl wrapper under Test::Harness
#    Copyright (C) 2001  Lionel Victor, 2003,2006 Ludovic Rousseau
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

# $Id: test.t,v 1.6 2006-12-09 13:07:26 rousseau Exp $

use Test::More;
use Chipcard::PCSC;

plan tests => 2;

use strict;
use warnings;

my $hContext;
my @ReadersList;

my @StatusResult;
my $tmpVal;
my $SendData;
my $RecvData;

#-------------------------------------------------------------------------------
$hContext = new Chipcard::PCSC();
#die ("not ok : Can't create the pcsc object: $Chipcard::PCSC::errno\n") unless (defined $hContext);
ok(defined $hContext, "new Chipcard::PCSC()");

#-------------------------------------------------------------------------------
@ReadersList = $hContext->ListReaders ();
#die ("not ok : Can't get readers' list: $Chipcard::PCSC::errno\n") unless (defined($ReadersList[0]));
ok(defined($ReadersList[0]), "\$hContext->ListReaders ()");

#-------------------------------------------------------------------------------
$hContext = undef;

# End of File #

