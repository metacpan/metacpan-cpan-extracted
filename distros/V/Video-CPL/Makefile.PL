use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Video::CPL',
    AUTHOR              => q{Carl Rosenberg <carl@coincident.tv>},
    VERSION_FROM        => 'lib/Video/CPL.pm',
    ABSTRACT_FROM       => 'lib/Video/CPL.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'XML::Simple' => 0,
	'XML::Writer' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Video-CPL-*' },
);
