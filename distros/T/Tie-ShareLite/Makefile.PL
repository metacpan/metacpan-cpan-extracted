use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tie::ShareLite',
    'VERSION_FROM'	=> 'ShareLite.pm', # finds $VERSION
    'PREREQ_PM'		=> {'IPC::ShareLite' => 0.08}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'ShareLite.pm', # retrieve abstract from module
       AUTHOR     => 'Nathan Shafer <nate-tiesharelite@seekio.com>') : ()),
);
