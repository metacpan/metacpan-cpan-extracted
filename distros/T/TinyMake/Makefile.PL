use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'TinyMake',
    'VERSION_FROM'	=> 'TinyMake.pm', # finds $VERSION
    'PREREQ_PM'		=> {File::Find => '1.04'}, 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'TinyMake.pm', # retrieve abstract from module
       AUTHOR     => 'Walter Higgins <walterh@rocketmail.com>') : ()),
);
