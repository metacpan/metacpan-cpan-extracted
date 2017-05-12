#!perl
#===============================================================================
#
# Makefile.PL
#
# DESCRIPTION
#   Makefile creation script.
#
# COPYRIGHT
#   Copyright (C) 2014 Steve Hay.  All rights reserved.
#
# LICENCE
#   You may distribute under the terms of either the GNU General Public License
#   or the Artistic License, as specified in the LICENCE file.
#
#===============================================================================

use 5.008001;

use strict;
use warnings;

use ExtUtils::MakeMaker 6.64;
use ExtUtils::MakeMaker qw(WriteMakefile);

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    WriteMakefile(
        NAME          => 'XML::Encoding',
        ABSTRACT_FROM => 'lib/XML/Encoding.pm',
        AUTHOR        => 'Clark Cooper <coopercc@netheaven.com>, Steve Hay <shay@cpan.org>',
        LICENSE       => 'perl_5',
        VERSION_FROM  => 'lib/XML/Encoding.pm',

        META_MERGE => {
            'meta-spec' => {
                version => 2
            },

            resources => {
                repository => {
                    type => 'git',
                    url  => 'https://github.com/steve-m-hay/XML-Encoding.git'
                }
            }
        },

        MIN_PERL_VERSION => '5.008001',

        CONFIGURE_REQUIRES => {
            'ExtUtils::MakeMaker' => '6.64',
            'perl'                => '5.008001',
            'strict'              => '0',
            'warnings'            => '0'
        },

        TEST_REQUIRES => {
            'Test::More' => '0',
            'perl'       => '5.008001',
            'strict'     => '0',
            'warnings'   => '0'
        },

        PREREQ_PM => {
            'XML::Parser' => '2.18',
            'fields'      => '0',
            'integer'     => '0',
            'perl'        => '5.008001',
            'strict'      => '0',
            'vars'        => '0'
        },

        EXE_FILES => [qw(
            bin/compile_encoding
            bin/make_encmap
        )],

        dist => {
            PREOP   => 'find $(DISTVNAME) -type d -print|xargs chmod 0755 && ' .
                       'find $(DISTVNAME) -type f -print|xargs chmod 0644 && ' .
                       'chmod 0755 $(DISTVNAME)/bin/*',
            TO_UNIX => 'find $(DISTVNAME) -type f -print|xargs dos2unix'
        }
    );
}

#===============================================================================
