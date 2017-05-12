############################################################################
#
# Win32/ProcFarm/Child.pl - procedural support code for child processes in
#                           the Win32-ProcFarm system
#
# Author: Toby Everett
# Revision: 2.15
# Last Change: Namespace change
############################################################################
# Copyright 1999, 2000, 2001 Toby Everett.  All rights reserved.
#
# This file is distributed under the Artistic License. See
# http://www.ActiveState.com/corporate/artistic_license.htm or
# the license that comes with your perl distribution.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Everett at teverett@alascom.att.com
############################################################################

=head1 NAME

Win32/ProcFarm/Child.pl - procedural support code for child processes in
													the Win32-ProcFarm system

=head1 SYNOPSIS

	require 'Win32/ProcFarm/Child.pl';

	&init;
	while(1) {
		&main_loop;
	}

	sub child_sub {
		my(@params) = @_;

 #do some useful work that may take a while
		return (@return_values);
	}

=head1 DESCRIPTION

=head2 Installation instructions

This installs with MakeMaker as part of Win32::ProcFarm.

To install via MakeMaker, it's the usual procedure - download from CPAN,
extract, type "perl Makefile.PL", "nmake" then "nmake install". Don't
do an "nmake test" because the I haven't written a test suite yet.

=head1 UTILIZATION

Simple include the top 6 lines of code in a Perl script and define a bunch of subroutines.  Don't
use die in the subroutines.

=cut

use Data::Dumper;
use IO::Socket;

sub init {
	my($port_num, $unique) = @ARGV[0,1];

	$socket = new IO::Socket::INET ("localhost:$port_num") or die "Child unable to open socket.\n";
	print $socket pack("V", $unique);
}

sub main_loop {
	my($len, $cmd);

	my $temp = read($socket, $len, 4);
	$temp or exit;
	$temp == 4 or die "Unable to completely read command length.\n";
	$len = unpack("V", $len);
	(read($socket, $cmd, $len) == $len) or die "Unable to completely read command.\n";
	my($command, $ptr2params);
	eval($cmd);
	my(@retval) = &$command(@{$ptr2params});
	my $retstr = Data::Dumper->Dump([\@retval], ["ptr2retval"]);
	print $socket (pack("V", length($retstr)).$retstr);
}

1;
