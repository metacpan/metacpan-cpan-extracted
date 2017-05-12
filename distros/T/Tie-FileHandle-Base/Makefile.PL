use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tie::FileHandle::Base',
    'VERSION_FROM'	=> 'Base.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Base.pm', # retrieve abstract from module
       AUTHOR     => 'Robby Walker <robwalker@cpan.org>') : ()),
);
