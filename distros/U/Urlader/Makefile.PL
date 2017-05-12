use ExtUtils::MakeMaker;

use 5.008;

if ((join ":", stat "urlader.c") eq (join ":", stat "Urlader.c")) {
   print <<EOF;

***
*** Non-POSIX filesystem detected, moved urlader.c to urlader-orig.c
***

EOF
   rename "urlader.c", "urlader-orig.c";
}

$LIBS = $^O eq "MSWin32" ? "-lshell32 -lshlwapi" : "";

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text Urlader.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    depend      => { "Urlader.c" => "urlib.h urlib.c liblzf/lzf_d.c liblzf/lzf_c_best.c" },
    NAME => "Urlader",
    VERSION_FROM => "Urlader.pm",
    EXE_FILES => ["bin/urlader-util"],
    LIBS => [$LIBS],
    PREREQ_PM => {
       common::sense => 0,
       Win32::Exe    => 0.17,
    },
);
