package X11::IdleTime;

use strict;
use warnings;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(GetIdleTime);
$VERSION = '0.08';

use Inline (
	C => 'DATA',
	VERSION => '0.08',
	NAME => 'X11::IdleTime',
	LIBS => '-L/usr/X11R6/lib/ -lX11 -lXext -lXss',
	);

1;

__DATA__

=pod

=head1 NAME

X11::IdleTime - Get the idle time of X11

=head1 SYNOPSIS

   use X11::IdleTime;

   $idle = GetIdleTime();

   print "Your mouse and keyboard have been idle for $idle seconds.\n";

=head1 DESCRIPTION

The X11::IdleTime module is useful for checking how long the user has been idle.

=head1 AUTHOR

Adam Wendt <thelsdj@gmail.com> (http://blog.thelsdj.org/)

=head1 COPYRIGHT

Copyright 2003-2008 Adam Wendt <thelsdj@gmail.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

__C__
#include <time.h>
#include <stdio.h>
#include <unistd.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/extensions/scrnsaver.h>

int GetIdleTime () {
        time_t idle_time;
        static XScreenSaverInfo *mit_info;
        Display *display;
        int screen;
        mit_info = XScreenSaverAllocInfo();
        if((display=XOpenDisplay(NULL)) == NULL) { return(-1); }
        screen = DefaultScreen(display);
        XScreenSaverQueryInfo(display, RootWindow(display,screen), mit_info);
        idle_time = (mit_info->idle) / 1000;
        XFree(mit_info);
        XCloseDisplay(display); 
        return idle_time;
}
