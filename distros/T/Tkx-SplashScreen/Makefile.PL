use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tkx::SplashScreen',
    AUTHOR              => q{Alexander Nusov <alexander.nusov+cpan@gmail.com>},
    VERSION_FROM        => 'lib/Tkx/SplashScreen.pm',
    ABSTRACT_FROM       => 'lib/Tkx/SplashScreen.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'Tkx' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tkx-SplashScreen-*' },
);
