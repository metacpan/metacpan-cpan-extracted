use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'VKontakte::API',
    AUTHOR              => q{Anastasiya Deeva <support@creograf.ru>},
    VERSION_FROM        => 'lib/VKontakte/API.pm',
    ABSTRACT_FROM       => 'lib/VKontakte/API.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Digest::MD5' => 0,
		'WWW::Mechanize' => 0,
		'JSON'=>0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'VKontakte-API-*' },
);
