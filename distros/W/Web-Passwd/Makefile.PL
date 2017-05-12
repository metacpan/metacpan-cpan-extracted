use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Web::Passwd',
    AUTHOR              => 'Evan Kaufman <evank@cpan.org>',
    VERSION_FROM        => 'lib/Web/Passwd.pm',
    ABSTRACT_FROM       => 'lib/Web/Passwd.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'CGI::Application' => 0,
        'Config::Tiny' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Web-Passwd-*' },
);
