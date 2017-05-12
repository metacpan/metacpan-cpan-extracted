use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tk::DoubleClick',
    AUTHOR              => q{John C. Norton <jchnorton@verizon.net>},
    VERSION_FROM        => 'lib/Tk/DoubleClick.pm',
    ABSTRACT_FROM       => 'lib/Tk/DoubleClick.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        Tk =>           0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tk-DoubleClick-*' },
);
