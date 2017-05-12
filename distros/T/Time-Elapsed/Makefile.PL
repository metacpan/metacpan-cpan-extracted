#!/usr/bin/env perl
# This file was created automatically
use 5.006;
use strict;
use warnings;
use lib qw( builder/lib );
use Build::Spec qw( mm_spec );
use ExtUtils::MakeMaker;

my %spec = mm_spec;



WriteMakefile(
    NAME         => $spec{module_name},
    VERSION_FROM => $spec{VERSION_FROM},
    PREREQ_PM    => $spec{PREREQ_PM},
    PL_FILES     => {},
    ($] >= 5.005 ? (
    AUTHOR       => $spec{dist_author},
    ABSTRACT     => $spec{ABSTRACT},
    EXE_FILES    => $spec{EXE_FILES},
    ) : ()),
);
