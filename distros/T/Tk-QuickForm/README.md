# Tk-QuickForm
Quickly set up a form

This widget allows you to quickly set up a form for the user to fill out or modify.
Attempts are made to make it clear and elegant.

Inherits Tk::Frame.

With the B<-structure> option you can define
fields the user can fill. With the put and get methods you can set or retrieve values as a hash.


# Requirements

The following Perl modules must be installed:

  * Scalar::Util::Numeric
  * Test::Tk
  * Tk
  * Tk::FontDialog
  * Tk::ListEntry
  * Tk::ColorEntry

# Installation

perl Makefile.PL  
make  
make test  
make install  

After make you can do the following for visual inspection:

perl -Mblib t/Tk-QuickForm.t show  

