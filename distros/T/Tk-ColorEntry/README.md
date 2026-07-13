# Tk-ColorEntry

Entry widget with color editor in a pop box

# Requirements

Following Perl modules must be installed:

    * Convert::Color
    * Imager
    * Imager::Screenshot
    * Math::Round
    * Test::Tk
    * Tk
    * Tk::ListBrowser
    * Tk::PopList

# Installation

    perl Makefile.PL
    make
    make test
    make install

For visual inspection before install you can do any of:

    perl -Mblib t/Tk-ColorEntry-multi.t show
    perl -Mblib t/Tk-ColorEntry.t show
    perl -Mblib t/Tk-ColorPicker.t show
    perl -Mblib t/Tk-PopColor.t show

These also provide a nice demo program.
