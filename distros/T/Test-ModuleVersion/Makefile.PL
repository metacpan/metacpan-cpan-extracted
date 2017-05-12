use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::ModuleVersion',
    AUTHOR              => q{Yuki Kimoto <kimoto.yuki@gmail.com>},
    VERSION_FROM        => 'lib/Test/ModuleVersion.pm',
    ABSTRACT_FROM       => 'lib/Test/ModuleVersion.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-ModuleVersion-*' },
);
