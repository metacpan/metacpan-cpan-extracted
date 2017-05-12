use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tie::File::AnyData::MultiRecord_CSV',
    AUTHOR              => 'motif <motif@cpan.org>',
    VERSION_FROM        => 'lib/Tie/File/AnyData/MultiRecord_CSV.pm',
    ABSTRACT_FROM       => 'lib/Tie/File/AnyData/MultiRecord_CSV.pm',
    PL_FILES            => {},
    PREREQ_PM => {
		  'Test::More' => 0,
		  'Parse::CSV' => 0,
		  'Tie::File::AnyData' => 0.01,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tie-File-AnyData-MultiRecord_CSV-*' },
);
