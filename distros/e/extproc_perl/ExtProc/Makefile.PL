# $Id: Makefile.PL,v 1.2 2004/01/29 20:29:45 jeff Exp $

use ExtUtils::MakeMaker;

my $oh = $ENV{'ORACLE_HOME'};

WriteMakefile(
	'NAME'		=> 'ExtProc',
	'VERSION_FROM'	=> 'ExtProc.pm',
	'PREREQ_PM'	=> {},
	'LIBS'		=> [''],
	'DEFINE'	=> '',
	'INC'		=> "-I.. -I$oh/rdbms/public -I$oh/rdbms/demo",
	'LINKTYPE'	=> 'dynamic',
);
