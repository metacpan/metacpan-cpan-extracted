use ExtUtils::MakeMaker;
use ExtUtils::PkgConfig;

# We require PkgConfig available from YottaDB r1.24 on

my $cflags = cflags ExtUtils::PkgConfig ("yottadb");
my $libs = libs ExtUtils::PkgConfig ("yottadb");

open my $out, ">", "gen-switch.h" or die "opening gen-switch.h: $!";

for my $i (1..35) {
        print $out "case $i: rc = ydb_lock_s(to,$i";
        for (my $j = 0; $j < $i; $j++) {
            print $out ",&varnames[$j], subs_used[$j], &subsarray[$j]"
        }
        print $out "); break;\n";
}

WriteMakefile(
    clean        => { FILES => "gen-switch.h"},
    dist         => {
                     PREOP      => 'pod2text YottaDB.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
                     COMPRESS   => 'gzip -9v',
                     SUFFIX     => '.gz',
                    },
    NAME              => 'YottaDB',
    VERSION_FROM      => 'YottaDB.pm',
    PREREQ_PM         => {'POSIX::AtFork' => 0.02, JSON => 2.90},
    ABSTRACT_FROM     => 'YottaDB.pm',
    AUTHOR            => 'Stefan Traby <stefan@hello-penguin.com>',
    LIBS              => [$libs],
    DEFINE            => '',
    INC               => "$cflags",
    EXE_FILES         => [ "bin/ydb_json_import" ],
    PM                => { 'YottaDB.pm' => '$(INST_LIBDIR)/YottaDB.pm',
                           'Tie.pm'     => '$(INST_LIBDIR)/YottaDB/Tie.pm',
                         },
);
