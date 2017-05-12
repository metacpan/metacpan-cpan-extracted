use strict;
use warnings;
use 5.008;
use ExtUtils::MakeMaker;

if ($^O =~ m/^(?:mswin32|dos|macos|os2|cygwin|v[mo]s|riscos|amigaos|beos|mpeix)$/i) {
    die "NA: OS unsupported , lsof is not available for OS $^O, no point installing this module\n";
}

WriteMakefile(
    NAME                => 'Unix::Lsof',
    AUTHOR              => 'Marc Beyer <japh@tirwhan.org>',
    VERSION_FROM        => 'lib/Unix/Lsof.pm',
    ABSTRACT_FROM       => 'lib/Unix/Lsof.pm',
    PL_FILES            => {},
    PREREQ_PM => {
                  'Test::More' => 0,
                  'version'    => 0,
                  'IPC::Run3'  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Unix-Lsof-*' },
);
