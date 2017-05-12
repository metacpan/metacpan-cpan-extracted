#!perl
#===============================================================================
#
# Makefile.PL
#
# DESCRIPTION
#   Makefile creation script.
#
# COPYRIGHT
#   Copyright (C) 2003-2008, 2012, 2014 Steve Hay.  All rights reserved.
#
# LICENCE
#   You may distribute under the terms of either the GNU General Public License
#   or the Artistic License, as specified in the LICENCE file.
#
#===============================================================================

use 5.008001;

use strict;
use warnings;

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
        NAME          => 'Win32::UTCFileTime',
        ABSTRACT_FROM => 'lib/Win32/UTCFileTime.pm',
        AUTHOR        => 'Steve Hay <shay@cpan.org>',
        LICENSE       => 'perl_5',
        VERSION_FROM  => 'lib/Win32/UTCFileTime.pm',

        META_MERGE => {
            'meta-spec' => {
                version => 2
            },

            resources => {
                repository => {
                    type => 'git',
                    url  => 'https://github.com/steve-m-hay/Win32-UTCFileTime.git'
                }
            },

            optional_features => {
                podtest => {
                    description => 'POD testing',
                    prereqs => {
                        test => {
                            requires => {
                                'Test::Pod' => '1.00'
                            }
                        }
                    }
                }
            }
        },

        MIN_PERL_VERSION => '5.008001',

        CONFIGURE_REQUIRES => {
            'ExtUtils::MakeMaker'   => '6.66',
            'File::Copy'            => '0',
            'File::Spec::Functions' => '0',
            'perl'                  => '5.008001',
            'strict'                => '0',
            'warnings'              => '0'
        },

        TEST_REQUIRES => {
            'Config'                => '0',
            'File::Spec::Functions' => '0',
            'Test::More'            => '0',
            'perl'                  => '5.008001',
            'strict'                => '0',
            'warnings'              => '0'
        },

        PREREQ_PM => {
            'Exporter' => '0',
            'XSLoader' => '0',
            'perl'     => '5.008001'
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

    if  (eval { require ExtUtils::Constant; 1 }) {
        ExtUtils::Constant::WriteConstants(
            NAME => 'Win32::UTCFileTime',

            NAMES => [ qw(
                SEM_FAILCRITICALERRORS
                SEM_NOGPFAULTERRORBOX
                SEM_NOALIGNMENTFAULTEXCEPT
                SEM_NOOPENFILEERRORBOX
            ) ],

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
