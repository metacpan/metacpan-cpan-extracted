use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'WebService::CRUST',
    VERSION_FROM => 'lib/WebService/CRUST.pm', # finds \$VERSION
    AUTHOR       => 'Chris Heschong (chris@wiw.org)',
    ABSTRACT     => 'A lightweight Client for making REST calls',
    PREREQ_PM    => {
                     'Test::Simple'          => 0,
                     'XML::Simple'           => 0,
                     'URI'                   => 0,
                     'URI::QueryParam'       => 0,
                     'LWP'                   => 0,
                     'HTTP::Cookies'         => 0,
                     'HTTP::Request::Common' => 0
                    },
);
