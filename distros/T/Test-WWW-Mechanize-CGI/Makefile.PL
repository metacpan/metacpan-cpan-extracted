#!perl

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Test::WWW::Mechanize::CGI',
    VERSION_FROM => 'lib/Test/WWW/Mechanize/CGI.pm',
    PREREQ_PM    => {
        Test::More           =>   0,
        Test::WWW::Mechanize =>   0,
        WWW::Mechanize::CGI  => 0.2        
    }
);
