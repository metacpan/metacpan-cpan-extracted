#	Makefile.PL -- Makefile template for oEdtk.
#	This file is part of the "oEdtk" module package.
#
#	SEE README FILE
#	*******************************************************************
#	These modules are under GNU GENERAL PUBLIC LICENSE (see COPYING file)
#	You can use oEdtk as is without any warranty.
#
#	Copyright (c) 2005-2013  David AUNAY - GJ CHAILLOU DOMINGO
#
#	See COPYRIGHT section in oEdtk.pm for usage and distribution rights.
use POSIX;


BEGIN {
    require 5.8.8;
}


# load module
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
# to install pre requisite libxml : perl Makefile.PL LIBS='-L/usr/lib' INC='-I/usr/include/libxml2'
# 	depending on your lib path


# write makefile
WriteMakefile(
	NAME			=> 'oEdtk',
	VERSION_FROM	=> 'lib/oEdtk.pm',
	PREREQ_PM		=> {
		# dmake				=> 0,
		Archive::Zip			=> 0,
		charnames				=> 0,
		# DBD::Oracle			=> 0,
		Config::IniFiles 		=>'2.30',
		Cwd					=> 0,
		Data::Dumper			=> 0,
		Date::Calc			=> 0,
		DBI					=>'1.60',
		Digest::MD5			=> 0,
		Email::Sender::Simple	=> 0,
		Email::Sender::Transport::SMTP	=> 0,
		Encode				=> 0,
		File::Basename			=> 0,
		File::Copy			=> 0,
		File::Path			=> 0,
		List::MoreUtils		=> 0,
		List::Util			=> 0,
		Math::Round			=> '0.06',
		Net::FTP				=> 0,
		overload				=> 0,
		Scalar::Util			=> 0,
		Spreadsheet::WriteExcel 	=>'1.00',
		Sys::Hostname			=> 0,
		Roman				=> 0,
		Term::ReadKey			=> 0,
		Text::CSV				=>'1.20',
		XML::LibXML			=>'1.70',
		XML::XPath			=>'1.13',
		XML::Writer			=> 0
	},
	AUTHOR	=> 'oEdtk group <oedtk@free.fr>',
	dist		=> {
		COMPRESS				=> 'gzip -9',
		SUFFIX				=> '.gz',
	},
);
