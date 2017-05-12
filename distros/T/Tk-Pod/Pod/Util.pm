# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2003,2004,2012 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Tk::Pod::Util;
use strict;
use vars qw($VERSION @EXPORT_OK);
$VERSION = '5.05';

use base qw(Exporter);
@EXPORT_OK = qw(is_in_path is_interactive detect_window_manager start_browser);

# REPO BEGIN
# REPO NAME is_in_path /home/e/eserte/src/repository
# REPO MD5 1b42243230d92021e6c361e37c9771d1

sub is_in_path {
    my($prog) = @_;
    require Config;
    my $sep = $Config::Config{'path_sep'} || ':';
    foreach (split(/$sep/o, $ENV{PATH})) {
	if ($^O eq 'MSWin32') {
	    return "$_\\$prog"
		if (-x "$_\\$prog.bat" ||
		    -x "$_\\$prog.com" ||
		    -x "$_\\$prog.exe" ||
		    -x "$_\\$prog.cmd"
		   );
	} else {
	    return "$_/$prog" if (-x "$_/$prog" && !-d "$_/$prog");
	}
    }
    undef;
}
# REPO END

sub is_interactive {
    if ($^O eq 'MSWin32' || !eval { require POSIX; 1 }) {
	# fallback
	return -t STDIN && -t STDOUT;
    }

    # from perlfaq8 (with glitches)
    open(TTY, "/dev/tty") or return 0;
    my $tpgrp = POSIX::tcgetpgrp(fileno(*TTY));
    my $pgrp = getpgrp();
    if ($tpgrp == $pgrp) {
	1;
    } else {
	0;
    }
}

sub detect_window_manager {
    my $top = shift;
    if ($Tk::platform eq 'MSWin32') {
	return "win32";
    }
    if (   get_property($top, "GNOME_NAME_SERVER")) {
	return "gnome";
    }
    if (   get_property($top, "KWM_RUNNING") # KDE 1
	|| get_property($top, "KWIN_RUNNING") # KDE 2
       ) {
	return "kde";
    }
    "x11"; # generic X11 window manager
}

sub get_property {
    my($top, $prop) = @_;
    my @ret;
    if ($top->property('exists', $prop, 'root')) {
	@ret = $top->property('get', $prop, 'root');
	shift @ret; # get rid of property name
    }
    @ret;
}

sub start_browser {
    my($url) = @_;

    if (!defined &Tk::Pod::WWWBrowser::start_browser && !eval { require Tk::Pod::WWWBrowser }) {
	*Tk::Pod::WWWBrowser::start_browser = sub {
	    my $url = shift;
	    if ($^O eq 'MSWin32') {
		system(qq{start explorer "$url"});
	    } elsif ($^O eq 'cygwin') {
		system(qq{explorer "$url" &});
	    } elsif (is_in_path("firefox")) {
		system(qq{firefox "$url" &});
	    } else { # last fallback
		system(qq{mozilla "$url" &});
	    }
	};
    }

    Tk::Pod::WWWBrowser::start_browser($url);
}

1;

__END__

=head1 NAME

Tk::Pod::Util - Tk::Pod specific utility functions

=head1 DESCRIPTION

This module contains a collection of utility functions for Tk::Pod and
is not meant for public use.

=cut
