#!/usr/bin/perl -w

#    test.pl: simple sample program to test the pcsc Perl wrapper
#    Copyright (C) 2001  Lionel Victor
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

# $Id: test.pl,v 1.4 2001/09/05 07:41:27 rousseau Exp $

# $Log: test.pl,v $
# Revision 1.4  2001/09/05 07:41:27  rousseau
# Added CVS Log and Id fields
# Added GPL licence
#

use ExtUtils::testlib;
use PCSC;
use PCSC::Card;

use strict;

my $hContext;
my @ReadersList;

my $hCard;
my @StatusResult;
my $tmpVal;
my $SendData;
my $RecvData;

#my @ConnectionContext;

#-------------------------------------------------------------------------------
print "Getting context:\n";
$hContext = new PCSC();
die ("Can't create the pcsc object: $PCSC::errno\n") unless (defined $hContext);
print '.'x40 . " OK\n";

#-------------------------------------------------------------------------------
print "Retrieving readers'list:\n";
@ReadersList = $hContext->ListReaders ();
die ("Can't get readers' list: $PCSC::errno\n") unless (defined($ReadersList[0]));
$, = "\n  ";
$" = "\n  ";
print "  @ReadersList\n" . '.'x40 . " OK\n";

#-------------------------------------------------------------------------------
print "Connecting to the card:\n";
$hCard = new PCSC::Card ($hContext);
die ("Can't create the reader object: $PCSC::errno\n") unless (defined($hCard));

$tmpVal = $hCard->Connect($ReadersList[0], $PCSC::SCARD_SHARE_SHARED);
unless ($tmpVal) {
	# Try to reconnect and reset if connect fails
	print "Connect failed: trying to reset the card:\n";
	$tmpVal = $hCard->Reconnect ($PCSC::SCARD_SHARE_SHARED, $PCSC::SCARD_PROTOCOL_T0, $PCSC::SCARD_RESET_CARD);
	die ("Can't reconnect to the reader '$ReadersList[0]': $PCSC::errno\n") unless ($tmpVal);
}
die ("Can't understand the current protocol: $hCard->{dwProtocol}\n")
	unless ($hCard->{dwProtocol}==$PCSC::SCARD_PROTOCOL_T0 ||
            $hCard->{dwProtocol}==$PCSC::SCARD_PROTOCOL_T1 ||
	        $hCard->{dwProtocol}==$PCSC::SCARD_PROTOCOL_RAW);
print '.'x40 . " OK\n";

#-------------------------------------------------------------------------------
print ("Setting up timeout value:\n");
die ("Can't set timeout: $PCSC::errno\n") unless ($hContext->SetTimeout (50));
print '.'x40 . " OK\n";

#-------------------------------------------------------------------------------
print "Getting status:\n";
@StatusResult = $hCard->Status();
die ("Can't get status: $PCSC::errno\n") unless ($StatusResult[0]);
print "Reader name is $StatusResult[0]\n";
print "State: $StatusResult[1]\n";
print "Current protocol: $StatusResult[2]\n";
print "ATR: " . PCSC::array_to_ascii ($StatusResult[3]) . "\n";
print '.'x40 . " OK\n";

#-------------------------------------------------------------------------------
print ("Initiating transaction:\n");
die ("Can't initiate transaction: $PCSC::errno\n") unless ($hCard->BeginTransaction());
print '.'x40 . " OK\n";

#-------------------------------------------------------------------------------
#sleep (13);

print ("Exchanging data:\n");
$SendData = PCSC::ascii_to_array ("00 A4 01 00 02 01 00");
$RecvData = $hCard->Transmit($SendData);
die ("Can't transmit data: $PCSC::errno") unless (defined ($RecvData));

print "  Send -> " . PCSC::array_to_ascii ($SendData) . "\n";
print "  Recv <- " . PCSC::array_to_ascii ($RecvData) . "\n";
print '.'x40 . " OK\n";
# sleep (3);

#-------------------------------------------------------------------------------
print ("Ending transaction:\n");
die ("Can't terminate transaction: $PCSC::errno\n") unless ($hCard->EndTransaction($PCSC::SCARD_LEAVE_CARD));
print '.'x40 . " OK\n";

#-------------------------------------------------------------------------------
print "Disconnecting the card:\n";
$tmpVal = $hCard->Disconnect($PCSC::SCARD_LEAVE_CARD);
die ("Can't disconnect the PCSC object: $PCSC::errno\n") unless $tmpVal;
print '.'x40 . " OK\n";
#-------------------------------------------------------------------------------
print "Closing card object:\n";
$hCard = undef;
print '.'x40 . " OK\n";
#-------------------------------------------------------------------------------
print "Closing context:\n";
$hContext = undef;
#print '.'x40 . " OK\n";

# End of File #

