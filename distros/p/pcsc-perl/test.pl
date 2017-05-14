#!/usr/bin/perl

#    test.pl: simple sample program to test the PCSC Perl wrapper
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

# $Id: test.pl,v 1.15 2011/03/06 15:51:42 rousseau Exp $

use Test::More;
use Chipcard::PCSC;
use Chipcard::PCSC::Card;

plan 'no_plan';

use warnings;
use strict;

my $hContext;
my @ReadersList;

my $hCard;
my @StatusResult;
my $tmpVal;
my $SendData;
my $RecvData;
my $sw;

#--------------------------------------------------------------------------
diag("Getting context:");
$hContext = new Chipcard::PCSC();
die ("Can't create the pcsc object: $Chipcard::PCSC::errno\n") unless (defined $hContext);
ok(defined $hContext, "new Chipcard::PCSC()");

#--------------------------------------------------------------------------
diag("Retrieving readers'list:");
@ReadersList = $hContext->ListReaders ();
die ("Can't get readers' list: $Chipcard::PCSC::errno\n") unless (defined($ReadersList[0]));
$, = "\n  ";
$" = "\n  ";
ok(defined($ReadersList[0]), "\$hContext->ListReaders ()");
diag(@ReadersList);

#--------------------------------------------------------------------------
diag("Getting status change:");
my (@readers_states, $reader_state, $timeout, $event_state);
# create the list or readers to watch
map { push @readers_states, ({'reader_name'=>"$_"}) } @ReadersList;

@StatusResult = $hContext->GetStatusChange(\@readers_states);

for my $i (0..$#readers_states)
{
	diag("reader: " . $readers_states[$i]{'reader_name'});
	diag("  ATR: " . Chipcard::PCSC::array_to_ascii($readers_states[$i]{'ATR'}))
		if (defined $readers_states[$i]{'ATR'});
	diag("  state:");
	$event_state = $readers_states[$i]{'event_state'};
	diag("    state changed")
		if ($event_state & $Chipcard::PCSC::SCARD_STATE_CHANGED);
	diag("    card present")
		if ($event_state & $Chipcard::PCSC::SCARD_STATE_PRESENT);
	diag("    card absent")
		if ($event_state & $Chipcard::PCSC::SCARD_STATE_EMPTY);
	diag("    card mute")
		if ($event_state & $Chipcard::PCSC::SCARD_STATE_MUTE);

	$readers_states[$i]{'current_state'} = $event_state;
}

if (! ($readers_states[0]{'event_state'} &
		$Chipcard::PCSC::SCARD_STATE_PRESENT))
{
	$timeout = 10 * 1000;	# 10 seconds
	diag("Insert a card in the first reader please (timeout in $timeout ms)");
	@StatusResult = $hContext->GetStatusChange(\@readers_states, $timeout);
}

#--------------------------------------------------------------------------
diag("Connecting to the card:");
$hCard = new Chipcard::PCSC::Card ($hContext);
die ("Can't create the reader object: $Chipcard::PCSC::errno\n") unless (defined($hCard));

$tmpVal = $hCard->Connect($ReadersList[0], $Chipcard::PCSC::SCARD_SHARE_SHARED);
unless ($tmpVal) {
	# Try to reconnect and reset if connect fails
	diag("Connect failed: trying to reset the card:");
	$tmpVal = $hCard->Reconnect ($Chipcard::PCSC::SCARD_SHARE_SHARED, $Chipcard::PCSC::SCARD_PROTOCOL_T0, $Chipcard::PCSC::SCARD_RESET_CARD);
	die ("Can't reconnect to the reader '$ReadersList[0]': $Chipcard::PCSC::errno\n") unless ($tmpVal);
}
ok($hCard->{dwProtocol}==$Chipcard::PCSC::SCARD_PROTOCOL_T0 ||
	$hCard->{dwProtocol}==$Chipcard::PCSC::SCARD_PROTOCOL_T1 ||
	$hCard->{dwProtocol}==$Chipcard::PCSC::SCARD_PROTOCOL_RAW,
	"Can understand the current protocol: $hCard->{dwProtocol}");

#--------------------------------------------------------------------------
diag("Getting status:");
@StatusResult = $hCard->Status();
die ("Can't get status: $Chipcard::PCSC::errno\n") unless ($StatusResult[0]);
diag("Reader name is $StatusResult[0]");
diag("State: $StatusResult[1]");
diag("Current protocol: $StatusResult[2]");
diag("ATR: " . Chipcard::PCSC::array_to_ascii ($StatusResult[3]));

#--------------------------------------------------------------------------
diag("Initiating transaction:");
die ("Can't initiate transaction: $Chipcard::PCSC::errno\n") unless ($hCard->BeginTransaction());
diag($hCard->BeginTransaction(), "\$hCard->BeginTransaction()");

#--------------------------------------------------------------------------
diag("Exchanging data:");
$SendData = Chipcard::PCSC::ascii_to_array ("00 A4 01 00 02 01 00");
$RecvData = $hCard->Transmit($SendData);
die ("Can't transmit data: $Chipcard::PCSC::errno") unless (defined ($RecvData));

diag("  Send -> " . Chipcard::PCSC::array_to_ascii ($SendData));
diag("  Recv <- " . Chipcard::PCSC::array_to_ascii ($RecvData));

#--------------------------------------------------------------------------
diag("TransmitWithCheck:");
$SendData = "00 A4 00 00 02 3F 00";	# select DF 3F 00
# wait for ".. .." since we the SW will depend on the inserted card
($sw, $RecvData) = $hCard->TransmitWithCheck($SendData, ".. ..", 1);
warn "TransmitWithCheck: $Chipcard::PCSC::Card::Error" unless defined $sw;
ok(defined $sw, "\$hCard->TransmitWithCheck");

diag("  Send -> $SendData");
diag("  Recv <- $RecvData (SW: $sw)");

#--------------------------------------------------------------------------
diag("ISO7816Error:");
diag("$sw: " . &Chipcard::PCSC::Card::ISO7816Error($sw));

#--------------------------------------------------------------------------
# This test is commented since it is reader/driver specific and may do bad
# things for another reader. Reader your reader and driver
# specifications to know what data to use.
#
#diag("Control");
#$SendData = Chipcard::PCSC::ascii_to_array ("02");
#$RecvData = $hCard->Control(0x42000001, $SendData);
#die ("Can't Control data: $Chipcard::PCSC::errno") unless (defined ($RecvData));
#
#diag("  Send -> " . Chipcard::PCSC::array_to_ascii ($SendData));
#diag("  Recv <- " . Chipcard::PCSC::array_to_ascii ($RecvData));

#--------------------------------------------------------------------------
diag("Ending transaction:");
die ("Can't terminate transaction: $Chipcard::PCSC::errno\n") unless ($hCard->EndTransaction($Chipcard::PCSC::SCARD_LEAVE_CARD));
ok($hCard->EndTransaction($Chipcard::PCSC::SCARD_LEAVE_CARD),
	"\$hCard->EndTransaction($Chipcard::PCSC::SCARD_LEAVE_CARD)");

#--------------------------------------------------------------------------
diag("Disconnecting the card:");
$tmpVal = $hCard->Disconnect($Chipcard::PCSC::SCARD_LEAVE_CARD);
die ("Can't disconnect the Chipcard::PCSC object: $Chipcard::PCSC::errno\n") unless $tmpVal;
ok($tmpVal, "\$hCard->Disconnect");

#--------------------------------------------------------------------------
diag("Closing card object:");
$hCard = undef;

#--------------------------------------------------------------------------
diag("Closing context:");
$hContext = undef;

# End of File #

