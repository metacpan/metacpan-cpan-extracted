use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Yandex::BarTIC',
    AUTHOR              => q{Alex <alexbyk@cpan.org>},
    VERSION_FROM        => 'lib/WWW/Yandex/BarTIC.pm',
    ABSTRACT_FROM       => 'lib/WWW/Yandex/BarTIC.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'       => 0,
	'Carp' 		   => 0,
	'LWP::UserAgent'   => 0,
	'URI::Escape'      => 0,
	'Object::Accessor' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Yandex-BarTIC-*' },
);
