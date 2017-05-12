use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Weather::NOAA::GFS',
    VERSION_FROM      => 'lib/Weather/NOAA/GFS.pm', # finds $VERSION
    PREREQ_PM         => {
    				'HTML::LinkExtractor'	=> '0',
    				'LWP::UserAgent'	=> '0',
				'Net::FTP'	=> '0',
				'Data::Dumper'	=> '0',
				'Time::Local'	=> '0',
				'Cwd'	=> '0',
			}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Weather/NOAA/GFS.pm', # retrieve abstract from module
       AUTHOR         => 'Lorenzo Becchi <lbecchi@cpan.org>') : ()),
);

