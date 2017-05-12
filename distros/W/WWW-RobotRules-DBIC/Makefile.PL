use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::RobotRules::DBIC',
    AUTHOR              => 'Tomohiro IKEBE <ikebe@shebang.jp>',
    VERSION_FROM        => 'lib/WWW/RobotRules/DBIC.pm',
    ABSTRACT_FROM       => 'lib/WWW/RobotRules/DBIC.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'DBIx::Class' => 0.07,
        'WWW::RobotRules' => 1.33,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-RobotRules-DBIC-*' },
);
