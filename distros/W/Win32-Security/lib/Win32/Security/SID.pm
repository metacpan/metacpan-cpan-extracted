#############################################################################
#
# Win32::Security::SID - set of routines for SID manipulation
#
# Author: Toby Ovod-Everett
#
#############################################################################
# Copyright 2000, 2003, 2004 Toby Ovod-Everett.  All rights reserved
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Ovod-Everett at toby@ovod-everett.org
#############################################################################

=head1 NAME

C<Win32::Security::SID> - set of routines for SID manipulation

=head1 SYNOPSIS

  use Win32::Security::SID;

  Win32::Security::SID::ConvertSidToName($sid);
  Win32::Security::SID::ConvertSidToName(Win32::Security::SID::ConvertStringSidToSid($stringsid))

=head1 DESCRIPTION

This module provides functions for converting SIDs between binary and text
formats and for converting between SIDs and Trustees (usernames).

=head2 Installation instructions

This installs as part of C<Win32-Security.  See 
C<Win32::Security::NamedObject> for more information.

=head1 Function Reference

=head2 use Win32::Security::SID;

This has a side effect of C<use Win32;> and of patching 
C<Win32::LookupAccountName> to adjust the length of the SID properly as opposed 
to returning the entire 400 byte buffer.

=cut

use Win32;
use strict;

#This little block of code is workaround for a bug in Win32::LookupAccountName.  
#Specifically, Win32::LookupAccountName allocates a 400 byte buffer, loads the 
#SID into the buffer, and then returns the whole buffer.  Bleach.  So the BEGIN 
#block spirits away a reference to the underlying Win32::LookupAccountName call 
#and then the subroutine definition replaces the call with a wrapper that calls 
#the builtin and then crops the SID as appropriate.  For an explanation of how 
#the SID cropping works, see the docs for the SID structure in the Win32 
#Platform SDK.

BEGIN {
	$Win32::Security::SID::ref2old_LookupAccountName = \&Win32::LookupAccountName;

	local $^W = 0;    # suppress redefining messages.
	*Win32::LookupAccountName = sub {
		my $retval = &$Win32::Security::SID::ref2old_LookupAccountName;
		$_[3] = substr($_[3], 0, (unpack('xC', $_[3])+2)*4) if $retval;
		return $retval;
	}
}

package Win32::Security::SID;

=head2 ConvertSidToStringSid

This function is modeled on the Win32 API call of the same name.  The Win32 API 
call, however, requires Win2K.  This function takes a binary SID as a parameter 
(same format as returned by C<Win32::LookupAccountName>) and returns the string 
form of the SID in the S-I<R>-I<I>-I<S>-I<S> format.  It deals with 
IdentifierAuthority values greater than 2^32 by outputting them in hex (I have 
yet to run into any of these, but the spec allows for them).  If the SID is 
inconsistent or non-existent, the function returns C<undef>.  The string form is 
mostly commonly used for display purposes and for mounting hives under 
C<HKEY_USERS>.

=cut

sub ConvertSidToStringSid {
	my($sid) = @_;

	$sid or return;
	my($Revision, $SubAuthorityCount, $IdentifierAuthority0, $IdentifierAuthorities12, @SubAuthorities) =
		unpack("CCnNV*", $sid);
	my $IdentifierAuthority = $IdentifierAuthority0 ?
			sprintf('0x%04hX%08X', $IdentifierAuthority0, $IdentifierAuthorities12) :
			$IdentifierAuthorities12;
	$SubAuthorityCount == scalar(@SubAuthorities) or return;
	return "S-$Revision-$IdentifierAuthority-".join("-", @SubAuthorities);
}

=head2 ConvertStringSidToSid

This does the reverse of the above function.  It takes a string SID as a 
parameter and returns the binary format.  Again, if there are observable 
inconsistencies in the format, it will simply return C<undef>.

=cut

sub ConvertStringSidToSid {
	my($text) = @_;

	my(@Values) = split(/\-/, $text);
	(shift(@Values) eq 'S' && scalar(@Values) >= 3) or return;
	my $Revision = shift(@Values);
	my $IdentifierAuthority = shift(@Values);
	if (substr($IdentifierAuthority, 0, 2) eq '0x') {
		$IdentifierAuthority = pack("H12", substr($IdentifierAuthority, 2));
	} else {
		$IdentifierAuthority = pack("nN", 0, $IdentifierAuthority);
	}
	return pack("CCa6V*", $Revision, scalar(@Values), $IdentifierAuthority, @Values);
}

=head2 ConvertNameToSid

This is basically a semi-intelligent wrapper around C<Win32::LookupAccountName>.  
Of note, it uses C<undef> for the server name to query, which means the query 
will execute against the local host. This will correctly operate on un-prefixed 
domain user accounts, presuming they don't have the same name as the local 
computer.  If they do, the C<Win32::LookupAccountName> returns the SID for the 
local computer, which is a problem.  The C<$sidtype> returned is checked to see 
that it is User, Group, Alias, or WellKnownGroup - if it is Domain or Computer, 
the function returns C<'UNKNOWN_USERNAME'>, which helps to defend against this 
problem.  The safest solution is to always use a full user/group name - 
I<domain_name>\I<username>.  It returns the SID in binary format - if you need 
it in string SID format, call C<ConvertSidToStringSid>.

If this function gets passed a username that looks like a StringSid (i.e. 
C</^S(?:-\d+)+$/>), it calls C<ConvertStringSidToSid> and returns that result.  
This should only pose a problem if you have a very weird username and don't pass 
a domain name.

It uses a cache to remember previously asked for usernames (C<LookupAccountName> 
is very processor intensive - watch C<LSASS.EXE> spike if you make a lot of 
calls).

=cut

{
my $cache;

sub ConvertNameToSid {
	my($username) = @_;

	local $^W = 0;

	unless (exists $cache->{$username}) {
		if ($username =~ /^S(?:-\d+)+$/) {
			$cache->{$username} = ConvertStringSidToSid($username) || 'BAD_STRINGSID';
		} else {
			my($domain, $sid, $sidtype);
			if (Win32::LookupAccountName(undef, $username, $domain, $sid, $sidtype)) {
				if ($sidtype == 1 || $sidtype == 2 || $sidtype == 4 || $sidtype == 5) {
					$cache->{$username} = $sid;
				}
			}
			$cache->{$sid} ||= 'UNKNOWN_USERNAME';
		}
	}
	return $cache->{$username};
}

}

=head2 ConvertSidToName

This is basically a semi-intelligent wrapper around C<Win32::LookupAccountSID>.  
It returns I<domain_name>\I<username>.  In a nutshell, whatever gets returned by 
C<ConvertNameToSid> is safely suppliable to C<ConvertSidToName>.  It accepts the 
SID in binary format - if you have a SID in string SID format, call 
C<ConvertStringSidtoSid> first and pass the result.

It uses a cache to remember previously asked for SIDs (C<LookupAccountSID> is 
very processor intensive - watch C<LSASS.EXE> spike if you make a lot of calls).

=cut

{
my $cache;

sub ConvertSidToName {
	my($sid) = @_;

	local $^W = 0;

	unless (exists $cache->{$sid}) {
		my($domain, $username, $sidtype);
		if (Win32::LookupAccountSID(undef, $sid, $username, $domain, $sidtype)) {
			if ($sidtype == 1 || $sidtype == 2 || $sidtype == 4 || $sidtype == 5) {
				$cache->{$sid} = $domain ? "$domain\\$username" : $username;
			}
		}
		$cache->{$sid} ||= $sid ne '' ? (&ConvertSidToStringSid($sid) || 'BAD_SID') : 'UNDEFINED_SID';
	}

	return $cache->{$sid};
}

}

=head1 AUTHOR

Toby Ovod-Everett, toby@ovod-everett.org

=cut

1;
