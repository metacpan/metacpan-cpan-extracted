use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'WWW::Blog::Identify',
    'VERSION_FROM'	=> 'Identify.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Identify.pm', # retrieve abstract from module
       AUTHOR     => 'Maciej Ceglowski <developer@ceglowski.com>') : ()),
);
