use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'VMPS::Server',
    AUTHOR              => 'kevin brintnall <kbrint@rufus.net>',
    VERSION_FROM        => 'lib/VMPS/Server.pm',
    ABSTRACT_FROM       => 'lib/VMPS/Server.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Net::Server::PreFork' => 0,
        'Net::MAC' => 0,
        'Storable' => 0,
        'Cwd' => 0,
        'File::Basename' => 0,
        'File::Slurp' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'VMPS-*' },
    (MM->can('signature_target') ? (SIGN => 1) : ()),
);
