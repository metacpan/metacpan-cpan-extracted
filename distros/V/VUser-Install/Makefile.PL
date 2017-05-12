#!/usr/bin/perl

# Copyright 2005 Randy Smith <perlstalker@gmail.com>
# $Id: Makefile.PL,v 1.2 2005/10/28 04:35:31 perlstalker Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME            => 'VUser-Install',
	      VERSION_FROM    => 'lib/VUser/Install.pm',
	      EXE_FILES       => [qw[sbin/install-local]],
	      INSTALLSCRIPT   => '$(PREFIX)/sbin',
	      PREREQ_PM       => {'Config::IniFiles' => 0,
				  'VUser::ExtLib'    => 0.2.0,
				  'VUser::Meta'      => 0.2.0,
				  'VUser::ResultSet' => 0.2.0,
				  'VUser::Extension' => 0.2.0,
				  'Socket'           => 0,
				  'Cwd'              => 0,
				  'Text::Template'   => 0,
				  'SOAP::Lite'       => 0
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
