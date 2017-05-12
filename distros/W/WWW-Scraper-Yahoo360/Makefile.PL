use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Scraper::Yahoo360',
    VERSION_FROM      => 'lib/WWW/Scraper/Yahoo360.pm', # finds $VERSION
	EXE_FILES         => ['bin/export-yahoo360-blog.pl'],
    PREREQ_PM         => {
        # e.g., Module::Name => 1.1
        'JSON::XS'       => 0,
        'HTTP::Date'     => 0,
        'Date::Parse'    => 0,
        'File::Slurp'    => 0,
        'WWW::Mechanize' => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Scraper/Yahoo360.pm', # retrieve abstract from module
       AUTHOR         => 'Cosimo Streppone <cosimo@cpan.org>') : ()),
);

