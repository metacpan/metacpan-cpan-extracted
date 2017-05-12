use 5.010; use warnings; use strict;
use ExtUtils::MakeMaker 6.42 'WriteMakefile';

WriteMakefile(
    NAME                => 'Text::Glob::DWIW',
    AUTHOR              => 'Josef <josef@cpan.org>',
    VERSION_FROM        => 'lib/Text/Glob/DWIW.pm',
    ABSTRACT_FROM       => 'lib/Text/Glob/DWIW.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    CONFIGURE_REQUIRES  => { 'ExtUtils::MakeMaker' => 6.42 },
    # ^- at 6.52 but perl5.10=6.42, and if we force then to -v- 6.56 (with perl5.12)
    # v- not before EUMM 6.5503, but most likely most modules are installed anyway,
    BUILD_REQUIRES => {                    #\ or extra tests for skipping in t/*.t
        'Test::More'    => 0.92, Config => 0, 'Test::NoWarnings' => 0,
        'Test::Exception' => 0,  'Test::Pod' => 1.41, if => 0.05,
    },
    PREREQ_PM => {
        'Scalar::Util'  => 0, 'List::Util'  => 0, 'Hash::Util'  => 0,
        overload => 0, overloading => 0, Exporter => 5.57, Carp => 0, re => 0,
        parent => 0.221, warnings => 0, # 'Pod::Man' => 2.23
    },
    MIN_PERL_VERSION    => '5.010',
    clean               => { FILES => 'Text-Glob-DWIW-*' },
    # v- needs 6.45 but that info only of interest for PAUSE, not needed for build
    #    (old stuff > live with warnings)
    META_MERGE => { no_index =>
                    { directory => ['examples'],
                      namespace => ['Text::Glob::DWIW::'],
                      package   => [qw'_19TGD_tiefun Text::Glob::DWIW::Result'] },
                    keywords =>  [qw'glob globbing global-replacement
                                     wildcard expansion expand text string'] },
);
