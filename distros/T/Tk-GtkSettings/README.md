# Tk-GtkSettings

Beautify your perl/Tk applications with the Gtk colors and fonts in your desktop theme.

It will install on Windows and Mac. However it will just sit there quietly doing nothing.

# Installation

 perl Makefile.PL
 
 make
 
 make test
 
 make install

# running tkgtk

This package ontains the script 'tkgtk'. 

 tkgtk ?my_app?

If you do not specify an app name the settings apply to every Perl/Tk program. 

When you run it it will read the gtk settings of your desktop and exports them
to .Xdefaults. After logging in again all your Tk applications should conform
to the look of your desktop. You could also run:

 xrdb -remove all
 
 xrdb ~/.Xdefaults


