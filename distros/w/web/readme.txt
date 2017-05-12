Web - A set of useful routines for many webworking purposes

 
SYSTEM REQUIREMENTS
     This module was primarily made for UNIX/Linux-Systems.
     Parts of it cannot be used on other systems. E.g. the
     procedures for file locking demand systems that can use
     symlinks. If you use the modul on systems where symlinks
     cannot be used, fatal errors may happen.
     
SYNOPSIS
     use web;

ABSTRACT
     This perl module serves users with several useful routines
     for many purposes, like generating webpages, processing CGI
     scripts, working with XML datafiles and net-connections.  It
     also uses own variants of routines, that was invented first
     in the famous libraries CGI.pm and cgi-lib.pl.
     
SYNOPSIS
     use web;

INSTALLATION
     Copy web.pm into the Perl library directory and set it
     readable by everyone. 
     If you don't have sufficient privileges to install web.pm in
     the Perl library directory, you can put web.pm into some
     convenient spot, such as your home directory, or in cgi-bin
     itself and prefix all Perl scripts that call it with
     something along the lines of the following preamble:

             use lib '/home/myname/perl/lib';
             use web;

AUTHOR INFORMATION
     Copyright 1999-2002 Wolfgang Wiese.  All rights reserved.  It may
     be used and modified freely, but I do request that this
     copyright notice remain attached to the file.  You may
     modify this module as you wish, but if you redistribute a
     modified version, please attach a note listing the
     modifications you have made.
     Address bug reports and comments to:  xwolf@xwolf.com

CREDITS
     Thanks very much to:

     Johannes Schritz (johannes@schritz.de)
     Gert Buettner (g.buettner@rrze.uni-erlangen.de)
     Manfred Abel (m.abel@rrze.uni-erlangen.de)
     Rolf Rost (rolfrost@yahoo.com)
     Harald Mattern (webmaster@tsmweb.de)
