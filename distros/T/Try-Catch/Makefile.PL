use warnings;
use strict;

use 5.006;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Try::Catch',
    VERSION_FROM      => 'lib/Try/Catch.pm', # finds $VERSION
    PREREQ_PM         => {
        perl => '5.6.0', # Haven't tested earlier versions
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Try/Catch.pm', # retrieve abstract from module
       AUTHOR         => 'Mamod A. Mehyar <mamod.mehyar@gmail.com>') : ()),
    ## Add license (if EUMM support the LICENSE tag)
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'  => 'perl', ) : ()),
    ## Add source repo if EUMM supports META_MERGE
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/mamod/try-catch.git',
                 web  => 'https://github.com/mamod/try-catch',
             },
         }})
         : ()
    ),       
);
