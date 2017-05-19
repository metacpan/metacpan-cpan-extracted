use 5.008;
use ExtUtils::MakeMaker;

use Config;

WriteMakefile(
    NAME              => 'Time::Local::TZ',
    VERSION_FROM      => 'lib/Time/Local/TZ.pm',
    PREREQ_PM         => {},
    ABSTRACT_FROM     => 'lib/Time/Local/TZ.pm',
    AUTHOR            => 'Sergey Panteleev <bambr@cpan.org>',
    LICENSE           => 'perl_5',
    CCFLAGS           => "$Config{ccflags} -std=gnu99",
    dist              => {
       PREOP          => 'pod2text lib/Time/Local/TZ.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS       => 'gzip -9v',
       SUFFIX         => '.gz',
    },
);
