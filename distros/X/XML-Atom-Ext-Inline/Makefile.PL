use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XML::Atom::Ext::Inline',
    AUTHOR              => 'Dmitri Popov <operator@cv.dp-net.com>',
    VERSION_FROM        => 'lib/XML/Atom/Ext/Inline.pm',
    ABSTRACT_FROM       => 'lib/XML/Atom/Ext/Inline.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'XML::Atom' => 0,
    },
    META_MERGE      => {
        resources => {
            bugtracker  =>      'http://github.com/pin/xml-atom-ext-inline/issues',
            repository  =>      'git://github.com/pin/xml-atom-ext-inline.git',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XML-Atom-Ext-Inline-*' },
);
