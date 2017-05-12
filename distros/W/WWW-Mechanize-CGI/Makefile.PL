#!perl

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'WWW::Mechanize::CGI',
    VERSION_FROM => 'lib/WWW/Mechanize/CGI.pm',
    PREREQ_PM    => {
        Carp                 =>   0,
        File::Spec           =>   0,
        HTTP::Request::AsCGI => 0.2,
        IO::Pipe             =>   0,
        Test::More           =>   0,
        WWW::Mechanize       =>   0
    }
);
