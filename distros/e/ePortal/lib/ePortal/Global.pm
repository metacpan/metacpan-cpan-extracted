#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
# This program is open source software
#
#
#----------------------------------------------------------------------------

package ePortal::Global;
    our $VERSION = '4.5';

	# --------------------------------------------------------------------
	# Symbols to export
	#
    use base qw/Exporter/;
    our @EXPORT = qw/$ePortal %session %gdata /;

   	# --------------------------------------------------------------------
	# Global variables
	#
    our $ePortal;
	our %session;
	our %gdata;


1;


__END__


=head1 NAME

ePortal::Global.pm - Global variables for entire ePortal.



=head1 SYNOPSIS

This package exports some global variables. Use this package everywhere
when you need these variables.



=head2 $ePortal

Global object blessed to ePortal::Server. This is main engine.





=head2 %session

This is hash of persistent per session data


=head2 %gdata

This is temporary hash object. It exists only during apache request
processing.




=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut
