use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XDI',
    AUTHOR              => q{Mark Horstmeier <solargroovey@gmail.com>},
    VERSION_FROM        => 'lib/XDI.pm',
    ABSTRACT_FROM       => 'lib/XDI.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'gpl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XDI-*' },
);
