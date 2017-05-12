use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Wetware::llyrisWeb',
    'VERSION_FROM'	=> 'llyrisWeb.pm', # finds $VERSION
    'PREREQ_PM'		=> {'CGI' => '2.3' }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'llyrisWeb.pm', # retrieve abstract from module
       AUTHOR     => 'drieux just drieux <drieux@wetware.com>') : ()),
);
    #'PREREQ_PM'		=> {LMpath}, # e.g., Module::Name => 1.1
