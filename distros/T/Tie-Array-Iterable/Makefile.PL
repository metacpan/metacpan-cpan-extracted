use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tie::Array::Iterable',
    'VERSION_FROM'	=> 'Iterable.pm', # finds $VERSION
    'PREREQ_PM'		=> {Test::More => 0.33}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Iterable.pm', # retrieve abstract from module
       AUTHOR     => 'Michael K. Neylon <mneylon-pm@masemware.com>') : ()),
);
