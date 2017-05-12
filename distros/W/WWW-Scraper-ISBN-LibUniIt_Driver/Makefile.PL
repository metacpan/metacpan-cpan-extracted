use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'WWW::Scraper::ISBN::LibUniIt_Driver',
    'VERSION_FROM'	=> 'LibUniIt_Driver.pm', # finds $VERSION
    'PREREQ_PM'		=> { 
			LWP::UserAgent => 2.0,
			HTML::Entities => 1.32,
			WWW::Scraper::ISBN::Driver => 0.15  }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
       (AUTHOR     => 'Angelo Lucia <angelo.lucia@email.it>') : ()),
);
