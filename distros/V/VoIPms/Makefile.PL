#!/usr/bin/perl

use 5.024001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'VoIPms',
    VERSION_FROM      => 'lib/VoIPms.pm',
    PREREQ_PM         => { 'URI::Escape' => 3.31, 'WWW::Mechanize' => 1.83, 'JSON::XS' => 3.04 },
    ABSTRACT_FROM     => 'lib/VoIPms.pm',
    AUTHOR            => 'John Mertz <perl@john.me.tz>',
    LICENSE           => 'perl',
);
