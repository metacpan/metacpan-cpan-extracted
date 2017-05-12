use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'WWW::Mechanize::Plugin::Retry',
    AUTHOR       => 'Joe McMahon <mcmahon@yahoo-inc.com>',
    VERSION_FROM => 'lib/WWW/Mechanize/Plugin/Retry.pm',
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Exception' => 0,
        'WWW::Mechanize::Pluggable' => 0.10,
        'Class::Accessor::Fast' => 0,
       
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean =>{ FILES => 'WWW-Mechanize-Plugin-Retry-*' },
);
