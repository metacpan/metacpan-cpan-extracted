#!/usr/bin/perl

use strict;
use warnings;

use Win32;
use Win32::Process;

# -----------------------------------------------

sub win32_error
{
	return Win32::FormatMessage(Win32::GetLastError() );

}	# End of win32_error.

# -----------------------------------------------

my($process);

Win32::Process::Create($process, 'c:\MailRoot\bin\Xmail.exe', 'XMail --debug', 0, NORMAL_PRIORITY_CLASS, '.') || die "Can't start process XMail. \n" . win32_error();

print "Started XMail. \n";
