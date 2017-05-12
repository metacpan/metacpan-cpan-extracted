use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'typesafety',
    'VERSION_FROM'	=> 'typesafety.pm', # finds $VERSION
    'PREREQ_PM'		=> {'B::Generate' => 1.0}, # e.g., Module::Name => 1.1
    'PREREQ_FATAL'      => 1,
    'ABSTRACT'          => 'typesafety.pm - compile-time type usage static analysis',
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
       (AUTHOR     => 'Scott Walters <scott@slowass.net>') : ()),
);

# no, it doesn't, not from this .pm anyway
#      (ABSTRACT_FROM => 'typesafety.pm', # retrieve abstract from module 
