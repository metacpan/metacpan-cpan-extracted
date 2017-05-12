use 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Tie::Hash::Array',
    VERSION_FROM => 'lib/Tie/Hash/Array.pm',
    AUTHOR       => 'Martin H. Sluka <perl@sluka.de>',
    # Would like to use "ABSTRACT_FROM => 'lib/Tie/Hash/Array.pm'",
    # but this wouldn't work for Perl 5.005_03 (and assumedly earlier versions)
    # due to a missing /g switch in ExtUtils::MM_Unix.pm's ->parse_abstract()
    ABSTRACT     => 'a hash which is internally implemented as a sorted array',
    PREREQ_PM    => { 'Text::Abbrev' => 0,
                      'Test::More'   => 0 },
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean        => { FILES => 'Tie-Hash-Array-*' },
);
