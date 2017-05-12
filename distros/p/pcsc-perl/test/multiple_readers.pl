#!/usr/bin/perl -w

#    multiple_readers.pl: test the pcsc Perl wrapper with TWO readers
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

# $Id: multiple_readers.pl,v 1.7 2001/09/05 07:56:51 rousseau Exp $

# $Log: multiple_readers.pl,v $
# Revision 1.7  2001/09/05 07:56:51  rousseau
# Added title and author name in the GPL licence
#
# Revision 1.6  2001/09/05 07:53:54  rousseau
# Added -w flag to /usr/bin/perl and corrected some warnings
#
# Revision 1.5  2001/09/05 07:43:38  rousseau
# Added CVS Id and Log fields
# Added GPL licence
#

use ExtUtils::testlib;
use PCSC;
#use PCSCpipo;

use strict;

#my $current_protocol;
#my @StatusResult;

my $hContext;
my @ReadersList;

my $hCard;
my @StatusResult;
my $tmpVal;
my $SendData;
my $RecvData;

my $hCard2;
my @StatusResult2;
my $tmpVal2;
my $SendData2;
my $RecvData2;

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
$hCard = new PCSC::Card ($hContext, $ReadersList[0]);
die ("Can't connect to the reader '$ReadersList[0]': $PCSC::errno\n") unless (defined($hCard));
print '.'x40 . " OK\n";

#-------------------------------------------------------------------------------
print "Connecting to the card2:\n";
$hCard2 = new PCSC::Card ($hContext, $ReadersList[1]);
die ("Can't connect to the reader '$ReadersList[1]': $PCSC::errno\n") unless (defined($hCard2));
print '.'x40 . " OK\n";

# sleep (3);

#-------------------------------------------------------------------------------
if ($hCard->{dwProtocol}!=$PCSC::SCARD_PROTOCOL_T0 &&
    $hCard->{dwProtocol}!=$PCSC::SCARD_PROTOCOL_T1 &&
	$hCard->{dwProtocol}!=$PCSC::SCARD_PROTOCOL_RAW)
{
	print "Don't understand the active protocol, reconnecting to the card:\n";

	my $active_protocol = $hCard->Reconnect($PCSC::SCARD_SHARE_EXCLUSIVE,
	                                        $PCSC::SCARD_PROTOCOL_T1,
											$PCSC::SCARD_RESET_CARD);

	die ("Failed to reconnect to '$ReadersList[0]': $PCSC::errno\n") unless (defined($active_protocol));

	if ($hCard->{dwProtocol}!=$PCSC::SCARD_PROTOCOL_T0 &&
    	$hCard->{dwProtocol}!=$PCSC::SCARD_PROTOCOL_T1 &&
		$hCard->{dwProtocol}!=$PCSC::SCARD_PROTOCOL_RAW)
	{
		print "here is '$hCard->{dwProtocol}'";
		die ("Still don't understand the active current protocol: the card may be mute.\n");
	} else {
		print '.'x40 . " OK\n";
	}
}

#-------------------------------------------------------------------------------
print "Getting Status:\n";
@StatusResult = $hCard->Status ();
die ("Can't get card status: $PCSC::errno\n") unless (defined ($StatusResult[0]));

printf "  ReaderName = %s\n  Status = %X\n  Protocol =  %X\n  ATR = ",
	$StatusResult[0], $StatusResult[1], $StatusResult[2];

foreach $tmpVal (@{$StatusResult[3]}) {
	printf ("%02X ", $tmpVal);
} print "\n";
print '.'x40 . " OK\n";

#-------------------------------------------------------------------------------
print ("Exchanging data:\n");
$SendData = [0x00,0xA4,0x01,0x00, 0x02, 0x10, 0x00];
$RecvData = $hCard->Transmit($SendData);
die ("Can't transmit data: $PCSC::errno") unless (defined ($RecvData));

print "  Send = ";
foreach $tmpVal (@{$SendData}) {
	printf ("%02X ", $tmpVal);
} print "\n";

print "  Recv = ";
foreach $tmpVal (@{$RecvData}) {
	printf ("%02X ", $tmpVal);
} print "\n";
print '.'x40 . " OK\n";
# sleep (3);

#-------------------------------------------------------------------------------
if ($hCard2->{dwProtocol}!=$PCSC::SCARD_PROTOCOL_T0 &&
    $hCard2->{dwProtocol}!=$PCSC::SCARD_PROTOCOL_T1 &&
	$hCard2->{dwProtocol}!=$PCSC::SCARD_PROTOCOL_RAW)
{
	print "Don't understand the active protocol, reconnecting to the card:\n";

	my $active_protocol = $hCard2->Reconnect($PCSC::SCARD_SHARE_EXCLUSIVE,
	                                        $PCSC::SCARD_PROTOCOL_T1,
											$PCSC::SCARD_RESET_CARD);

	die ("Failed to reconnect to '$ReadersList[1]': $PCSC::errno\n") unless (defined($active_protocol));

	if ($hCard2->{dwProtocol}!=$PCSC::SCARD_PROTOCOL_T0 &&
    	$hCard2->{dwProtocol}!=$PCSC::SCARD_PROTOCOL_T1 &&
		$hCard2->{dwProtocol}!=$PCSC::SCARD_PROTOCOL_RAW)
	{
		print "here is '$hCard2->{dwProtocol}'";
		die ("Still don't understand the active current protocol: the card may be mute.\n");
	} else {
		print '.'x40 . " OK\n";
	}
}

#-------------------------------------------------------------------------------
print "Getting Status:\n";
@StatusResult = $hCard2->Status ();
die ("Can't get card status: $PCSC::errno\n") unless (defined ($StatusResult[0]));

printf "  ReaderName = %s\n  Status = %X\n  Protocol =  %X\n  ATR = ",
	$StatusResult[0], $StatusResult[1], $StatusResult[2];
foreach $tmpVal (@{$StatusResult[3]}) {
	printf ("%02X ", $tmpVal);
} print "\n";
print '.'x40 . " OK\n";

#-------------------------------------------------------------------------------
print ("Exchanging data:\n");
$SendData = [0x00,0xA4,0x00,0x00, 0x02, 0x10, 0x00];
$RecvData = $hCard2->Transmit($SendData);
die ("Can't transmit data: $PCSC::errno") unless (defined ($RecvData));

print "  Send = ";
foreach $tmpVal (@{$SendData}) {
	printf ("%02X ", $tmpVal);
} print "\n";

print "  Recv = ";
foreach $tmpVal (@{$RecvData}) {
	printf ("%02X ", $tmpVal);
} print "\n";
print '.'x40 . " OK\n";

#-------------------------------------------------------------------------------
print "Disconnecting the card:\n";
$hCard->Disconnect($PCSC::SCARD_LEAVE_CARD);
undef $hCard;
print '.'x40 . " OK\n";
#-------------------------------------------------------------------------------
print "Disconnecting the card:\n";
$hCard2->Disconnect($PCSC::SCARD_LEAVE_CARD);
undef $hCard2;
print '.'x40 . " OK\n";
#die ("") unless ($hCard->Disconnect ($PCSC::SCARD_UNPOWER_CARD));

#-------------------------------------------------------------------------------
print "Closing context:\n";
$hContext = undef;
print '.'x40 . " OK\n";

# End of File #

