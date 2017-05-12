#!/usr/bin/perl

# Copyright 2005 Randy Smith <perlstalker@vuser.org>
# $Id: Makefile.PL,v 1.1 2007-09-17 16:13:05 perlstalker Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME            => 'VUser-Google-Api',
	      VERSION_FROM    => 'lib/VUser/Google/ApiProtocol.pm',
	      INSTALLSCRIPT   => '$(PREFIX)/sbin',
	      PREREQ_PM       => {
				  'Carp' => 0,
				  'LWP::UserAgent' => 0,
				  'HTTP::Request' => 0,
				  'Encode' => 0,
				  'XML::Simple' => 0,
				  'Crypt::SSLeay' => 0,
				  }, # e.g., Module::Name => 1.1

	      );

__END__

=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE
 
 This file is part of VUser-Google-ProvisioningAPI.
 
 VUser-Google-ProvisioningAPI is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 VUser-Google-ProvisioningAPI is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with VUser-Google-ProvisioningAPI; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
