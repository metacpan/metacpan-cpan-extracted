use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Twitter::Badge',
    AUTHOR              => q{Arul John <arul@cpan.org>},
    VERSION_FROM        => 'lib/Twitter/Badge.pm',
    ABSTRACT_FROM       => 'lib/Twitter/Badge.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'LWP::UserAgent'=> 5.8,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Twitter-Badge-*' },
);
