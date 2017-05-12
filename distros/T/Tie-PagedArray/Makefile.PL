use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tie::PagedArray',
    AUTHOR              => q{Kartik Bherin <karthik.bp@gmail.com>},
    VERSION_FROM        => 'lib/Tie/PagedArray.pm',
    ABSTRACT_FROM       => 'lib/Tie/PagedArray.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Storable'   => 1.014,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tie-PagedArray-*' },
);
