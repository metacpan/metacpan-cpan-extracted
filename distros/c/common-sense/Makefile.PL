use ExtUtils::MakeMaker;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text sense.pod | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME        => "common::sense",
    VERSION_FROM => "sense.pm.PL",
    PM          => {
       "sense.pm"  => '$(INST_ARCHLIB)/common/sense.pm',
       "sense.pod" => '$(INST_LIB)/common/sense.pod',
    },
    clean       => { FILES => "sense.pm" },
);

