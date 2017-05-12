use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Umask::Local',
    AUTHOR              => q{James Rouzier <rouzier@gmail.com>},
    VERSION_FROM        => 'lib/Umask/Local.pm',
    ABSTRACT_FROM       => 'lib/Umask/Local.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Umask-Local-*' },
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (
        META_MERGE => {
            resources => {
                repository  => 'http://github.com/rouzier/Umask-Local',
            },
    }) : (),
);
