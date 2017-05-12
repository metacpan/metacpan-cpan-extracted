use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME                => 'Tie::File::AnyData::Bio::Fasta',
	      AUTHOR              => 'Miguel Pignatelli <motif@cpan.org>',
	      VERSION_FROM        => 'lib/Tie/File/AnyData/Bio/Fasta.pm',
#	      ABSTRACT_FROM       => 'lib/Tie/File/AnyData/Bio/Fasta.pm',
	      PL_FILES            => {},
	      PREREQ_PM => {
			    'Test::More' => 0,
			    'Tie::File::AnyData'  => 0.01
			   },
	      dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	      clean               => { FILES => 'Tie-File-AnyData-Bio-Fasta-*' },
	     );
