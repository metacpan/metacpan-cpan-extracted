#!/usr/bin/perl

# Copyright 2005 Randy Smith <perlstalker@gmail.com>
# $Id: Makefile.PL,v 1.7 2008-03-17 17:53:53 perlstalker Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME            => 'vuser',
	      VERSION_FROM    => 'sbin/vuser',
	      EXE_FILES       => [qw[sbin/vuser]],
	      INSTALLSCRIPT   => '$(PREFIX)/sbin',
	      PREREQ_PM       => {'Config::IniFiles' => 0,
				  'Regexp::Common'   => 0,
				  'File::Path'       => 0,
				  'User::pwent'      => 0,
				  'Carp'             => 0
				  }
	      );

__END__

=head1 AUTHOR

Randy Smith <perlstalker@gmail.com>

=head1 LICENSE
 
 This file is part of vuser.
 
 vuser is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 vuser is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with vuser; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
