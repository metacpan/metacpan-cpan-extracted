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
###############################################################################
# $Id: PCSC.pm,v 1.6 2001/10/10 13:12:31 lvictor Exp $
# $Log: PCSC.pm,v $
# Revision 1.6  2001/10/10 13:12:31  lvictor
# Added fake variable declarations/initialization to work with make test
#
# Revision 1.5  2001/09/04 14:49:49  lvictor
# tried to make the @EXPORT @ISA $VERSION variable use more standard (At
# least I hope so)
#
# Revision 1.4  2001/09/04 13:59:18  lvictor
# Fixed a bug in PCSC::ascii_to_array(). The returned array was global
# therefore, each call to the function was returning all the arrays since
# the object initialization.
# I now use 'use strict' to avoid such problems in the future but I do not
# know if I do it the proper way... I had to modify EXPORT and such to make
# it run
#
# Revision 1.3  2001/09/04 08:11:03  lvictor
# Applied a patch from somebody who apparently wants to stay anonymous.
# This patch includes mostly cosmetic changes and extra documentation about
# array_to_ascii() and ascii_to_array(). Thanks to this contributor for his
# help and time
#
# Revision 1.2  2001/05/31 13:21:03  rousseau
# added hash-bang
#
# Revision 1.1.1.1  2001/05/31 10:00:30  lvictor
# Initial import
#
#

package PCSC;

require PCSC::Card;
require Exporter;
require DynaLoader;

use strict;
use Carp;

use vars       qw($VERSION @ISA @EXPORT);

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default.
# Note: do not export
# names by default without a very good reason. Use
# EXPORT_OK instead.
# Do not simply export all your public
# functions/methods/constants.
@EXPORT = qw(

);
$VERSION = '1.0.8';

bootstrap PCSC $VERSION;

# Preloaded methods go here.

# We start with some basic conversion function here. They are global to
# the package and should not be used through an object instance
sub array_to_ascii {
	my $byte_array_ref = shift;

	confess ("wrong type") unless ref ($byte_array_ref);
	confess ('usage PCSC::array_to_ascii($string)') unless defined @{$byte_array_ref};

	my $return_string;
	my $tmpVal;

	# format the string with the array's contents
	foreach $tmpVal (@{$byte_array_ref}) {
		$return_string .= sprintf ("%02X ", $tmpVal);
	};

	# remove the trailing space or do nothing if the string is empty
	chop $return_string;
	return $return_string;
}

sub ascii_to_array {
	my $ascii_string = shift;
	my @return_array;
	my $tmpVal;

	confess ('usage PCSC::ascii_to_array($string)') unless defined $ascii_string;

	foreach $tmpVal (split / /, $ascii_string) {
		croak ("ascii_to_array: wrong value ($tmpVal)") unless $tmpVal =~ /[0-9a-fA-F][0-9a-fA-F]*/;
		push @return_array, hex ($tmpVal);
	}

	# return a reference to the constructed array
	return \@return_array;
}

# Usage:
# $my_var = new PCSC ($scope, $remote_host);
#
# default values:
# $scope = $PCSC::SCARD_SCOPE_SYSTEM
# $remote_host = 0 (localhost)
sub new ($scope) {
	my $class = shift;

	my $scope = shift;
	my $remote_host = shift;
	my $container = {};

	# Apply default values when required
	$scope = $PCSC::SCARD_SCOPE_SYSTEM unless (defined ($scope));
	$remote_host = 0 unless (defined ($remote_host));

	$container->{hContext} = _EstablishContext ($scope, $remote_host, 0);

	return undef unless (defined($container->{hContext}));
	return bless $container, $class;
}

sub ListReaders {
	my $self = shift;
	confess ("wrong type") unless ref $self;

	my $group = shift;
	# group is null if not given
#	$group = 0 unless (defined ($group));

	return _ListReaders ($self->{hContext}, $group);
}

sub SetTimeout {
	my $self = shift;
	confess ("wrong type") unless ref $self;

	my $timeout = shift;
	# Defult time out is 30 seconds
	$timeout = 30 unless (defined $timeout);

	return _SetTimeout ($self->{hContext}, $timeout);
}

sub DESTROY {
	my $self = shift;
	confess ("wrong type") unless ref $self;

	# Release PCSC context when the object is about to be destroyed
	my $return_val = _ReleaseContext ($self->{hContext});

	# die in case of an error
	confess ("Can't release context $self->{hContext}: $!") unless (defined ($return_val));
}

# Autoload methods go after __END__, and are processed by
# the autosplit program.

$PCSC::SCARD_STATE_ATRMATCH        = 0;
$PCSC::SCARD_POWERED               = 0;
$PCSC::SCARD_E_INVALID_HANDLE      = 0;
$PCSC::SCARD_SCOPE_USER            = 0;
$PCSC::SCARD_W_UNSUPPORTED_CARD    = 0;
$PCSC::SCARD_E_NO_MEMORY           = 0;
$PCSC::SCARD_ABSENT                = 0;
$PCSC::SCARD_E_NOT_TRANSACTED      = 0;
$PCSC::SCARD_F_UNKNOWN_ERROR       = 0;
$PCSC::SCARD_INSERTED              = 0;
$PCSC::SCARD_W_UNRESPONSIVE_CARD   = 0;
$PCSC::SCARD_PRESENT               = 0;
$PCSC::SCARD_E_SHARING_VIOLATION   = 0;
$PCSC::SCARD_SPECIFIC              = 0;
$PCSC::SCARD_STATE_CHANGED         = 0;
$PCSC::SCARD_SCOPE_GLOBAL          = 0;
$PCSC::SCARD_S_SUCCESS             = 0;
$PCSC::SCARD_UNKNOWN               = 0;
$PCSC::SCARD_SWALLOWED             = 0;
$PCSC::SCARD_E_SERVICE_STOPPED     = 0;
$PCSC::SCARD_E_UNSUPPORTED_FEATURE = 0;
$PCSC::SCARD_STATE_MUTE            = 0;
$PCSC::SCARD_E_CANCELLED           = 0;
$PCSC::SCARD_F_WAITED_TOO_LONG     = 0;
$PCSC::SCARD_E_SYSTEM_CANCELLED    = 0;
$PCSC::SCARD_STATE_INUSE           = 0;
$PCSC::SCARD_E_CARD_UNSUPPORTED    = 0;
$PCSC::SCARD_W_UNPOWERED_CARD      = 0;
$PCSC::SCARD_E_NOT_READY           = 0;
$PCSC::SCARD_W_INSERTED_CARD       = 0;
$PCSC::SCARD_STATE_EMPTY           = 0;
$PCSC::SCARD_F_COMM_ERROR          = 0;
$PCSC::SCARD_STATE_PRESENT         = 0;
$PCSC::SCARD_E_NO_SMARTCARD        = 0;
$PCSC::SCARD_RESET                 = 0;
$PCSC::SCARD_EJECT_CARD            = 0;
$PCSC::SCARD_E_INVALID_VALUE       = 0;
$PCSC::SCARD_UNPOWER_CARD          = 0;
$PCSC::SCARD_E_TIMEOUT             = 0;
$PCSC::SCARD_SHARE_DIRECT          = 0;
$PCSC::SCARD_E_PROTO_MISMATCH      = 0;
$PCSC::SCARD_STATE_UNKNOWN         = 0;
$PCSC::SCARD_E_DUPLICATE_READER    = 0;
$PCSC::SCARD_W_RESET_CARD          = 0;
$PCSC::SCARD_SCOPE_TERMINAL        = 0;
$PCSC::SCARD_STATE_EXCLUSIVE       = 0;
$PCSC::SCARD_NEGOTIABLE            = 0;
$PCSC::SCARD_E_READER_UNAVAILABLE  = 0;
$PCSC::SCARD_E_READER_UNSUPPORTED  = 0;
$PCSC::SCARD_E_CANT_DISPOSE        = 0;
$PCSC::SCARD_W_REMOVED_CARD        = 0;
$PCSC::SCARD_STATE_UNAVAILABLE     = 0;
$PCSC::SCARD_STATE_IGNORE          = 0;
$PCSC::SCARD_E_INSUFFICIENT_BUFFER = 0;
$PCSC::SCARD_E_UNKNOWN_READER      = 0;
$PCSC::SCARD_E_PCI_TOO_SMALL       = 0;
$PCSC::SCARD_F_INTERNAL_ERROR      = 0;
$PCSC::SCARD_E_INVALID_PARAMETER   = 0;
$PCSC::SCARD_E_UNKNOWN_CARD        = 0;
$PCSC::SCARD_E_INVALID_ATR         = 0;
$PCSC::SCARD_E_INVALID_TARGET      = 0;
$PCSC::SCARD_E_NO_SERVICE          = 0;
$PCSC::SCARD_REMOVED               = 0;
$PCSC::SCARD_STATE_UNAWARE         = 0;

_LoadPCSCLibrary();

__END__
# Below is the stub of documentation for your module. You
# better edit it!
