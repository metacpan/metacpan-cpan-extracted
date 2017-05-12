#!/usr/bin/perl -w

###############################################################################
#    Author      : Lionel VICTOR <lionel.victor@unforgettable.com>
#                                <lionel.victor@free.fr>
#    Compiler    : gcc, Visual C++
#    Target      : unix, Windows
#
#    Description : Perl wrapper to the PCSC API
#    
#    Copyright (C) 2001 - Lionel VICTOR
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
###############################################################################
# $Id: Card.pm,v 1.4 2001/09/05 14:46:15 lvictor Exp $
# $Log: Card.pm,v $
# Revision 1.4  2001/09/05 14:46:15  lvictor
# Do not warn anymore when P3(len) is not related to the number of bytes
# to be transmitted after the APDU
#
# Revision 1.3  2001/09/04 08:11:14  lvictor
# Applied a patch from somebody who apparently wants to stay anonymous.
# This patch includes mostly cosmetic changes and extra documentation about
# array_to_ascii() and ascii_to_array(). Thanks to this contributor for his
# help and time
#
# Revision 1.2  2001/05/31 13:21:06  rousseau
# added hash-bang
#
# Revision 1.1.1.1  2001/05/31 10:00:30  lvictor
# Initial import
#
#

package PCSC::Card;

require PCSC;

use Carp;
use strict;

$VERSION = '1.0.8';

# Usage:
# $hCard = new PCSCCard ($hcontext);
# $hCard = new PCSCCard ($hcontext, $reader_name, $share_mode, $prefered_protocol);
#
# the second version also connect to the supplied reader.
# when no connection has been required, use Connect()
#
# default values:
# $share_mode = $PCSC::SCARD_SHARE_EXCLUSIVE
# $prefered_protocol = $PCSC::SCARD_PROTOCOL_T0
sub new {
	my $class = shift;

	my $hContext = shift;
	my $reader_name = shift;
	my $share_mode = shift;
	my $prefered_protocol = shift;

	my $container = {};

	# $hContext is required therefore we check for its value
	return (undef) unless (defined $hContext->{hContext});

	# Keep a handle on the given PCSC context
	$container->{hContext} = $hContext;

	# if the user wants to initiate the connection we call _Connect()
	# for him and return the appropriate error code if required
	if (defined ($reader_name)) {
		# Apply default values when required
		$share_mode = $PCSC::SCARD_SHARE_EXCLUSIVE unless (defined($share_mode));
		$prefered_protocol = $PCSC::SCARD_PROTOCOL_T0 unless (defined ($prefered_protocol));

		($container->{hCard}, $container->{dwProtocol}) = PCSC::_Connect ($hContext->{hContext}, $reader_name, $share_mode, $prefered_protocol);
		return (undef) unless (defined $container->{hCard});
	}
	# At this point, either the connection was successful or the user
	# did not ask for a connection... in any case, we just return our
	# blessed reference
	return bless $container, $class;
}

# Usage:
# Connect ($reader_name, $share_mode, $prefered_protocol)
#
# defult values:
# $share_mode = $PCSC::SCARD_SHARE_EXCLUSIVE
# $prefered_protocol = $PCSC::SCARD_PROTOCOL_T0
sub Connect {
	my $self = shift;
	confess ("wrong type") unless ref $self;

	# The object may be connected already so we check for that case
	if (defined ($self->{hCard})) {
		$PCSC::errno = $PCSC::SCARD_P_ALREADY_CONNECTED;
		return (undef);
	}

	# otherwise, we just pop the other parameters
	my $reader_name = shift;
	my $share_mode = shift;
	my $prefered_protocol = shift;

	# $reader_name is required so we check for its value
	return (undef) unless (defined($reader_name));

	# Apply default values when required
	$share_mode = $PCSC::SCARD_SHARE_EXCLUSIVE unless (defined($share_mode));
	$prefered_protocol = $PCSC::SCARD_PROTOCOL_T0 unless (defined ($prefered_protocol));

	($self->{hCard}, $self->{dwProtocol}) = PCSC::_Connect ($self->{hContext}{hContext}, $reader_name, $share_mode, $prefered_protocol);

	# We return the current protocole being used or undef if an error
	# occured in this case, $self->{dwProtocol} should be undef
	return $self->{dwProtocol};
}

# Usage:
# Reconnect ($share_mode, $prefered_protocol, $initialization)
#
# default values:
# $share_mode = $PCSC::SCARD_SHARE_EXCLUSIVE
# $prefered_protocol = $PCSC::SCARD_PROTOCOL_T0
# $initialization = $PCSC::SCARD_LEAVE_CARD
sub Reconnect {
	my $self = shift;
	confess ("wrong type") unless ref $self;

	# check whever we know the card handle or not

	unless (defined ($self->{hCard})) {
		$PCSC::errno = $PCSC::SCARD_P_NOT_CONNECTED;
		return (undef);
	}

	my $share_mode = shift;
	my $prefered_protocol = shift;
	my $initialization = shift;

	# Apply default values when required
	$share_mode = $PCSC::SCARD_SHARE_EXCLUSIVE unless (defined($share_mode));
	$prefered_protocol = $PCSC::SCARD_PROTOCOL_T0 unless (defined ($prefered_protocol));
	$initialization = $PCSC::SCARD_LEAVE_CARD unless (defined($initialization));

	$self->{dwProtocol} = PCSC::_Reconnect ($self->{hCard}, $share_mode, $prefered_protocol, $initialization);
	return ($self->{dwProtocol});
}

sub Disconnect {
	my $self = shift;
	confess ("wrong type") unless ref $self;

	# check whever we know the card handle or not
	unless (defined ($self->{hCard})) {
		$PCSC::errno = $PCSC::SCARD_P_NOT_CONNECTED;
		return (undef);
	}

	my $disposition = shift;

	# Apply default values when required
	$disposition = $PCSC::SCARD_LEAVE_CARD unless (defined ($disposition));

	my $return_val = PCSC::_Disconnect ($self->{hCard}, $disposition);
	$self->{hCard} = (undef) if ($return_val);

	return $return_val;
}

sub Status {
	my $self = shift;
	confess ("wrong type") unless ref $self;

	return PCSC::_Status ($self->{hCard});
}

sub Transmit {
	my $self = shift;
	confess ("wrong type") unless ref $self;

	my $send_data = shift;
	my $trash;
	my $ret;

	confess ("not connected") unless defined $self->{hCard};

	warn ("Transmit: short APDU ($#$send_data bytes sent)") unless $#$send_data > 3;
	#TODO:
	# The following warning was supposed to be helpful but it is real
	# pain in the ass... I therefore decided to remove it. I will leave
	# this code for a little time just to make sure it really is useless
	# then I plan to remove it...
#	warn ("Transmit: APDU length does not match P3 (" . ($#$send_data-4) . " instead of $send_data->[4])") unless $send_data->[4] == $#$send_data-4;

	($trash, $ret) = PCSC::_Transmit ($self->{hCard}, $self->{dwProtocol}, $send_data);

	if (defined($ret)) {
		return $ret;
	} else {
		return (undef)
	}
}

sub BeginTransaction {
	my $self = shift;
	confess ("wrong type") unless ref $self;

	unless (defined ($self->{hCard})) {
		$PCSC::errno = $PCSC::SCARD_P_NOT_CONNECTED;
		return (0);
	}

	return PCSC::_BeginTransaction ($self->{hCard});
}

sub EndTransaction {
	my $self = shift;
	confess ("wrong type") unless ref $self;

	unless (defined ($self->{hCard})) {
		$PCSC::errno = $PCSC::SCARD_P_NOT_CONNECTED;
		return (0);
	}

	my $disposition = shift;

#	print "we got dispo = $disposition\n";
	# Apply default values when required
	$disposition = $PCSC::SCARD_LEAVE_CARD unless (defined ($disposition));

	return PCSC::_EndTransaction ($self->{hCard}, $disposition);
}

sub DESTROY {
	my $self = shift;
	confess ("wrong type") unless ref $self;

 	$self->Disconnect ();
	if (defined ($self->{hCard})) {
		warn ("PCSCCard object $self deleted but still connected");
	}
}

1;

