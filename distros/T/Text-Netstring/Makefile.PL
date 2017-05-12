use ExtUtils::MakeMaker;
# $Id: Makefile.PL,v 1.4 2006/11/17 16:03:34 james Exp $
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Text::Netstring',
    'VERSION_FROM' => 'Netstring.pm', # finds $VERSION
    'ABSTRACT_FROM' => 'Netstring.pm',
    'LICENSE' => 'perl',
    'dist'	=> { POSTOP=>'$(CHMOD) 444 $(DISTVNAME).tar$(SUFFIX)' },
);
