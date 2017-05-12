use strict;
use warnings;
use ExtUtils::MakeMaker;

die "Win32 is currently not supported due to timeouts in t/collapse.t\n"
  if $^O eq 'MSWin32';

WriteMakefile(
    NAME                => 'Tree::File',
    AUTHOR              => 'Ricardo Signes <rjbs@cpan.org>',
    VERSION_FROM        => 'lib/Tree/File.pm',
    ABSTRACT_FROM       => 'lib/Tree/File.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'YAML'       => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tree-File-* cover_db errors.err' },
);
