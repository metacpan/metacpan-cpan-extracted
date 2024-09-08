# Tk-PodViewer

Pod viewer module for Perl/Tk

# Requirements

Following Perl modules should be installed:

  * Getopt::Long
  * Syntax::Kamelon
  * Test::Tk
  * Tk

# Installation

    perl Makefile.PL
    make
    make test
    make install

# Sample program podviewer

This package comes with a sample script **podviewer**. You can invoke
it from the command line after install.

Before install you can do: perl -Mblib bin/podviewer

For command line options type: podviewer -help
