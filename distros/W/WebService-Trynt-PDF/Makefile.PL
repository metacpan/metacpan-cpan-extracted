use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::Trynt::PDF',
    AUTHOR              => 'Manu <<manu@bjornoya.net>>',
    VERSION_FROM        => 'lib/WebService/Trynt/PDF.pm',
    ABSTRACT_FROM       => 'lib/WebService/Trynt/PDF.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'LWP::UserAgent' => 0,
        'URI' => 0,
        'File::Copy' => 0,
        'File::Temp' => 0,
        'XML::Simple' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-Trynt-PDF-*' },
);
