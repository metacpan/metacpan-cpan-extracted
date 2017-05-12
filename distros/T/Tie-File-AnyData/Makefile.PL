use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tie::File::AnyData',
    AUTHOR              => 'Miguel Pignatelli <motif@cpan.org>',
    VERSION_FROM        => 'lib/Tie/File/AnyData.pm',
#    ABSTRACT_FROM       => 'lib/Tie/File/AnyData.pm',
    PL_FILES            => {},
    PREREQ_PM => {
		  'Test::More' => 0,
		  'Tie::File'  => 0.96
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tie-File-AnyData-*' },
);
