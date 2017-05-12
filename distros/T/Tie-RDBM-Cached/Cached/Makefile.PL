use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tie::RDBM::Cached',
    'VERSION_FROM'	=> 'Cached.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        "Tie::RDBM" => 0,    
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Cached.pm', # retrieve abstract from module
       AUTHOR     => 'H Jackson <harry@hjackson.org>') : ()),
);
