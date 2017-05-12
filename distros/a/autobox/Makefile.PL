use 5.008;

use strict;
use warnings;

use ExtUtils::MakeMaker;
use Config;

my $EUMM_VERSION = eval($ExtUtils::MakeMaker::VERSION);
my $OPTIMIZE;

if ($Config{gccversion}) {
    $OPTIMIZE = '-O3 -Wall';
    $OPTIMIZE .= ' -g -Wextra -Wdeclaration-after-statement' if (-d 'dev');
} elsif ($Config{osname} eq 'MSWin32') {
    $OPTIMIZE = '-O2 -W4';
} else {
    $OPTIMIZE = $Config{optimize};
}

WriteMakefile(
    NAME            => 'autobox',
    VERSION_FROM    => 'lib/autobox.pm',
    # compatibility in case module was previously installed to lib
    INSTALLDIRS     => ($] >= 5.011 ? 'site' : 'perl'),
    PREREQ_PM       => {
        'Scope::Guard'   => '0.21',
    },
    ABSTRACT_FROM        => 'lib/autobox.pod',
    AUTHOR               => 'chocolateboy <chocolate@cpan.org>',
    INC                  => '-I.',
    OPTIMIZE             => $OPTIMIZE,
    ($EUMM_VERSION >= 6.48 ? (MIN_PERL_VERSION => '5.8.0') : ()),
    ($EUMM_VERSION >= 6.31 ? (LICENSE => 'perl') : ()),
    ($EUMM_VERSION >= 6.46 ?
        (META_MERGE => {
            resources => {
                repository => 'https://github.com/chocolateboy/autobox',
                bugtracker => 'https://github.com/chocolateboy/autobox/issues',
            },
        })
        : ()
    ),
);
