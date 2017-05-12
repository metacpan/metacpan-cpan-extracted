use ExtUtils::MakeMaker qw(WriteMakefile);

WriteMakefile(
    'NAME'          => 'WWW::Mechanize::Pluggable',
    'VERSION_FROM'  => 'lib/WWW/Mechanize/Pluggable.pm', # finds $VERSION
    'ABSTRACT_FROM' => 'lib/WWW/Mechanize/Pluggable.pm', # retrieve abstract from module
    'AUTHOR'        => 'Joe McMahon <mcmahon@yahoo-inc.com>',
    'PREREQ_PM'     => {
        'Carp'              => 0,
        'File::Temp'        => 0,
        'FindBin'           => 0,
        'HTML::Form'        => 1.038,
        'HTML::HeadParser'  => 0,
        'HTML::TokeParser'  => 2.28,
        'HTTP::Cookies'     => 0,
        'HTTP::Daemon'      => 0,
        'HTTP::Request'     => 1.30,
        'HTTP::Status'      => 0,
        'LWP'               => 6.00,
        'LWP::UserAgent'    => 2.024,
        'Module::Pluggable' => 0,
        'Test::More'        => 0.34,
        'Test::Exception'   => 0.20,
        'URI'               => 1.25,
        'URI::URL'          => 0,
        'URI::file'         => 0,
	'WWW::Mechanize'    => 1.66,
        'Data::Dump::Streamer' => 0,
    },
    clean           => { FILES => join( " ",'WWW-Mechanize-0*' ) },
);
