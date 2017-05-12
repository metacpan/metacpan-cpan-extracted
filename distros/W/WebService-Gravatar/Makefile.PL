use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::Gravatar',
    AUTHOR              => 'Michal Wojciechowski <odyniec@cpan.org>',
    VERSION_FROM        => 'lib/WebService/Gravatar.pm',
    ABSTRACT_FROM       => 'lib/WebService/Gravatar.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'RPC::XML::Client' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-Gravatar-*' },
);
