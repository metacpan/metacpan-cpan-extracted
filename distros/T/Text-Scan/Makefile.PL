use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::Scan',
    VERSION_FROM        => 'Scan.pm',
    DEFINE              => '',
    OBJECT              => '$(O_FILES)',
    OPTIMIZE            => ' ',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-Scan-*' },
);

