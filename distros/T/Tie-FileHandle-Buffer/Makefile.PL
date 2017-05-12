use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tie::FileHandle::Buffer',
    'VERSION_FROM'	=> 'Buffer.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'Tie::FileHandle::Base' => 0.1 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Buffer.pm', # retrieve abstract from module
       AUTHOR     => 'Robby Walker <robwalker@cpan.org>') : ()),
);
