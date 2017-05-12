use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'WWW::Search::RPMPbone',
    'VERSION_FROM'	=> 'RPMPbone.pm', # finds $VERSION
    'PREREQ_PM'		=> {WWW::Search => 2.0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'RPMPbone.pm', # retrieve abstract from module
       AUTHOR     => 'Alagarsamy <samy@cpan.org>') : ()),
);
