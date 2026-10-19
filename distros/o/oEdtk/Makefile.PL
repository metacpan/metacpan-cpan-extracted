#	Makefile.PL -- Makefile template for oEdtk.
#	This file is part of the "oEdtk" module package.
#
#	SEE README FILE
#	*******************************************************************
#	These modules are under the Artistic License 2.0 (see COPYING file)
#	You can use oEdtk as is without any warranty.
#
#	Copyright (c) 2005-2026  David AUNAY - GJ CHAILLOU DOMINGO
#
#	See COPYRIGHT section in oEdtk.pm for usage and distribution rights.
use POSIX;


BEGIN {
    require 5.028;
}


# load module
use ExtUtils::MakeMaker 6.64;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
# to install pre requisite libxml : perl Makefile.PL LIBS='-L/usr/lib' INC='-I/usr/include/libxml2'
# 	depending on your lib path
# It's easier to install libxml with system package manager (see README file)


# write makefile
WriteMakefile(
	# be careful at this level perl version are odd V5.10 should be defined as 5.010 ...
	MIN_PERL_VERSION	=> 5.028,
	LICENSE 			=> 'artistic_2',
	NAME				=> 'oEdtk',
	VERSION_FROM		=> 'lib/oEdtk.pm',
	# The companion oEUser distributions now live inside this repository.
	# ExtUtils::MM_Unix::init_dirscan auto-detects every immediate
	# subdirectory holding a Makefile.PL and recurses into it; oEdtk ships on
	# its own, so recursion is off. (oEUser-M/ is read-only, recursion would
	# die there.)
	DIR					=> [],
	PREREQ_PM			=> {
		YAML					=> 0,
		CPAN::DistnameInfo		=> 0,
		Archive::Zip			=> 0,
		charnames				=> 0,
		Config::IniFiles		=>'2.30',
		Cwd						=> 0,
		Data::Dumper			=> 0,
		Date::Calc				=> 0,
		Digest::MD5				=> 0,
		Email::Sender::Simple	=> 0,
		Email::Sender::Transport::SMTP	=> 0,
		Encode					=> 0,
		File::Basename			=> 0,
		File::Copy				=> 0,
		File::Path				=> 0,
		Image::Size				=> 0,
		JSON					=> 0,
		List::MoreUtils			=> 0,
		List::Util				=> 0,
		Log::Log4perl			=> 0,
		Math::Round				=> '0.06',
		Net::FTP				=> 0,
		overload				=> 0,
		PDF::Create				=> 0,
		Roman					=> 0,
		Scalar::Util			=> 0,
		Spreadsheet::WriteExcel	=>'1.00',
		Sys::Hostname			=> 0,
		Term::ReadKey			=> 0,
		Text::CSV				=>'1.20',
		DBI						=>'1.60',
		#DBD::Oracle			=> 0,
		#DBD::mysql				=> 0, 	# see DBD::mysql::INSTALL - How to install and configure DBD::mysql
		#DBD::Pg				=> 0,
		DBD::SQLite				=> 0,
		DBD::Excel				=> 0,
		XML::LibXML				=>'1.70',
		XML::Simple				=> 0,
		XML::XPath				=>'1.13',
		XML::Writer				=> 0,
		# Dependencies actually used by the 0.8032 fork (S10); merged here as the
		# fork code lands. The S10 gate kept them all as hard requirements.
		Data::UUID			=> 0,
		File::Slurp			=> 0,
		IPC::Run3			=> 0,
		JSON::PP			=> 0,
		Readonly			=> 0,
		Regexp::Common			=> 0,
		Term::ANSIColor			=> 0,
		Text::CSV_XS			=> 0,
		Time::HiRes			=> 0,
		Try::Tiny			=> 0,
		YAML::Tiny			=> 0,
		HTTP::Request			=> 0,
		HTTP::Request::Common	=> 0,
		HTTP::Status			=> 0,
		IO::Socket::SSL			=> 0,
		LWP::UserAgent			=> 0,
		PDF::Tk				=> 0,
		Text::QRCode			=> 0,
		# CGI front-end, loaded by the shipped lib/oEdtk/lib/cgi-bin/*.cgi at
		# the top level, so a hard requirement (never a recommends).
		CGI				=> 0,
		CGI::FormBuilder		=> 0,
	},
	TEST_REQUIRES		=> {
		DBD::mysql			=> 0,
		DBD::Pg				=> 0,
		IPC::Run3			=> 0,
		Perl::Critic			=> 0,
		Perl::Tidy			=> 0,
		Test::Fake::HTTPD		=> 0,
		Test::Fatal			=> 0,
		Test::MockModule		=> 0,
		Test::More			=> '1.302'
	},
	META_MERGE		=> {
		'meta-spec'	=> { version => 2 },
		# Optional runtime database drivers: installed by default (a plain
		# install pulls the driver of the engine in use) but never mandatory.
		# DBD::Oracle is left out: it needs the Oracle client to build.
		prereqs		=> {
			runtime	=> {
				recommends	=> {
					'DBD::Pg'	=> 0,
					'DBD::mysql'	=> 0,
				},
			},
		},
	},
	AUTHOR	=> 'oEdtk group <oedtk@free.fr>',
	dist		=> {
		COMPRESS				=> 'gzip -9',
		SUFFIX					=> '.gz',
	},
);
