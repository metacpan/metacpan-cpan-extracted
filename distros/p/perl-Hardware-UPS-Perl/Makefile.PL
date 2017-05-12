#!/usr/bin/perl -w

#==============================================================================
# description:
#------------------------------------------------------------------------------
# Perl Makefile for Hardware::UPS::Perl
#==============================================================================

#==============================================================================
# Copyright:
#------------------------------------------------------------------------------
# Copyright (c) 2007 Christian Reile, <Christian.Reile@t-online.de>. All
# rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#==============================================================================

#==============================================================================
# Entries for Revision Control:
#------------------------------------------------------------------------------
# Revision        : $Revision: 1.9 $
# Author          : $Author: creile $
# Last Modified On: $Date: 2007/04/17 19:49:28 $
# Status          : $State: Exp $
#------------------------------------------------------------------------------
# Modifications   :
#------------------------------------------------------------------------------
#
# $Log: Makefile.PL,v $
# Revision 1.9  2007/04/17 19:49:28  creile
# prerequisite package Test::Simple added;
# update to version 0.43.
#
# Revision 1.8  2007/04/14 17:16:13  creile
# update to package version 0.42.
#
# Revision 1.7  2007/04/14 09:37:26  creile
# documentation update.
#
# Revision 1.6  2007/04/07 14:50:09  creile
# upgrade to version 0.40 including new scripts upsadm.pl and
# upsstat.pl;
# required modules constant, POSIX and Tie::RefHash added;
# some "best practices" style improvements.
#
# Revision 1.5  2007/02/05 20:42:02  creile
# target install_vendor in MY::postamble() added;
# update of packages required to version 0.30;
# change of DISTNAME to perl-Hardware-UPS-Perl;
# update of ABSTRACT.
#
# Revision 1.4  2007/01/28 05:33:45  creile
# update of version.
#
# Revision 1.3  2007/01/28 04:19:33  creile
# name update in documentation.
#
# Revision 1.2  2007/01/21 15:00:11  creile
# documentation added;
# Version stated explicitly;
# Perl modules required added.
#
#
#==============================================================================

#==============================================================================
# packages required:
#------------------------------------------------------------------------------
#
#   ExtUtils::MakeMaker		- create a module Makefile
#   strict			- restricting unsafe constructs
#
#==============================================================================

use ExtUtils::MakeMaker;
use strict;

#==============================================================================
# defining subroutines:
#==============================================================================

# just to make it ignore editor backup and version control files and
# directories.
sub MY::libscan {
	$_ = $_[1];

	return q{}
       		if $_ eq 'upsadm.pl'   or
		   $_ eq 'upsagent.pl' or 
		   $_ eq 'upsstat.pl'  or
		   $_ eq 'upswatch.pl';

	return q{} if m{\/(RCS|CVS|SCCS)\/} || m{[~%]$} || m{\.(orig|rej)$};

	return $_;
}

# add a few more targets.
sub MY::postamble {
	return q{

install:: extra_install
pure_install:: extra_install
install_vendor:: extra_install

extra_install:
	install -d $(DESTDIR)/etc/init.d $(DESTDIR)/$(PREFIX)/sbin
	install -m 755 suse/upsperld.sh $(DESTDIR)/etc/init.d/upsperld
	ln -s ../../etc/init.d/upsperld $(DESTDIR)/$(PREFIX)/sbin/rcupsperld
	install -d $(DESTDIR)/etc/sysconfig
	install -m 644 suse/upsperld.sysconfig $(DESTDIR)/etc/sysconfig/upsperld

}
}

#==============================================================================
# start of main body:
#==============================================================================

WriteMakefile(
	NAME		=> 'Hardware::UPS::Perl',
	DISTNAME	=> 'perl-Hardware-UPS-Perl',
	VERSION      	=> '0.43',
	PREREQ_PM 	=> {
				'Carp'			=> 0,
				'constant'		=> 0,
				'Date::Format'		=> 0,
				'Env'			=> 0,
				'Fcntl'			=> 0,
				'File::Basename'	=> 0,
				'File::Find'		=> 0,
				'File::Spec::Functions'	=> 0,
				'FileHandle'		=> 0,
				'FindBin'		=> 0,
				'Getopt::Long'		=> 0,
				'IO::Select'		=> 0,
				'IO::Socket'		=> 0,
				'IO::Socket::INET'	=> 0,
				'IO::Stty'		=> 0,
				'Mail::Send'		=> 0,
				'Net::Domain'		=> 0,
				'Net::hostent'		=> 0,
				'POSIX'			=> 0,
				'Sys::Syslog'		=> 0,
				'strict'		=> 0,
				'Test::Simple'		=> 0,
				'Tie::RefHash'		=> 0,
				'Time::HiRes'		=> 0,
				'vars'  		=> 0,
			   },
	AUTHOR		=> 'Christian Reile <Christian.Reile@t-online.de>',
	ABSTRACT	=> 'UPS (uninterruptible power supply)',
	EXE_FILES	=> [
			       	'upsadm.pl',
				'upsagent.pl',
			       	'upsstat.pl',
			       	'upswatch.pl',
			   ],
);
