use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'TiddlyWeb::Wikrad',
    AUTHOR              => 'Chris Dent <cdent@peermore.com>',
    VERSION_FROM        => 'lib/TiddlyWeb/Wikrad.pm',
    ABSTRACT_FROM       => 'lib/TiddlyWeb/Wikrad.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Curses::UI'    => '0.95',
        'JSON'          => '0',
        'JSON::XS'      => '0',
        'Class::Field'  => '0',
        'Readonly'      => '0',
        'URI'           => '0',
        'LWP::UserAgent' => '0',
        'YAML'          => '0',
    },
    EXE_FILES           => ['bin/twikrad'],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
