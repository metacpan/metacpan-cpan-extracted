use strict;
use warnings;
use ExtUtils::MakeMaker;

# CPAN distribution metadata for Voxgig::Struct.
#
# NOTE: `perl Makefile.PL` (run by ExtUtils::MakeMaker) GENERATES a file
# named `Makefile`, which would clobber this port's hand-written
# `perl/Makefile`. Never run it in place — the `publish` target in
# `perl/Makefile` copies the dist sources into a throwaway `.release/`
# directory and builds there instead.

WriteMakefile(
    NAME             => 'Voxgig::Struct',
    VERSION_FROM     => 'lib/Voxgig/Struct.pm',
    ABSTRACT         => 'Uniform JSON-shaped data structure manipulations — Perl port of @voxgig/struct',
    AUTHOR           => 'Voxgig',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.010',
);
