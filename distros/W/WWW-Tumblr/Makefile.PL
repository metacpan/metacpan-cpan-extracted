use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'WWW::Tumblr',
    VERSION_FROM    => 'lib/WWW/Tumblr.pm',
    AUTHOR          => q{David Moreno <david@axiombox.com>},
    LICENSE         => 'perl',

    PREREQ_PM => {
        'Moose'                 => 0,
        'JSON'                  => 0,
        'LWP::UserAgent'        => 0,
        'Net::OAuth::Client'    => 0,
        'HTTP::Request::Common' => 0,
    },

    TEST_REQUIRES => {
        'Test::More'            => 0,
        'LWP::Simple'           => 0,
    },

    META_MERGE => {
        resources => {
            homepage   => 'http://github.com/damog/www-tumblr',
            repository => 'git://github.com/damog/www-tumblr.git',
            x_twitter => 'http://twitter.com/habanerd',
            bugtracker => 'https://github.com/damog/www-tumblr/issues',
        }
    },

    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW::Tumblr-*' },

);
