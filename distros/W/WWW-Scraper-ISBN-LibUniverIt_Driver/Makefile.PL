use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Scraper::ISBN::LibUniverIt_Driver',
    AUTHOR              => 'Marco Ghezzi <marcog@gmail.com>',
    VERSION_FROM        => 'lib/WWW/Scraper/ISBN/LibUniverIt.pm',
    PREREQ_PM	=> { 
			LWP::UserAgent => 2.0,
			HTML::Entities => 1.32,
			WWW::Scraper::ISBN::Driver => 0.15,
			WWW::Scraper::ISBN			=> 0.25,  
			},
	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean               => { FILES => 'WWW-Scraper-ISBN-LibUniverIt-Driver-*' },
);
