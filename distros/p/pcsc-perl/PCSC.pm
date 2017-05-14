###########################################################################
#    Authors     : Lionel VICTOR <lionel.victor@unforgettable.com>
#                                 <lionel.victor@free.fr>
#                  Ludovic ROUSSEAU <ludovic.rousseau@free.fr>
#    Compiler    : gcc, Visual C++
#    Target      : Unix, Windows
#
#    Description : Perl wrapper to the PCSC API
#    
#    Copyright (C) 2001 - Lionel VICTOR
#    Copyright (c) 2003-2010 Ludovic ROUSSEAU
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
###########################################################################

# $Id: PCSC.pm,v 1.25 2013/04/01 10:23:33 rousseau Exp $

package Chipcard::PCSC;

require Chipcard::PCSC::Card;
require Exporter;
require DynaLoader;

use warnings;
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
$VERSION = '0.05';

bootstrap Chipcard::PCSC $VERSION;

# Preloaded methods go here.

# We start with some basic conversion function here. They are global to
# the package and should not be used through an object instance
sub array_to_ascii($)
{
	my $byte_array_ref = shift;

	confess ("wrong type") unless ref ($byte_array_ref);
	confess ('usage Chipcard::PCSC::array_to_ascii($string)') unless defined $byte_array_ref;

	# return an empty string for an empty list
	return "" if (! @{$byte_array_ref});

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

sub ascii_to_array($)
{
	my $ascii_string = shift;
	my @return_array;
	my $tmpVal;

	confess ('usage Chipcard::PCSC::ascii_to_array($string)') unless defined $ascii_string;

	foreach $tmpVal (split / /, $ascii_string) {
		croak ("ascii_to_array: wrong value ($tmpVal)") unless ($tmpVal =~ m/^[0-9a-f][0-9a-f]$/i);
		push @return_array, hex ($tmpVal);
	}

	# return a reference to the constructed array
	return \@return_array;
}

# Usage:
# $my_var = new Chipcard::PCSC ($scope, $remote_host);
#
# default values:
# $scope = $Chipcard::PCSC::SCARD_SCOPE_SYSTEM
# $remote_host = 0 (localhost)
sub new ($$$)
{
	my $class = shift;

	my $scope = shift;
	my $remote_host = shift;
	my $container = {};

	# Apply default values when required
	$scope = $Chipcard::PCSC::SCARD_SCOPE_SYSTEM unless (defined ($scope));
	$remote_host = 0 unless (defined ($remote_host));

	$container->{hContext} = _EstablishContext ($scope, $remote_host, 0);

	return undef unless (defined($container->{hContext}));
	return bless $container, $class;
}

sub ListReaders($)
{
	my $self = shift;
	confess ("wrong type") unless ref $self;

	my $group = shift;
	# group is null if not given
#	$group = 0 unless (defined ($group));

	return _ListReaders ($self->{hContext}, $group);
}

sub GetStatusChange($)
{
	my $self = shift;
	confess ("wrong type") unless ref $self;

	my $readers_state = shift;
	my $nTimeout = shift;

	# The default timeout value is something supposed to be infinite
	$nTimeout = 0xFFFFFFFF unless (defined ($nTimeout));

	return _GetStatusChange ($self->{hContext}, $nTimeout, $readers_state);
}

sub Cancel($)
{
	my $self = shift;
	confess ("wrong type") unless ref $self;

	return _Cancel ($self->{hContext});
}

sub DESTROY($)
{
	my $self = shift;
	confess ("wrong type") unless ref $self;

	# Release Chipcard::PCSC context when the object is about to be destroyed
	my $return_val = _ReleaseContext ($self->{hContext});

	# die in case of an error
	confess ("Can't release context $self->{hContext}: $!") unless (defined ($return_val));
}

# Autoload methods go after __END__, and are processed by
# the autosplit program.

$Chipcard::PCSC::SCARD_ABSENT                = 0;
$Chipcard::PCSC::SCARD_E_CANCELLED           = 0;
$Chipcard::PCSC::SCARD_E_CANT_DISPOSE        = 0;
$Chipcard::PCSC::SCARD_E_CARD_UNSUPPORTED    = 0;
$Chipcard::PCSC::SCARD_E_DUPLICATE_READER    = 0;
$Chipcard::PCSC::SCARD_E_INSUFFICIENT_BUFFER = 0;
$Chipcard::PCSC::SCARD_E_INVALID_ATR         = 0;
$Chipcard::PCSC::SCARD_E_INVALID_HANDLE      = 0;
$Chipcard::PCSC::SCARD_E_INVALID_PARAMETER   = 0;
$Chipcard::PCSC::SCARD_E_INVALID_TARGET      = 0;
$Chipcard::PCSC::SCARD_E_INVALID_VALUE       = 0;
$Chipcard::PCSC::SCARD_EJECT_CARD            = 0;
$Chipcard::PCSC::SCARD_E_NO_MEMORY           = 0;
$Chipcard::PCSC::SCARD_E_NO_SERVICE          = 0;
$Chipcard::PCSC::SCARD_E_NO_SMARTCARD        = 0;
$Chipcard::PCSC::SCARD_E_NOT_READY           = 0;
$Chipcard::PCSC::SCARD_E_NOT_TRANSACTED      = 0;
$Chipcard::PCSC::SCARD_E_PCI_TOO_SMALL       = 0;
$Chipcard::PCSC::SCARD_E_PROTO_MISMATCH      = 0;
$Chipcard::PCSC::SCARD_E_READER_UNAVAILABLE  = 0;
$Chipcard::PCSC::SCARD_E_READER_UNSUPPORTED  = 0;
$Chipcard::PCSC::SCARD_E_SERVICE_STOPPED     = 0;
$Chipcard::PCSC::SCARD_E_SHARING_VIOLATION   = 0;
$Chipcard::PCSC::SCARD_E_SYSTEM_CANCELLED    = 0;
$Chipcard::PCSC::SCARD_E_TIMEOUT             = 0;
$Chipcard::PCSC::SCARD_E_UNKNOWN_CARD        = 0;
$Chipcard::PCSC::SCARD_E_UNKNOWN_READER      = 0;
$Chipcard::PCSC::SCARD_E_UNSUPPORTED_FEATURE = 0;
$Chipcard::PCSC::SCARD_F_COMM_ERROR          = 0;
$Chipcard::PCSC::SCARD_F_INTERNAL_ERROR      = 0;
$Chipcard::PCSC::SCARD_F_UNKNOWN_ERROR       = 0;
$Chipcard::PCSC::SCARD_F_WAITED_TOO_LONG     = 0;
$Chipcard::PCSC::SCARD_INSERTED              = 0;
$Chipcard::PCSC::SCARD_LEAVE_CARD            = 0;
$Chipcard::PCSC::SCARD_NEGOTIABLE            = 0;
$Chipcard::PCSC::SCARD_POWERED               = 0;
$Chipcard::PCSC::SCARD_PRESENT               = 0;
$Chipcard::PCSC::SCARD_REMOVED               = 0;
$Chipcard::PCSC::SCARD_RESET                 = 0;
$Chipcard::PCSC::SCARD_RESET_CARD            = 0;
$Chipcard::PCSC::SCARD_SCOPE_GLOBAL          = 0;
$Chipcard::PCSC::SCARD_SCOPE_TERMINAL        = 0;
$Chipcard::PCSC::SCARD_SCOPE_USER            = 0;
$Chipcard::PCSC::SCARD_SHARE_DIRECT          = 0;
$Chipcard::PCSC::SCARD_SPECIFIC              = 0;
$Chipcard::PCSC::SCARD_S_SUCCESS             = 0;
$Chipcard::PCSC::SCARD_STATE_ATRMATCH        = 0;
$Chipcard::PCSC::SCARD_STATE_CHANGED         = 0;
$Chipcard::PCSC::SCARD_STATE_EMPTY           = 0;
$Chipcard::PCSC::SCARD_STATE_EXCLUSIVE       = 0;
$Chipcard::PCSC::SCARD_STATE_IGNORE          = 0;
$Chipcard::PCSC::SCARD_STATE_INUSE           = 0;
$Chipcard::PCSC::SCARD_STATE_MUTE            = 0;
$Chipcard::PCSC::SCARD_STATE_PRESENT         = 0;
$Chipcard::PCSC::SCARD_STATE_UNAVAILABLE     = 0;
$Chipcard::PCSC::SCARD_STATE_UNAWARE         = 0;
$Chipcard::PCSC::SCARD_STATE_UNKNOWN         = 0;
$Chipcard::PCSC::SCARD_SWALLOWED             = 0;
$Chipcard::PCSC::SCARD_UNKNOWN               = 0;
$Chipcard::PCSC::SCARD_UNPOWER_CARD          = 0;
$Chipcard::PCSC::SCARD_W_REMOVED_CARD        = 0;
$Chipcard::PCSC::SCARD_W_RESET_CARD          = 0;
$Chipcard::PCSC::SCARD_W_UNPOWERED_CARD      = 0;
$Chipcard::PCSC::SCARD_W_UNRESPONSIVE_CARD   = 0;
$Chipcard::PCSC::SCARD_W_UNSUPPORTED_CARD    = 0;

$Chipcard::PCSC::SCARD_PROTOCOL_RAW          = 4;
$Chipcard::PCSC::SCARD_PROTOCOL_T0           = 1;
$Chipcard::PCSC::SCARD_PROTOCOL_T1           = 2;
$Chipcard::PCSC::SCARD_SHARE_DIRECT          = 3;
$Chipcard::PCSC::SCARD_SHARE_EXCLUSIVE       = 1;
$Chipcard::PCSC::SCARD_SHARE_SHARED          = 2;

_LoadPCSCLibrary();

__END__
# Below is the stub of documentation for your module. You
# better edit it!
