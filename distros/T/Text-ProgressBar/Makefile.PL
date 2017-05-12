#! perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::ProgressBar',
    AUTHOR              => q{Farhad Fouladi <farhad@cpan.org>},
    VERSION_FROM        => 'lib/Text/ProgressBar.pm',
    ABSTRACT_FROM       => 'lib/Text/ProgressBar.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'Moose'         => 0,
        'Moose::Role'   => 0,
        'List::Util'    => 0,
        'Term::ReadKey' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-ProgressBar-*' },
);
