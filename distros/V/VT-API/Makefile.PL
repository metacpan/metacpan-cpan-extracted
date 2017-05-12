use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'VT::API',
    AUTHOR              => q{Alexander Nusov <cpan@sancode.net>},
    VERSION_FROM        => 'lib/VT/API.pm',
    ABSTRACT_FROM       => 'lib/VT/API.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'LWP::UserAgent' => 0,
		'JSON' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'VT-API-*' },
);
