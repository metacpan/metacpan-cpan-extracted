use strict;
use warnings;
use ExtUtils::MakeMaker;
use 5.009_003;

WriteMakefile(
    NAME          => 'pragma',
    AUTHOR        => 'Joshua ben Jore <jjore@cpan.org>',
    VERSION_FROM  => 'lib/pragma.pm',
    ABSTRACT_FROM => 'lib/pragma.pm',
    PREREQ_PM     => {},
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'pragma-*' },
);
