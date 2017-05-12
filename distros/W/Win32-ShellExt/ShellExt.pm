# -*- cperl -*-
# Win32/ShellExt.pm
#
# (C) 2001-2002 jbnivoit@cpan.org
#

package Win32::ShellExt;

use 5.006;
use strict;
use warnings;
$Win32::ShellExt::VERSION = '0.1';

use Config; # to locate where the DLL is installed.
use Win32::TieRegistry 0.23 ( Delimiter=>"/", ArrayValues=>1 ); # used for creation/deletion of registry keys for a given extension.
# tested with version 0.23 of Win32::TieRegistry.

sub create_hkeys() {

	my $hkeys = shift;

	my $hkey;
	foreach $hkey (sort keys %$hkeys) {
	  print "adding $hkey => $hkeys->{$hkey}\n";
	  $Registry->{$hkey} = $hkeys->{$hkey};
	}

}

sub remove_hkeys() {
	my $hkey;

	$Registry->Delimiter("/");

	while ($hkey = pop @_) {
	  print "removing $hkey\n";
	  delete $Registry->{$hkey} or die $^E;
	}
}

1;
__END__

=head1 NAME

Win32::ShellExt - Perl module for implementing extensions of the Windows Explorer

=head1 DESCRIPTION

This module is never used directly. You always subclass one of its sub-packages into 
your own package, then do a one-time invocation of the install() method on your package 
(to install the needed registry keys). There are 4 types of shell extensions that you can
make: ColumnProvider (add new informative columns in the explorer), CopyHook (allow and
disallow copying, moving or renaming shell objects), CtxtMenu (add commands to the contextual
menu), QueryInfo (provide tooltips for specific file type).

=head2 EXPORT

None by default. None needed.

=head1 AUTHOR

Jean-Baptiste Nivoit E<lt>jbnivoit@hotmail.comE<gt>

=head1 SEE ALSO

L<perl>.

=cut
