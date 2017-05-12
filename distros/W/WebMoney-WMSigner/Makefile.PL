#!/usr/bin/perl -w

use ExtUtils::MakeMaker;

$CC = 'g++';

WriteMakefile(
    'NAME'		=> 'WebMoney::WMSigner',
    'VERSION_FROM'	=> 'WMSigner.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'WMSigner.pm', # retrieve abstract from module
       AUTHOR     => 'Walery Studennikov <despair@cpan.org>') : ()),
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    'OPTIMIZE'		=> '-g',
    'CC'		=> $CC,
    'LD'		=> '$(CC)',
    'INC'		=> '', # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    'OBJECT'		=> '$(O_FILES)', # link all the C files too
    'XSOPT'		=> '-C++',
);
