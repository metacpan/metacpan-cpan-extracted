use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Verilog::Readmem',
    AUTHOR              => 'Gene Sullivan <gsullivan@cpan.org>',
    VERSION_FROM        => 'lib/Verilog/Readmem.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Verilog-Readmem-*' },
);
