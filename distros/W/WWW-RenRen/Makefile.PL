use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::RenRen',
    AUTHOR              => q{Aaron Lewis <the.warl0ck.1989@gmail.com>},
    VERSION_FROM        => 'lib/WWW/RenRen.pm',
    ABSTRACT            => 'renren.com funcality helper module',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-RenRen-*' },
);
