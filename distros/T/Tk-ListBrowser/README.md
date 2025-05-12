# Tk-ListBrowser

**Tk::ListBrowser** began as an inspiration on Tk::IconList.
Nice, column oriented arrangement, but how about row oriented
arrangement. And while we are at it, also list bar hlist and tree
oriented arrangement. Scrollbars work automatically. Efforts have
been made to follow the conventions of the Tk hierarchical list
family as close as possible.

[Screenshots here.](https://www.perlgui.org/all/tklistbrowser-screenshots/)

This module features:

## Arrange modes

Available arrange modes are 'bar', 'column', 'hlist', 'list'
and 'tree'. You can switch between arrange modes through the
*-arrange* option while retaining data.

The 'hlist' and 'tree' modes provide a hierarchical list
interface. For it to work properly the I<-separator> option
must be set to a non empty string of one character.

## Sorting

This module allows sorting your list on all kinds of paramenters,
like sorting on column, ascending or descending. Furthemore you 
can choose sort fields like '-data', '-name', or '-text'.

## Headers

Headers are shown in the 'hlist', 'list' and 'tree' modes. You can
create and configure them in any mode. They are resizable and can
be made sortable. You can drag headers left or right with your
mouse to change the column ordering.

## Side columns

Side columns are shown in the 'hlist', 'list' and tree modes. 
You can create and configure them in any mode.

## Filtering

The keyboard shortcut CTFL+F opens a filter entry at the bottom of the widget. Filtering is case insensitive.
The filter will start updating when *-filterdelay* milliseconds have past after your last keystroke.
You can choose which data to filter with the *-filterfield* option. Filtering can be done on the main list
as well as on the side columns.

# Requirements

Following Perl modules must be installed:

    * Math::Round
    * Test::Tk
    * Tk

# Installation

    perl Makefile.PL
    make
    make test
    make install

For visual inspection before install you can do any of:

    perl -Mblib t/1-Tk-ListBrowser.t show
    perl -Mblib t/2-Tk-ListBrowser-columns-headers.t show
    perl -Mblib t/3-Tk-ListBrowser-hlist-tree.t show

These also provide a nice demo program.



