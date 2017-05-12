use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Text::FixEOL',
    VERSION_FROM      => 'lib/Text/FixEOL.pm', 
    PREREQ_PM         => {
                         'Test::More'       => 0,
                        }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Text/FixEOL.pod', # retrieve abstract from module
       AUTHOR         => 'Benjamin Franz <snowhare@nihongo.org>') : ()),

       ($] >= 5.800 ?     ## Add these new keywords supported since 5.8
             (NO_META      => 1) : ()),

       PL_FILES       => {},
);
