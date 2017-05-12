use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WordPress::Plugin::WallFlower',
    AUTHOR              => q{C.J. Adams-Collier <cjac@colliertech.org>},
    VERSION_FROM        => 'lib/WordPress/Plugin/WallFlower.pm',
    ABSTRACT_FROM       => 'lib/WordPress/Plugin/WallFlower.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WordPress-Plugin-WallFlower-*' },
);
