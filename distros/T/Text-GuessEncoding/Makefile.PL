use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::GuessEncoding',
    AUTHOR              => q{Juergen Weigert <jw@suse.de>},
    VERSION_FROM        => 'GuessEncoding.pm',
    ABSTRACT_FROM       => 'GuessEncoding.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    EXE_FILES		=> [ 'guess_encoding' ],
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-GuessEncoding-*' },
);
