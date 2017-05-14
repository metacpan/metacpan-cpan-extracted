#
# Makefile for BeanCounter.pm
#
# BeanCounter.pm --- A stock portfolio performance monitoring tool
#
# Copyright (C) 2000 - 2005 Dirk Eddelbuettel <edd@debian.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
# $Id: Makefile.PL,v 1.3 2004/04/03 15:22:18 edd Exp edd $
#

use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'		=> 'Finance::BeanCounter',
	      'VERSION'		=> '0.8.10',
	      'PREREQ_PM'   	=> { "LWP::UserAgent"   => 1.62,
				     "HTTP::Request"    => 1.23,
				     "HTML::Parser"     => 2.20,
				     "Text::ParseWords" => 3.1,
				     "Date::Manip"	=> 5.35,
				     "DBI"		=> 1.16,
				     ## and any one of these
				     ##   "DBD::Pg"	=> 0.93,
				     ##   "DBD::ODBC"	=> 0.28,
				     ##   "DBD::mysql"	=> 2.0416,
				     ##   "DBD::SQLite" => 1.0,    # v3
				     ##   "DBD::SQLite2"=> 0.33
				     "Statistics::Descriptive" => 2.4,
				     "Finance::YahooQuote" => 0.20
				   },
	      ($] >= 5.005 ?
	       ('ABSTRACT'   => 'Stock portfolio performance monitoring tool',
		'AUTHOR'     	=> 'Dirk Eddelbuettel (edd@debian.org)')
	       : ()
	      ),
	      EXE_FILES 	=> ['beancounter', 
				    'setup_beancounter',
				    'update_beancounter'],
	      'dist'		=> { COMPRESS => "gzip -9f",
				     SUFFIX => '.gz' }
	     );



