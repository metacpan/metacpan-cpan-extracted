# Tk-Terminal

Terminal widget for Perl/Tk

This module works as a modest command shell. 
You can enter a command and go into dialog with the program you are running, 
if the program does not buffer it's output.

# Requirements

Following Perl modules must be installed:

    * IO::Handle
    * Tk
    * Tk::TextANSIColor
    * Test::Tk

# Installation

    perl Makefile.PL
    make
    make test
    make install

After make you can do the following for visual inspection:

    perl -Mblib t/Tk-Terminal.t show
 
