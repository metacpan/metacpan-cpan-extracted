#!/usr/bin/perl

# Creation date: 2005-04-24 11:29:18
# Authors: Don
# Change log:
# $Id: Makefile.PL,v 1.4 2008/12/02 10:30:15 don Exp $

use strict;

# main
{
    use ExtUtils::MakeMaker;

    WriteMakefile(
                  NAME => 'XML::Parser::Wrapper',
                  DISTNAME => 'XML-Parser-Wrapper',
                  VERSION_FROM => 'lib/XML/Parser/Wrapper.pm',
                  ABSTRACT => 'Simple object wrapper around XML::Parser',
                  AUTHOR => 'DON OWENS <don@regexguy.com>',
                  PM => { 'lib/XML/Parser/Wrapper.pm' => '$(INST_LIBDIR)/Wrapper.pm',
                          'lib/XML/Parser/Wrapper/SAXHandler.pm' => '$(INST_LIBDIR)/Wrapper/SAXHandler.pm',
                          'lib/XML/Parser/Wrapper/Changes.pm' => '$(INST_LIBDIR)/Wrapper/Changes.pm',
                        },
                  dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                            ZIP => '/usr/bin/zip', ZIPFLAGS => '-rl',
                          },
                  DIR => [],
                  EXE_FILES => [],
                  PREREQ_PM => { 'XML::Parser' => 0, 'Test::More' => 0, 'XML::SAX::Base' => 0 },
                 );

}

exit 0;

###############################################################################
# Subroutines

