use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::Livedoor::SpamChampuru::DNSBL',
    AUTHOR              => 'Kensuke Kaneko <k-kaneko@livedoor.jp>',
    VERSION_FROM        => 'lib/WebService/Livedoor/SpamChampuru/DNSBL.pm',
    ABSTRACT_FROM       => 'lib/WebService/Livedoor/SpamChampuru/DNSBL.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Net::DNS' => 0,
        'IO::Select' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-Livedoor-SpamChampuru-DNSBL-*' },
);
