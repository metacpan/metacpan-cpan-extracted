#!perl

use strict;
use warnings;

# Really this module isn't any use if you don't have the device file:
die "OS unsupported"
    unless -e '/dev/tty';

# Need this for TEST_REQUIRES
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
    NAME             => 'Test::NoTty',
    VERSION_FROM     => 'lib/Test/NoTty.pm',
    AUTHOR           => 'Nicholas Clark <nick@ccl4.org>',
    LICENSE          => 'perl',
    # Dear CPAN Testers, please keep me honest here:
    MIN_PERL_VERSION => '5.8.1',
    TEST_REQUIRES => {
        'IO::Pty'          => 0,
        'Test::Fatal'      => 0,
        'Test::More'       => 0,
        'Test::Warnings'   => 0,
    },
    META_MERGE => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://metacpan.org/module/Test::NoTty',
            bugtracker => 'https://github.com/Humanstate/test-notty/issues',
            repository => 'https://github.com/Humanstate/test-notty'
        },
    },
);
