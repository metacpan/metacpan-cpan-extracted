use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	        => 'sitemapper',
    'EXE_FILES'         => [ 'sitemapper.pl' ],
    'PREREQ_PM'         => 
    {
        'WWW::Robot'    => 0.021,
        'HTML::Summary' => 0,
        'Digest::MD5'   => 0,
        'Date::Format'  => 0,
        'Getopt::Long'  => 0,
        'HTML::Entities'=> 0,
        'IO::File'      => 0,
        'LWP::UserAgent'=> 0,
        'URI::URL'      => 0,
        'Term::ReadKey' => 0,
        'Pod::Usage'    => 0,
        'Tk'            => 0,
    },
    'VERSION_FROM'      => 'sitemapper.pl', # finds $VERSION
    'dist'         => {
        'COMPRESS' => 'gzip',
        'SUFFIX'   => 'gz',
    },
);
