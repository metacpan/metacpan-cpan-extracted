#!perl
#===============================================================================
#
# Makefile.PL
#
# DESCRIPTION
#   Makefile creation script.
#
# COPYRIGHT
#   Copyright (C) 2015, 2020 Steve Hay.  All rights reserved.
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

use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker qw(WriteMakefile);

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    WriteMakefile(
        NAME          => 'Text::Balanced',
        ABSTRACT_FROM => 'lib/Text/Balanced.pm',
        AUTHOR        => 'Damian Conway <damian@conway.org>, Adam Kennedy <adamk@cpan.org>, Steve Hay <shay@cpan.org>',
        LICENSE       => 'perl_5',
        VERSION_FROM  => 'lib/Text/Balanced.pm',

        META_MERGE => {
            'meta-spec' => {
                version => 2
            },

            resources => {
                repository => {
                    type => 'git',
                    web  => 'https://github.com/steve-m-hay/Text-Balanced'
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

                metatest => {
                    description => 'META testing',
                    prereqs => {
                        test => {
                            requires => {
                                'Test::CPAN::Meta' => '0.12'
                            }
                        }
                    }
                },

                pmvtest => {
                    description => 'Perl minimum version testing',
                    prereqs => {
                        test => {
                            requires => {
                                'Perl::MinimumVersion' => '1.20',
                                'Test::MinimumVersion' => '0.101082'
                            }
                        }
                    }
                },

                podtest => {
                    description => 'POD testing',
                    prereqs => {
                        test => {
                            requires => {
                                'Pod::Simple' => '3.07',
                                'Test::Pod'   => '1.26'
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
            'Test::More' => '0.88', # done_testing
            'vars'       => '0'
        },

        PREREQ_PM => {
            'Carp'       => '0',
            'Exporter'   => '0',
            'overload'   => '0',
            'strict'     => '0',
            'vars'       => '0'
        },

        INSTALLDIRS => ($] < 5.011 ? 'perl' : 'site'),

        dist => {
            PREOP   => 'find $(DISTVNAME) -type d -print|xargs chmod 0755 && ' .
                       'find $(DISTVNAME) -type f -print|xargs chmod 0644',
            TO_UNIX => 'find $(DISTVNAME) -type f -print|xargs dos2unix'
        }
    );
}

#===============================================================================
