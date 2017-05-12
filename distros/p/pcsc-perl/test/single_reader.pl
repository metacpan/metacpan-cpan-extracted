#!/usr/bin/perl -w

#    single_reader.pl: test the pcsc Perl wrapper with one reader
#    copyright (c) 2001   Lionel Victor
#
#    this program is free software; you can redistribute it and/or modify
#    it under the terms of the gnu general public license as published by
#    the free software foundation; either version 2 of the license, or
#    (at your option) any later version.
#
#    this program is distributed in the hope that it will be useful,
#    but without any warranty; without even the implied warranty of
#    merchantability or fitness for a particular purpose.  see the
#    gnu general public license for more details.
#
#    you should have received a copy of the gnu general public license
#    along with this program; if not, write to the free software
#    foundation, inc., 59 temple place, suite 330, boston, ma  02111-1307  usa

# $Id: single_reader.pl,v 1.6 2001/09/05 07:58:41 rousseau Exp $

# $Log: single_reader.pl,v $
# Revision 1.6  2001/09/05 07:58:41  rousseau
# Added -w flag to #!/usr/bin/perl and corrected some warnings
#
# Revision 1.5  2001/09/05 07:55:49  rousseau
# Added CVS Id and Log fields
# Added GPL licence
#

use ExtUtils::testlib;
use PCSC;
use PCSC::Card;

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
print "Disconnecting the card:\n";
$hCard->Disconnect($PCSC::SCARD_LEAVE_CARD);
undef $hCard;
print '.'x40 . " OK\n";
#-------------------------------------------------------------------------------
print "Closing context:\n";
$hContext = undef;
print '.'x40 . " OK\n";

# End of File #
