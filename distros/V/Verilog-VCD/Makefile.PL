use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Verilog::VCD',
    AUTHOR              => 'Gene Sullivan <gsullivan@cpan.org>',
    VERSION_FROM        => 'lib/Verilog/VCD.pm',
    LICENSE             => 'perl',
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean               => { FILES => 'Verilog-VCD-*' },
);
