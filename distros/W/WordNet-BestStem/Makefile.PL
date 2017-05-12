use strict;
use warnings;
use ExtUtils::MakeMaker;

eval {
  use WordNet::QueryData;
  use WordNet::Similarity::ICFinder;
};
if ($@) {
  print STDERR "Please try again after installing WordNet::QueryData and WordNet::Similarity::ICFinder.\n";
  exit 0;
}

WriteMakefile(
    NAME              => 'WordNet::BestStem',
    AUTHOR            => 'Maggie J. Xiong  < maggiexyz users.sourceforge.net >',
    VERSION_FROM      => 'BestStem.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PREREQ_FATAL      => 1,
    PREREQ_PM => {
        'WordNet::QueryData' => 0,
        'WordNet::Similarity::ICFinder' => 0,
    },
    dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean             => { FILES => 'WordNet-BestStem-*' },
);
