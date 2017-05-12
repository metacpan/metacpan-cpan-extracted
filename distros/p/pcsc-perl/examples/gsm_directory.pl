#!/usr/bin/perl -w
#
#    This program reads the phone directory of a GSM11.11 SIM card and
#    prints out its contents in a human readable format. It is based on
#    another Perl script from Ludovic ROUSSEAU <ludovic.rousseau@free.fr>
#    That you can obtain at the following URL:
#        http://ludovic.rousseau.free.fr/softwares/SIM-1.0.tar.gz
#
#    Copyright (C) <2001> - Lionel VICTOR <lionel.victor@free.fr>
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
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
#

# $Id: gsm_directory.pl,v 1.5 2001/09/07 14:17:45 lvictor Exp $

# $Log: gsm_directory.pl,v $
# Revision 1.5  2001/09/07 14:17:45  lvictor
# cosmetic chage in the header comment
#
# Revision 1.4  2001/09/06 09:55:25  rousseau
# added CVS Id and Log fields
#

use strict;
use Carp;

use PCSC;
use PCSC::Card;

use Getopt::Std;
use Term::ReadKey;

my %options;

my $hContext = new PCSC();
my $hCard;
my $RecvData;
my $nRecordsLength;
my $PIN;

die ("Could not create PCSC object: $PCSC::errno\n") unless defined $hContext;

sub gsmrecord_to_ascii {
	my $gsmrecord = shift;
	my $out_string = '';
	my $delta = $#$gsmrecord-27;
	my $i;

	if ($$gsmrecord[0] != 0xFF) {
		for $i (0..14+$delta-1) {
			if ($$gsmrecord[$i] != 0xFF) {
				$out_string.=chr($$gsmrecord[$i])
			} else {
				$out_string.=' ';
			}
		}

		my $phone_length = $$gsmrecord[14] - 2;
		if ($phone_length > 0) {
			my $digit;
			$out_string .= '-> ';
			for $i (16+$delta..$#$gsmrecord) {
				$digit = $$gsmrecord[$i]&0x0F;
				$out_string .= sprintf ("%01X", $digit) if ($digit!=0x0F);
				$digit = ($$gsmrecord[$i]&0xF0)>>4;
				$out_string .= sprintf ("%01X", $digit) if ($digit!=0x0F);
			}
		} else {
			$out_string.= "null or invalid phone";
		}
	}

	return $out_string;
}

sub pin_to_array {
	my $pin = shift;
	my @array;

	confess ("PIN code must not exceed 8 bytes.") unless (length $pin <= 8);

	$pin =~ s/(.)/$1 /g;
	@array = split / /, $pin;
	@array = map (ord, @array);

	# Pad the array with 0xFF up to 8 bytes
	while ($#array < 7) { push @array, 0xFF; }

	return @array;
}

getopt ('hvr:', \%options);

if (exists $options{h}) {
	#TODO
	print "TODO: usage -v verbose -r reader -h help";
}

if (exists $options{r}) {
    $hCard = new PCSC::Card ($hContext, $options{r});
    die ("Can't allocate PCSCCard object: $PCSC::errno\n") unless defined $hCard;
    print STDERR "Using given card reader: $options{r}\n" if exists $options{'v'};
} else {
    my @readers_list = $hContext->ListReaders ();
    die ("Can't get readers list: $PCSC::errno\n") unless defined $readers_list[0];
    print STDERR "No reader given: using $readers_list[0]\n" if exists $options{v};
    $hCard = new PCSC::Card ($hContext, $readers_list[0]);
    die ("Can't allocate PCSCCard object: $PCSC::errno\n") unless defined $hCard;
}

# Select MF (3F00)
print STDERR "Selecting Master File (3F00)\n" if exists $options{v};
$RecvData = $hCard->Transmit([0xA0, 0xA4, 0x00, 0x00, 0x02, 0x3F, 0x00]);
die ("Can't communicate: $PCSC::errno\n") unless defined $RecvData;
die ("Can't select MF: SW = [ ".PCSC::array_to_ascii($RecvData)." ]") unless $$RecvData[0] == 0x9F;

# Select DF Telecom (7F10)
print STDERR "Selecting Telecom Directory (3F00/7F10)\n" if exists $options{v};
$RecvData = $hCard->Transmit([0xA0, 0xA4, 0x00, 0x00, 0x02, 0x7F, 0x10]);
die ("Can't communicate: $PCSC::errno\n") unless defined $RecvData;
die ("Can't select DF Telecom: SW = [ ".PCSC::array_to_ascii($RecvData)." ]") unless $$RecvData[0] == 0x9F; 

# Select EF_ADN (6F3A) (Abbreviated Dialing Numbers)
print STDERR "Selecting Abbreviated Dialing Numbers File (3F00/7F10/6F3A)\n" if exists $options{v};
$RecvData = $hCard->Transmit([0xA0, 0xA4, 0x00, 0x00, 0x02, 0x6F, 0x3A]);
die ("Can't communicate: $PCSC::errno\n") unless defined $RecvData;
die ("Can't select EF_ADN: SW = [ ".PCSC::array_to_ascii($RecvData)." ]") unless $$RecvData[0] == 0x9F;

# Get Response (get informations about EF_ADN)
# The last SW gives the length of available bytes:
# 9F xx means there are xx bytes waiting
print STDERR "Getting ADN Records length\n" if exists $options{v};
$nRecordsLength = $$RecvData[1];
$RecvData = $hCard->Transmit([0xA0, 0xC0, 0x00, 0x00, $nRecordsLength]);
die ("Can't communicate: $PCSC::errno\n") unless defined $RecvData;
die ("Can't retrieve records length: SW = [ ".PCSC::array_to_ascii($RecvData)." ]") unless $$RecvData[$nRecordsLength] == 0x90;

# Extract record length from the response
$nRecordsLength = $$RecvData[$nRecordsLength-1];
print STDERR "Records are $nRecordsLength bytes long\n" if exists $options{v};

# Asks the user for his/her PIN code
print STDOUT "Please insert your PIN code:";
ReadMode 'noecho';
$PIN = ReadLine 0;
ReadMode 'normal';
chomp $PIN;
print STDOUT "\n";

# Submitting PIN code to the card
print STDERR "Submitting PIN code\n" if exists $options{v};
$RecvData = $hCard->Transmit([0xA0, 0x20, 0x00, 0x01, 0x08, pin_to_array($PIN)]);
die ("Can't communicate: $PCSC::errno\n") unless defined $RecvData;
die ("Can't access file (wrong PIN code ?): SW = [ ".PCSC::array_to_ascii($RecvData)." ]") unless $$RecvData[0] == 0x90;

# Get phone records
my $i;
my @SW;
print STDERR "Getting records\n" if exists $options{v};
for $i (1..255) {
	$RecvData = $hCard->Transmit([0xA0, 0xB2, $i, 0x04, $nRecordsLength]);
	die ("Can't communicate: $PCSC::errno\n") unless defined $RecvData;

	# pop the status word out of the retrieved bytes
	$SW[1] = pop @$RecvData;
	$SW[0] = pop @$RecvData;

	# Ignore referencing errors (record out of range, file
	# empty, etc...) but die if anything else bad occurs.
	die ("Can't read from EF_ADN: SW = [ ".sprintf ("%02X %02X",$SW[0],$SW[1])." ]\n") if ($SW[0] != 0x94 && $SW[0] != 0x90);

	# Exit if the status word is not 90xx
	last if $SW[0] != 0x90;

	# TODO:remove that it is only debug...
	# TODO: format that and print phone record...
	print "SLOT $i: ".gsmrecord_to_ascii($RecvData)."\n";
	#print "[ ".PCSC::array_to_ascii($RecvData)." ] [".PCSC::array_to_ascii(\@SW)."]\n";
}

print STDERR "Reseting the card\n" if exists $options{v};
$hCard->Disconnect($PCSC::SCARD_RESET);

# End of File

