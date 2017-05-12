#!/usr/bin/perl

use 5.010;

use strict;
use warnings;
no  warnings 'syntax';

use ExtUtils::MakeMaker;

my %args = (
    NAME                   => 'Test::Regexp',
    VERSION_FROM           => 'lib/Test/Regexp.pm',
    ABSTRACT_FROM          => 'lib/Test/Regexp.pm',
    PREREQ_PM              => {
        'Exporter'              => 0,
        'Hash::Util::FieldHash' => 0,
        'Test::Builder'         => 0,
        'warnings'              => 0,
        'strict'                => 0,
    },
    MIN_PERL_VERSION       =>  5.010,
    AUTHOR                 => 'Abigail <test-regexp@abigail.be>',
    LICENSE                => 'mit',
    META_MERGE             => {
        test_requires      => {
            'Test::More'   => 0.88,
            'Test::Tester' => 0,
            'warnings'     => 0,
            'strict'       => 0,
        },
        resources          => {
            repository     => 'git://github.com/Abigail/Test-Regexp.git',
        },
        keywords           => ['regular expression', 'pattern', 'regexp',
                               'test', 'tests'],
    },
);

$args {META_MERGE} {build_requires} ||= {
    'ExtUtils::MakeMaker' =>  0,
    %{$args {META_MERGE} {test_requires}}
};
    
$args {META_MERGE} {configure_requires} ||=
    $args {META_MERGE} {build_requires};
    
my %filter = (
    MIN_PERL_VERSION     => '6.48',
    META_MERGE           => '6.46',
    AUTHOR               => '6.07',
    ABSTRACT_FROM        => '6.07',
    LICENSE              => '6.07',
);

delete $args {$_} for grep {defined $filter {$_} &&
                            $ExtUtils::MakeMaker::VERSION lt $filter {$_}}
                            keys %args;


WriteMakefile %args;

__END__
