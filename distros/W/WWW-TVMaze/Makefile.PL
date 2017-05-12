use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::TVMaze',
    AUTHOR              => q{Bruno Martins <bscmartins@gmail.com>},
    VERSION_FROM        => 'lib/WWW/TVMaze.pm',
    ABSTRACT_FROM       => 'lib/WWW/TVMaze.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'Mouse' => 0,
		'LWP::UserAgent' => 0,
		'JSON::XS' => 0,
		'DateTime' => 0,
		'Params::Validate' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-TVMaze-*' },
);
