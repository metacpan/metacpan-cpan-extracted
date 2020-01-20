use ExtUtils::MakeMaker;

# We require PkgConfig available from YottaDB r1.24 on

sub pkgconfig ($)
{
  my $v = shift;
  my $cmd = "pkg-config --$v yottadb";
  my $r = `$cmd`;
  chomp $r;
  $r = undef if $r eq "";
  die "pkg-config error running: `$cmd`: $!" unless defined $r;
  $r;
}

my $libs = pkgconfig "libs";
my $cflags = pkgconfig "cflags";
my $ver = pkgconfig "modversion";

$ver =~ s/^r//;
$cflags .= " -DNO_CHILD_INIT" if $ver >= 1.24;


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
    PREREQ_PM         => {JSON => 2.90},
    ABSTRACT_FROM     => 'YottaDB.pm',
    AUTHOR            => 'Stefan Traby <stefan@hello-penguin.com>',
    LIBS              => [$libs],
    DEFINE            => '',
    INC               => "$cflags",
    EXE_FILES         => [ "bin/ydb_json_import" ],
    PM                => { 'YottaDB.pm' => '$(INST_LIBDIR)/YottaDB.pm',
                           'YottaDB/Tie.pm'     => '$(INST_LIBDIR)/YottaDB/Tie.pm',
                           'YottaDB/Lock.pm'     => '$(INST_LIBDIR)/YottaDB/Lock.pm',
                         },
);
