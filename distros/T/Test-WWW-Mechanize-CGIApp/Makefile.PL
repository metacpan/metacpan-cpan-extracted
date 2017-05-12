
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Test::WWW::Mechanize::CGIApp',
    VERSION      => '0.05',
    AUTHOR       => 'George Hartzell (hartzell@alerce.com)',
    ABSTRACT     => 'Test::WWW::Mechanize wrapper for CGI::Application apps',
    PREREQ_PM    => {
                     'Test::More' => 0.47,
                     'CGI::Application' => 0,
                     'Test::WWW::Mechanize' => 1.04,
                     'HTTP::Request::AsCGI' => 0,
                    },
             );
