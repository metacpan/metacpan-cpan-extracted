use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tk::GridEntry',
    'VERSION_FROM'	=> 'GridEntry.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # None
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'GridEntry.pm', # retrieve abstract from module
       AUTHOR     => 'Raman.P <raamanp@yahoo.co.in>') : ()),
);
