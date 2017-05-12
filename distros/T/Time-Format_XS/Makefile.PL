
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Time::Format_XS',
    'VERSION_FROM'	=> 'Format_XS.pm', # finds $VERSION
    'PREREQ_PM'		=> {Time::Format => '1.01'}, # e.g., Module::Name => 1.1
    'depend'            => {'Format_XS.c' => 'format.c'},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Format_XS.pm', # retrieve abstract from module
       AUTHOR     => 'Eric Roode <roode@cpan.org>') : ()),
);
