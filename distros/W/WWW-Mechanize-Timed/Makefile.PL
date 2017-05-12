#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'WWW::Mechanize::Timed',
    VERSION_FROM => 'lib/WWW/Mechanize/Timed.pm',
    LICENSE      => 'perl',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    PREREQ_PM    => {
        'Test::More'      => '0.01',
        'WWW::Mechanize'  => '0.72',
        'LWPx::TimedHTTP' => '1.2',
    },
);

