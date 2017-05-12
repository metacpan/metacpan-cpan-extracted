#!/usr/bin/perl -w
#$Id: Makefile.PL 427 2009-10-14 01:51:49Z gab $
use ExtUtils::MakeMaker;

WriteMakefile(
	ABSTRACT		=> 	'Perl implementation of the phonex algorithm',
	NAME			=>	'Text::Phonex',
	VERSION_FROM	=>	"lib/Text/Phonex.pm",
	AUTHOR			=>	'Gabriel Guillon <korsani(removeme)@free(removeme).fr(removeagain)>',
);
1;
