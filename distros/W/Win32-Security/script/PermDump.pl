#############################################################################
#
# PermDump.pl - script to do intelligent permissions enumeration under Win32
#
# Author: Toby Ovod-Everett
#
#############################################################################
# Copyright 2003, 2004 Toby Ovod-Everett.  All rights reserved
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Ovod-Everett at toby@ovod-everett.org
#############################################################################

#BEGIN {
#	use Class::Prototyped;
#	my $temp = Class::Prototyped->reflect->defaultAttributes;
#	$temp->{FIELD}->{profile} = 2;
#	$temp->{METHOD}->{profile} = 2;
#	Class::Prototyped->reflect->defaultAttributes($temp);
#}

use Data::Dumper;
use File::DosGlob 'glob';
use Getopt::Long;
use Win32::Security::Recursor;

use strict;
use vars qw($counter $starttime);

$starttime = Win32::GetTickCount();

my $options = {};
GetOptions($options, qw(csv! dirsonly! inherited! owner! recurse|s! help performance!)) or die "Invalid option.\n";

if (defined($options->{help})) {
	print <<ENDHELP;
PermDump.pl options:
  -c[sv]         Output in CSV format
  -d[irsonly]    Check directories only
  -i[nherited]   Display properly inherited permissions/ownership
  -o[wner]       Display ownership
  -r[ecurse]     Recurse into subdirectories
  -s             Same as -r[ecurse]
  -p[erformance] Outputs simple performance numbers
  -h[elp]        Print this message

PermDump.pl takes an optional list of files and/or directories to check.  If
no list is passed, it will display permissions for the current directory.

The Desc value displays one of these three values in the first column:
  (D)irectory  The thing in question is a directory
  (F)ile       The thing in question is a file
  (?)          Returned with ERROR_READ_FILEATTRIBS

The Desc value displays one of these nine values in the second column:
  (B)locked    Inheritance is blocked for this object
  (E)rror      There was an error on this object
  (I)nherited  The ACE is properly inherited from its container
  (J)unction   Permission enumeration did not proceed through this Junction
  (M)issing    This inheritable ACE on the container is missing from the object
  (N)ULLDACL   This object has a NULL DACL
  (O)wner      Ownership record for the object
  (W)rong      This ACE is marked as inherited but there is no corresponding
               ACE on its container
  e(X)plicit   The ACE is explicitly applied to the object

ENDHELP
	exit;
}

$| = 1;
select((select(STDERR), $|=1)[0]);

@ARGV = map {/[*?]/ ? glob($_) : $_ } @ARGV;
@ARGV = (".") unless scalar(@ARGV);

my $recursor = Win32::Security::Recursor::SE_FILE_OBJECT::PermDump->new($options, debug => 0);

$recursor->print_header();
foreach my $name (@ARGV) {
	$recursor->recurse($name);
}

if ($options->{performance}) {
	my $elapsed = Win32::GetTickCount()-$starttime;
	print STDERR sprintf("%i in %0.2f seconds (%i/s, %0.2f ms)\n", $recursor->{payload_count},
			($elapsed)/1000, $recursor->{payload_count}*1000/($elapsed || 1),
			$elapsed/($recursor->{payload_count} || 1)
		);
	print STDERR sprintf("%i unique ACEs, %i unique ACLs\n",
			scalar(keys %{Win32::Security::ACE::SE_FILE_OBJECT->_rawAceCache()}),
			scalar(keys %{Win32::Security::ACL::SE_FILE_OBJECT->_rawAclCache()}) );
}

#my $payload_count = $recursor->{payload_count};
#foreach my $package (sort keys %{$Class::Prototyped::Mirror::PROFILE::counts}) {
#	foreach my $slotName (sort keys %{$Class::Prototyped::Mirror::PROFILE::counts->{$package}}) {
#		foreach my $caller (sort keys %{$Class::Prototyped::Mirror::PROFILE::counts->{$package}->{$slotName}}) {
#			my $call_count = $Class::Prototyped::Mirror::PROFILE::counts->{$package}->{$slotName}->{$caller};
#			print STDERR "$package\t$slotName\t$caller\t$call_count\t".sprintf("%0.3f", $call_count/$payload_count)."\n";
#		}
#	}
#}
