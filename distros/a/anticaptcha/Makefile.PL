#!perl -w

require 5.010001;
use strict;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME => 'Anticaptcha',
    DISTNAME => 'Anticaptcha',
    VERSION_FROM => 'lib/Anticaptcha.pm',
    ABSTRACT => 'The Perl implementation for anti-captcha.com API',
    AUTHOR => 'Alexander Mironov <skull@cpan.org>',
    LICENSE => 'perl_5',
    MIN_PERL_VERSION => 5.010001,
    PREREQ_PM => {
        'LWP' => 6,
        'JSON' => 2,
    },
);

WriteMakefile(%WriteMakefileArgs);
