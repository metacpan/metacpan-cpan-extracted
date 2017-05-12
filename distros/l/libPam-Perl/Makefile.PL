#!/usr/bin/perl

use warnings;
use strict;
use 5.010001;
use ExtUtils::MakeMaker;
use ExtUtils::Embed;
use Config;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

$Verbose=1;
unless(-f "/usr/lib/libpam.a"){
	warn "can't find /usr/lib/libpam.a";
	exit 0;
}
WriteMakefile(
	NAME		=> 'Authen::PAM::Module',
	VERSION_FROM	=> 'lib/Authen/PAM/Module.pm', # finds $VERSION
	BUILD_REQUIRES	=> {'Authen::PAM'=>0}, # e.g., Module::Name => 1.1
	($] >= 5.005 ?	## Add these new keywords supported since 5.005
		(ABSTRACT	=> 'Base module for writing Pam Modules in Perl',
		AUTHOR		=> 'Ben Hildred<bhildred@cpan.org>') : ()),
	LIBS		=> ['-lperl -ldl -lm -lpthread -lc -lcrypt'], # e.g., '-lm'
	DEFINE		=> '-D_REENTRANT -D_GNU_SOURCE -DDEBIAN -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64', # e.g., '-DHAVE_SOMETHING'
	INC		=> perl_inc(),
	#OBJECT		=> 'pam_perl.o const.o /usr/lib/libpam.a', # link all the C files too
	OBJECT		=> '$(O_FILES) /usr/lib/libpam.a', # link all the C files too
	DISTNAME	=> 'libPam-Perl',
	CCFLAGS		=> '-Wall -Wextra -fno-strict-aliasing -pipe -fstack-protector',
	LDFLAGS		=> '-Wl,-E',
#	PERL_MALLOC_OK	=> 1,
	depend		=> {
#		'$(FIRST_MAKEFILE)' => '$(VERSION_FROM)',
		'Module.c'	=> 'Module.xs const-xs.inc const.xs.inc',
		'Module.o'	=> 'Module.c const-c.inc const.h',
		'const.o'	=> 'const.c const.h const.c.inc',
		'pam_perl.o'	=> 'pam_perl.c const.h',
		'const.h'	=> 'const.pl',
	}
);
#sub MY::top_targets {
#'
#';
#}
sub MY::postamble {
'

const.h : const.pl
	./const.pl

const.c.inc : const.pl
	./const.pl

const.xs.inc : const.pl Local/ExtUtils/Constant.pm 
	./const.pl

const-xs.inc : const.pl Local/ExtUtils/Constant.pm 
	./const.pl

const-c.inc : const.pl Local/ExtUtils/Constant.pm 
	./const.pl
';
}
#pam_perl.so : pam_module.o perlxsi.o Module.o
#	$(LD) $(LDFLAGS) -o perl_module.so pam_module.o perlxsi.o Module.o 
#
