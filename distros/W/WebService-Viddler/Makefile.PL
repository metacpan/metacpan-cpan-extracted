use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::Viddler',
    AUTHOR              => q{Paul Weinstein <pdw@weinstein.org>},
    VERSION_FROM        => 'lib/WebService/Viddler.pm',
    ABSTRACT_FROM       => 'lib/WebService/Viddler.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-Viddler-*' },
);
