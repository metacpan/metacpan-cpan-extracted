use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'VisionDB::Read',
    AUTHOR              => q{R.Scussat <r.scussat@dsplabs.net>},
    VERSION_FROM        => 'lib/VisionDB/Read.pm',
    ABSTRACT_FROM       => 'lib/VisionDB/Read.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'VisionDB-Read-*' },
);
