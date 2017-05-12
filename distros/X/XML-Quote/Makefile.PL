#!/usr/bin/perl
use ExtUtils::MakeMaker;
# $Version: release/perl/base/XML-Quote/Makefile.PL,v 1.2 2003/01/24 13:41:54 godegisel Exp $

WriteMakefile(
    'NAME'		=> 'XML::Quote',
    'VERSION_FROM'	=> 'Quote.pm',
    'PREREQ_PM'		=> {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'Quote.pm',
       AUTHOR     => 'Sergey Skvortsov <skv@protey.ru>') : ()),
    'LIBS'		=> [''],
    'DEFINE'		=> '',
    'INC'		=> '',
);
