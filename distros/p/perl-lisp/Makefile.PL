require 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	 => 'perl-lisp',
    VERSION      => '0.06',
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
