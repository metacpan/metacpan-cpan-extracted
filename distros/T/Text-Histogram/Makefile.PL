use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::Histogram',
    AUTHOR              => q{Marco Neves <neves@cpan.org>},
    VERSION_FROM        => 'lib/Text/Histogram.pm',
    ABSTRACT_FROM       => 'lib/Text/Histogram.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-Histogram-*' },
);
