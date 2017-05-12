#
# Makefile.PL for Text::Fracture
# Distributable under the terms of GPLv2
#
# 2007-08-17, jw, V0.1  -- 
# 
# CFLAGS come from from /usr/lib/perl5/*/*/Config_heavy.pl
# edit there, if your compiler does not understand them.

use ExtUtils::MakeMaker;

WriteMakefile(
 NAME		=> 'Text::Fracture',
 VERSION_FROM	=> 'Fracture.pm',		# finds $VERSION
 PREREQ_PM      => {}, 				# e.g., Module::Name => 1.1
# ABSTRACT_FROM  => 'Fracture.pm', 		# retrieve abstract from module (since 5.004)
 AUTHOR         => 'Juergen Weigert <jw@suse.de>',
 LIBS		=> [''],			# e.g. '-lm'
 DEFINE		=> '',				# e.g. -DHAVE_FOO
# INC		=> '-O0 -g',				# e.g. -I/usr/include/foo
# OBJECT	=> '$(O_FILES)', 		# link all the C files too
 clean          => { FILES => ['Text-Fracture-*', '*.orig'] },
);

