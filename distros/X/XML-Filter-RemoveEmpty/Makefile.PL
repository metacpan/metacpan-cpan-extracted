use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XML::Filter::RemoveEmpty',
    AUTHOR              => 'Darren Kulp <darren@kulp.ch>',
    VERSION_FROM        => 'lib/XML/Filter/RemoveEmpty.pm',
    ABSTRACT_FROM       => 'lib/XML/Filter/RemoveEmpty.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Alias' => 0,
        'Test::More' => 0,
        'Text::Trim' => 0,
		'XML::Filter::BufferText' => 0,
        'XML::SAX::Base' => 0,
        'enum' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XML-Filter-RemoveEmpty-*' },
);
