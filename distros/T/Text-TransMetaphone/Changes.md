# Revision History for the Text::Transmetaphone Perl Distribution

## 0.10 Thu Mar 27 17:41:17 EDT 2025
	- Added LICENSE to MANTIFEST.

## 0.09 Thu Mar 27 17:34:23 EDT 2025
	- Missing License file added.
	- Perl version set in Build.PL and META files.
	- Replaced hyphen with minus sign in abstract to avoide 'has_abstract_in_pod' error.

## 0.08 Sun Mar  2 19:46:24 EST 2025
	- Migration to a Build.PL & GitHub system.
	- Pure Perl implementation of the `en_US` Double Metaphone algorithm.
	- Removing PerlXS and C code.

## 0.07 Sat Aug 12 12:59:32 EDT 2006
	- fixed installation problems
	- masked all unsigned chars to chars for stdlib string functions
          to make gcc 4.0.3 happy.  This could be hazardous.
	- tested with perl v5.8.7, on Ubuntu 6.06

## 0.06 Sat Apr 12 21:23:09 EDT 2003
	- fixes in am.pm.
	- am.pm resynced with Regexp::Ethiopic.

## 0.05a Mon Mar 24 07:28:19 EST 2003
	- minor documentation fixes.

## 0.05 Sat Mar 22 20:41:44 EST 2003
	- initial release.
