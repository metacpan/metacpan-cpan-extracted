use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Text::Amuse::Preprocessor',
    AUTHOR           => q{Marco Pessotto <melmothx@gmail.com>},
    VERSION_FROM     => 'lib/Text/Amuse/Preprocessor.pm',
    ABSTRACT_FROM    => 'lib/Text/Amuse/Preprocessor.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'IO::HTML' => 1,
        'HTML::PullParser' => 0,
        'Text::Amuse' => '0.95',
        'Pod::Simple::Wiki' => '0.19',
    },
    EXE_FILES => [
        'bin/muse-rearrange-footnotes.pl',
        'bin/muse-check-footnotes.pl',
        'bin/html-to-muse.pl',
        'bin/pod-to-muse.pl',
        'bin/muse-preprocessor.pl',
       ],
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Text-Amuse-Preprocessor-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/melmothx/text-amuse-preprocessor',
           },
    },
);

# Local Variables:
# cperl-indent-parens-as-block: t
# End:
