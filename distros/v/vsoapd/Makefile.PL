#!/usr/bin/perl

# Copyright 2005 Randy Smith <perlstalker@vuser.org>
# $Id: Makefile.PL,v 1.5 2007/09/19 19:16:25 perlstalker Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME            => 'vsoapd',
	      VERSION_FROM    => 'sbin/vsoapd',
	      EXE_FILES       => [qw[sbin/vsoapd sbin/vsoapc sbin/gen-wsdl.pl]],
	      INSTALLSCRIPT   => '$(PREFIX)/sbin',
	      PREREQ_PM       => {'Config::IniFiles' => 0,
				              'Regexp::Common'   => 0,
				              'File::Path'       => 0,
				              'SOAP::Lite'       => "0.67",
				              'Pod::Usage'       => 0,
                              'Getopt::Long'     => 0,
                              'FindBin'          => 0,
                              'SOAP::Transport::HTTP' => 0,
                              'Config'           => 0,
                              'Digest::MD5'      => 0,
                              'Term::ReadKey'    => 0,
                              # VUser modules
				              'VUser::Log'       => 0,
				              'VUser::ExtHandler' => '0.3.2',
				              'VUser::ExtLib'    => 0,
				              'VUser::ACL'       => 0
				              }
	      );

__END__

=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE
 
 This file is part of vsoapd.
 
 vsoapd is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 vsoapd is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with vsoapd; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
