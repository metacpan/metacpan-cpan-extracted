#!perl
#===============================================================================
#
# Makefile.PL
#
# DESCRIPTION
#   Makefile creation script.
#
# COPYRIGHT
#   Copyright (C) 2014-2015, 2020 Steve Hay.  All rights reserved.
#
# LICENCE
#   This script is free software; you can redistribute it and/or modify it under
#   the same terms as Perl itself, i.e. under the terms of either the GNU
#   General Public License or the Artistic License, as specified in the LICENCE
#   file.
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
                    web  => 'https://github.com/steve-m-hay/XML-Encoding'
                }
            },

            optional_features => {
                changestest => {
                    description => 'Changes testing',
                    prereqs => {
                        test => {
                            requires => {
                                'Test::CPAN::Changes' => '0'
                            }
                        }
                    }
                },

                critictest => {
                    description => 'Perl::Critic testing',
                    prereqs => {
                        test => {
                            requires => {
                                'Test::Perl::Critic' => '0'
                            }
                        }
                    }
                },

                podtest => {
                    description => 'POD testing',
                    prereqs => {
                        test => {
                            requires => {
                                'Test::Pod' => '1.00'
                            }
                        }
                    }
                },

                podcoveragetest => {
                    description => 'POD coverage testing',
                    prereqs => {
                        test => {
                            requires => {
                                'Test::Pod::Coverage' => '0.08'
                            }
                        }
                    }
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
            'Test::More' => '0'
        },

        PREREQ_PM => {
            'XML::Parser' => '2.18',
            'fields'      => '0',
            'integer'     => '0',
            'strict'      => '0',
            'warnings'    => '0'
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
