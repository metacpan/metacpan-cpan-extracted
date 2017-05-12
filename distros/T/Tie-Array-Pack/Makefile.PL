use warnings;
use strict;
use 5.008001;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Tie::Array::Pack',
    VERSION_FROM      => 'lib/Tie/Array/Pack.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tie/Array/Pack.pm', # retrieve abstract from module
       AUTHOR         => 'Dan Kogai <dankogai@dan.co.jp>') : ()),
);
