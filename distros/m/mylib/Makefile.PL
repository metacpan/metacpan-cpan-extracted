use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	   => 'mylib',
    VERSION_FROM => 'mylib.pm',
    PREREQ_PM => {
       FindBin => 0,
    },
    dist           => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
