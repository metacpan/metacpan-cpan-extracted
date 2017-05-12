#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;
use IO::File;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

if(my $BACK = IO::File->new('backends.pl','w+')) {
    if (eval {require YAML; 1;}) {
        print $BACK "sub test_stores {qw/YAML Storable/;} 1;\n";
    } else {
        warn "Tests for in situ YAML will be skipped as YAML is not installed";
        print $BACK "sub test_stores {qw/Storable/;} 1;\n";
    }
    $BACK->close;
}

my @exe;

if (eval {require Parse::RecDescent; 1;}) {
	push @exe, 'bin/VCShell';
} else {
    warn "Parse::RecDescent not available, so VCShell will not be installed";
}

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'VCS::Lite::Repository',
    VERSION_FROM        => 'lib/VCS/Lite/Repository.pm',
    ABSTRACT            => 'A minimal version control system - the repository',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'VCS::Lite'         => 0.05,
    	'Time::Piece'       => 0,
    	'Params::Validate'  => 0,

        # build/test prereqs
        'IO::File'          => '0',
        'Test::More'        => '0.70'

    },

    EXE_FILES		=> \@exe
);
