package WebShortcutUtil;

use strict;
use warnings;

our $VERSION = '0.22';

# REFERENCES
#
# Free Desktop:
#   http://standards.freedesktop.org/desktop-entry-spec/latest/ (used Version 1.1-draft)
#
# Windows URL (also applicable to Website):
#   http://stackoverflow.com/questions/539962/creating-a-web-shortcut-on-user-desktop-programmatically
#   http://stackoverflow.com/questions/234231/creating-application-shortcut-in-a-directory
#   http://delphi.about.com/od/internetintranet/a/lnk-shortcut.htm
#   http://read.pudn.com/downloads3/sourcecode/windows/system/11495/shell/shlwapi/inistr.cpp__.htm
#   http://epiphany-browser.sourcearchive.com/documentation/2.24.0/plugin_8cpp-source.html
#   http://epiphany-browser.sourcearchive.com/documentation/2.24.0/plugin_8cpp-source.html
#
# Webloc / Plist:
#   http://search.cpan.org/~bdfoy/Mac-PropertyList-1.38/
#     or https://github.com/briandfoy/mac-propertylist
#   http://opensource.apple.com/source/CF/CF-550/CFBinaryPList.c
#   http://code.google.com/p/cocotron/source/browse/Foundation/NSPropertyList/NSPropertyListReader_binary1.m
#   http://www.apple.com/DTDs/PropertyList-1.0.dtd


=head1 NAME

WebShortcutUtil - Perl module for reading and writing web shortcut files

=head1 DESCRIPTION

This module is part of the WebShortcutUtil suite.  For more details
see the main website at http://beckus.github.io/WebShortcutUtil/ .

All of the subroutines are contained in the Read and Write submodules.
See those submodules for usage information.

A brief list of the supported shortcut types:

=over 4

=item * .desktop - Free Desktop shortcut (used by Linux)

=item * .url - Used by Windows

=item * .website - Used by Windows

=item * .webloc - Used by Mac

=back

In order to read/write ".webloc" files, the Mac::PropertyList module (http://search.cpan.org/~bdfoy/Mac-PropertyList/)
must be installed.  Mac::PropertyList is listed as a dependency, but the the WebShortcutUtil
module will still test out and install properly if it is not present.  The webloc subroutines will die
if the Mac::PropertyList module is not installed.

Note that this module is still beta-quality, and the interface is subject to change.

=head1 SOURCE

https://github.com/beckus/WebShortcutUtil-Perl

=head1 FUTURE IDEAS

Some ideas for enhanced functionality:

=over 4

=item * For ".desktop" files, add logic to extract the names embedded in a shortcut
        (including all localized versions of the name).  Similar logic could also
        be written for ".website" files.

=item * Explore unicode functionality for ".webloc" files.  Will a Mac open a URL
        that has unicode characters?

=item * Add an ASCII conversion option to the filename creation routines
        (i.e. to remove unicode characters).

=back

=head1 AUTHOR

Andre Beckus E<lt>beckus@cpan.orgE<gt>

=head1 SEE ALSO

=over 4

=item * Main project website: http://beckus.github.io/WebShortcutUtil/

=item * Read module: http://search.cpan.org/~beckus/WebShortcutUtil/lib/WebShortcutUtil/Read.pm

=item * Write module: http://search.cpan.org/~beckus/WebShortcutUtil/lib/WebShortcutUtil/Write.pm

=item * Perl module for using Windows shortcuts: http://search.cpan.org/~ishigaki/Win32-InternetShortcut/

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Andre Beckus

This library is free software; you can redistribute it and/or modify
it under the same terms as the Perl 5 programming language itself.

=cut


1;
__END__
