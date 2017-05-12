use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::YAWikiFormater',
    AUTHOR              => q{Marco Neves <perl-cpan@fwd.avidmind.net>},
    VERSION_FROM        => 'lib/Text/YAWikiFormater.pm',
    ABSTRACT_FROM       => 'lib/Text/YAWikiFormater.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'     => 0,
        JSON             => 0,
        'HTML::Entities' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-YAWikiFormater-*' },
);
