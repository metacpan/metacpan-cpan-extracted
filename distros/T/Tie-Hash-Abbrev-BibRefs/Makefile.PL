use 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Tie::Hash::Abbrev::BibRefs',
    VERSION_FROM => 'lib/Tie/Hash/Abbrev/BibRefs.pm',
    AUTHOR       => 'Martin H. Sluka <martin@sluka.de>',
    # Would like to use "ABSTRACT_FROM => 'lib/Tie/Hash/Abbrev/BibRefs.pm'",
    # but this wouldn't work for Perl 5.005_03 (and assumedly earlier versions)
    # due to a missing /g switch in ExtUtils::MM_Unix.pm's ->parse_abstract()
    ABSTRACT     => 'match bibliographic references to the original titles',
    PREREQ_PM    => { 'Test::More' => 0 }
);
