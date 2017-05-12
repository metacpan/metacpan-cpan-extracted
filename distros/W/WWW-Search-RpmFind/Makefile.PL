use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'WWW::Search::RpmFind',
    'VERSION_FROM'	=> 'RpmFind.pm', # finds $VERSION
    'PREREQ_PM'		=> {WWW::Search => 2.0}, # e.g., Module::Name => 1.1
    'EXE_FILES'         => [ 'rpmfind' ],
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'RpmFind.pm', # retrieve abstract from module
       AUTHOR     => 'Alain BARBET <alian@alianwebserver.com>') : ()),
);
