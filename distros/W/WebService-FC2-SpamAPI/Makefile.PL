use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::FC2::SpamAPI',
    AUTHOR              => 'FUJIWARA Shunichiro <fujiwara@topicmaker.com>',
    VERSION_FROM        => 'lib/WebService/FC2/SpamAPI.pm',
    ABSTRACT_FROM       => 'lib/WebService/FC2/SpamAPI.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'            => 0,
        'URI::Fetch'            => 0,
        'URI'                   => 0,
        'URI::QueryParam'       => 0,
        'Class::Accessor::Fast' => 0,
        'Encode'                => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-FC2-SpamAPI-*' },
);
