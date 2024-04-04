# Tk-FileBrowser

Perl/Tk widget for browsing files

A multicolumn file browser widget. Columns are configurable, sortable
and resizable.

# Requirements

Following Perl modules should be installed:

  * File::Basename
  * Test::Tk
  * Tk
  * Tk::ITree
  * Tk::ListEntry

They are installable through cpan.

# Installation

    perl Makefile.PL
    make
    make test
    make install

After make you can do the following for visual inspection

    perl -Mblib t/Tk-FileBrowser.t show
    perl -Mblib t/Tk-FileBrowser-Header.t show
    


