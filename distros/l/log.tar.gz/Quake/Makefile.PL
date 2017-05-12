use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'              => 'Games::Quake::Log',
    'VERSION_FROM'      => 'Log.pm', # finds $VERSION
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM    => 'Log.pm', # retrieve abstract from module
       AUTHOR           => 'mwk <quake@stray-toaster.co.uk>') : ()),
);

