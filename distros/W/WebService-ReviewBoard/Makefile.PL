use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::ReviewBoard',
    AUTHOR              => 'Jay Buffington <jaybuffington@gmail.com>',
    VERSION_FROM        => 'lib/WebService/ReviewBoard.pm',
    ABSTRACT_FROM       => 'lib/WebService/ReviewBoard.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'          => 0,
        'Test::Exception'     => 0,
        'Test::Pod'           => 0,
        'Test::Pod::Coverage' => 0,
        'Test::Perl::Critic'  => 0,
        'version'       => 0,
        'YAML::Syck'    => 0,
        'Data::Dumper'  => 0,
        'Log::Log4perl' => 0,
        'Bundle::LWP'   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-ReviewBoard-*' },
);
