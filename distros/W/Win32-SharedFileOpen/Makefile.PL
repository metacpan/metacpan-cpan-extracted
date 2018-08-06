#!perl
#===============================================================================
#
# Makefile.PL
#
# DESCRIPTION
#   Makefile creation script.
#
# COPYRIGHT
#   Copyright (C) 2001-2008, 2012, 2014-2015 Steve Hay.  All rights reserved.
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

use Config qw(%Config);
use ExtUtils::MakeMaker 6.66;
use ExtUtils::MakeMaker qw(WriteMakefile);
use File::Copy qw(copy);
use File::Spec::Functions qw(catfile);

#===============================================================================
# INITIALIZATION
#===============================================================================

BEGIN {
    if ($^O ne 'MSWin32') {
        die qq{OS unsupported: This module requires a "native" } .
            qq{(i.e. non-Cygwin) Microsoft Windows platform.\n};
    }
}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    WriteMakefile(
        NAME          => 'Win32::SharedFileOpen',
        ABSTRACT_FROM => 'lib/Win32/SharedFileOpen.pm',
        AUTHOR        => 'Steve Hay <shay@cpan.org>',
        LICENSE       => 'perl_5',
        VERSION_FROM  => 'lib/Win32/SharedFileOpen.pm',

        META_MERGE => {
            'meta-spec' => {
                version => 2
            },

            no_index => {
                package => 'Win32::SharedFileOpen::_NaturalNumber'
            },

            resources => {
                repository => {
                    type => 'git',
                    url  => 'https://github.com/steve-m-hay/Win32-SharedFileOpen.git'
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
            'Config'                => '0',
            'ExtUtils::MakeMaker'   => '6.66',
            'File::Copy'            => '0',
            'File::Spec::Functions' => '0',
            'perl'                  => '5.008001',
            'strict'                => '0',
            'warnings'              => '0'
        },

        TEST_REQUIRES => {
            'FileHandle' => '0',
            'IO::File'   => '0',
            'IO::Handle' => '0',
            'Test::More' => '0'
        },

        PREREQ_PM => {
            'Carp'            => '0',
            'Config'          => '0',
            'Errno'           => '0',
            'Exporter'        => '0',
            'Symbol'          => '0',
            'Time::HiRes'     => '0',
            'Win32::WinError' => '0',
            'XSLoader'        => '0',
            'strict'          => '0',
            'warnings'        => '0'
        },

        clean => {
            FILES => 'const-*.inc'
        },

        dist => {
            PREOP   => 'find $(DISTVNAME) -type d -print|xargs chmod 0755 && ' .
                       'find $(DISTVNAME) -type f -print|xargs chmod 0644',
            TO_UNIX => 'find $(DISTVNAME) -type f -print|xargs unix2dos'
        }
    );

    if  (eval { require ExtUtils::Constant }) {
        my @oflags = qw(
            O_APPEND
            O_BINARY
            O_CREAT
            O_EXCL
            O_NOINHERIT
            O_RAW
            O_RDONLY
            O_RDWR
            O_TEXT
            O_TRUNC
            O_WRONLY
            S_IREAD
            S_IWRITE
            SH_DENYNO
            SH_DENYRD
            SH_DENYRW
            SH_DENYWR
        );

        # Borland C++ (as of 5.5.1) doesn't support the following flags, so
        # don't try to export them.
        if ($Config{cc} !~ /bcc32/io) {
            push @oflags, qw(
                O_RANDOM
                O_SEQUENTIAL
                O_SHORT_LIVED
                O_TEMPORARY
            );
        }

        ExtUtils::Constant::WriteConstants(
            NAME => 'Win32::SharedFileOpen',

            NAMES => [ {
                name => 'INFINITE',
                type => 'UV'
            },  @oflags ],

            DEFAULT_TYPE => 'IV',

            C_FILE => 'const-c.inc',

            XS_FILE => 'const-xs.inc'
        );
    }
    else {
        foreach my $file ('const-c.inc', 'const-xs.inc') {
            my $fallback_file = catfile('fallback', $file);
            copy($fallback_file, $file) or
                die "Can't copy '$fallback_file' to '$file': $!.\n";
        }
    }
}

#===============================================================================
