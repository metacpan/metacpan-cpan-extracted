# Tk-DocumentTree

ITree based document list

Tk::DocumentTree is a Tree like megawidget. It consists of a Label and an ITree Widget.

You can use all of the options of an ITree widget except for I<-itemtype>, I<-browsecmd>,
I<-separator>, I<-selectmode> and I<-exportselection>.

The Label on top displays the path all added entries have in commom.
It automatically creates a folder tree as entries are added.

Entries can have the status 'file' or 'untracked'
An entry is untracked when it does not exist as a file.

# Requirements

The following Perl modules must be installed:

  * Test::Tk
  * Tk
  * Tk::ITree

# Installation

perl Makefile.PL  
make  
make test  
make install  

After make you can do the following for visual inspection:

perl -Mblib t/Tk-DocumentTree.t show  

