use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Unicode::CharWidth',
    AUTHOR              => q{Anno Siegel <anno5@mac.com>},
    VERSION_FROM        => 'lib/Unicode/CharWidth.pm',
    ABSTRACT_FROM       => 'lib/Unicode/CharWidth.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    MIN_PERL_VERSION    => 5.010001,
    PREREQ_PM => {
        'Test::More' => 0,
        'strict'     => 0,
        'warnings'   => 0,
        'Carp'       => 0,
        'constant'   => 0,
        'Dir::Self'  => 0,
        'File::Spec' => 0,
        'Storable'   => 0,
        'List::Util' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Unicode-CharWidth-*' },
);


