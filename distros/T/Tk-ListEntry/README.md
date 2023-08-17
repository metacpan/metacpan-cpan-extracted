# Tk-ListEntry

Tk::ListEntry is a variant on the Tk::BrowseEntry widget. It does
not have a label or button. Clicking the entry will pop the list.

You can use all config options and methods of the Entry widget.

# Installation

perl Makefile.PL  
make  
make test  
make install  

for visual inspection do the following after make:

perl -Mblib t/Tk-ListEntry.t show  

