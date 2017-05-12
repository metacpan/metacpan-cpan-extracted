use strict;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'Text::vFile::asData',
    AUTHOR        => 'Richard Clamp <richardc@unixbeard.net>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/Text/vFile/asData.pm',
    ABSTRACT_FROM => 'lib/Text/vFile/asData.pm',
    PREREQ_PM => {
        'Test::More' => '0.88',
        'Class::Accessor::Chained' => 0
    }
);
