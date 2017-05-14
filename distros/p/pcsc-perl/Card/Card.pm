###############################################################################
#
#    Authors     : Lionel VICTOR <lionel.victor@unforgettable.com>
#                                <lionel.victor@free.fr>
#                  Ludovic ROUSSEAU <ludovic.rousseau@free.fr>
#    Compiler    : gcc, Visual C++
#    Target      : Unix, Windows
#
#    Description : Perl wrapper to the PCSC API
#    
#    Copyright (C) 2001 - Lionel VICTOR
#                  2003-2008 - Ludovic ROUSSEAU
#
#    This program is free software; you can redistribute it and/or
#    modify it under the terms of the GNU General Public License as
#    published by the Free Software Foundation; either version 2 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
#    02111-1307 USA
#
###############################################################################

# $Id: Card.pm,v 1.24 2008-03-26 17:10:08 rousseau Exp $

package Chipcard::PCSC::Card;

require Chipcard::PCSC;

use warnings;
use Carp;
use strict;

our $VERSION = '0.02';

# Usage:
# $hCard = new Chipcard::PCSC::Card ($hcontext);
# $hCard = new Chipcard::PCSC::Card ($hcontext, $reader_name, $share_mode,
#  $preferred_protocol);
#
# the second version also connect to the supplied reader.
# when no connection has been required, use Connect()
#
# default values:
#  $share_mode = $Chipcard::PCSC::SCARD_SHARE_EXCLUSIVE
#  $preferred_protocol = $Chipcard::PCSC::SCARD_PROTOCOL_T0 | $Chipcard::PCSC::SCARD_PROTOCOL_T1
sub new
{
	my $class = shift;

	my $hContext = shift;
	my $reader_name = shift;
	my $share_mode = shift;
	my $preferred_protocol = shift;

	my $container = {};

	# $hContext is required therefore we check for its value
	return (undef) unless (defined $hContext->{hContext});

	# Keep a handle on the given PCSC context
	$container->{hContext} = $hContext;

	# if the user wants to initiate the connection we call _Connect()
	# for him and return the appropriate error code if required
	if (defined ($reader_name))
	{
		# Apply default values when required
		$share_mode = $Chipcard::PCSC::SCARD_SHARE_EXCLUSIVE unless (defined($share_mode));
		$preferred_protocol = $Chipcard::PCSC::SCARD_PROTOCOL_T0 | $Chipcard::PCSC::SCARD_PROTOCOL_T1 unless (defined ($preferred_protocol));

		($container->{hCard}, $container->{dwProtocol}) = Chipcard::PCSC::_Connect ($hContext->{hContext}, $reader_name, $share_mode, $preferred_protocol);
		return (undef) unless (defined $container->{hCard});
	}

	# At this point, either the connection was successful or the user
	# did not ask for a connection... in any case, we just return our
	# blessed reference
	return bless $container, $class;
} # new

# Usage:
# Connect ($reader_name, $share_mode, $preferred_protocol)
#
# default values:
#  $share_mode = $Chipcard::PCSC::SCARD_SHARE_EXCLUSIVE
#  $preferred_protocol = $Chipcard::PCSC::SCARD_PROTOCOL_T0 | $Chipcard::PCSC::SCARD_PROTOCOL_T1
sub Connect
{
	my $self = shift;
	confess ("wrong type") unless ref $self;

	# The object may be connected already so we check for that case
	if (defined ($self->{hCard}))
	{
		$Chipcard::PCSC::errno = $Chipcard::PCSC::SCARD_P_ALREADY_CONNECTED;
		return (undef);
	}

	# otherwise, we just pop the other parameters
	my $reader_name = shift;
	my $share_mode = shift;
	my $preferred_protocol = shift;

	# $reader_name is required so we check for its value
	return (undef) unless (defined($reader_name));

	# Apply default values when required
	$share_mode = $Chipcard::PCSC::SCARD_SHARE_EXCLUSIVE unless (defined($share_mode));
	$preferred_protocol = $Chipcard::PCSC::SCARD_PROTOCOL_T0 | $Chipcard::PCSC::SCARD_PROTOCOL_T1 unless (defined ($preferred_protocol));

	($self->{hCard}, $self->{dwProtocol}) = Chipcard::PCSC::_Connect ($self->{hContext}{hContext}, $reader_name, $share_mode, $preferred_protocol);

	# We return the current protocole being used or undef if an error
	# occured in this case, $self->{dwProtocol} should be undef
	return $self->{dwProtocol};
} # Connect

# Usage:
# Reconnect ($share_mode, $preferred_protocol, $initialization)
#
# default values:
#  $share_mode = $Chipcard::PCSC::SCARD_SHARE_EXCLUSIVE
#  $preferred_protocol = $Chipcard::PCSC::SCARD_PROTOCOL_T0 | $Chipcard::PCSC::SCARD_PROTOCOL_T1
#  $initialization = $Chipcard::PCSC::SCARD_LEAVE_CARD
sub Reconnect
{
	my $self = shift;
	confess ("wrong type") unless ref $self;

	# check whever we know the card handle or not

	unless (defined ($self->{hCard}))
	{
		$Chipcard::PCSC::errno = $Chipcard::PCSC::SCARD_P_NOT_CONNECTED;
		return (undef);
	}

	my $share_mode = shift;
	my $preferred_protocol = shift;
	my $initialization = shift;

	# Apply default values when required
	$share_mode = $Chipcard::PCSC::SCARD_SHARE_EXCLUSIVE unless (defined($share_mode));
	$preferred_protocol = $Chipcard::PCSC::SCARD_PROTOCOL_T0 | $Chipcard::PCSC::SCARD_PROTOCOL_T1 unless (defined ($preferred_protocol));
	$initialization = $Chipcard::PCSC::SCARD_LEAVE_CARD unless (defined($initialization));

	$self->{dwProtocol} = Chipcard::PCSC::_Reconnect ($self->{hCard}, $share_mode, $preferred_protocol, $initialization);
	return ($self->{dwProtocol});
} # Reconnect

sub Disconnect
{
	my $self = shift;
	confess ("wrong type") unless ref $self;

	# check whever we know the card handle or not
	unless (defined ($self->{hCard}))
	{
		$Chipcard::PCSC::errno = $Chipcard::PCSC::SCARD_P_NOT_CONNECTED;
		return (undef);
	}

	my $disposition = shift;

	# Apply default values when required
	$disposition = $Chipcard::PCSC::SCARD_LEAVE_CARD unless (defined ($disposition));

	my $return_val = Chipcard::PCSC::_Disconnect ($self->{hCard}, $disposition);
	$self->{hCard} = (undef) if ($return_val);

	return $return_val;
} # Disconnect

sub Status
{
	my $self = shift;
	confess ("wrong type") unless ref $self;

	return Chipcard::PCSC::_Status ($self->{hCard});
} # Status

sub Transmit
{
	my $self = shift;
	confess ("wrong type") unless ref $self;

	my $send_data = shift;
	my $trash;
	my $ret;

	confess ("not connected") unless defined $self->{hCard};
	return (undef) unless defined $self->{dwProtocol};

	# the APDU is at least 4 bytes (CLA, INS, P1, P2)
	warn ("Transmit: short APDU ($#$send_data bytes sent)") unless $#$send_data >= 3;
	#TODO:
	# The following warning was supposed to be helpful but it is real
	# pain in the ass... I therefore decided to remove it. I will leave
	# this code for a little time just to make sure it really is useless
	# then I plan to remove it...
#	warn ("Transmit: APDU length does not match P3 (" . ($#$send_data-4) . " instead of $send_data->[4])") unless $send_data->[4] == $#$send_data-4;

	($trash, $ret) = Chipcard::PCSC::_Transmit ($self->{hCard}, $self->{dwProtocol}, $send_data);

	return $ret if (defined($ret));

	# else error
	return (undef)
} # Transmit

sub Control
{
	my $self = shift;
	confess ("wrong type") unless ref $self;

	my $controlcode = shift;
	my $send_data = shift;

	confess ("not connected") unless defined $self->{hCard};

	return Chipcard::PCSC::_Control ($self->{hCard}, $controlcode, $send_data);
} # Control

sub BeginTransaction
{
	my $self = shift;
	confess ("wrong type") unless ref $self;

	unless (defined ($self->{hCard}))
	{
		$Chipcard::PCSC::errno = $Chipcard::PCSC::SCARD_P_NOT_CONNECTED;
		return (0);
	}

	return Chipcard::PCSC::_BeginTransaction ($self->{hCard});
} # BeginTransaction

sub EndTransaction
{
	my $self = shift;
	confess ("wrong type") unless ref $self;

	unless (defined ($self->{hCard})) {
		$Chipcard::PCSC::errno = $Chipcard::PCSC::SCARD_P_NOT_CONNECTED;
		return (0);
	}

	my $disposition = shift;

#	print "we got dispo = $disposition\n";
	# Apply default values when required
	$disposition = $Chipcard::PCSC::SCARD_LEAVE_CARD unless (defined ($disposition));

	return Chipcard::PCSC::_EndTransaction ($self->{hCard}, $disposition);
} # EndTransaction

sub DESTROY
{
	my $self = shift;
	confess ("wrong type") unless ref $self;

 	$self->Disconnect ();
	if (defined ($self->{hCard}))
	{
		warn ("PCSCCard object $self deleted but still connected");
	}
} # DESTROY

# Usage:
# $text = ISO7816Error($sw)
#
# return the text version of the ISO 7816-4 error given in $sw
sub ISO7816Error($)
{
	my $sw = shift;

	# default error message
	my $text = "Error not defined by ISO 7816";

	return "wrong SW size for: $sw" unless (length($sw) == 5);

	# split the two error bytes
	my ($sw1, $sw2) = split / /, $sw;

	$text = "Normal processing." if ($sw =~ m/90 00/);
	$text = "0x$sw2 bytes of response still available." if ($sw1 =~ m/61/);
	if ($sw1 =~ m/62/)
	{
		$text = "State of non-volatile memory unchanged. ";
		$text .= "No information given." if ($sw2 =~ m/00/);
		$text .= "Part of returned data my be corrupted." if ($sw2 =~ m/81/);
		$text .= "End of file/record reached before reading Le bytes." if ($sw2 =~ m/82/);
		$text .= "Selected file invalidated." if ($sw2 =~ m/83/);
		$text .= "FCI not formated according to 5.1.5." if ($sw2 =~ m/84/);
	}

	if ($sw1 =~ m/63/)
	{
		$text = "State of non-volatile memory changed. ";
		$text .= "No information given." if ($sw2 =~ m/00/);
		$text .= "File filled up by the last write." if ($sw2 =~ m/81/);
		$text .= "Counter: 0x" . substr($sw2, 1, 1) if ($sw2 =~ m/^C/);
	}

	$text = "State of non-volatile memory unchanged." if ($sw =~ m/64 00/);

	if ($sw1 =~ m/65/)
	{
		$text = "State of non-volatile memory changed. ";
		$text .= "Memory failure." if ($sw2 =~ m/81/);
	}

	$text = "Reserved for security-related issues." if ($sw1 =~ m/66/);
	$text = "Wrong length." if ($sw =~ m/67 00/);

	if ($sw1 =~ m/68/)
	{
		$text = "Functions in CLA not supported. ";
		$text .= "Logical channel not supported." if ($sw2 =~ m/81/);
		$text .= "Secure messaging not supported." if ($sw2 =~ m/82/);
	}

	if ($sw1 =~ m/69/)
	{
		$text = "Command not allowed. ";
		$text .= "Command incompatible with file structure." if ($sw2 =~ m/81/);
		$text .= "Security status not satisfied." if ($sw2 =~ m/82/);
		$text .= "Authentication method blocked." if ($sw2 =~ m/83/);
		$text .= "Referenced data invalidated." if ($sw2 =~ m/84/);
		$text .= "Conditions of use not satisfied." if ($sw2 =~ m/85/);
		$text .= "Command not allowed (no current EF)." if ($sw2 =~ m/86/);
		$text .= "Expected SM data objects missing." if ($sw2 =~ m/87/);
		$text .= "SM data objects incorrect." if ($sw2 =~ m/88/);
	}

	if ($sw1 =~ m/6A/)
	{
		$text = "Wrong parameter(s) P1-P2. ";
		$text .= "Incorrect parameters in the data field." if ($sw2 =~ m/80/);
		$text .= "Function not supported." if ($sw2 =~ m/81/);
		$text .= "File not found." if ($sw2 =~ m/82/);
		$text .= "Record not found." if ($sw2 =~ m/83/);
		$text .= "Not enough memory space in the file." if ($sw2 =~ m/84/);
		$text .= "Lc inconsistent with TLV structure." if ($sw2 =~ m/85/);
		$text .= "Incorrect parameters P1-P2." if ($sw2 =~ m/86/);
		$text .= "Lc inconsistent with P1-P2." if ($sw2 =~ m/87/);
		$text .= "Referenced data not found." if ($sw2 =~ m/88/);
	}

	$text = "Wrong parameter(s) P1-P2." if ($sw =~ m/6B 00/);
	$text = "Wrong length Le: should be 0x$sw2" if ($sw1 =~ m/6C/);
	$text = "Instruction code not supported or invalid." if ($sw =~ m/6D 00/);
	$text = "Class not supported." if ($sw =~ m/6E 00/);
	$text = "No precise diagnosis." if ($sw =~ m/6F 00/);

	return $text;
} # ISO7816Error

$Chipcard::PCSC::Card::Error = "";

# Usage:
# ($sw, $res) = TransmitWithCheck($apdu, $sw_expected);
# die "Error: $Chipcard::PCSC::Card::Error\n" unless defined $sw;
#
# With debug
# ($sw, $res) = TransmitWithCheck($apdu, $sw_expected, 1);
# die "Error: $Chipcard::PCSC::Card::Error\n" unless defined $sw;
#
# Example:
# ($sw, $res) = TransmitWithCheck("00 A4 01 00 02 01 00", "90 [10]0");
sub TransmitWithCheck
{
	my $self = shift;
	confess ("wrong type") unless ref $self;

	my $command = shift;
	my $sw_expected = shift;
	my $debug = shift;

	my ($send, $recv, $data, $sw);

	# add needed spaces
	$command =~ s/(..)/$1 /g if ($command !~ m/ /);
	print "=> $command\n" if (defined $debug);

	# Convert $command in a reference to an array
	$send = Chipcard::PCSC::ascii_to_array($command);

	# send the APDU
	$recv = $self -> Transmit($send);
	if (! defined $recv)
	{
	 	$Chipcard::PCSC::Card::Error = "Can't transmit data: $Chipcard::PCSC::errno";
		return undef;
	}

	$data = Chipcard::PCSC::array_to_ascii($recv);
	print "<= $data\n" if defined $debug;

	# Status word
	$sw = substr $data, length ($data) -5, 5, "";

	print "SW: $sw (" . &Chipcard::PCSC::Card::ISO7816Error($sw) . ")\n" if defined $debug;

	if ($sw !~ m/$sw_expected/)
	{
		#$sw = PCSC::ISO7816_ErrorStr($sw);
		$Chipcard::PCSC::Card::Error = "ERROR: expected $sw_expected and got $sw\n";
		return undef;
	}

	# normal execution and no error
	return ($sw, $data);
} # TransmitWithCheck

1;

