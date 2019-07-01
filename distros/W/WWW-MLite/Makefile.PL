#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'CTK'                   => 2.01,
        'HTTP::Message'         => 6.08,
        'File::Temp'            => 0.22,
        'IO'                    => 0,
        'Storable'              => 0,
        'URI'                   => 1.50,
    };

WriteMakefile(
    'NAME'                  => 'WWW::MLite',
    'MIN_PERL_VERSION'      => 5.016001,
    'VERSION_FROM'          => 'lib/WWW/MLite.pm',
    'ABSTRACT_FROM'         => 'lib/WWW/MLite.pm',
    'BUILD_REQUIRES'        => $build_requires,
    'PREREQ_PM'             => $prereq_pm,
    'AUTHOR'                => 'Serz Minus (Sergey Lepenkov) <abalama@cpan.org>',
    'LICENSE'               => 'perl',
    'META_MERGE' => {
        recommends => {
            'Data::Dumper'  => 0,
        },
        resources => {
            homepage        => 'https://www.serzik.com',
            repository      => 'http://svn.serzik.com/WWW-MLite/trunk',
            license         => 'https://dev.perl.org/licenses',
        },
    },
);
