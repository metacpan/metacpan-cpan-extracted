use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tie::Handle::Flock',
    AUTHOR              => 'Ivan Heffner <iheffner@gmail.com>',
    VERSION_FROM        => 'lib/Tie/Handle/Flock.pm',
    ABSTRACT_FROM       => 'lib/Tie/Handle/Flock.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tie-Handle-Flock-*' },
);
