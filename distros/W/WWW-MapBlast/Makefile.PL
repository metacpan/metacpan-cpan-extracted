use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'WWW::MapBlast',
    'VERSION_FROM'	=> 'MapBlast.pm', # finds $VERSION
    'PREREQ_PM'		=> {LWP::UserAgent=>0.1,HTTP::Request=>0.1,HTML::TokeParser=>0.1,}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'MapBlast.pm', # retrieve abstract from module
       AUTHOR     => 'Lee GOddard <lgoddard@CPAN.org>') : ()),
);


